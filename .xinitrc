#!/bin/sh

# shellcheck disable=1090,1091
# bypass non-constant source following

#          ██          ██   ██
#         ░░          ░░   ░██
#  ██   ██ ██ ███████  ██ ██████
# ░░██ ██ ░██░░██░░░██░██░░░██░
#  ░░███  ░██ ░██  ░██░██  ░██
#   ██░██ ░██ ░██  ░██░██  ░██
#  ██ ░░██░██ ███  ░██░██  ░░██
# ░░   ░░ ░░ ░░░   ░░ ░░    ░░
# runs after executing `startx`

# load defaults
xinit_cfg_dir='/etc/X11/xinit/xinitrc.d'
test -d "${xinit_cfg_dir}" && {
    for f in "${xinit_cfg_dir}"/*.sh ; do
        test -x "${f}" && . "${f}"
    done
    unset f
}
unset -v xinit_cfg_dir

# -----------------------------------------------------------------------------
# Xorg settings
# -----------------------------------------------------------------------------

xset s off &                                  # disable screensaver
xset dpms 0 0 900 &                           # off-screen time
xrdb "${XDG_CONFIG_HOME:?}/X11/.Xresources" & # source Xresources

# load X start-up programs
test -x "${HOME}/.xprofile" && . "${HOME}/.xprofile"

# -----------------------------------------------------------------------------
# graphical environment (window manager/desktop environment)
# -----------------------------------------------------------------------------

# default ses
session='awesome'

case ${session:?} in
awesome)
    unset -v session

    exec awesome
    ;;

dwm)
    unset -v session

    # statusbar
    dwmblocks &

    # run dwm as a loop in order to restart, also log
    while :; do dwm 2>"${HOME}/.dwm.log" >&2; done
    ;;
*)
    printf "error :: '%s'\n" "$1" >&2
    exit 1
esac
