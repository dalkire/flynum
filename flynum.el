;;; flynum.el --- Line number highlighting for flycheck.

;; Copyright (c) 2014 David Alkire
;;
;; Author: David Alkire
;; URL: https://github.com/dalkire/flycheck
;; Package-Requires: cl, flycheck, linum

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
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

;; Line number highlighting for flycheck.

;; Provide `flynum-mode' which enables highlighting of flycheck error lines

;;; Code:

(require 'cl)

(setq linum-format 'flynum-format)
(add-hook 'flycheck-after-syntax-check-hook 'flynum-build-list)
(add-hook 'flycheck-after-syntax-check-hook 'linum-update-current)

(defun flynum-build-list ()
  (let ((num-lines (count-lines (point-min) (point-max))))
    (when (> num-lines 0)
        (setq-local flynum-vector (make-vector num-lines nil))
        (loop for n from 1 to num-lines do
              (if (string-equal "error" (flynum-error-level n))
                  (aset flynum-vector (1- n) "error")
                (if (string-equal "warning" (flynum-error-level n))
                    (aset flynum-vector (1- n) "warning")))))))

(defun num-to-format (line)
  (if (< line 10)
      (concat "  " (number-to-string line) " ")
    (if (< line 100)
        (concat " " (number-to-string line) " ")
      (concat (number-to-string line) " "))))

(defun flynum-format (line)
  (let ((format nil)
        (default-format (propertize (num-to-format line) 'face 'linum))
        (error-format (propertize
                    (num-to-format line)
                    'face
                    '(:foreground "black" :background "red")))
        (warning-format (propertize
                         (num-to-format line)
                         'face
                         '(:foreground "black" :background "yellow"))))
    (setq format default-format)
    (if (flynum-valid-p line)
        (if (string-equal "error" (aref flynum-vector (1- line)))
            (setq format error-format)
          (if (string-equal "warning" (aref flynum-vector (1- line)))
              (setq format warning-format))))
    format))

(defun flynum-valid-p (line)
  (and (boundp 'flynum-vector)
       (boundp 'flycheck-current-errors)
       (symbol-value 'flycheck-current-errors)
       (<= line (length flynum-vector))))

(defun flynum-error-level (line)
  (let ((foundp nil)
        (errorp nil)
        (warningp nil))
    (catch 'break
      (loop for error in flycheck-current-errors do
            (setq foundp (= line (flycheck-error-line error)))
            (setq errorp (string-equal "error" (flycheck-error-level error)))
            (setq warningp (string-equal "warning" (flycheck-error-level error)))
            (if (and foundp errorp)
                (throw 'break "error"))
            (if (and foundp warningp)
                (throw 'break "warning"))))))

(provide 'flynum)

;; End:

;;; flynum.el ends here
