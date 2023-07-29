#!/bin/sh

# *****************************************************************************
# Modify these variables as per requirements.
#
# aur_helper: Preferred AUR helper. Example: paru, yay etc.
# pkgs_file : The csv file containing the list of pacman and AUR packages.
#             The csv file should be of format : <P or A>,<package_name>
#             Example:
#             # pacman packages
#             P,zsh
#             P,git
#             # aur packages
#             A,spotify
# *****************************************************************************

aur_helper='paru'
pkgs_file='pkgs.csv'

# *****************************************************************************

check_requirements() {
    test ! -x "$(command -v 'pacman')" && {
        printf 'Error: This script requires pacman but it is not installed. Exiting...\n' >&2
        exit 1
    }

    test ! -x "$(command -v ${aur_helper})" && {
        printf 'Error: This script requires %s but it is not installed. Exiting...\n' "${aur_helper}" >&2
        exit 1
    }
}

parse_pkgs() {
    aur_pkgs_file=$(mktemp)

    tmp_prog_file=$(mktemp)
    # trim comments and empty lines
    sed '/^#/d ; /^$/d' < "${pkgs_file}" > "${tmp_prog_file}"

    install_pkgs "${tmp_prog_file}"
    rm -f "${tmp_prog_file}" "${aur_pkgs_file}"
}

install_pkgs() {
    aur_pkgs_file="${1}"
    flags="--noconfirm --needed -Syyu"

    test -s "${aur_pkgs_file}" && "${aur_helper}" ${flags} - < "${aur_pkgs_file}"
}

# *****************************************************************************

check_requirements
parse_pkgs

exit 0
