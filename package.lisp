(defpackage cpu-temperature
  (:use #:cl #:cffi)
  (:export #:temperature-error
           #:get-dev.cpu-temperature))
