# setforge-live

MLR-paradigm stem performance device family for Ableton Live.

Three Max for Live devices:

- **`setforge-loader.amxd`** — audio effect: clip management, LiveAPI, state machine
- **`setforge-grid.amxd`** — MIDI effect: bridges MIDI between Launchpad and loader
- **`setforge-calibrate.amxd`** — the validation device, native warp-marker UX

Reads deck manifests produced by [stemforge](../../stemforge); see `spec/setforge-live-spec.md` for the full build specification.

## Quick start

See **[`docs/setup-guide.md`](docs/setup-guide.md)** for full setup instructions including MIDI preferences, track routing, and troubleshooting.

## Status

In development. Loader + grid bridge functional; calibrator not yet started.

## Build order

See spec §7. Phase 2 (calibrator) ships first as v0.1 standalone.

## Reference

- Setup: [`docs/setup-guide.md`](docs/setup-guide.md)
- Spec: [`spec/setforge-live-spec.md`](spec/setforge-live-spec.md)
- Tests: `npm test` (run from this directory)
