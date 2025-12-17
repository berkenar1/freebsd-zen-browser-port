--- memory/mozalloc/mozalloc.cpp.orig2024-01-01 00:00:00 UTC
+++ memory/mozalloc/mozalloc.cpp
@@ -14,6 +14,17 @@
 #if !defined(MOZ_MEMORY)
 // When jemalloc is disabled, or when building the static runtime variant,
 // we need not to use the suffixes.
+
+#  if defined(__FreeBSD__)
+#    include <malloc_np.h>
+extern "C" void* memalign(size_t boundary, size_t size) {
+  void* ptr = nullptr;
+  if (posix_memalign(&ptr, boundary, size) != 0) {
+    return nullptr;
+  }
+  return ptr;
+}
+#  endif
 
 #  include <stdlib.h>  // for malloc, free
 #  if defined(XP_UNIX)
