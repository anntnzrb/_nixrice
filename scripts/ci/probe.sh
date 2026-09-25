#!/usr/bin/env sh
# Prints "probe.<target>.<toggle> <drvPath>" for every liberion toggle no host
# enables, each switched on over a real host (probes.nix), so refactors of
# unused modules are as checkable as live ones. $1: flake dir (default: .).

# shellcheck disable=SC2016 # the sh -c body expands its own arguments

set -eu

jobs="$(getconf _NPROCESSORS_ONLN)"
flake="path:$(cd "${1:-.}" && pwd)"
probes="$(cd "$(dirname "$0")" && pwd)/probes.nix"

nix eval --impure --raw --expr "import ${probes} { flake = \"${flake}\"; }" 2>/dev/null \
    | xargs -P "${jobs}" -L 1 sh -c '
        drv=$(nix eval --impure --raw --expr \
            "import $0 { flake = \"$1\"; target = \"$2\"; path = \"$3\"; }" 2>/dev/null) \
            || drv=eval-error
        printf "probe.%s.%s %s\n" "$2" "$3" "${drv}"
    ' "${probes}" "${flake}" \
    | sort
