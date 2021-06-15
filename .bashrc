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

setup_posix() {
    # **
    # sets up POSIX mode for Bash if available.
    # *

    if test ${IN_NIX_SHELL}; then
        printf "nix-shell does not support the 'POSIX' option, disabling...\n"
    else
        set -o posix
    fi
}

setup_posix
# update the values of LINES and COLUMNS
test "${DISPLAY}" && shopt -s checkwinsize
shopt -s globstar      # allow ** to match recursively
shopt -s nocaseglob    # match globs case-insensitively
shopt -s histappend    # append to history
shopt -s cmdhist       # save multiline commands as one
# attempt correcting directory names
shopt -s dirspell
shopt -s cdspell

# cleanup
unset -f setup_posix

# -----------------------------------------------------------------------------
# settings
# -----------------------------------------------------------------------------

# history
export HISTCONTROL='erasedups'        # keep duplicates off
export HISTFILESIZE=10000
export HISTIGNORE='cd:ls:ll:exit:pwd' # commands to be ignored in history

ps1_user="\[\033[38;5;1m\]\u\[$(tput sgr0)\]"
ps1_hostname="\[\033[38;5;69m\]\H\[$(tput sgr0)\]"
ps1_at="\[$(tput bold)\]\[\033[38;5;244m\]@\[$(tput sgr0)\]"
ps1_arrow="\[$(tput bold)\]\[\033[38;5;244m\]->\[$(tput sgr0)\]"
ps1_dir="\[\033[38;5;3m\]\w\[$(tput sgr0)\]"
ps1_qstn="\[$(tput bold)\]\[\033[38;5;244m\]?\[$(tput sgr0)\]"
ps1_exit_code="\[$(tput bold)\]\[\033[38;5;160m\]\$?\[$(tput sgr0)\]"
ps1_colons="\[$(tput bold)\]\[\033[38;5;244m\]::\[$(tput sgr0)\]"

# prompt + git
PS1="${ps1_user}${ps1_at}${ps1_hostname} ${ps1_arrow} ${ps1_dir}\n${ps1_arrow} ${ps1_qstn} ${ps1_exit_code} ${ps1_colons} "

# cleanup
unset -v ps1_user ps1_hostname ps1_at ps1_arrow ps1_dir ps1_qstn ps1_exit_code ps1_colons

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
