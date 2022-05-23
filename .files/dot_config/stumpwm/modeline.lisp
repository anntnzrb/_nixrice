;;; modeline.lisp --- StumpWM modeline configuration

;; This file is NOT part of StumpWM.

;;; Commentary:

;; TODO

;;; Code:

(defun annt/mode-line-enable-everywhere ()
  "Enable the mode-line on every screen."
  (loop for screen in *screen-list* do
        (loop for head in (screen-heads screen) do
              (enable-mode-line screen head t))))

(setf *mode-line-pad-y* 0)
(setf *mode-line-pad-x* 0)
(setf *mode-line-position* :top)
(setf *mode-line-border-width* 2)
(setf *time-modeline-string* "%a, %b %d @ %R")

(let ((mode-line-separator                       "|")
      (mode-line-pad-right                      "^>")
      (mode-line-current-group-name "^7{^B^1%n^7^b}")
      (mode-line-current-head-windows           "%W")
      (mode-line-date                         "^7%d"))
  (setf *screen-mode-line-format* (list
                                   mode-line-current-group-name
                                   mode-line-separator
                                   mode-line-current-head-windows
                                   mode-line-pad-right
                                   mode-line-date
                                   )))

;; finally, enable it
(annt/mode-line-enable-everywhere)

;;; modeline.lisp ends here
