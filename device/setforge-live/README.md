# setforge-live

MLR-paradigm stem performance device family for Ableton Live.

Two Max for Live devices:

- **`setforge-loader.amxd`** — the performance device, drives two Launchpad Pro grids
- **`setforge-calibrate.amxd`** — the validation device, native warp-marker UX

Reads deck manifests produced by [stemforge](../../stemforge); see `spec/setforge-live-spec.md` for the full build specification.

## Status

Pre-implementation. Phase 0 (scaffold) complete; phases 1-6 not yet started.

## Build order

See spec §7. Phase 2 (calibrator) ships first as v0.1 standalone.

## Reference

- Spec: [`spec/setforge-live-spec.md`](spec/setforge-live-spec.md)
- Tests: `npm test` (run from this directory)
