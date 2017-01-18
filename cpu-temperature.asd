(eval-when (:compile-toplevel :load-toplevel :execute)
  (asdf:oos 'asdf:load-op :cffi-grovel))

(defsystem :cpu-temperature
  :name :cpu-temperature
  :description "CPU temperature getter for FreeBSD"
  :maintainer "Vasily Postnicov <shamaz.mazum at gmail.com>"
  :licence "2-clause BSD"
  :version "0.1"
  :depends-on (:cffi)
  :serial t
  :components ((:file "package")
               (cffi-grovel:wrapper-file "sysctl-wrapper" :soname "libtemp")
               (:file "temperature")))
