# FreeBSD Memory Allocation Compatibility Layer

## Summary

This FreeBSD port of Zen Browser includes a comprehensive compatibility layer to address memory allocation differences between glibc (GNU C Library) and FreeBSD's libc.

## Problem Statement

Mozilla Firefox/Zen Browser code is primarily developed for Linux with glibc, which provides memory allocation APIs that differ from FreeBSD's implementation:

| Function | glibc | FreeBSD |
|----------|-------|---------|
| `memalign()` | Available directly | Not available (use `posix_memalign()`) |
| `malloc_usable_size()` | In `<malloc.h>` | In `<malloc_np.h>` (non-portable) |
| Exception specs | Supports `noexcept(true)` | C++ ABI differences |

## Solution Architecture

### 1. Header Wrappers (`files/` directory)

We use preprocessor include path manipulation to inject compatibility wrappers **before** system headers:

```make
CPPFLAGS += -I${FILESDIR}
```

This allows our wrappers to intercept glibc-specific includes and provide FreeBSD-compatible implementations.

**Key wrappers:**
- `malloc.h` - Provides `memalign()` and includes `malloc_np.h`
- `endian.h` - Redirects to `<sys/endian.h>`
- `byteswap.h` - Maps byte-swapping function names

### 2. Mozilla Memory Subsystem Patches

Multiple patch files adapt Mozilla's memory allocator to FreeBSD:

- **mozjemalloc** - Mozilla's jemalloc implementation
- **mozmemory** - Memory API declarations
- **mozalloc** - Memory allocation helpers
- **Fallback.cpp** - System allocator fallback

See `files/README.md` for detailed patch descriptions.

## Key Design Decisions

### Why Wrappers Instead of Patching Mozilla Code?

1. **Minimal invasiveness** - Don't modify upstream Mozilla code unnecessarily
2. **Maintainability** - Easier to update to new Zen/Firefox versions
3. **Portability** - Same approach works for other BSD variants
4. **Clarity** - Clear separation between compatibility layer and application code

### Inline vs. Macro Implementations

Our `memalign()` wrapper uses an inline function rather than a macro:

```c
static inline void* memalign(size_t alignment, size_t size) {
    void* ptr = NULL;
    if (posix_memalign(&ptr, alignment, size) != 0) {
        return NULL;
    }
    return ptr;
}
```

**Benefits:**
- Type safety
- Better debugging (preserves function call stack)
- Compiler optimization (inlined anyway)
- Proper C/C++ linkage handling

## Testing

A test suite is provided in `files/test_malloc_wrapper.c` that validates:
- Alignment correctness for various sizes
- Memory usability
- API compatibility

Run tests on FreeBSD:
```bash
cd files && cc -I. test_malloc_wrapper.c -o test && ./test
```

## Build Integration

The FreeBSD port Makefile (`Makefile`) applies all patches during the `post-patch` phase:

```make
post-patch:
	@${ECHO_MSG} "===> Applying FreeBSD patches"
	@for p in ${FILESDIR}/patch-*; do \
		if [ -f "$$p" ]; then \
			${ECHO_MSG} "Applying $${p##*/}"; \
			${PATCH} -d ${WRKSRC} -p0 < $$p || exit 1; \
		fi; \
	done
```

This ensures all compatibility patches are applied before building.

## Future Enhancements

Potential improvements for this compatibility layer:

1. **Additional glibc functions** - Add more wrappers as needed (e.g., `aligned_alloc`)
2. **Performance optimization** - Profile and optimize wrapper overhead
3. **Other BSD variants** - Test and adapt for OpenBSD, NetBSD, DragonflyBSD
4. **Upstream contributions** - Contribute patches back to Mozilla for better BSD support

## Contributing

When adding new patches or wrappers:

1. Document the purpose and rationale
2. Keep changes minimal and focused
3. Test on actual FreeBSD system
4. Update `files/README.md` with patch descriptions
5. Ensure patches are in unified diff format (`-p0` compatible)

## License

These compatibility wrappers and patches are provided under the same license as the Zen Browser port (MPL 2.0).

## References

- [FreeBSD Porter's Handbook](https://docs.freebsd.org/en/books/porters-handbook/)
- [Mozilla Memory Management](https://firefox-source-docs.mozilla.org/memory/)
- [POSIX Memory Alignment](https://pubs.opengroup.org/onlinepubs/9699919799/functions/posix_memalign.html)
- [FreeBSD malloc_np.h](https://man.freebsd.org/cgi/man.cgi?query=malloc_np)
