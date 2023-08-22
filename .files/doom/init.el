;;; $DOOMDIR/init.el -*- lexical-binding: t; -*-

;;; Commentary:

;; This file controls what Doom modules are enabled and what order they load in.
;; Remember running 'doom sync' after modification.

;;; Code:

(doom! :input
       :completion
       (company +childframe)
       (vertico +childframe +icons)

       :ui
       doom
       doom-dashboard
       (emoji +ascii +unicode +github) ; 🙂
       hl-todo
       indent-guides
       ligatures
       modeline
       ophints
       (popup +defaults)
       (treemacs +lsp)

       :editor
       (evil +everywhere)
       file-templates
       snippets

       :emacs
       (dired +icons)
       (ibuffer +icons)
       vc

       :checkers
       (syntax +childframe)

       :tools
       (eval +overlay)
       (lookup +dictionary)
       (lsp +peek)
       magit
       tree-sitter

       :os
       tty

       :lang
       emacs-lisp
       org
       (rust +lsp +tree-sitter)
       (sh +lsp +tree-sitter)
       yaml

       :config
       (default +bindings +smartparens))
