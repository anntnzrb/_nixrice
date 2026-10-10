# shellcheck shell=sh

state=${1}
manifest=${2}
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
: >"${work}/carried"

if [ -f "${state}" ]; then
    jq -c --slurpfile new "${manifest}" \
        '($new[0] | map(.port)) as $ports | .[] | select(.port as $port | $ports | index($port) | not)' \
        "${state}" >"${work}/stale"
    while IFS= read -r entry; do
        printf '%s\n' "${entry}" | jq -r '.stop[]' >"${work}/command"
        set --
        while IFS= read -r arg; do
            set -- "$@" "${arg}"
        done <"${work}/command"
        port=$(printf '%s\n' "${entry}" | jq -r '.port')
        echo >&2 "tailscale: removing owned listener ${port}"
        if ! "$@"; then
            echo >&2 "tailscale: keeping listener ownership to retry on the next switch"
            printf '%s\n' "${entry}" >>"${work}/carried"
        fi
    done <"${work}/stale"
fi

mkdir -p "$(dirname "${state}")"
jq -s '.[0] + .[1:] | unique_by(.port)' "${manifest}" "${work}/carried" >"${state}.tmp"
chmod 0644 "${state}.tmp"
mv "${state}.tmp" "${state}"
