# shellcheck shell=sh

set -eu

bundle_id=${1:?bundle_id required}
app_name=${2:?app_name required}
mode=${3:?mode required}
state_dir=${4:?state_dir required}
timeout_seconds=${5:?timeout_seconds required}
kill_grace_seconds=${6:?kill_grace_seconds required}
reset_on_frontmost=${7:?reset_on_frontmost required}
initialize_on_first_seen=${8:?initialize_on_first_seen required}

last_active_file="${state_dir}/last-active"
instance_file="${state_dir}/instance"
lock_file="${state_dir}/lock"
lock_owned=0

timestamp() {
    date '+%Y-%m-%dT%H:%M:%S%z'
}

log() {
    set +e
    timestamp_value=$(timestamp)
    set -e
    printf '%s %s\n' "${timestamp_value}" "$*"
}

err() {
    set +e
    timestamp_value=$(timestamp)
    set -e
    printf '%s ERROR: %s\n' "${timestamp_value}" "$*" >&2
}

write_last_active() {
    date +%s >"${last_active_file}"
}

write_instance() {
    pid=$1
    asn=$2
    launch_time=$3

    printf 'pid=%s\nasn=%s\nlaunch_time=%s\n' \
        "${pid}" \
        "${asn}" \
        "${launch_time}" >"${instance_file}"
}

read_instance_value() {
    key=$1

    if [ ! -f "${instance_file}" ]; then
        return 0
    fi

    sed -n "s/^${key}=//p" "${instance_file}" | head -n1
}

is_numeric() {
    case $1 in
        '' | *[!0-9]*)
            is_numeric_result=0
            ;;
        *)
            is_numeric_result=1
            ;;
    esac
}

acquire_lock() {
    holder=""

    if (
        set -C
        printf '%s\n' "$$" >"${lock_file}"
    ) 2>/dev/null; then
        lock_owned=1
        return 0
    fi

    if [ -f "${lock_file}" ]; then
        holder=$(tr -d '\n' <"${lock_file}" 2>/dev/null || true)
        is_numeric "${holder}"

        if [ "${is_numeric_result}" = "1" ] && ! kill -0 "${holder}" 2>/dev/null; then
            rm -f "${lock_file}"

            if (
                set -C
                printf '%s\n' "$$" >"${lock_file}"
            ) 2>/dev/null; then
                lock_owned=1
                log "${app_name} idle guard cleared stale lock from pid=${holder}"
                return 0
            fi
        fi
    fi

    log "${app_name} idle guard skipping overlapping run"
    exit 0
}

cleanup() {
    [ "${lock_owned}" = "1" ] && rm -f "${lock_file}"
}

get_front_bundle_id() {
    front_asn=$(/usr/bin/lsappinfo front 2>/dev/null || true)

    [ -n "${front_asn}" ] || return 0

    /usr/bin/lsappinfo info -only bundleID "${front_asn}" 2>/dev/null \
        | sed -n 's/^.*="\([^"]*\)"$/\1/p' \
        | head -n1
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

maybe_initialize_state() {
    pid=$1
    asn=$2
    launch_time=$3

    write_instance "${pid}" "${asn}" "${launch_time}"

    if [ "${initialize_on_first_seen}" = "1" ]; then
        write_last_active
        log "${app_name} idle guard initialized state"
    else
        log "${app_name} idle guard skipped initialization because initializeOnFirstSeen=false"
    fi

    exit 0
}

mkdir -p "${state_dir}"
trap cleanup 0 INT TERM
acquire_lock

front_bundle_id=$(get_front_bundle_id)
matches=$(resolve_target_matches)
match_count=$(count_lines "${matches}")

[ "${match_count}" -eq 0 ] && exit 0

if [ "${match_count}" -gt 1 ]; then
    log "${app_name} idle guard found multiple matching app instances for bundle id ${bundle_id}; skipping"
    exit 0
fi

target_match=$(first_line "${matches}")
target_info=$(read_target_info "${target_match}")

if [ -z "${target_info}" ]; then
    err "${app_name} idle guard could not read lsappinfo for bundle id ${bundle_id}"
    exit 0
fi

target_asn=$(parse_asn "${target_info}")
target_pid=$(parse_pid "${target_info}")
target_launch_time=$(parse_launch_time "${target_info}")

if [ -z "${target_asn}" ] || [ -z "${target_pid}" ]; then
    err "${app_name} idle guard failed to parse target instance details for bundle id ${bundle_id}"
    exit 0
fi

if [ "${front_bundle_id}" = "${bundle_id}" ]; then
    write_instance "${target_pid}" "${target_asn}" "${target_launch_time}"
    [ "${reset_on_frontmost}" = "1" ] && write_last_active
    exit 0
fi

[ -f "${last_active_file}" ] || maybe_initialize_state "${target_pid}" "${target_asn}" "${target_launch_time}"

stored_pid=$(read_instance_value pid)
stored_asn=$(read_instance_value asn)
stored_launch_time=$(read_instance_value launch_time)

if [ "${stored_pid}" != "${target_pid}" ] || [ "${stored_asn}" != "${target_asn}" ] || [ "${stored_launch_time}" != "${target_launch_time}" ]; then
    write_instance "${target_pid}" "${target_asn}" "${target_launch_time}"
    write_last_active
    log "${app_name} idle guard detected a new app instance and reset idle state"
    exit 0
fi

last_active_raw=$(tr -d '\n' <"${last_active_file}" 2>/dev/null || true)
is_numeric "${last_active_raw}"

if [ "${is_numeric_result}" = "0" ]; then
    maybe_initialize_state "${target_pid}" "${target_asn}" "${target_launch_time}"
fi

now=$(date +%s)
idle_seconds=$((now - last_active_raw))
[ "${idle_seconds}" -lt "${timeout_seconds}" ] && exit 0

case "${mode}" in
    log-only)
        log "${app_name} idle guard would terminate pid=${target_pid} asn=${target_asn} after ${idle_seconds}s idle"
        ;;

    term)
        if kill -TERM "${target_pid}" 2>/dev/null; then
            log "${app_name} idle guard sent SIGTERM to pid=${target_pid} asn=${target_asn} after ${idle_seconds}s idle"
        else
            err "${app_name} idle guard failed to send SIGTERM to pid=${target_pid} asn=${target_asn}"
        fi
        ;;

    term-then-kill)
        if ! kill -TERM "${target_pid}" 2>/dev/null; then
            err "${app_name} idle guard failed to send SIGTERM to pid=${target_pid} asn=${target_asn}"
            exit 0
        fi

        log "${app_name} idle guard sent SIGTERM to pid=${target_pid} asn=${target_asn} after ${idle_seconds}s idle"
        sleep "${kill_grace_seconds}"

        matches_after=$(resolve_target_matches)
        match_count_after=$(count_lines "${matches_after}")

        if [ "${match_count_after}" -eq 0 ]; then
            log "${app_name} idle guard confirmed the app exited after SIGTERM"
            exit 0
        fi

        if [ "${match_count_after}" -gt 1 ]; then
            log "${app_name} idle guard found multiple matching instances after SIGTERM; skipping SIGKILL"
            exit 0
        fi

        target_match_after=$(first_line "${matches_after}")
        target_info_after=$(read_target_info "${target_match_after}")
        target_asn_after=$(parse_asn "${target_info_after}")
        target_pid_after=$(parse_pid "${target_info_after}")
        target_launch_time_after=$(parse_launch_time "${target_info_after}")

        if [ -z "${target_asn_after}" ] || [ -z "${target_pid_after}" ]; then
            err "${app_name} idle guard could not re-resolve the app after SIGTERM; skipping SIGKILL"
            exit 0
        fi

        if [ "${target_asn_after}" != "${target_asn}" ] || [ "${target_pid_after}" != "${target_pid}" ] || [ "${target_launch_time_after}" != "${target_launch_time}" ]; then
            log "${app_name} idle guard detected a different app instance after SIGTERM; skipping SIGKILL"
            exit 0
        fi

        if ! kill -0 "${target_pid_after}" 2>/dev/null; then
            log "${app_name} idle guard confirmed the app exited after SIGTERM"
            exit 0
        fi

        if kill -KILL "${target_pid_after}" 2>/dev/null; then
            log "${app_name} idle guard sent SIGKILL to pid=${target_pid_after} asn=${target_asn_after} after waiting ${kill_grace_seconds}s"
        else
            err "${app_name} idle guard failed to send SIGKILL to pid=${target_pid_after} asn=${target_asn_after}"
        fi
        ;;

    *)
        :
        ;;
esac
