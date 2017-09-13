;;; helm-code-skeleton.el --- Search code skeleton with helm interface  -*- lexical-binding: t; -*-

;; Copyright (C) 2017 by Ryo Fujimoto

;; Author: Ryo Fujimoto <fujimisakri@gmail.com>
;; URL: https://github.com/fujimisakari/emacs-helm-code-skeleton
;; Version: 1.0.1
;; Package-Requires: ((helm "1.5") (emacs "24"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; `helm-code-skeleton.el' will be able to use code skeleton through helm interface
;;

;; To use this package, add these lines to your init.el or .emacs file:
;;
;;  (when (require 'helm-code-skeleton nil t)
;;    (require 'skeleton)
;;    (setq helm-code-skeleton-dir-root-path "~/.emacs.d/code-skeletons")
;;    (helm-code-skeleton-load))
;;
;; ----------------------------------------------------------------
;;
;; to search code skeleton
;; M-x helm-code-skeleton-search
;;

;;; Code:

(require 'helm)
(require 'helm-utils)

(defgroup helm-code-skeleton nil
  "Search code skeleton with helm interface"
  :group 'helm)

(defcustom helm-code-skeleton-dir-root-path nil
  "Code directory root path"
  :group 'helm-code-skeleton)

(defcustom helm-code-skeleton-exclude-load-regex ".*\\(php-mode.el\\|php-mode-pkg.el\\|php-mode-autoloads.el\\)$"
  "Exclude load file name
e.g. .*\\(php-mode.el\\|php-mode-pkg.el\\|php-mode-autoloads.el\\)$"
  :group 'helm-code-skeleton)

(defcustom helm-code-skeleton-maximum-candidates 200
  "Maximum number of helm candidates"
  :type 'integer
  :group 'helm-code-skeleton)

(defcustom helm-code-skeleton-log-level -1
  "Logging level, only messages with level lower or equal will be logged.
-1 = NONE, 0 = ERROR, 1 = WARNING, 2 = INFO, 3 = DEBUG"
  :type 'integer
  :group 'helm-code-skeleton)

(defvar helm-code-skeleton--candidates-cache '()
  "Candidates Cache")

(defvar helm-code-skeleton--current-mode nil
  "Mode in use")

(defconst helm-code-skeleton--buffer "*helm code skeleton*")

(defun helm-code-skeleton-log (level text &rest args)
  "Log a message at level LEVEL.
If LEVEL is higher than `helm-code-skeleton-log', the message is
ignored.  Otherwise, it is printed using `message'.
TEXT is a format control string, and the remaining arguments ARGS
are the string substitutions (see `format')."
  (if (<= level helm-code-skeleton-log-level)
      (let* ((msg (apply 'format text args)))
        (message "%s" msg))))

(defun helm-code-skeleton--get-candidates-cache (mode)
  (assoc-default mode helm-code-skeleton--candidates-cache))

(defun helm-code-skeleton--set-candidates-cache (mode candidates)
  (add-to-list 'helm-code-skeleton--candidates-cache `(,mode . ,candidates)))

(defun helm-code-skeleton--get-mode-dir-list ()
  (let ((cmd (format "ls --ignore '*.md' %s" (file-name-as-directory helm-code-skeleton-dir-root-path)))
        (result))
    (dolist (mode-dir (split-string (shell-command-to-string cmd) "\n"))
      (if (> (length mode-dir) 0)
          (setq result (cons mode-dir result))))
    result))

(defun helm-code-skeleton--get-mode-dir-path(mode)
  (format "%s%s" (file-name-as-directory helm-code-skeleton-dir-root-path) mode))

(defun helm-code-skeleton--construct-command-for-search (mode)
  (let* ((cmd "ls")
         (dir-path (helm-code-skeleton--get-mode-dir-path mode))
         (path (concat (file-name-as-directory dir-path) "*.el"))
         (opt "| xargs grep -r 'define-skeleton' | sed -e 's/.*define-skeleton //g'")
         (cmds (list cmd path opt)))
    (mapconcat 'identity cmds " ")))

(defun helm-code-skeleton--construct-command-for-load (mode)
  (let* ((cmd "ls")
         (dir-path (helm-code-skeleton--get-mode-dir-path mode))
         (path (concat (file-name-as-directory dir-path) "*.el"))
         (cmds (list cmd path)))
    (mapconcat 'identity cmds " ")))

(defun helm-code-skeleton--excecute-command (cmd-str)
  (let ((call-shell-command-fn 'shell-command-to-string))
    (helm-code-skeleton-log 3 "shell command: %s" cmd-str)
    (funcall call-shell-command-fn cmd-str)))

(defun helm-code-skeleton--get-candidates ()
  (let* ((current-mode helm-code-skeleton--current-mode)
         (candidates-cache (helm-code-skeleton--get-candidates-cache current-mode)))
    (if (null candidates-cache)
        (let* ((ret (helm-code-skeleton--excecute-command (helm-code-skeleton--construct-command-for-search current-mode)))
               (candidates (split-string ret "\n"))
               (candidates (sort candidates 'string<))
               (candidates (cl-remove-if (lambda (s) (string-match ".*define-skeleton.*" s)) candidates)))
          (helm-code-skeleton--set-candidates-cache current-mode candidates)
          candidates)
      candidates-cache)))

(defun helm-code-skeleton--funcall (func-name)
  (let((func (intern-soft func-name)))
    (helm-code-skeleton-log 3 (format "func-name: %s" func-name))
    (if (fboundp func)
        (funcall func)
      (error (format "%s is not load." func-name)))))

(defun helm-code-skeleton--search-init ()
  (let ((buf-coding buffer-file-coding-system))
    (with-current-buffer (helm-candidate-buffer 'global)
      (let ((coding-system-for-read buf-coding)
            (coding-system-for-write buf-coding))
        (mapc (lambda (row) (insert (concat row "\n"))) (helm-code-skeleton--get-candidates))))))

(defvar helm-source-code-skeleton-search
  (helm-build-in-buffer-source "Search code skeleton"
    :init 'helm-code-skeleton--search-init
    :candidate-number-limit helm-code-skeleton-maximum-candidates
    :action 'helm-code-skeleton--funcall))

;;;###autoload
(defun helm-code-skeleton-cache-clear ()
  (interactive)
  (setq helm-code-skeleton--candidates-cache '()))

;;;###autoload
(defun helm-code-skeleton-load ()
  (interactive)
  (unless helm-code-skeleton-dir-root-path
    (error "Dose not set 'helm-code-skeleton-dir-root-path'."))
  (helm-code-skeleton-cache-clear)
  (dolist (mode (helm-code-skeleton--get-mode-dir-list))
    (helm-code-skeleton-log 3 "mode: %s" mode)
    (let* ((ret (helm-code-skeleton--excecute-command (helm-code-skeleton--construct-command-for-load mode)))
           (file-path-list (split-string ret "\n"))
           (file-path-list (cl-remove-if (lambda (s) (string-match helm-code-skeleton-exclude-load-regex s)) file-path-list)))
      (dolist (file-path file-path-list)
        (helm-code-skeleton-log 3 "file-path: %s" file-path)
        (if (> (length file-path) 0) (load file-path)))))
  (message "helm-code-skeleton-load done."))

;;;###autoload
(defun helm-code-skeleton-search ()
  "Search code skeleton"
  (interactive)
  (unless helm-code-skeleton-dir-root-path
    (error "Dose not set 'helm-code-skeleton-dir-root-path'."))
  (unless (file-directory-p (helm-code-skeleton--get-mode-dir-path major-mode))
    (error (format "Dose not exsist skeleton directory path on '%s'." major-mode)))
  (setq helm-code-skeleton--current-mode major-mode)
  (helm :sources '(helm-source-code-skeleton-search) :buffer helm-code-skeleton--buffer))

(provide 'helm-code-skeleton)

;;; helm-code-skeleton.el ends here
