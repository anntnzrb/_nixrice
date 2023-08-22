;;; $DOOMDIR/lib/ui.el -*- lexical-binding: t; -*-

;;; Commentary:

;; UI related settings

;;; Code:

(setq doom-theme 'nil)

(use-package! modus-themes
  :init
  (load-theme 'modus-vivendi t t) ;; load theme; don't enable yet
  :config
  (setq modus-themes-links             '(background italic))
  (setq modus-themes-region            '(no-extend bg-only accented))
  (setq modus-themes-syntax            '(green-strings yellow-comments))
  (setq modus-themes-mode-line         '(accented borderless))
  (setq modus-themes-org-blocks        'greyscale)
  (setq modus-themes-paren-match       '(bold underline))
  (setq modus-themes-lang-checkers     'straight-underline)
  (setq modus-themes-bold-constructs   t)
  (setq modus-themes-italic-constructs t)

  (map! "M-<f5>" #'modus-themes-toggle)

  ;; if running via GUI, prefer light or dark theme depending on daytime
  ;; else (terminal) prefer dark mode
  (let ((time (string-to-number (format-time-string "%H"))))
    (if (and (display-graphic-p) (and (> time 9) (< time 18)))
        (modus-themes-load-operandi)
      (modus-themes-load-vivendi))))

(let* ((main-font      "mononoki")
       (main-font-size         18)
       (main-font-weight 'regular)

       (variable-pitch-font        "Iosevka")
       (variable-pitch-font-size   main-font-size)
       (variable-pitch-font-weight main-font-weight)

       (big-font        main-font)
       (big-font-size   (* main-font-size 2))
       (big-font-weight main-font-weight))
  (setq doom-font
        (font-spec
         :family main-font
         :size   main-font-size
         :weight main-font-weight))
  (setq doom-variable-pitch-font
        (font-spec :family variable-pitch-font
                   :size   variable-pitch-font-size
                   :weight variable-pitch-font-weight))
  (setq doom-big-font
        (font-spec :family big-font
                   :size   big-font-size
                   :weight big-font-weight)))
