--- memory/build/mozmemory_wrap.cpp.orig	2025-01-01 00:00:00 UTC
+++ memory/build/mozmemory_wrap.cpp
@@ -10,8 +10,13 @@
 
 // Declare malloc implementation functions with the right return and
 // argument types.
+#if defined(__FreeBSD__)
+#define NOTHROW_MALLOC_DECL(name, return_type, ...) \
+  MOZ_MEMORY_API return_type name##_impl(__VA_ARGS__);
+#else
 #define NOTHROW_MALLOC_DECL(name, return_type, ...) \
   MOZ_MEMORY_API return_type name##_impl(__VA_ARGS__) noexcept(true);
+#endif
 #define MALLOC_DECL(name, return_type, ...) \
   MOZ_MEMORY_API return_type name##_impl(__VA_ARGS__);
 #define MALLOC_FUNCS MALLOC_FUNCS_MALLOC
