# ruff: noqa: S101 - pytest asserts
"""Behavior of the scratch cleaner rules."""

from __future__ import annotations

import importlib.util
import os
import shutil
import socket
import sys
import tempfile
import time
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "scratch",
    Path(__file__).parents[1] / "scratch.py",
)
if spec is None or spec.loader is None:
    raise ImportError("failed to locate scratch.py")
scratch = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = scratch
spec.loader.exec_module(scratch)

gc = scratch
OLD = time.time() - 30 * 86400


def _age(path: Path, when: float = OLD) -> None:
    for root, dirs, files in os.walk(path):
        for name in (*dirs, *files):
            os.utime(Path(root, name), (when, when), follow_symlinks=False)
    os.utime(path, (when, when), follow_symlinks=False)


def test_scratch_removes_only_entries_idle_past_the_cutoff(tmp_path: Path) -> None:
    """Idle entries go; a fresh write anywhere inside keeps the whole entry."""
    stale = tmp_path / "agents-ci-old"
    (stale / "deep").mkdir(parents=True)
    _ = (stale / "deep" / "log").write_text("x", encoding="utf-8")
    _age(stale)

    fresh_inside = tmp_path / "pytest-of-annt"
    (fresh_inside / "pytest-1").mkdir(parents=True)
    _age(fresh_inside)
    _ = (fresh_inside / "pytest-1" / "new").write_text("x", encoding="utf-8")

    old_file = tmp_path / "report.json"
    _ = old_file.write_text("{}", encoding="utf-8")
    _age(old_file)

    gc.clean_scratch(tmp_path, days=7, dry_run=False)

    assert not stale.exists()
    assert not old_file.exists()
    assert fresh_inside.is_dir(), "a recent write anywhere inside keeps the entry"


def test_scratch_keeps_runtime_state_and_sockets() -> None:
    """Runtime directories and sockets survive however old they are."""
    # macOS pytest paths exceed the AF_UNIX limit, so use a short root.
    tmp_path = Path(tempfile.mkdtemp(prefix="gc", dir="/tmp"))
    kept = [
        tmp_path / ".X11-unix",
        tmp_path / "tmux-1000",
        tmp_path / "systemd-private-abc-cliproxyapi.service-x",
        tmp_path / "nix-build-1",
    ]
    for path in kept:
        path.mkdir()
        _age(path)
    lock = tmp_path / "uv-28cc4b8c9dcd1219.lock"
    lock.touch()
    _age(lock)
    kept.append(lock)
    sock_path = tmp_path / "s"
    server = socket.socket(socket.AF_UNIX)
    server.bind(str(sock_path))
    try:
        os.utime(sock_path, (OLD, OLD))
        gc.clean_scratch(tmp_path, days=7, dry_run=False)
        assert sock_path.exists()
    finally:
        server.close()
    assert all(path.exists() for path in kept)
    shutil.rmtree(tmp_path)


def test_scratch_dry_run_removes_nothing(tmp_path: Path) -> None:
    """A dry run only reports."""
    stale = tmp_path / "old"
    stale.mkdir()
    _age(stale)
    gc.clean_scratch(tmp_path, days=7, dry_run=True)
    assert stale.is_dir()


def test_scratch_skips_entries_owned_by_another_user(tmp_path: Path) -> None:
    """Another user's files are never candidates."""
    stale = tmp_path / "old"
    stale.mkdir()
    _age(stale)
    assert gc.stale_scratch(tmp_path, os.getuid() + 1, time.time()) == []
