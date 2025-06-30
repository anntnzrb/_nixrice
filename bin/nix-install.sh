#!/bin/sh

# This POSIX shell script installs Nix using Determinate's installer.
#
# This installation process is automated and executes without manual
# intervention. Administrative privileges are necessary for proper installation.
# The invoking user is added to the "trusted users" group, which is required for
# capabilities such as configuration of additional package sources and
# utilization of binary caches.
#
# Usage:
#   ./nix-install.sh

# log to stderr and exit failure
die() {
    printf "Error: %s\n" "$1" >&2
    exit 1
}

# early check if Nix is already installed
nix_check_dir="/nix/store"
[ -d "${nix_check_dir}" ] \
    && die "Nix seems to be already installed at ${nix_check_dir}."

# exit if curl is not installed
! command -v curl >/dev/null 2>&1 && die "curl is required but not installed."

# install Nix using Determinate's installer
current_user=$(id -un)
curl --proto '=https' \
    --tlsv1.2 \
    -sSf \
    -L "https://install.determinate.systems/nix" \
    | sh -s -- install \
        --no-confirm \
        --extra-conf "trusted-users = ${current_user}"

printf "Installation complete.\n"
