;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;;; Commentary:

;; User-defined configurations.

;;; Code:

(setq user-full-name    "anntnzrb")
(setq user-mail-address "anntnzrb@protonmail.com")

(load! "lib/env.el")
(load! "lib/editor.el")
(load! "lib/completion.el")
(load! "lib/ai.el")
(load! "lib/ui.el")

;; programming languages
(load! "lib/lang/rust.el")
