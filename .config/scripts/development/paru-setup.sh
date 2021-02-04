#!/bin/sh

# paru-setup.sh --- Paru AUR helper setup

# Commentary:

# Paru is an AUR helper and pacman wrapper, an alternative to 'yay'

# References: https://github.com/Morganamilo/paru

# Code:

# -----------------------------------------------------------------------------
# functions
# -----------------------------------------------------------------------------

is_installed() {
    # **
    # Checks if command "$1" is installed
    #
    # verifies if the file is an executable file, this is used to prevent
    # conflicts with user-defined aliases and functions
    # *

    test -x "`command -v "$1"`"
}

die() {
    # **
    # Prints a message to stderr & exits script with non-successful code "1"
    # *

    printf '%s\n' "$@" >&2 ; exit 1
}

# -----------------------------------------------------------------------------
# preamble
# -----------------------------------------------------------------------------

# Quit if not running an Arch-based distro
! is_installed 'pacman' && die 'Not running an Arch-based distribution'

# -----------------------------------------------------------------------------
# main
# -----------------------------------------------------------------------------

# Only download & install if 'paru' is not installed already
if ! is_installed 'paru'; then
    dest='/tmp/paru/'
    current_dir=`pwd`

    git clone 'https://aur.archlinux.org/paru.git' "${dest}"
    cd "${dest}" || die 'Could not cd, exiting...'
    makepkg --needed --noconfirm -Ccirs
    cd "${current_dir}" || die 'Could not cd, exiting...'

    # Cleanup
    rm -Rf "${dest}"
    unset -v dest

else
    die "'paru' is already installed..."
fi
