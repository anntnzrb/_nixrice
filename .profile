#!/bin/sh

# shellcheck disable=1090
# follow non-constant sources

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

# -----------------------------------------------------------------------------
# preamble
# -----------------------------------------------------------------------------

# == $PATH
append_path() {
    # Append "$1" to $PATH when not already in.
    # taken from '/etc/profile'
    case ":${PATH}:" in
    *:"$1":*) ;;
    *) PATH="${PATH:+${PATH}:}$1"
    esac
}

# load profiles from /etc/profile.d/
if test -d '/etc/profile.d/'; then
    for prof in /etc/profile.d/*.sh; do
        test -r "${prof}" && . "${prof}"
    done
    unset prof
fi

# '~/.local/bin'
append_path "${HOME}/.local/bin/"

# Java
JAVA_HOME=$(readlink -f '/usr/bin/java' | sed 's:/bin/java::') \
    && export JAVA_HOME && append_path "${JAVA_HOME}/bin"

# ... finally export & clean
export PATH
unset -f append_path

# Haskell (ghcup)
test -f "${HOME}/.ghcup/env" && . "${HOME}/.ghcup/env"

# SDKman
test -d "${HOME}/.sdkman/" && . "${HOME}/.sdkman/bin/sdkman-init.sh"

# -----------------------------------------------------------------------------
# applications
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

export EDITOR="${XDG_DESKTOP_DIR:?}/.local/bin/editor"
export TERMINAL='alacritty'
export BROWSER='qutebrowser'
export FILE='pcmanfm'
export READER='zathura'
export SH_CFGS="${XDG_CONFIG_HOME:?}/sh"

# load utilities
export LIBSHUTILS="${HOME}/.local/bin/libshutils"

# shell(s)
export ZDOTDIR="${SH_CFGS}/zsh"

# -----------------------------------------------------------------------------
# colors
# -----------------------------------------------------------------------------

test -x "$(command -v 'tput')" && {
    export LESS_TERMCAP_ZN=$(tput ssubm)
    export LESS_TERMCAP_ZO=$(tput ssupm)
    export LESS_TERMCAP_ZV=$(tput rsubm)
    export LESS_TERMCAP_ZW=$(tput rsupm)
    export LESS_TERMCAP_mb=$(tput bold; tput setaf 3)
    export LESS_TERMCAP_md=$(tput bold; tput setaf 2)
    export LESS_TERMCAP_me=$(tput sgr0)
    export LESS_TERMCAP_mh=$(tput dim)
    export LESS_TERMCAP_mr=$(tput rev)
    export LESS_TERMCAP_se=$(tput rmso; tput sgr0)
    export LESS_TERMCAP_so=$(tput bold; tput setaf 3; tput setab 4)
    export LESS_TERMCAP_ue=$(tput rmul; tput sgr0)
    export LESS_TERMCAP_us=$(tput smul; tput bold; tput setaf 7)
}

# -----------------------------------------------------------------------------
# ~/ clean-up
# -----------------------------------------------------------------------------

# == languages
# Rust
export CARGO_HOME="${XDG_DATA_HOME:?}/.local/share}/cargo"

# == Android
export ANDROID_SDK_HOME="${XDG_CONFIG_HOME:?}/.config}/android"
export ANDROID_AVD_HOME="${XDG_DATA_HOME:?}/.local/share}/android"
export ANDROID_EMULATOR_HOME="${XDG_DATA_HOME:?}/.local/share}/android"
export ADB_VENDOR_KEY="${XDG_CONFIG_HOME:?}/.config}/android"

# == GTK
export GTK_RC_FILES="${XDG_CONFIG_HOME:?}/.config}/gtk-1.0/gtkrc"
export GTK2_RC_FILES="${XDG_CONFIG_HOME:?}/.config}/gtk-2.0/gtkrc"

# == misc
export HISTFILE="${XDG_DATA_HOME:?}/.local/share}/history"
export WGETRC="${XDG_CONFIG_HOME:?}/.config}/wget/wgetrc"
export FZF_DEFAULT_OPTS='--layout=reverse --height 40%'
export LESSKEY="${XDG_CONFIG_HOME:?}/less/lesskey"
export LESSHISTFILE='-'
export SUDO_ASKPASS="${XDG_DESKTOP_DIR:?}/.local/bin/dmenupass"

# == pfetch
# information to display
export PF_INFO='ascii title kernel os host wm de memory pkgs editor shell uptime palette'
# alignment padding
export PF_ALIGN='7'
# color of info data
export PF_COL2=4
# color of title data
export PF_COL3=1

# -----------------------------------------------------------------------------
# miscellaneous
# -----------------------------------------------------------------------------

# Java apps fix for dwm
export _JAVA_AWT_WM_NONREPARENTING=1

# start graphical automatically
#test "$(tty)" = '/dev/tty1' && ! pgrep -x 'Xorg' >/dev/null 2>&1 && exec startx
