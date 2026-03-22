#!/bin/sh
set -eu

# SCRIPT_DIR
# Wrapper directory
SCRIPT_DIR="${0%/*}"

# shellcheck source=agent-wrapper-common.sh
. "${SCRIPT_DIR}/agent-wrapper-common.sh"

FLAKE="github:numtide/llm-agents.nix/main"
REFRESH_SECS=$((8 * 60 * 60))

ATTR="${1:-}"
require_arg "${ATTR}" "attribute"
BIN_NAME="${2:-}"
require_arg "${BIN_NAME}" "binary name"
shift 2

command -v nix >/dev/null 2>&1 || die "nix not found" 127

CACHE_HOME="${XDG_CACHE_HOME:-${HOME}/.cache}"
STAMP_DIR="${CACHE_HOME}/llm-agents/${ATTR}"
STAMP_FILE="${STAMP_DIR}/last-flake-refresh"
OUT_PATH_FILE="${STAMP_DIR}/out-path"
COMMAND_PATH_FILE="${STAMP_DIR}/command-path"
REFRESH_LOCK_DIR="${STAMP_DIR}/refresh.lock"

[ -d "${STAMP_DIR}" ] || mkdir -p "${STAMP_DIR}"

store_resolved_command() {
    out_path="${1}"
    command_path="${2}"

    printf '%s\n' "${out_path}" >"${OUT_PATH_FILE}"
    printf '%s\n' "${command_path}" >"${COMMAND_PATH_FILE}"
    printf '%s\n' "$(date +%s)" >"${STAMP_FILE}"
}

resolve_command_path() {
    out_path="${1}"
    main_program="${2}"

    for preferred_name in "${main_program}" "${BIN_NAME}"; do
        [ -n "${preferred_name}" ] || continue
        preferred="${out_path}/bin/${preferred_name}"
        if [ -x "${preferred}" ] && [ ! -d "${preferred}" ]; then
            printf '%s\n' "${preferred}"
            return 0
        fi
    done

    candidate_count=0
    candidate_path=""
    for candidate in "${out_path}"/bin/*; do
        [ -e "${candidate}" ] || continue
        [ ! -d "${candidate}" ] || continue
        [ -x "${candidate}" ] || continue
        candidate_count=$((candidate_count + 1))
        candidate_path="${candidate}"
    done

    [ "${candidate_count}" -eq 1 ] || die "cannot resolve executable for ${ATTR} in ${out_path}"
    printf '%s\n' "${candidate_path}"
}

build_out_path() {
    refresh_flag="${1}"

    if [ "${refresh_flag}" = "--refresh" ]; then
        nix --accept-flake-config build --refresh --no-link --print-out-paths "${FLAKE}#${ATTR}"
        return 0
    fi

    nix --accept-flake-config build --no-link --print-out-paths "${FLAKE}#${ATTR}"
}

resolve_main_program() {
    main_program="$(nix eval --raw "${FLAKE}#${ATTR}.meta.mainProgram" 2>/dev/null || :)"
    if [ -n "${main_program}" ]; then
        printf '%s\n' "${main_program}"
        return 0
    fi

    printf '%s\n' "${BIN_NAME}"
}

refresh_cache() {
    refresh_flag="${1}"
    out_path="$(build_out_path "${refresh_flag}")" || return 1
    main_program="$(resolve_main_program)" || return 1
    command_path="$(resolve_command_path "${out_path}" "${main_program}")" || return 1
    store_resolved_command "${out_path}" "${command_path}"
    return 0
}

cached_command_path() {
    [ -f "${COMMAND_PATH_FILE}" ] || return 1
    read -r command_path <"${COMMAND_PATH_FILE}" || return 1
    [ -x "${command_path}" ] || return 1
    printf '%s\n' "${command_path}"
}

cache_is_stale() {
    now="$(date +%s)"
    last=0
    [ -f "${STAMP_FILE}" ] && read -r last <"${STAMP_FILE}" || :
    [ $((now - last)) -ge "${REFRESH_SECS}" ]
}

refresh_cache_async() {
    mkdir "${REFRESH_LOCK_DIR}" 2>/dev/null || return 0

    (
        trap 'rm -rf "${REFRESH_LOCK_DIR}"' EXIT
        refresh_cache "--refresh" >/dev/null 2>&1 || :
    ) &
    return 0
}

COMMAND_PATH="$(cached_command_path || :)"

if [ -z "${COMMAND_PATH}" ]; then
    refresh_cache "" >/dev/null
    COMMAND_PATH="$(cached_command_path || :)"
fi

[ -n "${COMMAND_PATH}" ] || die "failed to resolve command path for ${ATTR}"

if cache_is_stale; then
    refresh_cache_async
fi

run_exec "${COMMAND_PATH}" "$@"
