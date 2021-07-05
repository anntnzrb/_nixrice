#!/bin/sh

# font-utils.sh --- Utility file for font setup

# *****************************************************************************
# Variables (constants)
# *****************************************************************************

export fonts_dir="${HOME}/.local/share/fonts"

# *****************************************************************************
# Functions
# *****************************************************************************

update_fonts() {
    # **
    # * Build & update font information cache files.
    # *

    fc-cache -frv
}

check_font_dir() {
    # **
    # * Checks if the fonts folder is present
    # *

    test -d "${fonts_dir}"
}

install_font() {
    # shellcheck disable=2086
    # quoting $1 breaks the wildcard expansion for some reason
    cp -Rfv $1 "${fonts_dir}"
}

fgclone() {
    # **
    # * "Fast Git Clone"
    # * This is just a simple wrapper around `git clone` with a few extra flags;
    # * mainly for speed.
    # *

    # shellcheck disable=SC2046
    # numeric value, not string
    git clone --depth 1 -j $(nproc) "$1" "$2"
}

die() {
    # **
    # Prints a message to stderr & exits script with non-successful code 1
    # *

    printf '%s\n' "$@" >&2
    exit 1
}

# *****************************************************************************
# Main
# *****************************************************************************

# check if fonts folder exists and create if false
! check_font_dir && mkdir -pv "${fonts_dir}"
