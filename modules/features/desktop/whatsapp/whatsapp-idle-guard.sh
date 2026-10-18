# shellcheck shell=sh

set -eu

app_path=${1:?app_path required}
sleep_block_seconds=${2:?sleep_block_seconds required}
kill_grace_seconds=${3:?kill_grace_seconds required}

log() {
    stamp=$(date '+%Y-%m-%dT%H:%M:%S%z')
    printf '%s %s\n' "${stamp}" "$*"
}

pids=$(/usr/bin/pgrep -f "^${app_path}/Contents/" | tr '\n' ' ' || true)
[ -n "${pids}" ] || exit 0

assertions=$(/usr/bin/pmset -g assertions 2>/dev/null || true)

in_call=$(printf '%s\n' "${assertions}" \
    | awk -v pids="${pids}" '
        BEGIN { n = split(pids, p, " "); for (i = 1; i <= n; i++) ours[p[i]] = 1 }
        $1 == "pid" { owner = $2 }
        $1 == "Created" && $2 == "for" && $3 == "PID:" && ($4 + 0) in ours && owner ~ /^[0-9]+\(coreaudiod\)/ { print 1; exit }' || true)

[ -z "${in_call}" ] || exit 0

hid_idle=$(/usr/sbin/ioreg -c IOHIDSystem 2>/dev/null \
    | awk '/HIDIdleTime/ { print int($NF / 1000000000); exit }' || true)
hid_idle=${hid_idle:-0}

lid_state=$(/usr/sbin/ioreg -r -k AppleClamshellState -d1 2>/dev/null \
    | awk '/"AppleClamshellState"/ { print $NF; exit }' || true)
[ "${lid_state}" != "Yes" ] || sleep_block_seconds=60

[ "${hid_idle}" -ge "${sleep_block_seconds}" ] || exit 0

blocker=$(printf '%s\n' "${assertions}" \
    | awk -v pids="${pids}" -v min="${sleep_block_seconds}" '
        BEGIN { n = split(pids, p, " "); for (i = 1; i <= n; i++) ours[p[i]] = 1 }
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
            owner = $2
            sub(/\(.*/, "", owner)
            hit = blocks && (owner + 0) in ours
            camera = blocks && name ~ /^cameracaptured/
            next
        }
        camera && $1 == "Created" && $3 == "PID:" && ($4 + 0) in ours { hit = 1 }
        END { emit() }' || true)

[ -n "${blocker}" ] || exit 0

reason="holding ${blocker} for over ${sleep_block_seconds}s while user idle ${hid_idle}s"

# shellcheck disable=SC2086 # pids is a space-separated list
kill -TERM ${pids} 2>/dev/null || true
log "sent SIGTERM to WhatsApp pids=${pids}: ${reason}"
sleep "${kill_grace_seconds}"

for pid in ${pids}; do
    if kill -0 "${pid}" 2>/dev/null; then
        kill -KILL "${pid}" 2>/dev/null || true
        log "sent SIGKILL to WhatsApp pid=${pid} after ${kill_grace_seconds}s"
    fi
done
