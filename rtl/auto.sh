#!/bin/sh
# -*- mode: emacs-lisp -*-
cd "$(dirname $0)"
exec emacs -Q --batch --eval="(progn $(tail -n+5 $0))" "$@"

(require 'verilog-mode)
(dolist (path '("src" "src/bfs" "../sim"))
  (push (expand-file-name path) verilog-library-directories))
(setq verilog-auto-arg-format 'single)
(setq verilog-auto-inst-param-value t)

(dolist (file command-line-args-left)
  (find-file (concat (file-name-directory file) "build/" (file-name-base file)))
  (insert-file-contents-literally file nil nil nil t)
  (verilog-auto)
  (save-buffer)
  (kill-buffer))
