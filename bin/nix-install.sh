#!/bin/sh

set -eu

die() {
    printf 'Error: %s\n' "$1" >&2
    exit 1
}

if [ -d /nix/store ]; then
    die "Nix seems to be already installed at /nix/store."
fi
command -v curl >/dev/null 2>&1 || die "curl is required but not installed."

user=$(id -un)
installer=$(mktemp)
cleanup() {
    rm -f "${installer}"
}
trap cleanup EXIT
for sig in HUP INT TERM; do
    # shellcheck disable=SC2064
    trap "trap '' HUP INT TERM; cleanup; trap - EXIT ${sig}; kill -s ${sig} \$\$" "${sig}"
done

curl --proto '=https' --tlsv1.2 -sSfL -o "${installer}" \
    https://install.determinate.systems/nix
sh "${installer}" install --no-confirm \
    --extra-conf "trusted-users = ${user}" "$@"

printf 'Installation complete.\n'
