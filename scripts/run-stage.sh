#!/usr/bin/env bash
set -euo pipefail

# Helper to run the 'stage' Makefile target using fakeroot if available,
# otherwise falling back to sudo so that file ownership/modes are preserved
# in the staging area without affecting the live system.

FAKEROOT=fakeroot
if ! command -v "$FAKEROOT" >/dev/null 2>&1; then
  echo "fakeroot not found; falling back to sudo"
  FAKEROOT=sudo
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"
cd "$REPO_ROOT"

# Ensure build artifacts
echo "==> Building (make build)"
if ! make build; then
  echo "make build failed; trying 'sudo -E make build'"
  if ! sudo -E make build; then
    echo "sudo build also failed; aborting."
    exit 1
  fi
fi

echo "==> Running: FAKEROOT=$FAKEROOT make stage"
FAKEROOT="$FAKEROOT" make stage

echo "==> Stage completed. Inspect ./stage directory."
