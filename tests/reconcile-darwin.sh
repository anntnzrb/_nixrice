# shellcheck shell=bash

set -euo pipefail

reconcile=${1}
work=$(mktemp -d)
trap 'rm -rf "${work}"' EXIT
user=$(id -un)
mkdir "${work}/bin"
# shellcheck disable=SC2016 # Expanded by the generated command, not the test.
printf '%s\n' '#!/bin/sh' 'printf "%s\n" "$*" >>"${AS_USER_LOG}"' 'exec "$@"' >"${work}/bin/as-user"
# shellcheck disable=SC2016 # Expanded by the generated command, not the test.
printf '%s\n' '#!/bin/sh' 'touch "${REFRESHED}"' >"${work}/bin/activate-settings"
chmod +x "${work}/bin/as-user" "${work}/bin/activate-settings"
export AS_USER_LOG="${work}/as-user.log"
export REFRESHED="${work}/refreshed"
plist_buddy=/usr/libexec/PlistBuddy
platform=$(uname -s)
if [[ "${platform}" != Darwin ]]; then
    plist_buddy="${work}/bin/PlistBuddy"
    cat >"${work}/bin/defaults" <<'DEFAULTS'
#!/bin/sh
set -eu
if [ "$1" = -currentHost ]; then shift; fi
command=$1
domain=$2
shift 2
case $command in
    write)
        key=$1
        kind=$2
        shift 2
        [ -f "$domain" ] || printf '%s\n' '{}' >"$domain"
        case $kind in
            -int) value=$1 ;;
            -string) value=$(jq -n --arg value "$1" '$value') ;;
            -dict)
                value=$(jq -n --arg key1 "$1" --arg value1 "$2" --arg key2 "$3" --arg value2 "$4" '{($key1):$value1,($key2):$value2}')
                ;;
            *) exit 1 ;;
        esac
        jq --arg key "$key" --argjson value "$value" '.[$key] = $value' "$domain" >"$domain.tmp"
        mv "$domain.tmp" "$domain"
        ;;
    read)
        [ -f "$domain" ] || exit 1
        if [ "$#" = 0 ]; then cat "$domain"; else jq -er --arg key "$1" '.[$key]' "$domain"; fi
        ;;
    delete)
        jq --arg key "$1" 'del(.[$key])' "$domain" >"$domain.tmp"
        mv "$domain.tmp" "$domain"
        ;;
    export) cat "$domain" ;;
    import) cat >"$domain" ;;
    *) exit 1 ;;
esac
DEFAULTS
    cat >"${plist_buddy}" <<'PLIST_BUDDY'
#!/bin/sh
set -eu
command=${2%% *}
path=${2#* :}
file=$3
case $command in
    Print) jq -er --arg path "$path" 'getpath($path | split(":"))' "$file" ;;
    Delete)
        jq --arg path "$path" 'delpaths([$path | split(":")])' "$file" >"$file.tmp"
        mv "$file.tmp" "$file"
        ;;
    *) exit 1 ;;
esac
PLIST_BUDDY
    chmod +x "${work}/bin/defaults" "${plist_buddy}"
fi
export PATH="${work}/bin:${PATH}"
domain="${work}/preferences"

defaults write "${domain}" owned -int 7
defaults write "${domain}" unrelated -string keep
defaults write "${domain}" dictionary -dict owned remove unrelated preserve
jq -n --arg domain "${domain}" '[
    {kind:"defaults",id:"key",domain:$domain,key:"owned",scope:"user",currentHost:false,path:[],restart:[]},
    {kind:"defaults",id:"nested",domain:$domain,key:"dictionary",scope:"system",currentHost:false,path:["owned"],restart:[]}
]' >"${work}/manifest.json"

bash "${reconcile}" "${work}/state.json" "${work}/manifest.json" "${user}" "${work}/bin/as-user" "${work}/bin/activate-settings" "${plist_buddy}"
value=$(defaults read "${domain}" owned)
test "${value}" = 7
printf '%s\n' '[]' >"${work}/manifest.json"
bash "${reconcile}" "${work}/state.json" "${work}/manifest.json" "${user}" "${work}/bin/as-user" "${work}/bin/activate-settings" "${plist_buddy}"
if defaults read "${domain}" owned; then
    exit 1
fi
test -f "${REFRESHED}"
grep -Fx "defaults read ${domain}" "${AS_USER_LOG}"
grep -Fx "${work}/bin/activate-settings" "${AS_USER_LOG}"
value=$(defaults read "${domain}" unrelated)
test "${value}" = keep
defaults export "${domain}" - >"${work}/remaining.plist"
value=$("${plist_buddy}" -c 'Print :dictionary:unrelated' "${work}/remaining.plist")
test "${value}" = preserve
if "${plist_buddy}" -c 'Print :dictionary:owned' "${work}/remaining.plist"; then
    exit 1
fi
jq -e '. == []' "${work}/state.json"
bash "${reconcile}" "${work}/state.json" "${work}/manifest.json" "${user}" "${work}/bin/as-user" "${work}/bin/activate-settings" "${plist_buddy}"
jq -e '. == []' "${work}/state.json"
