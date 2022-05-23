;;; init.lisp --- StumpWM init configuration

;; This file is NOT part of StumpWM.

;;; Commentary:

;; TODO

;;; Code:

(in-package :stumpwm)

(defvar annt/stumpwm-dir
  (directory-namestring
   (truename (uiop:merge-pathnames* ".config/stumpwm" (user-homedir-pathname))))
  "A directory with initially loaded files.")

(defun annt/load-file (filename)
  "Load a file FILENAME (no extension) from `annt/stumpwm-dir'."
  (let ((file (uiop:merge-pathnames* (concat filename ".lisp")
                                     annt/stumpwm-dir)))
    (if (uiop:probe-file* file)
        (load file)
      (format *error-output* "File '~a' does not exist." file))))

;; enable logging
(redirect-all-output (uiop:merge-pathnames* "stumpwm.log" annt/stumpwm-dir))

(annt/load-file "core/core")
(annt/load-file "core/module")
(annt/load-file "core/core-keybinds")
(annt/load-file "message-bar")
(annt/load-file "windows")
(annt/load-file "groups")
(annt/load-file "modeline")

;; root-map
(def-key! *root-map* "C-g" "abort")

(def-key! *root-map* ";" "colon")
(def-key! *root-map* ":" "eval")
(def-key! *root-map* "!" "exec")
(def-key! *top-map* "s-R" "restart-hard")

;; define map keys
(let ((map *root-map*))
  (def-key! map "h" '*help-map*)
  (def-key! map "g" '*groups-map*)
  (def-key! map "x" '*exchange-window-map*))

;;; init.lisp ends here
