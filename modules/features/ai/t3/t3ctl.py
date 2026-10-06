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
from dataclasses import dataclass
from pathlib import Path
from typing import cast

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
    wrappers: dict[str, str]
    gateway: str

    @property
    def runtime(self) -> Path:
        return self.home / "runtime"

    @property
    def userdata(self) -> Path:
        return self.home / "userdata"


def say(message: str) -> None:
    sys.stdout.write(f"t3: {message}\n")
    sys.stdout.flush()


def load_object(path: Path) -> JsonObject | None:
    """Read a JSON object; None when the file is missing or not an object."""
    try:
        data: object = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return None
    return cast("JsonObject", data) if isinstance(data, dict) else None


def write_object(path: Path, data: JsonObject) -> None:
    """Replace a JSON file atomically; T3 watches the settings file for edits."""
    fd, tmp = tempfile.mkstemp(dir=path.parent, suffix=".json")
    with os.fdopen(fd, "w", encoding="utf-8") as handle:
        json.dump(data, handle, indent=2)
        handle.write("\n")
    Path(tmp).replace(path)


def installed_binary(ctx: Context) -> Path | None:
    """The executable of the runtime the service currently runs."""
    state = load_object(ctx.runtime / "service-state.json") or {}
    version = state.get("activeVersion")
    if not isinstance(version, str) or not version:
        return None
    binary = ctx.runtime / "versions" / version / "t3"
    return binary if os.access(binary, os.X_OK) else None


def busy_threads(ctx: Context) -> int:
    """Count threads with an orchestration run that has not settled."""
    database = ctx.userdata / "statev2.sqlite"
    marks = ", ".join("?" for _ in BUSY_RUN_STATES)
    query = (
        "SELECT count(DISTINCT thread_id) FROM orchestration_v2_projection_runs "
        f"WHERE status IN ({marks})"
    )
    with sqlite3.connect(f"file:{database}?mode=ro", uri=True, timeout=10) as conn:
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


def instance_config(live: JsonObject, instance_id: str) -> JsonObject | None:
    instances = live.get("providerInstances")
    instance = instances.get(instance_id) if isinstance(instances, dict) else None
    if not isinstance(instance, dict):
        return None
    config = instance.get("config")
    if not isinstance(config, dict):
        config = {}
        instance["config"] = config
    return config


def point_at_wrappers(live: JsonObject, wrappers: dict[str, str]) -> None:
    """Run every harness through its sync-managed wrapper."""
    for instance_id, wrapper in wrappers.items():
        config = instance_config(live, instance_id)
        if config is not None:
            config["binaryPath"] = wrapper


def gateway_models(gateway: str) -> list[Json] | None:
    """Non-Anthropic gateway models as Claude custom models; None if unreachable."""
    request = urllib.request.Request(  # noqa: S310 - fixed tailnet gateway
        f"{gateway.rstrip('/')}/models",
        headers={"x-api-key": "keyless", "anthropic-version": "2023-06-01"},
    )
    try:
        with urllib.request.urlopen(request, timeout=10) as response:  # noqa: S310
            payload: object = json.loads(response.read())
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
    """Replace Claude's custom models with the gateway catalog; True if changed."""
    instances = live.get("providerInstances")
    instance = instances.get(CLAUDE_INSTANCE) if isinstance(instances, dict) else None
    if not isinstance(instance, dict) or not instance.get("enabled"):
        return False
    models = gateway_models(gateway)
    if models is None:
        say("gateway catalog unreachable; Claude models unchanged")
        return False
    config = instance_config(live, CLAUDE_INSTANCE)
    if config is None or config.get("customModels") == models:
        return False
    config["customModels"] = models
    say(f"Claude custom models -> {len(models)} gateway models")
    return True


def apply_settings(ctx: Context) -> bool:
    """Merge declared settings into the live file; True if it changed.

    Keys the declaration does not set, including ones changed from a client,
    survive. T3 reloads the file while running.
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
    point_at_wrappers(live, ctx.wrappers)
    refresh_claude_models(live, ctx.gateway)
    if json.dumps(live, sort_keys=True) == before:
        return False
    target.parent.mkdir(parents=True, exist_ok=True)
    write_object(target, live)
    say(f"applied settings to {target}")
    return True


def run(argv: list[str]) -> int:
    say("+ " + " ".join(argv))
    return subprocess.call(argv)  # noqa: S603 - argv built from fixed paths


def bootstrap(ctx: Context) -> int:
    """Install the service from the registry on a host without T3."""
    if run(["npx", "-y", f"t3@{ctx.channel}", "service", "install"]) != 0:
        return 1
    apply_settings(ctx)
    binary = installed_binary(ctx)
    return run([str(binary), "service", "restart"]) if binary else 1


def update(ctx: Context) -> int:
    """Install the channel head, restarting the service only when idle."""
    binary = installed_binary(ctx)
    if binary is None:
        say("not installed; bootstrapping")
        return bootstrap(ctx)
    apply_settings(ctx)
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


def refresh_models(ctx: Context) -> int:
    target = ctx.userdata / "settings.json"
    live = load_object(target)
    if live is None:
        say("not installed yet; no models to refresh")
        return 0
    if refresh_claude_models(live, ctx.gateway):
        write_object(target, live)
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="t3ctl")
    parser.add_argument("command", choices=("update", "refresh-models"))
    parser.add_argument("--channel", required=True, choices=("stable", "nightly"))
    parser.add_argument("--settings", required=True, type=Path)
    parser.add_argument("--gateway", required=True)
    parser.add_argument(
        "--wrapper",
        action="append",
        default=[],
        metavar="INSTANCE=PATH",
        help="harness instance id and the wrapper T3 must run for it",
    )
    args = parser.parse_args(argv)
    wrappers = dict(entry.split("=", 1) for entry in cast("list[str]", args.wrapper))
    ctx = Context(
        home=Path(os.environ.get("T3CODE_HOME") or Path.home() / ".t3"),
        channel=cast("str", args.channel),
        settings=cast("Path", args.settings),
        wrappers=wrappers,
        gateway=cast("str", args.gateway),
    )
    match cast("str", args.command):
        case "update":
            return update(ctx)
        case "refresh-models":
            return refresh_models(ctx)
        case _:
            return 2


if __name__ == "__main__":
    raise SystemExit(main())
