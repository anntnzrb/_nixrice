#!/bin/sh

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

# PS1
export PROMPT_COMMAND='__git_ps1 "\e[36m\]║\e[m\] \e[1;33m\]\w\[\e[m\] \e[36m\]║ ━\e[m\]" "\e[94m\] $ \e[m\]"'

# random quote on launch
fortune -s | cowsay -f tux

# git prompt
export GIT_PS1_SHOWDIRTYSTATE=1
export GIT_PS1_SHOWSTASHSTATE=1
export GIT_PS1_SHOWUNTRACKEDFILES=1
export GIT_PS1_SHOWUPSTREAM="auto"
export GIT_PS1_SHOWCOLORHINTS=1

# -----------------------------------------------------------------------------
# miscellaneous
# -----------------------------------------------------------------------------
# uncrustify config (for some reason this needs to be sourced every time)
export UNCRUSTIFY_CONFIG="$HOME/.config/uncrustify/uncrustify.cfg"

# source functions, aliases, etc
for f in "$HOME"/.config/sh/*; do
    . "$f"
done

# enable bash completion
BASH_COMPLETION_PATH=/usr/share/bash-completion/bash_completion
[ -f "$BASH_COMPLETION_PATH" ] && . "$BASH_COMPLETION_PATH"
