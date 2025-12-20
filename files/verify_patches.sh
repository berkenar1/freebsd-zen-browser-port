#!/bin/sh
#
# Verify that all FreeBSD memory allocation patches are syntactically correct
# This script checks patch file format without applying them
#

set -e

FILESDIR="$(dirname "$0")"
cd "$FILESDIR"

echo "Verifying FreeBSD memory allocation patches..."
echo "=============================================="
echo

patch_count=0
error_count=0

for patch in patch-memory_*; do
    if [ -f "$patch" ]; then
        patch_count=$((patch_count + 1))
        echo "Checking: $patch"
        
        # Verify patch file has proper header
        if ! head -1 "$patch" | grep -q "^--- "; then
            echo "  ERROR: Missing proper patch header (--- line)"
            error_count=$((error_count + 1))
            continue
        fi
        
        if ! head -2 "$patch" | tail -1 | grep -q "^+++ "; then
            echo "  ERROR: Missing proper patch header (+++ line)"
            error_count=$((error_count + 1))
            continue
        fi
        
        # Check for common issues
        if grep -q "^patch:" "$patch"; then
            echo "  WARNING: Contains build artifacts (patch: target)"
            error_count=$((error_count + 1))
            continue
        fi
        
        if grep -q "^build:" "$patch"; then
            echo "  WARNING: Contains build artifacts (build: target)"
            error_count=$((error_count + 1))
            continue
        fi
        
        # Verify it has actual diff content
        if ! grep -q "^@@ " "$patch"; then
            echo "  ERROR: No diff hunks found (missing @@ markers)"
            error_count=$((error_count + 1))
            continue
        fi
        
        echo "  OK"
    fi
done

echo
echo "=============================================="
echo "Checked $patch_count patch files"

if [ $error_count -eq 0 ]; then
    echo "Status: All patches OK ✓"
    exit 0
else
    echo "Status: Found $error_count error(s) ✗"
    exit 1
fi
