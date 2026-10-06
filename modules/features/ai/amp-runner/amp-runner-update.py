"""Restart the Amp runner onto the newest release while no thread is active.

The `amp` wrapper installs the newest release whenever it runs, but the runner
keeps the executable it started with until it restarts. Every release lives in
a directory named after its version, so the running executable's path tells
which version runs.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import time
from datetime import UTC, datetime, timedelta
from pathlib import Path

LOG_TAIL_BYTES = 4 * 1024 * 1024
IDLE = timedelta(minutes=15)
STUCK = timedelta(minutes=120)


def say(message: str) -> None:
    sys.stdout.write(f"amp-runner-update: {message}\n")
    sys.stdout.flush()


def output(*argv: str) -> str:
    return subprocess.run(  # noqa: S603 - fixed argv
        list(argv), capture_output=True, text=True, check=False, timeout=600
    ).stdout.strip()


def running_executable(service: str) -> Path | None:
    if sys.platform == "darwin":
        listing = output("launchctl", "print", f"gui/{os.getuid()}/{service}")
        pids = [line.split("=", 1)[1].strip() for line in listing.splitlines() if line.strip().startswith("pid =")]
        pid = pids[0] if pids else ""
        if not pid.isdigit():
            return None
        names = output("lsof", "-n", "-w", "-a", "-p", pid, "-d", "txt", "-Fn")
        paths = [line[1:] for line in names.splitlines() if line.startswith("n")]
        return Path(paths[0]) if paths else None
    pid = output("systemctl", "--user", "show", service, "-p", "MainPID", "--value")
    if not pid.isdigit() or pid == "0":
        return None
    try:
        return Path(f"/proc/{pid}/exe").readlink()
    except OSError:
        return None


def newest_version(wrapper: Path) -> str | None:
    """First token of the wrapper's `--version`, after it installs the newest release."""
    lines = output(str(wrapper), "--version").splitlines()
    tokens = lines[-1].split() if lines else []
    return tokens[0] if tokens else None


def busy_threads(log: Path, now: datetime) -> list[str]:
    """Threads with recent activity or an unfinished turn; raises OSError if unreadable."""
    with log.open("rb") as handle:
        handle.seek(max(0, log.stat().st_size - LOG_TAIL_BYTES))
        lines = handle.read().decode(errors="replace").splitlines()
    last_seen: dict[str, datetime] = {}
    last_state: dict[str, str] = {}
    for line in lines:
        try:
            event = json.loads(line)
        except ValueError:
            continue
        if not isinstance(event, dict):
            continue
        thread, stamp = event.get("threadId"), event.get("@timestamp")
        if not isinstance(thread, str) or not isinstance(stamp, str):
            continue
        try:
            last_seen[thread] = datetime.fromisoformat(stamp)
        except ValueError:
            continue
        if event.get("message") == "[observer] onAgentState":
            last_state[thread] = str(event.get("subtype"))
    return [
        thread
        for thread, seen in last_seen.items()
        if now - seen < IDLE or (last_state.get(thread, "idle") != "idle" and now - seen < STUCK)
    ]


def restart(service: str) -> int:
    if sys.platform == "darwin":
        argv = ["launchctl", "kickstart", "-k", f"gui/{os.getuid()}/{service}"]
    else:
        argv = ["systemctl", "--user", "restart", service]
    return subprocess.call(argv)  # noqa: S603 - fixed service manager argv


def main() -> int:
    parser = argparse.ArgumentParser(prog="amp-runner-update")
    parser.add_argument("--service", required=True, help="systemd unit or launchd label")
    parser.add_argument("--wrapper", required=True, type=Path)
    parser.add_argument("--log-file", required=True, type=Path)
    args = parser.parse_args()

    running = running_executable(args.service)
    if running is None:
        say("the runner is not running; nothing to update")
        return 0
    latest = newest_version(args.wrapper)
    if latest is None:
        say("could not resolve the newest release; not restarting")
        return 1
    if latest in running.parts:
        say(f"current at {latest}")
        return 0
    try:
        busy = busy_threads(args.log_file, datetime.now(UTC))
    except OSError as error:
        say(f"cannot read {args.log_file} ({error}); not restarting")
        return 1
    if busy:
        say(f"{len(busy)} thread(s) active; postponing restart onto {latest}")
        return 0
    say(f"restarting onto {latest}")
    if restart(args.service) != 0:
        return 1
    for _ in range(30):
        after = running_executable(args.service)
        if after is not None and latest in after.parts:
            say(f"running {latest}")
            return 0
        time.sleep(2)
    say(f"restart did not land on {latest}")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
