;;; windows.lisp --- StumpWM windows configuration

;; This file is NOT part of StumpWM.

;;; Commentary:

;; TODO

;;; Code:

(let ((map *top-map*))
  (def-key! map "s-Q" "delete")
  (def-key! map "s-K" "kill")

  ;; movement
  (def-key! map "s-j" "next")
  (def-key! map "s-k" "prev"))

(let ((map *exchange-window-map*))
  (def-key! map "f" "fullscreen")
  (def-key! map "w" "windowlist")
  (def-key! map "i" "info")
  (def-key! map "I" "show-window-properties"))

;;; windows.lisp ends here
