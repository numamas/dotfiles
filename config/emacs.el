;;; -*- lexical-binding: t -*-

(progn :emacs
  (defalias 'yes-or-no-p 'y-or-n-p)
  (load-theme 'wombat t)
  (menu-bar-mode -1)
  (column-number-mode)
  (global-display-line-numbers-mode)
  (winner-mode)
  (show-paren-mode)
  (recentf-mode)
  (add-hook 'prog-mode-hook #'hs-minor-mode)
  (setq-default tab-width 4
                indent-tabs-mode nil
                truncate-lines t)
  (setq auto-save-default nil
        create-lockfiles nil
        make-backup-files nil
        custom-file (locate-user-emacs-file "custom.el"))
  (setq display-line-numbers-width-start t)
  (setq show-paren-delay 0)
  (setq vc-follow-symlinks t)
  ;; (load custom-file)
  ;; (setq lisp-indent-function 'common-lisp-indent-function) ;; malfunction
  (put 'progn 'lisp-indent-function 'defun)
  (put 'if 'lisp-ident-function 'defun)
  (put 'general-define-key 'lisp-indent-function 'defun))

(progn :CUI
  (unless window-system
    (xterm-mouse-mode 1)
    (global-set-key [mouse-4] (lambda () (interactive) (scroll-down 5)))
    (global-set-key [mouse-5] (lambda () (interactive) (scroll-up 5)))
    ;; clipboard
    ;; https://unknownplace.org/blog/2020/09/01/sharing-clipboard-between-windows-and-emacs-on-wsl/
    (when (getenv "DISPLAY")
      (defun xsel-cut-function (text &optional push)
        (identity push)
        (with-temp-buffer
          (insert text)
          (call-process-region (point-min) (point-max) "xsel" nil 0 nil "--clipboard" "--input")))
      (defun xsel-paste-function ()
        (let ((xsel-output (shell-command-to-string "xsel --clipboard --output")))
          (unless (string= (car kill-ring) xsel-output) xsel-output)))
      (setq interprogram-cut-function 'xsel-cut-function)
      (setq interprogram-paste-function 'xsel-paste-function))))

(progn :GUI
  (when window-system
    (tool-bar-mode -1)
    (setq initial-frame-alist
          (append (list '(height . 38)
                        '(width  . 100)
                        '(font   . "HackGen Console-11"))
                  initial-frame-alist))
    (setq default-frame-alist initial-frame-alist)))

(progn :package
  (require 'package)
  (add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
  (package-initialize)
  (unless (package-installed-p 'use-package)
    (package-refresh-contents)
    (package-install 'use-package))
  (require 'use-package)
  (setq use-package-always-ensure t))

(use-package general
  :init
  ;; q / g / @
  (general-define-key
    "C-_" #'evilnc-comment-or-uncomment-lines
    "C-q" #'winner-undo
    "C-M-q" #'winner-redo)
  (general-define-key :states 'motion
    "H" #'back-to-indentation
    "L" #'move-end-of-line
    "s" #'evil-snipe-F)
  (general-define-key :states 'normal
    "s" nil
    "," nil
    "+" #'evil-repeat-find-char-reverse
    "*" #'swiper-thing-at-point
    "t" #'hs-toggle-hiding
    "T" #'hs-hide-all
    "C-t" #'hs-show-all)
  (general-define-key :states 'normal
    "m" nil
    "m @" #'sp-splice-sexp
    "m s" #'sp-splice-sexp
    "m r" #'sp-raise-sexp
    "m ." #'sp-forward-slurp-sexp
    "m ," #'sp-forward-barf-sexp
    "m (" #'sp-wrap-round
    "m [" #'sp-wrap-sqaure
    "m {" #'sp-wrap-curly)
  (general-define-key :states 'normal
    "SPC" nil
    "SPC 0" #'evil-ex-nohighlight
    "SPC ;" #'ivy-switch-buffer
    "SPC :" #'execute-extended-command
    "SPC f" #'find-file
    "SPC g" #'counsel-rg
    "SPC j" #'avy-goto-char-2
    "SPC k" #'kill-buffer
    "SPC r" #'counsel-recentf
    "SPC s" #'swiper
    "SPC w" #'toggle-truncate-lines
    "SPC e e" #'set-buffer-file-coding-system
    "SPC e r" #'revert-buffer
    "SPC e t" #'counsel-major
    "SPC q e" (lambda () (interactive) (find-file (expand-file-name "~/.emacs.el")))
    "SPC q r" (lambda () (interactive) (load-file (expand-file-name "~/.emacs.el")))))

(use-package diminish
  :init
  (defmacro safe-diminish (file mode)
    `(with-eval-after-load ,file
       (diminish, mode)))
  :config
  (safe-diminish "hideshow" 'hs-minor-mode))

(use-package evil
  :init
  (setq evil-want-C-u-scroll t
        evil-search-module 'evil-search
        evil-ex-search-vim-style-regexp t)
  ;; (setq evil-insert-state-map (make-sparse-keymap)) ;; enable emacs-keybind on insert-state
  ;; (define-key evil-insert-state-map [escape] #'evil-normal-state)
  (evil-mode 1)
  :config
  (define-key key-translation-map (kbd "C-c") #'evil-escape-or-quit)
  (define-key evil-operator-state-map (kbd "C-c") #'evil-escape-or-quit)
  (define-key evil-normal-state-map [escape] #'keyboard-quit)
  (defun evil-escape-or-quit (&optional prompt)
    ;; https://tarao.hatenablog.com/entry/20130304/evil_config#vim-c-c
    (interactive)
    (identity prompt)
    (cond
     ((or (evil-normal-state-p)
          (evil-insert-state-p)
          (evil-replace-state-p)
          (evil-visual-state-p))
      [escape])
     (t (kbd "C-g")))))

(use-package evil-mc
  ;; :diminish evil-mc-mode
  :init
  (setq evil-mc-key-map (make-sparse-keymap)
        evil-mc-one-cursor-show-mode-line-text nil
        evil-mc-enable-bar-cursor nil)
  (global-evil-mc-mode t)
  :config
  (evil-define-key 'normal evil-mc-key-map
    (kbd "<escape>") 'evil-mc-undo-all-cursors)

  (evil-define-key 'visual evil-mc-key-map
    "A" #'evil-mc-make-cursor-in-visual-selection-end
    "I" #'evil-mc-make-cursor-in-visual-selection-beg
    "i" #'evil-mc-make-cursor-in-visual-selection-beg
    "n" #'evil-mc-make-visual-cursors)

  (evil-define-key 'normal evil-mc-key-map
    "i" #'my/evil-mc-resume-and-insert
    "n" #'evil-mc-resume-cursors
    (kbd "SPC SPC") #'my/evil-mc-make-cursor-and-pause
    (kbd "C-n")   #'evil-mc-make-and-goto-next-match
    (kbd "C-p")   #'evil-mc-make-and-goto-prev-match
    (kbd "C-M-n") #'evil-mc-skip-and-goto-next-match
    (kbd "C-M-p") #'evil-mc-skip-and-goto-prev-match
    (kbd "C-M-u") #'evil-mc-undo-last-added-cursor)

  (defun my/evil-mc-make-visual-cursors ()
    (interactive)
    (evil-mc-make-cursor-in-visual-selection-end)
    (execute-kbd-macro (kbd "<escape>")))

  (defun my/evil-mc-resume-and-insert ()
    (interactive)
    (evil-mc-resume-cursors)
    (evil-insert 0))

  (defun my/evil-mc-make-cursor-and-pause ()
    (interactive)
    (evil-mc-make-cursor-here)
    (evil-mc-pause-cursors)))

(use-package ivy
  :diminish ivy-mode
  :init
  (use-package swiper)
  (use-package counsel)
  (ivy-mode 1)
  :config
  (setq ivy-ignore-buffers '("\\` " "\\`\\*" "\\*dired\\*" "history"))
  (setq swiper-include-line-number-in-search t))

(use-package company
  :diminish company-mode
  :init
  (setq company-idle-delay 0
        company-minimum-prefix-length 2
        company-selection-wrap-around t
        completion-ignore-case t)
  (global-company-mode))

(use-package smartparens
  :diminish smartparens-mode
  :config
  (require 'smartparens-config)
  (smartparens-global-mode t))

(use-package shackle
  :init
  (setq shackle-default-rule '(:align below :ratio 0.4)))

(use-package avy)

(use-package evil-nerd-commenter)

(use-package evil-snipe
  :init
  (evil-snipe-override-mode))

(use-package tree-sitter
  :hook ((tree-sitter-after-on-hook . tree-sitter-hl-mode))
  :init
  (use-package tree-sitter-langs)
  :config
  (global-tree-sitter-mode))

(use-package eglot
  :diminish eldoc-mode
  :config
  (bind-keys* ("<F12>" . xref-find-definitions)
              ("<F11>" . pop-tag-mark)))

(use-package go-mode
  ;; go get -u golang.org/x/tools/gopls
  ;; go get -u golang.org/x/tools/cmd/goimports
  :hook ((go-mode . eglot-ensure)
         (before-save . gofmt-before-save))
  :config
  (setq gofmt-command "goimports")
  (add-to-list 'eglot-server-programs '(go-mode . ("gopls"))))

(use-package julia-mode
  ;; julia -e 'using Pkg; Pkg.add("LanguageServer"); exit()'
  :init
  (use-package julia-repl)
  (add-hook 'julia-mode-hook 'julia-repl-mode)
  (add-to-list 'eglot-server-programs
	       '(julia-mode . ("julia" "-e using LanguageServer, LanguageServer.SymbolServer; runserver()")))
  :config
  (general-define-key :states 'normal :keymaps 'julia-mode-map
    ", c" #'julia-repl
    ", e" #'julia-repl-send-region-or-line
    ", a" #'julia-repl-send-buffer)
  (general-define-key :states 'visual :keymaps 'julia-mode-map
    ", e" #'julia-repl-send-region-or-line))

(use-package clojure-mode
  :init
  (use-package cider)
  :config
  (general-define-key :states 'normal :keymaps 'clojure-mode-map
    ", c" #'cider-jack-in
    ", e" #'cider-eval-sexp-at-point
    ", a" #'cider-eval-buffer
    ", d" #'cider-eval-defun-at-point)
  (general-define-key :states 'visual :keymaps 'clojure-mode-map
    ", e" #'cider-eval-region))

