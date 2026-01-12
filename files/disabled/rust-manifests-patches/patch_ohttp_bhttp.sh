#!/bin/sh
# Create a reproducible patch for ohttp/bhttp crates that use edition.workspace
# Usage:
#   patch_ohttp_bhttp.sh <repo-root> [--apply]
# Default: dry-run (shows previews and writes patch to stdout). Use --apply to create/append
# files/patch-rust-manifests/patch-ohttp-bhttp.patch and (optionally) apply edits in-place.
set -eu
set -o pipefail
ROOT=${1:-.}
APPLY=false
if [ "${2:-}" = "--apply" ] || [ "${1:-}" = "--apply" ]; then
    APPLY=true
fi
PATCH_DIR="files/patch-rust-manifests"
PATCH_FILE="$PATCH_DIR/patch-ohttp-bhttp.patch"
TMP_PATCH="$(mktemp)"
found=0

echo "Scanning for */ohttp-*/bhttp/Cargo.toml under: $ROOT"
for f in $(find "$ROOT" -type f -path "*/ohttp-*/bhttp/Cargo.toml" -print); do
    if grep -q 'edition[[:space:]]*\.workspace' "$f" 2>/dev/null; then
        found=1
        echo ""
        echo "Found candidate: $f"

        # preview replacement
        awk '{ if($0 ~ /^[[:space:]]*edition[[:space:]]*\.workspace[[:space:]]*=.*/){ sub(/edition[[:space:]]*\.workspace[[:space:]]*=.*/, "edition = \"2021\""); print; } else { print } }' "$f" > "$f.tmp.preview"
        echo "--- preview (first 200 lines) ---"
        sed -n '1,200p' "$f.tmp.preview"
        echo "--- end preview ---"

        # prepare small context-aware patch fragment
        lineno=$(grep -n 'edition[[:space:]]*\.workspace' "$f" | cut -d: -f1 | head -n1)
        start=$((lineno>3 ? lineno-3 : 1))
        end=$((lineno+3))
        old_snippet=$(sed -n "${start},${end}p" "$f")
        new_snippet=$(sed -n "${start},${end}p" "$f.tmp.preview")

        cat >> "$TMP_PATCH" <<EOF
*** Begin Patch
*** Update File: ohttp-*/bhttp/Cargo.toml
@@
EOF
        echo "$old_snippet" | sed 's/^/-/g' >> "$TMP_PATCH"
        echo "$new_snippet" | sed 's/^/+/g' >> "$TMP_PATCH"
        echo "*** End Patch" >> "$TMP_PATCH"

        if [ "$APPLY" = true ]; then
            mkdir -p "$PATCH_DIR"
            # Append the patch fragment to the canonical patch file if not already present
            if ! grep -qF "*** Update File: ohttp-*/bhttp/Cargo.toml" "$PATCH_FILE" 2>/dev/null || ! grep -qF "edition = \"2021\"" "$PATCH_FILE" 2>/dev/null; then
                cat "$TMP_PATCH" >> "$PATCH_FILE"
                echo "Appended patch fragment to: $PATCH_FILE"
            else
                echo "Patch file $PATCH_FILE already contains the ohttp/bhttp edit; skipping append."
            fi

            # Apply the edit in-place
            mv "$f.tmp.preview" "$f"
            echo "Applied change in-place to: $f"
            # cleanup tmp patch content for next file
            : > "$TMP_PATCH"
        else
            echo "(dry-run) patch fragment for $f:"
            sed -n '1,240p' "$TMP_PATCH"
            : > "$TMP_PATCH"
        fi

        rm -f "$f.tmp.preview"
    fi
done

if [ "$found" -eq 0 ]; then
    echo "No ohttp bhttp crates with edition.workspace found under: $ROOT"
fi

if [ "$APPLY" = false ] && [ -s "$TMP_PATCH" ]; then
    printf "\nCombined patch (would write to %s if --apply was given):\n" "$PATCH_FILE"
    sed -n '1,240p' "$TMP_PATCH"
fi

rm -f "$TMP_PATCH"
exit 0
