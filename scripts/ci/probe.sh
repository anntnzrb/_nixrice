#!/usr/bin/env sh

# shellcheck disable=SC2016 # the sh -c body expands its own arguments

set -eu

# older glibc requires _NPROCESSORS_ONLN fallback
jobs="$(getconf NPROCESSORS_ONLN 2>/dev/null || getconf _NPROCESSORS_ONLN)"
flake="path:$(cd "${1:-.}" && pwd)"
probes="$(cd "$(dirname "$0")" && pwd)/probes.nix"
shard="${PROBE_SHARD:-0}"
shards="${PROBE_SHARDS:-1}"

list="$(nix eval --impure --raw --expr "import ${probes} { flake = \"${flake}\"; }" 2>/dev/null)"

printf '%s\n' "${list}" \
    | awk -v s="${shard}" -v n="${shards}" '(NR - 1) % n == s' \
    | xargs -P "${jobs}" -L 1 sh -c '
        drv=$(nix eval --impure --raw --expr \
            "import $0 { flake = \"$1\"; target = \"$2\"; name = \"$3\"; }" 2>/dev/null) \
            || drv=eval-error
        printf "probe.%s.%s %s\n" "$2" "$3" "${drv}"
    ' "${probes}" "${flake}" \
    | sort
