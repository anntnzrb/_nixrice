#!/usr/bin/env python3
# Copyright (c) 2026 rice authors. SPDX-License-Identifier: AGPL-3.0-or-later
"""Bearer-token gate in front of the keyless CLIProxyAPI gateway.

Tailscale Funnel publishes this listener to the internet so hosted clients
can reach the gateway. CLIProxyAPI itself accepts any client key, so the
token checked here is the only credential on the public path. Secrets can be
loaded via systemd LoadCredential (credentials directory) or GATEWAY_SECRET.

The management panel stays on the private network: its routes are refused
here before authentication, so a leaked client token never reaches it.
"""

import hmac
import json
import os
import sys
import urllib.error
import urllib.request
from email.message import Message
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import IO, TYPE_CHECKING, Protocol, cast, override
from urllib.parse import unquote, urlsplit

if TYPE_CHECKING:
    from contextlib import AbstractContextManager
    from http.client import HTTPResponse


def _load_secret_key() -> bytes:
    env_secret = os.environ.get("GATEWAY_SECRET", "").strip()
    if env_secret:
        return env_secret.encode("utf-8")

    creds_dir = os.environ.get("CREDENTIALS_DIRECTORY")
    if creds_dir:
        cred_file = Path(creds_dir) / "secrets.json"
        if cred_file.is_file():
            try:
                # json.loads is typed Any; the match below narrows the untrusted value
                data = cast("object", json.loads(cred_file.read_text(encoding="utf-8")))
                match data:
                    case {"CLIPROXY_FUNNEL_TOKEN": str() as raw} if raw.strip():
                        return raw.strip().encode("utf-8")
                    case _:
                        pass
            except Exception as err:  # noqa: BLE001 - fail closed on any credential read error
                _ = sys.stderr.write(
                    f"auth-gateway: failed to read credentials: {err}\n"
                )
                sys.exit(1)

    _ = sys.stderr.write(
        "auth-gateway: missing GATEWAY_SECRET or CREDENTIALS_DIRECTORY/secrets.json\n"
    )
    sys.exit(1)


SECRET_KEY = _load_secret_key()
try:
    UPSTREAM = os.environ["CLIPROXY_UPSTREAM"]
    LISTEN = ("127.0.0.1", int(os.environ["GATEWAY_PORT"]))
except KeyError as err:
    _ = sys.stderr.write(f"auth-gateway: missing required environment variable {err}\n")
    sys.exit(1)
# CLIProxyAPI's management surface (its server_middleware.go).
MANAGEMENT_PREFIXES = ("/v0/management", "/v8/management", "/v0/resource/plugins")


def management_route(raw_path: str) -> bool:
    """Match on the decoded path so encoded or doubled slashes cannot hide a route.

    Returns:
        Whether the request path addresses CLIProxyAPI's management surface.
    """
    path = "/" + "/".join(
        part for part in unquote(urlsplit(raw_path).path).split("/") if part
    )
    return path.startswith("/management") or any(
        path == prefix or path.startswith(prefix + "/")
        for prefix in MANAGEMENT_PREFIXES
    )


class _Readable(Protocol):
    def read(self, size: int, /) -> bytes: ...


class _NoRedirect(urllib.request.HTTPRedirectHandler):
    """Hand upstream 3xx responses to the client instead of following them."""

    @override
    def redirect_request(
        self,
        req: urllib.request.Request,
        fp: IO[bytes],
        code: int,
        msg: str,
        headers: Message,
        newurl: str,
    ) -> None:
        """Decline the redirect so urllib raises HTTPError carrying the 3xx."""


_OPENER = urllib.request.build_opener(_NoRedirect)


class ProxyHandler(BaseHTTPRequestHandler):
    """Authenticate each request, then stream it to the upstream CLIProxyAPI."""

    def authorized(self) -> bool:
        """Compare the bearer token to the secret in constant time.

        Returns:
            Whether the request carries the gateway token.
        """
        auth = self.headers.get("Authorization", "")
        if not auth.startswith("Bearer "):
            return False
        token = auth.removeprefix("Bearer ").strip().encode()
        return hmac.compare_digest(token, SECRET_KEY)

    def do_OPTIONS(self) -> None:
        """Answer CORS preflights without authentication."""
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header(
            "Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS"
        )
        self.send_header("Access-Control-Allow-Headers", "*")
        self.end_headers()

    def forward(self, method: str) -> None:
        """Refuse management routes and bad tokens, else proxy upstream."""
        if management_route(self.path):
            self.send_response(404)
            self.end_headers()
            return
        if not self.authorized():
            self.send_response(401)
            self.send_header("WWW-Authenticate", 'Bearer realm="cliproxyapi"')
            self.end_headers()
            return

        headers = {
            k: v for k, v in self.headers.items() if k.lower() != "authorization"
        }
        headers["Authorization"] = "Bearer keyless"
        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length) if length > 0 else None

        req = urllib.request.Request(  # noqa: S310 - upstream URL is operator-configured
            UPSTREAM + self.path,
            data=body,
            headers=headers,
            method=method,
        )
        try:
            # urlopen is typed Any; http(s) upstreams always yield an HTTPResponse
            opened = cast(
                "AbstractContextManager[HTTPResponse]",
                _OPENER.open(req),
            )
            with opened as resp:
                self.relay(resp.status, resp.headers, resp)
        except urllib.error.HTTPError as err:
            self.relay(err.code, err.headers, err)
        except urllib.error.URLError as err:
            self.send_response(502)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            payload = json.dumps({
                "error": f"upstream unavailable: {err.reason}"
            }).encode()
            _ = self.wfile.write(payload)

    def relay(self, status: int, headers: Message, body: _Readable) -> None:
        """Send the upstream status, headers and body to the client."""
        # Stream the body as it arrives: SSE responses must reach the client
        # token by token, not after generation ends. HTTP/1.0 (the handler's
        # default) delimits the body by closing the connection.
        self.send_response(status)
        for name, value in headers.items():
            if name.lower() not in {"connection", "transfer-encoding"}:
                self.send_header(name, value)
        self.end_headers()
        try:
            while chunk := body.read(4096):
                _ = self.wfile.write(chunk)
                self.wfile.flush()
        except (BrokenPipeError, ConnectionResetError):
            return

    def do_GET(self) -> None:
        """Proxy a GET request."""
        self.forward("GET")

    def do_POST(self) -> None:
        """Proxy a POST request."""
        self.forward("POST")

    def do_PUT(self) -> None:
        """Proxy a PUT request."""
        self.forward("PUT")

    def do_DELETE(self) -> None:
        """Proxy a DELETE request."""
        self.forward("DELETE")

    @override
    def log_message(self, format: str, *args: object) -> None:
        pass


if __name__ == "__main__":
    ThreadingHTTPServer(LISTEN, ProxyHandler).serve_forever()
