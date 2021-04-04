#!/bin/sh

# doom-emacs-setup.sh --- Doom Emacs setup

# Commentary:

# Installs Doom Emacs environment

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

case ${SYSTEM:?} in
arch)
${PKG_INSTALL:?} 'emacs'

# dependencies
${PKG_INSTALL:?} 'emacs' 'git' 'fd' 'ripgrep'

;;

void) ;;

debian) ;;

*) die 'no setup found for this environment.'
esac

# Doom Emacs installation
emacs_dir="${HOME}/.config/emacs"

if test ! -d "${emacs_dir}"; then 
    git clone 'https://github.com/hlissner/doom-emacs' "${emacs_dir}";
    "${emacs_dir}"/bin/doom install
    "${emacs_dir}"/bin/doom doctor
else
    die 'an Emacs configuration was already found...'
fi
