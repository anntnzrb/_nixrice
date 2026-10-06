"""Restart the Paseo daemon onto the newest release while no agent is mid-turn.

The `paseo` wrapper installs the newest release whenever it runs, but the
daemon keeps the version it started with until it restarts.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path

BUSY_STATUSES = frozenset({"initializing", "running"})


def say(message: str) -> None:
    sys.stdout.write(f"paseo-update: {message}\n")
    sys.stdout.flush()


def run_paseo(wrapper: Path, *args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(  # noqa: S603 - fixed wrapper path
        [str(wrapper), *args], capture_output=True, text=True, check=False, timeout=600
    )


def parse_json(text: str) -> object:
    try:
        return json.loads(text)
    except ValueError:
        return None


def daemon_version(status: str) -> str | None:
    """`daemonVersion` from `paseo daemon status --json` while it runs."""
    fields = parse_json(status)
    if not isinstance(fields, dict) or fields.get("localDaemon") != "running":
        return None
    version = fields.get("daemonVersion")
    return version if isinstance(version, str) and version else None


def cli_version(output: str) -> str | None:
    """Last token of `paseo --version`, ignoring wrapper warnings before it."""
    lines = [line.strip() for line in output.splitlines() if line.strip()]
    if not lines:
        return None
    token = lines[-1].split()[-1].removeprefix("v")
    return token if token[:1].isdigit() else None


def busy(listing: str) -> bool:
    """True if any agent is mid-turn or the listing cannot be read."""
    agents = parse_json(listing)
    if not isinstance(agents, list):
        return True
    return any(
        not isinstance(agent, dict) or agent.get("status") in BUSY_STATUSES
        for agent in agents
    )


def restart(service: str) -> int:
    if sys.platform == "darwin":
        argv = ["launchctl", "kickstart", "-k", f"gui/{os.getuid()}/{service}"]
    else:
        argv = ["systemctl", "--user", "restart", service]
    return subprocess.call(argv)  # noqa: S603 - fixed service manager argv


def main() -> int:
    parser = argparse.ArgumentParser(prog="paseo-update")
    parser.add_argument("--service", required=True, help="systemd unit or launchd label")
    parser.add_argument("--wrapper", required=True, type=Path)
    args = parser.parse_args()
    wrapper: Path = args.wrapper

    running = daemon_version(run_paseo(wrapper, "daemon", "status", "--json").stdout)
    if running is None:
        say("the daemon is not running; nothing to update")
        return 0
    version = run_paseo(wrapper, "--version")
    latest = cli_version(version.stdout) if version.returncode == 0 else None
    if latest is None:
        say("could not resolve the newest release; not restarting")
        return 1
    if latest == running:
        say(f"current at {running}")
        return 0
    listing = run_paseo(wrapper, "agent", "ls", "--global", "--json")
    if listing.returncode != 0 or busy(listing.stdout):
        say(f"agents are mid-turn; postponing {running} -> {latest}")
        return 0
    say(f"restarting {running} -> {latest}")
    return restart(args.service)


if __name__ == "__main__":
    raise SystemExit(main())
