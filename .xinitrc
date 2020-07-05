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

#◦◝◟∘◞◜◦ window manager

# i3
#exec i3

# spectrwm
#exec spectrwm

# dwm
while :; do
    ssh-agent dwm
done
