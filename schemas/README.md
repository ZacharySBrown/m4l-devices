# Setforge contract schemas (L1)

JSON Schemas (draft 2020-12) + a validator for the cross-repo data contracts. Catches malformed artifacts early (hardens the edges).

## Schemas

| Schema | File | Status |
|--------|------|--------|
| `set.json` (1.0) | `set.schema.json` | ✅ validated against real data |
| `manifest.json` (2.x) | `manifest.schema.json` | ✅ validated against real data |
| `arrangement_manifest.json` (1) | `arrangement.schema.json` | ✅ validated against real data |
| `.calib_override.json` | `calib_override.schema.json` | ⚠️ provisional (from FEATURE_INVENTORY spec) |

Permissive (`additionalProperties: true`) for forward-compat, but the load-bearing fields are required.

## Validator
```bash
python3 schemas/validate.py <file> ...     # auto-detects type; exit 0 = all valid
python3 -m pytest schemas/                 # 10 tests: real data PASS, malformed FAILs
```
Library: `from validate import validate_file` → `(ok, schema_name, errors)`.

## Test matrix (10 tests)
- **set**: `hiphop_danceable.set.json`, `hiphop_v3.set.json`, `full_vocal.set.json` (PASS); `bad.set.json` (expected FAIL)
- **manifest**: `hiphop_danceable.manifest.json`, `hiphop_v3.manifest.json`, `varying_track.manifest.json` (PASS); `invalid_bpm.manifest.json` (expected FAIL — bpm=0 caught)
- **arrangement**: `breaks-n-beats.arrangement.json` (PASS)
- **calib_override**: `sample.calib_override.json` (PASS)

## CI wiring
Add `python3 schemas/validate.py <artifacts>` to the `setforge-test` / pre-commit gate, alongside `PYTHONPATH=tools python3 -m forge_device.check_drift`.
