#!/bin/sh

# EXIT_MISSING_DIR
# Exit code for missing directory
EXIT_MISSING_DIR="1"

# EXIT_MISSING_ARG
# Exit code for missing argument
EXIT_MISSING_ARG="2"

# AGENTS_HOME
# Root of agents repo
AGENTS_HOME="${HOME}/.config/agents"

# SYNC_RUNNER
# Runtime used to execute the sync script. Set by wrapper entrypoint.
SYNC_RUNNER=""

# SYNC_SCRIPT
# Sync script path. Set by wrapper entrypoint.
SYNC_SCRIPT=""

# SYNC_TIMEOUT_SECS
# Max launch-time sync runtime before forced cleanup.
SYNC_TIMEOUT_SECS="60"

# SYNC_TERM_GRACE_SECS
# Grace period before escalating to SIGKILL.
SYNC_TERM_GRACE_SECS="2"

SYNC_PID=""
SYNC_TIMER_PID=""
SYNC_TIMEOUT_FLAG=""

# die
# Emit error and exit
die() {
    msg="${1}"
    code="${2:-1}"
    printf '%s\n' "llm-agent: ${msg}" >&2
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

# require_uint
# Require unsigned integer value
require_uint() {
    value="${1}"
    label="${2}"
    case "${value}" in
        '' | *[!0-9]*)
            die "invalid ${label}: ${value}"
            ;;
        *) : ;;
    esac
    return 0
}

# require_dir
# Require directory to exist
require_dir() {
    path="${1}"
    [ -d "${path}" ] || die "missing agents dir: ${path}" "${EXIT_MISSING_DIR}"
    return 0
}

# set_sync_command
# Configure sync runner and script path
set_sync_command() {
    SYNC_RUNNER="${1:-}"
    SYNC_SCRIPT="${2:-}"
    require_arg "${SYNC_RUNNER}" "sync runner"
    require_arg "${SYNC_SCRIPT}" "sync script"
    return 0
}

sync_signal() {
    signal="${1}"
    child_pids=""
    child_pid=""

    [ -n "${SYNC_PID}" ] || return 0
    kill -0 "${SYNC_PID}" 2>/dev/null || return 0

    child_pids="$(pgrep -P "${SYNC_PID}" 2>/dev/null || :)"
    for child_pid in ${child_pids}; do
        kill "-${signal}" "${child_pid}" 2>/dev/null || :
    done
    kill "-${signal}" "${SYNC_PID}" 2>/dev/null || :
    return 0
}

stop_sync_timer() {
    [ -n "${SYNC_TIMER_PID}" ] || return 0
    kill "${SYNC_TIMER_PID}" 2>/dev/null || :
    wait "${SYNC_TIMER_PID}" 2>/dev/null || :
    SYNC_TIMER_PID=""
    return 0
}

wait_for_sync_exit() {
    remaining="${1}"

    while kill -0 "${SYNC_PID}" 2>/dev/null; do
        [ "${remaining}" -gt 0 ] || return 1
        sleep 1
        remaining=$((remaining - 1))
    done

    return 0
}

cleanup_sync() {
    stop_sync_timer

    [ -n "${SYNC_PID}" ] || return 0
    kill -0 "${SYNC_PID}" 2>/dev/null || {
        SYNC_PID=""
        return 0
    }

    sync_signal TERM
    set +e
    wait_for_sync_exit "${SYNC_TERM_GRACE_SECS}"
    wait_status=$?
    set -e
    if [ "${wait_status}" -ne 0 ]; then
        sync_signal KILL
        set +e
        wait_for_sync_exit 1
        set -e
    fi

    wait "${SYNC_PID}" 2>/dev/null || :
    SYNC_PID=""
    return 0
}

on_wrapper_signal() {
    signal="${1}"

    cleanup_sync
    trap - EXIT HUP INT TERM

    case "${signal}" in
        HUP) exit 129 ;;
        INT) exit 130 ;;
        TERM) exit 143 ;;
        *) exit 1 ;;
    esac
}

start_sync_timer() {
    SYNC_TIMEOUT_FLAG="${TMPDIR:-/tmp}/llm-agent-sync-timeout-$$"
    rm -f "${SYNC_TIMEOUT_FLAG}"

    (
        sleep_pid=""
        # shellcheck disable=SC2329 # Invoked indirectly by the signal trap.
        stop_sleep() {
            [ -n "${sleep_pid}" ] || exit 0
            kill "${sleep_pid}" 2>/dev/null || :
            wait "${sleep_pid}" 2>/dev/null || :
            exit 0
        }
        trap 'stop_sleep' TERM HUP INT

        sleep "${SYNC_TIMEOUT_SECS}" &
        sleep_pid=$!
        wait "${sleep_pid}" || exit 0
        sleep_pid=""
        kill -0 "${SYNC_PID}" 2>/dev/null || exit 0

        printf '%s\n' "llm-agent: sync timed out after ${SYNC_TIMEOUT_SECS}s" >&2
        : >"${SYNC_TIMEOUT_FLAG}"
        sync_signal TERM

        sleep "${SYNC_TERM_GRACE_SECS}" &
        sleep_pid=$!
        wait "${sleep_pid}" || exit 0
        sleep_pid=""
        kill -0 "${SYNC_PID}" 2>/dev/null || exit 0
        sync_signal KILL
    ) &
    SYNC_TIMER_PID=$!
    return 0
}

# run_sync
# Run sync after checking agents dir
run_sync() {
    if [ ! -d "${AGENTS_HOME}" ]; then
        printf '%s\n' "llm-agent: missing agents dir: ${AGENTS_HOME}" >&2
        return "${EXIT_MISSING_DIR}"
    fi
    require_arg "${SYNC_RUNNER}" "sync runner"
    if [ ! -f "${SYNC_SCRIPT}" ]; then
        printf '%s\n' "llm-agent: missing sync script: ${SYNC_SCRIPT}" >&2
        return "${EXIT_MISSING_DIR}"
    fi
    require_uint "${SYNC_TIMEOUT_SECS}" "sync timeout"
    require_uint "${SYNC_TERM_GRACE_SECS}" "sync grace period"

    trap 'cleanup_sync' EXIT
    trap 'on_wrapper_signal HUP' HUP
    trap 'on_wrapper_signal INT' INT
    trap 'on_wrapper_signal TERM' TERM

    "${SYNC_RUNNER}" "${SYNC_SCRIPT}" &
    SYNC_PID=$!
    start_sync_timer

    status=0
    wait "${SYNC_PID}" || status=$?
    SYNC_PID=""
    stop_sync_timer

    trap - EXIT HUP INT TERM
    if [ -n "${SYNC_TIMEOUT_FLAG}" ] && [ -f "${SYNC_TIMEOUT_FLAG}" ]; then
        rm -f "${SYNC_TIMEOUT_FLAG}"
        SYNC_TIMEOUT_FLAG=""
        return 124
    fi

    SYNC_TIMEOUT_FLAG=""
    return "${status}"
}

# try_sync
# Run sync; warn and continue on failure.
try_sync() {
    set +e
    run_sync
    sync_status=$?
    set -e
    if [ "${sync_status}" -ne 0 ]; then
        printf '%s\n' "llm-agent: warning: continuing launch without completed sync" >&2
    fi
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
# Sync, cache, and execute an npm package binary.
run_npm_package() {
    if [ "$#" -lt 5 ]; then
        die "usage: run_npm_package TOOL PACKAGE BIN DIST_TAG -- [ARGS...]" "${EXIT_MISSING_ARG}"
    fi

    TOOL="$1"
    PACKAGE="$2"
    BIN="$3"
    DIST_TAG="$4"
    SEPARATOR="$5"
    shift 5

    [ "${SEPARATOR}" = "--" ] || die "missing -- separator" "${EXIT_MISSING_ARG}"
    require_component "${TOOL}" "tool"
    require_arg "${PACKAGE}" "package"
    require_component "${BIN}" "bin"
    require_component "${DIST_TAG}" "dist-tag"

    try_sync

    CACHE_HOME="${XDG_CACHE_HOME:-}"
    if [ -z "${CACHE_HOME}" ]; then
        CACHE_HOME="${HOME:-}"
        [ -n "${CACHE_HOME}" ] || die "missing XDG_CACHE_HOME or HOME"
        CACHE_HOME="${CACHE_HOME}/.cache"
    fi

    AGENT_CACHE="${CACHE_HOME}/agent-tools/${TOOL}"
    VERSIONS_DIR="${AGENT_CACHE}/versions"
    CURRENT_LINK="${AGENT_CACHE}/current"
    PREVIOUS_LINK="${AGENT_CACHE}/previous"
    LOCK_FILE="${AGENT_CACHE}/lock"

    mkdir -p "${VERSIONS_DIR}"

    # Keep the exclusive lock through resolution, installation, and symlink updates.
    # Release it immediately before handing control to the launched agent.
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
        "${STAGED_BIN}" --version >/dev/null

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
            PREVIOUS_TMP="${AGENT_CACHE}/.previous.$$"
            rm -f -- "${PREVIOUS_TMP}"
            ln -s -- "${CURRENT_TARGET}" "${PREVIOUS_TMP}"
            mv -fT -- "${PREVIOUS_TMP}" "${PREVIOUS_LINK}"
        fi

        CURRENT_TMP="${AGENT_CACHE}/.current.$$"
        rm -f -- "${CURRENT_TMP}"
        ln -s -- "${EXPECTED_TARGET}" "${CURRENT_TMP}"
        mv -fT -- "${CURRENT_TMP}" "${CURRENT_LINK}"
    fi

    CURRENT_BIN="${CURRENT_LINK}/node_modules/.bin/${BIN}"
    [ -x "${CURRENT_BIN}" ] || die "current package has no executable bin: ${BIN}"

    exec 9>&-
    exec "${CURRENT_BIN}" "$@"
}
