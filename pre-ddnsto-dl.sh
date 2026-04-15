#!/bin/sh

set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
version_file=${VERSION_FILE:-$script_dir/version}

default_version() {
    [ -f "$version_file" ] || {
        echo "missing version file: $version_file" >&2
        exit 2
    }
    sed -n '1p' "$version_file" | tr -d '[:space:]'
}

DDNSTO_VERSION=${DDNSTO_VERSION:-$(default_version)}
DDNSTO_PACKAGE="ddnsto-binary-${DDNSTO_VERSION}.tar.gz"
DDNSTO_PACKAGE_DIR="ddnsto-binary-${DDNSTO_VERSION}"
DOWNLOAD_URL="https://fw0.koolcenter.com/binary/ddnsto/${DDNSTO_PACKAGE}"
DIST_DIR=${DIST_DIR:-$script_dir/dist}
TMP_DIR=$(mktemp -d)

cleanup() {
    rm -rf "$TMP_DIR"
}

trap cleanup EXIT INT TERM

mkdir -p "$DIST_DIR"
ARCHIVE_PATH="$TMP_DIR/$DDNSTO_PACKAGE"

echo "Downloading release package from: ${DOWNLOAD_URL}"
wget --no-check-certificate -O "$ARCHIVE_PATH" "$DOWNLOAD_URL"

for arch in x86_64 aarch64 arm mipsel; do
    entry="$DDNSTO_PACKAGE_DIR/ddnsto.$arch"
    echo "Extracting $entry"
    tar -xzf "$ARCHIVE_PATH" -C "$TMP_DIR" "$entry"
    install -m 0755 "$TMP_DIR/$entry" "$DIST_DIR/ddnsto.$arch"
done

printf '%s\n' "$DDNSTO_VERSION" > "$DIST_DIR/VERSION"
echo "Prepared dist directory: $DIST_DIR"
