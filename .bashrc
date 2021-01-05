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

set -o posix # POSIX mode
# attempt correcting directory names
shopt -s dirspell
shopt -s cdspell
shopt -s histappend # append history to set file

# -----------------------------------------------------------------------------
# settings
# -----------------------------------------------------------------------------

# history
export HISTCONTROL='erasedups'        # keep duplicates off
export HISTFILESIZE=10000
export HISTFILE="${BASHDIR}/.bash_history"
export HISTIGNORE='cd:ls:ll:exit:pwd' # commands to be ignored in history

# -----------------------------------------------------------------------------
# prompt
# -----------------------------------------------------------------------------

# prompt + git
PS1='\e[37m[\e[31m\u :: \h\e[37m] -> \e[36m\w\e[34m $(__git_ps1 "(%s)\e[33m <~ git")\e[0m\n\e[32m$\e[0m '

export GIT_PS1_SHOWDIRTYSTATE=1
export GIT_PS1_SHOWSTASHSTATE=1
export GIT_PS1_SHOWUNTRACKEDFILES=1
export GIT_PS1_SHOWUPSTREAM='verbose name'
export GIT_PS1_SHOWCOLORHINTS=1

# -----------------------------------------------------------------------------
# miscellaneous
# -----------------------------------------------------------------------------
# uncrustify config (for some reason this needs to be sourced every time)
export UNCRUSTIFY_CONFIG="${HOME}/.config/uncrustify/uncrustify.cfg"

# source functions, aliases, etc
for cfg in "${HOME}"/.config/sh/lib/*; do . "${cfg}"; done

# enable bash completion
bash_compl_path='/usr/share/bash-completion/bash_completion'
test -f "${bash_compl_path}" && . "${bash_compl_path}"

# git prompt
git_prompt_path="${BASHDIR}/lib/prompt/git-prompt"
test -f "${git_prompt_path}" && . "${git_prompt_path}"
