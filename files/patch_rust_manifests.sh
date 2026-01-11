#!/bin/sh
# Patch Cargo.toml files in-tree to replace edition.workspace with an explicit edition
# Usage: patch_rust_manifests.sh <repo-root>
set -eu
ROOT=${1:-.}
CHANGED=0
find "$ROOT" -type f -name Cargo.toml | while read -r f; do
    if grep -q "edition.workspace" "$f"; then
        if grep -q "^edition\s*=\s*\"" "$f"; then
            # edition already present: remove the workspace marker
            sed -n '1,200p' "$f" >/dev/null 2>&1 || true
            awk '!/edition\.workspace\s*=/ {print}' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
            echo "Patched (removed workspace edition): $f"
            CHANGED=1
        else
            # replace workspace marker with explicit edition
            sed 's/edition\.workspace\s*=\s*true/edition = "2021"/' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
            echo "Patched (inserted edition): $f"
            CHANGED=1
        fi
    fi
done
if [ "$CHANGED" = 0 ]; then
    echo "No edition.workspace occurrences found"
fi
exit 0
