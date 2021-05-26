#!/usr/bin/env bash

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
# preamble
# -----------------------------------------------------------------------------

# do nothing if not running interactively
[[ $- != *i* ]] && return

set -o posix
# update the values of LINES and COLUMNS
test "${DISPLAY}" && shopt -s checkwinsize
shopt -s globstar   # allow ** to match recursively
shopt -s nocaseglob # match globs case-insensitively
shopt -s histappend # append to history
shopt -s cmdhist       # save multiline commands as one
# attempt correcting directory names
shopt -s dirspell
shopt -s cdspell

# -----------------------------------------------------------------------------
# settings
# -----------------------------------------------------------------------------

# history
export HISTCONTROL='erasedups'        # keep duplicates off
export HISTFILESIZE=10000
export HISTIGNORE='cd:ls:ll:exit:pwd' # commands to be ignored in history

# prompt + git
PS1="\[\033[38;5;9m\]\u\[$(tput sgr0)\]\[\033[38;5;238m\]@\[$(tput sgr0)\]\[\033[38;5;244m\]\h\[$(tput sgr0)\] \[$(tput sgr0)\]\[\033[38;5;239m\]-\[$(tput sgr0)\]\[\033[38;5;238m\]>\[$(tput sgr0)\] \[$(tput sgr0)\]\[\033[38;5;6m\]\w\[$(tput sgr0)\] \[$(tput sgr0)\]\[\033[38;5;238m\]*\[$(tput sgr0)\]*\[$(tput sgr0)\]\[\033[38;5;238m\]*\[$(tput sgr0)\] \[$(tput sgr0)\]\[\033[38;5;4m\]\A\[$(tput sgr0)\] \[$(tput sgr0)\]\[\033[38;5;238m\]?\[$(tput sgr0)\] \[$(tput sgr0)\]\[\033[38;5;1m\]\$?\[$(tput sgr0)\] \[$(tput sgr0)\]\[\033[38;5;238m\]::\[$(tput sgr0)\] \[$(tput sgr0)\]\[\033[38;5;28m\]\\$ \[$(tput sgr0)\]"

# prompt, aliases, functions...
. "${SH_CFGS}/sh-prompt"
. "${SH_CFGS}/sh-aliases"
. "${SH_CFGS}/sh-functions"

# -----------------------------------------------------------------------------
# miscellaneous
# -----------------------------------------------------------------------------

# enable bash completion
bash_compl_path='/usr/share/bash-completion/bash_completion'
test -r "${bash_compl_path}" && . "${bash_compl_path}"
unset bash_compl_path
