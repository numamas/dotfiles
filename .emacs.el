(progn :elementary
  (defalias 'yes-or-nop 'y-or-n-p)
  (load-theme 'wombat t)
  (menu-bar-mode -1)
  (column-number-mode t)
  (global-display-line-numbers-mode t)
  (show-paren-mode t)
  (add-hook 'prog-mode-hook #'hs-minor-mode)
  (setq inhibit-startup-message t
	auto-save-default nil
	create-lockfiles nil
	make-backup-files nil
	custom-file (locate-user-emacs-file "custom.el") ;; (load custom-file)
	indent-tabs-mode nil
	kill-whole-line t
	show-paren-delay 0)
  
  ;; CUI
  (unless window-system
    ;; mouse
    (xterm-mouse-mode 1)
    (global-set-key [mouse-4] (lambda () (interactive) (scroll-down 5)))
    (global-set-key [mouse-5] (lambda () (interactive) (scroll-up 5)))
    ;; clipboard
    ;; https://unknownplace.org/blog/2020/09/01/sharing-clipboard-between-windows-and-emacs-on-wsl/
    (when (getenv "DISPLAY")
      (defun xsel-cut-function (text &optional push)
	(with-temp-buffer
	  (insert text)
	  (call-process-region (point-min) (point-max) "xsel" nil 0 nil "--clipboard" "--input")))
      (defun xsel-paste-function ()
	(let ((xsel-output (shell-command-to-string "xsel --clipboard --output")))
	  (unless (string= (car kill-ring) xsel-output) xsel-output)))
      (setq interprogram-cut-function 'xsel-cut-function)
      (setq interprogram-paste-function 'xsel-paste-function)))

  ;; GUI
  (when window-system
    (tool-bar-mode -1)
    (setq initial-frame-alist
	  (append (list '(height . 38)
			'(width  . 84)
			'(font   . "HackGen Console-12"))
		  initial-frame-alist))
    (setq default-frame-alist initial-frame-alist)))


(progn :command
  (defun toggle-comment ()
    "Comment/uncomment the current line or region."
    ;; https://stackoverflow.com/questions/9688748/emacs-comment-uncomment-current-line
    (interactive)
    (if (region-active-p)
      (comment-line 1)
      (comment-or-uncomment-region (line-beginning-position) (line-end-position))))

  (defun move-line-up ()
    "Move up the current line."
    (interactive)
    (transpose-lines 1)
    (forward-line -2)
    (indent-according-to-mode))

  (defun move-line-down ()
    "Move down the current line."
    (interactive)
    (forward-line 1)
    (transpose-lines 1)
    (forward-line -1)
    (indent-according-to-mode))

  (defun config-open ()
    (interactive)
    (find-file (expand-file-name "~/.emacs.el")))

  (defun config-reload ()
    (interactive)
    (load-file (expand-file-name "~/.emacs.el"))))


(progn :package
  (require 'package)
  (add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
  (package-initialize)
  (unless (package-installed-p 'use-package)
    (package-refresh-contents)
    (package-install 'use-package))
  (require 'use-package)
  (setq use-package-always-ensure t))


(progn :appearance
  (use-package railscasts-reloaded-theme
    :init
    (load-theme 'railscasts-reloaded t))
  (use-package simple-modeline
    :hook
    (after-init . simple-modeline-mode))
  (use-package rainbow-delimiters
    :init
    (add-hook 'prog-mode-hook #'rainbow-delimiters-mode)))


(use-package bind-key
  :init
  (use-package evil)
  :config
  (bind-keys* ("M-;"      . toggle-comment)
              ("C-_"      . toggle-comment)
              ("C-/"      . toggle-comment)
              ("M-<up>"   . move-line-up)
              ("M-<down>" . move-line-down)
              ("C-q"      . winner-undo))

  (bind-keys* :prefix-map my-prefix-c-k-map
              :prefix "C-k"
              ("C-e" . julia-repl-send-region-or-line)
              ("e"   . julia-repl-send-buffer)

	      ("C-r" . sp-raise-sexp)
	      ("C-@" . sp-splice-sexp)
	      ("C-s" . sp-splice-sexp)
              ("C-l" . sp-forward-slurp-sexp)
              ("C-h" . sp-forward-barf-sexp)
              ("("   . sp-wrap-round)
              ("["   . sp-wrap-square)
              ("{"   . sp-wrap-curly)

              ;; ("C-j" . hs-toggle-hiding)
              ;; ("C-k" . hs-hide-all)
              ;; ("C-l" . hs-show-all)
              )

  (bind-keys :map evil-normal-state-map
	     ("*" . swiper-thing-at-point)
	     ("t" . hs-toggle-hiding)
	     ("T" . hs-hide-all)
	     ("C-t" . hs-show-all))

  (bind-keys :map evil-motion-state-map
  	     ("H" . back-to-indentation)
  	     ("L" . move-end-of-line))
  )


(use-package ivy
  :init
  (use-package swiper)   ;; search interface
  (use-package counsel)  ;; presets
  (ivy-mode 1)
  :config
  (setq ivy-ignore-buffers '("\\` " "\\`\\*" "\\*dired\\*" "history"))
  (setq swiper-include-line-number-in-search t)
  (set-face-attribute 'ivy-minibuffer-match-face-1 nil :foreground "#999999")
  (set-face-attribute 'ivy-minibuffer-match-face-2 nil :foreground "#e04444" :underline t)
  (set-face-attribute 'ivy-minibuffer-match-face-3 nil :foreground "#7777ff" :underline t)
  (set-face-attribute 'ivy-minibuffer-match-face-4 nil :foreground "#33bb33" :underline t))


(use-package evil
  :init
  (setq evil-search-module 'evil-search
        evil-ex-search-vim-style-regexp t
        evil-esc-delay 0
        evil-want-C-u-scroll t)
  (evil-mode 1)
  :config
  (setq evil-insert-state-map (make-sparse-keymap)) ;; enable emacs-keybind on insert-state
  (bind-keys* ("C-o" . point-undo))
  (bind-keys :map key-translation-map
             ("C-c" . evil-escape-or-quit)
             :map evil-operator-state-map
             ("C-c" . evil-escape-or-quit)
             :map evil-normal-state-map
             ("<escape>" . keyboard-quit)
             :map evil-insert-state-map
             ("<escape>" . evil-normal-state))

  (defun evil-escape-or-quit (&optional prompt)
    ;; https://tarao.hatenablog.com/entry/20130304/evil_config#vim-c-c
    (interactive)
    (cond
      ((or (evil-normal-state-p)
           (evil-insert-state-p)
           (evil-replace-state-p)
           (evil-visual-state-p))
       [escape])
      (t (kbd "C-g")))))


(use-package evil-leader
  :init
  (global-evil-leader-mode)
  :config
  (evil-leader/set-leader "<SPC>")
  (evil-leader/set-key
    "0" 'evil-ex-nohighlight
    "w" 'toggle-truncate-lines
    "f" 'find-file
    "s" 'swiper
    "g" 'counsel-rg
    ";" 'ivy-switch-buffer
    ;; ":" 'exexute-extended-command
    ))


(use-package evil-mc
  :init
  (global-evil-mc-mode t)
  :config
  (evil-define-key 'normal evil-mc-key-map
    (kbd "<escape>") 'evil-mc-undo-all-cursors)
  (evil-define-key 'visual evil-mc-key-map
    "A" #'evil-mc-make-cursor-in-visual-selection-end
    "I" #'evil-mc-make-cursor-in-visual-selection-beg
    "n" #'evil-mc-make-visual-cursors)

  (defun evil-mc-make-visual-cursors ()
    (interactive)
    (evil-mc-make-cursor-in-visual-selection-end)
    (execute-kbd-macro (kbd "<escape>"))))


(use-package smartparens
  :config
  (require 'smartparens-config)
  (smartparens-global-mode t))


(use-package shackle
  :init
  (setq shackle-default-rule '(:align below :ratio 0.4))
  (winner-mode t))


(use-package company
  :config
  (global-company-mode))


(use-package eglot
  :config
  (bind-keys* ("<F12>" . xref-find-definitions)
              ("<F11>" . pop-tag-mark)))


(use-package go-mode
  ;; go get -u golang.org/x/tools/gopls
  ;; go get -u golang.org/x/tools/cmd/goimports
  :config
  (setq gofmt-command "goimports")
  (add-hook 'before-save-hook 'gofmt-before-save)
  (add-to-list 'eglot-server-programs
	       '(go-mode . ("gopls"))))


(use-package julia-mode
  ;; julia -e 'using Pkg; Pkg.add("LanguageServer"); exit()'
  :init
  (use-package julia-repl)
  (add-hook 'julia-mode-hook 'julia-repl-mode)
  (add-to-list 'eglot-server-programs
	       '(julia-mode . ("julia" "-e using LanguageServer, LanguageServer.SymbolServer; runserver()")))
  :config
  (bind-keys* ("C-e" . julia-repl-send-region-or-line)
	      ("C-A-e" . julia-repl-send-buffer)))
  

(use-package org
  :config
  (defun concat-with-newline (&rest strings)
    (mapconcat #'identity strings "\n"))

  (setq org-latex-with-hyperref nil)  ;; disable '\hypersetup{}'

  (setq org-latex-pdf-process '("lualatex --draftmode %f" "lualatex %f"))
  (when (eq system-type 'windows-nt)
    (setq org-latex-pdf-process (mapcar #'(lambda (s) (concat "wsl " s)) org-latex-pdf-process)))

  (require 'ox-latex)
  (with-eval-after-load 'ox-latex
    (add-to-list 'org-latex-classes
		 `("ltjarticle"
		   ,(concat-with-newline "\\documentclass{ltjarticle}"
                                      ;; "[NO-PACKAGES]"
				      ;; "[NO-DEFAULT-PACKAGES]"
				      ;; "\\usepackage[dvipdfmx]{graphicx}"
					 )
		   ("\\section{%s}"       . "\\section*{%s}")
		   ("\\subsection{%s}"    . "\\subsection*{%s}")
		   ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
		   ("\\paragraph{%s}"     . "\\paragraph*{%s}")
		   ("\\subparagraph{%s}"  . "\\subparagraph*{%s}"))))

  (bind-keys* :map org-mode-map
              ("C-x i i" . skele-org-init)
              ("C-x i f" . skele-org-figure)
              ("C-x i t" . skele-org-table)
              ("C-x i l" . skele-org-latex-block)
              ("C-x i s" . skele-org-source-block)
	      ("C-x e p" . org-latex-export-to-pdf)
              ("C-x e l" . org-latex-export-to-latex)
              ("C-x e L" . org-latex-export-as-latex))

  (defun skele-org-init (title)
    ;; https://tamura70.hatenadiary.org/entry/20100304/org
    ;; https://orgmode.org/manual/Export-Settings.html
    (interactive "sTitle: ")
    (skeleton-insert
     '("" nil
       "#+TITLE: " title                                                                               > \n
       "#+AUTHOR:"                                                                                     > \n
       "#+DATE: \\today"                                                                               > \n
       "#+OPTIONS: toc:nil title:t num:t ^:{} author:nil creator:nil timestamp:nil"                    > \n
       "#+LATEX_CLASS: ltjarticle"                                                                     > \n
       "#+LATEX_CLASS_OPTIONS: [a4j,10pt]"                                                             > \n
       "#+LATEX_HEADER: \\renewcommand{\\today}{\\number\\year 年\\number\\month 月\\number\\day 日}"  > \n
       ""                                                                                              > \n
       )))
  
  (defun skele-org-figure (caption path)
    (interactive "sCaption: \nsFilepath: ")
    (skeleton-insert
     '("" nil
       "#+CAPTION: " caption                > \n
       "#+NAME: fig:" (file-name-base path) > \n
       "#+ATTR_LaTeX: :width 10cm"          > \n
       "file:" path                         > \n
       ""                                   > \n
       )))
  
  (defun skele-org-table (caption label)
    (interactive "sCaption: \nsLabel: ")
    (skeleton-insert
     '("" nil
       "#+CAPTION: " caption        > \n
       "#+NAME: tb:" label          > \n 
       "#+ATTR_LaTeX: :align |l|l|" > \n
       ""                           > \n
       )))
  
  (defun skele-org-latex-block ()
    (interactive)
    (skeleton-insert
     '("" nil
       "#+BEGIN_LaTeX" > \n
       _               > \n
       "#+END_LaTeX"   > \n
       ""              > \n
       )))
  
  (defun skele-org-source-block (lang)
    (interactive "sLanguage: ")
    (skeleton-insert
     '("" nil
       "#+BEGIN_SRC " lang > \n
       _                   > \n
       "#+END_SRC"         > \n
       ""                  > \n
       ))))

