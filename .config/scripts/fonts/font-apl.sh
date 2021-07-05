#!/bin/sh

# font-apl.sh --- APL font

# shellcheck disable=SC1091
# follow sourced files

. ./font-utils.sh

# *****************************************************************************
# Variables (constants)
# *****************************************************************************

font_link='https://github.com/abrudz/APL386'
font_path="/tmp/font-${font_link##*/}"

# *****************************************************************************
# Main
# *****************************************************************************

# get font
fgclone "${font_link}" "${font_path}"

# copy (install) it
install_font "${font_path}/*.ttf" || die "Error installing fonts..."

# update fonts
update_fonts
