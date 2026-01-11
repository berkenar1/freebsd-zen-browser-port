--- memory/build/Fallback.cpp.orig	2025-01-01 00:00:00 UTC
+++ memory/build/Fallback.cpp
@@ -6,6 +6,12 @@
 
 #include "mozmemory.h"
 #include "mozjemalloc.h"
+
+#ifdef __FreeBSD__
+#  include <malloc_np.h>
+#  define HAVE_MEMALIGN 1
+#endif
+
 #include <stdlib.h>
 
 #ifndef HAVE_MEMALIGN
