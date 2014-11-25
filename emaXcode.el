;;; emaXcode.el --- My Emacs setting for Objective-C, Xcode -*- coding: utf-8; lexical-binding: t -*-

;; Copyright (C) 2014 by Shingo Fukuyama

;; Version: 1.0
;; Author: Shingo Fukuyama - http://fukuyama.co
;; URL: https://github.com/ShingoFukuyama/emaXcode
;; Created: May 26 2014
;; Keywords: xcode, objective-c, yasnippet, auto-complete, helm
;; Package-Requires: ((auto-complete "1.4.0) (yasnippet "0.8.0") (helm "1.5.6") (s "1.9.0) (emacs "24.3.5"))

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2 of
;; the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be
;; useful, but WITHOUT ANY WARRANTY; without even the implied
;; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
;; PURPOSE.  See the GNU General Public License for more details.

;;; Commentary:

;;

;;; Code:

(require 'auto-complete)
(require 'yasnippet)
(require 'helm)
(require 's)

(defgroup emaXcode nil
  "Group for emaXcode.el"
  :prefix "emaXcode-" :group 'development)


;; Make new NSObject subclass template files -----------------------------------

(defvar emaXcode-your-name-for-template "Your Name")

(defun emaXcode-make-new-files-subclass-of-NSObject (class-name)
  "Make .h and .m file subclassing from NSObject in the current directory."
  (interactive "sClass Name: ")
  (setq class-name (s-trim class-name))
  (let* ((header    (expand-file-name (concat "./" class-name ".h")))
         (implement (expand-file-name (concat "./" class-name ".m")))
         (time (current-time))
         (date (format-time-string "%Y/%m/%d" time))
         (year (format-time-string "%Y" time)))
    (unless (or (file-exists-p header)
                (file-exists-p implement))
      (with-temp-file header
        (insert (format "//
//  %s.h
//  Project Name
//
//  Created by %s on %s.
//  Copyright (c) %s %s. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface %s : NSObject

@end
"
                        class-name
                        emaXcode-your-name-for-template
                        date
                        year
                        emaXcode-your-name-for-template
                        class-name)))
      (with-temp-file implement
        (insert (format "//
//  %s.m
//  Project Name
//
//  Created by %s on %s.
//  Copyright (c) %s %s. All rights reserved.
//

#import \"%s.h\"

@implementation %s

@end
"
                        class-name
                        emaXcode-your-name-for-template
                        date
                        year
                        emaXcode-your-name-for-template
                        class-name
                        class-name)))
      (if (eq major-mode 'dired-mode) (revert-buffer)))))



;; Make compiled yasnippet file from Apple's header files ----------------------

(defcustom emaXcode-yas-objc-header-directories-list
  '("/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator7.1.sdk/System/Library/Frameworks/Foundation.framework/Headers"
    "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator7.1.sdk/System/Library/Frameworks/UIKit.framework/Headers")
  "List header directory paths"
  :group 'emaXcode
  :type 'list)
(defvar emaXcode-yas-root (if (listp yas-snippet-dirs)
                              (car yas-snippet-dirs)
                            yas-snippet-dirs))
(defvar emaXcode-yas-objc-root (concat emaXcode-yas-root "/objc-mode"))
(defvar emaXcode-yas-objc-compiled-file (concat emaXcode-yas-objc-root "/.yas-compiled-snippets.el"))

(defun emaXcode-yas-compile-subdir ()
  "Make .yas-compiled-snippets.el file from existing files under the objc-mode snippet directory"
  (unless (file-directory-p emaXcode-yas-root)
    (error (format "Yasnippet directory doesn't exist: %s" emaXcode-yas-root)))
  (unless (file-directory-p emaXcode-yas-objc-root)
    (make-directory emaXcode-yas-objc-root))
  (let ((yas--creating-compiled-snippets t)
        (dir emaXcode-yas-objc-root))
    (let* ((major-mode-and-parents (yas--compute-major-mode-and-parents
                                    (concat dir "/dummy")))
           (mode-sym (car major-mode-and-parents))
           (parents (cdr major-mode-and-parents)))
      (yas--define-parents mode-sym parents)
      (yas--menu-keymap-get-create mode-sym)
      (let ((fun `(lambda ()
                    (yas--load-directory-1 ',dir ',mode-sym))))
        (funcall fun)))))

(defun emaXcode-yas-get-objc-messages-from-header-files ()
  (interactive)
  (let ($header-files
        $yas-compiled-snippets
        ;;$return-type
        $fn-name
        $template-content
        $key-for-expand
        $list)
    (emaXcode-yas-compile-subdir) ;; (yas-recompile-all)

    (mapc (lambda ($path)
            (unless (file-directory-p $path)
              (error (format "Apples's directory doesn't exist: %s" $path)))

            (mapc (lambda ($file)
                    (with-temp-buffer
                      (insert-file-contents-literally $file)
                      (goto-char (point-min))
                      (while (re-search-forward "^[\t ]*[+-][\t ]*\\(([^)]+)\\)\\([^;]+\\);" nil t)
                        (setq $key-for-expand "")
                        ;;(setq $return-type (match-string 1))
                        (setq $fn-name (match-string 2))
                        (setq $template-content "")
                        ;; Set yasnippet placeholder
                        (if (string-match ":" $fn-name)
                            (with-temp-buffer
                              (insert $fn-name)
                              (goto-char (point-min))
                              (while (re-search-forward "[a-zA-Z0-9_]*:" nil t)
                                (setq $key-for-expand (concat $key-for-expand (match-string 0))))
                              (goto-char (point-min))
                              (let (($num 1) $po1 $po2 $rep)
                                (while (re-search-forward ":[\t ]*(" nil t)
                                  (backward-char 1)
                                  (setq $po1 (point))
                                  (forward-sexp)
                                  (re-search-forward "[\t ]*[a-zA-Z0-9_$]*" nil t)
                                  (setq $po2 (point))
                                  (setq $rep (buffer-substring-no-properties $po1 $po2))
                                  (delete-region $po1 $po2)
                                  (insert (format "${%d:%s}" $num $rep))
                                  (setq $num (1+ $num))))
                              (setq $template-content (buffer-string)))
                          (setq $key-for-expand $fn-name)
                          (setq $template-content $fn-name))
                        (when (equal $key-for-expand "")
                          (setq $key-for-expand nil))
                        ;; (when (string-match "[ (]" $key-for-expand)
                        ;;   (setq $key-for-expand (car (split-string $key-for-expand "[ (]"))))
                        (setq $list (cons
                                     (list
                                      $key-for-expand   ; key
                                      $template-content ; template-content
                                      $fn-name          ; name
                                      nil               ; condition
                                      nil               ; group
                                      '((yas/indent-line 'fixed) (yas/wrap-around-region 'nil)) nil nil nil)
                                     $list)))
                      ;; Extract UIKIT_EXTERN functions
                      (goto-char (point-min))
                      (while (re-search-forward "^UIKIT\_EXTERN[\t ]*\\([a-zA-Z0-9]*\\)[\t ]*\\*?\\([^;]*\\)" nil t)
                        (setq $key-for-expand "")
                        ;; (setq $return-type (match-string 1))
                        (setq $fn-name (match-string 2))
                        (setq $template-content "")
                        ;; Set yasnippet placeholder
                        (if (string-match "([^)]+)" $fn-name)
                            (with-temp-buffer
                              (insert $fn-name)
                              (goto-char (point-min))
                              (when (re-search-forward "(" nil t)
                                (setq $key-for-expand (buffer-substring-no-properties (point-min) (1- (point)))))
                              (let (($num 1) ($po (point)) $rep)
                                (while (re-search-forward "\\([^,]+\\)" (1- (point-max)) t)
                                  (setq $rep (buffer-substring-no-properties $po (point)))
                                  (delete-region $po (point))
                                  ;; For a space after a preceding comma
                                  (if (string-match "^\\s-" $rep)
                                      (insert (format " ${%d:%s}" $num $rep))
                                    (insert (format "${%d:%s}" $num $rep)))
                                  (re-search-forward "," nil t)
                                  (setq $po (point))
                                  (setq $num (1+ $num))))
                              (setq $template-content (buffer-string)))
                          (setq $key-for-expand $fn-name)
                          (setq $template-content $fn-name))
                        (when (equal $key-for-expand "")
                          (setq $key-for-expand nil))
                        (setq $list (cons
                                     (list
                                      $key-for-expand   ; key
                                      $template-content ; template-content
                                      $fn-name          ; name
                                      nil               ; condition
                                      nil               ; group
                                      '((yas/indent-line 'fixed) (yas/wrap-around-region 'nil)) nil nil nil)
                                     $list)))))
                  ;; Make header files list
                  (split-string
                   (shell-command-to-string
                    (concat "find " $path " -name '*.h' -type f")))))
          emaXcode-yas-objc-header-directories-list)

    (if (file-exists-p emaXcode-yas-objc-compiled-file)
        (setq $yas-compiled-snippets
              (or (ignore-errors
                    (read (with-temp-buffer
                            (insert-file-contents-literally emaXcode-yas-objc-compiled-file)
                            (buffer-string))))
                  '(yas-define-snippets 'objc-mode '())))
      (setq $yas-compiled-snippets '(yas-define-snippets 'objc-mode '())))

    (setf (nth 1 (nth 2 $yas-compiled-snippets))
          (append $list (nth 1 (nth 2 $yas-compiled-snippets))))

    (with-temp-file emaXcode-yas-objc-compiled-file
      (insert (prin1-to-string $yas-compiled-snippets)))
    (message "Extract %s messages and save to %s." (length $list) emaXcode-yas-objc-compiled-file)))

;; (emaXcode-yas-get-objc-messages-from-header-files)

;; Chenge yasnippet settings ---------------------------------------------------

(when (and (string-match "apple-darwin" system-configuration)
           (memq 'yas-x-prompt yas-prompt-functions))
  ;; Eliminate `yas-x-prompt' for MacOSX
  (setq yas-prompt-functions (delq 'yas-x-prompt yas-prompt-functions)))

(defun emaXcode-helm-dir-files ($dir)
  (interactive)
  (helm :sources
        `((name . "emaXcode helm dir files")
          (candidates . (lambda () (directory-files ,$dir t)))
          (type . file))
        :buffer "*emaXcode helm dir files*"))

(defun emaXcode-helm-yas-visit-snippet-file ()
  (interactive)
  (let* ((yas-dir (if (listp yas-snippet-dirs)
                      (car yas-snippet-dirs)
                    yas-snippet-dirs))
         (target-dir (format "%s/%s" yas-dir major-mode)))
    (when (file-directory-p target-dir)
      (emaXcode-helm-dir-files target-dir))))

(defun emaXcode-yas-new-snippet-from-region (beg end)
  "Pops a new buffer for writing a snippet from the region."
  (interactive "r")
  (let ((guessed-directories (yas--guess-snippet-directories))
        (subst (buffer-substring-no-properties beg end)))

    (switch-to-buffer "*new snippet*")
    (erase-buffer)
    (kill-all-local-variables)
    (snippet-mode)
    (yas-minor-mode 1)
    (set (make-local-variable 'yas--guessed-modes) (mapcar #'(lambda (d)
                                                               (yas--table-mode (car d)))
                                                           guessed-directories))
    (insert subst)
    (goto-char (point-min))
    (yas-expand-snippet yas-new-snippet-default)))

;; Set snippets to auto-complete -----------------------------------------------

(defvar emaXcode-yas-name-key (make-hash-table :test 'equal :size 5000))
(defvar emaXcode-yas-name-list nil)

(defun emaXcode-yas-set-source ()
  "Read objc snippets from objc-mode snippet folder, and set name list and name-key pair list."
  (when (not emaXcode-yas-name-list)
    (let ((template (yas--all-templates (yas--get-snippet-tables)))
          name)
      (when template
        (setq template
              (sort template #'(lambda (t1 t2)
                                 (< (length (yas--template-name t1))
                                    (length (yas--template-name t2))))))
        (setq emaXcode-yas-name-list
              (mapcar (lambda (temp)
                        (setq name (yas--template-name temp))
                        (puthash name
                                 (yas--template-key temp)
                                 emaXcode-yas-name-key)
                        name)
                      template))))
    (when emaXcode-yas-name-list
      (ac-define-source emaXcode-yasnippet
        `((depends yasnippet)
          (candidates . emaXcode-yas-name-list)
          (action . (lambda ()
                      (let* ((undo-inhibit-record-point t)
                             (position (point))
                             (completed (cdr ac-last-completion))
                             (length (length completed))
                             (beginning (- position length)))
                        (delete-region beginning position)
                        (insert (gethash completed emaXcode-yas-name-key))
                        (yas-expand-from-trigger-key))))
          (candidate-face . ac-yasnippet-candidate-face)
          (selection-face . ac-yasnippet-selection-face)
          (symbol . "yas"))))))

(defun emaXcode-yas-ac-objc-setup ()
  (emaXcode-yas-set-source) ;; Set lists if name list has not set
  (add-to-list 'ac-modes 'objc-mode)
  (if (and (symbolp 'auto-complete-mode) (not (symbol-value 'auto-complete-mode)))
      (auto-complete-mode 1))
  (set (make-local-variable 'ac-delay) 0.2)
  (set (make-local-variable 'ac-auto-show-menu) 0.5)
  (set (make-local-variable 'ac-ignore-case) t)
  (setq ac-sources (delq 'ac-source-yasnippet ac-sources))
  (add-to-list 'ac-sources 'ac-source-emaXcode-yasnippet))

(add-hook 'objc-mode-hook 'emaXcode-yas-ac-objc-setup t)

;; Check error -----------------------------------------------------------------

(require 'flymake)

(defcustom emaXcode-check-error nil
  "Checking error or warnings for objc-mode"
  :group 'emaXcode
  :type 'boolean)

(defcustom emaXcode-xcode:sdkpath
  "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator7.1.sdk"
  "Developer directory path"
  :group 'emaXcode
  :type 'string)
(defvar emaXcode-flymake-objc-compiler "/usr/bin/gcc")
(defvar emaXcode-flymake-objc-compile-default-options
  (list "-Wall" "-Wextra" "-fsyntax-only" "-ObjC" "-std=c99" "-isysroot" emaXcode-xcode:sdkpath))
(defvar emaXcode-flymake-objc-compile-options '("-I."))

(defun emaXcode-flymake-objc-init ()
  (let* ((temp-file (flymake-init-create-temp-buffer-copy
                    'flymake-create-temp-inplace))
         (local-file (file-relative-name
                     temp-file
                     (file-name-directory buffer-file-name))))
    (list emaXcode-flymake-objc-compiler
          (append emaXcode-flymake-objc-compile-default-options
                  emaXcode-flymake-objc-compile-options (list local-file)))))
(defun emaXcode-flymake-objc-setup ()
  (when emaXcode-check-error
    ;; Need to place before flymake-mode enabled
    (push '("\\.mm?$" emaXcode-flymake-objc-init) flymake-allowed-file-name-masks)
    (push '("\\.h$"   emaXcode-flymake-objc-init) flymake-allowed-file-name-masks)
    ;; File exists and writable
    (if (and (not (null buffer-file-name)) (file-writable-p buffer-file-name))
        (flymake-mode t))))

(add-hook 'objc-mode-hook 'emaXcode-flymake-objc-setup)

(defun emaXcode-flymake-display-err-minibuffer ()
  "Display error or warnings on the minibuffer."
  (interactive)
  (when emaXcode-check-error
    (let* ((line-no (flymake-current-line-no))
           (line-err-info-list (nth 0 (flymake-find-err-info flymake-err-info line-no)))
           (count (length line-err-info-list)))
      (while (> count 0)
        (when line-err-info-list
          (let* (
                 ;; (file (flymake-ler-file (nth (1- count) line-err-info-list)))
                 ;; (full-file (flymake-ler-full-file (nth (1- count) line-err-info-list)))
                 (text (flymake-ler-text (nth (1- count) line-err-info-list)))
                 (line (flymake-ler-line (nth (1- count) line-err-info-list))))
            (message "[%s] %s" line text)))
        (setq count (1- count))))))

(defadvice flymake-mode (before post-command-stuff activate compile)
  "To display error on the minibuffer, add function to `post-command-hook'"
  (when emaXcode-check-error
    (set (make-local-variable 'post-command-hook)
         (add-hook 'post-command-hook 'emaXcode-flymake-display-err-minibuffer))))

;; Relevant paths --------------------------------------------------------------

(defun emaXcode-open-application-directory ()
  (interactive)
  (let ((path (expand-file-name "~/Library/Application Support/iPhone Simulator")))
    (if (file-exists-p path)
        (dired path)
      (error (format "Directory not found: %s" path)))))

;; Set up objc-mode ------------------------------------------------------------

(or (boundp 'ff-other-file-alist)
    (defvar ff-other-file-alist nil))

(defun emaXcode-etc-objc-setup ()
  (auto-revert-mode 1)
  (set (make-local-variable 'ff-other-file-alist)
       '(("\\.mm?$" (".h"))
         ("\\.cc$"  (".hh" ".h"))
         ("\\.hh$"  (".cc" ".C"))

         ("\\.c$"   (".h"))
         ("\\.h$"   (".c" ".cc" ".C" ".CC" ".cxx" ".cpp" ".m" ".mm"))

         ("\\.C$"   (".H"  ".hh" ".h"))
         ("\\.H$"   (".C"  ".CC"))

         ("\\.CC$"  (".HH" ".H"  ".hh" ".h"))
         ("\\.HH$"  (".CC"))

         ("\\.cxx$" (".hh" ".h"))
         ("\\.cpp$" (".hpp" ".hh" ".h"))

         ("\\.hpp$" (".cpp" ".c")))))

(defalias 'emaXcode-open-corresponding-file 'ff-find-other-file)

(add-hook 'objc-mode-hook 'emaXcode-etc-objc-setup)

(add-to-list 'auto-mode-alist '("\\.mm?$" . objc-mode))
(add-to-list 'auto-mode-alist '("\\.h$" . objc-mode))


(provide 'emaXcode)
;;; emaXcode.el ends here
