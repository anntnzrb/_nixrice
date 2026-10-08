"""Behavior of the idle-restart job, run end to end with fake service tooling."""

from __future__ import annotations

import json
import os
import shutil
import stat
import subprocess
import sys
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from pathlib import Path
from typing import TYPE_CHECKING

import pytest

if TYPE_CHECKING:
    from collections.abc import Iterator

SCRIPT = Path(__file__).parents[1] / "idle-restart.py"
SERVICE = "svc.service"
FAKE = """#!/bin/sh
d=$FAKE_DIR
key=$(basename "$0")
for a in "$@"; do key="$key.$a"; done
key=$(printf '%s' "$key" | tr / _)
echo "$(basename "$0") $*" >> "$d/calls"
case "$key" in *restart*|*kickstart*) : > "$d/restarted" ;; esac
f="$d/$key.out"
if [ -e "$d/restarted" ] && [ -e "$d/$key.after" ]; then f="$d/$key.after"; fi
if [ -e "$f" ]; then cat "$f"; fi
if [ -e "$d/$key.rc" ]; then exit "$(cat "$d/$key.rc")"; fi
exit 0
"""
# Run the real script with the platform and the clock faked at the edge.
LAUNCHER = """
import argparse, datetime, json, os, pathlib, runpy, subprocess, sys, time
sys.platform = sys.argv[1]
time.sleep = lambda _seconds: None
sys.argv = sys.argv[2:]
runpy.run_path(sys.argv[0], run_name="__main__")
"""
WRAPPER_VERSION = "wrapper.--version"
DAEMON_STATUS = "wrapper.daemon.status.--json"
AGENTS = "wrapper.agent.ls.--global.--json"
SHOW_PID = f"systemctl.--user.show.{SERVICE}.-p.MainPID.--value"
RESTART = f"systemctl.--user.restart.{SERVICE}"
LAUNCHD_LABEL = f"gui/{os.getuid()}/{SERVICE}"
PRINT = f"launchctl.print.{LAUNCHD_LABEL}"
KICKSTART = f"launchctl.kickstart.-k.{LAUNCHD_LABEL}"
LSOF = "lsof.-n.-w.-a.-p.4242.-d.txt.-Fn"
RUNNING_1 = json.dumps({"localDaemon": "running", "daemonVersion": "1.0.0"})
RUNNING_2 = json.dumps({"localDaemon": "running", "daemonVersion": "2.0.0"})


@dataclass(frozen=True)
class Result:
    """Outcome of one job run."""

    code: int
    out: str
    calls: list[str]


@dataclass(frozen=True)
class Sandbox:
    """A directory of fake executables that record calls and replay replies."""

    root: Path

    def reply(self, key: str, out: str = "", *, rc: int = 0, after: str = "") -> None:
        """Script the reply of a fake command; `after` applies once restarted."""
        name = key.replace("/", "_")
        _ = (self.root / f"{name}.out").write_text(out, encoding="utf-8")
        _ = (self.root / f"{name}.rc").write_text(str(rc), encoding="utf-8")
        if after:
            _ = (self.root / f"{name}.after").write_text(after, encoding="utf-8")

    def run(
        self,
        kind: str,
        *extra: str,
        platform: str = "linux",
    ) -> Result:
        """Run the job as a subprocess with the fakes first on PATH.

        Returns:
            The exit status, stdout and recorded fake calls.
        """
        bin_dir = self.root / "bin"
        bin_dir.mkdir(exist_ok=True)
        for name in ("wrapper", "systemctl", "launchctl", "lsof"):
            fake = bin_dir / name
            _ = fake.write_text(FAKE, encoding="utf-8")
            fake.chmod(fake.stat().st_mode | stat.S_IXUSR)
        env = {
            **os.environ,
            "FAKE_DIR": str(self.root),
            "PATH": f"{bin_dir}{os.pathsep}{os.environ['PATH']}",
        }
        done = subprocess.run(  # noqa: S603 - test harness argv
            [
                sys.executable,
                "-c",
                LAUNCHER,
                platform,
                str(SCRIPT),
                "--kind",
                kind,
                "--service",
                SERVICE if platform == "linux" else "svc",
                "--wrapper",
                str(bin_dir / "wrapper"),
                *extra,
            ],
            capture_output=True,
            text=True,
            check=False,
            env=env,
        )
        calls_file = self.root / "calls"
        calls = calls_file.read_text(encoding="utf-8").splitlines()
        return Result(done.returncode, done.stdout, calls)


@pytest.fixture
def box(tmp_path: Path) -> Sandbox:
    """Provide an empty sandbox with an empty call log.

    Returns:
        The sandbox.
    """
    _ = (tmp_path / "calls").write_text("", encoding="utf-8")
    return Sandbox(tmp_path)


@pytest.fixture
def procs() -> Iterator[list[subprocess.Popen[bytes]]]:
    """Track spawned processes and stop them afterwards.

    Yields:
        The list tests append their spawned processes to.
    """
    started: list[subprocess.Popen[bytes]] = []
    yield started
    for proc in started:
        proc.kill()
        _ = proc.wait()


def _spawn(
    tmp_path: Path,
    version: str,
    procs: list[subprocess.Popen[bytes]],
    *,
    name: str = "runner",
) -> int:
    """Start a long-lived process whose executable sits in a versions tree.

    Returns:
        The process ID.
    """
    sleep = shutil.which("sleep")
    assert sleep is not None
    exe = tmp_path / "install" / "versions" / version / name
    exe.parent.mkdir(parents=True)
    _ = shutil.copy(sleep, exe)
    proc = subprocess.Popen([sleep, "600"], executable=str(exe))  # noqa: S603 - test-owned binary
    procs.append(proc)
    return proc.pid


def _stamp(minutes_ago: float) -> str:
    return (datetime.now(UTC) - timedelta(minutes=minutes_ago)).isoformat()


def _event(
    thread: str,
    minutes_ago: float,
    message: str = "",
    subtype: str = "",
) -> str:
    return json.dumps(
        {
            "threadId": thread,
            "@timestamp": _stamp(minutes_ago),
            "message": message,
            "subtype": subtype,
        },
    )


def _amp_linux(
    box: Sandbox,
    procs: list[subprocess.Popen[bytes]],
    log_lines: list[str] | None,
) -> list[str]:
    """Arrange a running amp 1.0.0 with 2.0.0 available.

    Returns:
        The extra job arguments naming the log file, if any.
    """
    old = _spawn(box.root, "1.0.0", procs)
    new = _spawn(box.root / "next", "2.0.0", procs)
    box.reply(SHOW_PID, f"{old}\n", after=f"{new}\n")
    box.reply(WRAPPER_VERSION, "2.0.0\n")
    if log_lines is None:
        return []
    log = box.root / "runner.log"
    _ = log.write_text("\n".join(log_lines), encoding="utf-8")
    return ["--log-file", str(log)]


@pytest.mark.parametrize(
    ("version_output", "message"),
    [
        ("", "could not resolve"),
        ("warning: stale cache\nbogus 1.0\n", "could not resolve"),
        ("\n  \n", "could not resolve"),
        ("warning: stale cache\nv1.0.0 (build 7)\n", "current at 1.0.0"),
    ],
)
def test_wrapper_version_is_read_from_the_last_line(
    box: Sandbox,
    version_output: str,
    message: str,
) -> None:
    """Warnings are skipped, a leading v is dropped, junk is not a version."""
    box.reply(DAEMON_STATUS, RUNNING_1)
    box.reply(WRAPPER_VERSION, version_output)
    result = box.run("paseo")
    assert message in result.out
    assert result.code == (0 if "current" in message else 1)


@pytest.mark.parametrize(
    "status",
    [
        "not json",
        "[]",
        json.dumps({"localDaemon": "stopped", "daemonVersion": "1.0.0"}),
        json.dumps({"localDaemon": "running"}),
        json.dumps({"localDaemon": "running", "daemonVersion": ""}),
        json.dumps({"localDaemon": "running", "daemonVersion": 3}),
    ],
)
def test_paseo_without_a_usable_daemon_is_left_alone(
    box: Sandbox,
    status: str,
) -> None:
    """No running daemon version means nothing to update."""
    box.reply(DAEMON_STATUS, status)
    result = box.run("paseo")
    assert result.code == 0
    assert result.out == f"idle-restart: {SERVICE} is not running; nothing to update\n"
    assert not any("restart" in call for call in result.calls)


def test_paseo_restarts_onto_the_newest_release_when_idle(box: Sandbox) -> None:
    """An idle service on an old release is restarted and confirmed."""
    box.reply(DAEMON_STATUS, RUNNING_1, after=RUNNING_2)
    box.reply(WRAPPER_VERSION, "2.0.0\n")
    box.reply(AGENTS, json.dumps([{"status": "idle"}]))
    result = box.run("paseo")
    assert result.code == 0
    assert f"restarting {SERVICE}: 1.0.0 -> 2.0.0" in result.out
    assert f"{SERVICE} running 2.0.0" in result.out
    assert f"systemctl --user restart {SERVICE}" in result.calls


def test_paseo_current_release_is_not_restarted(box: Sandbox) -> None:
    """Matching versions mean no restart."""
    box.reply(DAEMON_STATUS, RUNNING_1)
    box.reply(WRAPPER_VERSION, "1.0.0\n")
    result = box.run("paseo")
    assert result.code == 0
    assert f"{SERVICE} current at 1.0.0" in result.out
    assert not any("restart" in call for call in result.calls)


def test_restart_failure_is_reported_without_polling(box: Sandbox) -> None:
    """A failing service manager fails the job immediately."""
    box.reply(DAEMON_STATUS, RUNNING_1, after=RUNNING_2)
    box.reply(WRAPPER_VERSION, "2.0.0\n")
    box.reply(AGENTS, "[]")
    box.reply(RESTART, rc=3)
    result = box.run("paseo")
    assert result.code == 1
    assert "running 2.0.0" not in result.out
    status_calls = [call for call in result.calls if "daemon status" in call]
    assert len(status_calls) == 1


def test_service_that_does_not_return_on_the_new_release_fails(box: Sandbox) -> None:
    """If the daemon keeps reporting the old version the job fails."""
    box.reply(DAEMON_STATUS, RUNNING_1)
    box.reply(WRAPPER_VERSION, "2.0.0\n")
    box.reply(AGENTS, "[]")
    result = box.run("paseo")
    assert result.code == 1
    assert f"{SERVICE} did not come back on 2.0.0" in result.out
    assert len([call for call in result.calls if "daemon status" in call]) == 31


@pytest.mark.parametrize(
    ("listing", "rc", "busy"),
    [
        ("[]", 0, False),
        (json.dumps([{"status": "idle"}, {"status": "closed"}]), 0, False),
        (json.dumps([{"status": "idle"}, {"status": "running"}]), 0, True),
        (json.dumps([{"status": "initializing"}]), 0, True),
        (json.dumps([{"status": "idle"}, "oops"]), 0, True),
        ("{}", 0, True),
        ("not json", 0, True),
        ("[]", 1, True),
    ],
)
def test_paseo_busy_means_a_working_agent_or_an_unreadable_listing(
    box: Sandbox,
    listing: str,
    rc: int,
    busy: bool,  # noqa: FBT001 - parametrized expectation
) -> None:
    """Only a clean listing without working agents allows a restart."""
    box.reply(DAEMON_STATUS, RUNNING_1, after=RUNNING_2)
    box.reply(WRAPPER_VERSION, "2.0.0\n")
    box.reply(AGENTS, listing, rc=rc)
    result = box.run("paseo")
    assert result.code == 0
    assert ("postponing 1.0.0 -> 2.0.0" in result.out) is busy
    assert (f"systemctl --user restart {SERVICE}" in result.calls) is not busy


def test_darwin_restart_uses_launchctl_kickstart(box: Sandbox) -> None:
    """On darwin the label is kickstarted in the user's gui domain."""
    box.reply(DAEMON_STATUS, RUNNING_1, after=RUNNING_2)
    box.reply(WRAPPER_VERSION, "2.0.0\n")
    box.reply(AGENTS, "[]")
    box.reply(KICKSTART.replace(SERVICE, "svc"))
    result = box.run("paseo", platform="darwin")
    assert result.code == 0
    assert f"launchctl kickstart -k gui/{os.getuid()}/svc" in result.calls


def test_amp_restarts_when_idle_and_the_runner_moves_to_the_new_release(
    box: Sandbox,
    procs: list[subprocess.Popen[bytes]],
) -> None:
    """The runner's version is the versions/<v> directory of its executable."""
    extra = _amp_linux(box, procs, [_event("T-1", 600)])
    result = box.run("amp", *extra)
    assert result.code == 0
    assert f"restarting {SERVICE}: 1.0.0 -> 2.0.0" in result.out
    assert f"{SERVICE} running 2.0.0" in result.out


@pytest.mark.parametrize(
    ("log_lines", "busy"),
    [
        ([], False),
        ([_event("T-1", 5)], True),
        ([_event("T-1", 30)], False),
        ([_event("T-1", 30), _event("T-2", 3)], True),
        ([_event("T-1", 30, "[observer] onAgentState", "idle")], False),
        ([_event("T-1", 30, "[observer] onAgentState", "running")], True),
        ([_event("T-1", 200, "[observer] onAgentState", "running")], False),
        ([_event("T-1", 30, "[observer] other", "running")], False),
        (
            [
                _event("T-1", 30, "[observer] onAgentState", "running"),
                _event("T-1", 10, "[observer] onAgentState", "idle"),
                _event("T-1", 30),
            ],
            False,
        ),
        (
            [
                "not json",
                "[1]",
                json.dumps({"threadId": 1, "@timestamp": _stamp(1)}),
                json.dumps({"threadId": "T-1", "@timestamp": 5}),
                json.dumps({"threadId": "T-1", "@timestamp": "garbage"}),
                _event("T-2", 90),
            ],
            False,
        ),
    ],
)
def test_amp_busy_follows_recent_thread_activity(
    box: Sandbox,
    procs: list[subprocess.Popen[bytes]],
    log_lines: list[str],
    busy: bool,  # noqa: FBT001 - parametrized expectation
) -> None:
    """A fresh turn or an unfinished one inside the stuck window postpones."""
    extra = _amp_linux(box, procs, log_lines)
    result = box.run("amp", *extra)
    assert result.code == 0
    assert ("postponing 1.0.0 -> 2.0.0" in result.out) is busy
    assert (f"systemctl --user restart {SERVICE}" in result.calls) is not busy


def test_amp_without_a_log_file_counts_as_busy(
    box: Sandbox,
    procs: list[subprocess.Popen[bytes]],
) -> None:
    """No log to inspect means it is unknown whether work is in flight."""
    extra = _amp_linux(box, procs, None)
    result = box.run("amp", *extra)
    assert "postponing" in result.out
    assert result.code == 0


def test_amp_with_an_unreadable_log_counts_as_busy(
    box: Sandbox,
    procs: list[subprocess.Popen[bytes]],
) -> None:
    """A missing log file is treated like unknown activity."""
    _ = _amp_linux(box, procs, None)
    result = box.run("amp", "--log-file", str(box.root / "absent.log"))
    assert "postponing" in result.out
    assert result.code == 0


def test_amp_with_a_naive_timestamp_counts_as_busy_without_crashing(
    box: Sandbox,
    procs: list[subprocess.Popen[bytes]],
) -> None:
    """A timestamp without an offset cannot be aged, so the job postpones."""
    naive = datetime.now(UTC).replace(tzinfo=None).isoformat()
    event = json.dumps({"threadId": "T-1", "@timestamp": naive})
    extra = _amp_linux(box, procs, [event])
    result = box.run("amp", *extra)
    assert result.code == 0
    assert "postponing 1.0.0 -> 2.0.0" in result.out
    assert not any("restart" in call for call in result.calls)


@pytest.mark.parametrize("pid", ["", "0", "abc"])
def test_amp_without_a_main_pid_is_not_running(box: Sandbox, pid: str) -> None:
    """Empty, zero or garbage MainPID means the service is down."""
    box.reply(SHOW_PID, f"{pid}\n")
    result = box.run("amp")
    assert result.code == 0
    assert "is not running; nothing to update" in result.out


def test_amp_with_a_vanished_process_is_not_running(
    box: Sandbox,
    procs: list[subprocess.Popen[bytes]],
) -> None:
    """A PID whose /proc entry is gone has no executable to inspect."""
    pid = _spawn(box.root, "1.0.0", procs)
    procs[0].kill()
    _ = procs[0].wait()
    box.reply(SHOW_PID, f"{pid}\n")
    result = box.run("amp")
    assert result.code == 0
    assert "is not running; nothing to update" in result.out


@pytest.mark.parametrize("name", ["versions", "runner"])
def test_amp_outside_a_versions_tree_is_not_running(
    box: Sandbox,
    procs: list[subprocess.Popen[bytes]],
    name: str,
) -> None:
    """An executable not below versions/<v>/ (or named versions) has no version."""
    sleep = shutil.which("sleep")
    assert sleep is not None
    exe = box.root / "plain" / name
    exe.parent.mkdir()
    _ = shutil.copy(sleep, exe)
    proc = subprocess.Popen([sleep, "600"], executable=str(exe))  # noqa: S603 - test-owned binary
    procs.append(proc)
    box.reply(SHOW_PID, f"{proc.pid}\n")
    result = box.run("amp")
    assert result.code == 0
    assert "is not running; nothing to update" in result.out


def test_amp_on_darwin_reads_the_version_from_lsof(box: Sandbox) -> None:
    """Launchctl supplies the PID and lsof the executable path."""
    pid_print = "state = running\n\tpid = 4242\n"
    box.reply(PRINT.replace(SERVICE, "svc"), pid_print)
    box.reply(
        LSOF,
        "p4242\nfcwd\nn/Users/x/versions/1.0.0/amp\n",
        after="p4242\nn/Users/x/versions/2.0.0/amp\n",
    )
    box.reply(WRAPPER_VERSION, "2.0.0\n")
    box.reply(KICKSTART.replace(SERVICE, "svc"))
    log = box.root / "runner.log"
    _ = log.write_text(_event("T-1", 600), encoding="utf-8")
    result = box.run("amp", "--log-file", str(log), platform="darwin")
    assert result.code == 0
    assert "restarting svc: 1.0.0 -> 2.0.0" in result.out
    assert f"launchctl kickstart -k gui/{os.getuid()}/svc" in result.calls


@pytest.mark.parametrize(
    ("print_out", "lsof_out"),
    [
        ("state = waiting\n", ""),
        ("pid = 0\n", ""),
        ("pid = 4242\n", ""),
        ("pid = 4242\n", "p4242\nfcwd\n"),
        ("pid = 4242\n", "n/Users/x/bin/amp\n"),
    ],
)
def test_amp_on_darwin_without_a_resolvable_runner_is_not_running(
    box: Sandbox,
    print_out: str,
    lsof_out: str,
) -> None:
    """Missing pid or executable path means there is nothing to restart."""
    box.reply(PRINT.replace(SERVICE, "svc"), print_out)
    box.reply(LSOF, lsof_out)
    result = box.run("amp", platform="darwin")
    assert result.code == 0
    assert "svc is not running; nothing to update" in result.out


def test_unknown_kind_is_rejected_by_the_parser() -> None:
    """Only the declared kinds are accepted."""
    done = subprocess.run(  # noqa: S603 - test harness argv
        [sys.executable, str(SCRIPT), "--kind", "other"],
        capture_output=True,
        text=True,
        check=False,
        env=dict(os.environ),
    )
    assert done.returncode == 2
    assert "invalid choice" in done.stderr
