#!/usr/bin/env bash
# install.sh — build and install all setforge-live M4L devices
#
# Run from anywhere:  ./install.sh
# Or from the repo:   bash install.sh
#
# What it does:
#   1. Rebuilds .maxpat, .amxd, and concatenated JS from source
#   2. Creates Max Package dir (~/Documents/Max 9/Packages/setforge-live/)
#   3. Deploys loader.js + calibrate.js into the package so Max finds them
#
# No external dependencies — build tools are bundled in tools/.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
DEVICE_DIR="$REPO_ROOT/device/setforge-live"
BUILD_SCRIPT="$DEVICE_DIR/build/build_setforge.py"

echo "=== setforge-live installer ==="
echo "  repo: $REPO_ROOT"
echo ""

# ── 1. Detect Max version ──
MAX9_DIR="$HOME/Documents/Max 9"
MAX8_DIR="$HOME/Documents/Max 8"

if [ -d "$MAX9_DIR" ]; then
    MAX_PKG="$MAX9_DIR/Packages/setforge-live"
    echo "  Max 9 detected"
elif [ -d "$MAX8_DIR" ]; then
    MAX_PKG="$MAX8_DIR/Packages/setforge-live"
    echo "  Max 8 detected"
else
    echo "  WARNING: No Max 8 or 9 found in ~/Documents."
    echo "  Creating Max 9 package dir anyway (Max will find it when installed)."
    MAX_PKG="$MAX9_DIR/Packages/setforge-live"
fi

# ── 2. Create package structure ──
mkdir -p "$MAX_PKG/javascript"
echo "  package dir: $MAX_PKG"

# ── 3. Run the build ──
echo ""
echo "  Running build..."
cd "$DEVICE_DIR"
python3 "$BUILD_SCRIPT"

# ── 4. Verify key outputs exist ──
echo ""
FAIL=0
for f in \
    "$DEVICE_DIR/setforge-loader.amxd" \
    "$DEVICE_DIR/setforge-grid.amxd" \
    "$DEVICE_DIR/setforge-calibrate.amxd" \
    "$DEVICE_DIR/setforge-arranger.amxd" \
    "$DEVICE_DIR/loader.js" \
    "$DEVICE_DIR/arranger-main.js" \
    "$DEVICE_DIR/sf_arrangement_loader.js" \
    "$MAX_PKG/javascript/loader.js" \
    "$MAX_PKG/javascript/arranger-main.js" \
    "$MAX_PKG/javascript/sf_arrangement_loader.js"; do
    if [ -f "$f" ]; then
        echo "  OK  $f"
    else
        echo "  MISSING  $f"
        FAIL=1
    fi
done

if [ "$FAIL" -eq 0 ]; then
    echo ""
    echo "=== Install complete ==="
    echo ""
    echo "Next steps in Ableton Live:"
    echo "  1. Add setforge-loader.amxd to an audio track"
    echo "  2. Add setforge-grid.amxd to a MIDI track"
    echo "  3. Set the MIDI track's input/output to your Launchpad (Standalone Port)"
    echo "  4. Browse for a .set.json file in the loader device"
else
    echo ""
    echo "=== Install incomplete — check errors above ==="
    exit 1
fi
