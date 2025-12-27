set -eu

FLAKE="github:numtide/llm-agents.nix/main"
ATTR="opencode"
REFRESH_SECS=$((8 * 60 * 60))

CACHE_HOME="${XDG_CACHE_HOME:-${HOME}/.cache}"
STAMP_DIR="${CACHE_HOME}/opencode"
STAMP_FILE="${STAMP_DIR}/last-flake-refresh"

command -v nix >/dev/null 2>&1 || {
    printf '%s\n' "opencode: nix not found" >&2
    exit 127
}

[ -d "${STAMP_DIR}" ] || mkdir -p "${STAMP_DIR}"

now="$(date +%s)"
last=0
[ -f "${STAMP_FILE}" ] && read -r last <"${STAMP_FILE}" || :

[ $((now - last)) -ge "${REFRESH_SECS}" ] \
    && nix flake metadata --refresh "${FLAKE}" >/dev/null 2>&1 || :
[ $((now - last)) -ge "${REFRESH_SECS}" ] && printf '%s\n' "${now}" >"${STAMP_FILE}" || :

exec nix --accept-flake-config run "${FLAKE}#${ATTR}" -- "$@"
