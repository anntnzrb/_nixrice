#!/usr/bin/env python3
# Copyright (c) 2026 rice authors. SPDX-License-Identifier: AGPL-3.0-or-later
# ruff: noqa: INP001 - standalone installed script, not an importable package
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
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import unquote, urlsplit


def _load_secret_key() -> bytes:
    if "GATEWAY_SECRET" in os.environ and os.environ["GATEWAY_SECRET"]:
        return os.environ["GATEWAY_SECRET"].encode("utf-8")

    creds_dir = os.environ.get("CREDENTIALS_DIRECTORY")
    if creds_dir:
        cred_file = Path(creds_dir) / "secrets.json"
        if cred_file.is_file():
            try:
                data = json.loads(cred_file.read_text(encoding="utf-8"))
                token = data.get("CLIPROXY_FUNNEL_TOKEN")
                if token and isinstance(token, str):
                    return token.strip().encode("utf-8")
            except Exception as err:
                sys.stderr.write(f"auth-gateway: failed to read credentials: {err}\n")
                sys.exit(1)

    sys.stderr.write("auth-gateway: missing GATEWAY_SECRET or CREDENTIALS_DIRECTORY/secrets.json\n")
    sys.exit(1)


SECRET_KEY = _load_secret_key()
UPSTREAM = os.environ.get("CLIPROXY_UPSTREAM", "http://127.0.0.1:18317")
# The Funnel mapping proxies to 127.0.0.1:8318; the override exists for tests.
LISTEN = ("127.0.0.1", int(os.environ.get("GATEWAY_PORT", "8318")))
# CLIProxyAPI's management surface (its server_middleware.go).
MANAGEMENT_PREFIXES = ("/v0/management", "/v8/management", "/v0/resource/plugins")


def management_route(raw_path):
    """Match on the decoded path so encoded or doubled slashes cannot hide a route."""
    path = "/" + "/".join(
        part for part in unquote(urlsplit(raw_path).path).split("/") if part
    )
    return path.startswith("/management") or any(
        path == prefix or path.startswith(prefix + "/") for prefix in MANAGEMENT_PREFIXES
    )


class ProxyHandler(BaseHTTPRequestHandler):
    def authorized(self):
        auth = self.headers.get("Authorization", "")
        if not auth.startswith("Bearer "):
            return False
        token = auth.removeprefix("Bearer ").strip().encode()
        return hmac.compare_digest(token, SECRET_KEY)

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "*")
        self.end_headers()

    def forward(self, method):
        if management_route(self.path):
            self.send_response(404)
            self.end_headers()
            return
        if not self.authorized():
            self.send_response(401)
            self.send_header("WWW-Authenticate", 'Bearer realm="cliproxyapi"')
            self.end_headers()
            return

        headers = {k: v for k, v in self.headers.items() if k.lower() != "authorization"}
        headers["Authorization"] = "Bearer keyless"
        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length) if length > 0 else None

        req = urllib.request.Request(
            UPSTREAM + self.path,
            data=body,
            headers=headers,
            method=method,
        )
        try:
            with urllib.request.urlopen(req) as resp:
                self.relay(resp.status, resp.headers, resp)
        except urllib.error.HTTPError as err:
            self.relay(err.code, err.headers, err)
        except urllib.error.URLError as err:
            self.send_response(502)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            payload = json.dumps({"error": f"upstream unavailable: {err.reason}"}).encode()
            self.wfile.write(payload)

    def relay(self, status, headers, body):
        # Stream the body as it arrives: SSE responses must reach the client
        # token by token, not after generation ends. HTTP/1.0 (the handler's
        # default) delimits the body by closing the connection.
        self.send_response(status)
        for name, value in headers.items():
            if name.lower() not in ("connection", "transfer-encoding"):
                self.send_header(name, value)
        self.end_headers()
        try:
            while chunk := body.read(4096):
                self.wfile.write(chunk)
                self.wfile.flush()
        except (BrokenPipeError, ConnectionResetError):
            return

    def do_GET(self):
        self.forward("GET")

    def do_POST(self):
        self.forward("POST")

    def do_PUT(self):
        self.forward("PUT")

    def do_DELETE(self):
        self.forward("DELETE")

    def log_message(self, format, *args):  # noqa: A002 - stdlib signature
        pass


if __name__ == "__main__":
    ThreadingHTTPServer(LISTEN, ProxyHandler).serve_forever()
