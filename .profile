#!/bin/sh

# shellcheck disable=1090
# follow non-constant sources
# shellcheck disable=SC2155
# Disable declare and assign separately to avoid masking return values
# needs further studying

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
export PATH="${PATH}:`du "${HOME}/.local/bin/" | cut -f2 | paste -sd ':' -`"

# source Nix
test -d "${HOME}/.nix-profile/" && . "${HOME}/.nix-profile/etc/profile.d/nix.sh"

# -----------------------------------------------------------------------------
# preamble
# -----------------------------------------------------------------------------

# == Xorg stuff
export XDG_DESKTOP_DIR="${HOME}"
export XDG_DOCUMENTS_DIR="${HOME}/lib/docs/"
export XDG_PICTURES_DIR="${HOME}/lib/imgs/"
export XDG_VIDEOS_DIR="${HOME}/lib/vids/"
export XDG_MUSIC_DIR="${HOME}/lib/audio/"
export XDG_DOWNLOAD_DIR="${HOME}/downloads"
export XDG_TEMPLATES_DIR="${HOME}/lib"
export XDG_PUBLICSHARE_DIR="${HOME}/lib"
export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_CACHE_HOME="${HOME}/.cache"
export XDG_DATA_HOME="${HOME}/.local/share"

# -----------------------------------------------------------------------------
# defaults
# -----------------------------------------------------------------------------

export EDITOR='editor'
export TERMINAL='alacritty'
export BROWSER='qutebrowser'
export FILE='pcmanfm'
export READER='zathura'
export SH_CFGS="${XDG_CONFIG_HOME}/sh"
export ALIASES="${SH_CFGS}/lib/02-aliases"
export FUNCTIONS="${SH_CFGS}/lib/03-functions"

# load utilities
export LIBSHUTILS="${HOME}/.local/bin/libshutils"

# shell(s)
export BASHDIR="${SH_CFGS}/bash"
export ZDOTDIR="${SH_CFGS}/zsh"

# -----------------------------------------------------------------------------
# colors
# -----------------------------------------------------------------------------

test -x "`command -v 'tput'`" && {
    export LESS_TERMCAP_ZN=`tput ssubm`
    export LESS_TERMCAP_ZO=`tput ssupm`
    export LESS_TERMCAP_ZV=`tput rsubm`
    export LESS_TERMCAP_ZW=`tput rsupm`
    export LESS_TERMCAP_mb=`tput bold; tput setaf 3`
    export LESS_TERMCAP_md=`tput bold; tput setaf 2`
    export LESS_TERMCAP_me=`tput sgr0`
    export LESS_TERMCAP_mh=`tput dim`
    export LESS_TERMCAP_mr=`tput rev`
    export LESS_TERMCAP_se=`tput rmso; tput sgr0`
    export LESS_TERMCAP_so=`tput bold; tput setaf 3; tput setab 4`
    export LESS_TERMCAP_ue=`tput rmul; tput sgr0`
    export LESS_TERMCAP_us=`tput smul; tput bold; tput setaf 7`
}

# -----------------------------------------------------------------------------
# ~ clean-up
# -----------------------------------------------------------------------------

# == languages
# Rust
export CARGO_HOME="${XDG_DATA_HOME}/cargo"

# == Android
export ANDROID_SDK_HOME="${XDG_CONFIG_HOME}/android"
export ANDROID_AVD_HOME="${XDG_DATA_HOME}/android"
export ANDROID_EMULATOR_HOME="${XDG_DATA_HOME}/android"
export ADB_VENDOR_KEY="${XDG_CONFIG_HOME}/android"

# == GTK
export GTK_RC_FILES="${XDG_CONFIG_HOME}/gtk-1.0/gtkrc"
export GTK2_RC_FILES="${XDG_CONFIG_HOME}/gtk-2.0/gtkrc"

# == misc
export HISTFILE="${XDG_DATA_HOME}/history"
export WGETRC="${XDG_CONFIG_HOME}/wget/wgetrc"

# -----------------------------------------------------------------------------
# miscellaneous
# -----------------------------------------------------------------------------

# Java apps fix for dwm
export _JAVA_AWT_WM_NONREPARENTING=1

# Java
export JAVA_HOME=`readlink -f '/usr/bin/java' | sed 's:/bin/java::'` &&
    export PATH=${JAVA_HOME}/bin:${PATH}

# start graphical automatically
#test "`tty`" = '/dev/tty1' && ! pgrep -x 'Xorg' >/dev/null && exec startx
