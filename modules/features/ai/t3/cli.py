"""Install, update, configure, refresh, and prune the T3 Code user service.

T3 installs runtimes; Darwin uses a stable launcher supervised by Nix. This
script decides when it is safe to update, applies the declared settings, and
keeps Claude's model list in step with the model gateway. It removes superseded
runtimes while preserving runtimes still in use and one rollback runtime.
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import sqlite3
import subprocess
import sys
import tempfile
import urllib.request
from contextlib import closing
from dataclasses import dataclass
from pathlib import Path
from typing import TYPE_CHECKING, cast

if TYPE_CHECKING:
    from http.client import HTTPResponse

type Json = str | int | float | bool | list[Json] | dict[str, Json] | None
type JsonObject = dict[str, Json]

CLAUDE_INSTANCE = "claudeAgent"
BUSY_RUN_STATES = ("queued", "preparing", "starting", "running", "waiting")


@dataclass(frozen=True, slots=True)
class Context:
    """Host paths and declared configuration."""

    home: Path
    channel: str
    settings: Path
    gateway: str

    @property
    def runtime(self) -> Path:
        """Directory holding the installed runtimes.

        Returns:
            The runtime directory under the T3 home.
        """
        return self.home / "runtime"

    @property
    def userdata(self) -> Path:
        """Directory holding settings and state.

        Returns:
            The userdata directory under the T3 home.
        """
        return self.home / "userdata"


class Args(argparse.Namespace):
    """Parsed command line."""

    command: str = ""
    channel: str = ""
    settings: Path = Path()
    gateway: str = ""


def say(message: str) -> None:
    """Print a message prefixed with the tool name."""
    _ = sys.stdout.write(f"t3: {message}\n")
    _ = sys.stdout.flush()


def parse_json(raw: str | bytes) -> Json:
    """Decode JSON text; the result is untrusted until narrowed by the caller.

    Returns:
        The decoded value.
    """
    return cast("Json", json.loads(raw))


def load_object(path: Path) -> JsonObject | None:
    """Read a JSON object.

    Returns:
        The object, or None when the file is missing or not an object.
    """
    try:
        data = parse_json(path.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return None
    return data if isinstance(data, dict) else None


def write_object(path: Path, data: JsonObject) -> None:
    """Replace a JSON file atomically."""
    fd, tmp = tempfile.mkstemp(dir=path.parent, suffix=".json")
    with os.fdopen(fd, "w", encoding="utf-8") as handle:
        json.dump(data, handle, indent=2)
        _ = handle.write("\n")
    _ = Path(tmp).replace(path)


def installed_binary(ctx: Context) -> Path | None:
    """Find the executable of the runtime the service currently runs.

    Returns:
        The executable path, or None when no runtime is active.
    """
    state = load_object(ctx.runtime / "service-state.json") or {}
    version = state.get("activeVersion")
    if not isinstance(version, str) or not version:
        return None
    binary = ctx.runtime / "versions" / version / "t3"
    return binary if os.access(binary, os.X_OK) else None


def busy_threads(ctx: Context) -> int:
    """Count threads with an orchestration run that has not settled.

    Returns:
        The number of busy threads.
    """
    database = ctx.userdata / "statev2.sqlite"
    marks = ", ".join("?" for _ in BUSY_RUN_STATES)
    query = (
        "SELECT count(DISTINCT thread_id) FROM orchestration_v2_projection_runs "  # noqa: S608 - only "?" placeholders are interpolated
        f"WHERE status IN ({marks})"
    )
    with closing(
        sqlite3.connect(f"file:{database}?mode=ro", uri=True, timeout=10)
    ) as conn:
        row = cast("tuple[int] | None", conn.execute(query, BUSY_RUN_STATES).fetchone())
    return row[0] if row else 0


def merge(base: JsonObject, overlay: JsonObject) -> None:
    """Deep-merge overlay into base; overlay leaves win."""
    for key, value in overlay.items():
        current = base.get(key)
        if isinstance(value, dict) and isinstance(current, dict):
            merge(current, value)
        else:
            base[key] = value


def gateway_models(gateway: str) -> list[Json] | None:
    """List non-Anthropic gateway models as Claude custom models.

    Returns:
        The models, or None when the gateway is unreachable or malformed.
    """
    request = urllib.request.Request(  # noqa: S310 - fixed tailnet gateway
        f"{gateway.rstrip('/')}/models",
        headers={"x-api-key": "keyless", "anthropic-version": "2023-06-01"},
    )
    try:
        with cast(
            "HTTPResponse",
            urllib.request.urlopen(request, timeout=10),  # noqa: S310 - fixed tailnet gateway
        ) as response:
            payload = parse_json(response.read())
    except (OSError, ValueError):
        return None
    data = payload.get("data") if isinstance(payload, dict) else None
    if not isinstance(data, list):
        return None
    models: list[Json] = []
    for model in data:
        if not isinstance(model, dict) or model.get("owned_by") == "anthropic":
            continue
        slug, name = model.get("id"), model.get("display_name")
        if isinstance(slug, str) and slug:
            entry: JsonObject = {"slug": slug}
            if isinstance(name, str) and name:
                entry["name"] = name
            models.append(entry)
    return models


def refresh_claude_models(live: JsonObject, gateway: str) -> bool:
    """Replace Claude's custom models with the gateway catalog.

    Returns:
        True if the models changed.
    """
    instances = live.get("providerInstances")
    instance = instances.get(CLAUDE_INSTANCE) if isinstance(instances, dict) else None
    if not isinstance(instance, dict) or not instance.get("enabled"):
        return False
    models = gateway_models(gateway)
    if models is None:
        say("gateway catalog unreachable; Claude models unchanged")
        return False
    config = instance.get("config")
    if not isinstance(config, dict):
        config = {}
        instance["config"] = config
    if config.get("customModels") == models:
        return False
    config["customModels"] = models
    say(f"Claude custom models -> {len(models)} gateway models")
    return True


def apply_settings(ctx: Context) -> bool:
    """Merge declared settings into the server and desktop client files.

    Keys the declaration does not set, including ones changed from a client,
    survive. The server reloads its file while running; desktop clients read
    theirs when they open.

    Returns:
        True if either file changed.

    Raises:
        SystemExit: A settings file is not a JSON object.
    """
    changed = False
    for filename, source in (
        ("settings.json", ctx.settings),
        ("client-settings.json", ctx.settings.with_name("client-settings.json")),
    ):
        target = ctx.userdata / filename
        declared = load_object(source)
        if declared is None:
            msg = f"{source} is not a JSON object"
            raise SystemExit(msg)
        live = load_object(target) if target.exists() else {}
        if live is None:
            msg = f"{target} is not a JSON object"
            raise SystemExit(msg)
        before = json.dumps(live, sort_keys=True)
        settings = live
        if filename == "client-settings.json" and "settings" in live:
            stored = live["settings"]
            if not isinstance(stored, dict):
                msg = f"{target}: settings is not a JSON object"
                raise SystemExit(msg)
            settings = stored
        merge(settings, declared)
        if filename == "settings.json":
            _ = refresh_claude_models(settings, ctx.gateway)
        if json.dumps(live, sort_keys=True) == before:
            continue
        target.parent.mkdir(parents=True, exist_ok=True)
        write_object(target, live)
        say(f"applied settings to {target}")
        changed = True
    return changed


def run(argv: list[str], *, unattended: bool = False) -> int:
    """Echo and run a command.

    Returns:
        The command's result.
    """
    say("+ " + " ".join(argv))
    return subprocess.call(  # noqa: S603 - argv built from fixed paths
        argv, stdin=subprocess.DEVNULL if unattended else None
    )


def bootstrap(ctx: Context) -> int:
    """Install the service from the registry on a host without T3.

    Returns:
        The exit status.
    """
    if run(["npx", "-y", f"t3@{ctx.channel}", "service", "install"]) != 0:
        return 1
    _ = apply_settings(ctx)
    binary = installed_binary(ctx)
    return run([str(binary), "service", "restart"]) if binary else 1


def update(ctx: Context) -> int:
    """Install the channel head, restarting the service only when idle.

    Returns:
        The exit status.
    """
    binary = installed_binary(ctx)
    if binary is None:
        say("not installed; bootstrapping")
        result = bootstrap(ctx)
        return stabilize(ctx) if sys.platform == "darwin" and result == 0 else result
    _ = apply_settings(ctx)
    try:
        busy = busy_threads(ctx)
    except sqlite3.Error as error:
        say(f"cannot tell whether threads run ({error}); not updating")
        return 1
    if busy:
        say(f"{busy} thread(s) running; postponing the update")
        return 0
    if sys.platform != "darwin":
        return run([str(binary), "update", "--yes", "--channel", ctx.channel])
    result = run([str(binary), "update", "--channel", ctx.channel], unattended=True)
    stabilized = stabilize(ctx)
    return result or stabilized


def launchctl(*args: str, check: bool = True) -> subprocess.CompletedProcess[bytes]:
    """Run launchctl, requiring success except when inspecting a job.

    Returns:
        The command's result.
    """
    return subprocess.run(  # noqa: S603 - fixed launchctl commands
        ["/bin/launchctl", *args], check=check, capture_output=True, timeout=150
    )


def refresh_stable(ctx: Context) -> bool:
    """Clone the completed active runtime and recover interrupted swaps.

    Returns:
        Whether the stable runtime was replaced.

    Raises:
        ValueError: The active runtime is missing or incomplete.
    """
    binary = installed_binary(ctx)
    if binary is None or not runtime_complete(binary.parent):
        msg = "active runtime is missing or incomplete"
        raise ValueError(msg)
    stable = ctx.runtime / "stable"
    old = ctx.runtime / "stable.old"
    staging = ctx.runtime / "stable.new"
    if old.exists():
        if not stable.exists():
            _ = old.rename(stable)
        else:
            shutil.rmtree(old)
    if staging.exists():
        shutil.rmtree(staging)
    if runtime_marker(stable / ".version").strip() == binary.parent.name:
        return False
    _ = subprocess.run(  # noqa: S603 - absolute macOS cp for APFS clones
        ["/bin/cp", "-cR", str(binary.parent), str(staging)], check=True
    )
    _ = (staging / ".version").write_text(binary.parent.name, encoding="utf-8")
    (ctx.runtime / "stable.restart").touch()
    if stable.exists():
        _ = stable.rename(old)
    _ = staging.rename(stable)
    if old.exists():
        shutil.rmtree(old)
    return True


def bootout_loaded(label: str) -> None:
    """Unload a launchd job only when it is loaded."""
    if launchctl("print", label, check=False).returncode == 0:
        _ = launchctl("bootout", "--wait", label)


def start_stable(ctx: Context, domain: str, label: str) -> None:
    """Load the gated launcher and discharge its restart debt."""
    job = launchctl("print", label, check=False)
    running = any(
        line.strip().startswith(b"pid = ") for line in job.stdout.splitlines()
    )
    plist = Path.home() / "Library/LaunchAgents/org.nix-community.home.t3-service.plist"
    if job.returncode != 0:
        _ = launchctl("bootstrap", domain, str(plist))
    (ctx.runtime / "stable.enabled").touch()
    restart = ctx.runtime / "stable.restart"
    if running:
        state = load_object(ctx.runtime / "service-state.json") or {}
        pending = runtime_marker(ctx.runtime / ".restart-pending").strip()
        if restart.exists() or pending == state.get("activeVersion"):
            _ = launchctl("kickstart", "-k", label)
    restart.unlink(missing_ok=True)


def restore_upstream(ctx: Context, domain: str, ours: str, upstream: str) -> None:
    """Stop the gated launcher before enabling T3, retaining an idle rice job."""
    (ctx.runtime / "stable.enabled").unlink(missing_ok=True)
    bootout_loaded(ours)
    agents = Path.home() / "Library/LaunchAgents"
    try:
        _ = launchctl(
            "bootstrap",
            domain,
            str(agents / "org.nix-community.home.t3-service.plist"),
            check=False,
        )
    except (OSError, subprocess.SubprocessError) as error:
        say(f"cannot reload gated service ({error})")
    _ = launchctl("enable", upstream)
    plist = agents / "com.t3tools.t3code.service.plist"
    if plist.exists() and launchctl("print", upstream, check=False).returncode != 0:
        _ = launchctl("bootstrap", domain, str(plist))


def stabilize(ctx: Context) -> int:
    """Take over the Darwin service when idle, restoring T3 on failure.

    Returns:
        Zero on success or postponement, one on failure.
    """
    if sys.platform != "darwin":
        return 0
    try:
        busy = busy_threads(ctx)
    except sqlite3.Error as error:
        say(f"cannot tell whether threads run ({error}); not stabilizing")
        return 1
    if busy:
        say(f"{busy} thread(s) running; postponing service stabilization")
        return 0
    domain = f"gui/{os.getuid()}"
    upstream = f"{domain}/com.t3tools.t3code.service"
    ours = f"{domain}/org.nix-community.home.t3-service"
    try:
        bootout_loaded(upstream)
        _ = launchctl("disable", upstream)
        _ = refresh_stable(ctx)
        start_stable(ctx, domain, ours)
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        say(f"cannot stabilize service ({error}); restoring T3's service")
        try:
            restore_upstream(ctx, domain, ours, upstream)
        except (OSError, subprocess.SubprocessError) as fallback_error:
            say(f"cannot restore T3's service ({fallback_error})")
        return 1
    return 0


def sync(ctx: Context) -> int:
    """Apply server and desktop settings and refresh Claude models.

    Returns:
        The exit status.
    """
    if installed_binary(ctx) is None:
        say("not installed yet; nothing to sync")
        return 0
    _ = apply_settings(ctx)
    return 0


def runtime_marker(path: Path) -> str:
    """Read runtime metadata or a launcher shim when present.

    Returns:
        The text, or an empty string for a missing or non-text file.
    """
    try:
        return path.read_text(encoding="utf-8")
    except (FileNotFoundError, UnicodeDecodeError):
        return ""


def runtime_references() -> str:
    """Collect service unit and CLI launcher runtime references.

    Returns:
        Unit and launcher paths/text that may still name an installed runtime.
    """
    home = Path.home()
    units = (
        home / "Library/LaunchAgents/com.t3tools.t3code.service.plist",
        home / ".config/systemd/user/t3code.service",
    )
    launchers = {
        home / ".local/bin/t3",
        Path(os.environ.get("T3CODE_INSTALL_BIN_DIR", home / ".local/bin")) / "t3",
    }
    if launcher := shutil.which("t3"):
        launchers.add(Path(launcher))
    references = [runtime_marker(unit) for unit in units]
    references.extend(
        f"{launcher.resolve()}\n{runtime_marker(launcher)}"
        for launcher in sorted(launchers)
    )
    return "\n".join(references)


def runtime_complete(path: Path) -> bool:
    """Check for a regular, readable completion marker matching the runtime.

    Returns:
        Whether the runtime has a valid completion marker.
    """
    marker = path / ".install-complete"
    try:
        return marker.is_file() and runtime_marker(marker).strip() == path.name
    except OSError:
        return False


def prune(ctx: Context) -> int:
    """Remove superseded runtimes when idle, keeping one for rollback.

    Returns:
        The exit status.
    """
    state = load_object(ctx.runtime / "service-state.json") or {}
    version = state.get("activeVersion")
    if not isinstance(version, str) or not version:
        say("no active runtime; nothing to prune")
        return 0
    pending = state.get("update")
    if isinstance(pending, dict) and pending.get("status") == "pending":
        say("an update is pending; postponing runtime pruning")
        return 0
    try:
        busy = busy_threads(ctx)
    except sqlite3.Error as error:
        say(f"cannot tell whether threads run ({error}); not pruning")
        return 1
    if busy:
        say(f"{busy} thread(s) running; postponing runtime pruning")
    versions = ctx.runtime / "versions"
    if busy or not versions.is_dir():
        return 0
    try:
        references = runtime_references()
    except OSError as error:
        say(f"cannot read runtime references ({error}); not pruning")
        return 1
    others = sorted(
        (
            path
            for path in versions.iterdir()
            if not path.name.startswith(".")
            and not path.is_symlink()
            and path.is_dir()
            and runtime_complete(path)
            and path.name != version
            and f"versions/{path.name}/" not in references
        ),
        key=lambda path: (path.stat().st_mtime, path.name),
        reverse=True,
    )
    for path in others[1:]:
        shutil.rmtree(path)
        say(f"removed runtime {path.name}")
    return 0


def main(argv: list[str] | None = None) -> int:
    """Run the command line.

    Returns:
        The exit status.
    """
    parser = argparse.ArgumentParser(prog="t3ctl")
    _ = parser.add_argument("command", choices=("update", "sync", "prune", "stabilize"))
    _ = parser.add_argument("--channel", required=True, choices=("stable", "nightly"))
    _ = parser.add_argument("--settings", required=True, type=Path)
    _ = parser.add_argument("--gateway", required=True)
    args = parser.parse_args(argv, namespace=Args())
    ctx = Context(
        home=Path(os.environ.get("T3CODE_HOME") or Path.home() / ".t3"),
        channel=args.channel,
        settings=args.settings,
        gateway=args.gateway,
    )
    return {"update": update, "sync": sync, "prune": prune, "stabilize": stabilize}[
        args.command
    ](ctx)


if __name__ == "__main__":
    raise SystemExit(main())
