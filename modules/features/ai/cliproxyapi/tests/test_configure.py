"""Unit and contract tests for configure.py and release.py CLIProxyAPI helpers."""

import json
import importlib.util
import sys
from pathlib import Path

import pytest
import yaml

spec = importlib.util.spec_from_file_location("cliproxy_configure", Path(__file__).parents[1] / "configure.py")
configure = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = configure
spec.loader.exec_module(configure)
ConfigureError = configure.ConfigureError
Credential = configure.Credential
merge_config = configure.merge_config
parse_secrets_json = configure.parse_secrets_json


def test_parse_secrets_valid():
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
    assert pools["opencode-go"][0] == Credential(api_key="key1", weight=10, proxy_url=None)
    assert pools["opencode-go"][1] == Credential(api_key="key2", weight=None, proxy_url="http://127.0.0.1:8080")
    assert pools["mimo"][0] == Credential(api_key="key3", weight=None, proxy_url=None)


def test_parse_secrets_duplicate_keys():
    content = json.dumps({
        "CLIPROXY_CREDENTIAL_POOLS": {
            "opencode-go": [
                {"apiKey": "dup-key"},
                {"apiKey": "dup-key"},
            ],
        },
    })
    with pytest.raises(ConfigureError, match="duplicate api-key"):
        parse_secrets_json(content)


def test_parse_secrets_empty_pool():
    content = json.dumps({
        "CLIPROXY_CREDENTIAL_POOLS": {
            "empty-pool": [],
        },
    })
    with pytest.raises(ConfigureError, match="empty"):
        parse_secrets_json(content)


def test_merge_config_expands_native_and_compatibility():
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
    data = yaml.safe_load(rendered)

    # Native expansion creates 2 items
    assert len(data["codex-api-key"]) == 2
    assert data["codex-api-key"][0]["api-key"] == "key1"
    assert data["codex-api-key"][0]["weight"] == 5
    assert data["codex-api-key"][0]["base-url"] == "https://opencode.ai/zen/go/v1"
    assert data["codex-api-key"][1]["api-key"] == "key2"
    assert "x-credential-pool" not in data["codex-api-key"][0]

    # OpenAI-compatibility expansion adds api-key-entries
    assert len(data["openai-compatibility"]) == 1
    assert data["openai-compatibility"][0]["name"] == "custom-mimo"
    assert data["openai-compatibility"][0]["api-key-entries"] == [{"api-key": "mimo-key1"}]
    assert "x-credential-pool" not in data["openai-compatibility"][0]


def test_merge_config_fails_on_unused_pools():
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
        merge_config(settings_yaml, pools)


def test_merge_config_fails_on_missing_pool():
    settings_yaml = """
codex-api-key:
  - x-credential-pool: "missing-pool"
"""
    pools = {
        "opencode-go": [Credential(api_key="key1")],
    }
    with pytest.raises(ConfigureError, match="references unknown pool"):
        merge_config(settings_yaml, pools)
