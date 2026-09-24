# shellcheck shell=sh
# WhatsApp sleep/display-sleep quit hook.
#
# Runs from sleepwatcher when macOS is about to sleep or when the display goes
# to sleep. This is intentionally separate from the idle guard: the idle guard
# tracks frontmost activity over time, while this hook reacts to explicit power
# transition events.
#
# Arguments, in order:
# 1. bundle_id            exact app bundle id to quit
# 2. app_name             friendly name for logs
# 3. mode                 term | term-then-kill
# 4. kill_grace_seconds   wait between SIGTERM and SIGKILL
#
# Behavior:
# - resolve the target app via exact bundle id
# - refuse to act if the target is ambiguous
# - send SIGTERM first
# - optionally re-resolve and SIGKILL the same instance if it survives
#
# Note: sleepwatcher documents that sleep hooks must finish quickly. Keep the
# grace period below 15 seconds.

set -eu

bundle_id=${1:?bundle_id required}
app_name=${2:?app_name required}
mode=${3:?mode required}
kill_grace_seconds=${4:?kill_grace_seconds required}

timestamp() {
    date '+%Y-%m-%dT%H:%M:%S%z'
}

log() {
    set +e
    log_timestamp=$(timestamp)
    set -e
    printf '%s %s\n' "${log_timestamp}" "$*"
}

err() {
    set +e
    err_timestamp=$(timestamp)
    set -e
    printf '%s ERROR: %s\n' "${err_timestamp}" "$*" >&2
}

resolve_target_matches() {
    /usr/bin/lsappinfo find "bundleID=${bundle_id}" 2>/dev/null \
        | sed 's/ ASN:/\
ASN:/g' \
        | grep '^ASN:' || true
}

read_target_info() {
    match=$1
    /usr/bin/lsappinfo info "${match}" 2>/dev/null || true
}

parse_asn() {
    printf '%s\n' "$1" | grep -o 'ASN:[^:]*:' | head -n1 || true
}

parse_pid() {
    printf '%s\n' "$1" | sed -n 's/.*pid = \([0-9][0-9]*\).*/\1/p' | head -n1 || true
}

parse_launch_time() {
    printf '%s\n' "$1" \
        | sed -n 's/^[[:space:]]*launch time =  *//p' \
        | sed 's/ (.*$//' \
        | head -n1 || true
}

count_lines() {
    printf '%s\n' "$1" | sed '/^$/d' | wc -l | tr -d ' '
}

first_line() {
    printf '%s\n' "$1" | sed -n '1p'
}

matches=$(resolve_target_matches)
match_count=$(count_lines "${matches}")

[ "${match_count}" -eq 0 ] && exit 0

if [ "${match_count}" -gt 1 ]; then
    log "${app_name} sleep hook found multiple matching app instances for bundle id ${bundle_id}; skipping"
    exit 0
fi

target_match=$(first_line "${matches}")
target_info=$(read_target_info "${target_match}")

if [ -z "${target_info}" ]; then
    err "${app_name} sleep hook could not read lsappinfo for bundle id ${bundle_id}"
    exit 0
fi

target_asn=$(parse_asn "${target_info}")
target_pid=$(parse_pid "${target_info}")
target_launch_time=$(parse_launch_time "${target_info}")

if [ -z "${target_asn}" ] || [ -z "${target_pid}" ]; then
    err "${app_name} sleep hook failed to parse target instance details for bundle id ${bundle_id}"
    exit 0
fi

case "${mode}" in
    term)
        if kill -TERM "${target_pid}" 2>/dev/null; then
            log "${app_name} sleep hook sent SIGTERM to pid=${target_pid} asn=${target_asn}"
        else
            err "${app_name} sleep hook failed to send SIGTERM to pid=${target_pid} asn=${target_asn}"
        fi
        ;;

    term-then-kill)
        if ! kill -TERM "${target_pid}" 2>/dev/null; then
            err "${app_name} sleep hook failed to send SIGTERM to pid=${target_pid} asn=${target_asn}"
            exit 0
        fi

        log "${app_name} sleep hook sent SIGTERM to pid=${target_pid} asn=${target_asn}"
        sleep "${kill_grace_seconds}"

        matches_after=$(resolve_target_matches)
        match_count_after=$(count_lines "${matches_after}")

        if [ "${match_count_after}" -eq 0 ]; then
            log "${app_name} sleep hook confirmed the app exited after SIGTERM"
            exit 0
        fi

        if [ "${match_count_after}" -gt 1 ]; then
            log "${app_name} sleep hook found multiple matching instances after SIGTERM; skipping SIGKILL"
            exit 0
        fi

        target_match_after=$(first_line "${matches_after}")
        target_info_after=$(read_target_info "${target_match_after}")
        target_asn_after=$(parse_asn "${target_info_after}")
        target_pid_after=$(parse_pid "${target_info_after}")
        target_launch_time_after=$(parse_launch_time "${target_info_after}")

        if [ -z "${target_asn_after}" ] || [ -z "${target_pid_after}" ]; then
            err "${app_name} sleep hook could not re-resolve the app after SIGTERM; skipping SIGKILL"
            exit 0
        fi

        if [ "${target_asn_after}" != "${target_asn}" ] || [ "${target_pid_after}" != "${target_pid}" ] || [ "${target_launch_time_after}" != "${target_launch_time}" ]; then
            log "${app_name} sleep hook detected a different app instance after SIGTERM; skipping SIGKILL"
            exit 0
        fi

        if ! kill -0 "${target_pid_after}" 2>/dev/null; then
            log "${app_name} sleep hook confirmed the app exited after SIGTERM"
            exit 0
        fi

        if kill -KILL "${target_pid_after}" 2>/dev/null; then
            log "${app_name} sleep hook sent SIGKILL to pid=${target_pid_after} asn=${target_asn_after} after waiting ${kill_grace_seconds}s"
        else
            err "${app_name} sleep hook failed to send SIGKILL to pid=${target_pid_after} asn=${target_asn_after}"
        fi
        ;;

    *) ;;
esac
