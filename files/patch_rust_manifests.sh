#!/bin/sh
# Safer, idempotent patch script for Cargo.toml metadata fixes
# Usage: patch_rust_manifests.sh <repo-root> [--apply]
# By default this runs in dry-run mode and prints proposed edits. Use --apply to make changes.
set -eu
set -o pipefail
ROOT=${1:-.}
APPLY=false
if [ "${2:-}" = "--apply" ] || [ "${1:-}" = "--apply" ]; then
    APPLY=true
fi

echo "Scanning Cargo.toml files under: $ROOT"

# Helper: show a diff (dry-run) or write backup and apply changes (apply mode)
apply_edit() {
    local file="$1"
    local tmp="${file}.tmp"

    if [ "$APPLY" = true ]; then
        mv "$tmp" "$file"
        echo "Applied: $file"
    else
        echo "DRY-RUN: would modify $file"
        echo "--- $file ---"
        sed -n '1,200p' "$file" | sed -n '1,200p'
        echo "(end preview)"
    fi
}

# 1) Convert dependency entries that were rewritten to `version = "0.1.0"` back into workspace = true
# but only when the `version = "0.1.0"` appears inside a `{ ... }` (i.e. dependency spec), not a package's own version.
find "$ROOT" -type f -name Cargo.toml | while read -r f; do
    # check for a version attr inside a brace (likely an accidental rewrite)
    if grep -q "{[^}]*version\s*=\s*\"0\.1\.0\"[^}]*}" "$f"; then
        echo "Found dependency-version=0.1.0 (candidate) in: $f"
        # Create a candidate transformation into workspace=true within the braces
        if [ "$APPLY" = true ]; then
            if perl -0777 -pe '\
                s/\{([^}]*)\bversion\s*=\s*\"0\.1\.0\"([^}]*)\}/\{\1workspace = true\2\}/msg;\
            ' "$f" > "$f.tmp"; then
                apply_edit "$f"
            else
                echo "perl substitution failed for $f; skipping"
                rm -f "$f.tmp" || true
            fi
        else
            echo "--- preview (first 120 lines of transformed output) ---"
            if ! perl -0777 -pe '\
                s/\{([^}]*)\bversion\s*=\s*\"0\.1\.0\"([^}]*)\}/\{\1workspace = true\2\}/msg;\
            ' "$f" | sed -n '1,120p'; then
                echo "perl preview failed for $f"
            fi
            echo "--- end preview ---"
        fi
    fi
done

# 2) Fix spurious rust-version = "0.1.0" -> set to a conservative MSRV (1.81.0)
find "$ROOT" -type f -name Cargo.toml | while read -r f; do
    if grep -q '^[[:space:]]*rust-version[[:space:]]*=[[:space:]]*"0\.1\.0"' "$f"; then
        echo "Found rust-version = \"0.1.0\" in: $f"
        if [ "$APPLY" = true ]; then
            if sed 's/^[[:space:]]*rust-version[[:space:]]*=[[:space:]]*"0\.1\.0"/rust-version = "1.81.0"/' "$f" > "$f.tmp"; then
                apply_edit "$f"
            else
                echo "sed failed for rust-version replacement in $f; skipping"
                rm -f "$f.tmp" || true
            fi
        else
            echo "--- preview (rust-version change) ---"
            sed 's/^[[:space:]]*rust-version[[:space:]]*=[[:space:]]*"0\.1\.0"/rust-version = "1.81.0"/' "$f" | sed -n '1,120p'
            echo "--- end preview ---"
        fi
    fi
done

# 3) Remove spurious lints.version entries introduced as 'lints.version = "0.1.0"' or [lints]\nversion = "0.1.0"
find "$ROOT" -type f -name Cargo.toml | while read -r f; do
    if grep -q '^[[:space:]]*\[lints' "$f" && grep -q '^[[:space:]]*version[[:space:]]*=[[:space:]]*"0\.1\.0"' "$f"; then
        echo "Removing lints.version = \"0.1.0\" in: $f"
        if [ "$APPLY" = true ]; then
            perl -0777 -pe 's/\[lints\][^\[]*?^\s*version\s*=\s*"0\.1\.0"\s*\n//gms' "$f" > "$f.tmp"
            apply_edit "$f"
        else
            echo "--- preview (remove lints.version) ---"
            perl -0777 -pe 's/\[lints\][^\[]*?^\s*version\s*=\s*"0\.1\.0"\s*\n//gms' "$f" | sed -n '1,120p'
            echo "--- end preview ---"
        fi
    fi
done

# 4) Ensure wgpu platform-dep Cargo.tomls declare wgpu-hal as an optional workspace dependency inside the target-specific dependencies
WGPU_PD="wgpu-*/wgpu-core/platform-deps/*/Cargo.toml"
find "$ROOT" -path "*/wgpu-*/wgpu-core/platform-deps/*/Cargo.toml" -print | while read -r f; do
    echo "Checking wgpu platform-deps: $f"
    if grep -q "wgpu-hal" "$f"; then
        echo "  wgpu-hal already present in $f"
    else
        echo "  Adding wgpu-hal = { workspace = true, optional = true } to target dependencies in $f"
        # Add the line after the target.'...'.dependencies header
        if [ "$APPLY" = true ]; then
            awk '1{print; if($0 ~ /\[target.*dependencies\]/ && !x){print "wgpu-hal = { workspace = true, optional = true }"; x=1}}' "$f" > "$f.tmp"
            apply_edit "$f"
        else
            echo "--- preview (insert wgpu-hal into $f) ---"
            awk '1{print; if($0 ~ /\[target.*dependencies\]/ && !x){print "wgpu-hal = { workspace = true, optional = true }"; x=1}}' "$f" | sed -n '1,120p'
            echo "--- end preview ---"
        fi
    fi
done

# 5) Ensure top-level workspace has an explicit edition and annotate-snippets in [workspace.dependencies]
TOP="$ROOT/Cargo.toml"
if [ -f "$TOP" ]; then
    # Ensure [workspace.package] has an edition defined so crates that inherit edition.workspace succeed
    if grep -q "\[workspace.package\]" "$TOP"; then
        if ! grep -q "^[[:space:]]*edition[[:space:]]*=" "$TOP"; then
            echo "Adding edition = \"2021\" to $TOP (under [workspace.package])"
            if [ "$APPLY" = true ]; then
                awk '1{print; if($0 ~ /\[workspace.package\]/ && !x){print "edition = \"2021\""; x=1}}' "$TOP" > "$TOP.tmp"
                apply_edit "$TOP"
            else
                echo "--- preview (insert edition in $TOP) ---"
                awk '1{print; if($0 ~ /\[workspace.package\]/ && !x){print "edition = \"2021\""; x=1}}' "$TOP" | sed -n '1,120p'
                echo "--- end preview ---"
            fi
        else
            echo "edition already present in $TOP"
        fi

        if ! grep -q "^[[:space:]]*version[[:space:]]*=" "$TOP"; then
            echo "Adding version = \"0.0.0\" to $TOP (under [workspace.package])"
            if [ "$APPLY" = true ]; then
                awk '1{print; if($0 ~ /\[workspace.package\]/ && !x){print "version = \"0.0.0\""; x=1}}' "$TOP" > "$TOP.tmp"
                apply_edit "$TOP"
            else
                echo "--- preview (insert version = \"0.0.0\" in $TOP) ---"
                awk '1{print; if($0 ~ /\[workspace.package\]/ && !x){print "version = \"0.0.0\""; x=1}}' "$TOP" | sed -n '1,120p'
                echo "--- end preview ---"
            fi
        else
            echo "version already present in $TOP"
        fi

        if ! grep -q "^[[:space:]]*authors[[:space:]]*=" "$TOP"; then
            echo "Adding authors = [] to $TOP (under [workspace.package])"
            if [ "$APPLY" = true ]; then
                awk '1{print; if($0 ~ /\[workspace.package\]/ && !x){print "authors = []"; x=1}}' "$TOP" > "$TOP.tmp"
                apply_edit "$TOP"
            else
                echo "--- preview (insert authors = [] in $TOP) ---"
                awk '1{print; if($0 ~ /\[workspace.package\]/ && !x){print "authors = []"; x=1}}' "$TOP" | sed -n '1,120p'
                echo "--- end preview ---"
            fi
        else
            echo "authors already present in $TOP"
        fi
    else
        echo "No [workspace.package] in $TOP, skipping edition/authors insertion"
    fi

    if grep -q "\[workspace.dependencies\]" "$TOP"; then
        if ! grep -q "^[[:space:]]*annotate-snippets[[:space:]]*=" "$TOP"; then
            echo "Adding annotate-snippets = \"0.11.4\" to $TOP"
            # Insert it right after the workspace.dependencies header
            if [ "$APPLY" = true ]; then
                awk '1{print; if($0 ~ /\[workspace.dependencies\]/ && !x){print "annotate-snippets = \"0.11.4\""; x=1}}' "$TOP" > "$TOP.tmp"
                apply_edit "$TOP"
            else
                echo "--- preview (insert annotate-snippets in $TOP) ---"
                awk '1{print; if($0 ~ /\[workspace.dependencies\]/ && !x){print "annotate-snippets = \"0.11.4\""; x=1}}' "$TOP" | sed -n '1,120p'
                echo "--- end preview ---"
            fi
        else
            echo "annotate-snippets already present in $TOP"
        fi
    else
        echo "No [workspace.dependencies] in $TOP, skipping annotate-snippets insertion"
    fi
fi

# 6) Fix ohttp bhttp crates which use "edition.workspace = true" -> make explicit edition
# This targets ohttp's bhttp crates which previously failed cargo metadata due to missing
# [workspace.package].edition in the workspace root.
find "$ROOT" -type f -path "*/ohttp-*/bhttp/Cargo.toml" -print | while read -r F; do
    if grep -q "edition.workspace" "$F" 2>/dev/null; then
        echo "Will replace edition.workspace in $F"
        if [ "$APPLY" = true ]; then
            awk '{ if($0 ~ /^[[:space:]]*edition[[:space:]]*\.workspace[[:space:]]*=.*/){ sub(/edition[[:space:]]*\.workspace[[:space:]]*=.*/, "edition = \"2021\""); print; } else { print } }' "$F" > "$F.tmp" && apply_edit "$F"
        else
            echo "--- preview (replace edition.workspace in $F) ---"
            awk '{ if($0 ~ /^[[:space:]]*edition[[:space:]]*\.workspace[[:space:]]*=.*/){ sub(/edition[[:space:]]*\.workspace[[:space:]]*=.*/, "edition = \"2021\""); print; } else { print } }' "$F" | sed -n '1,120p'
            echo "--- end preview ---"
        fi
    fi
done

# 7) Replace any remaining edition.workspace usages across all Cargo.toml files (global sweep)
find "$ROOT" -type f -name Cargo.toml -print | while read -r F; do
    if grep -q "edition[[:space:]]*\.workspace" "$F" 2>/dev/null; then
        echo "Replacing edition.workspace in: $F"
        if [ "$APPLY" = true ]; then
            awk '{ if($0 ~ /^[[:space:]]*edition[[:space:]]*\.workspace[[:space:]]*=.*/){ sub(/edition[[:space:]]*\.workspace[[:space:]]*=.*/, "edition = \"2021\""); print; } else { print } }' "$F" > "$F.tmp" && apply_edit "$F"
        else
            echo "--- preview (global edition.workspace replacement for $F) ---"
            awk '{ if($0 ~ /^[[:space:]]*edition[[:space:]]*\.workspace[[:space:]]*=.*/){ sub(/edition[[:space:]]*\.workspace[[:space:]]*=.*/, "edition = \"2021\""); print; } else { print } }' "$F" | sed -n '1,120p'
            echo "--- end preview ---"
        fi
    fi
done

# 8) Tidy: where a dependency line includes trailing commas left by replacements, remove duplicate commas
find "$ROOT" -type f -name Cargo.toml | while read -r f; do
    if grep -q ",," "$f"; then
        echo "Tidying double-commas in: $f"
        if [ "$APPLY" = true ]; then
            sed 's/,[[:space:]]*,/,/g' "$f" > "$f.tmp"
            apply_edit "$f"
        else
            echo "--- preview (tidy double-commas) ---"
            sed 's/,\s*,/,/g' "$f" | sed -n '1,120p'
            echo "--- end preview ---"
        fi
    fi
done

# Summary
if [ "$APPLY" = true ]; then
    echo "Done (applied changes). Please review and commit the resulting patches under files/ if desired."
else
    echo "Dry-run complete. Rerun with --apply to perform the changes." 
fi
exit 0
