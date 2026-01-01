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

### Unit Test

A test program is provided in `test_malloc_wrapper.c` to verify the wrappers work correctly.

**On FreeBSD:**
```bash
cd files
cc -I. test_malloc_wrapper.c -o test_malloc_wrapper
./test_malloc_wrapper
```

**On Linux (for comparison):**
```bash
cd files
cc test_malloc_wrapper.c -o test_malloc_wrapper
./test_malloc_wrapper
```

The test verifies:
1. `memalign()` works with various alignment values (8, 16, 32, 64, 128, 256 bytes)
2. Returned pointers are properly aligned
3. `malloc_usable_size()` returns reasonable values
4. Allocated memory is readable and writable

### Integration Testing

After applying these patches:
1. Mozilla's jemalloc should build with FreeBSD compatibility
2. Memory allocation functions work transparently
3. No runtime memory corruption or leaks

You can verify the build with:
```bash
make clean
make configure
make build
```

## Cargo Workspace Version Handling

### The Problem

Mozilla/Zen Browser uses a Cargo workspace with a root `Cargo.toml` that controls all Rust crate dependencies. When you try to fix crate version mismatches by editing individual `Cargo.toml` files in subdirectories of the work directory, these changes are ineffective because:

1. Cargo resolves all dependencies from the **workspace root** `Cargo.toml`
2. The `Cargo.lock` file is shared across the entire workspace
3. Individual crate `Cargo.toml` files inherit version constraints from the root

### The Solution

The port now includes:

1. **`patch-Cargo.toml`** - A patch template for the root Cargo.toml that:
   - Documents how to add version overrides using `[patch.crates-io]`
   - Explains the workspace dependency resolution mechanism
   - Provides examples for common override patterns

2. **Makefile `pre-configure` target** - Automatically syncs the Cargo.lock file with the workspace root configuration before building.

3. **`CARGO_ENV` variables** - Ensure consistent Cargo behavior:
   - `CARGO_HOME` - Set to a local directory to avoid polluting system cargo
   - `CARGO_TARGET_DIR` - Keep build artifacts in the work directory
   - `CARGO_BUILD_JOBS` - Respect the port's job count setting

### Adding Version Overrides

To fix a specific crate version mismatch, add a `[patch.crates-io]` section to the root `Cargo.toml` patch:

```toml
[patch.crates-io]
# Pin semver to a specific version
semver = { version = "1.0.16" }

# Use a local patched crate
problematic-crate = { path = "third_party/rust/problematic-crate" }
```

For git dependencies:

```toml
[patch."https://github.com/example/repo"]
some-crate = { path = "third_party/rust/some-crate" }
```

After modifying, regenerate the lockfile:
```bash
cd ${WRKSRC} && cargo generate-lockfile
```

## References

- FreeBSD malloc_np.h: Non-portable malloc extensions
- Mozilla jemalloc: memory/build/
- POSIX memalign: https://pubs.opengroup.org/onlinepubs/9699919799/functions/posix_memalign.html
- Cargo Dependency Overrides: https://doc.rust-lang.org/cargo/reference/overriding-dependencies.html
- Cargo Workspaces: https://doc.rust-lang.org/cargo/reference/workspaces.html
