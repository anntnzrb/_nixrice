#!/bin/sh

# pick first available profile
autorandr -c &

# audio applet
pasystray &

# net applet
nm-applet &

# hotkeys
sxhkd -m 1 &

# light filter
redshift-gtk &

# compositor (X11)
picom -b &

# wm
exec awesome
