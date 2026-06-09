#!/usr/bin/env bash
# deploy-test.sh — deploy M4L devices to a machine for integration testing
# with automatic backup so we can cleanly revert.
#
# Usage:
#   bash tools/deploy-test.sh              # deploy locally
#   bash tools/deploy-test.sh zak@mini     # deploy to remote machine
#   bash tools/deploy-test.sh --revert     # revert local deployment
#   bash tools/deploy-test.sh --revert zak@mini  # revert remote deployment
#
# What it does:
#   1. Backs up existing Max Package JS + .amxd files
#   2. Runs install.sh to rebuild and deploy
#   3. On --revert: restores the backed-up files

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BACKUP_DIR="$REPO_ROOT/.deploy-backup"

# ── Parse args ──
REVERT=false
REMOTE=""
for arg in "$@"; do
    if [ "$arg" = "--revert" ]; then
        REVERT=true
    elif [[ "$arg" == *@* ]]; then
        REMOTE="$arg"
    fi
done

# ── Helper: run locally or remotely ──
run_cmd() {
    if [ -n "$REMOTE" ]; then
        ssh "$REMOTE" "$@"
    else
        eval "$@"
    fi
}

copy_to() {
    local src="$1" dst="$2"
    if [ -n "$REMOTE" ]; then
        scp -r "$src" "$REMOTE:$dst"
    else
        cp -r "$src" "$dst"
    fi
}

copy_from() {
    local src="$1" dst="$2"
    if [ -n "$REMOTE" ]; then
        scp -r "$REMOTE:$src" "$dst"
    else
        cp -r "$src" "$dst"
    fi
}

# ── Max Package locations ──
MAX_PACKAGES=()
for ver in 8 9; do
    pkg="Documents/Max $ver/Packages/setforge-live"
    if run_cmd "[ -d ~/\"$pkg\" ]" 2>/dev/null; then
        MAX_PACKAGES+=("$pkg")
    fi
done

if [ "$REVERT" = true ]; then
    echo "=== Reverting deployment ==="

    if [ ! -d "$BACKUP_DIR" ]; then
        echo "  No backup found at $BACKUP_DIR — nothing to revert."
        exit 1
    fi

    # Restore JS files
    for pkg in "${MAX_PACKAGES[@]}"; do
        js_dir="$HOME/$pkg/javascript"
        if [ -d "$BACKUP_DIR/javascript" ]; then
            echo "  Restoring $js_dir"
            run_cmd "rm -rf ~/'$pkg/javascript'"
            copy_to "$BACKUP_DIR/javascript" "$(run_cmd 'echo ~')/$pkg/javascript"
        fi
    done

    # Restore device files
    if [ -d "$BACKUP_DIR/devices" ]; then
        echo "  Restoring device files"
        for f in "$BACKUP_DIR/devices"/*.amxd "$BACKUP_DIR/devices"/*.maxpat; do
            [ -f "$f" ] || continue
            base="$(basename "$f")"
            copy_to "$f" "$(run_cmd 'echo ~')/zacharysbrown/m4l-devices/device/setforge-live/$base"
        done
    fi

    echo "  Cleaning up backup"
    rm -rf "$BACKUP_DIR"
    echo "=== Revert complete ==="
    exit 0
fi

# ── Backup existing files ──
echo "=== Deploying with backup ==="
mkdir -p "$BACKUP_DIR/javascript" "$BACKUP_DIR/devices"

# Backup JS from first Max Package found
for pkg in "${MAX_PACKAGES[@]}"; do
    js_dir="$HOME/$pkg/javascript"
    if run_cmd "[ -d ~/'$pkg/javascript' ]" 2>/dev/null; then
        echo "  Backing up $js_dir"
        copy_from "$(run_cmd 'echo ~')/$pkg/javascript/" "$BACKUP_DIR/javascript/"
        break
    fi
done

# Backup .amxd and .maxpat files
DEVICE_DIR="$REPO_ROOT/device/setforge-live"
for f in "$DEVICE_DIR"/*.amxd "$DEVICE_DIR"/*.maxpat; do
    [ -f "$f" ] || continue
    cp "$f" "$BACKUP_DIR/devices/"
done
echo "  Backed up to $BACKUP_DIR"

# ── Build and deploy ──
echo ""
if [ -n "$REMOTE" ]; then
    echo "  Building on remote ($REMOTE)..."
    ssh "$REMOTE" "cd ~/zacharysbrown/m4l-devices && git pull && bash install.sh"
else
    echo "  Building locally..."
    bash "$REPO_ROOT/install.sh"
fi

echo ""
echo "=== Deploy complete ==="
echo "  To revert: bash tools/deploy-test.sh --revert${REMOTE:+ $REMOTE}"
