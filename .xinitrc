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
test -f "${HOME}/.xprofile" && . "${HOME}/.xprofile"

# some dbus patch for systemd systems (keyring-related)
pgrep -x 'systemd' >/dev/null && . '/etc/X11/xinit/xinitrc.d/50-systemd-user.sh'

SESSION='i3'

case ${SESSION} in
i3)

# keybinds
sxhkd -t 5 -c "${HOME}/.config/i3/sxhkdrc_i3" &

exec i3 ;;

bsp[wm]) exec bspwm ;;

dwm)
# statusbar
dwmblocks &

# keybinds
sxhkd -t 5 -c "${HOME}/.config/dwm/sxhkdrc_dwm" &

# run dwm as a loop in order to restart, also log
while :; do dwm 2>"${HOME}/.dwm.log" >&2; done
;;

spectr[wm]) exec spectrwm ;;

*) exit 1 ;;
esac
