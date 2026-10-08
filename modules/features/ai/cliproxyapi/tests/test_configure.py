"""Unit and contract tests for configure.py and release.py CLIProxyAPI helpers."""

import http.server
import importlib.util
import json
import sys
import threading
from collections.abc import Mapping, Sequence
from pathlib import Path
from typing import Protocol, TypeIs, cast, override

import pytest
import yaml


class CredentialFactory(Protocol):
    def __call__(
        self, api_key: str, weight: int | None = None, proxy_url: str | None = None
    ) -> object: ...


class ConfigureModule(Protocol):
    ConfigureError: type[Exception]
    Credential: CredentialFactory

    def merge_config(
        self, settings_content: str, pools: Mapping[str, Sequence[object]]
    ) -> str: ...
    def parse_secrets_json(self, content: str) -> dict[str, list[object]]: ...
    def main(self, argv: Sequence[str] | None = None) -> int: ...


def load_configure() -> ConfigureModule:
    spec = importlib.util.spec_from_file_location(
        "cliproxy_configure", Path(__file__).parents[1] / "configure.py"
    )
    assert spec is not None
    assert spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    # Loaded by path: the checker cannot see the module, so a Protocol mirrors it.
    return cast("ConfigureModule", cast("object", module))


configure = load_configure()
ConfigureError = configure.ConfigureError
Credential = configure.Credential
merge_config = configure.merge_config
parse_secrets_json = configure.parse_secrets_json


def is_dict(value: object) -> TypeIs[dict[str, object]]:
    return isinstance(value, dict)


def is_list(value: object) -> TypeIs[list[object]]:
    return isinstance(value, list)


def yaml_dict(text: str) -> dict[str, object]:
    # yaml.safe_load is typed Any; narrowed immediately.
    loaded = cast("object", yaml.safe_load(text))
    assert is_dict(loaded)
    return loaded


def entries(data: dict[str, object], key: str) -> list[dict[str, object]]:
    value = data[key]
    assert is_list(value)
    result: list[dict[str, object]] = []
    for item in value:
        assert is_dict(item)
        result.append(item)
    return result


def test_parse_secrets_valid() -> None:
    content = json.dumps({
        "CLIPROXY_CREDENTIAL_POOLS": {
            "opencode-go": [
                {"apiKey": "key1", "weight": 10},
                {"apiKey": "key2", "proxyUrl": "http://127.0.0.1:8080"},
            ],
            "mimo": [
                {"apiKey": "key3"},
            ],
        },
        "CLIPROXY_FUNNEL_TOKEN": "token-12345678901234567890123456789012",
    })
    pools = parse_secrets_json(content)
    assert len(pools) == 2
    assert "opencode-go" in pools
    assert pools["opencode-go"][0] == Credential(
        api_key="key1", weight=10, proxy_url=None
    )
    assert pools["opencode-go"][1] == Credential(
        api_key="key2", weight=None, proxy_url="http://127.0.0.1:8080"
    )
    assert pools["mimo"][0] == Credential(api_key="key3", weight=None, proxy_url=None)


def test_parse_secrets_duplicate_keys() -> None:
    content = json.dumps({
        "CLIPROXY_CREDENTIAL_POOLS": {
            "opencode-go": [
                {"apiKey": "dup-key"},
                {"apiKey": "dup-key"},
            ],
        },
    })
    with pytest.raises(ConfigureError, match="duplicate api-key"):
        _ = parse_secrets_json(content)


def test_parse_secrets_empty_pool() -> None:
    content = json.dumps({
        "CLIPROXY_CREDENTIAL_POOLS": {
            "empty-pool": [],
        },
    })
    with pytest.raises(ConfigureError, match="empty"):
        _ = parse_secrets_json(content)


def test_merge_config_expands_native_and_compatibility() -> None:
    settings_yaml = """
codex-api-key:
  - x-credential-pool: "opencode-go"
    base-url: "https://opencode.ai/zen/go/v1"
    prefix: "opencode-go"
openai-compatibility:
  - name: "custom-mimo"
    x-credential-pool: "mimo"
    base-url: "https://token-plan.mimo.com/v1"
"""
    pools = {
        "opencode-go": [
            Credential(api_key="key1", weight=5),
            Credential(api_key="key2"),
        ],
        "mimo": [
            Credential(api_key="mimo-key1"),
        ],
    }
    rendered = merge_config(settings_yaml, pools)
    data = yaml_dict(rendered)
    native = entries(data, "codex-api-key")
    compat = entries(data, "openai-compatibility")

    # Native expansion creates 2 items
    assert len(native) == 2
    assert native[0]["api-key"] == "key1"
    assert native[0]["weight"] == 5
    assert native[0]["base-url"] == "https://opencode.ai/zen/go/v1"
    assert native[1]["api-key"] == "key2"
    assert "x-credential-pool" not in native[0]

    # OpenAI-compatibility expansion adds api-key-entries
    assert len(compat) == 1
    assert compat[0]["name"] == "custom-mimo"
    assert compat[0]["api-key-entries"] == [{"api-key": "mimo-key1"}]
    assert "x-credential-pool" not in compat[0]


def test_merge_config_fails_on_unused_pools() -> None:
    settings_yaml = """
codex-api-key:
  - x-credential-pool: "opencode-go"
    base-url: "https://opencode.ai/zen/go/v1"
"""
    pools = {
        "opencode-go": [Credential(api_key="key1")],
        "unused-pool": [Credential(api_key="key2")],
    }
    with pytest.raises(ConfigureError, match="unused credential pools"):
        _ = merge_config(settings_yaml, pools)


def test_merge_config_fails_on_missing_pool() -> None:
    settings_yaml = """
codex-api-key:
  - x-credential-pool: "missing-pool"
"""
    pools = {
        "opencode-go": [Credential(api_key="key1")],
    }
    with pytest.raises(ConfigureError, match="references unknown pool"):
        _ = merge_config(settings_yaml, pools)


DISCOVERY_SETTINGS = """
openai-compatibility:
  - name: "zen"
    base-url: "{base_url}"
    prefix: "zen"
    x-credential-pool: "zen"
    x-model-discovery: true
    x-model-exclude: ["hidden"]
"""


class ModelListing(http.server.BaseHTTPRequestHandler):
    def do_GET(self) -> None:
        authorized = self.headers.get("Authorization") == "Bearer zen-key"
        if self.path != "/v1/models" or not authorized:
            self.send_response(401)
            self.end_headers()
            return
        body = json.dumps({
            "data": [
                {"id": "gpt-x", "name": "GPT X", "context_length": 400000},
                {"id": "hidden"},
            ]
        }).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        _ = self.wfile.write(body)

    @override
    def log_message(self, format: str, *args: object) -> None:
        pass


def run_configure(tmp_path: Path, base_url: str) -> dict[str, object]:
    settings = tmp_path / "settings.yaml"
    _ = settings.write_text(DISCOVERY_SETTINGS.format(base_url=base_url))
    secrets = tmp_path / "secrets.json"
    _ = secrets.write_text(
        json.dumps({"CLIPROXY_CREDENTIAL_POOLS": {"zen": [{"apiKey": "zen-key"}]}})
    )
    out = tmp_path / "config.yaml"
    code = configure.main([
        "--settings",
        str(settings),
        "--secrets",
        str(secrets),
        "--models-cache",
        str(tmp_path / "models.json"),
        "--out",
        str(out),
    ])
    assert code == 0
    return entries(yaml_dict(out.read_text()), "openai-compatibility")[0]


def test_discovery_lists_upstream_models_and_survives_an_outage(tmp_path: Path) -> None:
    server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), ModelListing)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    base_url = f"http://127.0.0.1:{server.server_address[1]}/v1"
    try:
        profile = run_configure(tmp_path, base_url)
    finally:
        server.shutdown()
        server.server_close()

    expected = [
        {"name": "gpt-x", "display-name": "GPT X", "max-context-length": 400000}
    ]
    assert profile["models"] == expected
    assert (
        not {"x-model-discovery", "x-model-exclude", "x-credential-pool"}
        & profile.keys()
    )

    assert run_configure(tmp_path, base_url)["models"] == expected


def test_discovery_without_a_listing_or_cache_declares_no_models(
    tmp_path: Path,
) -> None:
    assert run_configure(tmp_path, "http://127.0.0.1:9/v1")["models"] == []


def test_regenerating_keeps_the_watched_config_inode(tmp_path: Path) -> None:
    _ = run_configure(tmp_path, "http://127.0.0.1:9/v1")
    out = tmp_path / "config.yaml"
    inode = out.stat().st_ino
    _ = (tmp_path / "models.json").write_text(json.dumps({"zen": [{"name": "fresh"}]}))

    assert run_configure(tmp_path, "http://127.0.0.1:9/v1")["models"] == [
        {"name": "fresh"}
    ]
    assert out.stat().st_ino == inode
    assert out.stat().st_mode & 0o777 == 0o600


def test_exclusion_without_discovery_is_rejected() -> None:
    settings_yaml = """
openai-compatibility:
  - name: "zen"
    base-url: "https://example.test/v1"
    x-credential-pool: "zen"
    x-model-exclude: ["hidden"]
"""
    with pytest.raises(ConfigureError, match="requires x-model-discovery"):
        _ = merge_config(settings_yaml, {"zen": [Credential(api_key="k")]})


def test_discovery_rejected_by_upstream_declares_no_models(tmp_path: Path) -> None:
    server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), ModelListing)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    try:
        profile = run_configure(
            tmp_path, f"http://127.0.0.1:{server.server_address[1]}/wrong"
        )
    finally:
        server.shutdown()
        server.server_close()
        thread.join()

    assert profile["models"] == []
