;;; counsel-projectile.el --- Ivy integration for Projectile

;; Copyright (C) 2016 Eric Danan

;; Author: Eric Danan
;; URL: https://github.com/ericdanan/counsel-projectile
;; Package-Version: 20170906.349
;; Created: 2016-04-11
;; Keywords: project, convenience
;; Version: 0.1
;; Package-Requires: ((counsel "0.8.0") (projectile "0.14.0"))

;; This file is NOT part of GNU Emacs.

;;; License:

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or (at
;; your option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:
;;
;; Projectile has native support for using ivy as its completion
;; system.  Counsel-projectile provides further ivy integration into
;; projectile by taking advantage of ivy's mechanism to select from a
;; list of actions and/or apply an action without leaving the
;; comlpetion session.  It is inspired by helm-projectile.  See the
;; README for more details.
;;
;;; Code:

(require 'counsel)
(require 'projectile)

;;; counsel-projectile-map

(defun counsel-projectile-drop-to-switch-project ()
  "For use in minibuffer maps.  Quit and call
`counsel-projectile-switch-project'."
  (interactive)
  (ivy-quit-and-run
   (counsel-projectile-switch-project)))

(defvar counsel-projectile-drop-to-switch-project-binding "M-SPC"
  "Key binding for `counsel-projectile-drop-to-switch-project' in
  `counsel-projectile-map'.")

(defvar counsel-projectile-map
  (let ((map (make-sparse-keymap)))
    (define-key map
      (kbd counsel-projectile-drop-to-switch-project-binding)
      'counsel-projectile-drop-to-switch-project)
    map)
  "Keymap used in the minibuffer.")

;;; counsel-projectile-find-file

(defun counsel-projectile-action-find-file (file &optional other-window)
  "Find FILE and run `projectile-find-file-hook'."
  (funcall (if other-window
               'find-file-other-window
             'find-file)
           (projectile-expand-root file))
  (run-hooks 'projectile-find-file-hook))

(defun counsel-projectile-action-find-file-other-window (file)
  "Find FILE in another window and run
`projectile-find-file-hook'."
  (counsel-projectile-action-find-file file t))

(defun counsel-projectile-find-file-transformer (name)
  "Transform non-visited file names with `ivy-virtual' face."
  (if (not (get-file-buffer (expand-file-name name (projectile-project-root))))
      (propertize name 'face 'ivy-virtual)
    name))

;;;###autoload
(defun counsel-projectile-find-file (&optional arg)
  "Jump to a project's file using completion.

Replacement for `projectile-find-file'.  With a prefix ARG
invalidates the cache first."
  (interactive "P")
  (projectile-maybe-invalidate-cache arg)
  (ivy-read (projectile-prepend-project-name "Find file: ")
            (projectile-current-project-files)
            :matcher #'counsel--find-file-matcher
            :require-match t
            :keymap counsel-projectile-map
            :action #'counsel-projectile-action-find-file
            :caller 'counsel-projectile-find-file))

(defvar counsel-projectile-find-file-actions
  '(("j" counsel-projectile-action-find-file-other-window
     "other window"))
  "List of actions for `counsel-projecile-find-file'.  If
  you modify this variable after loading counsel-projectile, then
  you should call `ivy-set-actions' afterwards to apply your
  changes.")

(ivy-set-actions
 'counsel-projectile-find-file
 counsel-projectile-find-file-actions)

(ivy-set-display-transformer
 'counsel-projectile-find-file
 'counsel-projectile-find-file-transformer)

;;; counsel-projectile-find-dir

(defun counsel-projectile--dir-list ()
  "Return a list of files for the current project."
  (if projectile-find-dir-includes-top-level
      (append '("./") (projectile-current-project-dirs))
    (projectile-current-project-dirs)))

(defun counsel-projectile-action-find-dir (dir &optional other-window)
  "Visit DIR with dired and run `projectile-find-dir-hook'."
  (funcall (if other-window
               'dired-other-window
             'dired)
           (projectile-expand-root dir))
  (run-hooks 'projectile-find-dir-hook))

(defun counsel-projectile-action-find-dir-other-window (dir)
  "Visit DIR with dired in another window and run
`projectile-find-dir-hook'."
  (counsel-projectile-action-find-dir dir t))

;;;###autoload
(defun counsel-projectile-find-dir (&optional arg)
  "Jump to a project's directory using completion.

With a prefix ARG invalidates the cache first."
  (interactive "P")
  (projectile-maybe-invalidate-cache arg)
  (ivy-read (projectile-prepend-project-name "Find dir: ")
            (counsel-projectile--dir-list)
            :require-match t
            :keymap counsel-projectile-map
            :action #'counsel-projectile-action-find-dir
            :caller 'counsel-projectile-find-dir))

(defvar counsel-projectile-find-dir-actions
  '(("j" counsel-projectile-action-find-dir-other-window
     "other window"))
  "List of actions for `counsel-projecile-find-dir'.  If
  you modify this variable after loading counsel-projectile, then
  you should call `ivy-set-actions' afterwards to apply your
  changes.")

(ivy-set-actions
 'counsel-projectile-find-dir
 counsel-projectile-find-dir-actions)

;;; counsel-projectile-switch-to-buffer

(defun counsel-projectile--buffer-list ()
  "Get a list of project buffer names.

Like `projectile-project-buffer-names', but propertize buffer
names as in `ivy--buffer-list'."
  (let ((buffer-names (projectile-project-buffer-names)))
    (ivy--buffer-list "" nil
                      (lambda (x)
                        (member (car x) buffer-names)))))

(defun counsel-projectile-action-switch-buffer (buffer &optional other-window)
  "Switch to BUFFER.

BUFFER may be a string or nil."
  (cond
   ((zerop (length buffer))
    (switch-to-buffer ivy-text nil 'force-same-window))
   (other-window
    (switch-to-buffer-other-window buffer))
   (t
    (switch-to-buffer buffer nil 'force-same-window))))

(defun counsel-projectile-action-switch-buffer-other-window (buffer)
  "Switch to BUFFER in other window.

BUFFER may be a string or nil."
  (counsel-projectile-action-switch-buffer buffer t))

;;;###autoload
(defun counsel-projectile-switch-to-buffer ()
  "Switch to a project buffer."
  (interactive)
  (ivy-read (projectile-prepend-project-name "Switch to buffer: ")
            (counsel-projectile--buffer-list)
            :matcher #'ivy--switch-buffer-matcher
            :require-match t
            :keymap counsel-projectile-map
            :action #'counsel-projectile-action-switch-buffer
            :caller 'counsel-projectile-switch-to-buffer))

(defvar counsel-projectile-switch-to-buffer-actions
  '(("j" counsel-projectile-action-switch-buffer-other-window
    "other window"))
  "List of actions for `counsel-projecile-switch-to-buffer'.  If
  you modify this variable after loading counsel-projectile, then
  you should call `ivy-set-actions' afterwards to apply your
  changes.")

(ivy-set-actions
 'counsel-projectile-switch-to-buffer
 counsel-projectile-switch-to-buffer-actions)

(ivy-set-display-transformer
 'counsel-projectile-switch-to-buffer
 'ivy-switch-buffer-transformer)

;;; counsel-projectile-ag

(defvar counsel-projectile-ag-initial-input nil
  "Initial minibuffer input for `counsel-projectile-ag'.  If non-nil, it should be a form whose evaluation yields the initial input string, e.g.

    (setq counsel-projectile-ag-initial-input
          '(projectile-symbol-or-selection-at-point))

or

    (setq counsel-projectile-ag-initial-input 
          '(thing-at-point 'symbol t))

Note that you can always insert the value of `(ivy-thing-at-point)' by
hitting \"M-n\" in the minibuffer.")

;;;###autoload
(defun counsel-projectile-ag (&optional options)
  "Run an ag search in the project."
  (interactive)
  (if (projectile-project-p)
      (let* ((options
              (if current-prefix-arg
                  (read-string "options: ")
                options))
             (ignored
              (unless (eq (projectile-project-vcs) 'git)
                ;; ag supports git ignore files
                (append
                 (cl-union (projectile-ignored-files-rel) grep-find-ignored-files)
                 (cl-union (projectile-ignored-directories-rel) grep-find-ignored-directories))))
             (options
              (concat options " "
                      (mapconcat (lambda (i)
                                   (concat "--ignore " (shell-quote-argument i)))
                                 ignored
                                 " "))))
        (counsel-ag (eval counsel-projectile-ag-initial-input)
                    (projectile-project-root)
                    options
                    (projectile-prepend-project-name "ag")))
    (user-error "You're not in a project")))

;;; counsel-projectile-rg

(defvar counsel-projectile-rg-initial-input nil
  "Initial minibuffer input for `counsel-projectile-rg'.  See `counsel-projectile-ag-initial-input' for details.")

;;;###autoload
(defun counsel-projectile-rg (&optional options)
  "Run an rg search in the project."
  (interactive)
  (if (projectile-project-p)
      (let* ((options
              (if current-prefix-arg
                  (read-string "options: ")
                options))
             (ignored
              (unless (eq (projectile-project-vcs) 'git)
                ;; rg supports git ignore files
                (append
                 (cl-union (projectile-ignored-files-rel) grep-find-ignored-files)
                 (cl-union (projectile-ignored-directories-rel) grep-find-ignored-directories))))
             (options
              (concat options " "
                      (mapconcat (lambda (i)
                                   (concat "--glob " (shell-quote-argument (concat "!" i))))
                                 ignored
                                 " "))))
        (counsel-rg (eval counsel-projectile-rg-initial-input)
                    (projectile-project-root)
                    options
                    (projectile-prepend-project-name "rg")))
    (user-error "You're not in a project")))


;;; counsel-projectile-switch-project

(defun counsel-projectile-switch-project-by-name (project-to-switch)
  "Switch to project by project name PROJECT-TO-SWITCH.
Invokes the command referenced by `projectile-switch-project-action' on switch.

This is a replacement for `projectile-switch-project-by-name'
with a different switching mechanism: the switch-project action
is called from a dedicated buffer rather than the initial buffer.
Also, PROJECT's dir-local variables are loaded before calling the
action."
  (run-hooks 'projectile-before-switch-project-hook)
  ;; Kill and recreate the switch buffer to get rid of any local
  ;; variable
  (ignore-errors (kill-buffer " *counsel-projectile*"))
  (set-buffer (get-buffer-create " *counsel-projectile*"))
  (setq default-directory project-to-switch)
  ;; Load the project dir-local variables into the switch buffer, so
  ;; the action can make use of them
  (hack-dir-local-variables-non-file-buffer)
  (funcall projectile-switch-project-action)
  ;; If the action relies on `ivy-read' then, after one of its
  ;; `ivy-read' actions is executed, the current buffer will be set
  ;; back to the initial buffer. Hence we make sure tu evaluate
  ;; `projectile-after-switch-project-hook' from the switch buffer.
  (with-current-buffer " *counsel-projectile*"
    (run-hooks 'projectile-after-switch-project-hook)))

(defun counsel-projectile-switch-project-action-find-file (project)
  "Action for `counsel-projectile-switch-project' to find a
PROJECT file."
  (let ((projectile-switch-project-action
         (lambda ()
           (counsel-projectile-find-file ivy-current-prefix-arg))))
    (counsel-projectile-switch-project-by-name project)))

(defun counsel-projectile-switch-project-action-find-file-manually (project)
  "Action for `counsel-projectile-switch-project' to find a
PROJECT file manually."
  (let ((projectile-switch-project-action
         (lambda ()
           (counsel-find-file project))))
    (counsel-projectile-switch-project-by-name project)))

(defun counsel-projectile-switch-project-action-find-dir (project)
  "Action for `counsel-projectile-switch-project' to find a
PROJECT directory."
  (let ((projectile-switch-project-action
         (lambda ()
           (counsel-projectile-find-dir ivy-current-prefix-arg))))
    (counsel-projectile-switch-project-by-name project)))

(defun counsel-projectile-switch-project-action-switch-to-buffer (project)
  "Action for `counsel-projectile-switch-project' to switch to a
PROJECT buffer."
  (let ((projectile-switch-project-action 'counsel-projectile-switch-to-buffer))
    (counsel-projectile-switch-project-by-name project)))

(defun counsel-projectile-switch-project-action-save-all-buffers (project)
  "Action for `counsel-projectile-switch-project' to save all
PROJECT buffers."
  (let ((projectile-switch-project-action 'projectile-save-project-buffers))
    (counsel-projectile-switch-project-by-name project)))

(defun counsel-projectile-switch-project-action-kill-buffers (project)
  "Action for `counsel-projectile-switch-project' to kill all
PROJECT buffers."
  (let ((projectile-switch-project-action 'projectile-kill-buffers))
    (counsel-projectile-switch-project-by-name project)))

(defun counsel-projectile-switch-project-action-remove-known-project (project)
  "Action for `counsel-projectile-switch-project' to remove
PROJECT from the list of known projects."
  (projectile-remove-known-project project)
  (setq ivy--all-candidates
        (delete dir ivy--all-candidates))
  (ivy--reset-state ivy-last))

(defun counsel-projectile-switch-project-action-edit-dir-locals (project)
  "Action for `counsel-projectile-switch-project' to edit
PROJECT's dir-locals."
  (let ((projectile-switch-project-action 'projectile-edit-dir-locals))
    (counsel-projectile-switch-project-by-name project)))

(defun counsel-projectile-switch-project-action-vc (project)
  "Action for `counsel-projectile-switch-project' to open PROJECT
in vc-dir / magit / monky."
  (let ((projectile-switch-project-action 'projectile-vc))
    (counsel-projectile-switch-project-by-name project)))

(defun counsel-projectile-switch-project-action-run-eshell (project)
  "Action for `counsel-projectile-switch-project' to start
`eshell' from PROJECT's root."
  (let ((projectile-switch-project-action 'projectile-run-eshell))
    (counsel-projectile-switch-project-by-name project)))

(defun counsel-projectile-switch-project-action-ag (project)
  "Action for `counsel-projectile-switch-project' to search
PROJECT with `ag'."
  (let ((projectile-switch-project-action 'counsel-projectile-ag))
    (counsel-projectile-switch-project-by-name project)))

(defun counsel-projectile-switch-project-action-rg (project)
  "Action for `counsel-projectile-switch-project' to search
PROJECT with `rg'."
  (let ((projectile-switch-project-action 'counsel-projectile-rg))
    (counsel-projectile-switch-project-by-name project)))

;;;###autoload
(defun counsel-projectile-switch-project ()
  "Switch to a project we have visited before.

Invokes the command referenced by
`projectile-switch-project-action' on switch."
  (interactive)
  (ivy-read (projectile-prepend-project-name "Switch to project: ")
            projectile-known-projects
            :preselect (and (projectile-project-p)
                            (abbreviate-file-name (projectile-project-root)))
            :action #'counsel-projectile-switch-project-by-name
            :require-match t
            :caller 'counsel-projectile-switch-project))

(defvar counsel-projectile-switch-project-actions
  '(("f" counsel-projectile-switch-project-action-find-file
     "find file")
    ("F" counsel-projectile-switch-project-action-find-file-manually
     "find file manually")
    ("d" counsel-projectile-switch-project-action-find-dir
     "find directory")
    ("b" counsel-projectile-switch-project-action-switch-to-buffer
     "switch to buffer")
    ("s" counsel-projectile-switch-project-action-save-all-buffers
     "save all buffers")
    ("k" counsel-projectile-switch-project-action-kill-buffers
     "kill all buffers")
    ("r" counsel-projectile-switch-project-action-remove-known-project
     "remove from known projects")
    ("l" counsel-projectile-switch-project-action-edit-dir-locals
     "edit dir-locals")
    ("g" counsel-projectile-switch-project-action-vc
     "open in vc-dir / magit / monky")
    ("e" counsel-projectile-switch-project-action-run-eshell
     "start eshell")
    ("a" counsel-projectile-switch-project-action-ag
     "search with ag")
    ("R" counsel-projectile-switch-project-action-rg
     "search with rg"))
  "List of actions for `counsel-projecile-switch-project'.  If
  you modify this variable after loading counsel-projectile, then
  you should call `ivy-set-actions' afterwards to apply your
  changes.")

(ivy-set-actions
 'counsel-projectile-switch-project
 counsel-projectile-switch-project-actions)

;;; counsel-projectile

(defun counsel-projectile--unvisited-file-list ()
  "Return a list of unvisited files for the current project.

Like `projectile-current-project-files', but skips any files
already being visited by a buffer."
  (let ((root (projectile-project-root)))
    (cl-loop
     for name in (projectile-current-project-files)
     for file = (expand-file-name name root)
     if (not (get-file-buffer file))
     collect name)))

(defun counsel-projectile--global-list ()
  "Get a list of project buffers and files."
  (append
   (mapc (lambda (buffer)
           (add-text-properties 0 1 '(type buffer) buffer))
         (counsel-projectile--buffer-list))
   (mapc (lambda (file)
           (add-text-properties 0 1 '(type file) file))
         (counsel-projectile--unvisited-file-list))))

(defun counsel-projectile--matcher (regexp candidates)
  "Return REGEXP-matching CANDIDATES.

Relies on `ivy--switch-buffer-matcher` and
`counsel--find-file-matcher'."
  (let ((buffers (cl-remove-if-not (lambda (name)
                                     (eq (get-text-property 0 'type name) 'buffer))
                                   candidates))
        (files (cl-remove-if-not (lambda (name)
                                   (eq (get-text-property 0 'type name) 'file))
                                 candidates)))
    (append (ivy--switch-buffer-matcher regexp buffers)
            (counsel--find-file-matcher regexp files))))

(defun counsel-projectile-action (name &optional other-window)
  "Switch to buffer or find file named NAME."
  (let ((type (get-text-property 0 'type name)))
    (cond
     ((eq type 'file)
      (counsel-projectile-action-find-file name other-window))
     ((eq type 'buffer)
      (counsel-projectile-action-switch-buffer name other-window)))))

(defun counsel-projectile-action-other-window (name)
  "Switch to buffer or find file named NAME in another window."
  (counsel-projectile-action name t))

(defun counsel-projectile-transformer (str)
  "Fontifies modified, file-visiting buffers.

Relies on `ivy-switch-buffer-transformer'."
  (let ((type (get-text-property 0 'type str)))
    (cond
     ((eq type 'buffer) (ivy-switch-buffer-transformer str))
     ((eq type 'file) (propertize str 'face 'ivy-virtual))
     (t str))))

;;;###autoload
(defun counsel-projectile (&optional arg)
  "Use projectile with Ivy instead of ido.

With a prefix ARG invalidates the cache first."
  (interactive "P")
  (if (not (projectile-project-p))
      (counsel-projectile-switch-project)
    (projectile-maybe-invalidate-cache arg)
    (ivy-read (projectile-prepend-project-name "Load buffer or file: ")
              (counsel-projectile--global-list)
              :matcher #'counsel-projectile--matcher
              :require-match t
              :keymap counsel-projectile-map
              :action #'counsel-projectile-action
              :caller 'counsel-projectile)))

(defvar counsel-projectile-actions
  '(("j" counsel-projectile-action-other-window
    "other window"))
  "List of actions for `counsel-projecile'.  If
  you modify this variable after loading counsel-projectile, then
  you should call `ivy-set-actions' afterwards to apply your
  changes.")

(ivy-set-actions
 'counsel-projectile
 counsel-projectile-actions)

(ivy-set-display-transformer
 'counsel-projectile
 'counsel-projectile-transformer)

;;; key bindings

;;;###autoload
(eval-after-load 'projectile
  '(progn
     (define-key projectile-command-map (kbd "SPC") #'counsel-projectile)))

(defun counsel-projectile-commander-bindings ()
  (def-projectile-commander-method ?f
    "Find file in project."
    (counsel-projectile-find-file))
  (def-projectile-commander-method ?d
    "Find directory in project."
    (counsel-projectile-find-dir))
  (def-projectile-commander-method ?b
    "Switch to project buffer."
    (counsel-projectile-switch-to-buffer))
  (def-projectile-commander-method ?A
    "Search project files with ag."
    (counsel-projectile-ag))
  (def-projectile-commander-method ?s
    "Switch project."
    (counsel-projectile-switch-project)))

(defun counsel-projectile-toggle (toggle)
  "Toggle counsel-projectile keybindings."
  (if (> toggle 0)
      (progn
        (when (eq projectile-switch-project-action #'projectile-find-file)
          (setq projectile-switch-project-action #'counsel-projectile))
        (define-key projectile-mode-map [remap projectile-find-file] #'counsel-projectile-find-file)
        (define-key projectile-mode-map [remap projectile-find-dir] #'counsel-projectile-find-dir)
        (define-key projectile-mode-map [remap projectile-switch-project] #'counsel-projectile-switch-project)
        (define-key projectile-mode-map [remap projectile-ag] #'counsel-projectile-ag)
        (define-key projectile-mode-map [remap projectile-switch-to-buffer] #'counsel-projectile-switch-to-buffer)
        (counsel-projectile-commander-bindings))
    (progn
      (when (eq projectile-switch-project-action #'counsel-projectile)
        (setq projectile-switch-project-action #'projectile-find-file))
      (define-key projectile-mode-map [remap projectile-find-file] nil)
      (define-key projectile-mode-map [remap projectile-find-dir] nil)
      (define-key projectile-mode-map [remap projectile-switch-project] nil)
      (define-key projectile-mode-map [remap projectile-ag] nil)
      (define-key projectile-mode-map [remap projectile-switch-to-buffer] nil)
      (projectile-commander-bindings))))

;;;###autoload
(defun counsel-projectile-on ()
  "Turn on counsel-projectile key bindings."
  (interactive)
  (message "Turn on counsel-projectile key bindings")
  (counsel-projectile-toggle 1))

;;;###autoload
(defun counsel-projectile-off ()
  "Turn off counsel-projectile key bindings."
  (interactive)
  (message "Turn off counsel-projectile key bindings")
  (counsel-projectile-toggle -1))


(provide 'counsel-projectile)

;;; counsel-projectile.el ends here
