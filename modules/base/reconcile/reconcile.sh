# shellcheck shell=sh

set -eu

state=${1}
manifest=${2}
user=${3}
as_user=${4}
activate_settings=${5}
plist_buddy=${6}

work=$(mktemp -d)
trap 'rm -rf "${work}"' EXIT
: >"${work}/carried"
: >"${work}/restart"
refresh=0

run_defaults() {
    if [ "${current_host}" = true ]; then
        set -- -currentHost "$@"
    fi
    if [ "${scope}" = user ]; then
        "${as_user}" defaults "$@"
    else
        defaults "$@"
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
    if ! "${as_user}" tccutil reset "${service}" "${bundle_id}" >"${work}/tcc.log" 2>&1; then
        echo "reconcile: could not revoke ${service} for ${bundle_id}" >&2
        carry
        return 0
    fi
    echo "reconcile: revoked ${service} for ${bundle_id}" >&2
}

remove_shell() {
    if ! current=$(dscl . -read "/Users/${user}" UserShell); then
        carry
        return 0
    fi
    if [ "${current#UserShell: }" != "${shell}" ]; then
        return 0
    fi
    echo "reconcile: resetting the login shell of ${user} to /bin/zsh" >&2
    if ! dscl . -create "/Users/${user}" UserShell /bin/zsh; then
        carry
    fi
}

remove_default() {
    # shellcheck disable=SC2310 # run_defaults returns the external command's status for retry handling.
    {
        # An unreadable domain (missing, or behind TCC) cannot be checked: keep owning it.
        if ! run_defaults read "${domain}" >/dev/null 2>&1; then
            carry
            return 0
        fi

        if [ -z "${nested}" ]; then
            if ! run_defaults read "${domain}" "${key}" >/dev/null 2>&1; then
                return 0
            fi
            echo "reconcile: removing ${domain} ${key}" >&2
            if ! run_defaults delete "${domain}" "${key}"; then
                carry
                return 0
            fi
        else
            if ! run_defaults export "${domain}" - >"${work}/domain.plist"; then
                carry
                return 0
            fi
            if ! "${plist_buddy}" -c "Print :${key}${nested}" "${work}/domain.plist" >/dev/null 2>&1; then
                return 0
            fi
            echo "reconcile: removing ${domain} ${key}${nested}" >&2
            if ! "${plist_buddy}" -c "Delete :${key}${nested}" "${work}/domain.plist" \
                || ! run_defaults import "${domain}" - <"${work}/domain.plist"; then
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
            '.kind, (.file // ""), (.scope // ""), (.currentHost // false), (.domain // ""), (.key // ""), (.service // ""), (.bundleId // ""), (.shell // ""), ((.path // []) | map(":" + .) | join(""))' \
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
            read -r shell
            read -r nested || nested=""
        } <"${work}/fields"
        case ${kind} in
            file) remove_file ;;
            defaults) remove_default ;;
            privacy) remove_privacy ;;
            shell) remove_shell ;;
            *) echo "reconcile: unknown kind ${kind}, keeping it" >&2 && carry ;;
        esac
    done <"${work}/stale"
fi

if [ "${refresh}" = 1 ]; then
    "${as_user}" "${activate_settings}" || true
fi
sort -u "${work}/restart" >"${work}/restart.sorted"
while IFS= read -r name; do
    killall -q "${name}" || true
done <"${work}/restart.sorted"

mkdir -p "$(dirname "${state}")"
jq -s '.[0] + .[1:] | unique_by(.id)' "${manifest}" "${work}/carried" >"${state}.tmp"
chmod 0644 "${state}.tmp"
mv "${state}.tmp" "${state}"
