--- memory/build/mozmemory.h.orig	2025-01-01 00:00:00 UTC
+++ memory/build/mozmemory.h
@@ -67,7 +67,12 @@

 #endif  // MOZ_MEMORY

+#if defined(__FreeBSD__)
+#define NOTHROW_MALLOC_DECL(name, return_type, ...) \
+  MOZ_JEMALLOC_API return_type name(__VA_ARGS__);
+#else
 #define NOTHROW_MALLOC_DECL(name, return_type, ...) \
   MOZ_JEMALLOC_API return_type name(__VA_ARGS__) noexcept(true);
+#endif
 #define MALLOC_DECL(name, return_type, ...) \
   MOZ_JEMALLOC_API return_type name(__VA_ARGS__);
