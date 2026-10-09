"""End-to-end tests for release.py, run as a subprocess against a temporary state dir.

GitHub is the only fake: an HTTPS proxy on loopback tunnels ``github.com:443`` to a
local TLS server with a throwaway certificate, so the script's URLs, redirects and
downloads are exercised unchanged. The seams are ``HTTPS_PROXY`` and the CA file
(``SSL_CERT_FILE``, plus ``NIX_SSL_CERT_FILE`` that nixpkgs' OpenSSL prefers).
Host OS/arch detection and ``execv`` coverage hand-off need a tiny runner.
"""

import fcntl
import hashlib
import io
import json
import os
import runpy
import shlex
import shutil
import ssl
import subprocess
import sys
import tarfile
import threading
import time
from collections.abc import Iterator
from dataclasses import dataclass
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import TYPE_CHECKING, cast, final, override

import pytest

if TYPE_CHECKING:
    import argparse
    import socket
    from collections.abc import Callable

SCRIPT = Path(__file__).parents[1] / "release.py"
RELEASES = "/router-for-me/CLIProxyAPI/releases"
TAG_URL = "https://github.com/router-for-me/CLIProxyAPI/releases/tag"
ASSET_ARCH = {"amd64": "amd64", "arm64": "aarch64"}
ALL_PLATFORMS = (
    ("linux", "amd64"),
    ("linux", "arm64"),
    ("darwin", "amd64"),
    ("darwin", "arm64"),
)
FAKE_BINARY = (
    b'#!/bin/sh\nprintf "%s\\n" "$@" > "$CPA_ARGS_FILE"\nexit "${CPA_EXIT:-0}"\n'
)
CHECKSUM_NOISE = "\n".join([
    "",
    "not-a-checksum-line",
    "abc123  CLIProxyAPI_short_digest.tar.gz",
    f"{'z' * 64}  CLIProxyAPI_not_hex.tar.gz",
    f"{'0' * 64}  too many fields",
])

# Replaces the process environment's view of the host (os.uname, the lowest boundary
# behind platform.system/machine) and saves coverage before execv, which would drop it.
RUNNER = """
import os, runpy, sys
env = os.environ
fake = os.uname_result((env["FAKE_SYSNAME"], "host", "1", "v", env["FAKE_MACHINE"]))
os.uname = lambda: fake
preseed = os.environ.get("PRESEED_DIR")
if preseed:
    os.symlink("dangling", f"{preseed}/.current.{os.getpid()}.tmp")
real_execv = os.execv
def execv(path, argv):
    try:
        import coverage
    except ImportError:
        coverage = None
    cov = coverage.Coverage.current() if coverage else None
    if cov is not None:
        cov.stop()
        cov.save()
    real_execv(path, argv)
os.execv = execv
sys.argv = sys.argv[1:]
runpy.run_path(sys.argv[0], run_name="__main__")
"""

type Done = subprocess.CompletedProcess[str]
type Tls = tuple[Path, Path]


@dataclass(frozen=True)
class Reply:
    status: int = 200
    body: bytes = b""
    headers: tuple[tuple[str, str], ...] = ()
    drop: bool = False
    delay: float = 0


@dataclass(frozen=True)
class GitHub:
    routes: dict[str, Reply]
    seen: list[str]
    env: dict[str, str]


def tarball(name: str, data: bytes = b"", kind: bytes = tarfile.REGTYPE) -> bytes:
    buffer = io.BytesIO()
    with tarfile.open(fileobj=buffer, mode="w:gz") as tar:
        info = tarfile.TarInfo(name)
        info.type = kind
        info.mode = 0o644
        info.size = len(data)
        tar.addfile(info, io.BytesIO(data))
    return buffer.getvalue()


GOOD_ARCHIVE = tarball("cli-proxy-api", FAKE_BINARY)


def asset_name(version: str, os_name: str, arch: str) -> str:
    return f"CLIProxyAPI_{version}_{os_name}_{ASSET_ARCH[arch]}.tar.gz"


def publish(
    github: GitHub,
    version: str,
    *,
    archive: bytes = GOOD_ARCHIVE,
    digest: str | None = None,
) -> None:
    lines = [CHECKSUM_NOISE]
    for os_name, arch in ALL_PLATFORMS:
        asset = asset_name(version, os_name, arch)
        github.routes[f"{RELEASES}/download/v{version}/{asset}"] = Reply(body=archive)
        shown = digest or hashlib.sha256(archive).hexdigest().upper()
        lines.append(f"{shown}  {asset}")
    github.routes[f"{RELEASES}/download/v{version}/checksums.txt"] = Reply(
        body="\n".join(lines).encode()
    )
    github.routes[f"{RELEASES}/latest"] = Reply(
        302, headers=(("Location", f"{TAG_URL}/v{version}"),)
    )


@pytest.fixture(scope="session")
def tls_files(tmp_path_factory: pytest.TempPathFactory) -> Tls:
    directory = tmp_path_factory.mktemp("tls")
    cert, key = directory / "cert.pem", directory / "key.pem"
    openssl = shutil.which("openssl")
    assert openssl is not None
    _ = subprocess.run(  # noqa: S603 - fixed openssl argv, no shell
        [
            *(openssl, "req", "-x509", "-newkey", "ec", "-pkeyopt"),
            *("ec_paramgen_curve:prime256v1", "-nodes", "-days", "2"),
            *("-subj", "/CN=github.com", "-addext", "subjectAltName=DNS:github.com"),
            *("-addext", "basicConstraints=critical,CA:TRUE"),
            *("-keyout", str(key), "-out", str(cert)),
        ],
        check=True,
        capture_output=True,
    )
    return cert, key


@pytest.fixture
def github(tls_files: Tls) -> Iterator[GitHub]:
    cert, key = tls_files
    routes: dict[str, Reply] = {}
    seen: list[str] = []
    stop = threading.Event()
    context = ssl.create_default_context(ssl.Purpose.CLIENT_AUTH)
    context.load_cert_chain(cert, key)

    @final
    class Origin(BaseHTTPRequestHandler):
        def do_GET(self) -> None:
            seen.append(self.path)
            reply = routes.get(self.path, Reply(404))
            _ = stop.wait(reply.delay)
            if reply.drop:
                self.close_connection = True
                return
            self.send_response(reply.status)
            for name, value in reply.headers:
                self.send_header(name, value)
            self.send_header("Content-Length", str(len(reply.body)))
            self.end_headers()
            _ = self.wfile.write(reply.body)

        @override
        def log_message(self, format: str, *args: object) -> None:
            pass

    @final
    class Proxy(BaseHTTPRequestHandler):
        def do_CONNECT(self) -> None:
            self.send_response(200)
            self.end_headers()
            tunnel = context.wrap_socket(
                cast("socket.socket", self.connection), server_side=True
            )
            _ = Origin(tunnel, ("127.0.0.1", 0), self.server)
            tunnel.close()
            self.close_connection = True

        @override
        def log_message(self, format: str, *args: object) -> None:
            pass

    with ThreadingHTTPServer(("127.0.0.1", 0), Proxy) as server:
        thread = threading.Thread(target=server.serve_forever)
        thread.start()
        proxy = f"http://127.0.0.1:{server.server_port}"
        env = {
            **{
                k: v
                for k, v in os.environ.items()
                if k.upper() not in {"HTTPS_PROXY", "HTTP_PROXY", "NO_PROXY"}
            },
            "HTTPS_PROXY": proxy,
            "SSL_CERT_FILE": str(cert),
            "NIX_SSL_CERT_FILE": str(cert),
        }
        try:
            yield GitHub(routes, seen, env)
        finally:
            stop.set()
            server.shutdown()
            thread.join()


def release(*args: str, env: dict[str, str], cwd: Path | None = None) -> Done:
    return subprocess.run(  # noqa: S603 - the script under test, no shell
        [sys.executable, str(SCRIPT), *args],
        check=False,
        capture_output=True,
        text=True,
        env=env,
        cwd=cwd,
        timeout=60,
    )


def shimmed(
    *args: str,
    env: dict[str, str],
    host: tuple[str, str] = ("Linux", "x86_64"),
    preseed: Path | None = None,
) -> Done:
    fake = {"FAKE_SYSNAME": host[0], "FAKE_MACHINE": host[1]}
    if preseed is not None:
        fake["PRESEED_DIR"] = str(preseed)
    return subprocess.run(  # noqa: S603 - the script under test, no shell
        [sys.executable, "-c", RUNNER, str(SCRIPT), *args],
        check=False,
        capture_output=True,
        text=True,
        env={**env, **fake},
        timeout=60,
    )


def install(github: GitHub, state: Path, *args: str, verb: str = "install") -> Done:
    return release(
        verb, "--state", str(state), "--platform", "linux-amd64", *args, env=github.env
    )


def fake_systemctl(directory: Path, exit_code: int, message: str) -> Path:
    directory.mkdir()
    record = directory / "calls"
    script = directory / "systemctl"
    lines = [
        "#!/bin/sh",
        f"printf '%s\\n' \"$*\" >> {record}",
        f"echo '{message}' >&2",
        f"exit {exit_code}",
    ]
    _ = script.write_text("\n".join(lines) + "\n")
    script.chmod(0o755)
    return record


def link_target(state: Path) -> str:
    return str((state / "current").readlink())


@pytest.mark.parametrize("failure", ["configure", "restart"])
def test_update_retries_selected_release_until_running(
    github: GitHub, tmp_path: Path, failure: str
) -> None:
    state = tmp_path / "releases"
    archive = tarball("cli-proxy-api", Path("/proc/self/exe").read_bytes())
    publish(github, "1.2.3", archive=archive)
    done = install(github, state)
    assert done.returncode == 0, done.stderr
    old_binary = (state / "current/cli-proxy-api").resolve()
    publish(github, "1.3.0", archive=archive)

    helpers = tmp_path / "bin"
    helpers.mkdir()
    for name, content in {
        "release": (
            f'exec {shlex.quote(sys.executable)} {shlex.quote(str(SCRIPT))} "$@"'
        ),
        "configure": (
            f"exec {shlex.quote(sys.executable)} "
            f'{shlex.quote(str(SCRIPT.with_name("configure.py")))} "$@"'
        ),
        "runuser": 'shift 3; exec "$@"',
        "systemctl": (
            'if [ "$1" = show ]; then cat "$CPA_PID_FILE"; exit; fi\n'
            'printf "%s\\n" "$*" >> "$CPA_RESTARTS"\n'
            '[ ! -f "$CPA_RESTART_FAIL" ]'
        ),
    }.items():
        _ = (helpers / name).write_text(f"#!/bin/sh\n{content}\n", encoding="utf-8")
        (helpers / name).chmod(0o755)

    settings = tmp_path / "settings.yaml"
    secrets = tmp_path / "secrets.json"
    pid_file = tmp_path / "pid"
    restarts = tmp_path / "restarts"
    restart_fail = tmp_path / "restart-fail"
    _ = settings.write_text("port: 8317\n", encoding="utf-8")
    valid_secrets = '{"CLIPROXY_CREDENTIAL_POOLS": {}}'
    _ = secrets.write_text(
        "invalid" if failure == "configure" else valid_secrets, encoding="utf-8"
    )
    if failure == "restart":
        restart_fail.touch()
    env = {
        **github.env,
        "PATH": f"{helpers}:{os.environ['PATH']}",
        "CPA_PID_FILE": str(pid_file),
        "CPA_RESTARTS": str(restarts),
        "CPA_RESTART_FAIL": str(restart_fail),
    }
    command = [
        "bash",
        "-euo",
        "pipefail",
        str(SCRIPT.with_name("update.sh")),
        "cliproxyapi",
        str(state),
        str(helpers / "release"),
        str(helpers / "configure"),
        str(settings),
        str(tmp_path / "models.json"),
        str(tmp_path / "runtime.yaml"),
        str(secrets),
    ]
    with subprocess.Popen(  # noqa: S603 - real executable in the temporary release tree
        [str(old_binary), "-c", "import sys; sys.stdin.read()"], stdin=subprocess.PIPE
    ) as process:
        _ = pid_file.write_text(str(process.pid), encoding="utf-8")
        done = subprocess.run(  # noqa: S603 - real updater with external service helpers
            command, env=env, capture_output=True, text=True, check=False, timeout=60
        )
        assert done.returncode != 0
        assert link_target(state) == "versions/1.3.0/linux-amd64"
        assert Path(f"/proc/{process.pid}/exe").resolve() == old_binary
        _ = secrets.write_text(valid_secrets, encoding="utf-8")
        restart_fail.unlink(missing_ok=True)
        done = subprocess.run(  # noqa: S603 - retry through the same updater entry point
            command, env=env, capture_output=True, text=True, check=False, timeout=60
        )
        assert done.returncode == 0, done.stderr
        attempts = (
            restarts.read_text(encoding="utf-8").splitlines()
            if restarts.exists()
            else []
        )
        assert attempts == ["try-restart cliproxyapi.service"] * (
            1 if failure == "configure" else 2
        )
    with subprocess.Popen(  # noqa: S603 - selected release now represents the running service
        [str(state / "current/cli-proxy-api"), "-c", "import sys; sys.stdin.read()"],
        stdin=subprocess.PIPE,
    ) as process:
        _ = pid_file.write_text(str(process.pid), encoding="utf-8")
        done = subprocess.run(  # noqa: S603 - an unchanged running release must not restart
            command, env=env, capture_output=True, text=True, check=False, timeout=60
        )
        assert done.returncode == 0, done.stderr
        assert restarts.read_text(encoding="utf-8").splitlines() == attempts
    _ = pid_file.write_text("0", encoding="utf-8")
    command[-2] = str(tmp_path / "absent-runtime/config.yaml")
    done = subprocess.run(  # noqa: S603 - a stopped service stays stopped, with cache-only sync
        command, env=env, capture_output=True, text=True, check=False, timeout=60
    )
    assert done.returncode == 0, done.stderr
    assert restarts.read_text(encoding="utf-8").splitlines() == attempts
    assert not (tmp_path / "absent-runtime").exists()


def test_install_latest_installs_verifies_and_links(
    github: GitHub, tmp_path: Path
) -> None:
    publish(github, "1.2.3")
    state = tmp_path.resolve() / "state"
    done = install(github, state)
    executable = state / "versions/1.2.3/linux-amd64/cli-proxy-api"
    assert done.returncode == 0, done.stderr
    assert done.stdout == (
        f"cli-proxy-api: installed (version: 1.2.3, previous: none, "
        f"executable: {executable})\n"
    )
    assert link_target(state) == "versions/1.2.3/linux-amd64"
    assert executable.stat().st_mode & 0o777 == 0o755
    receipt = cast(
        "dict[str, str]", json.loads((executable.parent / "receipt.json").read_text())
    )
    assert receipt == {
        "repository": "router-for-me/CLIProxyAPI",
        "version": "1.2.3",
        "platform": "linux-amd64",
        "asset": "CLIProxyAPI_1.2.3_linux_amd64.tar.gz",
        "sha256": hashlib.sha256(GOOD_ARCHIVE).hexdigest(),
    }
    assert sorted(p.name for p in executable.parent.iterdir()) == [
        "cli-proxy-api",
        "receipt.json",
    ]
    assert not list((state / "versions" / "1.2.3").glob(".stage.*"))
    assert (state / ".install.lock").is_file()


def test_install_pinned_version_skips_latest_lookup(
    github: GitHub, tmp_path: Path
) -> None:
    publish(github, "1.2.3")
    done = install(github, tmp_path / "state", "--version", "v1.2.3", "--timeout", "30")
    assert done.returncode == 0, done.stderr
    assert f"{RELEASES}/latest" not in github.seen
    assert github.seen[0] == f"{RELEASES}/download/v1.2.3/checksums.txt"


def test_reinstall_is_unchanged_and_downloads_nothing(
    github: GitHub, tmp_path: Path
) -> None:
    publish(github, "1.2.3")
    state = tmp_path / "state"
    _ = install(github, state)
    github.seen.clear()
    done = install(github, state, "--json", verb="update")
    assert done.returncode == 0, done.stderr
    out = cast("dict[str, object]", json.loads(done.stdout))
    assert out["status"] == "unchanged"
    assert out["changed"] is False
    assert out["previous_version"] == out["current_version"] == "1.2.3"
    assert github.seen == [f"{RELEASES}/latest"]


def test_upgrade_switches_current_and_reports_previous(
    github: GitHub, tmp_path: Path
) -> None:
    publish(github, "1.2.3")
    publish(github, "1.3.0")
    state = tmp_path / "state"
    _ = install(github, state, "--version", "1.2.3")
    done = install(github, state, "--json")
    out = cast("dict[str, object]", json.loads(done.stdout))
    assert (out["status"], out["changed"]) == ("installed", True)
    assert (out["previous_version"], out["current_version"]) == ("1.2.3", "1.3.0")
    assert link_target(state) == "versions/1.3.0/linux-amd64"
    assert (state / "versions/1.2.3/linux-amd64/cli-proxy-api").is_file()


def test_pinning_an_older_cached_version_relinks_without_download(
    github: GitHub, tmp_path: Path
) -> None:
    publish(github, "1.2.3")
    publish(github, "1.3.0")
    state = tmp_path / "state"
    _ = install(github, state, "--version", "1.2.3")
    _ = install(github, state, "--version", "1.3.0")
    github.seen.clear()
    done = install(github, state, "--version", "1.2.3", "--json")
    out = cast("dict[str, object]", json.loads(done.stdout))
    assert (out["status"], out["changed"]) == ("installed", True)
    assert out["previous_version"] == "1.3.0"
    assert link_target(state) == "versions/1.2.3/linux-amd64"
    assert github.seen == []


def test_missing_current_link_is_restored_from_cache(
    github: GitHub, tmp_path: Path
) -> None:
    publish(github, "1.2.3")
    state = tmp_path / "state"
    _ = install(github, state)
    (state / "current").unlink()
    done = install(github, state, "--json")
    out = cast("dict[str, object]", json.loads(done.stdout))
    assert (out["status"], out["previous_version"]) == ("installed", None)
    assert link_target(state) == "versions/1.2.3/linux-amd64"


def test_invalid_cached_directory_is_never_overwritten(
    github: GitHub, tmp_path: Path
) -> None:
    publish(github, "1.2.3")
    state = tmp_path / "state"
    broken = state / "versions/1.2.3/linux-amd64"
    broken.mkdir(parents=True)
    done = install(github, state, "--version", "1.2.3")
    assert done.returncode == 1
    assert "exists but is invalid; refusing to overwrite" in done.stderr
    assert list(broken.iterdir()) == []
    assert github.seen == []


@pytest.mark.parametrize(
    "version", ["v", ".", "..", "a/b", "a\\b", "bad version", "1.2.3/.."]
)
def test_unsafe_versions_are_rejected_before_any_request(
    github: GitHub, tmp_path: Path, version: str
) -> None:
    done = install(github, tmp_path / "state", "--version", version)
    assert done.returncode == 1
    assert f"error: invalid version string: {version!r}" in done.stderr
    assert github.seen == []


@pytest.mark.parametrize(
    ("platform", "key", "asset"),
    [
        ("linux-amd64", "linux-amd64", "linux_amd64"),
        ("Linux_AMD64", "linux-amd64", "linux_amd64"),
        (" linux-x64 ", "linux-amd64", "linux_amd64"),
        ("linux-arm64", "linux-arm64", "linux_aarch64"),
        ("darwin_aarch64", "darwin-arm64", "darwin_aarch64"),
        ("darwin-amd64", "darwin-amd64", "darwin_amd64"),
    ],
)
def test_explicit_platform_selects_matching_asset(
    github: GitHub, tmp_path: Path, platform: str, key: str, asset: str
) -> None:
    publish(github, "1.2.3")
    state = tmp_path / "state"
    done = release(
        *("install", "--state", str(state), "--version", "1.2.3"),
        *("--platform", platform),
        env=github.env,
    )
    assert done.returncode == 0, done.stderr
    assert (state / "versions/1.2.3" / key / "cli-proxy-api").is_file()
    assert (
        github.seen[-1]
        == f"{RELEASES}/download/v1.2.3/CLIProxyAPI_1.2.3_{asset}.tar.gz"
    )


@pytest.mark.parametrize(
    "platform",
    ["windows-amd64", "linux-riscv", "linux", "a-b-c", "linux-amd64-x", "linux-x86_64"],
)
def test_unsupported_explicit_platform_fails(
    github: GitHub, tmp_path: Path, platform: str
) -> None:
    done = release(
        *("install", "--state", str(tmp_path / "state"), "--platform", platform),
        env=github.env,
    )
    assert done.returncode == 1
    assert f"error: unsupported target platform: {platform!r}" in done.stderr


@pytest.mark.parametrize(
    ("host", "key"),
    [
        (("Linux", "x86_64"), "linux-amd64"),
        (("Linux", "aarch64"), "linux-arm64"),
        (("Darwin", "arm64"), "darwin-arm64"),
        (("Darwin", "AMD64"), "darwin-amd64"),
    ],
)
def test_host_platform_is_detected_when_none_given(
    github: GitHub, tmp_path: Path, host: tuple[str, str], key: str
) -> None:
    publish(github, "1.2.3")
    state = tmp_path.resolve() / "state"
    done = shimmed(
        *("install", "--state", str(state), "--version", "1.2.3", "--json"),
        env=github.env,
        host=host,
    )
    assert done.returncode == 0, done.stderr
    out = cast("dict[str, str]", json.loads(done.stdout))
    assert out["executable"] == str(state / "versions/1.2.3" / key / "cli-proxy-api")


@pytest.mark.parametrize(
    ("host", "message"),
    [
        (("FreeBSD", "amd64"), "unsupported host operating system: 'freebsd'"),
        (("Linux", "riscv64"), "unsupported host architecture: 'riscv64'"),
    ],
)
def test_unsupported_host_fails(
    github: GitHub, tmp_path: Path, host: tuple[str, str], message: str
) -> None:
    done = shimmed(
        *("install", "--state", str(tmp_path / "state")), env=github.env, host=host
    )
    assert done.returncode == 1
    assert f"error: {message}" in done.stderr
    assert github.seen == []


def test_checksum_mismatch_refuses_and_keeps_current(
    github: GitHub, tmp_path: Path
) -> None:
    publish(github, "1.2.3")
    publish(github, "1.3.0", digest="0" * 64)
    state = tmp_path / "state"
    _ = install(github, state, "--version", "1.2.3")
    done = install(github, state, "--version", "1.3.0")
    assert done.returncode == 1
    assert "checksum mismatch for CLIProxyAPI_1.3.0_linux_amd64.tar.gz" in done.stderr
    assert link_target(state) == "versions/1.2.3/linux-amd64"
    assert not (state / "versions/1.3.0/linux-amd64").exists()
    assert list((state / "versions/1.3.0").iterdir()) == []


def test_checksum_mismatch_on_first_install_leaves_nothing_current(
    github: GitHub, tmp_path: Path
) -> None:
    publish(github, "1.2.3", digest="f" * 64)
    state = tmp_path / "state"
    done = install(github, state)
    assert done.returncode == 1
    assert "checksum mismatch" in done.stderr
    assert not (state / "current").is_symlink()
    status = release("status", "--state", str(state), env=github.env)
    assert status.stdout == f"CLIProxyAPI: not installed in {state.resolve()}\n"


def test_asset_missing_from_checksums_fails(github: GitHub, tmp_path: Path) -> None:
    publish(github, "1.2.3")
    github.routes[f"{RELEASES}/download/v1.2.3/checksums.txt"] = Reply(
        body=f"{'a' * 64}  other.tar.gz\n".encode()
    )
    done = install(github, tmp_path / "state")
    assert done.returncode == 1
    assert (
        "checksums.txt for 1.2.3 does not contain asset "
        "CLIProxyAPI_1.2.3_linux_amd64.tar.gz"
    ) in done.stderr


def test_checksums_http_error_fails(github: GitHub, tmp_path: Path) -> None:
    publish(github, "1.2.3")
    del github.routes[f"{RELEASES}/download/v1.2.3/checksums.txt"]
    done = install(github, tmp_path / "state", "--version", "1.2.3")
    assert done.returncode == 1
    assert "checksums download failed from" in done.stderr
    assert "with HTTP 404: Not Found" in done.stderr


def test_checksums_connection_drop_fails(github: GitHub, tmp_path: Path) -> None:
    publish(github, "1.2.3")
    github.routes[f"{RELEASES}/download/v1.2.3/checksums.txt"] = Reply(drop=True)
    done = install(github, tmp_path / "state", "--version", "1.2.3")
    assert done.returncode == 1
    assert "error: checksums download failed from" in done.stderr
    assert "with HTTP" not in done.stderr


def test_asset_http_error_cleans_stage(github: GitHub, tmp_path: Path) -> None:
    publish(github, "1.2.3")
    asset = asset_name("1.2.3", "linux", "amd64")
    del github.routes[f"{RELEASES}/download/v1.2.3/{asset}"]
    state = tmp_path / "state"
    done = install(github, state, "--version", "1.2.3")
    assert done.returncode == 1
    assert f"download failed for https://github.com{RELEASES}" in done.stderr
    assert "with HTTP 404: Not Found" in done.stderr
    assert list((state / "versions/1.2.3").iterdir()) == []
    assert not (state / "current").is_symlink()


def test_asset_connection_drop_fails(github: GitHub, tmp_path: Path) -> None:
    publish(github, "1.2.3")
    asset = asset_name("1.2.3", "linux", "amd64")
    github.routes[f"{RELEASES}/download/v1.2.3/{asset}"] = Reply(drop=True)
    done = install(github, tmp_path / "state", "--version", "1.2.3")
    assert done.returncode == 1
    assert "error: download failed for" in done.stderr
    assert "with HTTP" not in done.stderr


@pytest.mark.parametrize(
    ("archive", "message"),
    [
        (tarball("README", b"hi"), "missing required binary cli-proxy-api"),
        (
            tarball("cli-proxy-api", kind=tarfile.DIRTYPE),
            "archive member cli-proxy-api is not a regular file",
        ),
        (b"definitely not a tarball", "failed to extract archive"),
    ],
)
def test_bad_archives_fail_after_checksum_and_install_nothing(
    github: GitHub, tmp_path: Path, archive: bytes, message: str
) -> None:
    publish(github, "1.2.3", archive=archive)
    state = tmp_path / "state"
    done = install(github, state, "--version", "1.2.3")
    assert done.returncode == 1
    assert message in done.stderr
    assert list((state / "versions/1.2.3").iterdir()) == []
    assert not (state / "current").is_symlink()


@pytest.mark.parametrize(
    ("route", "message"),
    [
        (Reply(404), "latest release lookup failed with HTTP 404: Not Found"),
        (Reply(500), "latest release lookup failed with HTTP 500: Internal Server"),
        (Reply(302), "missing Location header in redirect from"),
        (Reply(200), "missing Location header in redirect from"),
        (Reply(drop=True), "error: latest release lookup failed: "),
        (Reply(delay=30), "latest release lookup failed: "),
        (
            Reply(302, headers=(("Location", f"{TAG_URL}/vbad%20tag"),)),
            "invalid version string: 'vbad%20tag'",
        ),
    ],
)
def test_latest_lookup_failures(
    github: GitHub, tmp_path: Path, route: Reply, message: str
) -> None:
    github.routes[f"{RELEASES}/latest"] = route
    done = install(github, tmp_path / "state", "--timeout", "1")
    assert done.returncode == 1
    assert message in done.stderr
    assert github.seen == [f"{RELEASES}/latest"]


@pytest.mark.parametrize("status", [301, 303, 307, 308, 200])
def test_latest_accepts_any_redirect_status_and_a_plain_location(
    github: GitHub, tmp_path: Path, status: int
) -> None:
    publish(github, "1.2.3")
    github.routes[f"{RELEASES}/latest"] = Reply(
        status, headers=(("Location", f"{TAG_URL}/v1.2.3/"),)
    )
    done = install(github, tmp_path / "state")
    assert done.returncode == 0, done.stderr
    assert "version: 1.2.3" in done.stdout


def test_latest_timeout_is_reported(github: GitHub, tmp_path: Path) -> None:
    github.routes[f"{RELEASES}/latest"] = Reply(delay=30)
    started = time.monotonic()
    done = install(github, tmp_path / "state", "--timeout", "0.5")
    assert done.returncode == 1
    assert "latest release lookup failed: " in done.stderr
    assert "timed out" in done.stderr
    assert time.monotonic() - started < 20


def test_restart_runs_systemctl_only_when_version_changed(
    github: GitHub, tmp_path: Path
) -> None:
    publish(github, "1.2.3")
    record = fake_systemctl(tmp_path / "bin", 0, "")
    env = {**github.env, "PATH": str(tmp_path / "bin")}
    state = tmp_path / "state"
    args = (
        "--state",
        str(state),
        "--platform",
        "linux-amd64",
        "--restart",
        "cpa.service",
    )
    first = release("install", *args, env=env)
    assert first.returncode == 0, first.stderr
    assert first.stdout.endswith("restarted systemd system unit: cpa.service\n")
    again = release("update", *args, env=env)
    assert again.returncode == 0, again.stderr
    assert "restarted" not in again.stdout
    assert record.read_text() == "restart cpa.service\n"


def test_restart_with_user_flag_targets_user_manager(
    github: GitHub, tmp_path: Path
) -> None:
    publish(github, "1.2.3")
    record = fake_systemctl(tmp_path / "bin", 0, "")
    env = {**github.env, "PATH": str(tmp_path / "bin")}
    done = release(
        *("install", "--state", str(tmp_path / "state"), "--platform", "linux-amd64"),
        *("--restart", "cpa.service", "--user", "--json"),
        env=env,
    )
    assert done.returncode == 0, done.stderr
    assert done.stdout.endswith("restarted systemd user unit: cpa.service\n")
    assert record.read_text() == "--user restart cpa.service\n"


def test_restart_failure_is_an_error_after_install(
    github: GitHub, tmp_path: Path
) -> None:
    publish(github, "1.2.3")
    _ = fake_systemctl(tmp_path / "bin", 5, "unit exploded")
    env = {**github.env, "PATH": str(tmp_path / "bin")}
    state = tmp_path / "state"
    done = release(
        *("install", "--state", str(state), "--platform", "linux-amd64"),
        *("--restart", "cpa.service"),
        env=env,
    )
    assert done.returncode == 1
    assert "error: failed to restart unit cpa.service: unit exploded" in done.stderr
    assert link_target(state) == "versions/1.2.3/linux-amd64"


def test_restart_without_systemctl_is_an_error(github: GitHub, tmp_path: Path) -> None:
    publish(github, "1.2.3")
    (tmp_path / "empty").mkdir()
    env = {**github.env, "PATH": str(tmp_path / "empty")}
    done = release(
        *("install", "--state", str(tmp_path / "state"), "--platform", "linux-amd64"),
        *("--restart", "cpa.service"),
        env=env,
    )
    assert done.returncode == 1
    assert "error: failed to execute systemctl: " in done.stderr


def test_stale_temp_link_from_a_crashed_run_is_replaced(
    github: GitHub, tmp_path: Path
) -> None:
    publish(github, "1.2.3")
    state = tmp_path.resolve() / "state"
    state.mkdir()
    done = shimmed(
        *("install", "--state", str(state), "--platform", "linux-amd64"),
        env=github.env,
        preseed=state,
    )
    assert done.returncode == 0, done.stderr
    assert link_target(state) == "versions/1.2.3/linux-amd64"
    assert not list(state.glob(".current.*.tmp"))


def test_concurrent_install_waits_for_the_lock(github: GitHub, tmp_path: Path) -> None:
    publish(github, "1.2.3")
    state = tmp_path / "state"
    state.mkdir()
    with (state / ".install.lock").open("a+") as held:
        fcntl.flock(held, fcntl.LOCK_EX)
        proc = subprocess.Popen(  # noqa: S603 - the script under test, no shell
            [
                *(sys.executable, str(SCRIPT), "install", "--state", str(state)),
                *("--platform", "linux-amd64"),
            ],
            env=github.env,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        time.sleep(1)
        waited = proc.poll() is None
    out, err = proc.communicate(timeout=60)
    assert waited
    assert proc.returncode == 0, err
    assert "installed" in out


def test_state_path_that_is_a_file_reports_unexpected_error(
    github: GitHub, tmp_path: Path
) -> None:
    state = tmp_path / "state"
    _ = state.write_text("not a directory")
    done = install(github, state)
    assert done.returncode == 1
    assert done.stderr.startswith("unexpected error: ")
    assert github.seen == []


def test_unknown_user_home_in_state_is_a_run_error(tmp_path: Path) -> None:
    done = release(
        *("run", "--state", "~no-such-user-for-rice/s", "--config", "c"),
        env=dict(os.environ),
        cwd=tmp_path,
    )
    assert done.returncode == 2
    assert done.stderr.startswith("error: ")


def write_receipt(state: Path, version: str, content: str | None) -> Path:
    target = state / "versions" / version / "linux-amd64"
    target.mkdir(parents=True)
    if content is not None:
        _ = (target / "receipt.json").write_text(content)
    (state / "current").symlink_to(target.relative_to(state))
    return target


def test_status_when_nothing_is_installed(tmp_path: Path) -> None:
    env = dict(os.environ)
    text = release("status", "--state", str(tmp_path / "s"), env=env)
    assert text.returncode == 0
    assert text.stdout == f"CLIProxyAPI: not installed in {tmp_path / 's'}\n"
    data = release("status", "--state", str(tmp_path / "s"), "--json", env=env)
    assert json.loads(data.stdout) == {
        "installed": False,
        "version": None,
        "target": None,
        "receipt": None,
    }


def test_status_after_install_reports_version_and_receipt(
    github: GitHub, tmp_path: Path
) -> None:
    publish(github, "1.2.3")
    state = tmp_path.resolve() / "state"
    _ = install(github, state)
    target = state / "versions/1.2.3/linux-amd64"
    text = release("status", "--state", str(state), env=github.env)
    assert text.stdout == f"CLIProxyAPI: installed at version 1.2.3 ({target})\n"
    data = release("status", "--state", str(state), "--json", env=github.env)
    out = cast("dict[str, object]", json.loads(data.stdout))
    assert out["installed"] is True
    assert out["version"] == "1.2.3"
    assert out["target"] == str(target)
    receipt = cast("dict[str, str]", out["receipt"])
    assert receipt["sha256"] == hashlib.sha256(GOOD_ARCHIVE).hexdigest()


def test_status_ignores_a_dangling_current_link(tmp_path: Path) -> None:
    state = tmp_path.resolve() / "state"
    state.mkdir()
    (state / "current").symlink_to("versions/gone")
    done = release("status", "--state", str(state), env=dict(os.environ))
    assert done.stdout == f"CLIProxyAPI: not installed in {state}\n"


@pytest.mark.parametrize(
    ("content", "receipt"),
    [
        (None, None),
        ("{}", {}),
        ('{"other": 1}', {"other": "1"}),
        ("[1, 2]", None),
        ("{not json", None),
        ('"text"', None),
    ],
)
def test_status_falls_back_to_directory_name_without_a_usable_receipt(
    tmp_path: Path, content: str | None, receipt: dict[str, str] | None
) -> None:
    state = tmp_path.resolve() / "state"
    target = write_receipt(state, "9.9.9", content)
    done = release("status", "--state", str(state), "--json", env=dict(os.environ))
    out = cast("dict[str, object]", json.loads(done.stdout))
    assert out["version"] == "9.9.9"
    assert out["target"] == str(target)
    assert out["receipt"] == receipt


def test_status_reads_receipt_values_as_strings(tmp_path: Path) -> None:
    state = tmp_path.resolve() / "state"
    _ = write_receipt(state, "9.9.9", '{"version": 7, "n": null}')
    done = release("status", "--state", str(state), "--json", env=dict(os.environ))
    out = cast("dict[str, object]", json.loads(done.stdout))
    assert out["version"] == "7"
    assert out["receipt"] == {"version": "7", "n": "None"}


@pytest.mark.skipif(os.geteuid() == 0, reason="root ignores file permissions")
def test_status_treats_an_unreadable_receipt_as_missing(tmp_path: Path) -> None:
    state = tmp_path.resolve() / "state"
    target = write_receipt(state, "9.9.9", "{}")
    (target / "receipt.json").chmod(0)
    done = release("status", "--state", str(state), "--json", env=dict(os.environ))
    out = cast("dict[str, object]", json.loads(done.stdout))
    assert (out["version"], out["receipt"]) == ("9.9.9", None)


def test_status_treats_a_non_utf8_receipt_as_missing(tmp_path: Path) -> None:
    state = tmp_path.resolve() / "state"
    target = write_receipt(state, "9.9.9", None)
    _ = (target / "receipt.json").write_bytes(b"\xff\xfe")
    done = release("status", "--state", str(state), "--json", env=dict(os.environ))
    assert done.returncode == 0
    out = cast("dict[str, object]", json.loads(done.stdout))
    assert out["version"] == "9.9.9"
    assert out["target"] == str(target)
    assert out["receipt"] is None


@pytest.mark.skipif(os.geteuid() == 0, reason="root ignores directory permissions")
def test_status_treats_a_link_beneath_an_unreadable_directory_as_missing(
    tmp_path: Path,
) -> None:
    state = tmp_path.resolve() / "state"
    _ = write_receipt(state, "9.9.9", "{}")
    locked = state / "versions"
    try:
        locked.chmod(0)
        done = release("status", "--state", str(state), "--json", env=dict(os.environ))
    finally:
        locked.chmod(0o755)
    assert done.returncode == 0
    assert json.loads(done.stdout) == {
        "installed": False,
        "version": None,
        "target": None,
        "receipt": None,
    }


def make_state(tmp_path: Path, *, mode: int = 0o755) -> tuple[Path, Path]:
    state = tmp_path.resolve() / "state"
    (state / "current").mkdir(parents=True)
    binary = state / "current" / "cli-proxy-api"
    _ = binary.write_bytes(FAKE_BINARY)
    binary.chmod(mode)
    config = tmp_path / "config.yaml"
    _ = config.write_text("port: 1\n")
    return state, config


@pytest.mark.parametrize(
    ("tail", "forwarded"),
    [
        ((), []),
        (("--", "--flag", "x"), ["--flag", "x"]),
        (("--flag", "x"), ["--flag", "x"]),
    ],
)
def test_run_execs_binary_with_config_and_forwarded_args(
    tmp_path: Path, tail: tuple[str, ...], forwarded: list[str]
) -> None:
    state, config = make_state(tmp_path)
    args_file = tmp_path / "args"
    env = {**os.environ, "CPA_ARGS_FILE": str(args_file), "CPA_EXIT": "7"}
    done = shimmed(
        *("run", "--state", str(state), "--config", str(config), *tail), env=env
    )
    assert done.returncode == 7, done.stderr
    assert args_file.read_text().splitlines() == ["--config", str(config), *forwarded]


def test_run_without_installed_binary_exits_127(tmp_path: Path) -> None:
    state = tmp_path.resolve() / "state"
    done = release(
        *("run", "--state", str(state), "--config", "c"), env=dict(os.environ)
    )
    assert done.returncode == 127
    assert done.stderr == (
        f"error: CLIProxyAPI binary not found or not executable at "
        f"{state / 'current/cli-proxy-api'}.\n"
        f"Run 'release.py install --state {state}' first.\n"
    )


@pytest.mark.skipif(os.geteuid() == 0, reason="root can execute any file")
def test_run_with_non_executable_binary_exits_127(tmp_path: Path) -> None:
    state, config = make_state(tmp_path, mode=0o644)
    done = release(
        *("run", "--state", str(state), "--config", str(config)),
        env=dict(os.environ),
    )
    assert done.returncode == 127
    assert "not found or not executable" in done.stderr


def test_run_without_config_file_exits_1(tmp_path: Path) -> None:
    state, _ = make_state(tmp_path)
    missing = tmp_path / "missing.yaml"
    done = release(
        *("run", "--state", str(state), "--config", str(missing)),
        env=dict(os.environ),
    )
    assert done.returncode == 1
    assert done.stderr == f"error: CLIProxyAPI config file not found: {missing}\n"


def test_run_requires_config_argument(tmp_path: Path) -> None:
    done = release("run", "--state", str(tmp_path), env=dict(os.environ))
    assert done.returncode == 2
    assert "the following arguments are required: --config" in done.stderr


def test_state_named_run_still_dispatches_to_status(tmp_path: Path) -> None:
    done = release("status", "--state", "run", env=dict(os.environ), cwd=tmp_path)
    assert done.returncode == 0
    assert (
        done.stdout == f"CLIProxyAPI: not installed in {tmp_path.resolve() / 'run'}\n"
    )


def test_help_exits_zero() -> None:
    done = release("--help", env=dict(os.environ))
    assert done.returncode == 0
    assert "Dynamic release installer" in done.stdout


@pytest.mark.parametrize(
    "args", [(), ("bogus",), ("status",), ("install", "--state", "s", "--nope")]
)
def test_bad_command_lines_exit_2(args: tuple[str, ...]) -> None:
    done = release(*args, env=dict(os.environ))
    assert done.returncode == 2
    assert "usage:" in done.stderr


@pytest.mark.parametrize("command", ["install", "update"])
def test_install_and_update_defaults(command: str) -> None:
    module = cast(
        "dict[str, object]", runpy.run_path(str(SCRIPT), run_name="release_under_test")
    )
    build_parser = cast("Callable[[], argparse.ArgumentParser]", module["build_parser"])
    args_cls = cast("Callable[[], argparse.Namespace]", module["Args"])
    parsed = cast(
        "dict[str, object]",
        vars(
            build_parser().parse_args([command, "--state", "/s"], namespace=args_cls())
        ),
    )
    defaults = cast("dict[str, object]", vars(args_cls()))
    assert (
        parsed["version"],
        parsed["timeout"],
        parsed["platform"],
        parsed["restart"],
    ) == (
        "latest",
        60.0,
        None,
        None,
    )
    for key in defaults.keys() - {"state", "subcommand"}:
        assert parsed[key] == defaults[key], key
