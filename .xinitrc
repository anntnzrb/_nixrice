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
    # keybinds
    sxhkd -c "$HOME/.config/bspwm/sxhkdrc_bspc" &
    exec bspwm
    ;;
dwm)
    while :; do
        ssh-agent dwm
    done
    ;;
esac
