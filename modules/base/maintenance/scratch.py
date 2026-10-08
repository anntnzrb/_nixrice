"""Remove stale top-level /tmp entries this user owns."""

from __future__ import annotations

import argparse
import contextlib
import os
import shutil
import stat
import sys
import time
from pathlib import Path

SCRATCH_DAYS = 7
SCRATCH_ROOT = Path("/tmp")  # noqa: S108 - the directory being cleaned, not a temp file
# Live runtime state that other processes find by name; never removed.
KEEP_PREFIXES = (
    ".",
    "tmux-",
    "zellij-",
    "systemd-private-",
    "ssh-",
    "com.apple.",
    "launchd-",
    "nix-",
)


class Args(argparse.Namespace):
    """Parsed command line."""

    dry_run: bool = False
    scratch_days: int = SCRATCH_DAYS
    root: Path = SCRATCH_ROOT


def say(message: str) -> None:
    """Report one line to the service log."""
    print(f"scratch: {message}", flush=True)


def size_mb(path: Path) -> int:
    """Measure a tree, ignoring unreadable entries.

    Returns:
        The allocated size in MiB.
    """
    total = 0
    for root, _dirs, files in os.walk(path, onerror=lambda _e: None):
        for name in files:
            with contextlib.suppress(OSError):
                total += (Path(root) / name).lstat().st_blocks * 512
    return total // (1024 * 1024)


def newest_mtime(path: Path) -> float:
    """Find the newest modification time of an entry and everything beneath it.

    The entry is statted again here, so a refresh after the ownership check
    counts. A vanished entry counts as fresh and is never deleted.

    Returns:
        The modification time as seconds since the epoch.
    """
    try:
        info = path.lstat()
    except OSError:
        return time.time()
    newest = info.st_mtime
    if not stat.S_ISDIR(info.st_mode):
        return newest
    for root, dirs, files in os.walk(path, onerror=lambda _e: None):
        for name in (*dirs, *files):
            with contextlib.suppress(OSError):
                newest = max(newest, (Path(root) / name).lstat().st_mtime)
    return newest


def stale_scratch(root: Path, uid: int, cutoff: float) -> list[Path]:
    """List top-level entries this user owns that went untouched since cutoff.

    Returns:
        The stale entries.
    """
    stale: list[Path] = []
    try:
        entries = list(root.iterdir())
    except OSError:
        return stale
    for entry in entries:
        # Lock files are flock targets; unlinking a held one breaks exclusion.
        if entry.name.startswith(KEEP_PREFIXES) or entry.name.endswith(".lock"):
            continue
        try:
            info = entry.lstat()
        except OSError:
            continue
        if info.st_uid != uid or stat.S_ISSOCK(info.st_mode):
            continue
        if newest_mtime(entry) < cutoff:
            stale.append(entry)
    return stale


def clean_scratch(
    root: Path = SCRATCH_ROOT,
    *,
    days: int = SCRATCH_DAYS,
    dry_run: bool = False,
) -> None:
    """Remove scratch entries idle for more than ``days`` days."""
    cutoff = time.time() - days * 86400
    stale = stale_scratch(root, os.getuid(), cutoff)
    freed = 0
    for entry in stale:
        freed += size_mb(entry) if entry.is_dir() else 0
        if dry_run:
            say(f"would remove {entry}")
            continue
        if entry.is_dir() and not entry.is_symlink():
            shutil.rmtree(entry, ignore_errors=True)
        else:
            with contextlib.suppress(OSError):
                entry.unlink()
    say(f"{root}: {len(stale)} entries idle >{days}d, ~{freed}M")


def main() -> int:
    """Run the command line.

    Returns:
        The process exit status.
    """
    parser = argparse.ArgumentParser(description="Reclaim stale scratch entries.")
    _ = parser.add_argument("--dry-run", action="store_true", help="report only")
    _ = parser.add_argument("--scratch-days", type=int)
    _ = parser.add_argument("--root", type=Path)
    args = parser.parse_args(namespace=Args())
    clean_scratch(args.root, days=args.scratch_days, dry_run=args.dry_run)
    return 0


if __name__ == "__main__":
    sys.exit(main())
