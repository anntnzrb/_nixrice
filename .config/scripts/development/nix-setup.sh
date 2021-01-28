#!/bin/sh

# nix-setup.sh --- Nix Package Manager setup

# Commentary:

# This installation script is Distro-agnostic, does not depend on the package
# manager.

# References: https://nixos.org/manual/nix/stable/

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

# Only download & install if '/nix' folder is absent.
if test ! -d '/nix'; then
    curl -L 'https://nixos.org/nix/install' | sh
else
    die "'/nix/' folder is already present, Nix is probably installed already."
fi
