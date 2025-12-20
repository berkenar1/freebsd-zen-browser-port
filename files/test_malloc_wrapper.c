/*
 * Test program to verify glibc compatibility wrappers for FreeBSD
 * 
 * This test should be run on FreeBSD with:
 *   cc -I. test_malloc_wrapper.c -o test_malloc_wrapper
 *   ./test_malloc_wrapper
 * 
 * On Linux, this test uses native glibc functions for comparison.
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <assert.h>

#ifdef __FreeBSD__
/* On FreeBSD, use our compatibility wrapper */
#include "malloc.h"
#else
/* On Linux/glibc, use native headers */
#include <malloc.h>
#endif

int main(void) {
    printf("Testing memory allocation functions...\n");
    
#ifdef __FreeBSD__
    printf("Running on FreeBSD with compatibility wrapper\n\n");
#else
    printf("Running on Linux with native glibc (for comparison)\n\n");
#endif
    
    /* Test 1: memalign() */
    printf("Test 1: memalign() wrapper\n");
    void* aligned_ptr = memalign(64, 1024);
    if (aligned_ptr == NULL) {
        fprintf(stderr, "FAIL: memalign returned NULL\n");
        return 1;
    }
    
    /* Check alignment */
    if (((uintptr_t)aligned_ptr % 64) != 0) {
        fprintf(stderr, "FAIL: pointer not properly aligned (expected 64-byte alignment)\n");
        free(aligned_ptr);
        return 1;
    }
    printf("  PASS: memalign(64, 1024) returned properly aligned pointer: %p\n", aligned_ptr);
    
    /* Write to the memory to ensure it's usable */
    memset(aligned_ptr, 0xAB, 1024);
    printf("  PASS: Memory is writable\n");
    
    /* Test 2: malloc_usable_size() */
    printf("\nTest 2: malloc_usable_size()\n");
    size_t usable = malloc_usable_size(aligned_ptr);
    printf("  malloc_usable_size() returned: %zu bytes\n", usable);
    if (usable < 1024) {
        fprintf(stderr, "FAIL: usable size (%zu) less than requested (1024)\n", usable);
        free(aligned_ptr);
        return 1;
    }
    printf("  PASS: Usable size is at least as large as requested\n");
    
    free(aligned_ptr);
    
    /* Test 3: malloc_usable_size() with regular malloc */
    printf("\nTest 3: malloc_usable_size() with regular malloc\n");
    void* regular_ptr = malloc(512);
    if (regular_ptr == NULL) {
        fprintf(stderr, "FAIL: malloc returned NULL\n");
        return 1;
    }
    
    usable = malloc_usable_size(regular_ptr);
    printf("  malloc_usable_size(malloc(512)) returned: %zu bytes\n", usable);
    if (usable < 512) {
        fprintf(stderr, "FAIL: usable size (%zu) less than requested (512)\n", usable);
        free(regular_ptr);
        return 1;
    }
    printf("  PASS: Usable size is valid\n");
    
    free(regular_ptr);
    
    /* Test 4: Multiple memalign calls with different alignments */
    printf("\nTest 4: Various alignment values\n");
    size_t alignments[] = {8, 16, 32, 64, 128, 256};
    size_t num_alignments = sizeof(alignments) / sizeof(alignments[0]);
    
    for (size_t i = 0; i < num_alignments; i++) {
        void* ptr = memalign(alignments[i], 100);
        if (ptr == NULL) {
            fprintf(stderr, "FAIL: memalign(%zu, 100) returned NULL\n", alignments[i]);
            return 1;
        }
        if (((uintptr_t)ptr % alignments[i]) != 0) {
            fprintf(stderr, "FAIL: memalign(%zu) not properly aligned\n", alignments[i]);
            free(ptr);
            return 1;
        }
        free(ptr);
    }
    printf("  PASS: All alignment values work correctly\n");
    
    printf("\n=================================\n");
    printf("All tests PASSED!\n");
    printf("=================================\n");
    
    return 0;
}
