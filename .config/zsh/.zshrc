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
# random quote on launch
fortune -s | cowsay -f tux

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

# -----------------------------------------------------------------------------
# keybinds
# -----------------------------------------------------------------------------
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
for f in "$HOME"/.config/sh/*; do
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
