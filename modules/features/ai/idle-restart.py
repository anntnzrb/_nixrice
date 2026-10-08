"""Restart a wrapper-launched service onto the wrapper's newest release when idle.

An agents-managed wrapper installs the newest release whenever it runs, but a
long-running service keeps the release it started with until it restarts.
Each service module supplies how to read its running version and whether it
has work in flight; this job restarts the service only when the wrapper
reports a different version and the service is idle.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import time
from collections.abc import Callable
from datetime import UTC, datetime, timedelta
from pathlib import Path
from typing import cast

type Json = str | int | float | bool | list[Json] | dict[str, Json] | None
type Running = Callable[[str, str], str | None]
type Busy = Callable[[str, Path | None], bool]

LOG_TAIL_BYTES = 4 * 1024 * 1024
AMP_IDLE = timedelta(minutes=15)
AMP_STUCK = timedelta(minutes=120)
PASEO_BUSY = frozenset({"initializing", "running"})


def say(message: str) -> None:
    """Print one prefixed line to the job log."""
    _ = sys.stdout.write(f"idle-restart: {message}\n")
    _ = sys.stdout.flush()


def run(*argv: str) -> subprocess.CompletedProcess[str]:
    """Run a command and capture its text output.

    Returns:
        The completed process; a nonzero exit status is not an error.
    """
    return subprocess.run(  # noqa: S603 - fixed argv
        list(argv), capture_output=True, text=True, check=False, timeout=600
    )


def wrapper_version(wrapper: str) -> str | None:
    """Read the first token of the last line of `--version`, after warnings.

    Returns:
        The version number, or None when the wrapper printed none.
    """
    lines = [
        line for line in run(wrapper, "--version").stdout.splitlines() if line.strip()
    ]
    token = lines[-1].split()[0].removeprefix("v") if lines else ""
    return token if token[:1].isdigit() else None


def json_of(text: str) -> Json:
    """Parse JSON text.

    Returns:
        The parsed value, or None when the text is not valid JSON.
    """
    try:
        return cast("Json", json.loads(text))
    except ValueError:
        return None


def main_pid(service: str) -> str | None:
    """Look up the service manager's main PID for a service.

    Returns:
        The PID, or None when the service has no running main process.
    """
    if sys.platform == "darwin":
        listing = run("launchctl", "print", f"gui/{os.getuid()}/{service}").stdout
        pids = [
            line.split("=", 1)[1].strip()
            for line in listing.splitlines()
            if line.strip().startswith("pid =")
        ]
        pid = pids[0] if pids else ""
    else:
        pid = run(
            "systemctl", "--user", "show", service, "-p", "MainPID", "--value"
        ).stdout.strip()
    return pid if pid.isdigit() and pid != "0" else None


def paseo_running(wrapper: str, _service: str) -> str | None:
    """Ask the paseo daemon for its version.

    Returns:
        The version, or None when no local daemon is running.
    """
    status = json_of(run(wrapper, "daemon", "status", "--json").stdout)
    if not isinstance(status, dict) or status.get("localDaemon") != "running":
        return None
    version = status.get("daemonVersion")
    return version if isinstance(version, str) and version else None


def amp_running(_wrapper: str, service: str) -> str | None:
    """Find the version directory of the runner's executable.

    Returns:
        The version directory name, or None when it cannot be determined.
    """
    pid = main_pid(service)
    if pid is None:
        return None
    if sys.platform == "darwin":
        names = run("lsof", "-n", "-w", "-a", "-p", pid, "-d", "txt", "-Fn").stdout
        exe = next(
            (Path(line[1:]) for line in names.splitlines() if line.startswith("n")),
            None,
        )
    else:
        try:
            exe = Path(f"/proc/{pid}/exe").readlink()
        except OSError:
            exe = None
    parts = exe.parts if exe else ()
    return parts[parts.index("versions") + 1] if "versions" in parts[:-1] else None


def paseo_busy(wrapper: str, _log: Path | None) -> bool:
    """Check for agents initializing or running; an unreadable listing is busy.

    Returns:
        True when work may be in flight.
    """
    listing = run(wrapper, "agent", "ls", "--global", "--json")
    agents = json_of(listing.stdout)
    if listing.returncode != 0 or not isinstance(agents, list):
        return True
    return any(
        not isinstance(agent, dict) or agent.get("status") in PASEO_BUSY
        for agent in agents
    )


def amp_busy(_wrapper: str, log: Path | None) -> bool:
    """Check for recent thread activity or an unfinished turn.

    An unreadable log counts as busy, and so does a timestamp without an offset.

    Returns:
        True when work may be in flight.
    """
    if log is None:
        return True
    try:
        with log.open("rb") as handle:
            _ = handle.seek(max(0, log.stat().st_size - LOG_TAIL_BYTES))
            lines = handle.read().decode(errors="replace").splitlines()
    except OSError:
        return True
    now = datetime.now(UTC)
    seen: dict[str, datetime] = {}
    state: dict[str, str] = {}
    for line in lines:
        event = json_of(line)
        if not isinstance(event, dict):
            continue
        thread, stamp = event.get("threadId"), event.get("@timestamp")
        if not isinstance(thread, str) or not isinstance(stamp, str):
            continue
        try:
            at = datetime.fromisoformat(stamp)
        except ValueError:
            continue
        # A naive stamp cannot be compared with now; treat the instance as busy.
        if at.tzinfo is None:
            return True
        seen[thread] = at
        if event.get("message") == "[observer] onAgentState":
            state[thread] = str(event.get("subtype"))
    return any(
        now - at < AMP_IDLE
        or (state.get(thread, "idle") != "idle" and now - at < AMP_STUCK)
        for thread, at in seen.items()
    )


KINDS: dict[str, tuple[Running, Busy]] = {
    "paseo": (paseo_running, paseo_busy),
    "amp": (amp_running, amp_busy),
}


def restart(service: str) -> int:
    """Restart the service through the platform's service manager.

    Returns:
        The service manager's exit status.
    """
    if sys.platform == "darwin":
        argv = ["launchctl", "kickstart", "-k", f"gui/{os.getuid()}/{service}"]
    else:
        argv = ["systemctl", "--user", "restart", service]
    return subprocess.call(argv)  # noqa: S603 - fixed service manager argv


def came_back(running_of: Running, wrapper: str, service: str, latest: str) -> bool:
    """Poll for up to a minute until the service reports the new version.

    Returns:
        True when the service reported the new version.
    """
    for _ in range(30):
        time.sleep(2)
        if running_of(wrapper, service) == latest:
            return True
    return False


def restart_and_wait(
    running_of: Running, wrapper: str, service: str, versions: tuple[str, str]
) -> int:
    """Restart the service and confirm it came back on the newest release.

    Returns:
        The process exit status.
    """
    running, latest = versions
    say(f"restarting {service}: {running} -> {latest}")
    if restart(service) != 0:
        return 1
    if came_back(running_of, wrapper, service, latest):
        say(f"{service} running {latest}")
        return 0
    say(f"{service} did not come back on {latest}")
    return 1


class Args(argparse.Namespace):
    """Parsed command line."""

    kind: str = ""
    service: str = ""
    wrapper: str = ""
    log_file: Path | None = None


def main() -> int:
    """Run the command line.

    Returns:
        The process exit status.
    """
    parser = argparse.ArgumentParser(prog="idle-restart")
    _ = parser.add_argument("--kind", required=True, choices=sorted(KINDS))
    _ = parser.add_argument(
        "--service", required=True, help="systemd unit or launchd label"
    )
    _ = parser.add_argument("--wrapper", required=True)
    _ = parser.add_argument("--log-file", type=Path, help="runner log for --kind amp")
    args = parser.parse_args(namespace=Args())
    running_of, busy = KINDS[args.kind]
    wrapper = args.wrapper
    service = args.service

    running = running_of(wrapper, service)
    if running is None:
        say(f"{service} is not running; nothing to update")
        return 0
    latest = wrapper_version(wrapper)
    if latest is None:
        say("could not resolve the newest release; not restarting")
        return 1
    if latest == running:
        say(f"{service} current at {running}")
        return 0
    if busy(wrapper, args.log_file):
        say(f"{service} has work in flight; postponing {running} -> {latest}")
        return 0
    return restart_and_wait(running_of, wrapper, service, (running, latest))


if __name__ == "__main__":
    raise SystemExit(main())
