# shellcheck shell=sh

set -eu

bundle_id=${1:?bundle_id required}
state_dir=${2:?state_dir required}
timeout_seconds=${3:?timeout_seconds required}
sleep_block_seconds=${4:?sleep_block_seconds required}
kill_grace_seconds=${5:?kill_grace_seconds required}

present_seconds=120
last_active_file="${state_dir}/last-active"

log() {
    stamp=$(date '+%Y-%m-%dT%H:%M:%S%z')
    printf '%s %s\n' "${stamp}" "$*"
}

pid_of() {
    /usr/bin/lsappinfo info -only pid "$1" 2>/dev/null \
        | awk '{ for (i = 1; i < NF; i++) if ($i == "pid") { print $(i + 2); exit } }' || true
}

target=$(/usr/bin/lsappinfo find "bundleid=${bundle_id}" 2>/dev/null | awk 'NR == 1' || true)

if [ -z "${target}" ]; then
    rm -f "${last_active_file}"
    exit 0
fi

pid=$(pid_of "${target}")
[ -n "${pid}" ] || exit 0

now=$(date +%s)

assertions=$(/usr/bin/pmset -g assertions 2>/dev/null || true)

in_call=$(printf '%s\n' "${assertions}" \
    | awk -v pid="${pid}" '
        $1 == "pid" { owner = $2 }
        $1 == "Created" && $2 == "for" && $3 == "PID:" && $4 + 0 == pid && owner ~ /^[0-9]+\(coreaudiod\)/ { print 1; exit }' || true)

if [ -n "${in_call}" ]; then
    printf '%s\n' "${now}" >"${last_active_file}"
    exit 0
fi

hid_idle=$(/usr/sbin/ioreg -c IOHIDSystem 2>/dev/null \
    | awk '/HIDIdleTime/ { print int($NF / 1000000000); exit }' || true)
hid_idle=${hid_idle:-0}

lid_state=$(/usr/sbin/ioreg -r -k AppleClamshellState -d1 2>/dev/null \
    | awk '/"AppleClamshellState"/ { print $NF; exit }' || true)
[ "${lid_state}" != "Yes" ] || sleep_block_seconds=60

front=$(/usr/bin/lsappinfo front 2>/dev/null || true)
front_pid=""
[ -z "${front}" ] || front_pid=$(pid_of "${front}")

if [ "${front_pid}" = "${pid}" ] && [ "${hid_idle}" -lt "${present_seconds}" ]; then
    printf '%s\n' "${now}" >"${last_active_file}"
    exit 0
fi

last_active=$(cat "${last_active_file}" 2>/dev/null || true)
case ${last_active} in
    '' | *[!0-9]*)
        printf '%s\n' "${now}" >"${last_active_file}"
        exit 0
        ;;
    *) ;;
esac

blocker=$(printf '%s\n' "${assertions}" \
    | awk -v pid="${pid}" -v min="${sleep_block_seconds}" '
        function emit() {
            if (hit && !done) { done = 1; print type " \"" name "\""; exit }
        }
        $1 == "pid" {
            emit()
            type = $5
            name = $0
            sub(/^[^"]*"/, "", name)
            sub(/".*$/, "", name)
            split($4, t, ":")
            blocks = (t[1] * 3600 + t[2] * 60 + t[3] >= min) \
                && (type == "PreventUserIdleSystemSleep" || type == "PreventSystemSleep")
            hit = blocks && index($2, pid "(") == 1
            camera = blocks && name ~ /^cameracaptured/
            next
        }
        camera && $1 == "Created" && $3 == "PID:" && $4 + 0 == pid { hit = 1 }
        END { emit() }' || true)

idle_seconds=$((now - last_active))

if [ -n "${blocker}" ] && [ "${hid_idle}" -ge "${sleep_block_seconds}" ]; then
    reason="holding ${blocker} for over ${sleep_block_seconds}s while user idle ${hid_idle}s"
elif [ "${idle_seconds}" -ge "${timeout_seconds}" ]; then
    reason="unused for ${idle_seconds}s"
else
    exit 0
fi

if ! kill -TERM "${pid}" 2>/dev/null; then
    log "failed to SIGTERM ${bundle_id} pid=${pid}: ${reason}"
    exit 0
fi

log "sent SIGTERM to ${bundle_id} pid=${pid}: ${reason}"
sleep "${kill_grace_seconds}"

if kill -0 "${pid}" 2>/dev/null; then
    kill -KILL "${pid}" 2>/dev/null || true
    log "sent SIGKILL to ${bundle_id} pid=${pid} after ${kill_grace_seconds}s"
fi

rm -f "${last_active_file}"
