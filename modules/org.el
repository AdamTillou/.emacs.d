(qv/package org)

;;; Configuration
(qv/hook org-mode-hook qv/org-mode-setup
  (ignore-errors (org-connect-show-separator))
  (variable-pitch-mode 1)
  (setq line-spacing 0.2)
  (display-line-numbers-mode 0))

(font-lock-add-keywords
 'org-mode
 '(("^ *\\([-]\\) "
    (0 (prog1 () (compose-region (match-beginning 1) (match-end 1) "•"))))
   ("\\(^\n\\)" (1 '(:height 0.5)))))

(setq org-ellipsis " ")
(setq org-src-tab-acts-natively nil)
(setq org-return-follows-link t)
(setq org-hide-emphasis-markers t)
(setq org-pretty-entities t)
(setq org-adapt-indentation nil)

;;; Faces
;;;; Outline Faces
(qv/face qv/org-header :f "Droid Serif" :w bold)
(qv/face org-document-title qv/org-header :fg ,qv/fg :h 1.5)
(qv/face org-document-info qv/org-header :fg ,qv/fg :h 1.25)
(qv/face org-level-1 qv/org-header :fg qv/blue :h 1.2)
(qv/face org-level-2 qv/org-header :fg qv/yellow :h 1.2)
(qv/face org-level-3 qv/org-header :fg qv/red :h 1.2)
(qv/face org-level-4 qv/org-header :fg qv/purple :h 1.2)

;;;;; Special Faces
(qv/face org-special-keyword fixed-pitch :fg ,qv/gray2 :h 0.8)
(qv/face org-table fixed-pitch)
(qv/face org-meta-line org-special-keyword)
(qv/face org-document-info-keyword org-special-keyword)
(qv/face org-verbatim fixed-pitch :fg ,qv/gray2)
(qv/face org-code org-verbatim :fg ,qv/bg2)
(qv/face org-block fixed-pitch :fg ,qv/bg2 :x t)
(qv/face org-block-begin-line org-block :fg ,qv/gray3)
(qv/face org-block-end-line org-block :fg ,qv/gray3)
(qv/face org-checkbox fixed-pitch)
(qv/face org-ellipsis :u nil)

;;;; Keybindings
(qv/keys org-mode-map
  "C-c C-b" (insert "#+BEGIN_SRC emacs-lisp\n#+END_SRC")
  "C-c C-c" org-ctrl-c-ctrl-c
  "C-c C-t" org-todo
  "RET" (if insert-keymode (newline) (org-open-at-point))
  "SPC" outline-toggle-children
  "<backtab>" org-global-cycle
  "g =" qv/format-code-block-indentation)

;;;; Hiding Text
(defvar qv/org-showing-meta-text nil
  "If non-nil, hide meta lines in org mode buffers.")

(setq qv/org-hide-exclude-keywords
      '("begin_src"
        "end_src"))

(setq qv/org-show-value-keywords
      '("title"
        "author"
        "description"))

(defun qv/org-show-meta-text (&optional state)
  "If STATE is positive, show meta text
If STATE is negative, hide meta text.
If STATE is 0, do not make any change, but make sure
that the text is being displayed/hidden properly.
Otherwise, toggle meta text."
  (interactive)
  (setq-local qv/org-showing-meta-text
              (if (numberp state)
                  (if (eq state 0) qv/org-showing-meta-text
                    (if (< state 0) nil t))
                (not qv/org-showing-meta-text)))

  (remove-overlays nil nil 'qv/hide-meta-lines t)

  (unless qv/org-showing-meta-text
    (let ((original-position (point)))

      (beginning-of-buffer)
      (while (search-forward-regexp "^#\\+[a-zA-Z]" nil t)
        (beginning-of-line)
        (let* ((case-fold-search t)
               (exclude-regexp
                (concat "\\(#\\+"
                        (string-join qv/org-hide-exclude-keywords "[: \n]\\|#\\+")
                        "[: \n]\\)"))
               (end-regexp
                (concat "\\(#\\+"
                        (string-join qv/org-show-value-keywords ":? \\|#\\+")
                        ":? \\|\n\\)"))
               (beg (point))
               (end (save-excursion (search-forward-regexp end-regexp nil t) (point)))
               (line (buffer-substring-no-properties beg end)))
          (when (string= line (replace-regexp-in-string
                               exclude-regexp "" line))
            (let ((overlay (make-overlay beg end)))
              (overlay-put overlay 'invisible t)
              (overlay-put overlay 'qv/hide-meta-lines t)))
          (end-of-line)))

      (goto-char original-position))))
(defvar qv/org-showing-drawers nil
  "If non-nil, hide drawers in org mode buffers.")
(setq-default qv/org-showing-drawers nil)

(defun qv/org-show-drawers (&optional state)
  "If STATE is positive, show drawers
If STATE is negative, hide drawers.
If STATE is 0, do not make any change, but make sure
that drawers are being displayed/hidden properly.
Otherwise, toggle drawers."
  (interactive)
  (setq-local qv/org-showing-drawers
              (if (numberp state)
                  (if (eq state 0) qv/org-showing-drawers
                    (if (< state 0) nil t))
                (not qv/org-showing-drawers)))

  (defvar-local qv/org-drawer-overlays nil
    "Store the overlays for drawers and meta text in the current buffer")
  (mapcar 'delete-overlay qv/org-drawer-overlays)
  (setq-local qv/org-drawer-overlays nil)

  (unless qv/org-showing-drawers
    (let ((original-position (point)))

      (beginning-of-buffer)
      (while (search-forward-regexp org-drawer-regexp nil t)
        (beginning-of-line)
        (when (ignore-error t (org-element-drawer-parser nil (list (point))))
          (let* ((props (cadr (org-element-drawer-parser nil (list (point)))))
                 (beg (plist-get props ':begin))
                 (end (plist-get props ':end))
                 (overlay (make-overlay (1- beg) (1- end))))
            (overlay-put overlay 'invisible t)
            (setq-local qv/org-drawer-overlays
                        (append qv/org-drawer-overlays (list overlay)))
            (goto-char (1- end))))
        (forward-char))
      (goto-char original-position))))

(add-hook 'org-mode-hook
          (lambda ()
            (qv/org-show-meta-text -1)
            (qv/org-show-drawers 1)
            (local-set-key (kbd "C-c C-h") 'qv/org-show-meta-text)
            (local-set-key (kbd "C-c C-S-h") 'qv/org-show-drawers)))

;;;; Equation Overlays
(qv/hook org-mode-hook qv/org-equation-overlays
  "Search the buffer for equations surrounded by ``, and
italicize them using an overlay so as not to invalidate
other formatting."
  (interactive)

  (remove-overlays nil nil 'qv/equation t)

  (let ((original-position (point)))
    (beginning-of-buffer)
    (while (search-forward-regexp "〈.*?〉" nil t)
      (search-backward "〈")

      (let ((overlay (make-overlay (point) (search-forward "〉"))))
        (overlay-put overlay 'face '(:slant italic :height 1.05))
        (overlay-put overlay 'qv/equation t)))

    (beginning-of-buffer)
    (while (search-forward "√" nil t)
      (let ((overlay (make-overlay (1- (point)) (point))))
        (overlay-put overlay 'face '(:slant normal))
        (overlay-put overlay 'qv/equation t)
        (when (string= (buffer-substring (point) (1+ (point))) "{")
          (overlay-put overlay 'display '((raise 0.1))))))

    (goto-char original-position)))

;;; Visual Fill Column
(qv/package visual-fill-column)

(qv/hook org-mode-hook qv/visual-fill-column-hook
  (setq visual-fill-column-width 100)
  (setq visual-fill-column-center-text t)
  (visual-fill-column-mode 1)
  (visual-line-mode 1))

;;; Inserting Items
(setq qv/insert-symbols-alist
      '(("`" . "∙")
        ("." . "·")
        (";" . "°")
        ("-" . "−")
        ("~" . "≈")
        ("+" . "±")
        ("/" . "⁄")
        ("*" . "×")
        ("m r" . "√")
        ("m i" . "∞")
        ("g a" . "∡")
        ("g A" . "∢")
        ("g t" . "Δ")
        ("g =" . "∥")
        ("g +" . "⟂")
        ("s u" . "∪")
        ("s i" . "∩")
        ("s e" . "∈")
        ("l p" . "π")
        ("l t" . "θ")
        ("f 1 /" . "⅟")
        ("f 1 2" . "½")
        ("f 1 3" . "⅓")
        ("f 2 3" . "⅔")
        ("f 1 4" . "¼")
        ("f 3 4" . "¾")
        ("f 1 5" . "⅕")
        ("f 2 5" . "⅖")
        ("f 3 5" . "⅗")
        ("f 4 5" . "⅘")
        ("f 1 6" . "⅙")
        ("f 5 6" . "⅚")
        ("f 1 7" . "⅐")
        ("f 1 8" . "⅛")
        ("f 5 8" . "⅝")
        ("f 7 8" . "⅞")
        ("f 1 9" . "⅑")))
(defface qv/delimiter '((t :height 0.1))
  "Face for easily changing whether equation delimiters (`)
are visible (full height) or invisible (tiny height).")

(font-lock-add-keywords
 'org-mode
 '(("∡" (0 '(:height 1.05)))
   ("√" (0 `(:family ,(face-attribute 'fixed-pitch ':family))))
   ("[〈〉]" (0 'qv/delimiter))
   ("\\(⌈\\)\\(.+?\\)\\(⌉\\)"
    (1 'qv/delimiter) (2 '(:overline t)) (3 'qv/delimiter))
   ("√\\({\\)\\([^}\n]*\\)\\(}\\)"
    (1 '(:overline t :inherit qv/delimiter)) (2 '(:overline t))
    (3 '(:overline t :inherit qv/delimiter)))))

(qv/keys *
  "M-i" nil
  "M-i M-h" org-insert-heading
  "M-i M-l" org-insert-link
  "M-i M-d" org-insert-drawer
  "M-i M-m" ((setq org-pretty-entities (not org-hide-emphasis-markers)
                   org-hide-emphasis-markers (not org-hide-emphasis-markers))
             (org-mode-restart))
  "M-i M-b" ((insert "#+BEGIN_SRC emacs-lisp\n\n#+END_SRC")
             (previous-line))
  "M-i e" ((insert (format "〈%s〉" (read-string "Equation: ")))
           (qv/org-equation-overlays))
  "M-i E" ((insert "〈〉") (backward-char)
           (qv/org-equation-overlays))
  "M-e" ((insert (format "〈%s〉" (read-string "Equation: ")))
         (qv/org-equation-overlays))
  "M-E" ((insert "〈〉") (backward-char)
         (qv/org-equation-overlays))
  "M-i g l" ((insert (format "⌈%s⌉" (read-string "Line: "))))
  "M-i g L" ((insert "⌈⌉") (backward-char)))

(dolist (i qv/insert-symbols-alist)
  (global-set-key (kbd (concat "M-i " (car i)))
                  (eval `(lambda () (interactive) (insert ,(cdr i))))))