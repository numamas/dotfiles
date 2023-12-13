;; init.el -*- lexical-binding: t; -*-
(progn "profile"
  (defvar engrave-tick-previous-time before-init-time)

  (defun engrave-tick (msg)
    (let ((ctime (current-time)))
      (let ((inhibit-message t))
        (message "-- %5.1f[ms] %s"
                 (* 1000 (float-time (time-subtract ctime engrave-tick-previous-time)))
                 msg))
      (setq engrave-tick-previous-time ctime)))

  (defun engrave-total-tick ()
    (message "startup time: %.3f[ms] (restored from pdump in %.3f[ms])"
             (* 1000 (float-time (time-subtract engrave-tick-previous-time before-init-time)))
             (* 1000 (assoc-default 'load-time (pdumper-stats)))))

  (mapc (lambda (x) (add-hook x (lambda () (engrave-tick (format "at the end of %s" x))) t))
        '(after-init-hook tty-setup-hook emacs-startup-hook window-setup-hook))

  (add-hook 'window-setup-hook 'engrave-total-tick t)

  (engrave-tick "start"))

(progn "elpaca"
  (defvar elpaca-installer-version 0.5)
  (defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
  (defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
  (defvar elpaca-repos-directory (expand-file-name "repos/" elpaca-directory))
  (defvar elpaca-order '(elpaca :repo "https://github.com/progfolio/elpaca.git"
                                :ref nil
                                :files (:defaults (:exclude "extensions"))
                                :build (:not elpaca--activate-package)))
  (let* ((repo  (expand-file-name "elpaca/" elpaca-repos-directory))
         (build (expand-file-name "elpaca/" elpaca-builds-directory))
         (order (cdr elpaca-order))
         (default-directory repo))
    (add-to-list 'load-path (if (file-exists-p build) build repo))
    (unless (file-exists-p repo)
      (make-directory repo t)
      (when (< emacs-major-version 28) (require 'subr-x))
      (condition-case-unless-debug err
          (if-let ((buffer (pop-to-buffer-same-window "*elpaca-bootstrap*"))
                   ((zerop (call-process "git" nil buffer t "clone"
                                         (plist-get order :repo) repo)))
                   ((zerop (call-process "git" nil buffer t "checkout"
                                         (or (plist-get order :ref) "--"))))
                   (emacs (concat invocation-directory invocation-name))
                   ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
                                         "--eval" "(byte-recompile-directory \".\" 0 'force)")))
                   ((require 'elpaca))
                   ((elpaca-generate-autoloads "elpaca" repo)))
            (progn (message "%s" (buffer-string)) (kill-buffer buffer))
            (error "%s" (with-current-buffer buffer (buffer-string))))
        ((error) (warn "%s" err) (delete-directory repo 'recursive))))
    (unless (require 'elpaca-autoloads nil t)
      (require 'elpaca)
      (elpaca-generate-autoloads "elpaca" repo)
      (load "./elpaca-autoloads")))
  (add-hook 'after-init-hook #'elpaca-process-queues)
  (elpaca `(,@elpaca-order))

  ;; disable symlink feature on windows
  (when (eq system-type 'windows-nt)
    (elpaca-no-symlink-mode))

  ;; use-package support
  (elpaca elpaca-use-package
    (elpaca-use-package-mode)
    (setq elpaca-use-package-by-default t))

  ;; general
  (elpaca general)

  (defmacro enqueue (&rest args)
    (declare (indent defun))
    `(elpaca nil ,@args))

  ;; block until current queue processed.
  (elpaca-wait))

(engrave-tick "finish loading elpaca")

(enqueue 'emacs
  (defalias 'yes-or-no-p 'y-or-n-p)

  ;; suppression
  (defun display-startup-echo-area-message () nil)
  (setq suggest-key-bindings nil
        inhibit-startup-screen t
        package-enable-at-startup nil)

  ;; auto-save and backup
  (setq auto-save-default nil
	    create-lockfiles nil
	    make-backup-files nil
	    custom-file (locate-user-emacs-file "custom.el"))

  ;; indentation
  (setq-default tab-width 4
                c-basic-offset 4
                indent-tabs-mode nil)
  (setq sh-indent-for-case-label 0
        sh-indent-for-case-alt '+)

  ;; emacs-lisp indentation
  (mapc (lambda (x) (put x 'lisp-indent-function 'defun))
        '(if if-let when when-let progn))

  ;; TODO quit minibuffer with `esc'
  ;; (define-key minibuffer-local-map (kbd "ESC") #'abort-minibuffers)

  ;; line wrap
  (setq-default truncate-lines t)
  
  ;; disable centering while scrolling
  (setq scroll-conservatively 100
	    scroll-margin 2)

  ;; show-paren delay
  (custom-set-variables '(show-paren-delay 0))

  ;; vc
  (setq vc-handled-backends '(SVN Git))
  (setq vc-follow-symlinks t) ;; TODO What is different from `find-file-visit-truename'.

  ;; windows encoding
  (when (eq system-type 'windows-nt)
    (set-language-environment "Japanese")
    (prefer-coding-system 'utf-8)
    (set-file-name-coding-system 'cp932)
    (set-keyboard-coding-system 'cp932)
    (set-terminal-coding-system 'cp932)))

(enqueue 'elec-pair
  (electric-pair-mode t))

(enqueue 'global-line-numbers
  (setq display-line-numbers-width-start t
        display-line-numbers-grow-only t)
  (global-display-line-numbers-mode t))

(enqueue 'hideshow
  (add-hook 'prog-mode-hook #'hs-minor-mode)
  (add-hook 'nxml-mode-hook #'hs-minor-mode)

  (general-def 'normal hs-minor-mode-map
    "t"     #'my/hs-toggle-hiding
    "T"     #'my/hs-hide-same-level
    "C-t"   #'hs-hide-all
    "SPC t" #'hs-show-all)

  ;; nxml-mode rule [https://emacs.stackexchange.com/questions/2884]
  (add-to-list 'hs-special-modes-alist
               '(nxml-mode
                 "<!--\\|<[^/>?]*[^/]>"  ;; <?xml ... ?>
                 "-->\\|</[^/>]*[^/]>"
                 "<!--"
                 sgml-skip-tag-forward
                 nil))

  (defun my/hs-toggle-hiding ()
    (interactive)
    (save-excursion
      (move-beginning-of-line nil)
      (beginning-of-line-text)
      (hs-toggle-hiding)))

  (defun my/hs-hide-same-level ()
    (interactive)
    (save-excursion
      (move-beginning-of-line nil)
      (hs-hide-level 1))))

(enqueue 'recentf
  (setq recentf-max-saved-items 99
        recentf-auto-cleanup 'never
        recentf-exclude '(".emacs.d"))

  (let ((message-log-max nil))
    (with-temp-message (or (current-message) "")
      (recentf-mode t))))

(enqueue 'tab-line
  (general-def nil 'global
    "C-<prior>" #'my/previous-buffer
    "C-<next>"  #'my/next-buffer)

  (global-tab-line-mode t)

  (defun my/previous-buffer ()
    (interactive)
    (previous-buffer))

  (defun my/next-buffer ()
    (interactive)
    (next-buffer)))

(enqueue 'winner
  (general-def nil 'global
    "<prior>" #'winner-undo  ;; TODO
    "<next>"  #'winner-redo
    "C-,"     #'winner-undo
    "C-."     #'winner-redo)
  (winner-mode t))

;; (enqueue "clipboard"
;;   ;; https://unknownplace.org/blog/2020/09/01/sharing-clipboard-between-windows-and-emacs-on-wsl/
;;   (cond ((and (eq system-type 'gnu/linux)
;; 	      (getenv "WSLENV"))
;; 	 10)
;; 	((and (not (display-graphic-p))
;; 	      (getenv "DISPLAY"))
;; 	 (setq interprogram-cut-function #'xsel-cut-function)
;; 	 (setq interprogram-paste-function #'xsel-paste-function))
;; 	(t
;; 	 10)))

;;   (defun xsel-cut-function (text &optional push)
;;     (identity push)
;;     (with-temp-buffer
;;       (insert text)
;;       (call-process-region (point-min) (point-max) "xsel" nil nil nil "--clipboard" "--input")))

;;   (defun xsel-paste-function ()
;;     (let ((xsel-output (shell-command-to-string "xsel --clipboard --output")))
;;       (unless (string= (car kill-ring) xsel-output) xsel-output))))

;; TODO related to evil
(enqueue "evil-comment-toggle"
  (general-def nil 'global
    "C-_" #'my/comment-toggle
    "C-/" #'my/comment-toggle)
  
  (defun my/comment-toggle ()
    (interactive)
    (let (beg end)
      (if (or (evil-visual-state-p) (region-active-p))
	    (setq beg (save-excursion (goto-char (region-beginning))
				                  (line-beginning-position))
	          end (save-excursion (goto-char (1- (region-end)))  ;; evil-visual-blockだと region-end が範囲の次の行頭になる
				                  (line-end-position)))
	    (setq beg (line-beginning-position)
	          end (line-end-position)))
      (comment-or-uncomment-region beg end))))

(enqueue "evil-keymaps"
  (general-def nil 'global
    "C-s" #'consult-line)
  
  (general-def 'normal 'global
    "SPC"   nil
    "SPC -" #'split-window-below
    "SPC /" #'split-window-right
    "SPC ;" #'my/consult-buffer-no-preview
    "SPC c" (lambda () (interactive) (kill-buffer (current-buffer)) (delete-window))
    "SPC e" #'find-file
    "SPC k" #'kill-buffer
    "SPC n" #'evil-ex-nohighlight
    "SPC o" #'delete-other-windows
    "SPC p" #'my/consult-yank-pop-evil
    "SPC w" #'toggle-truncate-lines))

(enqueue "tmux-navigate"
  (general-def nil 'global
    "M-k" (lambda () (interactive) (tmux-navigate "up"))
    "M-j" (lambda () (interactive) (tmux-navigate "down"))
    "M-h" (lambda () (interactive) (tmux-navigate "left"))
    "M-l" (lambda () (interactive) (tmux-navigate "right")))
  
  (defun tmux-navigate (direction)
    (let ((cmd (concat "windmove-" direction)))
      (condition-case nil
	      (funcall (read cmd))
	    (error
	     (tmux-command direction)))))

  (defun tmux-command (direction)
    (shell-command-to-string
     (concat "tmux select-pane -" (upcase (substring direction 0 1))))))

(use-package evil
  :preface
  (setq evil-search-module 'evil-search)
  (setq evil-ex-search-vim-style-regexp t)
  (setq evil-want-C-u-scroll t)
  (setq evil-want-C-u-delete t)
  (setq evil-undo-system 'undo-redo)
  :init
  (evil-mode t)
  :config
  ;; highlight current line in insert state
  (add-hook 'evil-insert-state-entry-hook #'hl-line-mode)
  (add-hook 'evil-insert-state-exit-hook  (lambda () (hl-line-mode -1)))
  
  ;; use blackhole register with `x' and `c'
  (evil-define-operator advice/evil-change-with-blackhole (fn beg end &optional type _register &rest args)
    (apply fn beg end type ?_ args))
  (defun advice/evil-with-blackhole (fn beg end &optional type _register &rest args)
    (apply fn beg end type ?_ args))
  (advice-add 'evil-delete-char :around #'advice/evil-with-blackhole)
  (advice-add 'evil-change-line :around #'advice/evil-with-blackhole)
  (advice-add 'evil-change      :around #'advice/evil-change-with-blackhole)

  ;; discard selection with `p' in visual, equivalent to [vnoremap p "_xP]
  (defun evil-visual-paste-with-blackhole ()
    "Paste and discard the replaced string"
    (interactive)
    (when (evil-visual-state-p)
      (delete-region (region-beginning) (region-end))
      (evil-exit-visual-state)
      (evil-paste-before 1)))
  (evil-define-key 'visual 'global
    "p" 'evil-visual-paste-with-blackhole)

  ;; amalgamate undo records of evil-delete-char
  (defun advice/auto-amalgamate (fn &rest args)
    (undo-auto-amalgamate)
    (apply fn args))
  (advice-add 'evil-delete-char :around #'advice/auto-amalgamate)

  ;; keep cursor position with `*'
  (defun advice/keep-position (fn &rest args)
    (save-excursion
      (apply fn args)))
  (advice-add 'evil-ex-search-word-forward :around 'advice/keep-position)

  ;; visualstar
  (evil-define-operator evil-visualstar (beg end)
    "Search and highlight with a selection"
    (interactive "<r>")
    (let* ((selection (buffer-substring-no-properties beg end))
	       (pattern (evil-ex-make-search-pattern (regexp-quote selection))))
      (evil-exit-visual-state)
      (setq evil-ex-search-pattern pattern)
      (evil-ex-search-activate-highlight pattern)
      ;; push history
      (unless (equal (car-safe evil-ex-search-history) selection)
	    (push selection evil-ex-search-history))))
  (evil-define-key 'visual 'global "*" 'evil-visualstar))

(use-package evil-escape
  :init
  (with-eval-after-load 'evil
    (evil-define-key '(insert replace visual operator) 'global
      (kbd "C-g") #'evil-escape)))

(use-package evil-surround
  :init
  (global-evil-surround-mode t))

(use-package flymake-popon
  ;; TODO
  :hook
  (prog-mode . flymake-popon-mode)
  :init
  (add-hook 'evil-insert-state-entry-hook (lambda () (flymake-popon-mode -1)))
  (add-hook 'evil-insert-state-exit-hook  (lambda () (flymake-popon-mode t))))

(use-package consult
  :init
  (setq consult-buffer-filter
        '("\\` "
          "\\`\\*Completions\\*\\'"
          "\\`\\*Flymake log\\*\\'"
          "\\`\\*Semantic SymRef\\*\\'"
          "\\`\\*tramp/.*\\*\\'"
          "\\`\\*"
          "\\*dired\\*"

          "\\`magit:.*"
          "history"))

  (defun my/consult-buffer-no-preview ()
    (interactive)
    (defvar consult-preview-key)
    (let ((consult-preview-key nil))
      (consult-buffer)))

  (defun my/consult-yank-pop-evil ()
    (interactive)
    (save-excursion
      (forward-char 1)
      (consult-yank-pop))))

(use-package doom-themes
  :init
  (load-theme 'doom-dracula t))

(use-package marginalia
  :init
  (marginalia-mode t))

(use-package mood-line
  :custom
  (mood-line-show-eol-style t)
  (mood-line-show-encoding-information t)
  :init
  (mood-line-mode t))

(use-package orderless
  :custom
  (completion-styles '(orderless))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles partial-completion))))
  (orderless-component-separator "[ ,]"))

(use-package shackle
  :custom
  (shackle-default-rule '(:align below :ratio 0.45))
  :init
  (shackle-mode t))

(use-package vertico
  :init
  (vertico-mode t)
  (savehist-mode t))

;; (use-package eglot
;;   )

(engrave-tick "finish loading init.el")
;; Local Variables:
;; no-byte-compile: t
;; no-native-compile: t
;; no-update-autoloads: t
;; End:

;; (enqueue 'icomplete
;;   (fido-vertical-mode t)
;;   (savehist-mode t))

;; (use-package standard-themes
;;   :init
;;   (load-theme 'standard-dark t))
