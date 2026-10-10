#!/usr/bin/env bash
set -euo pipefail
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir "${work}/bin"
{
    printf '#!%s\n' "${BASH}"
    cat <<'FAKE'
printf '%s\n' "$*" >> "$CALLS"
if [ "${FAIL_PORT:-}" = "${2#--https=}" ]; then
    echo 'fake: tailscaled unavailable' >&2
    exit 1
fi
FAKE
} >"${work}/bin/tailscale"
chmod +x "${work}/bin/tailscale"
export PATH="${work}/bin:${PATH}" CALLS="${work}/calls"
script=${1}
entry() { jq -cn --argjson port "$1" --arg mode "${2:-serve}" '{port:$port,stop:["tailscale",$mode,"--https=\($port)","off"]}'; }
entry 443 | jq -s . >"${work}/manifest"
bash -euo pipefail "${script}" "${work}/state" "${work}/manifest"
test ! -e "${CALLS}"
echo 'PASS first activation: records 443; no cleanup of unknown/manual ports'
bash -euo pipefail "${script}" "${work}/state" "${work}/manifest"
test ! -e "${CALLS}"
echo 'PASS unchanged: no tailscale calls'
entry 8443 funnel | jq -s . >"${work}/manifest"
bash -euo pipefail "${script}" "${work}/state" "${work}/manifest"
calls=$(cat "${CALLS}")
test "${calls}" = 'serve --https=443 off'
jq -e 'map(.port) == [8443]' "${work}/state" >/dev/null
echo "PASS changed 443 -> 8443: ${calls}"
: >"${CALLS}"
printf '[]\n' >"${work}/manifest"
FAIL_PORT=8443 bash -euo pipefail "${script}" "${work}/state" "${work}/manifest"
jq -e 'map(.port) == [8443]' "${work}/state" >/dev/null
echo 'PASS failed removal: ownership retained for retry'
: >"${CALLS}"
bash -euo pipefail "${script}" "${work}/state" "${work}/manifest"
calls=$(cat "${CALLS}")
test "${calls}" = 'funnel --https=8443 off'
jq -e '. == []' "${work}/state" >/dev/null
echo "PASS removed: ${calls}; ownership now []"
: >"${CALLS}"
bash -euo pipefail "${script}" "${work}/state" "${work}/manifest"
test ! -s "${CALLS}"
echo 'PASS repeated empty activation: no tailscale calls'
