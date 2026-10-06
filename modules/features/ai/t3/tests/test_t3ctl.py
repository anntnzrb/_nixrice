"""Behavior of t3ctl through its command line, against a temporary T3 home."""

from __future__ import annotations

import http.server
import json
import os
import sqlite3
import subprocess
import sys
import threading
from collections.abc import Iterator
from pathlib import Path

import pytest

SCRIPT = Path(__file__).parents[1] / "t3ctl.py"
VERSION = "0.0.1-nightly.1"


@pytest.fixture
def gateway() -> Iterator[str]:
    catalog = {
        "data": [
            {"id": "gpt-x", "display_name": "GPT X", "owned_by": "openai"},
            {"id": "claude-y", "owned_by": "anthropic"},
        ]
    }

    class Handler(http.server.BaseHTTPRequestHandler):
        def do_GET(self) -> None:
            body = json.dumps(catalog).encode()
            self.send_response(200)
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def log_message(self, *_args: object) -> None:
            pass

    server = http.server.HTTPServer(("127.0.0.1", 0), Handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    yield f"http://127.0.0.1:{server.server_port}/v1"
    server.shutdown()


def make_home(root: Path, *, busy_status: str | None) -> Path:
    """A T3 home with an installed runtime whose `t3` records its arguments."""
    home = root / ".t3"
    version_dir = home / "runtime" / "versions" / VERSION
    version_dir.mkdir(parents=True)
    log = root / "t3.log"
    binary = version_dir / "t3"
    binary.write_text(f'#!/bin/sh\necho "$@" >> {log}\n', encoding="utf-8")
    binary.chmod(0o755)
    (home / "runtime" / "service-state.json").write_text(
        json.dumps({"activeVersion": VERSION}), encoding="utf-8"
    )
    userdata = home / "userdata"
    userdata.mkdir()
    (userdata / "settings.json").write_text(
        json.dumps(
            {
                "uiOnly": "kept",
                "storageCleanup": {"logsAfterDays": 7, "worktreeOnMerge": False},
                "providerInstances": {
                    "claudeAgent": {"driver": "claudeAgent", "enabled": True}
                },
            }
        ),
        encoding="utf-8",
    )
    with sqlite3.connect(userdata / "statev2.sqlite") as conn:
        conn.execute(
            "CREATE TABLE orchestration_v2_projection_runs (thread_id TEXT, status TEXT)"
        )
        conn.execute("INSERT INTO orchestration_v2_projection_runs VALUES ('a', 'completed')")
        if busy_status is not None:
            conn.execute(
                "INSERT INTO orchestration_v2_projection_runs VALUES ('b', ?)",
                (busy_status,),
            )
    return home


def run(home: Path, gateway: str, command: str, settings: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
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
            "--wrapper",
            "claudeAgent=/wrappers/claude",
        ],
        env={**os.environ, "T3CODE_HOME": str(home)},
        capture_output=True,
        text=True,
        check=False,
    )


@pytest.fixture
def declared(tmp_path: Path) -> Path:
    path = tmp_path / "declared.json"
    path.write_text(
        json.dumps({"storageCleanup": {"worktreeOnMerge": True, "worktreeAfterDays": 30}}),
        encoding="utf-8",
    )
    return path


def live_settings(home: Path) -> dict[str, object]:
    return json.loads((home / "userdata" / "settings.json").read_text(encoding="utf-8"))


def test_update_merges_settings_and_restarts_through_t3_when_idle(
    tmp_path: Path, gateway: str, declared: Path
) -> None:
    home = make_home(tmp_path, busy_status=None)
    result = run(home, gateway, "update", declared)
    assert result.returncode == 0, result.stderr

    live = live_settings(home)
    assert live["uiOnly"] == "kept"
    assert live["storageCleanup"] == {
        "logsAfterDays": 7,
        "worktreeOnMerge": True,
        "worktreeAfterDays": 30,
    }
    claude = live["providerInstances"]["claudeAgent"]["config"]  # type: ignore[index]
    assert claude["binaryPath"] == "/wrappers/claude"
    assert claude["customModels"] == [{"slug": "gpt-x", "name": "GPT X"}]
    assert (tmp_path / "t3.log").read_text(encoding="utf-8") == "update --yes --channel nightly\n"


@pytest.mark.parametrize("status", ["queued", "running", "waiting"])
def test_update_postpones_while_a_thread_runs(
    tmp_path: Path, gateway: str, declared: Path, status: str
) -> None:
    home = make_home(tmp_path, busy_status=status)
    result = run(home, gateway, "update", declared)
    assert result.returncode == 0, result.stderr
    assert "postponing" in result.stdout
    assert not (tmp_path / "t3.log").exists()
    assert live_settings(home)["storageCleanup"]["worktreeAfterDays"] == 30  # type: ignore[index]


def test_refresh_models_before_install_is_a_no_op(
    tmp_path: Path, gateway: str, declared: Path
) -> None:
    result = run(tmp_path / ".t3", gateway, "refresh-models", declared)
    assert result.returncode == 0
    assert "not installed" in result.stdout
