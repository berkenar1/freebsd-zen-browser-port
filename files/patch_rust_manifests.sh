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
            sed 's/edition\.workspace[[:space:]]*=[[:space:]]*true/edition = "2021"/' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
            echo "Patched (inserted edition): $f"
            CHANGED=1
        fi
    fi
done

# Now also ensure version.workspace and other workspace markers are handled
find "$ROOT" -type f -name Cargo.toml | while read -r f; do
    if grep -q "version.workspace" "$f"; then
        sed 's/version\.workspace[[:space:]]*=[[:space:]]*true/version = "0.1.0"/' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
        echo "Patched (inserted version): $f"
        CHANGED=1
    fi
    if grep -q "\.workspace[[:space:]]*=[[:space:]]*true" "$f"; then
        awk '!/\.workspace[[:space:]]*=[[:space:]]*true/ {print}' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
        echo "Patched (removed other workspace markers): $f"
        CHANGED=1
    fi
done

# Replace dependency entries that inherit from workspace (e.g., `xyz = { workspace = true, features = [...] }`).
# Change `workspace = true` to an explicit minimal `version = "0.1.0"` to avoid cargo workspace inheritance errors.
find "$ROOT" -type f -name Cargo.toml | while read -r f; do
    if grep -q "workspace\s*=\s*true" "$f"; then
        sed 's/workspace[[:space:]]*=[[:space:]]*true/version = "0.1.0"/g' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
        echo "Patched (replaced dependency workspace markers): $f"
        CHANGED=1
    fi
done

if [ "$CHANGED" = 0 ]; then
    echo "No workspace-derived occurrences found"
fi
exit 0
