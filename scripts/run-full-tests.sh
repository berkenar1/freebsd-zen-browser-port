#!/usr/bin/env bash
set -euo pipefail

# Simple end-to-end test runner for local dev and CI.
# It performs: build, format check, clippy (optional strict), and cargo test.

echo "==> Running full test suite"

# Ensure we operate from the repository root and build there
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "==> Building (make build) at $REPO_ROOT"
if ! (cd "$REPO_ROOT" && sudo -E make build); then
  echo "make build failed"
  exit 1
fi

# Move into vendored workspace
cd "$REPO_ROOT/work"

# Format check
echo "==> cargo fmt --all -- --check"
if ! cargo fmt --all -- --check; then
  echo "cargo fmt check failed. Run 'cargo fmt --all' to fix formatting."
  exit 1
fi

# Clippy (skip if CLIPPY_STRICT=0)
CLIPPY_STRICT=${CLIPPY_STRICT:-1}
if [ "$CLIPPY_STRICT" -ne 0 ]; then
  echo "==> cargo clippy --workspace --all-features -- -D warnings"
  if ! cargo clippy --workspace --all-features -- -D warnings; then
    echo "clippy failed (treating warnings as errors). Set CLIPPY_STRICT=0 to skip or allow warnings."
    exit 1
  fi
else
  echo "==> Skipping strict clippy (CLIPPY_STRICT=0)"
fi

# Run tests
echo "==> cargo test --workspace --all-features --verbose"
cargo test --workspace --all-features --verbose

echo "==> Test run complete"
