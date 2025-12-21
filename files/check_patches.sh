#!/bin/sh
#
# check_patches.sh - Check if FreeBSD patches are applied to the source tree
#
# Usage: ./check_patches.sh [work_directory]
#
# Returns:
#   0 - All patches need to be applied (none applied yet)
#   1 - Some or all patches already applied
#

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORK_DIR="${1:-$(dirname "$SCRIPT_DIR")/work}"

if [ ! -d "$WORK_DIR" ]; then
    echo "ERROR: Work directory not found: $WORK_DIR"
    echo "Usage: $0 [work_directory]"
    exit 2
fi

echo "=== FreeBSD Patch Status Check ==="
echo "Patch directory: $SCRIPT_DIR"
echo "Work directory:  $WORK_DIR"
echo ""

APPLIED=0
NOT_APPLIED=0
FAILED=0

for patch in "$SCRIPT_DIR"/patch-*; do
    [ -f "$patch" ] || continue
    
    patch_name="$(basename "$patch")"
    
    # Extract the target file path from the patch header
    # Unified diff format: --- path/to/file.orig or --- a/path/to/file
    target_file=$(grep -m1 '^--- ' "$patch" | sed -E 's/^--- (a\/)?//; s/\.orig.*//; s/[[:space:]].*//')
    
    if [ -z "$target_file" ]; then
        echo "⚠️  $patch_name: Cannot determine target file"
        FAILED=$((FAILED + 1))
        continue
    fi
    
    full_path="$WORK_DIR/$target_file"
    
    if [ ! -f "$full_path" ]; then
        echo "❓ $patch_name: Target file not found: $target_file"
        FAILED=$((FAILED + 1))
        continue
    fi
    
    # Check if .orig file exists (indicates patch was applied by FreeBSD ports)
    if [ -f "${full_path}.orig" ]; then
        echo "✅ $patch_name: APPLIED (${target_file}.orig exists)"
        APPLIED=$((APPLIED + 1))
        continue
    fi
    
    # Try to apply the patch in dry-run mode
    # If it applies cleanly, the patch hasn't been applied yet
    # If it fails or reverses, the patch is already applied
    result=$(patch -d "$WORK_DIR" -p0 --dry-run < "$patch" 2>&1)
    exit_code=$?
    
    if echo "$result" | grep -q "Reversed (or previously applied)"; then
        echo "✅ $patch_name: APPLIED (patch reversed/already applied)"
        APPLIED=$((APPLIED + 1))
    elif echo "$result" | grep -q "FAILED\|malformed\|can't find file"; then
        echo "⚠️  $patch_name: FAILED to check - $target_file"
        echo "   Reason: $(echo "$result" | grep -E 'FAILED|malformed|can.t find' | head -1)"
        FAILED=$((FAILED + 1))
    elif [ $exit_code -eq 0 ]; then
        echo "❌ $patch_name: NOT APPLIED - $target_file"
        NOT_APPLIED=$((NOT_APPLIED + 1))
    else
        echo "⚠️  $patch_name: UNKNOWN status - $target_file"
        FAILED=$((FAILED + 1))
    fi
done

echo ""
echo "=== Summary ==="
echo "Applied:     $APPLIED"
echo "Not Applied: $NOT_APPLIED"
echo "Failed/Unknown: $FAILED"
echo ""

if [ $APPLIED -gt 0 ] && [ $NOT_APPLIED -eq 0 ]; then
    echo "Status: All patches are already applied."
    exit 1
elif [ $NOT_APPLIED -gt 0 ] && [ $APPLIED -eq 0 ]; then
    echo "Status: No patches applied yet. Ready to patch."
    exit 0
elif [ $APPLIED -gt 0 ] && [ $NOT_APPLIED -gt 0 ]; then
    echo "Status: MIXED - Some patches applied, some not. Consider 'make clean' first."
    exit 1
else
    echo "Status: Unable to determine patch status."
    exit 2
fi
