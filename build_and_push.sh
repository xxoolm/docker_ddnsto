set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

"$SCRIPT_DIR/pre-ddnsto-dl.sh"

docker buildx build --platform linux/amd64,linux/arm/v6,linux/arm/v7,linux/arm64 \
        -t linkease/ddnsto:3.1.0 \
        -f "$SCRIPT_DIR/Dockerfile.architecture" --push "$SCRIPT_DIR"
