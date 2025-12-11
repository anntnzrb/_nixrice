"""NixOS/Darwin configuration management."""

import shutil
import socket
import subprocess
import sys
from dataclasses import dataclass
from enum import StrEnum
from pathlib import Path
from typing import Annotated

import typer
import typer.rich_utils

typer.rich_utils._print_options_panel = lambda *a, **kw: None  # noqa: SLF001


# === Types ===


class Platform(StrEnum):
    DARWIN = "darwin"
    LINUX = "linux"


class Ansi(StrEnum):
    GREEN = "\x1b[1;32m"
    RED = "\x1b[1;31m"
    BLUE = "\x1b[1;34m"
    DIM = "\x1b[2m"
    RESET = "\x1b[0m"


@dataclass(frozen=True, slots=True)
class Task:
    """Immutable task definition."""

    help: str
    info: str
    cmd: tuple[str, ...]
    ok: str
    sudo: bool = False
    platform: Platform | None = None


# === Environment ===

HOST = socket.gethostname().split(".")[0]
PLATFORM = Platform.DARWIN if sys.platform == "darwin" else Platform.LINUX


# === Output ===


def ok(msg: str) -> None:
    print(f"{Ansi.GREEN}✓{Ansi.RESET} {msg}")


def err(msg: str) -> None:
    print(f"{Ansi.RED}✗{Ansi.RESET} {msg}", file=sys.stderr)


def info(msg: str) -> None:
    print(f"{Ansi.BLUE}→{Ansi.RESET} {msg}")


# === Execution ===


def run(cmd: list[str], *, sudo: bool = False) -> None:
    if sudo:
        cmd = ["sudo", *cmd]
    print(f"{Ansi.DIM}$ {' '.join(cmd)}{Ansi.RESET}")
    subprocess.run(cmd, check=True)


def require_platform(platform: Platform) -> None:
    if PLATFORM != platform:
        name = "macOS" if platform == Platform.DARWIN else "Linux"
        err(f"Requires {name}")
        raise typer.Exit(1)


def exec_task(t: Task, **ctx: str) -> None:
    """Execute a task with optional context substitution."""
    if t.platform is not None:
        require_platform(t.platform)
    ctx = {"host": HOST, **ctx}
    info(t.info.format(**ctx))
    run([arg.format(**ctx) for arg in t.cmd], sudo=t.sudo)
    ok(t.ok)


# === Task Definitions ===

NIXOS_BUILD = Task(
    help="Build NixOS configuration",
    info="Building NixOS...",
    cmd=("nixos-rebuild", "build", "--flake", ".#"),
    ok="NixOS build complete",
    platform=Platform.LINUX,
)

NIXOS_BOOT = Task(
    help="Build and activate on next boot",
    info="Setting boot...",
    cmd=("nixos-rebuild", "boot", "--use-remote-sudo", "--flake", ".#"),
    ok="Boot set",
    platform=Platform.LINUX,
)

NIXOS_SWITCH = Task(
    help="Build and switch immediately",
    info="Switching...",
    cmd=("nixos-rebuild", "switch", "--use-remote-sudo", "--flake", ".#"),
    ok="NixOS switch complete",
    platform=Platform.LINUX,
)

DARWIN_BUILD = Task(
    help="Build Darwin configuration",
    info="Building Darwin for {host}...",
    cmd=("nix", "build", ".#darwinConfigurations.{host}.system"),
    ok="Darwin build complete",
    platform=Platform.DARWIN,
)

DARWIN_SWITCH = Task(
    help="Build and switch immediately",
    info="Switching...",
    cmd=("./result/sw/bin/darwin-rebuild", "switch", "--flake", ".#{host}"),
    ok="Darwin switch complete",
    platform=Platform.DARWIN,
    sudo=True,
)

NIX_OPTIMISE = Task(
    help="Optimize nix store",
    info="Optimizing nix store...",
    cmd=("nix", "store", "optimise"),
    ok="Nix store optimized",
    sudo=True,
)

NIX_REPAIR = Task(
    help="Repair nix store",
    info="Repairing nix store...",
    cmd=("nix-store", "--verify", "--check-contents", "--repair"),
    ok="Nix store repaired",
    sudo=True,
)

FLAKE_CHECK = Task(
    help="Check flake validity",
    info="Checking flake...",
    cmd=("nix", "flake", "check", "."),
    ok="Flake check passed",
)

FLAKE_FMT = Task(
    help="Format and check code",
    info="Formatting...",
    cmd=("pre-commit", "run", "--all-files"),
    ok="Format complete",
)


# === CLI ===

app = typer.Typer(
    help="NixOS/Darwin configuration management",
    no_args_is_help=True,
    add_completion=False,
    options_metavar="",
)


def subapp(help_text: str) -> typer.Typer:
    return typer.Typer(help=help_text, no_args_is_help=True, options_metavar="")


# --- system ---
system_app = subapp("System configuration")
app.add_typer(system_app, name="system")


@system_app.command("build", help="Build system configuration")
def system_build() -> None:
    exec_task(DARWIN_BUILD if PLATFORM == Platform.DARWIN else NIXOS_BUILD)


@system_app.command("switch", help="Build and switch immediately")
def system_switch() -> None:
    if PLATFORM == Platform.DARWIN:
        exec_task(DARWIN_BUILD)
        exec_task(DARWIN_SWITCH)
    else:
        exec_task(NIXOS_BUILD)
        exec_task(NIXOS_SWITCH)


# --- home ---
home_app = subapp("Home Manager")
app.add_typer(home_app, name="home")


@home_app.command("build", help="Build home-manager configuration")
def home_build(
    user: Annotated[str, typer.Argument()] = "annt",
    host: Annotated[str, typer.Argument()] = "wsl",
) -> None:
    info(f"Building home-manager for {user}@{host}...")
    run(["nix", "build", f".#homeConfigurations.{user}@{host}.activationPackage"])
    ok("Home-manager build complete")


@home_app.command("switch", help="Build and activate home-manager configuration")
def home_switch(
    user: Annotated[str, typer.Argument()] = "annt",
    host: Annotated[str, typer.Argument()] = "wsl",
) -> None:
    home_build(user, host)
    info("Activating home-manager...")
    run(["./result/activate"])
    ok("Home-manager switch complete")


# --- nixos ---
nixos_app = subapp("NixOS commands")
app.add_typer(nixos_app, name="nixos")


@nixos_app.command("build", help=NIXOS_BUILD.help)
def nixos_build() -> None:
    exec_task(NIXOS_BUILD)


@nixos_app.command("boot", help=NIXOS_BOOT.help)
def nixos_boot() -> None:
    exec_task(NIXOS_BOOT)


@nixos_app.command("switch", help=NIXOS_SWITCH.help)
def nixos_switch() -> None:
    exec_task(NIXOS_SWITCH)


# --- darwin ---
darwin_app = subapp("Darwin commands")
app.add_typer(darwin_app, name="darwin")


@darwin_app.command("build", help=DARWIN_BUILD.help)
def darwin_build() -> None:
    exec_task(DARWIN_BUILD)


@darwin_app.command("switch", help=DARWIN_SWITCH.help)
def darwin_switch() -> None:
    exec_task(DARWIN_SWITCH)


# --- nix ---
nix_app = subapp("Nix maintenance")
app.add_typer(nix_app, name="nix")


@nix_app.command("optimise", help=NIX_OPTIMISE.help)
def nix_optimise() -> None:
    exec_task(NIX_OPTIMISE)


@nix_app.command("repair", help=NIX_REPAIR.help)
def nix_repair() -> None:
    exec_task(NIX_REPAIR)


@nix_app.command("clean", help="Clean nix cache and run cleanup")
def nix_clean() -> None:
    info("Cleaning nix cache...")
    shutil.rmtree(Path.home() / ".cache/nix", ignore_errors=True)
    run(["nh", "clean", "all"])
    run(["nh", "clean", "user"])
    ok("Nix cleanup complete")


# --- flake ---
flake_app = subapp("Flake management")
app.add_typer(flake_app, name="flake")


@flake_app.command("check", help=FLAKE_CHECK.help)
def flake_check() -> None:
    exec_task(FLAKE_CHECK)


@flake_app.command("fmt", help=FLAKE_FMT.help)
def flake_fmt() -> None:
    exec_task(FLAKE_FMT)


@flake_app.command("update", help='Update flake inputs (use "all" to update all)')
def flake_update(
    name: Annotated[str, typer.Argument(help='Input to update (or "all")')],
) -> None:
    if name == "all":
        info("Updating all flake inputs...")
        run(
            [
                "nix",
                "flake",
                "update",
                "--commit-lock-file",
                "--option",
                "commit-lockfile-summary",
                "chore(flake): update lockfile",
            ]
        )
        ok("Flake update complete")
    else:
        info(f"Updating flake input: {name}...")
        run(["nix", "flake", "update", name])
        run(["git", "add", "flake.lock"])
        run(["git", "commit", "-m", f"chore(flake): update input ({name})"])
        ok("Flake update complete")


if __name__ == "__main__":
    app()
