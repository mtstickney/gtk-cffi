(in-package :gtk-cffi)

(defgeneric selection-bounds (widget &key)) ;; text-buffer, label
(defgeneric text (widget &key)) ;; entry, label, text-buffer
(defgeneric (setf text) (value widget &key))
(defgeneric layout-offsets (object)) ;; entry, label, scale

