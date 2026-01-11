# FreeBSD Zen Browser Port

FreeBSD port of [Zen Browser](https://zen-browser.app) - a privacy-focused, high-performance web browser built on Firefox's Gecko engine.

## Overview

This port provides FreeBSD-specific compatibility layers and patches to enable Zen Browser (originally developed for Linux with glibc) to build and run on FreeBSD systems.

## Key Features

- ✅ **Full Memory Allocation Compatibility** - Comprehensive glibc/libc compatibility layer
- ✅ **Mozilla jemalloc Support** - Custom memory allocator fully functional on FreeBSD
- ✅ **BSD Endianness Support** - Byte order and swapping function compatibility
- ✅ **WebRTC Support** - Real-time communication features enabled
- ✅ **ALSA Compatibility** - Audio subsystem patches for FreeBSD
- ✅ **Comprehensive Documentation** - Detailed guides for maintainers and developers

## Quick Start

### For Users

```bash
# Build and install from ports
cd /usr/ports/www/zen-browser
make install clean
```

### For Developers

```bash
# Clone the repository
git clone https://github.com/berkenar1/freebsd-zen-browser-port.git
cd freebsd-zen-browser-port

# Build
make clean
make configure
make build
```

## Memory Allocation Compatibility

The centerpiece of this port is a comprehensive memory allocation compatibility layer that addresses differences between glibc and FreeBSD's libc.

### The Challenge

Mozilla/Zen Browser code uses glibc-specific memory allocation APIs:
- `memalign()` - Not available on FreeBSD (use `posix_memalign()` instead)
- `malloc_usable_size()` - In `<malloc.h>` on glibc, but `<malloc_np.h>` on FreeBSD
- `noexcept(true)` - C++ exception specifications differ between glibc and FreeBSD

### The Solution

We provide wrapper headers that translate glibc APIs to FreeBSD equivalents:

```
Mozilla Code → Wrapper Headers → FreeBSD libc
               (files/*.h)
```

The wrappers are injected via preprocessor include path priority:
```make
CPPFLAGS += -I${FILESDIR}
```

### Documentation

- **[QUICKSTART.md](QUICKSTART.md)** - Quick start guide for maintainers and developers
- **[MEMORY_ALLOCATION.md](MEMORY_ALLOCATION.md)** - Architecture and design decisions
- **[files/README.md](files/README.md)** - Wrapper headers and patch overview
- **[files/PATCHES.md](files/PATCHES.md)** - Detailed reference for each patch

## Components

### Wrapper Headers (`files/`)

| File | Purpose |
|------|---------|
| `malloc.h` | Provides `memalign()` and `malloc_usable_size()` compatibility |
| `endian.h` | Redirects glibc `<endian.h>` to BSD `<sys/endian.h>` |
| `byteswap.h` | Maps glibc byte-swapping functions to BSD equivalents |

### Memory Allocation Patches (`files/patch-memory_*`)

| Patch | Purpose |
|-------|---------|
| `patch-memory_build_Fallback.cpp` | Include malloc_np.h and define HAVE_MEMALIGN |
| `patch-memory_build_mozjemalloc.cpp` | Remove noexcept, disable RTLD_DEEPBIND |
| `patch-memory_build_mozmemory.h` | Adapt API declarations for FreeBSD |
| `patch-memory_build_mozmemory__wrap.cpp` | Adapt wrapper declarations |
| `patch-memory_mozalloc_mozalloc.cpp` | Provide memalign() for non-jemalloc builds |
| `patch-memory_mozalloc_mozalloc.h` | Remove noexcept from mozalloc API |

### Other Patches (`files/patch-*`)

Additional patches for:
- WebRTC support on FreeBSD
- ALSA audio compatibility
- SQLite3 memory allocation
- Build system configuration

## Testing

### Wrapper Function Tests

```bash
cd files
cc -I. test_malloc_wrapper.c -o test_malloc_wrapper
./test_malloc_wrapper
```

### Patch Validation

```bash
cd files
./verify_patches.sh
```

### Full Build Test

```bash
make clean
make configure
make build
```

## Build System

The FreeBSD port uses standard FreeBSD Ports Makefile conventions:

- **USES**: `tar:zst gmake python:3.11,build compiler:c17-lang desktop-file-utils gl gnome localbase:ldflags pkgconfig`
- **Mozilla Options**: `--without-wasm-sandboxed-libraries --enable-jemalloc --with-ccache`

## Port automation (rust vendoring)

To make builds reproducible the port now automates Rust vendoring and small Cargo.toml fixes before configure:

- `files/patch_rust_manifests.sh` — replaces `edition.workspace = true` usages with `edition = "2021"` where needed.
- `make cargo-crates` (run by `do-configure`) vendors crates and generates `Makefile.crates`.

These steps are idempotent and run during `make configure`. If you modify Cargo.toml or `Cargo.lock`, re-run `make cargo-crates` and `make makesum`.

Note on build parallelism: to avoid passing problematic MAKEFLAGS into GNU make, the port clears MAKEFLAGS for the child build and therefore builds run serially by default. To run a parallel build manually, change into the work directory and run the build with MAKEFLAGS set, for example:

    cd work && env MAKEFLAGS='-j12' ./mach build

(We intentionally avoid forwarding arbitrary MAKEFLAGS to gmake to keep builds reproducible and safe.)
- **Wrapper Injection**: `CPPFLAGS += -I${FILESDIR}`
- **Patch Application**: Automatic during `post-patch` phase

## Requirements

### Build Dependencies

- nspr >= 4.32
- nss >= 3.118
- icu >= 76.1
- libevent >= 2.1.8
- harfbuzz >= 10.1.0
- Python 3.11+
- Rust toolchain
- ccache (optional, for faster rebuilds)

### Runtime Dependencies

- gtk30
- cairo
- gdk-pixbuf2
- Various multimedia codecs (dav1d, libvpx)

See `Makefile` for complete dependency list.

## Architecture

```
┌─────────────────────────────────────────┐
│     Mozilla/Zen Browser Source Code    │
│     (glibc-specific includes)           │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│     Wrapper Headers (files/*.h)         │
│     • malloc.h                          │
│     • endian.h                          │
│     • byteswap.h                        │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│     Memory Patches (patch-memory_*)     │
│     • noexcept removal                  │
│     • malloc_np.h inclusion             │
│     • memalign() wrapper                │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│     FreeBSD libc + malloc_np            │
│     • posix_memalign()                  │
│     • malloc_usable_size()              │
└─────────────────────────────────────────┘
```

## Contributing

Contributions welcome! When submitting patches:

1. Follow minimal change principle
2. Document the rationale
3. Test on actual FreeBSD system
4. Update relevant documentation
5. Run validation scripts

See [QUICKSTART.md](QUICKSTART.md) for detailed contribution guidelines.

## Known Issues

- WASM sandboxed libraries not supported (wasi-sysroot unavailable on FreeBSD)
- Some WebRTC features may have limitations

## Future Improvements

- [ ] Upstream contributions to Mozilla for better BSD support
- [ ] Additional wrapper functions as needed
- [ ] Performance optimization of wrapper overhead (if any)
- [ ] Support for other BSD variants (OpenBSD, NetBSD, DragonflyBSD)

## License

This FreeBSD port is provided under the Mozilla Public License 2.0 (MPL 2.0), consistent with Zen Browser and Firefox licensing.

## Credits

- **Zen Browser Team** - Original browser development
- **Mozilla Foundation** - Firefox/Gecko engine
- **FreeBSD Ports Team** - Porting infrastructure and guidance

## Support

- **Issues**: https://github.com/berkenar1/freebsd-zen-browser-port/issues
- **Documentation**: See QUICKSTART.md and MEMORY_ALLOCATION.md
- **FreeBSD Forums**: https://forums.freebsd.org/

## Version

- **Port Version**: 1.17.12b
- **FreeBSD**: 13.x and later
- **Gecko Version**: Based on Firefox 100+

---

**Note**: This is a FreeBSD-specific port. For other operating systems, refer to the [official Zen Browser repository](https://github.com/zen-browser/desktop).
