#!/usr/bin/env python3
# Copyright (c) 2026 rice authors. SPDX-License-Identifier: AGPL-3.0-or-later
"""Runtime CLIProxyAPI configuration generator.

Merges Nix-generated native YAML settings and private JSON secrets into a
concrete runtime YAML config. Expands x-credential-pool markers across native
credential sections and openai-compatibility pools, validating that every
referenced pool exists and that no credentials are duplicated.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import stat
import sys
import tempfile
from collections.abc import Mapping, Sequence
from dataclasses import dataclass
from pathlib import Path
from typing import Final, TypeIs

import yaml

POOL_NAME_PATTERN: Final[re.Pattern[str]] = re.compile(r"^[a-z][a-z0-9-]*$")
POOL_MARKER: Final[str] = "x-credential-pool"

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


@dataclass(frozen=True, slots=True)
class Credential:
    api_key: str
    weight: int | None = None
    proxy_url: str | None = None


def is_obj_dict(val: object) -> TypeIs[dict[str, object]]:
    return isinstance(val, dict)


def is_obj_list(val: object) -> TypeIs[list[object]]:
    return isinstance(val, list)


def parse_secrets_json(content: str) -> dict[str, list[Credential]]:
    try:
        raw: object = json.loads(content)
    except Exception as err:  # noqa: BLE001 - parse boundary
        raise ConfigureError(f"failed to parse secrets JSON: {err}") from err

    if not is_obj_dict(raw):
        raise ConfigureError("secrets JSON root must be an object")

    raw_pools = raw.get("CLIPROXY_CREDENTIAL_POOLS")
    if raw_pools is None:
        raise ConfigureError("missing CLIPROXY_CREDENTIAL_POOLS in secrets")
    if not is_obj_dict(raw_pools):
        raise ConfigureError("CLIPROXY_CREDENTIAL_POOLS must be an object")

    parsed_pools: dict[str, list[Credential]] = {}
    for pool_name, items in raw_pools.items():
        if not POOL_NAME_PATTERN.match(pool_name):
            raise ConfigureError(f"invalid credential pool name: {pool_name!r}")
        if not is_obj_list(items):
            raise ConfigureError(f"credential pool {pool_name!r} must be a list")
        if not items:
            raise ConfigureError(f"credential pool {pool_name!r} is empty")

        creds: list[Credential] = []
        seen_keys: set[str] = set()
        for idx, item in enumerate(items):
            if not is_obj_dict(item):
                raise ConfigureError(f"pool {pool_name}[{idx}] must be an object")
            api_key_obj = item.get("apiKey") or item.get("api-key")
            if not isinstance(api_key_obj, str) or not api_key_obj.strip():
                raise ConfigureError(f"pool {pool_name}[{idx}] missing valid apiKey")
            api_key = api_key_obj.strip()
            if api_key in seen_keys:
                raise ConfigureError(f"duplicate api-key in pool {pool_name!r}")
            seen_keys.add(api_key)

            weight: int | None = None
            if "weight" in item and item["weight"] is not None:
                if not isinstance(item["weight"], int) or item["weight"] < 1:
                    raise ConfigureError(f"pool {pool_name}[{idx}] invalid weight: {item['weight']}")
                weight = item["weight"]

            proxy_url: str | None = None
            raw_url = item.get("proxyUrl") or item.get("proxy-url")
            if raw_url is not None:
                if not isinstance(raw_url, str) or not raw_url.strip():
                    raise ConfigureError(f"pool {pool_name}[{idx}] invalid proxyUrl")
                proxy_url = raw_url.strip()

            creds.append(Credential(api_key=api_key, weight=weight, proxy_url=proxy_url))
        parsed_pools[pool_name] = creds

    return parsed_pools


def credential_config(cred: Credential) -> dict[str, object]:
    res: dict[str, object] = {"api-key": cred.api_key}
    if cred.weight is not None:
        res["weight"] = cred.weight
    if cred.proxy_url is not None:
        res["proxy-url"] = cred.proxy_url
    return res


def expand_native_section(
    section_name: str,
    items: object,
    pools: Mapping[str, Sequence[Credential]],
    referenced: set[str],
) -> list[dict[str, object]]:
    if not is_obj_list(items):
        raise ConfigureError(f"section {section_name!r} must be a list")

    expanded: list[dict[str, object]] = []
    for idx, item in enumerate(items):
        label = f"{section_name}[{idx}]"
        if not is_obj_dict(item):
            raise ConfigureError(f"{label} must be an object")
        profile = dict(item)

        if POOL_MARKER not in profile:
            expanded.append(profile)
            continue

        pool_marker_val = profile.pop(POOL_MARKER)
        if not isinstance(pool_marker_val, str) or not pool_marker_val.strip():
            raise ConfigureError(f"{label}.{POOL_MARKER} must be a non-empty string")
        pool_name = pool_marker_val.strip()

        for owned in OWNED_NATIVE_FIELDS:
            if owned in profile:
                raise ConfigureError(f"{label} cannot declare {owned} when using {POOL_MARKER}")

        if pool_name not in pools:
            raise ConfigureError(f"{label} references unknown pool {pool_name!r}")

        referenced.add(pool_name)
        for cred in pools[pool_name]:
            expanded.append(credential_config(cred) | profile)

    return expanded


def expand_compatibility_section(
    items: object,
    pools: Mapping[str, Sequence[Credential]],
    referenced: set[str],
) -> list[dict[str, object]]:
    if not is_obj_list(items):
        raise ConfigureError("'openai-compatibility' must be a list")

    expanded: list[dict[str, object]] = []
    for idx, item in enumerate(items):
        label = f"openai-compatibility[{idx}]"
        if not is_obj_dict(item):
            raise ConfigureError(f"{label} must be an object")
        profile = dict(item)

        if POOL_MARKER not in profile:
            expanded.append(profile)
            continue

        pool_marker_val = profile.pop(POOL_MARKER)
        if not isinstance(pool_marker_val, str) or not pool_marker_val.strip():
            raise ConfigureError(f"{label}.{POOL_MARKER} must be a non-empty string")
        pool_name = pool_marker_val.strip()

        for owned in OWNED_COMPATIBILITY_FIELDS:
            if owned in profile:
                raise ConfigureError(f"{label} cannot declare {owned} when using {POOL_MARKER}")

        if pool_name not in pools:
            raise ConfigureError(f"{label} references unknown pool {pool_name!r}")

        referenced.add(pool_name)
        creds = pools[pool_name]
        profile["api-key-entries"] = [credential_config(c) for c in creds]
        expanded.append(profile)

    return expanded


def merge_config(
    settings_content: str,
    pools: Mapping[str, Sequence[Credential]],
) -> str:
    try:
        raw_config: object = yaml.safe_load(settings_content)
    except Exception as err:  # noqa: BLE001 - parse boundary
        raise ConfigureError(f"failed to parse base settings YAML: {err}") from err

    if not is_obj_dict(raw_config):
        raise ConfigureError("base settings YAML must be an object")

    config = dict(raw_config)
    referenced_pools: set[str] = set()

    for sec in NATIVE_CREDENTIAL_SECTIONS:
        if sec in config:
            config[sec] = expand_native_section(sec, config[sec], pools, referenced_pools)

    if "openai-compatibility" in config:
        config["openai-compatibility"] = expand_compatibility_section(
            config["openai-compatibility"],
            pools,
            referenced_pools,
        )

    # Validate that no defined pool was left unused
    unused = set(pools.keys()) - referenced_pools
    if unused:
        unused_str = ", ".join(sorted(unused))
        raise ConfigureError(f"unused credential pools in secrets: {unused_str}")

    return yaml.safe_dump(config, sort_keys=False)


def sync_file_atomically(path: Path, content: str, mode: int = 0o600) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(
        mode="w",
        dir=str(path.parent),
        encoding="utf-8",
        delete=False,
    ) as tmp:
        tmp.write(content)
        tmp_name = Path(tmp.name)

    os.chmod(tmp_name, mode)
    tmp_name.replace(path)


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Generate runtime CLIProxyAPI config.")
    parser.add_argument("--settings", required=True, help="Path to base settings YAML")
    parser.add_argument("--secrets", required=True, help="Path to secrets JSON file")
    parser.add_argument("--out", required=True, help="Output runtime config YAML path")

    args = parser.parse_args(argv)

    try:
        settings_text = Path(args.settings).read_text(encoding="utf-8")
        secrets_text = Path(args.secrets).read_text(encoding="utf-8")
        pools = parse_secrets_json(secrets_text)
        rendered_yaml = merge_config(settings_text, pools)
        sync_file_atomically(Path(args.out), rendered_yaml)
    except ConfigureError as err:
        sys.stderr.write(f"cliproxyapi configure error: {err}\n")
        return 1
    except Exception as err:  # noqa: BLE001 - CLI process boundary
        sys.stderr.write(f"cliproxyapi unexpected error: {err}\n")
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
