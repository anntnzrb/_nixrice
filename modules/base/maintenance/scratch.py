"""Remove stale top-level /tmp entries this user owns."""

from __future__ import annotations

import argparse
import contextlib
import os
import shutil
import stat
import time
from pathlib import Path

SCRATCH_DAYS = 7
SCRATCH_ROOT = Path("/tmp")
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


def say(message: str) -> None:
    """Report one line to the service log."""
    print(f"scratch: {message}", flush=True)


def size_mb(path: Path) -> int:
    """Return the allocated size of a tree in MiB, ignoring unreadable entries."""
    total = 0
    for root, _dirs, files in os.walk(path, onerror=lambda _e: None):
        for name in files:
            with contextlib.suppress(OSError):
                st = (Path(root) / name).lstat()
                blocks = getattr(st, "st_blocks", None)
                if blocks is not None:
                    total += blocks * 512
                else:
                    total += st.st_size
    return total // (1024 * 1024)


def newest_mtime(path: Path) -> float:
    """Newest modification time of an entry and everything beneath it."""
    try:
        newest = path.lstat().st_mtime
    except OSError:
        return time.time()
    if not path.is_dir() or path.is_symlink():
        return newest
    for root, dirs, files in os.walk(path, onerror=lambda _e: None):
        for name in (*dirs, *files):
            with contextlib.suppress(OSError):
                newest = max(newest, (Path(root) / name).lstat().st_mtime)
    return newest


def stale_scratch(root: Path, uid: int, cutoff: float) -> list[Path]:
    """List top-level entries this user owns that went untouched since cutoff."""
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
    """CLI entrypoint."""
    parser = argparse.ArgumentParser(description="Reclaim stale scratch entries.")
    parser.add_argument("--dry-run", action="store_true", help="report only")
    parser.add_argument("--scratch-days", type=int, default=SCRATCH_DAYS)
    parser.add_argument("--root", type=Path, default=SCRATCH_ROOT)
    args = parser.parse_args()
    clean_scratch(args.root, days=args.scratch_days, dry_run=args.dry_run)
    return 0


if __name__ == "__main__":
    import sys

    sys.exit(main())
