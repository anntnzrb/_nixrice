#!/usr/bin/env sh

set -eu

cache="https://anntnzrb.cachix.org"

jq -c '.[]' \
    | while read -r target; do
        out="$(printf '%s' "${target}" | jq -r .out)"
        hash="$(basename "${out}" | cut -c1-32)"
        curl -fsS -o /dev/null "${cache}/${hash}.narinfo" 2>/dev/null || printf '%s\n' "${target}"
    done
