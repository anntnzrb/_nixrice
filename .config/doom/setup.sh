#!/bin/sh

# setup.sh --- utility script for Doom Emacs maintenance

doom_dir="${HOME}/.config/doom"
emacs_dir="${HOME}/.config/emacs"
files2del='config.el init.el packages.el'

# delete files for cleanup
for f in $files2del; do
    printf "removing '%s'...\n" "$f"
    rm -f "$f"
done

# set-up minimal Doom Emacs initialization file
tee "${doom_dir}/init.el" <<! >/dev/null
;;; init.el -*- lexical-binding: t; -*-

; minimal needed for first-time tangling
(doom! :config literate)
!

# perform Doom sync
"${emacs_dir}/bin/doom" sync

# perform Doom doc check
"${emacs_dir}/bin/doom" doctor
