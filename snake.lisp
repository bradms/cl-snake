;;;; snake.lisp

(in-package #:snake)

;; TODO(bsvercl): It would be nice to have highscores.

(defparameter +segment-size+ 25)
(defparameter +screen-width+ 800)
(defparameter +screen-height+ 600)
(defparameter +segments-across-width+ (floor (/ +screen-width+ +segment-size+)))
(defparameter +segments-across-height+ (floor (/ +screen-height+ +segment-size+)))

(defparameter +snake-color+ (gamekit:vec4 1.0 0.75 0.5 1.0))
(defparameter +food-color+ (gamekit:vec4 0.5 0.25 1.0 1.0))
(defparameter +grid-color+ (gamekit:vec4 0.9 0.9 0.9 0.5))
(defparameter +transparent+ (gamekit:vec4))

(defclass snake ()
  ((segments :initarg :segments :accessor segments-of)
   (direction :initarg :direction :accessor direction-of))
  (:documentation "The moving thing, usually user controlled."))

(defun make-snake (starting-position &optional (direction (gamekit:vec2)))
  "Creates a SNAKE with STARTING-POSITION and DIRECTION."
  (make-instance 'snake :segments (list starting-position)
                        :direction direction))

(defun snake-position (snake)
  "Head position of SNAKE."
  (first (segments-of snake)))

(defmethod (setf snake-position) (pos snake)
  (setf (first (segments-of snake)) pos))

(defun snake-tail (snake)
  "The rest of the SNAKE."
  (rest (segments-of snake)))

;; TODO(bsvercl): Don't allow Left<->Right Up<->Down
(defun change-direction (snake direction)
  "Modify DIRECTION of SNAKE with NEW-DIRECTION."
  (let ((new-direction (case direction
                         (:up (gamekit:vec2 0 1))
                         (:down (gamekit:vec2 0 -1))
                         (:left (gamekit:vec2 -1 0))
                         (:right (gamekit:vec2 1 0))
                         ;; We don't know that this is supposed to be.
                         (t (gamekit:vec2)))))
    (setf (direction-of snake) new-direction)))

(defun advance (snake ate-food-p)
  "Moves the SNAKE according to it's DIRECTION."
  (with-slots (segments direction) snake
    (let* ((position (snake-position snake))
           ;; The position of the next head.
           (new-head (gamekit:add position direction))
           ;; If we ate the food we do not chop off the end of the SEGMENTS.
           (which-segments (if ate-food-p segments (butlast segments)))
           (new-segments (push new-head which-segments)))
      (setf segments new-segments)
      ;; Wrap SNAKE around the boundaries
      (setf (snake-position snake) (mod-vec (snake-position snake)
                                            (gamekit:vec2 +segments-across-width+
                                                          +segments-across-height+))))))

(defun hit-itself (snake)
  "Did I just eat myself?"
  (let ((head-position (snake-position snake)))
    (loop for segment in (snake-tail snake)
          when (bodge-math:vec= segment head-position)
            do (return-from hit-itself t))))

(gamekit:defgame snake-game ()
  ((current-state))
  (:viewport-title "Snake")
  (:viewport-width +screen-width+)
  (:viewport-height +screen-height+)
  (:act-rate 10))

(defun new-food-pos ()
  "Generates a new spot on the grid."
  (gamekit:vec2 (random +segments-across-width+)
                (random +segments-across-height+)))

(defmethod gamekit:post-initialize ((this snake-game))
  (with-slots (current-state) this
    (labels ((start ()
               (setf current-state (make-instance 'game-state :end #'end)))
             (end ()
               (setf current-state (make-instance 'game-over-state :restart #'start))))
      (setf current-state (make-instance 'main-menu-state :start #'start)))
    (macrolet ((%%binder (key &body body)
                 "Binds one KEY to execute BODY on press."
                 `(gamekit:bind-button ,key :pressed #'(lambda () ,@body)))
               (%binder ((&rest keys))
                 "Binds all KEYS."
                 `(dolist (key ,keys)
                    (%%binder key (handle-key current-state key)))))
      (%binder '(:w :a :s :d :space :q :e)))))

(defmethod gamekit:act ((this snake-game))
  (with-slots (current-state) this
    (update current-state)))

(defmethod gamekit:draw ((this snake-game))
  (with-slots (current-state) this
    (draw current-state)))

(defun play (&optional blocking)
  "Let's get crackalackin'."
  (gamekit:start 'snake-game :viewport-resizable nil
                             :blocking blocking
                             :swap-interval 1))
