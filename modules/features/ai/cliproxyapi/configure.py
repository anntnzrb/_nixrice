#!/usr/bin/env python3
# Copyright (c) 2026 rice authors. SPDX-License-Identifier: AGPL-3.0-or-later
"""Runtime CLIProxyAPI configuration generator.

Merges Nix-generated native YAML settings and private JSON secrets into a
concrete runtime YAML config. Expands x-credential-pool markers across native
credential sections and openai-compatibility pools, validating that every
referenced pool exists and that no credentials are duplicated. Pools marked
x-model-discovery list the upstream's current models; the last successful
listing is cached so an unreachable upstream keeps its previous models.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import tempfile
import urllib.request
from collections.abc import Callable, Mapping, Sequence
from dataclasses import dataclass
from pathlib import Path
from typing import Final, NotRequired, Protocol, TypedDict, TypeIs, cast

import yaml

POOL_NAME_PATTERN: Final[re.Pattern[str]] = re.compile(r"^[a-z][a-z0-9-]*$")
POOL_MARKER: Final[str] = "x-credential-pool"
DISCOVERY_MARKER: Final[str] = "x-model-discovery"
EXCLUDE_MARKER: Final[str] = "x-model-exclude"
DISCOVERY_TIMEOUT_SECONDS: Final[float] = 10.0

ModelEntry = TypedDict(
    "ModelEntry",
    {
        "name": str,
        "display-name": NotRequired[str],
        "max-context-length": NotRequired[int],
    },
)
type ModelFetcher = Callable[[str, str], list[ModelEntry] | None]
type ModelCache = dict[str, list[ModelEntry]]

NATIVE_CREDENTIAL_SECTIONS: Final[tuple[str, ...]] = (
    "claude-api-key",
    "codex-api-key",
    "gemini-api-key",
    "vertex-api-key",
    "anthropic-api-key",
    "openai-api-key",
)

OWNED_NATIVE_FIELDS: Final[tuple[str, ...]] = ("api-key", "weight", "proxy-url")
OWNED_COMPATIBILITY_FIELDS: Final[tuple[str, ...]] = ("api-key-entries",)


class ConfigureError(Exception):
    """Configuration error for CLIProxyAPI setup."""


class Response(Protocol):
    """The part of an HTTP response that model discovery reads."""

    def read(self) -> bytes:
        """Read the response body."""
        ...

    def close(self) -> None:
        """Release the connection."""
        ...


@dataclass(frozen=True, slots=True)
class Credential:
    """One upstream API key with its optional weight and proxy."""

    api_key: str
    weight: int | None = None
    proxy_url: str | None = None


def is_obj_dict(val: object) -> TypeIs[dict[str, object]]:
    """Check whether `val` is a dict.

    Returns:
        True when `val` is a dict.
    """
    return isinstance(val, dict)


def is_obj_list(val: object) -> TypeIs[list[object]]:
    """Check whether `val` is a list.

    Returns:
        True when `val` is a list.
    """
    return isinstance(val, list)


def json_loads(content: str | bytes) -> object:
    """Parse JSON text, typing the result as `object`.

    Returns:
        The decoded JSON value.
    """
    # json.loads is typed Any; the result is only ever narrowed as object.
    return cast("object", json.loads(content))


def parse_credential(
    pool_name: str, idx: int, item: object, seen_keys: set[str]
) -> Credential:
    """Validate one pool entry and record its key in `seen_keys`.

    Returns:
        The parsed credential.

    Raises:
        ConfigureError: The entry is malformed or repeats a key.
    """
    if not is_obj_dict(item):
        msg = f"pool {pool_name}[{idx}] must be an object"
        raise ConfigureError(msg)
    api_key_obj = item.get("apiKey") or item.get("api-key")
    if not isinstance(api_key_obj, str) or not api_key_obj.strip():
        msg = f"pool {pool_name}[{idx}] missing valid apiKey"
        raise ConfigureError(msg)
    api_key = api_key_obj.strip()
    if api_key in seen_keys:
        msg = f"duplicate api-key in pool {pool_name!r}"
        raise ConfigureError(msg)
    seen_keys.add(api_key)

    weight: int | None = None
    raw_weight = item.get("weight")
    if raw_weight is not None:
        if not isinstance(raw_weight, int) or raw_weight < 1:
            msg = f"pool {pool_name}[{idx}] invalid weight: {raw_weight}"
            raise ConfigureError(msg)
        weight = raw_weight

    proxy_url: str | None = None
    raw_url = item.get("proxyUrl") or item.get("proxy-url")
    if raw_url is not None:
        if not isinstance(raw_url, str) or not raw_url.strip():
            msg = f"pool {pool_name}[{idx}] invalid proxyUrl"
            raise ConfigureError(msg)
        proxy_url = raw_url.strip()

    return Credential(api_key=api_key, weight=weight, proxy_url=proxy_url)


def parse_pool(pool_name: str, items: object) -> list[Credential]:
    """Validate a named pool and parse its credentials.

    Returns:
        The pool's credentials in declared order.

    Raises:
        ConfigureError: The name is invalid or the pool is not a non-empty list.
    """
    if not POOL_NAME_PATTERN.match(pool_name):
        msg = f"invalid credential pool name: {pool_name!r}"
        raise ConfigureError(msg)
    if not is_obj_list(items):
        msg = f"credential pool {pool_name!r} must be a list"
        raise ConfigureError(msg)
    if not items:
        msg = f"credential pool {pool_name!r} is empty"
        raise ConfigureError(msg)

    creds: list[Credential] = []
    seen_keys: set[str] = set()
    for idx, item in enumerate(items):
        creds.append(parse_credential(pool_name, idx, item, seen_keys))
    return creds


def parse_secrets_json(content: str) -> dict[str, list[Credential]]:
    """Parse the secrets JSON into credential pools.

    Returns:
        The credential pools by name.

    Raises:
        ConfigureError: The JSON is invalid or lacks a valid pool object.
    """
    try:
        raw = json_loads(content)
    except Exception as err:
        msg = f"failed to parse secrets JSON: {err}"
        raise ConfigureError(msg) from err

    if not is_obj_dict(raw):
        msg = "secrets JSON root must be an object"
        raise ConfigureError(msg)

    raw_pools = raw.get("CLIPROXY_CREDENTIAL_POOLS")
    if raw_pools is None:
        msg = "missing CLIPROXY_CREDENTIAL_POOLS in secrets"
        raise ConfigureError(msg)
    if not is_obj_dict(raw_pools):
        msg = "CLIPROXY_CREDENTIAL_POOLS must be an object"
        raise ConfigureError(msg)

    return {
        pool_name: parse_pool(pool_name, items)
        for pool_name, items in raw_pools.items()
    }


def credential_config(cred: Credential) -> dict[str, object]:
    """Render a credential as a CLIProxyAPI key entry.

    Returns:
        The entry with `api-key` and any weight or proxy.
    """
    res: dict[str, object] = {"api-key": cred.api_key}
    if cred.weight is not None:
        res["weight"] = cred.weight
    if cred.proxy_url is not None:
        res["proxy-url"] = cred.proxy_url
    return res


def parse_model_listing(payload: object) -> list[ModelEntry] | None:
    """Project an OpenAI-style `/models` response into CLIProxyAPI model entries.

    Returns:
        The models, or None when the payload is not a model listing.
    """
    if not is_obj_dict(payload):
        return None
    data = payload.get("data")
    if not is_obj_list(data):
        return None
    models: list[ModelEntry] = []
    for item in data:
        if not is_obj_dict(item):
            continue
        identifier = item.get("id")
        if not isinstance(identifier, str) or not identifier:
            continue
        entry: ModelEntry = {"name": identifier}
        display_name = item.get("name")
        if isinstance(display_name, str) and display_name:
            entry["display-name"] = display_name
        context_length = item.get("context_length")
        if (
            isinstance(context_length, int)
            and not isinstance(context_length, bool)
            and context_length > 0
        ):
            entry["max-context-length"] = context_length
        models.append(entry)
    return models


def get_json(request: urllib.request.Request) -> object:
    """Fetch and decode a JSON document.

    Returns:
        The decoded JSON value.
    """
    # typeshed types urlopen as Any; the HTTP(S) opener returns an HTTPResponse.
    response = cast(
        "Response",
        urllib.request.urlopen(request, timeout=DISCOVERY_TIMEOUT_SECONDS),  # noqa: S310 - base-url comes from operator-owned settings
    )
    try:
        return json_loads(response.read())
    finally:
        response.close()


def fetch_models(base_url: str, api_key: str) -> list[ModelEntry] | None:
    """Return the upstream's current models, or None when it cannot be listed.

    Returns:
        The models, or None when the upstream cannot be listed.
    """
    request = urllib.request.Request(  # noqa: S310 - base-url comes from operator-owned settings
        f"{base_url.rstrip('/')}/models",
        headers={
            "Accept": "application/json",
            "Authorization": f"Bearer {api_key}",
            "User-Agent": "rice-cliproxyapi/1.0",
        },
    )
    try:
        payload = get_json(request)
    except (OSError, ValueError):
        return None
    return parse_model_listing(payload)


def parse_model_cache(content: str) -> ModelCache:
    """Parse the discovered-model cache file.

    Returns:
        The cached models by profile name.

    Raises:
        ConfigureError: The cache is not valid JSON of the expected shape.
    """
    try:
        raw = json_loads(content)
    except ValueError as err:
        msg = f"failed to parse model cache: {err}"
        raise ConfigureError(msg) from err
    if not is_obj_dict(raw):
        msg = "model cache root must be an object"
        raise ConfigureError(msg)
    cache: ModelCache = {}
    for profile_name, entries in raw.items():
        if not is_obj_list(entries):
            msg = f"model cache entry {profile_name!r} must be a list"
            raise ConfigureError(msg)
        models: list[ModelEntry] = []
        for item in entries:
            if not is_obj_dict(item) or not isinstance(item.get("name"), str):
                msg = f"model cache entry {profile_name!r} has an invalid model"
                raise ConfigureError(msg)
            entry: ModelEntry = {"name": str(item["name"])}
            display_name = item.get("display-name")
            if isinstance(display_name, str):
                entry["display-name"] = display_name
            context_length = item.get("max-context-length")
            if isinstance(context_length, int) and not isinstance(context_length, bool):
                entry["max-context-length"] = context_length
            models.append(entry)
        cache[profile_name] = models
    return cache


def discover_models(
    profile_name: str,
    base_url: str,
    credential: Credential,
    fetch: ModelFetcher,
    cache: ModelCache,
) -> list[ModelEntry]:
    """List a profile's models, falling back to the cache when unreachable.

    Returns:
        The listed models, else the cached ones, else none.
    """
    listed = fetch(base_url, credential.api_key)
    if listed is not None:
        cache[profile_name] = listed
        return listed
    prefix = f"cliproxyapi configure: cannot list models for {profile_name};"
    cached = cache.get(profile_name)
    if cached is None:
        print(f"{prefix} none declared", file=sys.stderr)
        return []
    print(f"{prefix} reusing cached models", file=sys.stderr)
    return cached


def expand_native_section(
    section_name: str,
    items: object,
    pools: Mapping[str, Sequence[Credential]],
    referenced: set[str],
) -> list[dict[str, object]]:
    """Expand pool markers in a native credential section.

    Returns:
        The section's entries with each pool marker replaced by its credentials.

    Raises:
        ConfigureError: The section or a marker is invalid.
    """
    if not is_obj_list(items):
        msg = f"section {section_name!r} must be a list"
        raise ConfigureError(msg)

    expanded: list[dict[str, object]] = []
    for idx, item in enumerate(items):
        label = f"{section_name}[{idx}]"
        if not is_obj_dict(item):
            msg = f"{label} must be an object"
            raise ConfigureError(msg)
        profile = dict(item)

        if POOL_MARKER not in profile:
            expanded.append(profile)
            continue

        pool_marker_val = profile.pop(POOL_MARKER)
        if not isinstance(pool_marker_val, str) or not pool_marker_val.strip():
            msg = f"{label}.{POOL_MARKER} must be a non-empty string"
            raise ConfigureError(msg)
        pool_name = pool_marker_val.strip()

        for owned in OWNED_NATIVE_FIELDS:
            if owned in profile:
                msg = f"{label} cannot declare {owned} when using {POOL_MARKER}"
                raise ConfigureError(msg)

        if pool_name not in pools:
            msg = f"{label} references unknown pool {pool_name!r}"
            raise ConfigureError(msg)

        referenced.add(pool_name)
        expanded.extend(credential_config(cred) | profile for cred in pools[pool_name])

    return expanded


def apply_model_discovery(
    label: str,
    profile: dict[str, object],
    creds: Sequence[Credential],
    fetch: ModelFetcher,
    cache: ModelCache,
) -> None:
    """Replace the discovery markers in `profile` with the discovered models.

    Raises:
        ConfigureError: The discovery or exclusion markers are invalid.
    """
    excluded: frozenset[str] = frozenset()
    if EXCLUDE_MARKER in profile:
        raw_excluded = profile.pop(EXCLUDE_MARKER)
        if DISCOVERY_MARKER not in profile:
            msg = f"{label}.{EXCLUDE_MARKER} requires {DISCOVERY_MARKER}"
            raise ConfigureError(msg)
        if not is_obj_list(raw_excluded) or not all(
            isinstance(m, str) and m for m in raw_excluded
        ):
            msg = f"{label}.{EXCLUDE_MARKER} must be a list of model ids"
            raise ConfigureError(msg)
        excluded = frozenset(m for m in raw_excluded if isinstance(m, str))
    if DISCOVERY_MARKER in profile:
        if profile.pop(DISCOVERY_MARKER) is not True:
            msg = f"{label}.{DISCOVERY_MARKER} must be true"
            raise ConfigureError(msg)
        if "models" in profile:
            msg = f"{label} cannot declare models when using {DISCOVERY_MARKER}"
            raise ConfigureError(msg)
        profile_name = profile.get("name")
        base_url = profile.get("base-url")
        if not isinstance(profile_name, str) or not isinstance(base_url, str):
            msg = f"{label}.{DISCOVERY_MARKER} requires name and base-url"
            raise ConfigureError(msg)
        profile["models"] = [
            model
            for model in discover_models(profile_name, base_url, creds[0], fetch, cache)
            if model["name"] not in excluded
        ]


def take_compatibility_pool(
    label: str,
    profile: dict[str, object],
    pools: Mapping[str, Sequence[Credential]],
    referenced: set[str],
) -> Sequence[Credential] | None:
    """Pop the pool marker and return its credentials, or None without a marker.

    Returns:
        The referenced pool's credentials, or None without a marker.

    Raises:
        ConfigureError: The marker is invalid or names an unknown pool.
    """
    if POOL_MARKER not in profile:
        return None

    pool_marker_val = profile.pop(POOL_MARKER)
    if not isinstance(pool_marker_val, str) or not pool_marker_val.strip():
        msg = f"{label}.{POOL_MARKER} must be a non-empty string"
        raise ConfigureError(msg)
    pool_name = pool_marker_val.strip()

    for owned in OWNED_COMPATIBILITY_FIELDS:
        if owned in profile:
            msg = f"{label} cannot declare {owned} when using {POOL_MARKER}"
            raise ConfigureError(msg)

    if pool_name not in pools:
        msg = f"{label} references unknown pool {pool_name!r}"
        raise ConfigureError(msg)

    referenced.add(pool_name)
    return pools[pool_name]


def expand_compatibility_section(
    items: object,
    pools: Mapping[str, Sequence[Credential]],
    referenced: set[str],
    fetch: ModelFetcher,
    cache: ModelCache,
) -> list[dict[str, object]]:
    """Expand pool and discovery markers in `openai-compatibility`.

    Returns:
        The profiles with credentials and discovered models filled in.

    Raises:
        ConfigureError: The section or a profile is invalid.
    """
    if not is_obj_list(items):
        msg = "'openai-compatibility' must be a list"
        raise ConfigureError(msg)

    expanded: list[dict[str, object]] = []
    for idx, item in enumerate(items):
        label = f"openai-compatibility[{idx}]"
        if not is_obj_dict(item):
            msg = f"{label} must be an object"
            raise ConfigureError(msg)
        profile = dict(item)

        creds = take_compatibility_pool(label, profile, pools, referenced)
        if creds is None:
            for marker in (DISCOVERY_MARKER, EXCLUDE_MARKER):
                if marker in profile:
                    msg = f"{label}.{marker} requires {POOL_MARKER}"
                    raise ConfigureError(msg)
            expanded.append(profile)
            continue

        apply_model_discovery(label, profile, creds, fetch, cache)
        profile["api-key-entries"] = [credential_config(c) for c in creds]
        expanded.append(profile)

    return expanded


def yaml_load(content: str) -> object:
    """Parse YAML text, typing the result as `object`.

    Returns:
        The decoded YAML value.
    """
    # yaml.safe_load is typed Any; the result is only ever narrowed as object.
    return cast("object", yaml.safe_load(content))


def merge_config(
    settings_content: str,
    pools: Mapping[str, Sequence[Credential]],
    fetch: ModelFetcher = fetch_models,
    cache: ModelCache | None = None,
) -> str:
    """Render the runtime config; discovery updates `cache` in place.

    Returns:
        The runtime config as YAML.

    Raises:
        ConfigureError: The settings are invalid or a pool goes unused.
    """
    model_cache: ModelCache = {} if cache is None else cache
    try:
        raw_config = yaml_load(settings_content)
    except Exception as err:
        msg = f"failed to parse base settings YAML: {err}"
        raise ConfigureError(msg) from err

    if not is_obj_dict(raw_config):
        msg = "base settings YAML must be an object"
        raise ConfigureError(msg)

    config = dict(raw_config)
    referenced_pools: set[str] = set()

    for sec in NATIVE_CREDENTIAL_SECTIONS:
        if sec in config:
            config[sec] = expand_native_section(
                sec, config[sec], pools, referenced_pools
            )

    if "openai-compatibility" in config:
        config["openai-compatibility"] = expand_compatibility_section(
            config["openai-compatibility"],
            pools,
            referenced_pools,
            fetch,
            model_cache,
        )

    # Validate that no defined pool was left unused
    unused = set(pools.keys()) - referenced_pools
    if unused:
        unused_str = ", ".join(sorted(unused))
        msg = f"unused credential pools in secrets: {unused_str}"
        raise ConfigureError(msg)

    return yaml.safe_dump(config, sort_keys=False)


def sync_file_atomically(path: Path, content: str, mode: int = 0o600) -> None:
    """Write `content` to `path` through a temp file and rename."""
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(
        mode="w",
        dir=str(path.parent),
        encoding="utf-8",
        delete=False,
    ) as tmp:
        _ = tmp.write(content)
        tmp_name = Path(tmp.name)

    tmp_name.chmod(mode)
    _ = tmp_name.replace(path)


def write_in_place(path: Path, content: str) -> None:
    """Rewrite the live config without replacing its inode.

    CLIProxyAPI watches the config file itself; a rename would drop that watch,
    so only an in-place write triggers its hot reload.
    """
    if path.exists() and path.read_text(encoding="utf-8") == content:
        return
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, "w", encoding="utf-8") as handle:
        _ = handle.write(content)


class Arguments(argparse.Namespace):
    """Parsed command-line arguments."""

    settings: str = ""
    secrets: str = ""
    models_cache: str = ""
    out: str | None = None


def run(args: Arguments) -> None:
    """Generate the model cache and, with `--out`, the runtime config."""
    settings_text = Path(args.settings).read_text(encoding="utf-8")
    secrets_text = Path(args.secrets).read_text(encoding="utf-8")
    cache_path = Path(args.models_cache)
    cache = (
        parse_model_cache(cache_path.read_text(encoding="utf-8"))
        if cache_path.exists()
        else {}
    )
    pools = parse_secrets_json(secrets_text)
    rendered_yaml = merge_config(settings_text, pools, cache=cache)
    sync_file_atomically(cache_path, f"{json.dumps(cache, indent=2, sort_keys=True)}\n")
    if args.out:
        write_in_place(Path(args.out), rendered_yaml)


def main(argv: Sequence[str] | None = None) -> int:
    """Run the CLI.

    Returns:
        The process exit code.
    """
    parser = argparse.ArgumentParser(description="Generate runtime CLIProxyAPI config.")
    _ = parser.add_argument(
        "--settings", required=True, help="Path to base settings YAML"
    )
    _ = parser.add_argument(
        "--secrets", required=True, help="Path to secrets JSON file"
    )
    _ = parser.add_argument(
        "--models-cache", required=True, help="Path to the discovered-model cache"
    )
    _ = parser.add_argument(
        "--out", help="Output runtime config YAML path; omit to refresh only the cache"
    )

    args = parser.parse_args(argv, namespace=Arguments())

    try:
        run(args)
    except ConfigureError as err:
        print(f"cliproxyapi configure error: {err}", file=sys.stderr)
        return 1
    except Exception as err:  # noqa: BLE001 - CLI process boundary
        print(f"cliproxyapi unexpected error: {err}", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
