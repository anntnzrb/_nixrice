#!/bin/sh

# sdkman-setup.sh --- SDKman setup

# Commentary:

# This installation script is Distro-agnostic, does not depend on the package
# manager.

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

# SDKman installation
if test ! -d "${HOME}/.sdkman/"; then
    curl -s 'https://get.sdkman.io' | bash
else
    die "'~/.sdkman/' folder is already present, SDKman is probably installed already."
fi
