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
}

parse_pkgs() {
    pacman_pkgs_file=$(mktemp)
    aur_pkgs_file=$(mktemp)

    tmp_prog_file=$(mktemp)
    # trim comments and empty lines
    sed '/^#/d ; /^$/d' < "${pkgs_file}" > "${tmp_prog_file}"

    while IFS=',' read -r pkgs_type pkgs_name
    do
        case "${pkgs_type}" in
            P) printf "%s\n" "${pkgs_name}" >> "${pacman_pkgs_file}" ;;
            A) printf "%s\n" "${pkgs_name}" >> "${aur_pkgs_file}" ;;
            *) printf "Unknown pkgs type for pkgs: %s. Skipping...\n" "${pkgs_name}" ;;
        esac
    done < "${tmp_prog_file}"

    install_pkgs "${pacman_pkgs_file}" "${aur_pkgs_file}"
    rm -f "${tmp_prog_file}" "${pacman_pkgs_file}" "${aur_pkgs_file}"
}

install_pkgs() {
    pacman_pkgs_file="${1}"
    aur_pkgs_file="${2}"
    common_flags="-S --noconfirm --needed"

    test -s "${pacman_pkgs_file}" && sudo pacman ${common_flags} - < "${pacman_pkgs_file}"
    test -s "${aur_pkgs_file}" && "${aur_helper}" ${common_flags} - < "${aur_pkgs_file}"
}

# *****************************************************************************

check_requirements
parse_pkgs

exit 0
