"""Behavior of the scratch cleaner rules."""

from __future__ import annotations

import importlib.util
import os
import shutil
import socket
import subprocess
import sys
import tempfile
import time
from pathlib import Path
from typing import Protocol, cast


class Scratch(Protocol):
    """The parts of scratch.py these tests call."""

    def clean_scratch(self, root: Path, *, days: int, dry_run: bool) -> None: ...

    def stale_scratch(self, root: Path, uid: int, cutoff: float) -> list[Path]: ...

    def size_mb(self, path: Path) -> int: ...

    def newest_mtime(self, path: Path) -> float: ...


SCRIPT = Path(__file__).parents[1] / "scratch.py"
spec = importlib.util.spec_from_file_location("scratch", SCRIPT)
assert spec is not None
assert spec.loader is not None
scratch = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = scratch
spec.loader.exec_module(scratch)

# The module was just executed from scratch.py, which defines these functions.
gc = cast("Scratch", cast("object", scratch))
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


def _run_cli(*args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(  # noqa: S603 - fixed argv
        [sys.executable, str(SCRIPT), *args],
        capture_output=True,
        text=True,
        check=False,
        env=dict(os.environ),
    )


def test_cli_dry_run_reports_stale_entries_and_keeps_them(tmp_path: Path) -> None:
    """The command line lists what it would remove without touching it."""
    stale = tmp_path / "old"
    stale.mkdir()
    _age(stale)
    result = _run_cli("--root", str(tmp_path), "--dry-run")
    assert result.returncode == 0
    assert f"scratch: would remove {stale}" in result.stdout
    assert f"scratch: {tmp_path}: 1 entries idle >7d" in result.stdout
    assert stale.is_dir()


def test_cli_removes_stale_symlinks_and_honours_scratch_days(tmp_path: Path) -> None:
    """A stale symlink is unlinked, not followed; --scratch-days moves the cutoff."""
    target = tmp_path / "target"
    target.mkdir()
    link = tmp_path / "link"
    link.symlink_to(target)
    os.utime(link, (OLD, OLD), follow_symlinks=False)
    young = tmp_path / "young"
    young.mkdir()
    _age(young, time.time() - 3 * 86400)
    assert _run_cli("--root", str(tmp_path), "--scratch-days", "60").returncode == 0
    assert link.is_symlink()
    result = _run_cli("--root", str(tmp_path), "--scratch-days", "2")
    assert result.returncode == 0
    assert not link.is_symlink()
    assert not young.exists()
    assert target.is_dir()
    assert "idle >2d" in result.stdout


def test_cli_missing_root_reports_nothing_to_clean(tmp_path: Path) -> None:
    """An unreadable root is an empty scratch area, not a failure."""
    result = _run_cli("--root", str(tmp_path / "absent"))
    assert result.returncode == 0
    assert "0 entries idle >7d, ~0M" in result.stdout


def test_unreadable_entries_are_skipped_without_failing(tmp_path: Path) -> None:
    """Entries that cannot be inspected are never candidates and never crash."""
    locked = tmp_path / "locked"
    inner = locked / "inner"
    inner.mkdir(parents=True)
    _age(locked)
    locked.chmod(0o444)
    try:
        assert gc.stale_scratch(tmp_path, os.getuid(), time.time()) == [locked]
        assert gc.size_mb(locked) == 0
        tmp_path.chmod(0o444)
        assert gc.stale_scratch(tmp_path, os.getuid(), time.time()) == []
    finally:
        tmp_path.chmod(0o755)
        locked.chmod(0o755)


def test_newest_mtime_of_a_vanished_entry_counts_as_fresh(tmp_path: Path) -> None:
    """An entry that disappears mid-scan is treated as fresh, never stale."""
    before = time.time()
    assert gc.newest_mtime(tmp_path / "gone") >= before


def test_entry_refreshed_after_its_stat_is_not_reported_stale(tmp_path: Path) -> None:
    """A refresh between the ownership stat and the age check keeps the entry."""
    cutoff = time.time() - 7 * 86400
    path = tmp_path / "report.json"
    _ = path.write_text("{}", encoding="utf-8")
    _age(path)
    info = path.lstat()
    assert info.st_mtime < cutoff
    os.utime(path, None)
    assert gc.newest_mtime(path) >= cutoff
    assert gc.stale_scratch(tmp_path, os.getuid(), cutoff) == []


def test_size_mb_counts_allocated_blocks(tmp_path: Path) -> None:
    """Large files contribute their allocated size in MiB."""
    big = tmp_path / "big"
    _ = big.write_bytes(b"x" * (3 * 1024 * 1024))
    assert gc.size_mb(tmp_path) >= 3
