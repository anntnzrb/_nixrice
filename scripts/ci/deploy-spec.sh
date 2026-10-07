#!/usr/bin/env sh

set -eu

here="$(cd "$(dirname "$0")" && pwd)"

targets="$(nix eval --impure --json \
    --expr "import ${here}/deploy-targets.nix { flake = \"path:${PWD}\"; }" 2>/dev/null)"

missing="$(printf '%s\n' "${targets}" | "${here}/uncached.sh")"
if test -n "${missing}"; then
    printf 'deploy-spec: not in the binary cache:\n%s\n' "${missing}" >&2
    exit 1
fi

printf '%s\n' "${targets}" | jq -c '{agents: map({key: .name, value: .out}) | from_entries}'
