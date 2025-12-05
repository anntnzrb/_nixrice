#!/usr/bin/env -S uv run --script
# /// script
# dependencies = ["typer"]
# ///
"""NixOS/Darwin configuration management."""

import os, shutil, socket, subprocess, sys
from enum import StrEnum
from typing import Annotated, Any
import typer
import typer.rich_utils

# Patch: hide options panel in Rich help
typer.rich_utils._print_options_panel = lambda *a, **kw: None  # noqa: SLF001


class Color(StrEnum):
    GREEN = "\x1b[1;32m"
    RED = "\x1b[1;31m"
    BLUE = "\x1b[1;34m"
    DIM = "\x1b[2m"
    RESET = "\x1b[0m"


class Platform(StrEnum):
    DARWIN = "darwin"
    LINUX = "linux"


class TaskKey(StrEnum):
    HELP = "help"
    INFO = "info"
    CMD = "cmd"
    OK = "ok"
    DARWIN = "darwin"
    SUDO = "sudo"
    ARG = "arg"


class SubApp(StrEnum):
    SYSTEM = "system"
    HOME = "home"
    NIXOS = "nixos"
    DARWIN = "darwin"
    NIX = "nix"
    FLAKE = "flake"
    ISO = "iso"


# Output
def _ok(m: str) -> None:
    print(f"{Color.GREEN}✓{Color.RESET} {m}")


def _err(m: str) -> None:
    print(f"{Color.RED}✗{Color.RESET} {m}", file=sys.stderr)


def _info(m: str) -> None:
    print(f"{Color.BLUE}→{Color.RESET} {m}")


# Platform
def _host() -> str:
    return socket.gethostname().split(".")[0]


def _platform() -> Platform:
    return Platform.DARWIN if sys.platform == "darwin" else Platform.LINUX


def _require(platform: Platform) -> None:
    if _platform() != platform:
        name = "macOS" if platform == Platform.DARWIN else "Linux"
        _err(f"Requires {name}")
        raise typer.Exit(1)


def run(cmd: list[str], sudo: bool = False) -> None:
    if sudo:
        cmd = ["sudo", *cmd]
    print(f"{Color.DIM}$ {' '.join(cmd)}{Color.RESET}")
    subprocess.run(cmd, check=True)


def task(info: str, cmd: list[str], ok: str, *, sudo: bool = False) -> None:
    _info(info)
    run(cmd, sudo=sudo)
    _ok(ok)


# Task definitions
TASKS: dict[SubApp, dict[str, dict[TaskKey, Any]]] = {
    SubApp.NIXOS: {
        "build": {
            TaskKey.HELP: "Build NixOS configuration",
            TaskKey.INFO: "Building NixOS...",
            TaskKey.CMD: ["nixos-rebuild", "build", "--flake", ".#"],
            TaskKey.OK: "NixOS build complete",
            TaskKey.DARWIN: False,
        },
        "boot": {
            TaskKey.HELP: "Build and activate on next boot",
            TaskKey.INFO: "Setting boot...",
            TaskKey.CMD: [
                "nixos-rebuild",
                "boot",
                "--use-remote-sudo",
                "--flake",
                ".#",
            ],
            TaskKey.OK: "Boot set",
            TaskKey.DARWIN: False,
        },
        "switch": {
            TaskKey.HELP: "Build and switch immediately",
            TaskKey.INFO: "Switching...",
            TaskKey.CMD: [
                "nixos-rebuild",
                "switch",
                "--use-remote-sudo",
                "--flake",
                ".#",
            ],
            TaskKey.OK: "NixOS switch complete",
            TaskKey.DARWIN: False,
        },
    },
    SubApp.DARWIN: {
        "build": {
            TaskKey.HELP: "Build Darwin configuration",
            TaskKey.INFO: "Building Darwin for {host}...",
            TaskKey.CMD: ["nix", "build", ".#darwinConfigurations.{host}.system"],
            TaskKey.OK: "Darwin build complete",
            TaskKey.DARWIN: True,
        },
        "switch": {
            TaskKey.HELP: "Build and switch immediately",
            TaskKey.INFO: "Switching...",
            TaskKey.CMD: [
                "./result/sw/bin/darwin-rebuild",
                "switch",
                "--flake",
                ".#{host}",
            ],
            TaskKey.OK: "Darwin switch complete",
            TaskKey.DARWIN: True,
            TaskKey.SUDO: True,
        },
    },
    SubApp.NIX: {
        "optimise": {
            TaskKey.HELP: "Optimize nix store",
            TaskKey.INFO: "Optimizing nix store...",
            TaskKey.CMD: ["nix", "store", "optimise"],
            TaskKey.OK: "Nix store optimized",
            TaskKey.SUDO: True,
        },
        "repair": {
            TaskKey.HELP: "Repair nix store",
            TaskKey.INFO: "Repairing nix store...",
            TaskKey.CMD: ["nix-store", "--verify", "--check-contents", "--repair"],
            TaskKey.OK: "Nix store repaired",
            TaskKey.SUDO: True,
        },
    },
    SubApp.FLAKE: {
        "check": {
            TaskKey.HELP: "Check flake validity",
            TaskKey.INFO: "Checking flake...",
            TaskKey.CMD: ["nix", "flake", "check", "."],
            TaskKey.OK: "Flake check passed",
        },
        "fmt": {
            TaskKey.HELP: "Format and check code",
            TaskKey.INFO: "Formatting...",
            TaskKey.CMD: ["pre-commit", "run", "--all-files"],
            TaskKey.OK: "Format complete",
        },
    },
    SubApp.ISO: {
        "build": {
            TaskKey.HELP: "Build ISO configuration",
            TaskKey.INFO: "Building ISO: {config}...",
            TaskKey.CMD: ["nix", "build", ".#isoConfigurations.{config}"],
            TaskKey.OK: "ISO build complete",
            TaskKey.ARG: "config",
        },
    },
}


# Registration
def register(sub: typer.Typer, tasks: dict[str, dict[TaskKey, Any]]) -> None:
    for name, t in tasks.items():
        arg, hlp = t.get(TaskKey.ARG), t.get(TaskKey.HELP, "")

        def make(t: dict[TaskKey, Any] = t, arg: str | None = arg) -> Any:
            if arg:

                def cmd(val: Annotated[str, typer.Argument()] = "nomad") -> None:
                    if (d := t.get(TaskKey.DARWIN)) is not None:
                        _require(Platform.DARWIN if d else Platform.LINUX)
                    ctx = {"host": _host(), arg: val}
                    task(
                        t[TaskKey.INFO].format(**ctx),
                        [a.format(**ctx) for a in t[TaskKey.CMD]],
                        t[TaskKey.OK],
                        sudo=t.get(TaskKey.SUDO, False),
                    )

                return cmd
            else:

                def cmd() -> None:
                    if (d := t.get(TaskKey.DARWIN)) is not None:
                        _require(Platform.DARWIN if d else Platform.LINUX)
                    ctx = {"host": _host()}
                    task(
                        t[TaskKey.INFO].format(**ctx),
                        [a.format(**ctx) for a in t[TaskKey.CMD]],
                        t[TaskKey.OK],
                        sudo=t.get(TaskKey.SUDO, False),
                    )

                return cmd

        sub.command(name, help=hlp)(make())


# Apps
app = typer.Typer(
    help="NixOS/Darwin configuration management",
    no_args_is_help=True,
    add_completion=False,
    options_metavar="",
)
SUBS: dict[SubApp, typer.Typer] = {
    n: typer.Typer(help=h, no_args_is_help=True, options_metavar="")
    for n, h in [
        (SubApp.SYSTEM, "System configuration"),
        (SubApp.HOME, "Home Manager"),
        (SubApp.NIXOS, "NixOS commands"),
        (SubApp.DARWIN, "Darwin commands"),
        (SubApp.NIX, "Nix maintenance"),
        (SubApp.FLAKE, "Flake management"),
        (SubApp.ISO, "ISO generation"),
    ]
}
for n, sub in SUBS.items():
    app.add_typer(sub, name=n)
    if n in TASKS:
        register(sub, TASKS[n])


# Special: system (dispatch)
@SUBS[SubApp.SYSTEM].command("build")
def system_build() -> None:
    """Build system configuration."""
    sub = SUBS[SubApp.DARWIN] if _platform() == Platform.DARWIN else SUBS[SubApp.NIXOS]
    sub.registered_commands[0].callback()


@SUBS[SubApp.SYSTEM].command("switch")
def system_switch() -> None:
    """Build and switch immediately."""
    sub = SUBS[SubApp.DARWIN] if _platform() == Platform.DARWIN else SUBS[SubApp.NIXOS]
    sub.registered_commands[0].callback()
    sub.registered_commands[-1].callback()


# Special: home (args)
@SUBS[SubApp.HOME].command("build")
def home_build(
    user: Annotated[str, typer.Argument()] = os.getenv("RICE_USER", "annt"),
    host: Annotated[str, typer.Argument()] = os.getenv("RICE_HOST", "wsl"),
) -> None:
    """Build home-manager configuration."""
    task(
        f"Building home-manager for {user}@{host}...",
        ["nix", "build", f".#homeConfigurations.{user}@{host}.activationPackage"],
        "Home-manager build complete",
    )


@SUBS[SubApp.HOME].command("switch")
def home_switch(
    user: Annotated[str, typer.Argument()] = os.getenv("RICE_USER", "annt"),
    host: Annotated[str, typer.Argument()] = os.getenv("RICE_HOST", "wsl"),
) -> None:
    """Build and activate home-manager configuration."""
    home_build(user, host)
    task(
        "Activating home-manager...",
        ["./result/activate"],
        "Home-manager switch complete",
    )


# Special: nix clean (multi-step)
@SUBS[SubApp.NIX].command("clean")
def nix_clean() -> None:
    """Clean nix cache and run cleanup."""
    _info("Cleaning nix cache...")
    shutil.rmtree(os.path.expanduser("~/.cache/nix/"), ignore_errors=True)
    run(["nh", "clean", "all"])
    run(["nh", "clean", "user"])
    _ok("Nix cleanup complete")


# Special: flake update (conditional)
@SUBS[SubApp.FLAKE].command("update")
def flake_update(
    name: Annotated[str, typer.Argument(help='Input to update (or "all")')],
) -> None:
    """Update flake inputs (use "all" to update all)."""
    if name == "all":
        task(
            "Updating all flake inputs...",
            [
                "nix",
                "flake",
                "update",
                "--commit-lock-file",
                "--option",
                "commit-lockfile-summary",
                "chore(flake): update lockfile",
            ],
            "Flake update complete",
        )
    else:
        _info(f"Updating flake input: {name}...")
        run(["nix", "flake", "update", name])
        run(["git", "add", "flake.lock"])
        run(["git", "commit", "-m", f"chore(flake): update input ({name})"])
        _ok("Flake update complete")


if __name__ == "__main__":
    app()
