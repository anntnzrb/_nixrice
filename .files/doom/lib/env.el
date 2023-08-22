;;; $DOOMDIR/lib/env.el -*- lexical-binding: t; -*-

;;; Commentary:

;; Environment related configurations.

;;; Code:

(defun append-path (path)
  "Add PATH to exec-path and PATH environment variable if it exists."
  (let ((expanded-path (expand-file-name path)))
    (if (file-directory-p expanded-path)
        (progn
          (add-to-list 'exec-path expanded-path)
          (setenv "PATH" (concat (getenv "PATH") path-separator expanded-path)))
      (message "Warning: %s is not a directory" expanded-path))))

;; source RTX shims
(append-path "~/.local/share/rtx/shims")

;; source Cargo
(append-path "~/.cargo/bin")
