--- memory/mozalloc/mozalloc.h.orig	2025-01-01 00:00:00 UTC
+++ memory/mozalloc/mozalloc.h
@@ -31,7 +31,12 @@
 // See mozmemory_wrap.h for more details. Files that are part of libmozglue,
 // need to use _impl suffixes, which is becoming cumbersome. We'll have to use
 // something like a malloc.h wrapper and allow the use of the functions without
 // a _impl suffix. In the meanwhile, this is enough to get by for C++ code.
+#  if defined(__FreeBSD__)
+#    define NOTHROW_MALLOC_DECL(name, return_type, ...) \
+      MOZ_MEMORY_API return_type name##_impl(__VA_ARGS__);
+#  else
 #  define NOTHROW_MALLOC_DECL(name, return_type, ...) \
     MOZ_MEMORY_API return_type name##_impl(__VA_ARGS__) noexcept(true);
+#  endif
 #  define MALLOC_DECL(name, return_type, ...) \
