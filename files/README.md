# FreeBSD Compatibility Wrappers for Mozilla/Zen Browser

## Overview

This directory contains compatibility wrappers and patches to enable Mozilla Firefox/Zen Browser code (which targets glibc) to compile and run on FreeBSD (which uses BSD libc).

## Memory Allocation Compatibility

### The Problem

Mozilla's code (originally developed for Linux/glibc) uses memory allocation functions and conventions that differ from FreeBSD's libc:

1. **`memalign()` function**: 
   - glibc provides `memalign(alignment, size)`
   - FreeBSD only provides the POSIX `posix_memalign(ptr, alignment, size)` interface

2. **`malloc_usable_size()` function**:
   - glibc: Available in `<malloc.h>`
   - FreeBSD: Available in `<malloc_np.h>` (non-portable extensions)

3. **C++ ABI differences**:
   - `noexcept(true)` specifier not compatible with FreeBSD's C++ ABI in certain contexts

### The Solution: Wrapper Headers

We use preprocessor include path priority (`CPPFLAGS += -I${FILESDIR}`) to inject compatibility wrappers:

#### `malloc.h` - Memory Allocation Wrapper
- Includes FreeBSD's `<malloc_np.h>` to get `malloc_usable_size()`
- Provides inline `memalign()` wrapper that calls `posix_memalign()`
- Enables Mozilla code to use glibc-style APIs seamlessly

#### `endian.h` - Endianness Wrapper
- Redirects glibc's `<endian.h>` to BSD's `<sys/endian.h>`

#### `byteswap.h` - Byte Swapping Wrapper
- Maps glibc's `bswap_16/32/64` to BSD's `bswap16/32/64`
- Handles OpenBSD's `swap*` variants as well

## Mozilla Memory Subsystem Patches

### Core Memory Patches

1. **`patch-memory_build_mozjemalloc.cpp`**
   - Removes `noexcept(true)` from malloc declarations on FreeBSD
   - Disables `RTLD_DEEPBIND` usage (not available on FreeBSD)

2. **`patch-memory_build_mozmemory.h`**
   - Conditionally removes `noexcept(true)` from memory API declarations

3. **`patch-memory_build_mozmemory__wrap.cpp`**
   - Adapts memory wrapper to FreeBSD's C++ ABI

4. **`patch-memory_build_Fallback.cpp`**
   - Includes `<malloc_np.h>` on FreeBSD
   - Defines `HAVE_MEMALIGN` to use our wrapper

5. **`patch-memory_mozalloc_mozalloc.cpp`**
   - Provides `memalign()` wrapper for non-jemalloc builds
   - Includes `<malloc_np.h>` for malloc_usable_size

6. **`patch-memory_mozalloc_mozalloc.h`**
   - Removes `noexcept(true)` from mozalloc API on FreeBSD

### Why Multiple Patches?

Mozilla has multiple memory allocator configurations:
- **jemalloc enabled** (default): Uses Mozilla's jemalloc
- **jemalloc disabled**: Falls back to system allocator
- **Static runtime**: Different symbol resolution

Each configuration needs FreeBSD-specific adaptations.

## Build System Integration

The Makefile enables these wrappers via:

```make
CPPFLAGS += -I${FILESDIR}
```

This ensures our wrapper headers are found **before** system headers, allowing us to intercept and adapt glibc-specific includes.

## Testing

After applying these patches:
1. Mozilla's jemalloc should build with FreeBSD compatibility
2. Memory allocation functions work transparently
3. No runtime memory corruption or leaks

## References

- FreeBSD malloc_np.h: Non-portable malloc extensions
- Mozilla jemalloc: memory/build/
- POSIX memalign: https://pubs.opengroup.org/onlinepubs/9699919799/functions/posix_memalign.html
