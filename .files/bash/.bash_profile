#!/bin/sh

# shellcheck disable=1090
# follow non-constant sources

test -f "${HOME}/.profile" && . "${HOME}/.profile"
test -f "${HOME}/.bashrc" && . "${HOME}/.bashrc"
