/*
 * glibc malloc.h compatibility wrapper for FreeBSD
 *
 * This wrapper provides glibc-style memory allocation functions
 * for FreeBSD's libc, enabling Mozilla/Firefox code to compile
 * without modifications.
 *
 * Key differences handled:
 * - memalign() -> posix_memalign() wrapper
 * - malloc_usable_size() from malloc_np.h
 */

#ifndef _MALLOC_H
#define _MALLOC_H

#include <stdlib.h>

#ifdef __FreeBSD__
#include <malloc_np.h>

#ifdef __cplusplus
extern "C" {
#endif

/*
 * memalign() wrapper for FreeBSD
 * glibc provides memalign() but FreeBSD only has posix_memalign()
 * This wrapper translates the glibc interface to FreeBSD's POSIX interface
 */
inline void* memalign(size_t alignment, size_t size) {
    void* ptr = NULL;
    if (posix_memalign(&ptr, alignment, size) != 0) {
        return NULL;
    }
    return ptr;
}

#ifdef __cplusplus
}
#endif

#endif /* __FreeBSD__ */
#endif /* _MALLOC_H */
