(in-package :cpu-temperature)

(defconstant +string-size+ 256)

(defvar *ncpus* nil
  "Number of CPUs")

(defvar *dev.cpu-vector-table* (make-hash-table))

(define-condition temperature-error (error)
  ((message :initform "Undefined error"
            :initarg :message
            :reader error-message))
  (:report (lambda (c s)
             (format s "Cannot get temperature: ~a"
                     (error-message c)))))

(define-condition sysctl-call-error (temperature-error) ())
(define-condition sysctl-parse-error (temperature-error) ())

(defun getmib (name)
  "Get integer vector specifying a sysctl node with name NAME"
  (declare (type string name))
  (let ((size (1+ (count #\. name)))
        (len (1+ (length name))))
    (with-foreign-object (mib :int size)
      (with-foreign-object (str :char len)
        (if (= (getmib% (lisp-string-to-foreign name str len) mib size) 0)
            (make-array size :initial-contents
                        (loop for i below size collect (mem-aref mib :int i)))
            (error 'sysctl-call-error :message "Cannot get node's integer vector"))))))

(defun sysctl-int-raw (vector)
  "Get an integer from a sysctl node specified by VECTOR. The integer is returned as is
without respect to its format"
  (declare (type simple-vector vector))
  (let ((size (length vector)))
    (with-foreign-object (mib :int size)
      (loop for i below size do (setf (mem-aref mib :int i)
                                      (aref vector i)))
      (let ((res (getint% mib size)))
        (if (/= res -1) res (error 'sysctl-call-error :message "Cannot get a sysctl value"))))))

(defun get-format (vector)
  "Get a format string of sysctl node"
  (declare (type simple-vector vector))
  (let* ((size (+ 2 (length vector)))
         (new-vector (concatenate 'vector #(0 4) vector)))
    (with-foreign-object (str :char +string-size+)
      (with-foreign-object (mib :int size)
        (loop for i below size do (setf (mem-aref mib :int i)
                                        (aref new-vector i)))
        (if (/= (getformat% mib size str) 0)
            (error 'sysctl-call-error :message "Cannot get format"))
        (foreign-string-to-lisp str :offset 4 :max-chars 3)))))

(defun sysctl-int (vector)
  "Get a value representated by the integer sysctl specified by VECTOR.
This value is processed using its format, so returned value may or may
not be integer itself"
  (declare (type simple-vector vector))
  (let ((format (get-format vector))
        (temp (sysctl-int-raw vector)))
    (if (not (find #\I format)) (error 'sysctl-parse-error :message "Unknown format"))
    (if (not (find #\K format)) temp
        (let ((prec (if (= (length format) 2) 1
                        (digit-char-p (char format 2)))))
          (if (null prec) (error 'sysctl-parse-error :message "Unknown precision"))
          (- (/ temp (expt 10.0 prec)) 273.15)))))

(defun get-dev.cpu-temperature (cpu)
  "Get a temperature form a cpu with number CPU using `dev.cpu.%i.temperature'
sysctl nodes"
  (declare (type integer cpu))
  (if (not *ncpus*) (setq *ncpus* (sysctl-int (getmib "kern.smp.cpus"))))
  (if (and (>= cpu 0)
           (< cpu *ncpus*))
      (multiple-value-bind (vector found)
          (gethash cpu *dev.cpu-vector-table*
                   (getmib (format nil "dev.cpu.~d.temperature" cpu)))
        (if (not found) (setf (gethash cpu *dev.cpu-vector-table*) vector))
        (sysctl-int vector))
      (error 'temperature-error :message "Wrong CPU number")))
