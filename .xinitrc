#!/usr/bin/env sh

#          ██          ██   ██
#         ░░          ░░   ░██
#  ██   ██ ██ ███████  ██ ██████
# ░░██ ██ ░██░░██░░░██░██░░░██░
#  ░░███  ░██ ░██  ░██░██  ░██
#   ██░██ ░██ ░██  ░██░██  ░██
#  ██ ░░██░██ ███  ░██░██  ░░██
# ░░   ░░ ░░ ░░░   ░░ ░░    ░░

# runs after executing `startx`

[ -f ~/.xprofile ] && . ~/.xprofile

#◦◝◟∘◞◜◦ window manager

# i3
#exec i3

# spectrwm
#exec spectrwm

# dwm
while :; do
	ssh-agent dwm
done
