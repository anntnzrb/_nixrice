#!/bin/sh
set -eu

FLAKE="github:numtide/llm-agents.nix/main"
REFRESH_SECS=$((8 * 60 * 60))

ATTR="${1:-}"
[ -n "${ATTR}" ] || {
    printf '%s\n' "llm-agent: missing attribute" >&2
    exit 2
}
shift

command -v nix >/dev/null 2>&1 || {
    printf '%s\n' "llm-agent: nix not found" >&2
    exit 127
}

CACHE_HOME="${XDG_CACHE_HOME:-${HOME}/.cache}"
STAMP_DIR="${CACHE_HOME}/llm-agents/${ATTR}"
STAMP_FILE="${STAMP_DIR}/last-flake-refresh"

[ -d "${STAMP_DIR}" ] || mkdir -p "${STAMP_DIR}"

now="$(date +%s)"
last=0
[ -f "${STAMP_FILE}" ] && read -r last <"${STAMP_FILE}" || :

[ $((now - last)) -ge "${REFRESH_SECS}" ] \
    && nix flake metadata --refresh "${FLAKE}" >/dev/null 2>&1 || :
[ $((now - last)) -ge "${REFRESH_SECS}" ] && printf '%s\n' "${now}" >"${STAMP_FILE}" || :

exec nix --accept-flake-config run "${FLAKE}#${ATTR}" -- "$@"
