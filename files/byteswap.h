/*
 * glibc byteswap.h compatibility wrapper for FreeBSD
 * 
 * Provides glibc-style byte swapping function names (bswap_16, bswap_32, bswap_64)
 * by mapping them to FreeBSD's native functions (bswap16, bswap32, bswap64)
 * or OpenBSD's swap* functions.
 */

#ifndef _BYTESWAP_H
#define _BYTESWAP_H

#include <sys/endian.h>

#ifdef __OpenBSD__
#define bswap_16(x)	swap16(x)
#define bswap_32(x)	swap32(x)
#define bswap_64(x)	swap64(x)
#else
/* FreeBSD, NetBSD, and other BSD variants use bswap* naming */
#define bswap_16(x)	bswap16(x)
#define bswap_32(x)	bswap32(x)
#define bswap_64(x)	bswap64(x)
#endif
#endif /* _BYTESWAP_H */
