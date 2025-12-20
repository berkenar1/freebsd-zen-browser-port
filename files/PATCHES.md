# Memory Allocation Patch Reference

This document provides a detailed reference for each memory allocation patch in the FreeBSD Zen Browser port.

## Patch Overview

| Patch File | Target | Purpose |
|------------|--------|---------|
| `patch-memory_build_Fallback.cpp` | `memory/build/Fallback.cpp` | Include malloc_np.h and define HAVE_MEMALIGN |
| `patch-memory_build_mozjemalloc.cpp` | `memory/build/mozjemalloc.cpp` | Remove noexcept(true) and disable RTLD_DEEPBIND |
| `patch-memory_build_mozmemory.h` | `memory/build/mozmemory.h` | Conditional noexcept removal |
| `patch-memory_build_mozmemory__wrap.cpp` | `memory/build/mozmemory_wrap.cpp` | Adapt wrapper declarations |
| `patch-memory_mozalloc_mozalloc.cpp` | `memory/mozalloc/mozalloc.cpp` | Provide memalign() for non-jemalloc builds |
| `patch-memory_mozalloc_mozalloc.h` | `memory/mozalloc/mozalloc.h` | Remove noexcept from mozalloc API |

## Detailed Patch Analysis

### patch-memory_build_Fallback.cpp

**Purpose:** Enable the fallback memory allocator to work on FreeBSD

**Changes:**
```cpp
+#ifdef __FreeBSD__
+#  include <malloc_np.h>
+#  define HAVE_MEMALIGN 1
+#endif
```

**Rationale:**
- Includes FreeBSD's non-portable malloc extensions (`malloc_np.h`)
- Defines `HAVE_MEMALIGN` to indicate memalign is available (via our wrapper)
- Used when system allocator is preferred over jemalloc

### patch-memory_build_mozjemalloc.cpp

**Purpose:** Adapt Mozilla's jemalloc for FreeBSD

**Changes:**
1. Remove `noexcept(true)` from malloc declarations:
```cpp
+#if defined(__FreeBSD__)
+#define NOTHROW_MALLOC_DECL(...) \
+  MOZ_MEMORY_API MACRO_CALL(GENERIC_MALLOC_DECL, (, __VA_ARGS__))
+#else
 #define NOTHROW_MALLOC_DECL(...) \
   MOZ_MEMORY_API MACRO_CALL(GENERIC_MALLOC_DECL, (noexcept(true), __VA_ARGS__))
+#endif
```

2. Disable RTLD_DEEPBIND usage:
```cpp
-#elif defined(RTLD_DEEPBIND)
+#elif defined(RTLD_DEEPBIND) && !defined(__FreeBSD__)
```

**Rationale:**
- FreeBSD's C++ ABI handles exception specifications differently
- `noexcept(true)` can cause ABI compatibility issues
- `RTLD_DEEPBIND` is not available on FreeBSD
- These changes allow jemalloc to compile without ABI mismatches

### patch-memory_build_mozmemory.h

**Purpose:** Adapt memory API declarations for FreeBSD

**Changes:**
```cpp
+#if defined(__FreeBSD__)
+#define NOTHROW_MALLOC_DECL(name, return_type, ...) \
+  MOZ_JEMALLOC_API return_type name(__VA_ARGS__);
+#else
 #define NOTHROW_MALLOC_DECL(name, return_type, ...) \
   MOZ_JEMALLOC_API return_type name(__VA_ARGS__) noexcept(true);
+#endif
```

**Rationale:**
- Removes `noexcept(true)` from public API declarations on FreeBSD
- Ensures API declarations match implementation (from mozjemalloc.cpp)
- Prevents linker errors due to name mangling differences

### patch-memory_build_mozmemory__wrap.cpp

**Purpose:** Adapt memory function wrappers for FreeBSD

**Changes:**
```cpp
+#if defined(__FreeBSD__)
+#define NOTHROW_MALLOC_DECL(name, return_type, ...) \
+  MOZ_MEMORY_API return_type name##_impl(__VA_ARGS__);
+#else
 #define NOTHROW_MALLOC_DECL(name, return_type, ...) \
   MOZ_MEMORY_API return_type name##_impl(__VA_ARGS__) noexcept(true);
+#endif
```

**Rationale:**
- Wrapper functions use `_impl` suffix internally
- Must match exception specifications with actual implementations
- Prevents wrapper/implementation ABI mismatches

### patch-memory_mozalloc_mozalloc.cpp

**Purpose:** Provide memalign() for builds without jemalloc

**Changes:**
```cpp
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
```

**Rationale:**
- When `MOZ_MEMORY` is not defined (jemalloc disabled), need system memalign
- FreeBSD doesn't have native memalign(), so we provide a wrapper
- Uses `posix_memalign()` which is POSIX standard and available on FreeBSD
- Includes `malloc_np.h` for other memory functions needed by mozalloc

### patch-memory_mozalloc_mozalloc.h

**Purpose:** Adapt mozalloc API declarations for FreeBSD

**Changes:**
```cpp
+#  if defined(__FreeBSD__)
+#    define NOTHROW_MALLOC_DECL(name, return_type, ...) \
+      MOZ_MEMORY_API return_type name##_impl(__VA_ARGS__);
+#  else
 #  define NOTHROW_MALLOC_DECL(name, return_type, ...) \
     MOZ_MEMORY_API return_type name##_impl(__VA_ARGS__) noexcept(true);
+#  endif
```

**Rationale:**
- Ensures mozalloc header declarations match implementation
- Removes `noexcept(true)` to match FreeBSD ABI requirements
- Used by code that includes mozalloc.h

## Patch Application Order

Patches are applied in filename alphabetical order by the Makefile:

1. Fallback.cpp - Sets up fallback allocator
2. mozjemalloc.cpp - Core jemalloc implementation
3. mozmemory.h - API declarations
4. mozmemory_wrap.cpp - Wrapper implementations
5. mozalloc_mozalloc.cpp - Alternative allocator implementation
6. mozalloc_mozalloc.h - Alternative allocator API

The order generally doesn't matter since patches target different files, but this ordering is logical (core → API → wrappers → alternatives).

## Testing Patch Application

Use the provided verification script:

```bash
cd files
./verify_patches.sh
```

This checks:
- Proper patch format (unified diff)
- No build artifacts in patches
- Presence of diff hunks

## Common Issues and Solutions

### Issue: Patch Fails to Apply

**Symptom:** `patch: malformed patch at line N`

**Solution:**
- Check that patch has proper `---` and `+++` headers
- Ensure patch is in unified diff format (`diff -u` or `git diff`)
- Verify line endings are Unix-style (LF, not CRLF)
- Check context lines match the source file

### Issue: Build Errors After Patching

**Symptom:** Compilation fails with undefined symbols

**Solution:**
- Ensure wrapper headers (malloc.h, etc.) are in place
- Verify `CPPFLAGS += -I${FILESDIR}` in Makefile
- Check that all memory patches are applied
- Confirm FreeBSD system has malloc_np.h

### Issue: Runtime Memory Corruption

**Symptom:** Segfaults or malloc errors during execution

**Solution:**
- Verify memalign() wrapper correctly implements alignment
- Check that malloc_usable_size() is from malloc_np.h
- Test with `test_malloc_wrapper.c`
- Run with malloc debugging: `MALLOC_OPTIONS=AJ ./zen-bin`

## Version Compatibility

These patches are designed for:
- FreeBSD 13.x and later
- Mozilla/Gecko-based browsers (Firefox 100+)
- Zen Browser 1.17.x

Adjustments may be needed for:
- Older FreeBSD versions (pre-13.0)
- Significantly different Mozilla versions
- Other BSD variants (OpenBSD, NetBSD, DragonflyBSD)

## Contributing Patches

When creating new memory-related patches:

1. **Identify the issue** - Understand what fails and why
2. **Minimal changes** - Only modify what's necessary
3. **Test thoroughly** - Build and run tests
4. **Document** - Explain the rationale
5. **Follow format** - Use unified diff with `-p0` format

Example patch creation:
```bash
cd work/
cp path/to/file.cpp path/to/file.cpp.orig
# Edit file.cpp
diff -u path/to/file.cpp.orig path/to/file.cpp > ../files/patch-path_to_file.cpp
```

## See Also

- [MEMORY_ALLOCATION.md](../MEMORY_ALLOCATION.md) - High-level architecture
- [README.md](README.md) - Wrapper headers documentation
- [FreeBSD Porter's Handbook](https://docs.freebsd.org/en/books/porters-handbook/)
