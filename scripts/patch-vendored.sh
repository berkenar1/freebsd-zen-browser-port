et -e

echo "Patching vendored Cargo.toml files..."

find work -name "Cargo.toml" -type f -exec sed -i \
	    -e 's/edition\.workspace = true/edition = "2021"/g' \
	    -e 's/edition = { workspace = true }/edition = "2021"/g' \
	    -e 's/authors\.workspace = true/authors = ["Upstream Developer"]/g' \
	    -e 's/license\.workspace = true/license = "MPL-2.0"/g' \
	    -e 's/rust-version\.workspace = true/rust-version = "1.70"/g' \
        {} \;

echo "✓ Patched all vendored Cargo.toml files"

