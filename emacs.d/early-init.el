;; early-init.el -*- lexical-binding: t; -*-

;; inhibit garbage collection while startup
(setq gc-cons-threshold most-positive-fixnum)
(add-hook 'emacs-startup-hook (lambda () (setq gc-cons-threshold 16777216)))

;; disable package.el
(setq package-enable-at-startup nil)

;; user interface
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(setq frame-inhibit-implied-resize t)

;; Local Variables:
;; no-byte-compile: t
;; no-native-compile: t
;; no-update-autoloads: t
;; End:
