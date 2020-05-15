#                 ██
#                ░██
#  ██████  ██████░██      ██████  █████
# ░░░░██  ██░░░░ ░██████ ░░██░░█ ██░░░██
#    ██  ░░█████ ░██░░░██ ░██ ░ ░██  ░░
#   ██    ░░░░░██░██  ░██ ░██   ░██   ██
#  ██████ ██████ ░██  ░██░███   ░░█████
# ░░░░░░ ░░░░░░  ░░   ░░ ░░░     ░░░░░
# useful stuff should be at ../zsh/lib/


#◦◝◟∘◞◜◦  random quote on zsh launch

fortune -s | cowsay -f tux

#◦◝◟∘◞◜◦ settings

# tab completion
autoload -U compinit
zstyle ':completion:*' menu select
zmodload zsh/complist
compinit

# show hidden files
_comp_options+=(globdots)

# auto complete case insensitive
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

#◦◝◟∘◞◜◦ history

HISTSIZE=3000
SAVEHIST=1000
HISTFILE=$ZDOTDIR/.zsh_history
setopt APPEND_HISTORY
setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt SHARE_HISTORY

#◦◝◟∘◞◜◦ file sourcing

# aliases / functions / prompt
[ -f "$HOME/.config/sh/aliasrc" ] && source "$HOME/.config/sh/aliasrc"
[ -f "$HOME/.config/sh/functions" ] && source "$HOME/.config/sh/functions"
[ -f "$HOME/.config/sh/prompt" ] && source "$HOME/.config/sh/prompt"

# uncrustify config (for some reason this needs to be sourced every time)
export UNCRUSTIFY_CONFIG="$HOME/.config/uncrustify/uncrustify.cfg"

# extensions
for extension ($ZDOTDIR/lib/extensions/*) source $extension
