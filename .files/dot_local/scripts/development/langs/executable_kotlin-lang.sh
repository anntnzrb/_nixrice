#!/bin/sh

# kotlin-lang.sh --- Kotlin environment setup

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

# Kotlin installation
if test -d "${HOME}/.sdkman/"; then
    sdk install kotlin 1.4.21
else
    die 'SDKman cannot be found, could not install.'
fi
