set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
VERSION_FILE=${VERSION_FILE:-$SCRIPT_DIR/version}

read_version() {
    [ -f "$VERSION_FILE" ] || {
        echo "missing version file: $VERSION_FILE" >&2
        exit 2
    }
    sed -n '1p' "$VERSION_FILE" | tr -d '[:space:]'
}

IMAGE_TAG=${IMAGE_TAG:-$(read_version)}

"$SCRIPT_DIR/pre-ddnsto-dl.sh"

docker buildx build --platform linux/amd64,linux/arm/v6,linux/arm/v7,linux/arm64 \
        -t "linkease/ddnsto:${IMAGE_TAG}" \
        -f "$SCRIPT_DIR/Dockerfile.architecture" --push "$SCRIPT_DIR"
