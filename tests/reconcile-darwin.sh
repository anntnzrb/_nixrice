# shellcheck shell=bash

set -euo pipefail

reconcile=${1}
work=$(mktemp -d)
trap 'rm -rf "${work}"' EXIT
user=$(id -un)
mkdir "${work}/bin"
printf '%s\n' '#!/bin/sh' 'exit 0' >"${work}/bin/launchctl"
chmod +x "${work}/bin/launchctl"
export PATH="${work}/bin:${PATH}"
domain="${work}/preferences"

defaults write "${domain}" owned -int 7
defaults write "${domain}" unrelated -string keep
defaults write "${domain}" dictionary -dict owned remove unrelated preserve
jq -n --arg domain "${domain}" '[
    {kind:"defaults",id:"key",domain:$domain,key:"owned",scope:"system",currentHost:false,path:[],restart:[]},
    {kind:"defaults",id:"nested",domain:$domain,key:"dictionary",scope:"system",currentHost:false,path:["owned"],restart:[]}
]' >"${work}/manifest.json"

bash "${reconcile}" "${work}/state.json" "${work}/manifest.json" "${user}"
value=$(defaults read "${domain}" owned)
test "${value}" = 7
printf '%s\n' '[]' >"${work}/manifest.json"
bash "${reconcile}" "${work}/state.json" "${work}/manifest.json" "${user}"
if defaults read "${domain}" owned; then
    exit 1
fi
value=$(defaults read "${domain}" unrelated)
test "${value}" = keep
defaults export "${domain}" - >"${work}/remaining.plist"
value=$(/usr/libexec/PlistBuddy -c 'Print :dictionary:unrelated' "${work}/remaining.plist")
test "${value}" = preserve
if /usr/libexec/PlistBuddy -c 'Print :dictionary:owned' "${work}/remaining.plist"; then
    exit 1
fi
jq -e '. == []' "${work}/state.json"
bash "${reconcile}" "${work}/state.json" "${work}/manifest.json" "${user}"
jq -e '. == []' "${work}/state.json"
