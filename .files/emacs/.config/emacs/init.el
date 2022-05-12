;;; init.el --- Initialization file of GNU Emacs -*- lexical-binding: t; -*-

;; Copyright (C) 2020-2022 anntnzrb

;; Author: anntnzrb <anntnzrb@proton.me>
;; Keywords: initialization

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

;; This initialization file configures the literate configuration file written
;; in Org, it does so by checking when it was last updated and tangles it only
;; when needed, loads the non-updated file otherwise.  The main goal here is to
;; remove the unneeded tangling and improve startup time.

;; There are a few other options I like to keep here, should be well-documented.

;; Lastly, there a few benchmarks to debug the initialization.

;;; Code:

(defvar annt/emacs-config-file "readme"
  "Base name of annt's configuration file.")

(defun annt/notify-and-log (msg)
  "Prints MSG and logs it to a file in `user-emacs-directory' directory."
  (message msg)

  ;; log to file
  (append-to-file
   (format "[%s] :: %s\n" (current-time-string) msg)
   nil
   (expand-file-name "emacs.log" user-emacs-directory)))

(defun annt/expand-emacs-file-name (file extension)
  "Return canonical path to FILE to Emacs config with EXTENSION."
  (locate-user-emacs-file
   (concat file extension)))

(defun annt/org-tangle-and-byte-compile (file target-file)
  "Tangle given FILE to TARGET-FILE and byte-compile it."
  (require 'ob-tangle)
  (org-babel-tangle-file file target-file)
  (byte-compile-file          target-file))

(defun annt/update-emacs-config ()
  "If configuration files were modified, update them with the latest changes.
First it checks wether the literate configuration file (Org) was modified or
not, only when there's a change it deletes the previously tangled ELisp code
and re-tangles it, byte-compiles it afterwards."
  (let* ((cfg-file annt/emacs-config-file)
         (cfg-file-org
          (annt/expand-emacs-file-name cfg-file ".org"))
         (cfg-file-el
          (annt/expand-emacs-file-name cfg-file ".el"))
         (cfg-file-el-compiled
          (annt/expand-emacs-file-name cfg-file ".elc"))
         (cfg-file-org-last-modified
          (file-attribute-modification-time (file-attributes cfg-file-org))))

    (require 'org-macs)
    (unless (org-file-newer-than-p cfg-file-el cfg-file-org-last-modified)
      (annt/notify-and-log "Literate configuration has been updated...")
      (annt/notify-and-log "Deleting old configuration files files...")
      (delete-file cfg-file-el          t)
      (delete-file cfg-file-el-compiled t)
      (annt/org-tangle-and-byte-compile cfg-file-org cfg-file-el))))

;; set working directory to `~' regardless of where Emacs was started from
(cd (expand-file-name "~/"))

;; configuration file initialization
(let* ((cfg-file annt/emacs-config-file)
       (cfg-file-org (annt/expand-emacs-file-name cfg-file ".org"))
       (cfg-file-el  (annt/expand-emacs-file-name cfg-file ".el")))

  ;; only tangle if tangled file does not exists
  (unless (file-exists-p cfg-file-el)
    (annt/notify-and-log "Literate configuration has not been tangled yet...")
    (annt/notify-and-log "Proceeding to tangle & byte-compile configuration...")
    (annt/org-tangle-and-byte-compile cfg-file-org cfg-file-el)
    (annt/notify-and-log "Literate configuration was tangled & byte-compiled."))

  ;; finally load the configuration file
  (load-file cfg-file-el)
  (annt/notify-and-log "Configuration loaded."))

;; `kill-emacs-hook' used for startup time
(add-hook 'kill-emacs-hook #'annt/update-emacs-config)

;; WARNING: Reset garbage collector (should be at the end of this file)
;; After everything else is set-up, set the garbage collector to a considerable
;; non-archaic value.
(defun annt/setup-gc ()
  "Sets up efficient garbage collector settings.
The following values are modified: `gc-cons-threshold' and
`gc-cons-percentage'."
  (setq gc-cons-threshold (* 20 1024 1024))
  (setq gc-cons-percentage 0.1))

(defun annt/debug-init()
  "Displays information related to initialization."
  (let ((pkg-count 0)
        (init-time (emacs-init-time)))

    ;; package.el
    (when (bound-and-true-p package-alist)
      (setq pkg-count (length package-activated-list)))

    ;; straight.el
    (when (boundp 'straight--profile-cache)
      (setq pkg-count (+ (hash-table-count straight--profile-cache) pkg-count)))

    (annt/notify-and-log
     (format
      "GNU Emacs initialized in %s (%d pkgs) :: performed %d garbage collections."
      init-time pkg-count gcs-done))))

;; `emacs-startup-hook' can be used to set this after init files are done
(add-hook 'emacs-startup-hook #'annt/setup-gc)
(add-hook 'emacs-startup-hook #'annt/debug-init)

(provide 'init)
;;; init.el ends here
