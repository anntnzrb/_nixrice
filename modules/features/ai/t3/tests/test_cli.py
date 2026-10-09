"""Behavior of t3ctl through its command line, against a temporary T3 home."""

from __future__ import annotations

import http.server
import json
import os
import sqlite3
import subprocess
import sys
import threading
from contextlib import closing
from pathlib import Path
from typing import TYPE_CHECKING, cast, override

import pytest

if TYPE_CHECKING:
    from collections.abc import Callable, Iterator

type Json = str | int | float | bool | list[Json] | dict[str, Json] | None

SCRIPT = Path(__file__).parents[1] / "t3ctl.py"
VERSION = "0.0.1-nightly.1"
UNREACHABLE = "http://127.0.0.1:1/v1"
CATALOG: Json = {
    "data": [
        {"id": "gpt-x", "display_name": "GPT X", "owned_by": "openai"},
        {"id": "claude-y", "owned_by": "anthropic"},
    ]
}
GPT_ONLY: Json = [{"slug": "gpt-x", "name": "GPT X"}]
ENABLED_CLAUDE: Json = {"claudeAgent": {"driver": "claudeAgent", "enabled": True}}


@pytest.fixture
def serve() -> Iterator[Callable[[bytes, int], str]]:
    servers: list[http.server.HTTPServer] = []

    def start(body: bytes, status: int) -> str:
        class Handler(http.server.BaseHTTPRequestHandler):
            def do_GET(self) -> None:
                self.send_response(status)
                self.send_header("Content-Length", str(len(body)))
                self.end_headers()
                _ = self.wfile.write(body)

            @override
            def log_message(self, format: str, *args: object) -> None:
                pass

        server = http.server.HTTPServer(("127.0.0.1", 0), Handler)
        threading.Thread(target=server.serve_forever, daemon=True).start()
        servers.append(server)
        return f"http://127.0.0.1:{server.server_port}/v1"

    yield start
    for server in servers:
        server.shutdown()
        server.server_close()


@pytest.fixture
def gateway(serve: Callable[[bytes, int], str]) -> str:
    return serve(json.dumps(CATALOG).encode(), 200)


def install_runtime(home: Path, log: Path) -> None:
    # A runtime whose `t3` records its arguments in `log`.
    version_dir = home / "runtime" / "versions" / VERSION
    version_dir.mkdir(parents=True)
    binary = version_dir / "t3"
    _ = binary.write_text(f'#!/bin/sh\necho "$@" >> {log}\n', encoding="utf-8")
    binary.chmod(0o755)
    _ = (home / "runtime" / "service-state.json").write_text(
        json.dumps({"activeVersion": VERSION}), encoding="utf-8"
    )


def make_home(
    root: Path, *, busy_status: str | None, providers: Json = ENABLED_CLAUDE
) -> Path:
    # A T3 home with an installed runtime and a settings file.
    home = root / ".t3"
    install_runtime(home, root / "t3.log")
    userdata = home / "userdata"
    userdata.mkdir()
    _ = (userdata / "settings.json").write_text(
        json.dumps({
            "uiOnly": "kept",
            "storageCleanup": {"logsAfterDays": 7, "worktreeOnMerge": False},
            "providerInstances": providers,
        }),
        encoding="utf-8",
    )
    with closing(sqlite3.connect(userdata / "statev2.sqlite")) as conn, conn:
        _ = conn.execute(
            "CREATE TABLE orchestration_v2_projection_runs (thread_id, status)"
        )
        _ = conn.execute(
            "INSERT INTO orchestration_v2_projection_runs VALUES ('a', 'completed')"
        )
        if busy_status is not None:
            _ = conn.execute(
                "INSERT INTO orchestration_v2_projection_runs VALUES ('b', ?)",
                (busy_status,),
            )
    return home


def fake_npx(root: Path, body: str) -> Path:
    # A directory holding an `npx` that logs its arguments, then runs `body`.
    bin_dir = root / "bin"
    bin_dir.mkdir()
    npx = bin_dir / "npx"
    _ = npx.write_text(
        f'#!/bin/sh\necho "$@" >> {root / "npx.log"}\n{body}\n', encoding="utf-8"
    )
    npx.chmod(0o755)
    return bin_dir


def run(
    home: Path,
    gateway: str,
    command: str,
    settings: Path,
    bin_dir: Path | None = None,
) -> subprocess.CompletedProcess[str]:
    path = os.environ["PATH"]
    if bin_dir is not None:
        path = f"{bin_dir}{os.pathsep}{path}"
    return subprocess.run(  # noqa: S603 - argv built from fixed paths
        [
            sys.executable,
            str(SCRIPT),
            command,
            "--channel",
            "nightly",
            "--settings",
            str(settings),
            "--gateway",
            gateway,
        ],
        env={**os.environ, "T3CODE_HOME": str(home), "PATH": path},
        capture_output=True,
        text=True,
        check=False,
    )


@pytest.fixture
def declared(tmp_path: Path) -> Path:
    path = tmp_path / "declared.json"
    _ = path.write_text(
        json.dumps({
            "storageCleanup": {"worktreeOnMerge": True, "worktreeAfterDays": 30}
        }),
        encoding="utf-8",
    )
    return path


def live_settings(home: Path) -> Json:
    text = (home / "userdata" / "settings.json").read_text(encoding="utf-8")
    return cast("Json", json.loads(text))


def obj(data: Json) -> dict[str, Json]:
    # Narrow parsed JSON to an object; fails the test otherwise.
    assert isinstance(data, dict)
    return data


def at(data: Json, *path: str) -> Json:
    # Follow object keys through parsed JSON; fails the test on a missing step.
    for key in path:
        assert isinstance(data, dict), f"{key!r} is not inside an object"
        data = data[key]
    return data


def claude_config(home: Path) -> dict[str, Json]:
    return obj(at(live_settings(home), "providerInstances", "claudeAgent", "config"))


def test_update_merges_settings_and_restarts_through_t3_when_idle(
    tmp_path: Path, gateway: str, declared: Path
) -> None:
    home = make_home(tmp_path, busy_status=None)
    result = run(home, gateway, "update", declared)
    assert result.returncode == 0, result.stderr

    live = live_settings(home)
    assert at(live, "uiOnly") == "kept"
    assert at(live, "storageCleanup") == {
        "logsAfterDays": 7,
        "worktreeOnMerge": True,
        "worktreeAfterDays": 30,
    }
    assert at(claude_config(home), "customModels") == GPT_ONLY
    assert (tmp_path / "t3.log").read_text(
        encoding="utf-8"
    ) == "update --yes --channel nightly\n"


@pytest.mark.parametrize("status", ["queued", "running", "waiting"])
def test_update_postpones_while_a_thread_runs(
    tmp_path: Path, gateway: str, declared: Path, status: str
) -> None:
    home = make_home(tmp_path, busy_status=status)
    result = run(home, gateway, "update", declared)
    assert result.returncode == 0, result.stderr
    assert "postponing" in result.stdout
    assert not (tmp_path / "t3.log").exists()
    assert at(live_settings(home), "storageCleanup", "worktreeAfterDays") == 30


def test_update_refuses_when_busy_state_is_unreadable(
    tmp_path: Path, gateway: str, declared: Path
) -> None:
    home = make_home(tmp_path, busy_status=None)
    (home / "userdata" / "statev2.sqlite").unlink()
    result = run(home, gateway, "update", declared)
    assert result.returncode == 1
    assert "cannot tell whether threads run" in result.stdout
    assert not (tmp_path / "t3.log").exists()


def test_update_bootstraps_a_host_without_t3(
    tmp_path: Path, gateway: str, declared: Path
) -> None:
    staged = tmp_path / "staged"
    install_runtime(staged, tmp_path / "t3.log")
    home = tmp_path / ".t3"
    bin_dir = fake_npx(tmp_path, f'cp -r "{staged}/runtime" "{home}/"')
    home.mkdir()
    result = run(home, gateway, "update", declared, bin_dir)
    assert result.returncode == 0, result.stderr
    assert "not installed; bootstrapping" in result.stdout
    assert (tmp_path / "npx.log").read_text(
        encoding="utf-8"
    ) == "-y t3@nightly service install\n"
    assert (tmp_path / "t3.log").read_text(encoding="utf-8") == "service restart\n"
    assert at(live_settings(home), "storageCleanup", "worktreeAfterDays") == 30


def test_bootstrap_stops_when_the_install_fails(
    tmp_path: Path, gateway: str, declared: Path
) -> None:
    home = tmp_path / ".t3"
    result = run(home, gateway, "update", declared, fake_npx(tmp_path, "exit 3"))
    assert result.returncode == 1
    assert not (home / "userdata" / "settings.json").exists()


def test_bootstrap_fails_when_the_install_leaves_no_runtime(
    tmp_path: Path, gateway: str, declared: Path
) -> None:
    home = tmp_path / ".t3"
    result = run(home, gateway, "update", declared, fake_npx(tmp_path, "exit 0"))
    assert result.returncode == 1
    assert at(live_settings(home), "storageCleanup", "worktreeAfterDays") == 30


def test_sync_before_install_is_a_no_op(
    tmp_path: Path, gateway: str, declared: Path
) -> None:
    result = run(tmp_path / ".t3", gateway, "sync", declared)
    assert result.returncode == 0
    assert "not installed" in result.stdout
    assert not (tmp_path / ".t3" / "userdata" / "settings.json").exists()


def test_sync_applies_settings_and_models_without_calling_t3(
    tmp_path: Path, gateway: str, declared: Path
) -> None:
    home = make_home(tmp_path, busy_status="running")
    result = run(home, gateway, "sync", declared)
    assert result.returncode == 0, result.stderr
    assert not (tmp_path / "t3.log").exists()

    live = live_settings(home)
    assert at(live, "uiOnly") == "kept"
    assert at(live, "storageCleanup", "worktreeAfterDays") == 30
    assert at(claude_config(home), "customModels") == GPT_ONLY


def test_sync_twice_rewrites_nothing_the_second_time(
    tmp_path: Path, gateway: str, declared: Path
) -> None:
    home = make_home(tmp_path, busy_status=None)
    first = run(home, gateway, "sync", declared)
    second = run(home, gateway, "sync", declared)
    assert "applied settings" in first.stdout
    assert second.returncode == 0, second.stderr
    assert not second.stdout


def test_sync_rejects_a_declaration_that_is_not_an_object(
    tmp_path: Path, gateway: str
) -> None:
    home = make_home(tmp_path, busy_status=None)
    settings = tmp_path / "declared.json"
    _ = settings.write_text("[1]", encoding="utf-8")
    result = run(home, gateway, "sync", settings)
    assert result.returncode == 1
    assert f"{settings} is not a JSON object" in result.stderr


def test_sync_rejects_live_settings_that_are_not_an_object(
    tmp_path: Path, gateway: str, declared: Path
) -> None:
    home = make_home(tmp_path, busy_status=None)
    target = home / "userdata" / "settings.json"
    _ = target.write_text("not json", encoding="utf-8")
    result = run(home, gateway, "sync", declared)
    assert result.returncode == 1
    assert f"{target} is not a JSON object" in result.stderr
    assert target.read_text(encoding="utf-8") == "not json"


def test_sync_creates_settings_when_none_exist(
    tmp_path: Path, gateway: str, declared: Path
) -> None:
    home = make_home(tmp_path, busy_status=None)
    (home / "userdata" / "settings.json").unlink()
    result = run(home, gateway, "sync", declared)
    assert result.returncode == 0, result.stderr
    assert live_settings(home) == {
        "storageCleanup": {"worktreeOnMerge": True, "worktreeAfterDays": 30}
    }


def test_sync_keeps_claude_config_and_replaces_only_its_models(
    tmp_path: Path, gateway: str, declared: Path
) -> None:
    providers: Json = {
        "claudeAgent": {
            "enabled": True,
            "config": {"binaryPath": "/x", "customModels": [{"slug": "old"}]},
        }
    }
    home = make_home(tmp_path, busy_status=None, providers=providers)
    result = run(home, gateway, "sync", declared)
    assert result.returncode == 0, result.stderr
    assert claude_config(home) == {"binaryPath": "/x", "customModels": GPT_ONLY}


def test_sync_leaves_matching_claude_models_alone(
    tmp_path: Path, gateway: str, declared: Path
) -> None:
    providers: Json = {
        "claudeAgent": {"enabled": True, "config": {"customModels": GPT_ONLY}}
    }
    home = make_home(tmp_path, busy_status=None, providers=providers)
    first = run(home, gateway, "sync", declared)
    second = run(home, gateway, "sync", declared)
    assert "Claude custom models" not in first.stdout
    assert not second.stdout
    assert claude_config(home) == {"customModels": GPT_ONLY}


@pytest.mark.parametrize(
    "providers",
    [
        pytest.param([], id="providers-not-an-object"),
        pytest.param({}, id="no-claude-instance"),
        pytest.param({"claudeAgent": "off"}, id="instance-not-an-object"),
        pytest.param({"claudeAgent": {"enabled": False}}, id="disabled"),
    ],
)
def test_sync_skips_claude_models_unless_the_instance_is_enabled(
    tmp_path: Path, gateway: str, declared: Path, providers: Json
) -> None:
    home = make_home(tmp_path, busy_status=None, providers=providers)
    result = run(home, gateway, "sync", declared)
    assert result.returncode == 0, result.stderr
    assert at(live_settings(home), "providerInstances") == providers
    assert "Claude" not in result.stdout


def test_sync_filters_and_shapes_the_gateway_catalog(
    tmp_path: Path, serve: Callable[[bytes, int], str], declared: Path
) -> None:
    catalog: Json = {
        "data": [
            "not-an-object",
            {"id": "claude-z", "display_name": "Z", "owned_by": "anthropic"},
            {"display_name": "no id"},
            {"id": "", "display_name": "empty id"},
            {"id": 7, "display_name": "numeric id"},
            {"id": "plain"},
            {"id": "blank-name", "display_name": ""},
            {"id": "named", "display_name": "Named", "owned_by": "openai"},
        ]
    }
    home = make_home(tmp_path, busy_status=None)
    result = run(home, serve(json.dumps(catalog).encode(), 200), "sync", declared)
    assert result.returncode == 0, result.stderr
    assert at(claude_config(home), "customModels") == [
        {"slug": "plain"},
        {"slug": "blank-name"},
        {"slug": "named", "name": "Named"},
    ]
    assert "Claude custom models -> 3 gateway models" in result.stdout


KEPT_CONFIG: Json = {"customModels": [{"slug": "kept", "name": "Kept"}], "other": 1}
KEPT_PROVIDERS: Json = {
    "claudeAgent": {"driver": "claudeAgent", "enabled": True, "config": KEPT_CONFIG}
}


@pytest.mark.parametrize(
    ("body", "status"),
    [
        pytest.param(b"not json", 200, id="invalid-json"),
        pytest.param(b"[]", 200, id="not-an-object"),
        pytest.param(b'{"data": {}}', 200, id="data-not-a-list"),
        pytest.param(b"{}", 500, id="http-error"),
    ],
)
def test_sync_keeps_claude_models_when_the_gateway_answers_badly(
    tmp_path: Path,
    serve: Callable[[bytes, int], str],
    declared: Path,
    body: bytes,
    status: int,
) -> None:
    home = make_home(tmp_path, busy_status=None, providers=KEPT_PROVIDERS)
    result = run(home, serve(body, status), "sync", declared)
    assert result.returncode == 0, result.stderr
    assert "gateway catalog unreachable" in result.stdout
    assert claude_config(home) == KEPT_CONFIG
    assert at(live_settings(home), "storageCleanup", "worktreeAfterDays") == 30


def test_sync_keeps_claude_models_when_the_gateway_is_down(
    tmp_path: Path, declared: Path
) -> None:
    home = make_home(tmp_path, busy_status=None, providers=KEPT_PROVIDERS)
    result = run(home, UNREACHABLE, "sync", declared)
    assert result.returncode == 0, result.stderr
    assert "gateway catalog unreachable; Claude models unchanged" in result.stdout
    assert claude_config(home) == KEPT_CONFIG
