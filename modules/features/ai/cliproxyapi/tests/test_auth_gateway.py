"""Wire-level tests for the public Funnel gate with isolated loopback fakes."""

import errno
import http.client
import json
import os
import queue
import socket
import struct
import subprocess
import sys
import threading
import time
from collections.abc import Generator, Mapping
from contextlib import closing, contextmanager, suppress
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import NamedTuple, cast, final, override

import pytest

SCRIPT = Path(__file__).parents[1] / "auth-gateway.py"
TOKEN = "funnel-" + "0" * 32
MISSING_MESSAGE = (
    "auth-gateway: missing GATEWAY_SECRET or CREDENTIALS_DIRECTORY/secrets.json\n"
)
CHALLENGE = 'Bearer realm="cliproxyapi"'
OWN_ENV = ("GATEWAY_SECRET", "CREDENTIALS_DIRECTORY", "CLIPROXY_UPSTREAM")

type Seen = queue.Queue[tuple[str, str, dict[str, str], bytes]]


class Fake(NamedTuple):
    """The fake upstream: its port, the requests it saw, and a stream-end flag."""

    port: int
    seen: Seen
    closed: threading.Event


class Gate(NamedTuple):
    """A running gateway in front of the fake upstream."""

    port: int
    seen: Seen
    closed: threading.Event


class Reply(NamedTuple):
    """What a client observed."""

    status: int
    body: bytes
    headers: list[tuple[str, str]]


def free_port() -> int:
    with closing(socket.socket()) as probe:
        probe.bind(("127.0.0.1", 0))
        # getsockname is typed Any; an AF_INET socket yields (host, port)
        return cast("tuple[str, int]", probe.getsockname())[1]


def bearer(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def header(reply: Reply, name: str) -> str:
    (value,) = [v for k, v in reply.headers if k.lower() == name.lower()]
    return value


def make_handler(seen: Seen, closed: threading.Event) -> type[BaseHTTPRequestHandler]:
    @final
    class Upstream(BaseHTTPRequestHandler):
        def respond(self) -> None:
            length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(length)
            seen.put((self.command, self.path, dict(self.headers), body))
            routes = {
                "/stream": self.stream,
                "/chunked": self.chunked,
                "/status": self.status,
                "/redirect": self.redirect,
            }
            routes.get(self.path, self.plain)()

        def redirect(self) -> None:
            self.send_response(302)
            self.send_header("Location", self.headers.get("X-Redirect-To", ""))
            self.end_headers()

        def plain(self) -> None:
            self.send_response(200)
            self.end_headers()
            _ = self.wfile.write(b"upstream")

        def status(self) -> None:
            self.send_response(503)
            self.send_header("X-Err", "busy")
            self.end_headers()
            _ = self.wfile.write(b"nope")

        def chunked(self) -> None:
            self.send_response(200)
            self.send_header("Transfer-Encoding", "chunked")
            self.send_header("Connection", "keep-alive")
            self.send_header("X-Upstream", "yes")
            self.end_headers()
            _ = self.wfile.write(b"4\r\nabcd\r\n0\r\n\r\n")

        def stream(self) -> None:
            self.send_response(200)
            self.end_headers()
            with suppress(OSError):
                while True:
                    _ = self.wfile.write(b"x" * 65536)
            closed.set()

        do_GET = do_POST = do_PUT = do_DELETE = respond  # noqa: N815 - stdlib handler API

        @override
        def log_message(self, format: str, *args: object) -> None:
            pass

    return Upstream


@contextmanager
def upstream_server() -> Generator[Fake]:
    seen: Seen = queue.Queue()
    closed = threading.Event()
    with ThreadingHTTPServer(("127.0.0.1", 0), make_handler(seen, closed)) as server:
        thread = threading.Thread(target=server.serve_forever)
        thread.start()
        try:
            yield Fake(server.server_port, seen, closed)
        finally:
            server.shutdown()
            thread.join()


def listening(port: int) -> bool:
    with closing(socket.socket()) as probe:
        probe.settimeout(0.2)
        return probe.connect_ex(("127.0.0.1", port)) == 0


def pause_then_probe(port: int) -> bool:
    time.sleep(0.05)
    return listening(port)


@contextmanager
def gateway(env: Mapping[str, str]) -> Generator[int]:
    port = free_port()
    inherited = {k: v for k, v in os.environ.items() if k not in OWN_ENV}
    full = {**inherited, **env, "GATEWAY_PORT": str(port)}
    with subprocess.Popen([sys.executable, str(SCRIPT)], env=full) as process:  # noqa: S603 - fixed argv, runs the script under test
        try:
            assert any(pause_then_probe(port) for _ in range(200))
            yield port
        finally:
            process.terminate()
            _ = process.wait(10)


@pytest.fixture
def gate() -> Generator[Gate]:
    with upstream_server() as fake:
        env = {
            "GATEWAY_SECRET": TOKEN,
            "CLIPROXY_UPSTREAM": f"http://127.0.0.1:{fake.port}",
        }
        with gateway(env) as port:
            yield Gate(port, fake.seen, fake.closed)


@pytest.fixture
def fake() -> Generator[Fake]:
    with upstream_server() as running:
        yield running


def request(
    port: int,
    method: str,
    path: str,
    headers: Mapping[str, str] | None = None,
    body: bytes | None = None,
) -> Reply:
    sent = bearer(TOKEN) if headers is None else dict(headers)
    payload = b"{}" if body is None and method == "POST" else body
    with closing(http.client.HTTPConnection("127.0.0.1", port, timeout=5)) as client:
        client.request(method, path, body=payload, headers=sent)
        response = client.getresponse()
        return Reply(response.status, response.read(), response.getheaders())


def test_inference_is_forwarded_with_the_token(gate: Gate) -> None:
    port, seen, _ = gate
    assert request(port, "POST", "/v1/chat/completions")[0] == 200
    method, path, headers, _ = seen.get(timeout=1)
    assert (method, path) == ("POST", "/v1/chat/completions")
    assert headers["Authorization"] == "Bearer keyless"


@pytest.mark.parametrize("method", ["GET", "POST", "PUT", "DELETE"])
def test_every_method_is_forwarded_with_query_body_and_headers(
    gate: Gate, method: str
) -> None:
    reply = request(
        gate.port,
        method,
        "/v1/things?limit=2&q=%2F",
        {**bearer(TOKEN), "X-Trace": "abc"},
        b'{"a": 1}' if method != "GET" else None,
    )
    assert reply.status == 200
    assert reply.body == b"upstream"
    seen_method, path, headers, body = gate.seen.get(timeout=1)
    assert (seen_method, path) == (method, "/v1/things?limit=2&q=%2F")
    assert body == (b'{"a": 1}' if method != "GET" else b"")
    assert headers["X-Trace"] == "abc"
    assert headers["Authorization"] == "Bearer keyless"
    assert TOKEN not in "".join(headers.values())
    assert gate.seen.empty()


def test_inference_without_the_token_is_unauthorized(gate: Gate) -> None:
    port, seen, _ = gate
    assert request(port, "GET", "/v1/models", headers={})[0] == 401
    assert seen.empty()


@pytest.mark.parametrize(
    "headers",
    [
        {},
        {"Authorization": "Basic Zm9vOmJhcg=="},
        {"Authorization": "Bearer"},
        {"Authorization": TOKEN},
        {"Authorization": f"bearer {TOKEN}"},
        {"Authorization": "Bearer wrong"},
        {"Authorization": f"Bearer {TOKEN[:-1]}"},
        {"Authorization": f"Bearer {TOKEN}x"},
        {"X-Api-Key": TOKEN},
    ],
    ids=[
        "missing",
        "basic",
        "no-space",
        "bare-token",
        "lowercase-scheme",
        "wrong",
        "prefix",
        "suffix",
        "other-header",
    ],
)
def test_bad_credentials_get_a_challenge_and_never_reach_upstream(
    gate: Gate, headers: dict[str, str]
) -> None:
    reply = request(gate.port, "POST", "/v1/chat/completions", headers)
    assert reply.status == 401
    assert reply.body == b""
    assert header(reply, "WWW-Authenticate") == CHALLENGE
    assert gate.seen.empty()


def test_management_is_refused_before_authentication(gate: Gate) -> None:
    reply = request(gate.port, "GET", "/v0/management/config", headers={})
    assert (reply.status, reply.body) == (404, b"")
    assert gate.seen.empty()


@pytest.mark.parametrize("path", ["/v1/models", "/v0/management/config"])
def test_preflight_is_open_and_never_forwarded(gate: Gate, path: str) -> None:
    reply = request(gate.port, "OPTIONS", path, headers={})
    assert (reply.status, reply.body) == (200, b"")
    assert header(reply, "Access-Control-Allow-Origin") == "*"
    assert (
        header(reply, "Access-Control-Allow-Methods")
        == "GET, POST, PUT, DELETE, OPTIONS"
    )
    assert header(reply, "Access-Control-Allow-Headers") == "*"
    assert gate.seen.empty()


def test_upstream_error_status_headers_and_body_are_relayed(gate: Gate) -> None:
    reply = request(gate.port, "GET", "/status")
    assert (reply.status, reply.body) == (503, b"nope")
    assert header(reply, "X-Err") == "busy"


def test_hop_by_hop_response_headers_are_not_relayed(gate: Gate) -> None:
    reply = request(gate.port, "GET", "/chunked")
    assert (reply.status, reply.body) == (200, b"abcd")
    names = {name.lower() for name, _ in reply.headers}
    assert "transfer-encoding" not in names
    assert "connection" not in names
    assert header(reply, "X-Upstream") == "yes"


def test_client_hangup_mid_stream_stops_the_relay(gate: Gate) -> None:
    raw = f"GET /stream HTTP/1.1\r\nHost: gate\r\nAuthorization: Bearer {TOKEN}\r\n\r\n"
    with closing(socket.create_connection(("127.0.0.1", gate.port), 5)) as client:
        client.sendall(raw.encode())
        received = b""
        while b"\r\n\r\n" not in received:
            received += client.recv(4096)
        client.setsockopt(socket.SOL_SOCKET, socket.SO_LINGER, struct.pack("ii", 1, 0))
    assert gate.closed.wait(10)
    assert request(gate.port, "GET", "/v1/models").status == 200


def test_upstream_redirects_are_relayed_not_followed(gate: Gate, fake: Fake) -> None:
    target = f"http://127.0.0.1:{fake.port}/landed"
    reply = request(
        gate.port, "GET", "/redirect", {**bearer(TOKEN), "X-Redirect-To": target}
    )
    assert reply.status == 302
    assert header(reply, "Location") == target
    assert gate.seen.get(timeout=1)[1] == "/redirect"
    assert fake.seen.empty()


def test_unreachable_upstream_is_a_bad_gateway() -> None:
    env = {
        "GATEWAY_SECRET": TOKEN,
        "CLIPROXY_UPSTREAM": f"http://127.0.0.1:{free_port()}",
    }
    refused = ConnectionRefusedError(
        errno.ECONNREFUSED, os.strerror(errno.ECONNREFUSED)
    )
    with gateway(env) as port:
        reply = request(port, "GET", "/v1/models")
    assert reply.status == 502
    assert header(reply, "Content-Type") == "application/json"
    assert json.loads(reply.body) == {"error": f"upstream unavailable: {refused}"}


@pytest.mark.parametrize(
    ("method", "path"),
    [
        ("GET", "/management.html"),
        ("GET", "/management.html?safe-mode=configure"),
        ("GET", "/v0/management/config"),
        ("PUT", "/v0/management/config"),
        ("POST", "/v8/management/requests/api-call"),
        ("GET", "/v8/management"),
        ("GET", "/v0/resource/plugins/quota/card.js"),
        ("GET", "//v0/management/config"),
        ("GET", "/v0//management/config"),
        ("GET", "/%76%30/management/config"),
        ("GET", "/v0/management%2Fconfig"),
    ],
)
def test_management_routes_never_leave_the_tailnet(
    gate: Gate, method: str, path: str
) -> None:
    """A valid client token still cannot reach the panel from the internet."""
    port, seen, _ = gate
    assert request(port, method, path)[0] == 404
    assert seen.empty()


def run_failing(env: Mapping[str, str]) -> subprocess.CompletedProcess[str]:
    inherited = {k: v for k, v in os.environ.items() if k not in OWN_ENV}
    return subprocess.run(  # noqa: S603 - fixed argv, runs the script under test
        [sys.executable, str(SCRIPT)],
        env={**inherited, **env},
        capture_output=True,
        text=True,
        timeout=30,
        check=False,
    )


def invalid_json_message() -> str:
    with pytest.raises(json.JSONDecodeError) as caught:
        json.loads("{not json")
    return f"auth-gateway: failed to read credentials: {caught.value}\n"


@pytest.mark.parametrize(
    "secrets",
    [
        None,
        "[]",
        "{}",
        '{"CLIPROXY_FUNNEL_TOKEN": ""}',
        '{"CLIPROXY_FUNNEL_TOKEN": "   "}',
        '{"CLIPROXY_FUNNEL_TOKEN": 5}',
    ],
    ids=[
        "no-file",
        "not-an-object",
        "no-key",
        "empty-token",
        "blank-token",
        "non-string-token",
    ],
)
def test_missing_or_unusable_credentials_fail_closed(
    tmp_path: Path, secrets: str | None
) -> None:
    if secrets is not None:
        _ = (tmp_path / "secrets.json").write_text(secrets, encoding="utf-8")
    done = run_failing({"CREDENTIALS_DIRECTORY": str(tmp_path)})
    assert (done.returncode, done.stdout, done.stderr) == (1, "", MISSING_MESSAGE)


def test_no_credential_source_fails_closed() -> None:
    done = run_failing({"GATEWAY_SECRET": ""})
    assert (done.returncode, done.stdout, done.stderr) == (1, "", MISSING_MESSAGE)


def test_unparseable_credentials_fail_closed(tmp_path: Path) -> None:
    _ = (tmp_path / "secrets.json").write_text("{not json", encoding="utf-8")
    done = run_failing({"CREDENTIALS_DIRECTORY": str(tmp_path)})
    assert (done.returncode, done.stdout, done.stderr) == (
        1,
        "",
        invalid_json_message(),
    )


def test_credentials_file_token_is_stripped_and_enforced(
    fake: Fake, tmp_path: Path
) -> None:
    _ = (tmp_path / "secrets.json").write_text(
        '{"CLIPROXY_FUNNEL_TOKEN": "  file-token\\n"}', encoding="utf-8"
    )
    env = {
        "CREDENTIALS_DIRECTORY": str(tmp_path),
        "CLIPROXY_UPSTREAM": f"http://127.0.0.1:{fake.port}",
    }
    with gateway(env) as port:
        assert request(port, "GET", "/v1/models", bearer("file-token")).status == 200
        assert request(port, "GET", "/v1/models", bearer(TOKEN)).status == 401


@pytest.mark.parametrize("env_secret", [TOKEN, ""], ids=["env-wins", "empty-env"])
def test_environment_secret_takes_precedence_only_when_non_empty(
    fake: Fake, tmp_path: Path, env_secret: str
) -> None:
    _ = (tmp_path / "secrets.json").write_text(
        '{"CLIPROXY_FUNNEL_TOKEN": "file-token"}', encoding="utf-8"
    )
    env = {
        "GATEWAY_SECRET": env_secret,
        "CREDENTIALS_DIRECTORY": str(tmp_path),
        "CLIPROXY_UPSTREAM": f"http://127.0.0.1:{fake.port}",
    }
    winner, loser = (TOKEN, "file-token") if env_secret else ("file-token", TOKEN)
    with gateway(env) as port:
        assert request(port, "GET", "/v1/models", bearer(winner)).status == 200
        assert request(port, "GET", "/v1/models", bearer(loser)).status == 401


def test_blank_environment_secret_falls_back_to_the_file(
    fake: Fake, tmp_path: Path
) -> None:
    _ = (tmp_path / "secrets.json").write_text(
        '{"CLIPROXY_FUNNEL_TOKEN": "file-token"}', encoding="utf-8"
    )
    env = {
        "GATEWAY_SECRET": "   ",
        "CREDENTIALS_DIRECTORY": str(tmp_path),
        "CLIPROXY_UPSTREAM": f"http://127.0.0.1:{fake.port}",
    }
    with gateway(env) as port:
        assert request(port, "GET", "/v1/models", bearer("file-token")).status == 200
        assert request(port, "GET", "/v1/models", bearer("   ")).status == 401


def test_padded_environment_secret_is_enforced_stripped(fake: Fake) -> None:
    env = {
        "GATEWAY_SECRET": "  abc  ",
        "CLIPROXY_UPSTREAM": f"http://127.0.0.1:{fake.port}",
    }
    with gateway(env) as port:
        assert request(port, "GET", "/v1/models", bearer("abc")).status == 200
