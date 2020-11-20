;; literate config
(require 'org)
(org-babel-load-file (expand-file-name ".config/emacs/readme.org"))

;; disable emacs settings up custom variables
(unless (setq custom-file "/dev/null"))
(unless custom-file (expand-file-name (setq custom-file "~/.cache")))
