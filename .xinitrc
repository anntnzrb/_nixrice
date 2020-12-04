#!/bin/sh

#          ██          ██   ██
#         ░░          ░░   ░██
#  ██   ██ ██ ███████  ██ ██████
# ░░██ ██ ░██░░██░░░██░██░░░██░
#  ░░███  ░██ ░██  ░██░██  ░██
#   ██░██ ░██ ░██  ░██░██  ░██
#  ██ ░░██░██ ███  ░██░██  ░░██
# ░░   ░░ ░░ ░░░   ░░ ░░    ░░

# runs after executing `startx`

# shellcheck disable=1090
[ -f "$HOME"/.xprofile ] && . "$HOME"/.xprofile

SESSION="dwm"

case $SESSION in
i3 | i3wm) exec i3 ;;

bspwm) exec bspwm ;;

dwm)
    # statusbar
    dwmblocks &

    # keybinds
    sxhkd -t 5 -c "$HOME/.config/dwm/sxhkdrc_dwm" &

    # run dwm as a loop in order to restart, also log errors if any
    while :; do dwm 2>"$HOME/.dwm.log"; done
    ;;

spectrwm) exec spectrwm ;;

*) exit 1 ;;
esac
