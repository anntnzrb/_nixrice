"""Exercise the style checker through its CLI with real Nix files."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

import pytest

SCRIPT = Path(__file__).parents[1] / "check.py"


def run_check(
    tmp_path: Path, files: dict[str, str]
) -> subprocess.CompletedProcess[str]:
    """Create a repository fixture and run the actual CLI.

    Returns:
        The command's exit status and diagnostics.
    """
    for name, source in files.items():
        path = tmp_path / name
        path.parent.mkdir(parents=True, exist_ok=True)
        _ = path.write_text(source, encoding="utf-8")
    return subprocess.run(  # noqa: S603 - fixed script and temporary fixture root
        [sys.executable, str(SCRIPT), str(tmp_path)],
        check=False,
        capture_output=True,
        text=True,
    )


@pytest.mark.parametrize(
    ("source", "rule", "line"),
    [
        ("{ pkgs, lib, ... }: {}", "rule 1", 1),
        ("{\n pkgs,\n lib ? { a = 1; },\n ...\n}: {}", "rule 1", 1),
        ("{ ..., lib }: {}", "parse error", 1),
        ("_: {}", "rule 1", 1),
        ("{ ... }: {}", "rule 1", 1),
        ("{ options = {};\n imports = []; }", "rule 2", 2),
        ("{ config.x = 1;\n inherit options; }", "rule 2", 2),
        ('{ config = {};\n "options" = {}; }', "rule 2", 2),
        (
            '{\n _class = "clan.service";\n roles.a = {};\n manifest.name = "a";\n}',
            "rule 2",
            4,
        ),
        (
            '{\n _class = "clan.service";\n extra = {};\n perMachine = {};\n}',
            "rule 2",
            4,
        ),
        (
            "{ config, ... }: let\n cfg = config.x;\n inherit (config) x;\n in {}",
            "rule 3",
            3,
        ),
        ("let\n other = 1;\n cfg = 2;\n in {}", "rule 3", 3),
        ("let other = 1;\n inherit x; in {}", "rule 3", 2),
        ("({let cfg = 1; in cfg})", "parse error", 1),
        ("{ imports = [; }", "parse error", 1),
        ("", "parse error", 1),
        ("{}: {}", "rule 1", 1),
    ],
)
def test_rejects_layout(tmp_path: Path, source: str, rule: str, line: int) -> None:
    """Every convention violation reports its rule and source location."""
    result = run_check(tmp_path, {"modules/features/example/home.nix": source})
    assert result.returncode == 1
    assert f"modules/features/example/home.nix:{line}: {rule}" in result.stderr


@pytest.mark.parametrize(
    "source",
    [
        "{}",
        "{ lib }: lib.mkMerge []",
        "args@{ config, ... }: { config.x = args.config; }",
        "{ config, ... }: let /* comment */ cfg = config.x; in {}",
        "{ inherit /* comment */ imports; options = {}; }",
        "{ lib, ... }: { config = {}; other = 1; }",
        "rec { imports = []; options = {}; config = {}; }",
        """{ config, lib ? { b = 2; a = 1; }, ... }@args:
        let inherit (lib) x; cfg = config.x; other = args;
        in { imports = []; options.x = x; config.x = cfg; }""",
        """({ config, ... }: (let inherit (config) cfg; other = 1;
        in (with config; assert true; { options = {}; config = {}; })))""",
        """{ _class = "clan.service"; manifest.name = "a";
        roles.a = {}; roles.b = {}; perMachine = {}; other = {}; }""",
        """{ options = {}; config.text = ''{ pkgs, lib }:
        let cfg=1; inherit x; in { options={}; imports=[]; }''; }""",
        "# { z, a }:\n{ imports = []; /* options = {}; imports = []; */ config = {}; }",
        """{ config, ... }: let inherit config; cfg = config.x; other = 1;
        in { _class = "homeManager"; key = "x"; imports = [];
        disabledModules = []; options = {}; config = {}; }""",
    ],
)
def test_accepts_layout(tmp_path: Path, source: str) -> None:
    """Source-preserving parsing handles comments, defaults and strings."""
    result = run_check(tmp_path, {"modules/features/example/home.nix": source})
    assert result.returncode == 0, result.stderr
    assert "1 Nix files checked" in result.stdout


@pytest.mark.parametrize(
    "path",
    [
        "modules/features/example/settings.nix",
        "modules/features/_example/home.nix",
        "modules/features/example/_home.nix",
        "modules/features/example/tests/home.nix",
        "machines/example/waymote.nix",
    ],
)
def test_helpers_only_check_arguments(tmp_path: Path, path: str) -> None:
    """Helpers may use scalar functions and different binding layouts."""
    source = "_: let cfg = 1; inherit x; in { options = {}; imports = []; }"
    result = run_check(tmp_path, {path: source})
    assert result.returncode == 0, result.stderr
    result = run_check(tmp_path, {path: "{ z, a, ... }: {}"})
    assert result.returncode == 1
    assert f"{path}:1: rule 1" in result.stderr


@pytest.mark.parametrize(
    "path",
    [
        "machines/example/configuration.nix",
        "machines/example/home.nix",
        "machines/example/disk.nix",
        "machines/example/hardware/kernel.nix",
        "homes/example.nix",
        "flake/example.nix",
        "modules/services/example/default.nix",
    ],
)
def test_module_locations(tmp_path: Path, path: str) -> None:
    """Every module location enforces the outer layout."""
    result = run_check(tmp_path, {path: "{ options = {}; imports = []; }"})
    assert result.returncode == 1
    assert f"{path}:1: rule 2" in result.stderr


def test_nested_arguments(tmp_path: Path) -> None:
    """Nested callbacks also keep attrset function arguments sorted."""
    result = run_check(
        tmp_path,
        {"flake/example.nix": "{ perSystem = { pkgs, config, ... }: {}; }"},
    )
    assert result.returncode == 1
    assert "flake/example.nix:1: rule 1" in result.stderr


def test_empty_repository(tmp_path: Path) -> None:
    """Absent source directories are valid for small fixture repositories."""
    result = run_check(tmp_path, {})
    assert result.returncode == 0
    assert "0 Nix files checked" in result.stdout


def test_imported_modules(tmp_path: Path) -> None:
    """Follow recursive module imports without checking imported helper data."""
    result = run_check(
        tmp_path,
        {
            "modules/features/example/home.nix": """{
                imports = [ ./first.nix ./_private.nix ./tests/home.nix ];
                config.value = import ./data.nix;
            }""",
            "modules/features/example/first.nix": """{
                imports = [ ./second.nix ./home.nix ./missing.nix ];
            }""",
            "modules/features/example/second.nix": """{
                options = {};
                imports = [];
            }""",
            "modules/features/example/data.nix": "{ options = {}; imports = []; }",
            "modules/features/example/_private.nix": "_: {}",
            "modules/features/example/tests/home.nix": "_: {}",
        },
    )
    assert result.returncode == 1
    assert "modules/features/example/second.nix:3: rule 2" in result.stderr
    assert "data.nix" not in result.stderr
    assert "_private.nix" not in result.stderr
    assert "tests/home.nix" not in result.stderr


def test_helper_arguments_without_ellipsis(tmp_path: Path) -> None:
    """Package functions also sort their arguments when the pattern is closed."""
    result = run_check(tmp_path, {"machines/example/package.nix": "{ a, z }: {}"})
    assert result.returncode == 0, result.stderr


@pytest.mark.parametrize("call", ["import", "pkgs.callPackage"])
def test_explicit_helper_calls(tmp_path: Path, call: str) -> None:
    """Explicit helper calls take precedence over module-looking locations."""
    files = {
        "homes/main.nix": f"{{ config.data = {call} ./data.nix {{}}; }}",
        "homes/data.nix": "let cfg = 1; inherit x; in { options = {}; imports = []; }",
        "flake/main.nix": """{ helper = passthru ./data.nix;
            text = builtins.readFile ./text;
            absolute = import /tmp/data.nix;
        }""",
        "flake/data.nix": "{ options = {}; imports = []; }",
    }
    result = run_check(tmp_path, files)
    assert result.returncode == 1
    assert "homes/data.nix" not in result.stderr
    assert "flake/data.nix:1: rule 2" in result.stderr
    files["homes/data.nix"] = "{ z, a }: {}"
    result = run_check(tmp_path, files)
    assert result.returncode == 1
    assert "homes/data.nix:1: rule 1" in result.stderr
