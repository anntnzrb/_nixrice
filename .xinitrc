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

WM="dwm"

case $WM in
i3)
    exec i3
    ;;
bspwm)
    exec bspwm
    ;;
dwm)
    # statusbar
    dwmblocks &

    # keybinds
    sxhkd -c "$HOME/.config/dwm/sxhkdrc_dwm" &

    while :; do
        ssh-agent dwm
    done
    ;;
spectrwm)
    exec spectrwm
    ;;
*)
    exit 1
    ;;
esac
