#!/usr/bin/env sh
# Prints "probe.<target>.<module> <drvPath>" for every feature and profile,
# each imported into a real host (probes.nix), so refactors of modules no
# machine uses are as checkable as live ones. $1: flake dir (default: .).
# PROBE_SHARD / PROBE_SHARDS (default 0 / 1) run every Nth probe only, so CI can
# split them across runners.

# shellcheck disable=SC2016 # the sh -c body expands its own arguments

set -eu

jobs="$(getconf _NPROCESSORS_ONLN)"
flake="path:$(cd "${1:-.}" && pwd)"
probes="$(cd "$(dirname "$0")" && pwd)/probes.nix"
shard="${PROBE_SHARD:-0}"
shards="${PROBE_SHARDS:-1}"

nix eval --impure --raw --expr "import ${probes} { flake = \"${flake}\"; }" 2>/dev/null \
    | awk -v s="${shard}" -v n="${shards}" '(NR - 1) % n == s' \
    | xargs -P "${jobs}" -L 1 sh -c '
        drv=$(nix eval --impure --raw --expr \
            "import $0 { flake = \"$1\"; target = \"$2\"; name = \"$3\"; }" 2>/dev/null) \
            || drv=eval-error
        printf "probe.%s.%s %s\n" "$2" "$3" "${drv}"
    ' "${probes}" "${flake}" \
    | sort
