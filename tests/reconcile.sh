# shellcheck shell=bash

set -euo pipefail

reconcile=${1}
work=$(mktemp -d)
trap 'rm -rf "${work}"' EXIT
user=$(id -un)
mkdir "${work}/bin"
export PATH="${work}/bin:${PATH}"
export TCC_RESULT="${work}/tcc-result"

# shellcheck disable=SC2016 # Expanded by the generated command, not the test.
printf '%s\n' '#!/bin/sh' 'result=$(cat "${TCC_RESULT}")' 'printf "%s\n" "${result}" >&2' '[ "${result}" = success ]' >"${work}/bin/launchctl"
chmod +x "${work}/bin/launchctl"
printf '%s\n' '[]' >"${work}/manifest.json"
printf '%s\n' '[{"kind":"privacy","id":"grant","service":"Accessibility","bundleId":"com.example.Removed","restart":[]}]' >"${work}/state.json"

printf '%s\n' 'Failed to reset: OSStatus -10814' >"${TCC_RESULT}"
bash "${reconcile}" "${work}/state.json" "${work}/manifest.json" "${user}"
jq -e '. == [{"kind":"privacy","id":"grant","service":"Accessibility","bundleId":"com.example.Removed","restart":[]}]' "${work}/state.json"

printf '%s\n' success >"${TCC_RESULT}"
bash "${reconcile}" "${work}/state.json" "${work}/manifest.json" "${user}"
jq -e '. == []' "${work}/state.json"
bash "${reconcile}" "${work}/state.json" "${work}/manifest.json" "${user}"
jq -e '. == []' "${work}/state.json"

printf '%s\n' managed >"${work}/managed"
printf '%s\n' unmanaged >"${work}/unmanaged"
jq -n --arg file "${work}/managed" '[{kind:"file",id:"file",file:$file,restart:[]}]' >"${work}/manifest.json"
bash "${reconcile}" "${work}/first-run.json" "${work}/manifest.json" "${user}"
test "$(<"${work}/managed")" = managed
jq -e '.[0].id == "file"' "${work}/first-run.json"
printf '%s\n' '[]' >"${work}/manifest.json"
bash "${reconcile}" "${work}/first-run.json" "${work}/manifest.json" "${user}"
test ! -e "${work}/managed"
test "$(<"${work}/unmanaged")" = unmanaged
jq -e '. == []' "${work}/first-run.json"

printf '%s\n' '{invalid' >"${work}/broken.json"
if bash "${reconcile}" "${work}/broken.json" "${work}/manifest.json" "${user}" 2>/dev/null; then
    exit 1
fi
test "$(<"${work}/broken.json")" = '{invalid'

export DSCL_SHELL="${work}/login-shell"
# shellcheck disable=SC2016 # Expanded by the generated command, not the test.
printf '%s\n' '#!/bin/sh' '[ -e "${DSCL_SHELL}" ] || exit 1' 'if [ "$2" = -read ]; then printf "UserShell: %s\n" "$(cat "${DSCL_SHELL}")"; else printf "%s\n" "$5" >"${DSCL_SHELL}"; fi' >"${work}/bin/dscl"
chmod +x "${work}/bin/dscl"
shell_entry='[{"kind":"shell","id":"shell","shell":"/run/current-system/sw/bin/bash","restart":[]}]'
printf '%s\n' '[]' >"${work}/manifest.json"

printf '%s\n' "${shell_entry}" >"${work}/shell.json"
bash "${reconcile}" "${work}/shell.json" "${work}/manifest.json" "${user}"
jq -e --argjson entry "${shell_entry}" '. == $entry' "${work}/shell.json"

printf '%s\n' /run/current-system/sw/bin/bash >"${DSCL_SHELL}"
bash "${reconcile}" "${work}/shell.json" "${work}/manifest.json" "${user}"
test "$(<"${DSCL_SHELL}")" = /bin/zsh
jq -e '. == []' "${work}/shell.json"

printf '%s\n' /opt/homebrew/bin/fish >"${DSCL_SHELL}"
printf '%s\n' "${shell_entry}" >"${work}/shell.json"
bash "${reconcile}" "${work}/shell.json" "${work}/manifest.json" "${user}"
test "$(<"${DSCL_SHELL}")" = /opt/homebrew/bin/fish
jq -e '. == []' "${work}/shell.json"
