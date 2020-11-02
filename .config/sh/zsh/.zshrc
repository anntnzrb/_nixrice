#!/usr/bin/env zsh

#                 ██
#                ░██
#  ██████  ██████░██      ██████  █████
# ░░░░██  ██░░░░ ░██████ ░░██░░█ ██░░░██
#    ██  ░░█████ ░██░░░██ ░██ ░ ░██  ░░
#   ██    ░░░░░██░██  ░██ ░██   ░██   ██
#  ██████ ██████ ░██  ░██░███   ░░█████
# ░░░░░░ ░░░░░░  ░░   ░░ ░░░     ░░░░░
# useful stuff should be @ ../zsh/lib/

# -----------------------------------------------------------------------------
# general
# -----------------------------------------------------------------------------

autoload -Uz colors && colors

# tab completion
autoload -U compinit
zstyle ':completion:*' menu select
zmodload zsh/complist
compinit

# show hidden files
_comp_options+=(globdots)

# auto complete case insensitive
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# history
HISTSIZE=3000
SAVEHIST=1000
HISTFILE=$ZDOTDIR/.zsh_history
setopt APPEND_HISTORY
setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt SHARE_HISTORY

# == misc
# disable keybind to freeze terminal
stty stop undef

# -----------------------------------------------------------------------------
# keybinds
# -----------------------------------------------------------------------------

# vi-mode
bindkey -v
export KEYTIMEOUT=1

# vim-like edit '^e'
autoload edit-command-line; zle -N edit-command-line
bindkey '^e' edit-command-line

# change cursor shape for different vi modes
function zle-keymap-select() {
    if [[ ${KEYMAP} == vicmd ]] ||
        [[ $1 = 'block' ]]; then
        echo -ne '\e[1 q'
    elif [[ ${KEYMAP} == main ]] ||
        [[ ${KEYMAP} == viins ]] ||
        [[ ${KEYMAP} = '' ]] ||
        [[ $1 = 'beam' ]]; then
        echo -ne '\e[5 q'
    fi
} && zle -N zle-keymap-select

zle-line-init() {
    zle -K viins
    echo -ne "\e[5 q"
} && zle -N zle-line-init

typeset -g -A key

# declarations
key[Home]="${terminfo[khome]}"
key[End]="${terminfo[kend]}"
key[Delete]="${terminfo[kdch1]}"
key[Control-Left]="${terminfo[kLFT5]}"
key[Control-Right]="${terminfo[kRIT5]}"
key[Shift-Tab]="${terminfo[kcbt]}"

# actual binding
[[ -n "${key[Home]}"          ]] && bindkey -- "${key[Home]}"          beginning-of-line
[[ -n "${key[End]}"           ]] && bindkey -- "${key[End]}"           end-of-line
[[ -n "${key[Delete]}"        ]] && bindkey -- "${key[Delete]}"        delete-char
[[ -n "${key[Control-Left]}"  ]] && bindkey -- "${key[Control-Left]}"  backward-word
[[ -n "${key[Control-Right]}" ]] && bindkey -- "${key[Control-Right]}" forward-word
[[ -n "${key[Shift-Tab]}"     ]] && bindkey -- "${key[Shift-Tab]}"     reverse-menu-complete

# force terminal in application mode
if (( ${+terminfo[smkx]} && ${+terminfo[rmkx]} )); then
    autoload -Uz add-zle-hook-widget
    function zle_application_mode_start { echoti smkx }
    function zle_application_mode_stop { echoti rmkx }
    add-zle-hook-widget -Uz zle-line-init zle_application_mode_start
    add-zle-hook-widget -Uz zle-line-finish zle_application_mode_stop
fi

# -----------------------------------------------------------------------------
# miscellaneous
# -----------------------------------------------------------------------------

# source aliases, functions, etc
for f in "$HOME"/.config/sh/lib/*; do
    . "$f"
done

# uncrustify config (for some reason this needs to be sourced every time)
export UNCRUSTIFY_CONFIG="$HOME/.config/uncrustify/uncrustify.cfg"

# source settings/extensions (should be at last)
# checks if iteration is not a directory first
for cfg in "$ZDOTDIR"/lib/* "$ZDOTDIR"/lib/extensions/*; do
    [ ! -d "$cfg" ] && . "$cfg"
done

# -----------------------------------------------------------------------------
# references
# -----------------------------------------------------------------------------

# https://0x0.st/oCRf
