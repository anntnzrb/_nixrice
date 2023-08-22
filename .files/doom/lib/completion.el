;;; $DOOMDIR/lib/completion.el -*- lexical-binding: t; -*-

;;; Commentary:

;; Completion related configurations.

;;; Code:

(use-package! embark
  :defer t
  :init
  (map! [remap describe-bindings] #'embark-bindings
        "C-<escape>"              #'embark-act))
