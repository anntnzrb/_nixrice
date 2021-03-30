#!/bin/sh

# python-lang.sh --- Python environment setup

# Commentary:

# Installs Python & pip plus some other useful packages.

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
# tools
${PKG_INSTALL:?} 'python3' 'python-pip' 'npm'

# check if running with elevated priviledges; elevate if not
! is_su && elevate_privs "$0" "$@"

# LSP
npm install -g 'pyright'
;;

void)
# check if running with elevated priviledges; elevate if not
! is_su && elevate_privs "$0" "$@"

# tools
${PKG_INSTALL:?} 'python3' 'python3-pip'
;;

debian)
# check if running with elevated priviledges; elevate if not
! is_su && elevate_privs "$0" "$@"

# tools
${PKG_INSTALL:?} 'python3' 'python3-pip'
;;

*) die 'no setup found for this environment.'
esac

# == post-install
# dependencies
python3 -m pip install --user -U 'setuptools'
python3 -m pip install --user -U 'pip'

# code formatter (alternatively autopep8 & YAPF)
python3 -m pip install --user -U 'black'
