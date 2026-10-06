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
from datetime import UTC, datetime, timedelta
from pathlib import Path

LOG_TAIL_BYTES = 4 * 1024 * 1024
AMP_IDLE = timedelta(minutes=15)
AMP_STUCK = timedelta(minutes=120)
PASEO_BUSY = frozenset({"initializing", "running"})


def say(message: str) -> None:
    sys.stdout.write(f"idle-restart: {message}\n")
    sys.stdout.flush()


def run(*argv: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(  # noqa: S603 - fixed argv
        list(argv), capture_output=True, text=True, check=False, timeout=600
    )


def wrapper_version(wrapper: str) -> str | None:
    """First token of the last line of `--version`, after warnings."""
    lines = [line for line in run(wrapper, "--version").stdout.splitlines() if line.strip()]
    token = lines[-1].split()[0].removeprefix("v") if lines else ""
    return token if token[:1].isdigit() else None


def json_of(text: str) -> object:
    try:
        return json.loads(text)
    except ValueError:
        return None


def main_pid(service: str) -> str | None:
    if sys.platform == "darwin":
        listing = run("launchctl", "print", f"gui/{os.getuid()}/{service}").stdout
        pids = [line.split("=", 1)[1].strip() for line in listing.splitlines() if line.strip().startswith("pid =")]
        pid = pids[0] if pids else ""
    else:
        pid = run("systemctl", "--user", "show", service, "-p", "MainPID", "--value").stdout.strip()
    return pid if pid.isdigit() and pid != "0" else None


def paseo_running(wrapper: str, _service: str) -> str | None:
    status = json_of(run(wrapper, "daemon", "status", "--json").stdout)
    if not isinstance(status, dict) or status.get("localDaemon") != "running":
        return None
    version = status.get("daemonVersion")
    return version if isinstance(version, str) and version else None


def amp_running(_wrapper: str, service: str) -> str | None:
    """The version directory of the runner's executable."""
    pid = main_pid(service)
    if pid is None:
        return None
    if sys.platform == "darwin":
        names = run("lsof", "-n", "-w", "-a", "-p", pid, "-d", "txt", "-Fn").stdout
        exe = next((Path(line[1:]) for line in names.splitlines() if line.startswith("n")), None)
    else:
        try:
            exe = Path(f"/proc/{pid}/exe").readlink()
        except OSError:
            exe = None
    parts = exe.parts if exe else ()
    return parts[parts.index("versions") + 1] if "versions" in parts[:-1] else None


def paseo_busy(wrapper: str, _log: Path | None) -> bool:
    """Any agent initializing or running; an unreadable listing counts as busy."""
    listing = run(wrapper, "agent", "ls", "--global", "--json")
    agents = json_of(listing.stdout)
    if listing.returncode != 0 or not isinstance(agents, list):
        return True
    return any(not isinstance(agent, dict) or agent.get("status") in PASEO_BUSY for agent in agents)


def amp_busy(_wrapper: str, log: Path | None) -> bool:
    """Recent thread activity or an unfinished turn; an unreadable log counts as busy."""
    if log is None:
        return True
    try:
        with log.open("rb") as handle:
            handle.seek(max(0, log.stat().st_size - LOG_TAIL_BYTES))
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
            seen[thread] = datetime.fromisoformat(stamp)
        except ValueError:
            continue
        if event.get("message") == "[observer] onAgentState":
            state[thread] = str(event.get("subtype"))
    return any(
        now - at < AMP_IDLE or (state.get(thread, "idle") != "idle" and now - at < AMP_STUCK)
        for thread, at in seen.items()
    )


KINDS = {"paseo": (paseo_running, paseo_busy), "amp": (amp_running, amp_busy)}


def restart(service: str) -> int:
    if sys.platform == "darwin":
        argv = ["launchctl", "kickstart", "-k", f"gui/{os.getuid()}/{service}"]
    else:
        argv = ["systemctl", "--user", "restart", service]
    return subprocess.call(argv)  # noqa: S603 - fixed service manager argv


def main() -> int:
    parser = argparse.ArgumentParser(prog="idle-restart")
    parser.add_argument("--kind", required=True, choices=sorted(KINDS))
    parser.add_argument("--service", required=True, help="systemd unit or launchd label")
    parser.add_argument("--wrapper", required=True)
    parser.add_argument("--log-file", type=Path, help="runner log for --kind amp")
    args = parser.parse_args()
    running_of, busy = KINDS[args.kind]
    wrapper: str = args.wrapper
    service: str = args.service

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
    say(f"restarting {service}: {running} -> {latest}")
    if restart(service) != 0:
        return 1
    for _ in range(30):
        time.sleep(2)
        if running_of(wrapper, service) == latest:
            say(f"{service} running {latest}")
            return 0
    say(f"{service} did not come back on {latest}")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
