#!/bin/sh

# xbps-pkgs-setup.sh --- Void Linux XBPS Source Packages Collection Setup

# Commentary:

# Downloads & installs the Void Linux XBPS Source Packages Collection.

# References: https://github.com/void-linux/void-packages

# Code:

# -----------------------------------------------------------------------------
# preamble
# -----------------------------------------------------------------------------

# source utilities
# shellcheck disable=SC1090
. "${LIBSHUTILS:?}/sys-utils"

# -----------------------------------------------------------------------------
# main
# -----------------------------------------------------------------------------

# exit if not using void linux
test ! -x "`command -v 'xbps-pkgdb'`" && die 'Not running Void Linux.'

void_pkgs_path="${HOME}/.local/void-packages/"
current_dir="`pwd`"

# download void packages repo if not downloaded already
if test ! -d "${void_pkgs_path}"; then
    git clone 'git://github.com/void-linux/void-packages.git' "${void_pkgs_path}"

    cd "${void_pkgs_path}" || die "Could not 'cd' into directory."

    # build packages marked as 'restricted'
    command /bin/echo XBPS_ALLOW_RESTRICTED=yes >> ./etc/conf

    ./xbps-src binary-bootstrap

    # return to previously working directory
    cd "${current_dir}" || die "Could not 'cd' into directory."
else
    cd "${void_pkgs_path}" || die "Could not 'cd' into directory."

    # update repo
    git pull --force

    # return to previously working directory
    cd "${current_dir}" || die "Could not 'cd' into directory."
fi
