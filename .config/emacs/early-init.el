;;; early-init.el --- GNU Emacs >= 27.1 pre-initialization file

;;; Commentary:

;; This file gets loaded before the 'init.el' file.
;; Should not have more than a few files.

;;; Code:

;; Package tweaks
(setq-default package-enable-at-startup t
              package-quickstart        t)

(provide 'early-init)

;;; early-init.el ends here
