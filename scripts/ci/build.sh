#!/usr/bin/env sh
# Builds every machine and standalone home this platform can build, or only
# the flake attributes given as arguments, so a package that evaluates but
# fails to build shows up before a deploy.

set -eu

here="$(cd "$(dirname "$0")" && pwd)"
flake="path:${PWD}"

if test "$#" -eq 0; then
    system="$(nix eval --impure --raw --expr builtins.currentSystem)"
    attrs="$(nix eval --impure --raw --expr "builtins.concatStringsSep \" \" (map (t: t.attr) (builtins.filter (t: t.system == \"${system}\") (import ${here}/targets.nix { flake = \"${flake}\"; })))")"
    # shellcheck disable=SC2086 # attribute paths contain no whitespace
    set -- ${attrs}
fi

# prefix every attribute with the flake reference
n=$#
while test "${n}" -gt 0; do
    set -- "$@" "${flake}#$1"
    shift
    n=$((n - 1))
done

nix build --keep-going --no-link --print-build-logs "$@"
