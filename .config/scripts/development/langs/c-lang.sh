#!/bin/sh

# c-lang.sh --- C environment setup

# Commentary:

# Installs C compiler & other tools.

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
# compiler
${PKG_INSTALL:?} 'gcc'

# language server
${PKG_INSTALL:?} 'clang'

# ctags
${PKG_INSTALL:?} 'ctags'

# formatter
${PKG_INSTALL:?} 'uncrustify'
;;

void)
# check if running with elevated priviledges; elevate if not
! is_su && elevate_privs "$0" "$@"

# compiler
${PKG_INSTALL:?} 'gcc'

# language server
${PKG_INSTALL:?} 'clang'

# ctags
${PKG_INSTALL:?} 'ctags'

# formatter
${PKG_INSTALL:?} 'uncrustify'
;;

debian)
# check if running with elevated priviledges; elevate if not
! is_su && elevate_privs "$0" "$@"

# language server
${PKG_INSTALL:?} 'clangd'

# formatter
${PKG_INSTALL:?} 'uncrustify'
;;

*) die 'no setup found for this environment.'
esac
