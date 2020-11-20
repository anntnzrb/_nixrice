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
# environment variables are set here

# adds `~/.local/bin` to $PATH
export PATH="$PATH:$(du "$HOME/.local/bin/" | cut -f2 | paste -sd ':')"

# -----------------------------------------------------------------------------
# preamble
# -----------------------------------------------------------------------------

# == Xorg stuff
export XDG_DESKTOP_DIR="$HOME"
export XDG_DOCUMENTS_DIR="$HOME/lib/docs/"
export XDG_PICTURES_DIR="$HOME/lib/imgs/"
export XDG_VIDEOS_DIR="$HOME/lib/vids/"
export XDG_MUSIC_DIR="$HOME/lib/audio/"
export XDG_DOWNLOAD_DIR="$HOME/downloads"
export XDG_TEMPLATES_DIR="$HOME/lib"
export XDG_PUBLICSHARE_DIR="$HOME/lib"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"

# -----------------------------------------------------------------------------
# defaults
# -----------------------------------------------------------------------------

export EDITOR="editor"
export TERMINAL="st"
export BROWSER="qutebrowser"
export FILE="pcmanfm"
export READER="zathura"
export SYS_MONITOR="btm"
export SH_CFGS="$XDG_CONFIG_HOME/sh"
export ALIASES="$SH_CFGS/lib/02-aliases"
export FUNCTIONS="$SH_CFGS/lib/03-functions"

# shell(s)
export ZDOTDIR="$SH_CFGS/zsh"

# -----------------------------------------------------------------------------
# ~ clean-up
# -----------------------------------------------------------------------------

# == languages
export CARGO_HOME="$XDG_DATA_HOME/cargo"

# == Android
export ANDROID_SDK_HOME="$XDG_CONFIG_HOME/android"
export ANDROID_AVD_HOME="$XDG_DATA_HOME/android"
export ANDROID_EMULATOR_HOME="$XDG_DATA_HOME/android"
export ADB_VENDOR_KEY="$XDG_CONFIG_HOME/android"

# == GTK
export GTK_RC_FILES="$XDG_CONFIG_HOME/gtk-1.0/gtkrc"
export GTK2_RC_FILES="$XDG_CONFIG_HOME/gtk-2.0/gtkrc"

# == misc
export HISTFILE="$XDG_DATA_HOME/history"
export WGETRC="$XDG_CONFIG_HOME/wget/wgetrc"

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

# Java apps fix for dwm
export _JAVA_AWT_WM_NONREPARENTING=1

# Java
export JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:/bin/java::") &&
    export PATH=$JAVA_HOME/bin:$PATH

# start graphical automatically
#[ "$(tty)" = "/dev/tty1" ] && ! pidof -s Xorg >/dev/null 2>&1 && exec startx
