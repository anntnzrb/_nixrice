;;; module.lisp --- StumpWM modules configuration

;; This file is NOT part of StumpWM.

;;; Commentary:

;; TODO

;;; Code:

(defun annt/ql-setup ()
  "Installs Quicklisp via an external program."
  (annt/run-sh-cmd
   (format nil "sh ~A/core/install-quicklisp" annt/stumpwm-dir)))

(stumpwm:set-module-dir
 (uiop:merge-pathnames* ".config/stumpwm/modules" (user-homedir-pathname)))

;; set up Quicklisp only if not present already
(unless (annt/file-exists-p "~/quicklisp/") (annt/ql-setup))

;; load quicklisp
(load (uiop:merge-pathnames* "quicklisp/setup.lisp" (user-homedir-pathname)))

;;; module.lisp ends here
