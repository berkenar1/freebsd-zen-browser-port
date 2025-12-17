--- memory/mozalloc/mozalloc.cpp.orig
+++ memory/mozalloc/mozalloc.cpp
@@ -15,12 +15,22 @@
 #if !defined(MOZ_MEMORY)
 // When jemalloc is disabled, or when building the static runtime variant,
 // we need not to use the suffixes.
 
 #  include <stdlib.h>  // for malloc, free
 #  if defined(XP_UNIX)
 #    include <unistd.h>
 #  endif  // if defined(XP_UNIX)
+
+#  if defined(__FreeBSD__)
+#    include <malloc_np.h>  // for malloc_usable_size and friends
+// FreeBSD doesn't provide memalign; implement it using posix_memalign.
+extern "C" void* memalign(size_t boundary, size_t size) {
+  void* ptr = nullptr;
+  if (posix_memalign(&ptr, boundary, size) != 0) {
+    return nullptr;
+  }
+  return ptr;
+}
+#  endif
 
 #  define malloc_impl malloc
 #  define calloc_impl calloc
 #  define realloc_impl realloc
 #  define free_impl free
 #  define memalign_impl memalign
 #  define malloc_usable_size_impl malloc_usable_size
 #  define strdup_impl strdup
 #  define strndup_impl strndup
 
 #endif
