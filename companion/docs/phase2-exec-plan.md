# Phase 2 — Companion App: Execution Plan (cc DAG)

Translates `phase2-companion-spec.md` into a dependency-ordered task DAG for the cc executor. Each node = one bridge task (`NNN-*.task.md`), self-verifying (its own tests + `setforge-test` green), local commits only, no push.

## Waves & dependencies

```
WAVE 0  (foundations — the contract is the seam everything else builds on)
  023 (2A) Contract v2: /state fields + state.schema + sample_state + validator/tests
  024 (2B) Waveform peaks generator + GET /peaks            [needs 023 for peaks_ref shape]
  025 (2C) Write path: POST /action (+ mock-tested commands) [needs 023]
        └ 024 and 025 are mutually independent → parallel-eligible

WAVE 1  (app skeleton — needs the contract)
  026 (2D) SPA shell + data layer (poll/interpolate/store/style) [needs 023]
  027 (2E) Shared render fns: surface-mirror, now-playing, legend [needs 026 + 024]

WAVE 2  (views — need the components; the two views are parallel-eligible)
  028 (2F) Perform view (compose + live layout) + render tests + harness UAT [needs 027]
  029 (2G) Curate view (clip select, A↔B swap, scene board) + tests + UAT     [needs 027 + 025]

WAVE 3  (integration)
  030 (2H/I) Recommendations panel + end-to-end headless harness UAT + setforge-test companion stage [needs 028 + 029]
```

**Parallelization note.** cc is a single serial executor, so tasks run in number order; but the DAG marks the *independent* sets (024∥025, 028∥029) so a second executor — or a future parallel run — can pick them up without conflict. Within the serial run, ordering 023→024→025→026→027→028→029→030 respects all edges.

**Stable seams (so parallel work doesn't collide):**
- `state.schema.json` + `contract.md` — frozen after 023 (the data contract). Later tasks consume, don't change it (changes escalate back to a contract task).
- Pure render fns (`render/*.js`) take `state` only — no shared mutable globals.
- `/action` command vocabulary — fixed in 025; views call it, don't redefine it.

## Per-node testing + harness UAT

| Task | Tests | Harness UAT hook |
|------|-------|------------------|
| 023 | schema validates v2 sample; validator/pytest | state v2 passes `schemas/` validation in setforge-test |
| 024 | pytest: peaks shape + decimation on a fixture WAV | `/peaks` returns valid json for a sample clip |
| 025 | pytest: each `/action` type emits the right loader/OSC command (mocked sink); persistence json written | `/action` round-trip asserted against mock |
| 026 | node: data layer reducer + progress interpolation unit tests | app boots vs `sample_state.json`, renders shell |
| 027 | node/jsdom: each render fn vs sample_state → DOM assertions | components render correct colors/rows/progress |
| 028 | node/jsdom: Perform compose render; "replace-the-window" datum checklist | boot serve.py(sample) → render Perform → assert all perform-critical data present |
| 029 | node/jsdom: Curate interactions fire correct `/action`; scene tracks across swap | POST actions vs mock loader; scenes.json persists + survives swap |
| 030 | end-to-end: serve.py + both views + mock sink; recommendations present | full headless UAT in setforge-test; **live** smoke = manual/zak |

## Acceptance (whole phase)
`python3 companion/serve.py` → working Perform + Curate at `/`; live when Live is up, sample otherwise; waveforms + interpolated progress; legend preset→song + source color; Mix-Next from taste; Curate actions round-trip; scenes persist across A↔B; headless UAT + setforge-test green. zak does the live aural/visual pass.

## Gating to zak / deferred
- Live aural/visual pass (Live + hardware) — zak.
- Arrangement view, refined-preset editing, native persistence — Phase 3.
