;;; groups.lisp --- StumpWM groups configuration

;; This file is NOT part of StumpWM.

;;; Commentary:

;; TODO
;; "workspaces" and "groups" should be used interchangeably.

;;; Code:

(defvar annt/workspace-alist nil
  "Alist of workspace names associated with its key-bind; you may notice this
  is just the top number row with the shift modifier included.")

(setf annt/workspace-alist '(("i"    . "!")
                             ("ii"   . "@")
                             ("iii"  . "#")
                             ("iv"   . "$")
                             ("v"    . "%")
                             ("vi"   . "^")
                             ("vii"  . "&")
                             ("viii" . "*")
                             ("ix"   . "(")))

(defvar annt/workspace-alist-length (list-length annt/workspace-alist)
  "The lenght of `annt/workspace-alist'.")

;; rename current workspace "Default" to first workspace of the workspace alist
(grename (first (first annt/workspace-alist)))

;; create a workspace for each element of the workspace list
(loop for (w . k) in annt/workspace-alist do (gnewbg w))

;; map gselect (select workspace n); n is a number from [1,9]
;; SUPER+1 ==> workspace #1 ||| SUPER+8 ==> workspace #8 ||| ...
(loop for i from 1 to annt/workspace-alist-length do
      (let ((n (write-to-string i)))
        (def-key! *top-map* (concat "s-" n) (concat "gselect " n))))

;; map gmove (move current window to n); n is a number from [1,9]
;; SUPER+SHIFT+1 ==> move focused window to workspace #1 ||| ...
(let ((n 1))
  (loop for (w . k) in annt/workspace-alist do
        (def-key! *top-map* (concat "s-" k) (concat "gmove " (write-to-string n)))
        (incf n)))

;;; groups.lisp ends here
