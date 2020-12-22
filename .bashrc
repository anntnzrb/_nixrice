#!/bin/sh

# shellcheck disable=1090
# follow non-constant sources

#  ██                        ██
# ░██                       ░██
# ░██       ██████    ██████░██      ██████  █████
# ░██████  ░░░░░░██  ██░░░░ ░██████ ░░██░░█ ██░░░██
# ░██░░░██  ███████ ░░█████ ░██░░░██ ░██ ░ ░██  ░░
# ░██  ░██ ██░░░░██  ░░░░░██░██  ░██ ░██   ░██   ██
# ░██████ ░░████████ ██████ ░██  ░██░███   ░░█████
# ░░░░░    ░░░░░░░░ ░░░░░░  ░░   ░░ ░░░     ░░░░░

# -----------------------------------------------------------------------------
# prompt
# -----------------------------------------------------------------------------

# git prompt
export GIT_PS1_SHOWDIRTYSTATE=1
export GIT_PS1_SHOWSTASHSTATE=1
export GIT_PS1_SHOWUNTRACKEDFILES=1
export GIT_PS1_SHOWUPSTREAM='auto'
export GIT_PS1_SHOWCOLORHINTS=1

# -----------------------------------------------------------------------------
# miscellaneous
# -----------------------------------------------------------------------------
# uncrustify config (for some reason this needs to be sourced every time)
export UNCRUSTIFY_CONFIG="${HOME}/.config/uncrustify/uncrustify.cfg"

# source functions, aliases, etc
for cfg in "${HOME}"/.config/sh/lib/*; do
    . "${cfg}"
done

# enable bash completion
BASH_COMPLETION_PATH='/usr/share/bash-completion/bash_completion'
test -f "${BASH_COMPLETION_PATH}" && . "${BASH_COMPLETION_PATH}"
