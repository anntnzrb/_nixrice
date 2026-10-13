#!/usr/bin/env bash

: "${PGREP:?}" "${CACHE_SUBDIR:?}"

if "${PGREP}" -i stremio >/dev/null; then
    exit 0
fi

cache="${HOME}/${CACHE_SUBDIR}"
if [[ ! -d "${cache}" ]]; then
    exit 0
fi

find "${cache}" -mindepth 1 -maxdepth 1 -mtime +7 -exec rm -rf {} +
