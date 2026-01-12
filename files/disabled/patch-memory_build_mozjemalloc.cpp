--- memory/build/mozjemalloc.cpp.orig	2025-01-01 00:00:00 UTC
+++ memory/build/mozjemalloc.cpp
@@ -5163,7 +5163,12 @@
     GENERIC_MALLOC_DECL2_MINGW(name, name##_impl, return_type, ##__VA_ARGS__)
 #endif

+#if defined(__FreeBSD__)
+#define NOTHROW_MALLOC_DECL(...) \
+  MOZ_MEMORY_API MACRO_CALL(GENERIC_MALLOC_DECL, (, __VA_ARGS__))
+#else
 #define NOTHROW_MALLOC_DECL(...) \
   MOZ_MEMORY_API MACRO_CALL(GENERIC_MALLOC_DECL, (noexcept(true), __VA_ARGS__))
+#endif
 #define MALLOC_DECL(...) \
   MOZ_MEMORY_API MACRO_CALL(GENERIC_MALLOC_DECL, (, __VA_ARGS__))
@@ -5200,7 +5205,7 @@
 MOZ_EXPORT void* (*__memalign_hook)(size_t, size_t) = memalign_impl;
 }

-#elif defined(RTLD_DEEPBIND)
+#elif defined(RTLD_DEEPBIND) && !defined(__FreeBSD__)
 // XXX On systems that support RTLD_GROUP or DF_1_GROUP, do their
 // implementations permit similar inconsistencies?  Should STV_SINGLETON 
 // visibility be used for interposition where available?
