;;; core.lisp --- StumpWM core configuration

;;; Commentary:

;; TODO

;;; Code:

(defun annt/file-exists-p (filename)
  "Returns `t' if FILENAME exists, must be a string."
  (uiop:probe-file* (uiop:truename* filename)))

(defun annt/run-sh-cmd (command)
  "Runs COMMAND."
  (uiop:launch-program command))

;; clear all maps
(dolist (map '(*top-map* *root-map* *groups-map*
                         *help-map*
                         *exchange-window-map* *group-top-maps*
                         *group-top-map* *group-root-map*
                         *tile-group-top-map* *tile-group-root-map*))
  (setf map nil))

;; prefix key
(set-prefix-key (kbd "s-z"))

;; help-map
(fill-keymap *help-map*
             (kbd "v") "describe-variable"
             (kbd "f") "describe-function"
             (kbd "k") "describe-key"
             (kbd "c") "describe-command"
             (kbd "w") "where-is")

;;; core.lisp ends here
