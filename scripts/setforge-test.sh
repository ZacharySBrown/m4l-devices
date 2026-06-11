#!/usr/bin/env bash
# Setforge CI test runner — the green suite that gates commits.
#   L0  drift-guard      shipped loader.js == fresh concat of src/loader/*
#   L1  contract schemas  set.json + manifest validate; schema unit tests
#   JS  monolith e2e      loader-e2e against the built loader.js (mocha)
#
# The Live-in-the-loop UAT (IAC + AbletonOSC) is NOT run here — it needs Ableton
# running on the host. Run that separately:
#   python3 device/setforge-live/tests/uat/uat_perform_smoke.py
#
# Usage:  bash scripts/setforge-test.sh
# Exit 0 = all green, 1 = any failure.
set -uo pipefail
cd "$(dirname "$0")/.."

fail=0
step() {
  local name="$1"; shift
  echo; echo "▸ $name"
  if "$@"; then echo "  ✓ pass"; else echo "  ✗ FAIL"; fail=1; fi
}

step "L0 · drift-guard (monolith == src)" \
  env PYTHONPATH=tools python3 -m forge_device.check_drift

step "L1 · contract validation (set + manifest)" \
  python3 schemas/validate.py \
    schemas/examples/hiphop_danceable.set.json \
    schemas/examples/hiphop_danceable.manifest.json

step "L1 · schema unit tests" \
  python3 -m pytest schemas/ -q

step "L1 · spec↔code surface drift" \
  env PYTHONPATH=tools python3 -m forge_device.check_surface_spec

step "JS · monolith e2e (loader-e2e)" \
  bash -c 'cd device/setforge-live && npx --no-install mocha tests/integration/loader-e2e.test.js'

step "JS · surface e2e (Phase-1 gesture chain)" \
  bash -c 'cd device/setforge-live && npx --no-install mocha tests/integration/surface-e2e.test.js'

step "JS · companion data layer (interpolation + store)" \
  node --test companion/tests/render/datalayer.test.mjs

step "JS · companion render components (surface/now-playing/legend)" \
  node --test companion/tests/render/components.test.mjs

step "JS · companion Perform view UAT (window-replacement checklist)" \
  node --test companion/tests/uat_perform.test.mjs

step "JS · companion Curate view UAT (clip select/swap/scenes)" \
  node --test companion/tests/uat_curate.test.mjs

step "JS · companion guards (class coverage + init render)" \
  node --test companion/tests/render/class_coverage.test.mjs companion/tests/render/init_render.test.mjs

step "PY · companion e2e (server + state + peaks + actions)" \
  python3 -m pytest companion/tests/ -q

echo
if [ "$fail" -eq 0 ]; then
  echo "============================================================"
  echo "  ALL GREEN ✓   (L0 + L1 + spec-drift + JS e2e + surface e2e + companion)"
  echo "============================================================"
else
  echo "============================================================"
  echo "  FAILURES ✗   — see above"
  echo "============================================================"
fi
echo "note: headless UAT (Live-in-the-loop) runs on the host — tests/uat/uat_perform_smoke.py"
exit "$fail"
