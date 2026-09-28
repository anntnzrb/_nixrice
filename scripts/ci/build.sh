#!/usr/bin/env sh

set -eu

here="$(cd "$(dirname "$0")" && pwd)"
flake="path:${PWD}"

if test "$#" -eq 0; then
    attrs="$(nix eval --impure --raw --expr "builtins.concatStringsSep \" \" (map (t: t.attr) (builtins.filter (t: t.system == builtins.currentSystem) (import ${here}/targets.nix { flake = \"${flake}\"; })))")"
    # shellcheck disable=SC2086 # attribute paths contain no whitespace
    set -- ${attrs}
fi

n=$#
while test "${n}" -gt 0; do
    set -- "$@" "${flake}#$1"
    shift
    n=$((n - 1))
done

nix build --keep-going --no-link --print-build-logs "$@"
