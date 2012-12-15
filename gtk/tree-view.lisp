(in-package :gtk-cffi)

(defclass tree-view (container)
  ())

(defcenum tree-view-grid-lines
  :none :horizontal :vertical :both) 

(defcfun gtk-tree-view-new :pointer)
(defcfun gtk-tree-view-new-with-model :pointer (model pobject))

(defmethod gconstructor ((tree-view tree-view)
                         &key model &allow-other-keys)
  (if model
      (gtk-tree-view-new-with-model model)
    (gtk-tree-view-new)))

(defslots tree-view
  level-indentation :int
  show-expanders :boolean
  model pobject
  hadjustment pobject
  vadjustment pobject
  headers-visible :boolean
  headers-clickable :boolean
  rules-hint :boolean
  hover-selection :boolean
  hover-expand :boolean
  rubber-banding :boolean
  search-column :int
  expander-column pobject)
  

(deffuns tree-view 
  (remove-column :int (column pobject))
  (append-column :int (column pobject))
  (insert-column :int (column pobject) (position :int) &key)
  (:get selection pobject)
  (:get columns g-list-object)
  (:get column pobject (n :int))
  (:get n-columns :int)
  (move-column-after :void (column pobject) (base-column pobject))
  (scroll-to-point :void (x :int) (y :int)))

(defcfun gtk-tree-view-scroll-to-cell :void 
  (tree-view pobject) (path ptree-path) (column pobject) (use-align :boolean) (row-align :float) (col-align :float))

(defgeneric scroll-to-cell (tree-view path column &key row-align col-align)
  (:method ((tree-view tree-view) path column &key (row-align 0.0 row-align-p) (col-align 0.0 col-align-p))
    (gtk-tree-view-scroll-to-cell tree-view path column (or row-align-p col-align-p) row-align col-align)))


(defmethod (setf columns) (columns (tree-view tree-view))
  (dolist (column (columns tree-view))
    (remove-column tree-view column))
  (labels
      ((mk-column (column num)
         (typecase column
           (string (make-instance 'tree-view-column 
                                  :title column
                                  :cell (make-instance 'cell-renderer-text)
                                  :attributes `(:text ,num)))
           (cons (apply #'make-instance
                        'tree-view-column column))
           (t column))))
    (reduce (lambda (num column)
              (append-column tree-view (mk-column column num)))
            columns :initial-value 0)))
(save-setter tree-view columns)
       

(defcfun gtk-tree-view-get-path-at-pos :boolean (view pobject)
  (x :int) (y :int) (path :pointer) (column :pointer)
  (cell-x :pointer) (cell-y :pointer))

(defmethod path-at-pos ((tree-view tree-view) x y)
  (with-foreign-outs-list 
      ((path 'tree-path) (column 'pobject) 
       (cell-x :int) (cell-y :int)) :if-success
    (gtk-tree-view-get-path-at-pos tree-view x y path column cell-x cell-y)))

(defcfun gtk-tree-view-get-cursor :void (view pobject)
  (path :pointer) (column :pointer))

(defmethod get-cursor ((tree-view tree-view))
  (with-foreign-outs-list ((path 'tree-path) (column 'pobject)) :ignore
      (gtk-tree-view-get-cursor tree-view path column)))

(defcfun gtk-tree-view-insert-column-with-data-func :int
  (tree-view pobject) (position :int) (title :string) (cell pobject)
  (data-func pfunction) (data pdata) (destroy pfunction))

(defmethod insert-column ((tree-view tree-view) (cell cell-renderer) position 
                          &key title func data destroy-notify)
  (set-callback tree-view gtk-tree-view-insert-column-with-data-func
                cb-cell-data-func func data destroy-notify 
                position title cell))

(defcfun gtk-tree-view-set-column-drag-function :void
  (tree-view pobject) (func pfunction) (user-data pdata) (destroy pfunction))

(defcallback cb-column-drop-function :boolean
    ((tree-view pobject) (column pobject) (prev-column pobject) (next-column pobject) (data pdata))
  (funcall data tree-view column prev-column next-column))

(defgeneric (setf column-drag-function) (func tree-view &key data destroy-notify)
  (:documentation "gtk_tree_view_set_column_drag_function")
  (:method (func (tree-view tree-view) &key data destroy-notify)
    (set-callback tree-view gtk-tree-view-set-column-drag-function
                  cb-column-drop-function func data destroy-notify)))
                

(init-slots tree-view (on-select)
  (when on-select
    (setf (gsignal (selection tree-view) :changed)
          (lambda (selection)
            (destructuring-bind (rows model) (selected-rows selection)
              (when rows
                (apply on-select model rows)))))))