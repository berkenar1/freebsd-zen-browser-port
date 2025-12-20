/*
 * glibc endian.h compatibility wrapper for FreeBSD
 * 
 * glibc uses <endian.h> while BSD systems use <sys/endian.h>
 * This wrapper redirects to the BSD system header
 */

#ifndef _ENDIAN_H
#define	_ENDIAN_H
#include <sys/endian.h>
#endif /* _ENDIAN_H */
