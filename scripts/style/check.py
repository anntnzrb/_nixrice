"""Check Nix module layout using the source-preserving Tree-sitter syntax tree."""

from __future__ import annotations

import argparse
import sys
from ctypes import c_char_p, c_void_p, py_object, pythonapi
from importlib import import_module
from pathlib import Path
from typing import TYPE_CHECKING, Protocol, cast

from tree_sitter import Language, Node, Parser

if TYPE_CHECKING:
    from collections.abc import Iterator

ROOTS = ("modules", "machines", "homes", "flake")
MODULE_ORDER = ("_class", "key", "imports", "disabledModules", "options", "config")
SERVICE_ORDER = ("_class", "manifest", "roles", "perMachine")


class Grammar(Protocol):
    """The generated nixpkgs grammar binding exposes a language pointer."""

    def language(self) -> int:
        """Return the native grammar pointer."""
        ...


def text(node: Node) -> str:
    """Decode a syntax node's source text.

    Returns:
        The exact source text.
    """
    return cast("bytes", node.text).decode("utf-8")


def walk(node: Node) -> Iterator[Node]:
    """Visit syntax nodes without interpreting Nix expressions.

    Yields:
        Each syntax node in source order, including missing punctuation.
    """
    yield node
    for child in node.children:
        yield from walk(child)


def field(node: Node, name: str) -> Node:
    """Read a required grammar field from a successfully parsed expression.

    Returns:
        The field's syntax node.
    """
    return cast("Node", node.child_by_field_name(name))


def bindings(node: Node) -> list[Node]:
    """Read immediate bindings in their original source order.

    Returns:
        The bindings, excluding comments.
    """
    return [
        binding
        for child in node.named_children
        if child.type == "binding_set"
        for binding in child.named_children
        if binding.type != "comment"
    ]


def names(binding: Node) -> list[tuple[str, Node]]:
    """Get top-level attribute names, including quoted and inherited names.

    Returns:
        Each name paired with its source node.
    """
    if binding.type == "binding":
        attr = field(binding, "attrpath").named_children[0]
        return [(text(attr).strip('"'), attr)]
    return [
        (text(attr).strip('"'), attr)
        for attr in field(binding, "attrs").named_children
        if attr.type != "comment"
    ]


def ordered(entries: list[tuple[int, Node]], rule: str, path: Path) -> list[str]:
    """Report any entry placed before an earlier entry's priority group.

    Returns:
        Source locations and the violated rule.
    """
    errors: list[str] = []
    previous = -1
    for priority, node in entries:
        if priority < previous:
            errors.append(f"{path}:{node.start_point.row + 1}: {rule}")
        previous = max(previous, priority)
    return errors


def is_module(path: Path) -> bool:
    """Follow module discovery and machine layout; leave helper data alone.

    Returns:
        Whether this path is a module entry point.
    """
    if any(part.startswith("_") or part == "tests" for part in path.parts):
        return False
    if path.parts[0] in {"homes", "flake"}:
        return True
    if path.parts[0] == "machines":
        return path.name in {"configuration.nix", "home.nix", "disk.nix"} or (
            "hardware" in path.parts
        )
    return path.name in {"nixos.nix", "darwin.nix", "home.nix", "system.nix"} or (
        path.parts[:2] == ("modules", "services") and path.name == "default.nix"
    )


def imported_modules(root: Node, path: Path) -> set[Path]:
    """Find sibling module files explicitly listed in an imports expression.

    Returns:
        Module paths relative to the repository root.
    """
    return {
        path.parent / text(node).removeprefix("./")
        for binding in walk(root)
        if binding.type == "binding" and names(binding)[0][0] == "imports"
        for node in walk(field(binding, "expression"))
        if node.type == "path_expression"
        and text(node).startswith("./")
        and text(node).endswith(".nix")
    }


def imported_helpers(root: Node, path: Path) -> set[Path]:
    """Find helpers called through import or callPackage, regardless of filename.

    Returns:
        Helper paths relative to the repository root.
    """
    helpers: set[Path] = set()
    for node in walk(root):
        if node.type != "apply_expression":
            continue
        function = field(node, "function")
        argument = field(node, "argument")
        if argument.type != "path_expression" or not text(argument).startswith("./"):
            continue
        if text(function) == "import" or (
            function.type == "select_expression"
            and text(field(function, "attrpath")) == "callPackage"
        ):
            helpers.add(path.parent / text(argument).removeprefix("./"))
    return helpers


def check_arguments(root: Node, path: Path) -> list[str]:
    """Check attrset patterns, including defaults, aliases and nested functions.

    Returns:
        Argument ordering violations.
    """
    errors: list[str] = []
    for node in walk(root):
        if node.type != "formals":
            continue
        args = [
            child
            for child in node.named_children
            if child.type in {"formal", "ellipses"}
        ]
        labels = [
            text(field(arg, "name")) if arg.type == "formal" else "..." for arg in args
        ]
        expected = sorted(label for label in labels if label != "...")
        if "..." in labels:
            expected.append("...")
        if labels != expected:
            rule = "rule 1: function arguments must be alphabetical, with ... last"
            errors.append(f"{path}:{node.start_point.row + 1}: {rule}")
    return errors


def check_module(root: Node, path: Path) -> list[str]:
    """Check only the module's outer function, let bindings and attribute set.

    Returns:
        Module layout violations.
    """
    errors: list[str] = []
    node = field(root, "expression")
    while node.type in {
        "parenthesized_expression",
        "function_expression",
        "let_expression",
        "with_expression",
        "assert_expression",
    }:
        if node.type == "function_expression":
            formals = node.child_by_field_name("formals")
            universal = node.child_by_field_name("universal")
            if (
                formals is not None and not formals.children_by_field_name("formal")
            ) or (universal is not None and text(universal) == "_"):
                rule = "rule 1: argument-free modules must be bare attrsets"
                errors.append(f"{path}:{node.start_point.row + 1}: {rule}")
        if node.type == "let_expression":
            entries = [
                (
                    0
                    if binding.type != "binding"
                    else 1
                    if names(binding)[0][0] == "cfg"
                    else 2,
                    binding,
                )
                for binding in bindings(node)
            ]
            errors.extend(
                ordered(
                    entries,
                    "rule 3: let bindings must order inherit, cfg, then others",
                    path,
                )
            )
        node = field(
            node, "expression" if node.type == "parenthesized_expression" else "body"
        )
    if node.type not in {"attrset_expression", "rec_attrset_expression"}:
        return errors
    attrs = [
        (name, attr) for binding in bindings(node) for name, attr in names(binding)
    ]
    service = any(
        names(binding)[0][0] == "_class"
        and text(field(binding, "expression")) == '"clan.service"'
        for binding in bindings(node)
        if binding.type == "binding"
    )
    order = SERVICE_ORDER if service else MODULE_ORDER
    entries = [
        (order.index(name) if name in order else len(order), attr)
        for name, attr in attrs
        if service or name in order
    ]
    errors.extend(
        ordered(
            entries,
            f"rule 2: top-level attributes must follow {', '.join(order)}",
            path,
        )
    )
    return errors


def main() -> int:
    """Check the requested repository and exit nonzero on layout violations.

    Returns:
        One on violations, zero on success.
    """
    arguments = argparse.ArgumentParser(description=__doc__)
    _ = arguments.add_argument("root", type=Path)
    root = cast("Path", arguments.parse_args().root)
    grammar = cast("Grammar", cast("object", import_module("tree_sitter_nix")))
    # nixpkgs' binding returns a pointer; Tree-sitter expects this named capsule.
    capsule_new = pythonapi.PyCapsule_New
    capsule_new.restype = py_object
    capsule_new.argtypes = [c_void_p, c_char_p, c_void_p]
    capsule = cast(
        "object", capsule_new(grammar.language(), b"tree_sitter.Language", None)
    )
    parser = Parser(Language(capsule))
    errors: list[str] = []
    trees: dict[Path, Node] = {}
    for path in sorted(
        path for directory in ROOTS for path in (root / directory).rglob("*.nix")
    ):
        relative = path.relative_to(root)
        parsed = parser.parse(path.read_bytes()).root_node
        if parsed.has_error or parsed.child_by_field_name("expression") is None:
            bad = next(
                (
                    node
                    for node in walk(parsed)
                    if node.type == "ERROR" or node.is_missing
                ),
                parsed,
            )
            errors.append(
                f"{relative}:{bad.start_point.row + 1}: parse error: invalid Nix syntax"
            )
            continue
        trees[relative] = parsed
        errors.extend(check_arguments(parsed, relative))
    helpers = {
        helper
        for path, tree in trees.items()
        for helper in imported_helpers(tree, path)
    }
    modules = {path for path in trees if is_module(path) and path not in helpers}
    pending = list(modules)
    while pending:
        path = pending.pop()
        for imported in imported_modules(trees[path], path):
            if imported in trees and imported not in modules:
                modules.add(imported)
                pending.append(imported)
    for path in sorted(modules):
        if path not in helpers and not any(
            part.startswith("_") or part == "tests" for part in path.parts
        ):
            errors.extend(check_module(trees[path], path))
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    print(f"Module style: {len(trees)} Nix files checked")
    return 0


if __name__ == "__main__":
    sys.exit(main())
