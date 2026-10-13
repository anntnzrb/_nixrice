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

SCRIPT = Path(__file__).parents[1] / "cli.py"
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
    _ = (version_dir / ".install-complete").write_text(VERSION, encoding="utf-8")
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
    client_settings = settings.with_name("client-settings.json")
    if not client_settings.exists():
        _ = client_settings.write_bytes(
            SCRIPT.with_name("client-settings.json").read_bytes()
        )
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
        env={
            **os.environ,
            "HOME": str(home.parent),
            "T3CODE_HOME": str(home),
            "PATH": path,
        },
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


def completed_runtime(versions: Path, name: str, modified: int = 0) -> Path:
    runtime = versions / name
    runtime.mkdir()
    _ = (runtime / ".install-complete").write_text(f"{name}\n", encoding="utf-8")
    os.utime(runtime, (modified, modified))
    return runtime


@pytest.mark.parametrize("update", [None, "pending", {}, {"status": "completed"}])
def test_prune_keeps_active_and_newest_other_runtime(
    tmp_path: Path, declared: Path, update: Json
) -> None:
    home = make_home(tmp_path, busy_status=None)
    versions = home / "runtime" / "versions"
    for name, modified in (("newest", 300), ("old", 100), ("middle", 200)):
        runtime = versions / name
        runtime.mkdir()
        _ = (runtime / ".install-complete").write_text(name, encoding="utf-8")
        _ = (runtime / "t3").write_text("runtime", encoding="utf-8")
        os.utime(runtime, (modified, modified))
    os.utime(versions / VERSION, (0, 0))
    note = versions / "note.txt"
    _ = note.write_text("keep", encoding="utf-8")
    _ = (home / "runtime" / "service-state.json").write_text(
        json.dumps({"activeVersion": VERSION, "update": update}), encoding="utf-8"
    )
    settings = (home / "userdata" / "settings.json").read_bytes()
    result = run(home, UNREACHABLE, "prune", declared)
    assert result.returncode == 0, result.stderr
    assert {path.name for path in versions.iterdir()} == {VERSION, "newest", "note.txt"}
    assert "removed runtime old" in result.stdout
    assert "removed runtime middle" in result.stdout
    assert (versions / "newest" / "t3").read_text(encoding="utf-8") == "runtime"
    assert note.read_text(encoding="utf-8") == "keep"
    assert (home / "userdata" / "settings.json").read_bytes() == settings
    assert not (tmp_path / "t3.log").exists()
    again = run(home, UNREACHABLE, "prune", declared)
    assert again.returncode == 0, again.stderr
    assert not again.stdout


@pytest.mark.parametrize(
    "state",
    [None, "not json", "[]", "{}", '{"activeVersion":7}', '{"activeVersion":""}'],
)
def test_prune_leaves_runtimes_without_a_valid_active_version(
    tmp_path: Path, declared: Path, state: str | None
) -> None:
    home = make_home(tmp_path, busy_status=None)
    versions = home / "runtime" / "versions"
    _ = completed_runtime(versions, "old")
    _ = completed_runtime(versions, "newest")
    state_path = home / "runtime" / "service-state.json"
    if state is None:
        state_path.unlink()
    else:
        _ = state_path.write_text(state, encoding="utf-8")
    (home / "userdata" / "statev2.sqlite").unlink()
    result = run(home, UNREACHABLE, "prune", declared)
    assert result.returncode == 0, result.stderr
    assert "no active runtime" in result.stdout
    assert {path.name for path in versions.iterdir()} == {VERSION, "old", "newest"}


def test_prune_leaves_runtimes_while_an_update_is_pending(
    tmp_path: Path, declared: Path
) -> None:
    home = make_home(tmp_path, busy_status=None)
    versions = home / "runtime" / "versions"
    _ = completed_runtime(versions, "old")
    _ = completed_runtime(versions, "target")
    _ = (home / "runtime" / "service-state.json").write_text(
        json.dumps({
            "activeVersion": VERSION,
            "update": {"status": "pending", "targetVersion": "target"},
        }),
        encoding="utf-8",
    )
    (home / "userdata" / "statev2.sqlite").unlink()
    result = run(home, UNREACHABLE, "prune", declared)
    assert result.returncode == 0, result.stderr
    assert "update is pending" in result.stdout
    assert {path.name for path in versions.iterdir()} == {VERSION, "old", "target"}


@pytest.mark.parametrize(
    "status", ["queued", "preparing", "starting", "running", "waiting"]
)
def test_prune_postpones_while_a_thread_runs(
    tmp_path: Path, declared: Path, status: str
) -> None:
    home = make_home(tmp_path, busy_status=status)
    versions = home / "runtime" / "versions"
    _ = completed_runtime(versions, "old")
    _ = completed_runtime(versions, "newest")
    result = run(home, UNREACHABLE, "prune", declared)
    assert result.returncode == 0, result.stderr
    assert "postponing" in result.stdout
    assert {path.name for path in versions.iterdir()} == {VERSION, "old", "newest"}


def test_prune_refuses_when_busy_state_is_unreadable(
    tmp_path: Path, declared: Path
) -> None:
    home = make_home(tmp_path, busy_status=None)
    versions = home / "runtime" / "versions"
    _ = completed_runtime(versions, "old")
    _ = completed_runtime(versions, "newest")
    (home / "userdata" / "statev2.sqlite").unlink()
    result = run(home, UNREACHABLE, "prune", declared)
    assert result.returncode == 1
    assert "cannot tell whether threads run" in result.stdout
    assert {path.name for path in versions.iterdir()} == {VERSION, "old", "newest"}


@pytest.mark.parametrize("layout", ["missing", "empty", "active-only"])
def test_prune_handles_versions_without_a_rollback_runtime(
    tmp_path: Path, declared: Path, layout: str
) -> None:
    home = make_home(tmp_path, busy_status=None)
    versions = home / "runtime" / "versions"
    if layout != "active-only":
        (versions / VERSION / "t3").unlink()
        (versions / VERSION / ".install-complete").unlink()
        (versions / VERSION).rmdir()
    if layout == "missing":
        versions.rmdir()
    result = run(home, UNREACHABLE, "prune", declared)
    assert result.returncode == 0, result.stderr
    assert not result.stdout
    if layout == "missing":
        assert not versions.exists()
    else:
        assert {path.name for path in versions.iterdir()} == (
            {VERSION} if layout == "active-only" else set()
        )


@pytest.mark.parametrize(
    "unit_name",
    [
        "Library/LaunchAgents/com.t3tools.t3code.service.plist",
        ".config/systemd/user/t3code.service",
    ],
)
def test_prune_protects_all_service_unit_runtimes(
    tmp_path: Path, declared: Path, unit_name: str
) -> None:
    home = make_home(tmp_path, busy_status=None)
    versions = home / "runtime" / "versions"
    for name, modified in (
        ("installed", 500),
        ("referenced", 400),
        ("rollback", 300),
        ("obsolete", 200),
    ):
        _ = completed_runtime(versions, name, modified)
    unit = tmp_path / unit_name
    unit.parent.mkdir(parents=True)
    _ = unit.write_text(
        "\n".join([
            f"<string>{versions}/installed/t3</string>",
            f'ExecStart="{versions}/referenced/t3" __service-launcher',
        ]),
        encoding="utf-8",
    )
    result = run(home, UNREACHABLE, "prune", declared)
    assert result.returncode == 0, result.stderr
    assert {path.name for path in versions.iterdir()} == {
        VERSION,
        "installed",
        "referenced",
        "rollback",
    }


@pytest.mark.parametrize(
    "kind",
    [
        "symlink",
        "relative",
        "shim",
        "path",
        "custom",
        "outside",
        "binary",
        "dangling",
        "runtime-binary",
    ],
)
def test_prune_protects_launcher_runtime(
    tmp_path: Path, declared: Path, monkeypatch: pytest.MonkeyPatch, kind: str
) -> None:
    home = make_home(tmp_path, busy_status=None)
    versions = home / "runtime" / "versions"
    for name, modified in (("launcher", 300), ("rollback", 200), ("obsolete", 100)):
        runtime = completed_runtime(versions, name, modified)
        _ = (runtime / "t3").write_text("runtime", encoding="utf-8")
        (runtime / "t3").chmod(0o755)
        os.utime(runtime, (modified, modified))
    bin_dir = tmp_path / ("bin" if kind in {"path", "custom"} else ".local/bin")
    bin_dir.mkdir(parents=True)
    launcher = bin_dir / "t3"
    target = versions / "launcher/t3"
    if kind == "runtime-binary":
        _ = target.write_bytes(b"\xff")
    elif kind == "shim":
        _ = launcher.write_text(f'#!/bin/sh\nexec "{target}" "$@"\n', encoding="utf-8")
    elif kind == "binary":
        _ = launcher.write_bytes(b"\xff")
    else:
        if kind == "relative":
            target = Path(os.path.relpath(target, bin_dir))
        elif kind == "outside":
            target = tmp_path / "other-runtime/t3"
        elif kind == "dangling":
            target = versions / "missing/t3"
        launcher.symlink_to(target)
    if kind == "custom":
        monkeypatch.setenv("T3CODE_INSTALL_BIN_DIR", str(bin_dir))
    search_dir = (
        target.parent
        if kind == "runtime-binary"
        else bin_dir
        if kind == "path"
        else None
    )
    result = run(
        home,
        UNREACHABLE,
        "prune",
        declared,
        search_dir,
    )
    assert result.returncode == 0, result.stderr
    expected = (
        {VERSION, "launcher", "rollback"}
        if kind in {"symlink", "relative", "shim", "path", "custom", "runtime-binary"}
        else {VERSION, "launcher"}
    )
    assert {path.name for path in versions.iterdir()} == expected


@pytest.mark.parametrize("kind", ["directory", "unreadable", "fifo"])
def test_prune_skips_invalid_completion_markers(
    tmp_path: Path, declared: Path, kind: str
) -> None:
    home = make_home(tmp_path, busy_status=None)
    versions = home / "runtime" / "versions"
    _ = completed_runtime(versions, "rollback", 200)
    _ = completed_runtime(versions, "obsolete", 100)
    runtime = completed_runtime(versions, "invalid", 300)
    marker = runtime / ".install-complete"
    if kind == "unreadable":
        marker.chmod(0o000)
    else:
        marker.unlink()
        if kind == "directory":
            marker.mkdir()
        else:
            os.mkfifo(marker)
    try:
        result = run(home, UNREACHABLE, "prune", declared)
    finally:
        marker.chmod(0o700)
    assert result.returncode == 0, result.stderr
    assert {path.name for path in versions.iterdir()} == {
        VERSION,
        "rollback",
        "invalid",
    }


@pytest.mark.parametrize(
    "reference_name",
    [
        "Library/LaunchAgents/com.t3tools.t3code.service.plist",
        ".config/systemd/user/t3code.service",
        ".local/bin/t3",
    ],
)
@pytest.mark.parametrize("kind", ["directory", "unreadable"])
def test_prune_refuses_when_runtime_references_are_unreadable(
    tmp_path: Path, declared: Path, reference_name: str, kind: str
) -> None:
    home = make_home(tmp_path, busy_status=None)
    versions = home / "runtime" / "versions"
    _ = completed_runtime(versions, "rollback", 200)
    _ = completed_runtime(versions, "obsolete", 100)
    reference = tmp_path / reference_name
    reference.parent.mkdir(parents=True)
    if kind == "directory":
        reference.mkdir()
    else:
        _ = reference.write_text(f"{versions}/obsolete/t3", encoding="utf-8")
        reference.chmod(0o000)
    try:
        result = run(home, UNREACHABLE, "prune", declared)
    finally:
        reference.chmod(0o700)
    assert result.returncode == 1
    assert "cannot read runtime references" in result.stdout
    assert "not pruning" in result.stdout
    assert {path.name for path in versions.iterdir()} == {
        VERSION,
        "rollback",
        "obsolete",
    }


def test_prune_ignores_incomplete_hidden_and_symlink_entries(
    tmp_path: Path, declared: Path
) -> None:
    home = make_home(tmp_path, busy_status=None)
    versions = home / "runtime" / "versions"
    _ = completed_runtime(versions, "rollback", 200)
    _ = completed_runtime(versions, "obsolete", 100)
    _ = completed_runtime(versions, ".staging-complete", 900)
    for name in (".staging-pending", "incomplete", "mismatch", "non-text"):
        runtime = versions / name
        runtime.mkdir()
        if name == "mismatch":
            _ = (runtime / ".install-complete").write_text("other", encoding="utf-8")
        elif name == "non-text":
            _ = (runtime / ".install-complete").write_bytes(b"\xff")
        os.utime(runtime, (800, 800))
    outside = tmp_path / "outside"
    outside.mkdir()
    _ = (outside / ".install-complete").write_text("linked", encoding="utf-8")
    (versions / "linked").symlink_to(outside, target_is_directory=True)
    (versions / "dangling").symlink_to(tmp_path / "missing", target_is_directory=True)
    result = run(home, UNREACHABLE, "prune", declared)
    assert result.returncode == 0, result.stderr
    assert {path.name for path in versions.iterdir()} == {
        VERSION,
        "rollback",
        ".staging-complete",
        ".staging-pending",
        "incomplete",
        "mismatch",
        "non-text",
        "linked",
        "dangling",
    }
    assert (outside / ".install-complete").read_text(encoding="utf-8") == "linked"
    assert (versions / "linked").is_symlink()
    assert (versions / "dangling").is_symlink()


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


@pytest.mark.parametrize("wrapped", [False, True])
def test_sync_applies_desktop_settings_and_preserves_device_preferences(
    tmp_path: Path, gateway: str, declared: Path, *, wrapped: bool
) -> None:
    home = make_home(tmp_path, busy_status=None)
    target = home / "userdata" / "client-settings.json"
    preferences: dict[str, Json] = {
        "followUpBehavior": "queue",
        "sendShortcut": "enter",
        "fontSizePrompt": 18,
    }
    document: dict[str, Json] = (
        {"settings": preferences, "version": 1} if wrapped else preferences
    )
    _ = target.write_text(json.dumps(document), encoding="utf-8")
    result = run(home, gateway, "sync", declared)
    assert result.returncode == 0, result.stderr
    saved = obj(cast("Json", json.loads(target.read_text(encoding="utf-8"))))
    client = obj(saved["settings"]) if wrapped else saved
    expected = obj(
        cast(
            "Json",
            json.loads(
                SCRIPT.with_name("client-settings.json").read_text(encoding="utf-8")
            ),
        )
    )
    assert client == expected | {"fontSizePrompt": 18}
    if wrapped:
        assert saved["version"] == 1
    assert "followUpBehavior" not in obj(live_settings(home))
    assert not (tmp_path / "t3.log").exists()


@pytest.mark.parametrize("command", ["sync", "update"])
def test_commands_create_desktop_preferences_when_missing(
    tmp_path: Path, gateway: str, declared: Path, command: str
) -> None:
    home = make_home(tmp_path, busy_status=None)
    result = run(home, gateway, command, declared)
    assert result.returncode == 0, result.stderr
    target = home / "userdata" / "client-settings.json"
    assert json.loads(target.read_text(encoding="utf-8")) == json.loads(
        SCRIPT.with_name("client-settings.json").read_text(encoding="utf-8")
    )


@pytest.mark.parametrize("content", ["not json", "[]", '{"settings":null}'])
def test_sync_preserves_invalid_desktop_preferences(
    tmp_path: Path, gateway: str, declared: Path, content: str
) -> None:
    home = make_home(tmp_path, busy_status=None)
    target = home / "userdata" / "client-settings.json"
    _ = target.write_text(content, encoding="utf-8")
    result = run(home, gateway, "sync", declared)
    assert result.returncode == 1
    assert str(target) in result.stderr
    assert "not a JSON object" in result.stderr
    assert target.read_text(encoding="utf-8") == content


def test_sync_rejects_invalid_client_declaration(
    tmp_path: Path, gateway: str, declared: Path
) -> None:
    home = make_home(tmp_path, busy_status=None)
    source = tmp_path / "client-settings.json"
    _ = source.write_text("[]", encoding="utf-8")
    result = run(home, gateway, "sync", declared)
    assert result.returncode == 1
    assert f"{source} is not a JSON object" in result.stderr
    assert not (home / "userdata" / "client-settings.json").exists()


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
