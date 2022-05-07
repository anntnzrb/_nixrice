#!/usr/bin/env zsh

#                 ██
#                ░██
#  ██████  ██████░██      ██████  █████
# ░░░░██  ██░░░░ ░██████ ░░██░░█ ██░░░██
#    ██  ░░█████ ░██░░░██ ░██ ░ ░██  ░░
#   ██    ░░░░░██░██  ░██ ░██   ░██   ██
#  ██████ ██████ ░██  ░██░███   ░░█████
# ░░░░░░ ░░░░░░  ░░   ░░ ░░░     ░░░░░

# -----------------------------------------------------------------------------
# general
# -----------------------------------------------------------------------------

setopt beep
setopt extendedglob
setopt nomatch

# colors & misc
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
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=${HOME}/.local/zsh_history
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
zle-keymap-select() {
    case $KEYMAP in
        vicmd) echo -ne '\e[1 q' ;;        # block
        viins | main) echo -ne '\e[5 q' ;; # beam
    esac
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
test -n "${key[Home]}"          && bindkey -- "${key[Home]}"          beginning-of-line
test -n "${key[End]}"           && bindkey -- "${key[End]}"           end-of-line
test -n "${key[Delete]}"        && bindkey -- "${key[Delete]}"        delete-char
test -n "${key[Control-Left]}"  && bindkey -- "${key[Control-Left]}"  backward-word
test -n "${key[Control-Right]}" && bindkey -- "${key[Control-Right]}" forward-word
test -n "${key[Shift-Tab]}"     && bindkey -- "${key[Shift-Tab]}"     reverse-menu-complete

# force terminal in application mode
if (( ${+terminfo[smkx]} && ${+terminfo[rmkx]} )); then
    autoload -Uz add-zle-hook-widget
    function zle_application_mode_start { echoti smkx }
    function zle_application_mode_stop { echoti rmkx }
    add-zle-hook-widget -Uz zle-line-init zle_application_mode_start
    add-zle-hook-widget -Uz zle-line-finish zle_application_mode_stop
fi


# -----------------------------------------------------------------------------
# prompt
# -----------------------------------------------------------------------------

PS1="%B%{$fg[red]%}[%{$fg[yellow]%}%n%{$fg[green]%}@%{$fg[blue]%}%M %{$fg[magenta]%}%~%{$fg[red]%}]%{$reset_color%}$%b "

# -----------------------------------------------------------------------------
# defaults
# -----------------------------------------------------------------------------

. ${SHDIR}/aliasrc
. ${SHDIR}/functionrc

# -----------------------------------------------------------------------------
# plugins
# -----------------------------------------------------------------------------

. ${ZDOTDIR}/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
. ${ZDOTDIR}/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh

# -----------------------------------------------------------------------------
# references
# -----------------------------------------------------------------------------

# https://0x0.st/oCRf
