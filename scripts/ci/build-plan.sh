#!/usr/bin/env sh

set -eu

cache="https://anntnzrb.cachix.org"
here="$(cd "$(dirname "$0")" && pwd)"

targets="$(nix eval --impure --json \
    --expr "import ${here}/targets.nix { flake = \"path:${PWD}\"; }" 2>/dev/null)"

printf '%s\n' "${targets}" \
    | jq -c '.[]' \
    | while read -r target; do
        out="$(printf '%s' "${target}" | jq -r .out)"
        hash="$(basename "${out}" | cut -c1-32)"
        curl -fsS -o /dev/null "${cache}/${hash}.narinfo" 2>/dev/null || printf '%s\n' "${target}"
    done \
    | jq -cs 'map({
        name, attr,
        os: {
          "x86_64-linux": "ubuntu-latest",
          "aarch64-darwin": "macos-latest"
        }[.system]
      })'
