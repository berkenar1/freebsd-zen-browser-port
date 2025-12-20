--- third_party/sqlite3/src/sqlite3.c.orig	2025-01-01 00:00:00 UTC
+++ third_party/sqlite3/src/sqlite3.c
@@ -27240,7 +27240,12 @@
 ** The memory size function can always be overridden manually by defining
 ** the macro SQLITE_MALLOCSIZE to the desired function name.
 */
+#if defined(__FreeBSD__)
+#  include <malloc_np.h>
+#  define SQLITE_MALLOCSIZE(x)   malloc_usable_size(x)
+#elif defined(SQLITE_USE_MALLOC_H)
-#if defined(SQLITE_USE_MALLOC_H)
 #  include <malloc.h>
 #  if defined(SQLITE_USE_MALLOC_USABLE_SIZE)
 #    if !defined(SQLITE_MALLOCSIZE)
