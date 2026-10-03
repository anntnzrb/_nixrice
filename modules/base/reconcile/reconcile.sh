# shellcheck shell=sh

set -eu

state=${1}
manifest=${2}
user=${3}

uid=$(id -u -- "${user}")
work=$(mktemp -d)
trap 'rm -rf "${work}"' EXIT
: >"${work}/carried"
: >"${work}/restart"
refresh=0

# Prefixes for one entry: who runs `defaults`, and whether it targets ByHost.
set_runner() {
    runner=""
    if [ "${scope}" = user ]; then
        runner="launchctl asuser ${uid} sudo --user=${user} --"
    fi
    host=""
    if [ "${current_host}" = true ]; then
        host="-currentHost"
    fi
}

carry() {
    printf '%s\n' "${entry}" >>"${work}/carried"
}

removed() {
    printf '%s\n' "${entry}" | jq -r '.restart[]' >>"${work}/restart"
}

remove_file() {
    if [ ! -e "${file}" ] && [ ! -L "${file}" ]; then
        return 0
    fi
    echo "reconcile: removing ${file}" >&2
    if rm -f -- "${file}"; then
        removed
    else
        carry
    fi
}

remove_privacy() {
    if ! launchctl asuser "${uid}" sudo --user="${user}" -- \
        tccutil reset "${service}" "${bundle_id}" >"${work}/tcc.log" 2>&1; then
        echo "reconcile: could not revoke ${service} for ${bundle_id}" >&2
        carry
        return 0
    fi
    echo "reconcile: revoked ${service} for ${bundle_id}" >&2
}

remove_default() {
    set_runner
    # shellcheck disable=SC2086,SC2248 # runner and host are word lists by design
    {
        # An unreadable domain (missing, or behind TCC) cannot be checked: keep owning it.
        if ! ${runner} defaults ${host} read "${domain}" >/dev/null 2>&1; then
            carry
            return 0
        fi

        if [ -z "${nested}" ]; then
            if ! ${runner} defaults ${host} read "${domain}" "${key}" >/dev/null 2>&1; then
                return 0
            fi
            echo "reconcile: removing ${domain} ${key}" >&2
            if ! ${runner} defaults ${host} delete "${domain}" "${key}"; then
                carry
                return 0
            fi
        else
            if ! ${runner} defaults ${host} export "${domain}" - >"${work}/domain.plist"; then
                carry
                return 0
            fi
            if ! /usr/libexec/PlistBuddy -c "Print :${key}${nested}" "${work}/domain.plist" >/dev/null 2>&1; then
                return 0
            fi
            echo "reconcile: removing ${domain} ${key}${nested}" >&2
            if ! /usr/libexec/PlistBuddy -c "Delete :${key}${nested}" "${work}/domain.plist" \
                || ! ${runner} defaults ${host} import "${domain}" - <"${work}/domain.plist"; then
                carry
                return 0
            fi
        fi
    }
    refresh=1
    removed
}

if [ -f "${state}" ]; then
    jq -c --slurpfile new "${manifest}" \
        '($new[0] | map(.id)) as $ids | .[] | select(.id as $id | $ids | index($id) | not)' \
        "${state}" >"${work}/stale"
    while IFS= read -r entry; do
        printf '%s\n' "${entry}" | jq -r \
            '.kind, (.file // ""), (.scope // ""), (.currentHost // false), (.domain // ""), (.key // ""), (.service // ""), (.bundleId // ""), ((.path // []) | map(":" + .) | join(""))' \
            >"${work}/fields"
        {
            read -r kind
            read -r file
            read -r scope
            read -r current_host
            read -r domain
            read -r key
            read -r service
            read -r bundle_id
            read -r nested || nested=""
        } <"${work}/fields"
        case ${kind} in
            file) remove_file ;;
            defaults) remove_default ;;
            privacy) remove_privacy ;;
            *) echo "reconcile: unknown kind ${kind}, keeping it" >&2 && carry ;;
        esac
    done <"${work}/stale"
fi

if [ "${refresh}" = 1 ]; then
    launchctl asuser "${uid}" sudo --user="${user}" -- \
        /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u || true
fi
sort -u "${work}/restart" >"${work}/restart.sorted"
while IFS= read -r name; do
    killall -q "${name}" || true
done <"${work}/restart.sorted"

mkdir -p "$(dirname "${state}")"
jq -s '.[0] + .[1:] | unique_by(.id)' "${manifest}" "${work}/carried" >"${state}.tmp"
chmod 0644 "${state}.tmp"
mv "${state}.tmp" "${state}"
