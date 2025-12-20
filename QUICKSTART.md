# Quick Start Guide: Memory Allocation Compatibility

## For Port Maintainers

### Building the Port

The memory allocation compatibility layer is automatically applied during the build:

```bash
# Standard FreeBSD port build
make clean
make configure
make build
make install
```

The Makefile automatically:
1. Sets up include path: `CPPFLAGS += -I${FILESDIR}`
2. Applies all patches during `post-patch` phase
3. Builds with jemalloc enabled: `--enable-jemalloc`

### Verifying the Patches

Before building, verify patches are valid:

```bash
cd files
./verify_patches.sh
```

Expected output:
```
Verifying FreeBSD memory allocation patches...
==============================================

Checking: patch-memory_build_Fallback.cpp
  OK
Checking: patch-memory_build_mozjemalloc.cpp
  OK
... (6 patches total)

Status: All patches OK ✓
```

### Testing the Wrappers

Test memory allocation wrappers on FreeBSD:

```bash
cd files
cc -I. test_malloc_wrapper.c -o test_malloc_wrapper
./test_malloc_wrapper
```

Expected output:
```
Testing memory allocation functions...
Running on FreeBSD with compatibility wrapper

Test 1: memalign() wrapper
  PASS: memalign(64, 1024) returned properly aligned pointer
...
=================================
All tests PASSED!
=================================
```

## For Developers

### Understanding the Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   Mozilla/Zen Browser Code              │
│              #include <malloc.h>                        │
│              memalign(), malloc_usable_size()           │
└─────────────────────┬───────────────────────────────────┘
                      │
                      │ Preprocessor includes
                      │ (-I${FILESDIR} priority)
                      │
┌─────────────────────▼───────────────────────────────────┐
│              files/malloc.h (Wrapper)                   │
│  • Includes <malloc_np.h> for malloc_usable_size()     │
│  • Provides memalign() via posix_memalign()            │
└─────────────────────┬───────────────────────────────────┘
                      │
                      │ System headers
                      │
┌─────────────────────▼───────────────────────────────────┐
│              FreeBSD libc                               │
│  • posix_memalign() ✓                                  │
│  • malloc_usable_size() (malloc_np.h) ✓                │
│  • malloc(), free(), etc. ✓                            │
└─────────────────────────────────────────────────────────┘
```

### Key Components

1. **Wrapper Headers** (`files/`)
   - `malloc.h` - glibc memory allocation compatibility
   - `endian.h` - endianness API compatibility
   - `byteswap.h` - byte swapping compatibility

2. **Mozilla Memory Patches** (`files/patch-memory_*`)
   - Remove `noexcept(true)` for FreeBSD C++ ABI
   - Include `malloc_np.h` where needed
   - Provide memalign() in non-jemalloc builds

3. **Documentation**
   - `MEMORY_ALLOCATION.md` - Architecture overview
   - `files/README.md` - Wrapper and patch guide
   - `files/PATCHES.md` - Detailed patch reference

### Adding New Patches

1. **Identify the problem:**
   ```bash
   make build 2>&1 | tee build.log
   grep -i "error\|undefined" build.log
   ```

2. **Create the patch:**
   ```bash
   cd work/
   cp path/to/file.cpp path/to/file.cpp.orig
   # Make your changes to file.cpp
   diff -u path/to/file.cpp.orig path/to/file.cpp > ../files/patch-path_to_file.cpp
   ```

3. **Test the patch:**
   ```bash
   cd files
   ./verify_patches.sh
   cd ..
   make clean
   make configure
   make build
   ```

4. **Document the patch:**
   - Add description to `files/PATCHES.md`
   - Update `files/README.md` if needed

## Common Issues and Solutions

### Issue 1: memalign() not found

**Error message:**
```
error: use of undeclared identifier 'memalign'
```

**Solution:**
✓ Already fixed by `files/malloc.h` wrapper
- Provides inline memalign() using posix_memalign()
- Automatically included via -I${FILESDIR}

### Issue 2: malloc_usable_size() not found

**Error message:**
```
error: use of undeclared identifier 'malloc_usable_size'
```

**Solution:**
✓ Already fixed by `files/malloc.h` wrapper
- Includes `<malloc_np.h>` which provides this function
- Available via wrapper header

### Issue 3: noexcept(true) ABI mismatch

**Error message:**
```
undefined reference to `malloc' (with different exception specification)
```

**Solution:**
✓ Already fixed by patches:
- `patch-memory_build_mozjemalloc.cpp`
- `patch-memory_build_mozmemory.h`
- `patch-memory_build_mozmemory__wrap.cpp`
- `patch-memory_mozalloc_mozalloc.h`

All remove `noexcept(true)` on FreeBSD

## Build System Integration

### Makefile Configuration

```make
# Include wrappers before system headers
CPPFLAGS += -I${FILESDIR}

# Enable Mozilla's jemalloc
MOZ_OPTIONS += --enable-jemalloc

# Apply patches
post-patch:
	@for p in ${FILESDIR}/patch-*; do \
		${PATCH} -d ${WRKSRC} -p0 < $$p || exit 1; \
	done
```

### Environment Variables

No special environment variables needed. The build system automatically:
- Uses correct compiler flags
- Applies patches
- Includes wrapper headers

## Troubleshooting

### Build Fails with Patch Error

```bash
# Check patch format
cd files
./verify_patches.sh

# Manually test patch
cd work
patch -p0 --dry-run < ../files/patch-memory_build_mozjemalloc.cpp
```

### Runtime Memory Issues

```bash
# Enable malloc debugging
env MALLOC_OPTIONS=AJ ./zen-bin

# Run with valgrind (if available)
valgrind --leak-check=full ./zen-bin
```

### Verify Wrapper Compilation

```bash
# Check if wrapper is being used
cd files
cc -E -I. -dM malloc.h | grep memalign

# Should show our inline function definition
```

## Performance Notes

The wrapper functions have **negligible performance overhead**:

1. **memalign() wrapper**: Inline function, compiler optimizes to direct call
2. **malloc_usable_size()**: Direct function pointer, no overhead
3. **endian/byteswap**: Preprocessor macros, zero runtime cost

## Security Considerations

The compatibility layer maintains security properties:

1. **Alignment validation**: posix_memalign() validates alignment requirements
2. **Error handling**: Proper NULL returns on allocation failure
3. **No buffer overflows**: Uses standard library functions correctly
4. **Type safety**: Inline functions provide compile-time type checking

## References

- **FreeBSD Handbook**: https://docs.freebsd.org/en/books/porters-handbook/
- **Mozilla Memory Docs**: https://firefox-source-docs.mozilla.org/memory/
- **POSIX memalign**: https://pubs.opengroup.org/onlinepubs/9699919799/
- **FreeBSD malloc_np**: https://man.freebsd.org/cgi/man.cgi?query=malloc_np

## Getting Help

If you encounter issues:

1. Check documentation in this repository
2. Review build logs carefully
3. Test wrappers with `test_malloc_wrapper.c`
4. Verify patches with `verify_patches.sh`
5. Open an issue on GitHub with build logs

## License

This compatibility layer is provided under MPL 2.0, same as Zen Browser.
