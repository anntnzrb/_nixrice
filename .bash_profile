#!/usr/bin/env bash

# shellcheck disable=1090
# follow non-constant sources

[ -f "${HOME}/.bashrc" ] && . "${HOME}/.bashrc"
[ -f "${HOME}/.profile" ] && . "${HOME}/.profile"
