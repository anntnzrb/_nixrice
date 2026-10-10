#!/usr/bin/env sh

set -eu

here="$(cd "$(dirname "$0")" && pwd)"

targets="$(nix eval --impure --json \
    --expr "import ${here}/targets.nix { flake = \"path:${PWD}\"; }" 2>/dev/null)"

missing="$(printf '%s\n' "${targets}" | "${here}/uncached.sh")"
printf '%s\n' "${missing}" \
    | jq -cs 'map({
        name, attr,
        os: {
          "x86_64-linux": "ubuntu-latest",
          "aarch64-darwin": "macos-latest"
        }[.system]
      })'
