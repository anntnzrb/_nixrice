#!/usr/bin/env sh
# Prints the build matrix for GitHub Actions as JSON: every machine and home
# whose output is not in the binary cache yet, each on a runner of its
# platform. Cached targets are skipped, so an unchanged fleet builds nothing.

set -eu

cache="https://anntnzrb.cachix.org"
here="$(cd "$(dirname "$0")" && pwd)"

nix eval --impure --json \
    --expr "import ${here}/targets.nix { flake = \"path:${PWD}\"; }" 2>/dev/null \
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
          "aarch64-linux": "ubuntu-24.04-arm",
          "aarch64-darwin": "macos-latest"
        }[.system]
      })'
