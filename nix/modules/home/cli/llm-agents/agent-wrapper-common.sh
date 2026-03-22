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

# SYNC
# Sync script path
SYNC="${AGENTS_HOME}/bin/sync"

# SYNC_TIMEOUT_SECS
# Max sync runtime before forced cleanup
SYNC_TIMEOUT_SECS="${LLM_AGENT_SYNC_TIMEOUT_SECS:-300}"

# SYNC_TERM_GRACE_SECS
# Grace period before escalating to SIGKILL
SYNC_TERM_GRACE_SECS="${LLM_AGENT_SYNC_TERM_GRACE_SECS:-5}"

SYNC_PID=""
SYNC_PGID=""
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
        SYNC_PGID=""
        return 0
    }

    sync_signal TERM
    if ! wait_for_sync_exit "${SYNC_TERM_GRACE_SECS}"; then
        sync_signal KILL
        wait_for_sync_exit 1 || :
    fi

    wait "${SYNC_PID}" 2>/dev/null || :
    SYNC_PID=""
    SYNC_PGID=""
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
    esac

    exit 1
}

start_sync_timer() {
    SYNC_TIMEOUT_FLAG="${TMPDIR:-/tmp}/llm-agent-sync-timeout-$$"
    rm -f "${SYNC_TIMEOUT_FLAG}"

    (
        trap 'exit 0' TERM HUP INT
        sleep "${SYNC_TIMEOUT_SECS}" || exit 0
        kill -0 "${SYNC_PID}" 2>/dev/null || exit 0

        printf '%s\n' "llm-agent: sync timed out after ${SYNC_TIMEOUT_SECS}s" >&2
        : >"${SYNC_TIMEOUT_FLAG}"
        sync_signal TERM

        sleep "${SYNC_TERM_GRACE_SECS}" || exit 0
        kill -0 "${SYNC_PID}" 2>/dev/null || exit 0
        sync_signal KILL
    ) &
    SYNC_TIMER_PID=$!
    return 0
}

# run_sync
# Run sync after checking agents dir
run_sync() {
    require_dir "${AGENTS_HOME}"
    require_uint "${SYNC_TIMEOUT_SECS}" "sync timeout"
    require_uint "${SYNC_TERM_GRACE_SECS}" "sync grace period"

    trap 'cleanup_sync' EXIT
    trap 'on_wrapper_signal HUP' HUP
    trap 'on_wrapper_signal INT' INT
    trap 'on_wrapper_signal TERM' TERM

    "${SYNC}" &
    SYNC_PID=$!
    SYNC_PGID=""
    start_sync_timer

    status=0
    wait "${SYNC_PID}" || status=$?
    SYNC_PID=""
    SYNC_PGID=""
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

# run_exec
# Run sync then exec command
run_exec() {
    run_sync
    exec "$@"
}
