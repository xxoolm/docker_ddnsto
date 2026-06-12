#!/bin/sh

set -eu

SUPPORT_DIR=${DDNSTO_SUPPORT_DIR:-/ddnsto-support}
LATEST_DIR="$SUPPORT_DIR/latest"
HISTORY_DIR="$SUPPORT_DIR/history"
LOG_PATH=${DDNSTO_LOG_PATH:-/tmp/logs/ddnstoshell.log}
TAIL_LINES=${DDNSTO_SUPPORT_TAIL_LINES:-500}
KEEP_COUNT=${DDNSTO_SUPPORT_KEEP:-5}

timestamp() {
    date -u +"%Y%m%dT%H%M%SZ"
}

ensure_dirs() {
    mkdir -p "$LATEST_DIR" "$HISTORY_DIR"
}

capture_to_file() {
    output_file=$1
    shift
    if "$@" >"$output_file" 2>&1; then
        return 0
    fi
    printf 'command failed: %s\n' "$*" >>"$output_file"
    return 1
}

write_env_summary() {
    output_file=$1
    env | sort | awk '
        BEGIN {
            IGNORECASE = 0
        }
        {
            split($0, parts, "=")
            key = parts[1]
            value = substr($0, length(key) + 2)
            if (key ~ /(TOKEN|SECRET|PASSWORD|KEY)$/) {
                value = "***REDACTED***"
            }
            printf "%s=%s\n", key, value
        }
    ' >"$output_file"
}

write_runtime_summary() {
    output_file=$1
    reason_value=$2
    {
        printf 'timestamp=%s\n' "$(timestamp)"
        printf 'reason=%s\n' "$reason_value"
        printf 'support_dir=%s\n' "$SUPPORT_DIR"
        printf 'log_path=%s\n' "$LOG_PATH"
        uname -a
        printf 'date=%s\n' "$(date -u)"
    } >"$output_file"
}

copy_log_tail() {
    output_file=$1
    if [ -f "$LOG_PATH" ]; then
        tail -n "$TAIL_LINES" "$LOG_PATH" >"$output_file"
    else
        printf 'missing log file: %s\n' "$LOG_PATH" >"$output_file"
    fi
}

collect_ddnsto_outputs() {
    bundle_dir=$1

    if command -v ddnsto >/dev/null 2>&1; then
        capture_to_file "$bundle_dir/diagnostics-status.json" ddnsto diagnostics status || true
        capture_to_file "$bundle_dir/offline-diagnosis.json" ddnsto offline-diagnosis --json || true
        capture_to_file "$bundle_dir/diagnostics-logs.txt" ddnsto diagnostics logs --tail "$TAIL_LINES" || true
        if ddnsto diagnostics bundle --output "$bundle_dir/diagnostics-bundle.zip" >/dev/null 2>&1; then
            :
        else
            printf 'ddnsto diagnostics bundle unavailable\n' >"$bundle_dir/diagnostics-bundle-error.txt"
        fi
    else
        printf 'ddnsto binary not found in PATH\n' >"$bundle_dir/diagnostics-binary-error.txt"
    fi
}

prune_history() {
    if [ "$KEEP_COUNT" -le 0 ] 2>/dev/null; then
        return 0
    fi

    old_entries=$(ls -1t "$HISTORY_DIR"/ddnsto-support-*.zip 2>/dev/null | awk "NR>$KEEP_COUNT")
    if [ -n "$old_entries" ]; then
        printf '%s\n' "$old_entries" | while IFS= read -r entry; do
            [ -n "$entry" ] || continue
            rm -f "$entry"
        done
    fi
}

create_archive() {
    source_dir=$1
    archive_path=$2

    if command -v zip >/dev/null 2>&1; then
        (
            cd "$source_dir"
            zip -qr "$archive_path" bundle
        )
        return 0
    fi

    if command -v python3 >/dev/null 2>&1; then
        SOURCE_DIR="$source_dir" ARCHIVE_PATH="$archive_path" python3 - <<'PY'
import os
import zipfile

source_dir = os.environ["SOURCE_DIR"]
archive_path = os.environ["ARCHIVE_PATH"]

with zipfile.ZipFile(archive_path, "w", compression=zipfile.ZIP_DEFLATED) as zf:
    root = os.path.join(source_dir, "bundle")
    for current_root, _, files in os.walk(root):
        for name in files:
            full_path = os.path.join(current_root, name)
            rel_path = os.path.relpath(full_path, source_dir)
            zf.write(full_path, rel_path)
PY
        return 0
    fi

    echo "zip or python3 is required to create support bundle archives" >&2
    return 1
}

create_bundle() {
    reason=${1:-manual}

    ensure_dirs

    tmp_dir=$(mktemp -d)
    bundle_root="$tmp_dir/bundle"
    mkdir -p "$bundle_root"

    write_runtime_summary "$bundle_root/runtime.txt" "$reason"
    write_env_summary "$bundle_root/env.txt"
    copy_log_tail "$bundle_root/ddnstoshell.tail.log"
    collect_ddnsto_outputs "$bundle_root"

    archive_name="ddnsto-support-$(timestamp).zip"
    archive_path="$HISTORY_DIR/$archive_name"

    create_archive "$tmp_dir" "$archive_path"

    cp "$archive_path" "$LATEST_DIR/ddnsto-support.zip"
    printf '%s\n' "$archive_path" >"$LATEST_DIR/last-path.txt"
    printf '%s\n' "$reason" >"$LATEST_DIR/last-reason.txt"
    prune_history
    rm -rf "$tmp_dir"

    printf '%s\n' "$archive_path"
}

usage() {
    cat <<'EOF'
Usage:
  ddnsto-support.sh bundle [reason]
  ddnsto-support.sh auto [reason]
EOF
}

command_name=${1:-bundle}
reason=${2:-manual}

case "$command_name" in
    bundle)
        create_bundle "$reason"
        ;;
    auto)
        create_bundle "$reason"
        ;;
    *)
        usage >&2
        exit 2
        ;;
esac
