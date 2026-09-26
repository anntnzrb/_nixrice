#!/bin/sh

# Installs Nix with Determinate's installer, unattended; needs sudo. The
# invoking user becomes a trusted user, which is required to configure extra
# substituters (binary caches) and similar settings. Further arguments go to
# `nix-installer install`, e.g. --extra-conf "extra-substituters = <url>".
#
# Usage:
#   ./nix-install.sh [installer-args...]
set -eu

# log to stderr and exit failure
die() {
    printf 'Error: %s\n' "$1" >&2
    exit 1
}

if [ -d /nix/store ]; then
    die "Nix seems to be already installed at /nix/store."
fi
command -v curl >/dev/null 2>&1 || die "curl is required but not installed."

# Download first, then run: piped into sh, a failed or cut-off download would
# run a partial script, and dash has no pipefail to notice. The temporary copy
# is removed on exit, error, Ctrl+C, kill or hangup (dash skips the EXIT trap
# on a signal, so those are trapped too and re-raised so callers stop as well).
user=$(id -un)
installer=$(mktemp)
cleanup() {
    rm -f "${installer}"
}
trap cleanup EXIT
for sig in HUP INT TERM; do
    # shellcheck disable=SC2064 # the signal name is fixed per handler
    trap "trap '' HUP INT TERM; cleanup; trap - EXIT ${sig}; kill -s ${sig} \$\$" "${sig}"
done

curl --proto '=https' --tlsv1.2 -sSfL -o "${installer}" \
    https://install.determinate.systems/nix
sh "${installer}" install --no-confirm \
    --extra-conf "trusted-users = ${user}" "$@"

printf 'Installation complete.\n'
