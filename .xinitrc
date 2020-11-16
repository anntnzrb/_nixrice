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

[ -f "$HOME"/.xprofile ] && . "$HOME"/.xprofile

WM="bspwm"

case $WM in
i3)
    exec i3
    ;;
spectrwm)
    exec spectrwm
    ;;
bspwm)
    exec bspwm
    ;;
dwm)
    # statusbar
    dwmblocks &

    while :; do
        ssh-agent dwm
    done
    ;;
esac
