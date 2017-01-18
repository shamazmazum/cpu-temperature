(in-package :cpu-temperature)

(include "sys/types.h")
(include "sys/sysctl.h")
(include "stdlib.h")

(defwrapper* ("getmib" getmib%) :int
  ((name :string)
   (mib :pointer)
   (size :int))
  "int res;
   size_t s = size;

   res = sysctlnametomib (name, mib, &s);
   if (res == 0 && s == size) return 0;
   return -1;")

(defwrapper* ("sysctl_getint" getint%) :int
  ((mib :pointer)
   (size :int))
  "int res, temp;
   size_t s = sizeof (int);

   res = sysctl (mib, size, &temp, &s, NULL, 0);
   return (res == 0) ? temp : res;")

(defwrapper* ("getformat" getformat%) :int
  ((mib :pointer)
   (size :int)
   (buf :pointer))
  "int res;
   size_t s = 256;

   res = sysctl (mib, size, buf, &s, NULL, 0);
   return res;")
