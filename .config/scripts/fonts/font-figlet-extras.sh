#!/bin/sh

# font-figlet-extras.sh --- Extra fonts for figlet (and toilet)

# shellcheck disable=SC1091
# follow sourced files

. ./font-utils.sh

# *****************************************************************************
# Variables (constants)
# *****************************************************************************

font_link='https://github.com/xero/figlet-fonts'
font_path="/tmp/font-${font_link##*/}"

# *****************************************************************************
# Main
# *****************************************************************************

# get font
fgclone "${font_link}" "${font_path}"

# copy (install) it
install_font "${font_path}/*" || die "Error installing fonts..."

# update fonts
update_fonts
