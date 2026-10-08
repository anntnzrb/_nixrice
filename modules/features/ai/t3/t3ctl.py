"""Install, update, configure, and refresh the T3 Code user service.

T3 writes and supervises its own service unit. This script decides when it is
safe to update, applies the declared server settings, and keeps Claude's model
list in step with the model gateway.
"""

from __future__ import annotations

import argparse
import json
import os
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
    """Replace a JSON file atomically; T3 watches the settings file for edits."""
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
    """Merge declared settings into the live file.

    Keys the declaration does not set, including ones changed from a client,
    survive. T3 reloads the file while running.

    Returns:
        True if the file changed.

    Raises:
        SystemExit: A settings file is not a JSON object.
    """
    target = ctx.userdata / "settings.json"
    declared = load_object(ctx.settings)
    if declared is None:
        msg = f"{ctx.settings} is not a JSON object"
        raise SystemExit(msg)
    live = load_object(target) if target.exists() else {}
    if live is None:
        msg = f"{target} is not a JSON object"
        raise SystemExit(msg)
    before = json.dumps(live, sort_keys=True)
    merge(live, declared)
    _ = refresh_claude_models(live, ctx.gateway)
    if json.dumps(live, sort_keys=True) == before:
        return False
    target.parent.mkdir(parents=True, exist_ok=True)
    write_object(target, live)
    say(f"applied settings to {target}")
    return True


def run(argv: list[str]) -> int:
    """Echo and run a command.

    Returns:
        The command's exit status.
    """
    say("+ " + " ".join(argv))
    return subprocess.call(argv)  # noqa: S603 - argv built from fixed paths


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
        return bootstrap(ctx)
    _ = apply_settings(ctx)
    try:
        busy = busy_threads(ctx)
    except sqlite3.Error as error:
        say(f"cannot tell whether threads run ({error}); not updating")
        return 1
    if busy:
        say(f"{busy} thread(s) running; postponing the update")
        return 0
    # `t3 update` verifies the release checksums and that the new runtime starts
    # before it repoints the service; --yes restarts it without a prompt.
    return run([str(binary), "update", "--yes", "--channel", ctx.channel])


def sync(ctx: Context) -> int:
    """Apply settings and Claude models; T3 reloads them without a restart.

    Returns:
        The exit status.
    """
    if installed_binary(ctx) is None:
        say("not installed yet; nothing to sync")
        return 0
    _ = apply_settings(ctx)
    return 0


def main(argv: list[str] | None = None) -> int:
    """Run the command line.

    Returns:
        The exit status.
    """
    parser = argparse.ArgumentParser(prog="t3ctl")
    _ = parser.add_argument("command", choices=("update", "sync"))
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
    return update(ctx) if args.command == "update" else sync(ctx)


if __name__ == "__main__":
    raise SystemExit(main())
