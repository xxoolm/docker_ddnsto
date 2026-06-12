#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
TMP_DIR=$(mktemp -d)

cleanup() {
    rm -rf "$TMP_DIR"
}

trap cleanup EXIT INT TERM

mkdir -p "$TMP_DIR/bin" "$TMP_DIR/output" "$TMP_DIR/logs"

cat >"$TMP_DIR/bin/ddnsto" <<'EOF'
#!/bin/sh
set -eu

if [ "${1:-}" = "diagnostics" ] && [ "${2:-}" = "bundle" ] && [ "${3:-}" = "--output" ]; then
    printf 'diagnostics bundle\n' >"$4"
    exit 0
fi

if [ "${1:-}" = "offline-diagnosis" ] && [ "${2:-}" = "--json" ]; then
    printf '{"summary":"offline"}\n'
    exit 0
fi

if [ "${1:-}" = "diagnostics" ] && [ "${2:-}" = "status" ]; then
    printf '{"status":"ok"}\n'
    exit 0
fi

if [ "${1:-}" = "diagnostics" ] && [ "${2:-}" = "logs" ]; then
    printf 'diagnostics logs\n'
    exit 0
fi

echo "unexpected args: $*" >&2
exit 1
EOF

chmod +x "$TMP_DIR/bin/ddnsto"

printf 'log line\n' >"$TMP_DIR/logs/ddnstoshell.log"

PATH="$TMP_DIR/bin:$PATH" \
TOKEN="secret-token-value" \
DEVICE_NAME="device-a" \
DDNSTO_LOG_PATH="$TMP_DIR/logs/ddnstoshell.log" \
DDNSTO_SUPPORT_DIR="$TMP_DIR/output" \
"$REPO_DIR/ddnsto-support.sh" bundle

LATEST_ZIP="$TMP_DIR/output/latest/ddnsto-support.zip"
[ -f "$LATEST_ZIP" ]

EXTRACT_DIR="$TMP_DIR/extracted"
mkdir -p "$EXTRACT_DIR"
unzip -q "$LATEST_ZIP" -d "$EXTRACT_DIR"

grep -q "secret-token-value" "$EXTRACT_DIR"/bundle/env.txt && {
    echo "token should be redacted" >&2
    exit 1
}

grep -q "TOKEN=\*\*\*REDACTED\*\*\*" "$EXTRACT_DIR"/bundle/env.txt
grep -q '"summary":"offline"' "$EXTRACT_DIR"/bundle/offline-diagnosis.json
grep -q 'diagnostics bundle' "$EXTRACT_DIR"/bundle/diagnostics-bundle.zip
