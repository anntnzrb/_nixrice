;;; $DOOMDIR/config.el --- Doom Emacs personal configuration file -*- lexical-binding: t; -*-

;; Copyright (C) 2021 anntnzrb

;; Author: anntnzrb <anntnzrb@protonmail.com>
;; Keywords: configuration

;; This file is NOT part of GNU Emacs.

;; This file is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this file.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This file configures Doom Emacs, not Emacs itself, this is why this should
;; not be located at the commonly known Emacs directory, but the `doom' folder
;; instead.  This file may be interpreted as the usual `init.el' file to avoid
;; any confusion.  Package installation should NOT be declared here, refer to
;; `packages.el' file for this purpose.

;; Lastly, there is no need of running `doom sync' when updating this file.

;;; Code:

;;
;;; personal

(setq user-full-name    "anntnzrb")
(setq user-mail-address "anntnzrb@protonmail.com")

;;
;;; fonts

;; ensure font size numeric values are even for proper scaling, even better if
;; divisible by 8.

(let ((font-size 16))
  ;; default font
  (setq doom-font
        (font-spec
         :family "Fantasque Sans Mono"
         :weight 'regular
         :size   font-size))

  ;; for presentations
  (setq doom-big-font
        (font-spec
         :family "Fantasque Sans Mono"
         :weight 'regular
         :size   (* font-size 1.5)))

  ;; variable-pitch text
  (setq doom-variable-pitch-font
        (font-spec
         :family "JetBrains Mono"
         :weight 'regular
         :size   font-size)))


;;
;;; Doom itself

(setq doom-theme 'doom-dracula)
(setq fancy-splash-image
      (expand-file-name "assets/doom1993.png" doom-private-dir))

;;
;;; org

;; change default org files location
(setq org-directory "~/lib/org/")

;; line numbers
(setq display-line-numbers-type 'relative)
