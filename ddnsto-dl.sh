#!/bin/sh

set -eu

PLATFORM=${1:-}
DDNSTO_VERSION=${DDNSTO_VERSION:-4.0.5}
DDNSTO_PACKAGE="ddnsto-binary-${DDNSTO_VERSION}.tar.gz"
DDNSTO_PACKAGE_DIR="ddnsto-binary-${DDNSTO_VERSION}"

if [ -z "${PLATFORM:-}" ]; then
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64|amd64)
            DDNSTO_FILE="x86_64"
            ;;
        aarch64|arm64)
            DDNSTO_FILE="aarch64"
            ;;
        armv6l|armv7l|arm)
            DDNSTO_FILE="arm"
            ;;
        mipsel|mipsle)
            DDNSTO_FILE="mipsel"
            ;;
        *)
            DDNSTO_FILE=""
            ;;
    esac
else
    case "$PLATFORM" in
        linux/386)
            DDNSTO_FILE=""
            ;;
        linux/amd64)
            DDNSTO_FILE="x86_64"
            ;;
        linux/arm/v6)
            DDNSTO_FILE="arm"
            ;;
        linux/arm/v7)
            DDNSTO_FILE="arm"
            ;;
        linux/arm64|linux/arm64/v8)
            DDNSTO_FILE="aarch64"
            ;;
        linux/mipsle|linux/mipsel)
            DDNSTO_FILE="mipsel"
            ;;
        linux/ppc64le)
            DDNSTO_FILE=""
            ;;
        linux/s390x)
            DDNSTO_FILE=""
            ;;
        *)
            DDNSTO_FILE=""
            ;;
    esac
fi
[ -z "${DDNSTO_FILE}" ] && echo "Error: Not supported OS Architecture" && exit 1

DOWNLOAD_URL="https://fw0.koolcenter.com/binary/ddnsto/${DDNSTO_PACKAGE}"
TMP_DIR=$(mktemp -d)
ARCHIVE_PATH="${TMP_DIR}/${DDNSTO_PACKAGE}"
ARCHIVE_ENTRY="${DDNSTO_PACKAGE_DIR}/ddnsto.${DDNSTO_FILE}"

cleanup() {
    rm -rf "${TMP_DIR}"
}

trap cleanup EXIT INT TERM

echo "Downloading release package from: ${DOWNLOAD_URL}"
wget --no-check-certificate -O "${ARCHIVE_PATH}" "${DOWNLOAD_URL}" >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Error: Failed to download release package from: ${DOWNLOAD_URL}" && exit 1
fi

tar -xzf "${ARCHIVE_PATH}" -C "${TMP_DIR}" "${ARCHIVE_ENTRY}"
if [ ! -f "${TMP_DIR}/${ARCHIVE_ENTRY}" ]; then
    echo "Error: Missing binary in release package: ${ARCHIVE_ENTRY}" && exit 1
fi

install -m 0755 "${TMP_DIR}/${ARCHIVE_ENTRY}" /usr/bin/ddnsto

echo "Installed binary file: ${DDNSTO_FILE} (${DDNSTO_VERSION}) completed"

chmod +x /usr/bin/ddnsto
