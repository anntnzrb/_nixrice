;;; init.el --- Initialization file of GNU Emacs

;;; Commentary:
;; This file gets loaded after the 'early-init.el' file.

;;; Code:

(org-babel-load-file (expand-file-name "readme.org" user-emacs-directory))

(provide 'init)
;;; init.el ends here
