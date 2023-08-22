;;; $DOOMDIR/lib/ai.el -*- lexical-binding: t; -*-

;;; Commentary:

;; AI-related configurations.

;;; Code:

(use-package! copilot
  :if (executable-find "node") ;; needs nodejs
  :hook ((text-mode prog-mode) . #'copilot-mode)
  :bind (:map copilot-completion-map
              ("<tab>" . 'copilot-accept-completion)
              ("C-<tab>" . 'copilot-accept-completion-by-word)))
