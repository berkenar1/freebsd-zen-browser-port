#!/bin/sh
# Orchestrator: run manifest patchers and optionally verify with cargo metadata
# Usage:
#   fix_manifests_and_verify.sh <repo-root> [--apply] [--verify]
# - Default: dry-run previews only
# - --apply: apply edits (writes patch files under files/patch-rust-manifests/ and applies edits in-place)
# - --verify: if a Cargo.toml exists at <repo-root>/Cargo.toml and cargo is available, run cargo metadata
set -eu
set -o pipefail
ROOT=${1:-.}
shift || true
APPLY=false
VERIFY=false
for arg in "$@"; do
    case "$arg" in
        --apply) APPLY=true ;;
        --verify) VERIFY=true ;;
        *) echo "Unknown arg: $arg" ; exit 1 ;;
    esac
done

echo "Running patch_rust_manifests.sh (dry-run unless --apply) on: $ROOT"
sh files/patch_rust_manifests.sh "$ROOT" $( [ "$APPLY" = true ] && echo --apply || echo )

echo "Running patch_ohttp_bhttp.sh (dry-run unless --apply) on: $ROOT"
sh files/patch-rust-manifests/patch_ohttp_bhttp.sh "$ROOT" $( [ "$APPLY" = true ] && echo --apply || echo )

if [ "$VERIFY" = true ]; then
    if [ -x "$(command -v cargo 2>/dev/null || true)" ] && [ -f "$ROOT/Cargo.toml" ]; then
        echo "Running cargo metadata to verify workspace (may be slow)"
        # Run metadata with timeout using setsid; if it fails, capture output
        if cargo metadata --manifest-path "$ROOT/Cargo.toml" --format-version 1 > /tmp/cargo-metadata.out 2>&1; then
            echo "cargo metadata succeeded"
            rm -f /tmp/cargo-metadata.out
            exit 0
        else
            echo "cargo metadata failed; saving output to /tmp/cargo-metadata.out"
            sed -n '1,240p' /tmp/cargo-metadata.out || true
            echo "Inspect the error. If it references 'edition.workspace', re-run this script with --apply to ensure edits were applied."
            exit 1
        fi
    else
        echo "Skipping verification: cargo not found or $ROOT/Cargo.toml missing"
    fi
fi

echo "Done (dry-run). Use --apply to make changes persistent and to write patch files under files/patch-rust-manifests/." 
exit 0
