Purpose
-------
This small helper script produces a reproducible patch to fix crates in the `ohttp/.../bhttp` tree that were written with `edition.workspace = true` while the workspace root did not define `workspace.package.edition`.

Usage
-----
- Dry-run (preview only):
    sh files/patch-rust-manifests/patch_ohttp_bhttp.sh <repo-root>

- Apply (append patch to `files/patch-rust-manifests/patch-ohttp-bhttp.patch` and apply changes in-place):
    sh files/patch-rust-manifests/patch_ohttp_bhttp.sh <repo-root> --apply

Notes
-----
- The script is idempotent and safe to re-run.
- The patch format matches the project's existing `*** Begin Patch` / `*** End Patch` style for ports patch files.
- Running with `--apply` will also modify the referenced `Cargo.toml` in-place. If you prefer only to add the patch file and not modify the vendor tree, run without `--apply` and inspect the generated patch fragments first.
