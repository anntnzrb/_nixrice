#!/bin/sh

set -eu

# EXIT_MISSING_DIR
# Exit code for missing directory
EXIT_MISSING_DIR="1"

# EXIT_MISSING_ARG
# Exit code for missing argument
EXIT_MISSING_ARG="2"

# die
# Emit error and exit
die() {
    msg="${1}"
    code="${2:-1}"
    printf '%s\n' "npm-launch: ${msg}" >&2
    exit "${code}"
}

# require_arg
# Require non empty arg
require_arg() {
    value="${1}"
    label="${2}"
    [ -n "${value}" ] || die "missing ${label}" "${EXIT_MISSING_ARG}"
    return 0
}

# require_component
# Require a safe cache or executable path component.
require_component() {
    require_arg "${1:-}" "${2:-component}"
    case "${1:-}" in
        . | .. | *[!A-Za-z0-9._-]*)
            die "invalid ${2:-component}: ${1:-}" "${EXIT_MISSING_ARG}"
            ;;
        *)
            :
            ;;
    esac
    return 0
}

# require_version
# Require an npm version that is safe to use as a cache directory name.
require_version() {
    if ! printf '%s\n' "${1:-}" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$'; then
        die "invalid resolved version: ${1:-}"
    fi
    return 0
}

# run_npm_package
# Resolve, cache, and execute an npm package binary.
run_npm_package() {
    if [ "$#" -lt 6 ]; then
        die "usage: run_npm_package TOOL PACKAGE BIN DIST_TAG SMOKE -- [ARGS...]" "${EXIT_MISSING_ARG}"
    fi

    TOOL="$1"
    PACKAGE="$2"
    BIN="$3"
    DIST_TAG="$4"
    SMOKE="$5"
    SEPARATOR="$6"
    shift 6

    [ "${SEPARATOR}" = "--" ] || die "missing -- separator" "${EXIT_MISSING_ARG}"
    require_component "${TOOL}" "tool"
    require_arg "${PACKAGE}" "package"
    require_component "${BIN}" "bin"
    require_component "${DIST_TAG}" "dist-tag"
    require_arg "${SMOKE}" "smoke"

    CACHE_HOME="${XDG_CACHE_HOME:-}"
    if [ -z "${CACHE_HOME}" ]; then
        CACHE_HOME="${HOME:-}"
        [ -n "${CACHE_HOME}" ] || die "missing XDG_CACHE_HOME or HOME" "${EXIT_MISSING_DIR}"
        CACHE_HOME="${CACHE_HOME}/.cache"
    fi

    TOOL_CACHE="${CACHE_HOME}/npm-tools/${TOOL}"
    VERSIONS_DIR="${TOOL_CACHE}/versions"
    CURRENT_LINK="${TOOL_CACHE}/current"
    PREVIOUS_LINK="${TOOL_CACHE}/previous"
    LOCK_FILE="${TOOL_CACHE}/lock"

    mkdir -p "${VERSIONS_DIR}"

    # Keep the exclusive lock through resolution, installation, symlink
    # updates, and pruning. Release it immediately before handing control
    # to the launched tool.
    exec 9>"${LOCK_FILE}"
    flock -x 9

    if ! RESOLVED_VERSION="$(npm view "${PACKAGE}@${DIST_TAG}" version)"; then
        die "could not resolve ${PACKAGE}@${DIST_TAG}; refusing to run a stale version"
    fi
    RESOLVED_VERSION="$(printf '%s' "${RESOLVED_VERSION}" | tr -d '\r\n')"
    require_version "${RESOLVED_VERSION}"

    VERSION_DIR="${VERSIONS_DIR}/${RESOLVED_VERSION}"
    STAGED_BIN="${VERSION_DIR}/node_modules/.bin/${BIN}"
    STAGE_DIR=""

    # shellcheck disable=SC2329 # Invoked indirectly by the EXIT trap.
    cleanup_npm_stage() {
        if [ -n "${STAGE_DIR}" ]; then
            rm -rf -- "${STAGE_DIR}"
        fi
    }
    trap cleanup_npm_stage 0

    if [ ! -x "${STAGED_BIN}" ]; then
        if [ -e "${VERSION_DIR}" ] || [ -L "${VERSION_DIR}" ]; then
            die "cached package is incomplete: ${RESOLVED_VERSION}"
        fi

        STAGE_DIR="$(mktemp -d "${VERSIONS_DIR}/.stage.XXXXXX")"
        npm install \
            --prefix "${STAGE_DIR}" \
            --no-save \
            --no-package-lock \
            --no-audit \
            --no-fund \
            --loglevel=error \
            "${PACKAGE}@${RESOLVED_VERSION}"

        STAGED_BIN="${STAGE_DIR}/node_modules/.bin/${BIN}"
        [ -x "${STAGED_BIN}" ] || die "installed package has no executable bin: ${BIN}"
        if [ "${SMOKE}" != "-" ]; then
            "${STAGED_BIN}" "${SMOKE}" >/dev/null
        fi

        mv -- "${STAGE_DIR}" "${VERSION_DIR}"
        STAGE_DIR=""
    fi

    CACHED_BIN="${VERSION_DIR}/node_modules/.bin/${BIN}"
    [ -x "${CACHED_BIN}" ] || die "cached package has no executable bin: ${BIN}"

    CURRENT_TARGET=""
    if [ -L "${CURRENT_LINK}" ]; then
        CURRENT_TARGET="$(readlink "${CURRENT_LINK}")"
    elif [ -e "${CURRENT_LINK}" ]; then
        die "current cache entry is not a symlink"
    fi

    EXPECTED_TARGET="versions/${RESOLVED_VERSION}"
    if [ "${CURRENT_TARGET}" != "${EXPECTED_TARGET}" ]; then
        if [ -n "${CURRENT_TARGET}" ]; then
            PREVIOUS_TMP="${TOOL_CACHE}/.previous.$$"
            rm -f -- "${PREVIOUS_TMP}"
            ln -s -- "${CURRENT_TARGET}" "${PREVIOUS_TMP}"
            mv -fT -- "${PREVIOUS_TMP}" "${PREVIOUS_LINK}"
        fi

        CURRENT_TMP="${TOOL_CACHE}/.current.$$"
        rm -f -- "${CURRENT_TMP}"
        ln -s -- "${EXPECTED_TARGET}" "${CURRENT_TMP}"
        mv -fT -- "${CURRENT_TMP}" "${CURRENT_LINK}"
    fi

    # Prune: keep only the versions referenced by the current and previous
    # symlinks.
    KEEP_CURRENT=""
    KEEP_PREVIOUS=""
    if [ -L "${CURRENT_LINK}" ]; then
        KEEP_CURRENT="$(readlink "${CURRENT_LINK}")"
        KEEP_CURRENT="$(basename "${KEEP_CURRENT}")"
    fi
    if [ -L "${PREVIOUS_LINK}" ]; then
        KEEP_PREVIOUS="$(readlink "${PREVIOUS_LINK}")"
        KEEP_PREVIOUS="$(basename "${KEEP_PREVIOUS}")"
    fi
    for ENTRY in "${VERSIONS_DIR}"/*; do
        [ -e "${ENTRY}" ] || [ -L "${ENTRY}" ] || continue
        BASE="$(basename -- "${ENTRY}")"
        if [ "${BASE}" = "${KEEP_CURRENT}" ] || [ "${BASE}" = "${KEEP_PREVIOUS}" ]; then
            continue
        fi
        rm -rf -- "${ENTRY}"
    done

    CURRENT_BIN="${CURRENT_LINK}/node_modules/.bin/${BIN}"
    [ -x "${CURRENT_BIN}" ] || die "current package has no executable bin: ${BIN}"

    exec 9>&-
    exec "${CURRENT_BIN}" "$@"
}

# Entrypoint
TOOL="${1:-}"
PACKAGE="${2:-}"
BIN="${3:-}"
DIST_TAG="${4:-}"
SMOKE="${5:-}"
SEPARATOR="${6:-}"
if [ "$#" -lt 6 ] || [ "${SEPARATOR}" != "--" ]; then
    die "usage: TOOL PACKAGE BIN DIST_TAG SMOKE -- [ARGS...]" "${EXIT_MISSING_ARG}"
fi
shift 6

require_component "${TOOL}" "tool"
require_arg "${PACKAGE}" "package"
require_component "${BIN}" "bin"
require_component "${DIST_TAG}" "dist-tag"
require_arg "${SMOKE}" "smoke"

run_npm_package "${TOOL}" "${PACKAGE}" "${BIN}" "${DIST_TAG}" "${SMOKE}" "--" "$@"
