#!/bin/sh

#                            ████ ██  ██
#  ██████                   ░██░ ░░  ░██
# ░██░░░██ ██████  ██████  ██████ ██ ░██  █████
# ░██  ░██░░██░░█ ██░░░░██░░░██░ ░██ ░██ ██░░░██
# ░██████  ░██ ░ ░██   ░██  ░██  ░██ ░██░███████
# ░██░░░   ░██   ░██   ░██  ░██  ░██ ░██░██░░░░
# ░██     ░███   ░░██████   ░██  ░██ ███░░██████
# ░░      ░░░     ░░░░░░    ░░   ░░ ░░░  ░░░░░░
# runs on login
# environmental variables are set here

# adds `~/.local/bin` to $PATH
export PATH="$PATH:$(du "$HOME/.local/bin/" | cut -f2 | paste -sd ':')"

# -----------------------------------------------------------------------------
# default programs
# -----------------------------------------------------------------------------
export TERMINAL="st"
export EDITOR="nvim"
export BROWSER="qutebrowser"
export FILE="pcmanfm"
export READER="zathura"

# shell(s)
export ZDOTDIR="$HOME/.config/sh/zsh"

# -----------------------------------------------------------------------------
# ~ clean-up
# -----------------------------------------------------------------------------
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export ANDROID_SDK_HOME="$HOME/.config/android"
export GTK2_RC_FILES="$HOME/.config/gtk-2.0/gtkrc-2.0"
export HISTFILE="$HOME/.local/share/history"
export WGETRC="$HOME/.config/wget/wgetrc"

# -----------------------------------------------------------------------------
# miscellaneous
# -----------------------------------------------------------------------------
# settings

# language
export LANG="en_US.UTF-8"
export LANGUAGE="en_US.UTF-8"
export LESSCHARSET="utf-8"
export LC_ALL="en_US.UTF-8"
export LC_COLLATE="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"
export LC_MESSAGES="en_US.UTF-8"
export LC_MONETARY="en_US.UTF-8"
export LC_NUMERIC="en_US.UTF-8"
export LC_TIME="en_US.UTF-8"

export FZF_DEFAULT_OPTS="--layout=reverse --height 40%"
export LESSHISTFILE="-"
export SUDO_ASKPASS="$HOME/.local/bin/dmenupass"
export _JAVA_AWT_WM_NONREPARENTING=1 # Java apps fix for dwm

# Java
export JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:/bin/java::") &&
    export PATH=$JAVA_HOME/bin:$PATH

# start graphical server on tty1 if not already running.
#[ "$(tty)" = "/dev/tty1" ] && ! pidof Xorg >/dev/null 2>&1 && exec startx
