This directory documents the automated manifest fixes for Rust Cargo manifests.

The port's `Makefile` runs `files/patch_rust_manifests.sh ${WRKSRC}` during the patch phase to
apply idempotent transformations that make Cargo workspaces and crate manifests consistent
for the ports build (e.g., inserting `annotate-snippets` into `[workspace.dependencies]`,
removing spurious `lints.version = "0.1.0"`, converting `rust-version = "0.1.0"` to
`rust-version = "1.81.0"`, and converting accidental dependency `version = "0.1.0"` to
`workspace = true` where appropriate).

This script is intentionally idempotent and safe to run multiple times.

If you need per-file unified diffs instead of a script, I can generate them and commit them
under this directory as individual `patch-*` files — tell me if you'd prefer that.