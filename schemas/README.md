# Setforge contract schemas (L1)

JSON Schemas (draft 2020-12) + a validator for the cross-repo data contracts. Catches malformed artifacts early (hardens the edges).

## Validated against real data ✅
- **`set.schema.json`** — `set.json` (schema_version `1.0`): name, global_tempo, 8-slot preset banks (null-allowed), setlist.
- **`manifest.schema.json`** — `manifest.json` (schema_version `2.1`): tracks[] → bar_grid + stems{drums,bass,other,vox} → chops[] (require `chop_path`/`loop_start_sec`/`loop_end_sec`) and full-stem vox (`mode`, `warp_grid`).

Permissive (`additionalProperties: true`) for forward-compat, but the load-bearing fields are required.

## Validator
```bash
python3 schemas/validate.py <file> ...     # auto-detects set vs manifest; exit 0 = all valid
python3 -m pytest schemas/                 # tests: real set+manifest PASS, malformed fixture FAILs
```
Library: `from validate import validate_file` → `(ok, schema_name, errors)`.

## TODO — author when example data is on hand
Same pattern (drop a real file in `examples/`, write schema + test):
- prechop / arrangement manifest (`prechop_manifest.json`)
- deck-loader v1 manifest
- `.calib_override.json`

## CI wiring
Add `python3 schemas/validate.py <artifacts>` to the `setforge-test` / pre-commit gate, alongside `PYTHONPATH=tools python3 -m forge_device.check_drift`.
