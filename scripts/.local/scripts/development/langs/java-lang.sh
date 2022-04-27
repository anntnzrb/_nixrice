#!/bin/sh

# java-lang.sh --- Java environment setup

# Commentary:

# This installation depends on SDKman, should be installef first.

# References: https://sdkman.io/

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

case $SYSTEM in
arch)
# formatter
$PKG_INSTALL 'uncrustify'

# elevate permissions
elevate_perms "$@"
;;

void)
# check if running with elevated priviledges; elevate if not
! is_su && elevate_privs "$0" "$@"

# formatter
$PKG_INSTALL 'uncrustify'
;;

*) die 'no setup for this environment.'
esac

# Java installation
if test -d "${HOME}/.sdkman/"; then
    sdk install java 11.0.10.j9-adpt
else
    die 'SDKman cannot be found, could not install.'
fi
