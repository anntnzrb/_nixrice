#!/usr/bin/env sh

set -eu

cache="https://anntnzrb.cachix.org"

targets="$(jq -c '.[]')"
printf '%s\n' "${targets}" \
    | while read -r target; do
        test -n "${target}" || continue
        out="$(printf '%s' "${target}" | jq -r .out)"
        hash="$(basename "${out}" | cut -c1-32)"
        curl -fsS -o /dev/null "${cache}/${hash}.narinfo" 2>/dev/null || printf '%s\n' "${target}"
    done
