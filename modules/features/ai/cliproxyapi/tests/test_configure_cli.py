"""End-to-end tests for the configure.py command line."""

import http.server
import importlib.util
import json
import os
import socket
import string
import subprocess
import sys
import threading
from collections.abc import Iterator, Mapping, Sequence
from dataclasses import dataclass
from operator import itemgetter
from pathlib import Path
from typing import Protocol, TypeIs, cast, override

import pytest
import yaml
from hypothesis import given, settings
from hypothesis import strategies as st

SCRIPT = Path(__file__).parents[1] / "configure.py"
ERROR_PREFIX = "cliproxyapi configure error: "
EMPTY_ENTRY: dict[str, object] = {}
LABEL = "openai-compatibility[0]"
POOL_MARKER = "x-credential-pool"
POOL_A = json.dumps({"CLIPROXY_CREDENTIAL_POOLS": {"a": [{"apiKey": "k"}]}})


def is_dict(value: object) -> TypeIs[dict[str, object]]:
    return isinstance(value, dict)


def load_json_dict(text: str) -> dict[str, object]:
    # json.loads is typed Any; narrowed immediately.
    loaded = cast("object", json.loads(text))
    assert is_dict(loaded)
    return loaded


def load_yaml_dict(text: str) -> dict[str, object]:
    # yaml.safe_load is typed Any; narrowed immediately.
    loaded = cast("object", yaml.safe_load(text))
    assert is_dict(loaded)
    return loaded


def pools_json(pools: Mapping[str, object]) -> str:
    return json.dumps({"CLIPROXY_CREDENTIAL_POOLS": pools})


@dataclass(frozen=True)
class Result:
    code: int
    stdout: str
    stderr: str
    out: Path
    cache: Path


def run_raw(args: Sequence[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(  # noqa: S603 - fixed interpreter and script path
        [sys.executable, str(SCRIPT), *args],
        capture_output=True,
        text=True,
        check=False,
        env={**os.environ},
    )


def run_cli(
    tmp_path: Path,
    settings_text: str,
    secrets_text: str = POOL_A,
    cache_text: str | None = None,
    *,
    with_out: bool = True,
) -> Result:
    settings_path = tmp_path / "settings.yaml"
    secrets_path = tmp_path / "secrets.json"
    out = tmp_path / "config.yaml"
    cache = tmp_path / "state" / "models.json"
    _ = settings_path.write_text(settings_text)
    _ = secrets_path.write_text(secrets_text)
    if cache_text is not None:
        cache.parent.mkdir(parents=True, exist_ok=True)
        _ = cache.write_text(cache_text)
    args = [
        "--settings",
        str(settings_path),
        "--secrets",
        str(secrets_path),
        "--models-cache",
        str(cache),
    ]
    if with_out:
        args += ["--out", str(out)]
    done = run_raw(args)
    return Result(done.returncode, done.stdout, done.stderr, out, cache)


def native(entry: object) -> str:
    return json.dumps({"codex-api-key": [entry]})


def compat(entry: object) -> str:
    return json.dumps({"openai-compatibility": [entry]})


def assert_fails(result: Result, message: str) -> None:
    assert result.code == 1
    assert not result.stdout
    assert result.stderr == f"{ERROR_PREFIX}{message}\n"
    assert not result.out.exists()


SECRETS_ERRORS = [
    pytest.param("[]", "secrets JSON root must be an object", id="root-not-object"),
    pytest.param("{}", "missing CLIPROXY_CREDENTIAL_POOLS in secrets", id="no-pools"),
    pytest.param(
        '{"CLIPROXY_CREDENTIAL_POOLS": []}',
        "CLIPROXY_CREDENTIAL_POOLS must be an object",
        id="pools-not-object",
    ),
    pytest.param(
        pools_json({"Bad_Name": [{"apiKey": "k"}]}),
        "invalid credential pool name: 'Bad_Name'",
        id="bad-pool-name",
    ),
    pytest.param(
        pools_json({"a": {}}),
        "credential pool 'a' must be a list",
        id="pool-not-list",
    ),
    pytest.param(pools_json({"a": []}), "credential pool 'a' is empty", id="empty"),
    pytest.param(pools_json({"a": ["x"]}), "pool a[0] must be an object", id="entry"),
    pytest.param(
        pools_json({"a": [EMPTY_ENTRY]}), "pool a[0] missing valid apiKey", id="no-key"
    ),
    pytest.param(
        pools_json({"a": [{"apiKey": "  "}]}),
        "pool a[0] missing valid apiKey",
        id="blank-key",
    ),
    pytest.param(
        pools_json({"a": [{"apiKey": 5}]}),
        "pool a[0] missing valid apiKey",
        id="non-string-key",
    ),
    pytest.param(
        pools_json({"a": [{"apiKey": "k"}, {"api-key": " k "}]}),
        "duplicate api-key in pool 'a'",
        id="duplicate-after-strip",
    ),
    pytest.param(
        pools_json({"a": [{"apiKey": "k", "weight": 0}]}),
        "pool a[0] invalid weight: 0",
        id="weight-zero",
    ),
    pytest.param(
        pools_json({"a": [{"apiKey": "k", "weight": "5"}]}),
        "pool a[0] invalid weight: 5",
        id="weight-string",
    ),
    pytest.param(
        pools_json({"a": [{"apiKey": "k", "proxyUrl": 5}]}),
        "pool a[0] invalid proxyUrl",
        id="proxy-not-string",
    ),
    pytest.param(
        pools_json({"a": [{"apiKey": "k", "proxy-url": "  "}]}),
        "pool a[0] invalid proxyUrl",
        id="proxy-blank",
    ),
]


@pytest.mark.parametrize(("secrets_text", "message"), SECRETS_ERRORS)
def test_secrets_errors(tmp_path: Path, secrets_text: str, message: str) -> None:
    assert_fails(
        run_cli(tmp_path, native({"x-credential-pool": "a"}), secrets_text), message
    )


def test_secrets_invalid_json(tmp_path: Path) -> None:
    result = run_cli(tmp_path, "{}", "{nope")
    assert result.code == 1
    assert result.stderr.startswith(f"{ERROR_PREFIX}failed to parse secrets JSON: ")
    assert not result.out.exists()


NATIVE_MARKER = "codex-api-key[0].x-credential-pool must be a non-empty string"
NATIVE_ERRORS = [
    pytest.param(
        json.dumps({"codex-api-key": "x"}),
        "section 'codex-api-key' must be a list",
        id="section-not-list",
    ),
    pytest.param(native("x"), "codex-api-key[0] must be an object", id="not-object"),
    pytest.param(native({"x-credential-pool": ""}), NATIVE_MARKER, id="empty-marker"),
    pytest.param(native({"x-credential-pool": 5}), NATIVE_MARKER, id="int-marker"),
    pytest.param(
        native({"x-credential-pool": "a", "weight": 1}),
        "codex-api-key[0] cannot declare weight when using x-credential-pool",
        id="owned-field",
    ),
    pytest.param(
        native({"x-credential-pool": "b"}),
        "codex-api-key[0] references unknown pool 'b'",
        id="unknown-pool",
    ),
    pytest.param("{}", "unused credential pools in secrets: a", id="unused"),
    pytest.param("a: [", None, id="yaml-syntax"),
    pytest.param("- 1", "base settings YAML must be an object", id="yaml-not-mapping"),
    pytest.param("", "base settings YAML must be an object", id="yaml-empty"),
]


@pytest.mark.parametrize(("settings_text", "message"), NATIVE_ERRORS)
def test_native_settings_errors(
    tmp_path: Path, settings_text: str, message: str | None
) -> None:
    result = run_cli(tmp_path, settings_text)
    if message is None:
        assert result.code == 1
        assert result.stderr.startswith(
            f"{ERROR_PREFIX}failed to parse base settings YAML: "
        )
    else:
        assert_fails(result, message)


PROFILE = {"name": "zen", "base-url": "http://127.0.0.1:1/v1"}
COMPAT_MARKER = "openai-compatibility[0].x-credential-pool must be a non-empty string"
DISCOVERY = {"x-credential-pool": "a", "x-model-discovery": True, **PROFILE}
COMPAT_ERRORS = [
    pytest.param(
        json.dumps({"openai-compatibility": {}}),
        "'openai-compatibility' must be a list",
        id="section-not-list",
    ),
    pytest.param(compat(1), "openai-compatibility[0] must be an object", id="object"),
    pytest.param(compat({"x-credential-pool": " "}), COMPAT_MARKER, id="blank-marker"),
    pytest.param(compat({"x-credential-pool": 1}), COMPAT_MARKER, id="int-marker"),
    pytest.param(
        compat({"x-credential-pool": "a", "api-key-entries": []}),
        f"{LABEL} cannot declare api-key-entries when using {POOL_MARKER}",
        id="owned-field",
    ),
    pytest.param(
        compat({"x-credential-pool": "b"}),
        "openai-compatibility[0] references unknown pool 'b'",
        id="unknown-pool",
    ),
    pytest.param(
        compat({"x-model-discovery": True}),
        "openai-compatibility[0].x-model-discovery requires x-credential-pool",
        id="discovery-without-pool",
    ),
    pytest.param(
        compat({"x-model-exclude": ["m"]}),
        "openai-compatibility[0].x-model-exclude requires x-credential-pool",
        id="exclude-without-pool",
    ),
    pytest.param(
        compat({"x-credential-pool": "a", "x-model-exclude": ["m"]}),
        "openai-compatibility[0].x-model-exclude requires x-model-discovery",
        id="exclude-without-discovery",
    ),
    pytest.param(
        compat({**DISCOVERY, "x-model-exclude": "m"}),
        "openai-compatibility[0].x-model-exclude must be a list of model ids",
        id="exclude-not-list",
    ),
    pytest.param(
        compat({**DISCOVERY, "x-model-exclude": ["m", ""]}),
        "openai-compatibility[0].x-model-exclude must be a list of model ids",
        id="exclude-empty-id",
    ),
    pytest.param(
        compat({**DISCOVERY, "x-model-exclude": [1]}),
        "openai-compatibility[0].x-model-exclude must be a list of model ids",
        id="exclude-non-string",
    ),
    pytest.param(
        compat({**DISCOVERY, "x-model-discovery": "yes"}),
        "openai-compatibility[0].x-model-discovery must be true",
        id="discovery-not-true",
    ),
    pytest.param(
        compat({**DISCOVERY, "models": []}),
        "openai-compatibility[0] cannot declare models when using x-model-discovery",
        id="models-declared",
    ),
    pytest.param(
        compat({"x-credential-pool": "a", "x-model-discovery": True, "base-url": "u"}),
        "openai-compatibility[0].x-model-discovery requires name and base-url",
        id="no-name",
    ),
    pytest.param(
        compat({"x-credential-pool": "a", "x-model-discovery": True, "name": "z"}),
        "openai-compatibility[0].x-model-discovery requires name and base-url",
        id="no-base-url",
    ),
]


@pytest.mark.parametrize(("settings_text", "message"), COMPAT_ERRORS)
def test_compatibility_settings_errors(
    tmp_path: Path, settings_text: str, message: str
) -> None:
    assert_fails(run_cli(tmp_path, settings_text), message)


CACHE_ERRORS = [
    pytest.param("[]", "model cache root must be an object", id="root"),
    pytest.param(
        '{"zen": "x"}', "model cache entry 'zen' must be a list", id="entry-not-list"
    ),
    pytest.param(
        '{"zen": [1]}',
        "model cache entry 'zen' has an invalid model",
        id="model-not-object",
    ),
    pytest.param(
        '{"zen": [{"id": "x"}]}',
        "model cache entry 'zen' has an invalid model",
        id="model-without-name",
    ),
    pytest.param(
        '{"zen": [{"name": 5}]}',
        "model cache entry 'zen' has an invalid model",
        id="model-name-not-string",
    ),
]


@pytest.mark.parametrize(("cache_text", "message"), CACHE_ERRORS)
def test_model_cache_errors(tmp_path: Path, cache_text: str, message: str) -> None:
    assert_fails(run_cli(tmp_path, "{}", cache_text=cache_text), message)


def test_model_cache_invalid_json(tmp_path: Path) -> None:
    result = run_cli(tmp_path, "{}", cache_text="{nope")
    assert result.code == 1
    assert result.stderr.startswith(f"{ERROR_PREFIX}failed to parse model cache: ")


def test_missing_arguments_exit_with_usage_error() -> None:
    done = run_raw(["--settings", "x"])
    assert done.returncode == 2
    assert (
        "the following arguments are required: --secrets, --models-cache" in done.stderr
    )


def test_unreadable_input_is_an_unexpected_error(tmp_path: Path) -> None:
    done = run_raw([
        "--settings",
        str(tmp_path / "missing.yaml"),
        "--secrets",
        str(tmp_path / "missing.json"),
        "--models-cache",
        str(tmp_path / "models.json"),
    ])
    assert done.returncode == 1
    assert done.stderr.startswith(
        "cliproxyapi unexpected error: [Errno 2] No such file or directory"
    )


def test_renders_pools_and_passes_plain_profiles_through(tmp_path: Path) -> None:
    secrets_text = pools_json({
        "a": [
            {"api-key": " k1 ", "weight": 3, "proxy-url": "http://p:1"},
            {"apiKey": "k2", "proxyUrl": " http://q:2 "},
        ]
    })
    settings_text = json.dumps({
        "port": 8317,
        "codex-api-key": [
            {"x-credential-pool": " a ", "prefix": "p", "proxy-url2": "x"},
            {"api-key": "inline", "base-url": "u"},
        ],
        "openai-compatibility": [
            {"name": "plain", "base-url": "u2"},
            {"name": "pooled", "x-credential-pool": "a"},
        ],
    })
    result = run_cli(tmp_path, settings_text, secrets_text)
    assert result.code == 0
    assert not result.stderr
    assert not result.stdout
    config = load_yaml_dict(result.out.read_text())
    assert list(config) == ["port", "codex-api-key", "openai-compatibility"]
    assert config["codex-api-key"] == [
        {
            "api-key": "k1",
            "weight": 3,
            "proxy-url": "http://p:1",
            "prefix": "p",
            "proxy-url2": "x",
        },
        {"api-key": "k2", "proxy-url": "http://q:2", "prefix": "p", "proxy-url2": "x"},
        {"api-key": "inline", "base-url": "u"},
    ]
    assert config["openai-compatibility"] == [
        {"name": "plain", "base-url": "u2"},
        {
            "name": "pooled",
            "api-key-entries": [
                {"api-key": "k1", "weight": 3, "proxy-url": "http://p:1"},
                {"api-key": "k2", "proxy-url": "http://q:2"},
            ],
        },
    ]


def test_without_out_only_the_cache_is_written(tmp_path: Path) -> None:
    result = run_cli(tmp_path, compat({"x-credential-pool": "a"}), with_out=False)
    assert result.code == 0
    assert not result.stdout
    assert not result.stderr
    assert not result.out.exists()
    assert result.cache.read_text() == "{}\n"


def test_unchanged_config_is_not_rewritten(tmp_path: Path) -> None:
    first = run_cli(tmp_path, native({"x-credential-pool": "a"}))
    assert first.code == 0
    assert first.out.stat().st_mode & 0o777 == 0o600
    os.utime(first.out, ns=(1_000_000_000, 1_000_000_000))

    second = run_cli(tmp_path, native({"x-credential-pool": "a"}))
    assert second.code == 0
    assert second.out.stat().st_mtime_ns == 1_000_000_000

    third = run_cli(tmp_path, native({"x-credential-pool": "a", "prefix": "new"}))
    assert third.code == 0
    assert second.out.stat().st_mtime_ns != 1_000_000_000
    assert load_yaml_dict(third.out.read_text())["codex-api-key"] == [
        {"api-key": "k", "prefix": "new"}
    ]


MODELS_BODY = json.dumps({
    "data": [
        {"id": "a"},
        {"id": "b", "name": "B", "context_length": 10},
        {"id": "c", "name": "", "context_length": 0},
        {"id": "d", "context_length": True},
        {"id": "e", "context_length": -5},
        {"id": "f", "context_length": "7"},
        {"id": "hidden"},
        {"id": ""},
        {"id": 5},
        "text",
        {"name": "no-id"},
    ]
}).encode()
LISTED = [
    {"name": "a"},
    {"name": "b", "display-name": "B", "max-context-length": 10},
    {"name": "c"},
    {"name": "d"},
    {"name": "e"},
    {"name": "f"},
]
RESPONSES: dict[str, tuple[int, bytes]] = {
    "/ok/models": (200, MODELS_BODY),
    "/list/models": (200, b"[]"),
    "/no-data/models": (200, b"{}"),
    "/data-not-list/models": (200, b'{"data": "x"}'),
    "/garbage/models": (200, b"nope"),
    "/binary/models": (200, b"\xff\xfe"),
    "/denied/models": (401, b"{}"),
}


class UpstreamState:
    def __init__(self) -> None:
        self.headers: list[dict[str, str]] = []


def make_handler(state: UpstreamState) -> type[http.server.BaseHTTPRequestHandler]:
    class Handler(http.server.BaseHTTPRequestHandler):
        def do_GET(self) -> None:
            state.headers.append(dict(self.headers.items()))
            status, body = RESPONSES.get(self.path, (404, b"{}"))
            self.send_response(status)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            _ = self.wfile.write(body)

        @override
        def log_message(self, format: str, *args: object) -> None:
            pass

    return Handler


@pytest.fixture
def upstream() -> Iterator[tuple[str, UpstreamState]]:
    state = UpstreamState()
    server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), make_handler(state))
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    try:
        yield f"http://127.0.0.1:{server.server_address[1]}", state
    finally:
        server.shutdown()
        server.server_close()
        thread.join()


def dead_url() -> str:
    with socket.socket() as sock:
        sock.bind(("127.0.0.1", 0))
        port = cast("int", sock.getsockname()[1])
    return f"http://127.0.0.1:{port}/v1"


def discovery_settings(base_url: str, exclude: Sequence[str] = ("hidden",)) -> str:
    return compat({
        "name": "zen",
        "base-url": base_url,
        "x-credential-pool": "a",
        "x-model-discovery": True,
        "x-model-exclude": list(exclude),
    })


def models_of(result: Result) -> object:
    config = load_yaml_dict(result.out.read_text())
    profiles = config["openai-compatibility"]
    assert isinstance(profiles, list)
    first = cast("object", profiles[0])
    assert is_dict(first)
    return first["models"]


def test_discovery_lists_models_and_caches_them(
    tmp_path: Path, upstream: tuple[str, UpstreamState]
) -> None:
    base, state = upstream
    result = run_cli(tmp_path, discovery_settings(f"{base}/ok/"))
    assert result.code == 0
    assert not result.stderr
    assert models_of(result) == LISTED
    cached = load_json_dict(result.cache.read_text())
    assert cached == {"zen": [*LISTED, {"name": "hidden"}]}
    assert result.cache.read_text().endswith("}\n")
    assert state.headers[0]["Authorization"] == "Bearer k"
    assert state.headers[0]["Accept"] == "application/json"
    assert state.headers[0]["User-Agent"] == "rice-cliproxyapi/1.0"


@pytest.mark.parametrize(
    "path", ["list", "no-data", "data-not-list", "garbage", "binary", "denied", "gone"]
)
def test_discovery_unlistable_upstream_declares_no_models(
    tmp_path: Path, upstream: tuple[str, UpstreamState], path: str
) -> None:
    result = run_cli(tmp_path, discovery_settings(f"{upstream[0]}/{path}"))
    assert result.code == 0
    assert (
        result.stderr
        == "cliproxyapi configure: cannot list models for zen; none declared\n"
    )
    assert models_of(result) == []
    assert result.cache.read_text() == "{}\n"


def test_discovery_reuses_cached_models_when_unreachable(tmp_path: Path) -> None:
    cache_text = json.dumps({
        "zen": [
            {"name": "keep", "display-name": "Keep", "max-context-length": 5},
            {"name": "hidden"},
            {"name": "x", "display-name": 3, "max-context-length": True},
        ],
        "other": [],
    })
    result = run_cli(tmp_path, discovery_settings(dead_url()), cache_text=cache_text)
    assert result.code == 0
    assert (
        result.stderr
        == "cliproxyapi configure: cannot list models for zen; reusing cached models\n"
    )
    assert models_of(result) == [
        {"name": "keep", "display-name": "Keep", "max-context-length": 5},
        {"name": "x"},
    ]
    assert load_json_dict(result.cache.read_text()) == {
        "zen": [
            {"name": "keep", "display-name": "Keep", "max-context-length": 5},
            {"name": "hidden"},
            {"name": "x"},
        ],
        "other": [],
    }


def test_discovery_without_exclusions_keeps_every_listed_model(
    tmp_path: Path, upstream: tuple[str, UpstreamState]
) -> None:
    result = run_cli(tmp_path, discovery_settings(f"{upstream[0]}/ok", exclude=()))
    assert result.code == 0
    assert models_of(result) == [*LISTED, {"name": "hidden"}]


class CredentialFactory(Protocol):
    def __call__(
        self, api_key: str, weight: int | None = None, proxy_url: str | None = None
    ) -> object: ...


class ConfigureModule(Protocol):
    Credential: CredentialFactory

    def merge_config(
        self, settings_content: str, pools: Mapping[str, Sequence[object]]
    ) -> str: ...


def load_configure() -> ConfigureModule:
    spec = importlib.util.spec_from_file_location("cliproxy_configure_cli", SCRIPT)
    assert spec is not None
    assert spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    # Loaded by path: the checker cannot see the module, so a Protocol mirrors it.
    return cast("ConfigureModule", cast("object", module))


configure = load_configure()
KEYS = st.text(alphabet=string.ascii_letters + string.digits + "-_.: ", min_size=1)
CREDENTIALS = st.lists(
    st.tuples(KEYS, st.none() | st.integers(min_value=1, max_value=1000)),
    min_size=1,
    max_size=5,
    unique_by=itemgetter(0),
)


@settings(database=None, max_examples=50, deadline=None)
@given(CREDENTIALS)
def test_rendering_is_deterministic_and_round_trips(
    credentials: list[tuple[str, int | None]],
) -> None:
    pools = {"a": [configure.Credential(api_key=k, weight=w) for k, w in credentials]}
    settings_text = native({"x-credential-pool": "a", "base-url": "u"})
    first = configure.merge_config(settings_text, pools)
    assert configure.merge_config(settings_text, pools) == first
    expected: list[dict[str, object]] = []
    for key, weight in credentials:
        entry: dict[str, object] = {"api-key": key}
        if weight is not None:
            entry["weight"] = weight
        expected.append({**entry, "base-url": "u"})
    assert load_yaml_dict(first)["codex-api-key"] == expected
