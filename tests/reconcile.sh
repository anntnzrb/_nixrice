# shellcheck shell=bash

set -euo pipefail

reconcile=${1}
work=$(mktemp -d)
trap 'rm -rf "${work}"' EXIT
user=$(id -un)
uid=$(id -u)
mkdir "${work}/bin"
# shellcheck disable=SC2016 # Expanded by the generated command, not the test.
printf '%s\n' '#!/bin/sh' 'exec "$@"' >"${work}/bin/as-user"
chmod +x "${work}/bin/as-user"
export PATH="${work}/bin:${PATH}"
export TCC_RESULT="${work}/tcc-result"

# shellcheck disable=SC2016 # Expanded by the generated command, not the test.
printf '%s\n' '#!/bin/sh' 'result=$(cat "${TCC_RESULT}")' 'printf "%s\n" "${result}" >&2' '[ "${result}" = success ]' >"${work}/bin/tccutil"
chmod +x "${work}/bin/tccutil"
printf '%s\n' '[]' >"${work}/manifest.json"
printf '%s\n' '[{"kind":"privacy","id":"grant","service":"Accessibility","bundleId":"com.example.Removed","restart":[]}]' >"${work}/state.json"

printf '%s\n' 'Failed to reset: OSStatus -10814' >"${TCC_RESULT}"
bash "${reconcile}" "${work}/state.json" "${work}/manifest.json" "${user}" "${work}/bin/as-user" /usr/bin/true /usr/libexec/PlistBuddy
jq -e '. == [{"kind":"privacy","id":"grant","service":"Accessibility","bundleId":"com.example.Removed","restart":[]}]' "${work}/state.json"

printf '%s\n' success >"${TCC_RESULT}"
bash "${reconcile}" "${work}/state.json" "${work}/manifest.json" "${user}" "${work}/bin/as-user" /usr/bin/true /usr/libexec/PlistBuddy
jq -e '. == []' "${work}/state.json"
bash "${reconcile}" "${work}/state.json" "${work}/manifest.json" "${user}" "${work}/bin/as-user" /usr/bin/true /usr/libexec/PlistBuddy
jq -e '. == []' "${work}/state.json"

printf '%s\n' managed >"${work}/managed"
printf '%s\n' unmanaged >"${work}/unmanaged"
jq -n --arg file "${work}/managed" '[{kind:"file",id:"file",file:$file,restart:[]}]' >"${work}/manifest.json"
bash "${reconcile}" "${work}/first-run.json" "${work}/manifest.json" "${user}" "${work}/bin/as-user" /usr/bin/true /usr/libexec/PlistBuddy
test "$(<"${work}/managed")" = managed
jq -e '.[0].id == "file"' "${work}/first-run.json"
printf '%s\n' '[]' >"${work}/manifest.json"
bash "${reconcile}" "${work}/first-run.json" "${work}/manifest.json" "${user}" "${work}/bin/as-user" /usr/bin/true /usr/libexec/PlistBuddy
test ! -e "${work}/managed"
test "$(<"${work}/unmanaged")" = unmanaged
jq -e '. == []' "${work}/first-run.json"

printf '%s\n' '{invalid' >"${work}/broken.json"
if bash "${reconcile}" "${work}/broken.json" "${work}/manifest.json" "${user}" "${work}/bin/as-user" /usr/bin/true /usr/libexec/PlistBuddy 2>/dev/null; then
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
bash "${reconcile}" "${work}/shell.json" "${work}/manifest.json" "${user}" "${work}/bin/as-user" /usr/bin/true /usr/libexec/PlistBuddy
jq -e --argjson entry "${shell_entry}" '. == $entry' "${work}/shell.json"

printf '%s\n' /run/current-system/sw/bin/bash >"${DSCL_SHELL}"
bash "${reconcile}" "${work}/shell.json" "${work}/manifest.json" "${user}" "${work}/bin/as-user" /usr/bin/true /usr/libexec/PlistBuddy
test "$(<"${DSCL_SHELL}")" = /bin/zsh
jq -e '. == []' "${work}/shell.json"

export LAUNCHCTL_RESULT="${work}/launchctl-result"
export LAUNCHCTL_ARGS="${work}/launchctl-args"
# shellcheck disable=SC2016 # Expanded by the generated command, not the test.
printf '%s\n' '#!/bin/sh' 'printf "%s\n" "$@" >"${LAUNCHCTL_ARGS}"' '[ "$(cat "${LAUNCHCTL_RESULT}")" = success ]' >"${work}/bin/launchctl"
chmod +x "${work}/bin/launchctl"
launchd_entry='[{"kind":"launchdDisabled","id":"launchd","label":"com.example.Removed","restart":[]}]'
printf '%s\n' "${launchd_entry}" >"${work}/launchd.json"
printf '%s\n' failure >"${LAUNCHCTL_RESULT}"
bash "${reconcile}" "${work}/launchd.json" "${work}/manifest.json" "${user}" "${work}/bin/as-user" /usr/bin/true /usr/libexec/PlistBuddy
jq -e --argjson entry "${launchd_entry}" '. == $entry' "${work}/launchd.json"
test "$(<"${LAUNCHCTL_ARGS}")" = "$(printf '%s\n' enable "gui/${uid}/com.example.Removed")"
printf '%s\n' success >"${LAUNCHCTL_RESULT}"
bash "${reconcile}" "${work}/launchd.json" "${work}/manifest.json" "${user}" "${work}/bin/as-user" /usr/bin/true /usr/libexec/PlistBuddy
jq -e '. == []' "${work}/launchd.json"

mkdir -p "${work}/stable/nested" "${work}/unclaimed-runtime"
printf '%s\n' runtime >"${work}/stable/nested/t3"
jq -n --arg file "${work}/stable" '[{kind:"file",id:"stable",file:$file,recursive:true,restart:[]}]' >"${work}/manifest.json"
bash "${reconcile}" "${work}/runtime.json" "${work}/manifest.json" "${user}" "${work}/bin/as-user" /usr/bin/true /usr/libexec/PlistBuddy
test -f "${work}/stable/nested/t3"
printf '%s\n' '[]' >"${work}/manifest.json"
bash "${reconcile}" "${work}/runtime.json" "${work}/manifest.json" "${user}" "${work}/bin/as-user" /usr/bin/true /usr/libexec/PlistBuddy
test ! -e "${work}/stable"
test -d "${work}/unclaimed-runtime"
jq -e '. == []' "${work}/runtime.json"

printf '%s\n' /opt/homebrew/bin/fish >"${DSCL_SHELL}"
printf '%s\n' "${shell_entry}" >"${work}/shell.json"
bash "${reconcile}" "${work}/shell.json" "${work}/manifest.json" "${user}" "${work}/bin/as-user" /usr/bin/true /usr/libexec/PlistBuddy
test "$(<"${DSCL_SHELL}")" = /opt/homebrew/bin/fish
jq -e '. == []' "${work}/shell.json"
