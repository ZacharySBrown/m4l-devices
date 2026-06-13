# Setforge — Unified Product Features Spec

**For:** Claude Code. **Status:** spec — the **full functional feature set** the unification is meant to deliver, with honest build-status on each so the remaining product work is unambiguous.
**Why this exists:** prior unification work covered plumbing + UAT hardening (paths, install, test harness, device-panel skin). This spec is the **product features themselves** — what the instrument actually *does* — recovered from the locked product definition (`~/zacharysbrown/maad_traash_muzak/mtm/Setforge-Product-Definition.md`) and cross-checked against the 58-feature inventory (`docs/FEATURE_INVENTORY.md`).

**Status legend:** ✅ built · 🟡 partial / scaffolded (real wiring owed) · 🔴 specced, not built · ⏸ deferred by decision · 🧪 needs hardware/aural verify.

> **The honest headline — what you're still missing (the biggest 🔴/🟡):**
> 1. **punch-FX DSP** — the four actual audio effects. 🔴
> 2. **Companion on real data** — waveforms from real peaks + live taste-DB recommendations. 🟡
> 3. **Curation "pairs"** — clip-granular two-deck auditioning with A↔B swap + pairing score. 🔴
> 4. **Scenes as vetted clip-pairings** — the redefinition (tag/track-across-banks/show-in-both-views + SCENE◀▶ cycle). 🟡
> 5. **"No lying pads"** — every lit control does something (stub modifiers / FX bus → real Live sends). 🔴
> 6. **Pro-MK2 hardware profile** confirm (one-file diff). 🧪

---

## North star
A stem-based mashup/remix **instrument + production toolkit** on Ableton Live, driven by a **Launchpad Pro MK2** + an **interactive companion app**. Curation feeds two forks: **Production** (arrangement-view mashups/remixes/sampling) and **Performance** (live dual-deck stem mashups). During performance the **taste-DB companion app replaces the need to watch Ableton** — eyes on the app, hands on the Launchpad.

The pipeline is three phases: **Curation (always Phase 1) → Production (arrangement) / Performance (session)**.

---

## 1. Core performance model — always two decks (LOCKED)
- **Two decks A & B, permanently** (no single-song mode). ✅ (loader)
- Each deck = 4 stems (drums/bass/other/vox) → **8×8 grid = 8 stem rows × 8 chop columns**, permanent. ✅
- **Per-bank multi-preset stem sourcing:** each stem row sourced from a *different preset within its bank* (e.g. Deck A = {drums:A1, bass:A4, other:A3, vox:A7}); **max one stem per type per bank**. ✅ (per-row sourcing, cc-019)
- Chop trigger/replace/stop, per-row launch quant (drums 1/16, bass bar, other 1/4, vox 1/2), gapless hot-swap, dual-song 8-voice, panic/eject/reload. ✅ (PERF-04/05/08/09/10/16/17/18) — 🧪 aural phase/flam still owed.

## 2. Launchpad Pro MK2 surface (LOCKED layout)
- **Top → Bank A presets · Bottom → Bank B presets · Left → 8 stem-assign triggers · Right → punch-FX + utility.** ✅ layout / 🧪 hardware note-map is *provisional* (`docs/specs/pro-mk2-surface.md §8`) — needs one physical confirm (top/bottom = notes 91–98/1–8; pad pressure = poly-AT 0xA0). Confirming = a one-file table edit.
- **Stem-sourcing gesture:** *hold* a left stem button → *tap* a preset → that row loads all that stem's chops from that preset. ✅ (cc-019)
- **Per-source LED coloring** across grid rows + side buttons by source preset. ✅ (cc-020)
- **Right side = punch-FX** (top 4: REPEAT/STUTTER/SLICER/OCT−) + PANIC + **SCENE◀/SCENE▶** + 1 free slot (note 19). 🟡 controller/LED/gesture built (cc-018/021); **see §3 for the DSP gap**; SCENE◀▶ depends on §6.
- MK3 surface code present but dead (mk2 hardcoded). ⏸ (PERF-13)

## 3. punch-FX — momentary performance effects (LOCKED gesture, DSP 🔴)
The four EP-133-K.O.-II-style effects: **Beat Repeat · Stutter · Mute Slicer · Octave Down**.
- **Gesture (hold-FX → press pad):** holding a punch button turns the 8×8 grid into "apply this effect to the pad I press"; the **clip/stem under the pad** gets the effect and the **pad's polyphonic aftertouch sets the 0–1 amount**; multiple pads = multiple stems at independent pressures. Release pad = off, release button = grid back to chops. ✅ control layer (`punch-layer.js`, FX_APPLY state, `resolveFxTarget`, poly-AT parser — cc-017/018/021).
- **Routing = per-stem (Phase 1)** on the existing `sf-{stem}-{x,y}` tracks; `resolveFxTarget(pad,mode)` keeps `deckA/deckB/master` as a future toggle. ✅ resolver.
- **🔴 THE GAP: the actual DSP is not built.** The four effects need to exist as real audio (gen~ or native chain) on the stem tracks, aural-tuned. Spec: `device/punch-fx/spec/punch-fx-spec.md`. Today the pads light and the amount is read, but **no sound changes** — a "lying pad."
- **Stretch ⏸:** route punch triggers to a dedicated Ableton **send** with its own VST chain.

## 4. "No lying pads" — every lit control does something (🔴 principle)
- The legacy stub modifiers (MUTE/REV/STUT/HALF/DBL/KILL) light up but produce **zero audio** (PERF-06 partial, 2/8 functional). Under the punch-FX surface revision most are **displaced**; survivors must either become real audio or be **removed from the surface** — no control may light without effect.
- **FX bus → real Live sends/returns** wired (Phase-1 1.6). 🔴
- Acceptance: audit every lit pad/button; each maps to a real audio or state effect, or it's dark.

## 5. Companion app — the centerpiece (LOCKED, real-data wiring 🟡)
Replaces the Ableton window during performance. Three views:
- **Perform** (locked v2 layout): **surface-mirror centerpiece** (large, glowing), **now-playing left**, **preset→song map right** (the biggest at-a-glance value — which song sits on each A/B preset, live-sourced stem flagged), **Mix-Next + Queue along the bottom**. ✅ layout/render (cc-026/027/028).
- **Curate**: clip-level selection, A↔B swap, vetted-pairings/scenes board. ✅ scaffold (cc-029) — see §7/§8 for the real curation features it must drive.
- **Arrange**: dual-deck timeline, scenes-as-markers. ✅ scaffold (cc-038).
- **Per-source-preset color coding** (each preset its own accent; every stem row + assign button + now-playing carries its source color + source-ID chip; preset map = the legend). ✅
- **Aesthetic LOCKED:** dark-slate + amber(A)/cyan(B) + neon glow + perspective grid floor. ✅ (matches the unified device panels, cc-040).
- **🟡 THE GAP — real data:** waveform visualizers + clip-progress are scaffolded but need **real peaks** (peaks generator exists, cc-024) and live clip state; **Mix-Next must call the real taste-DB recommender** (see §9), not sample data. Two browser bugs already bit here (collapsed CSS, blank-until-poll) — keep the regression guards.
- **Interactive:** queue/tee-up additional sets to transition after a break; audition sets here. 🟡 (`/action` wired cc-034; real queueing owed).
- **Future polish ⏸:** clip **tags** (section differentiation), **loops vs one-shots** marking.

## 6. Curation — Phase 1 (the front of the whole product)
- **The pipeline** (`forge-set` → DB-dedup → stems → `reconciled_continuity` chops + vocal warp grid → set.json+manifest). ✅ and is the **one true pipeline** (skill: `taste/.claude/skills/forge-set/`). Harden per lean plan §B.
- **Refined preset (per song), session view:** (a) delete clips · (b) move clip start/end within loop or into padding · (c) move clips to other slots on the same stem track · (d) materialize warp changes ⏸ *never build now*. Output = best chops per stem for that song. 🔴 (deferred as Phase-3.1, but it's a wanted feature — flag for scheduling).
- **Pairs — clip-granular auditioning (🔴 / "arrangement-loader dual-deck parity"):** load two songs (one per deck), select a **specific clip per stem on each deck**, hear the *combination* (e.g. A·drums ch1 + B·vox ch3), **swap songs A↔B** to optimize deck placement, **taste-DB scores the pairing**. This is a headline curation feature and is **not built**.
- **Arrangement-view curation:** single track — move/delete/consolidate clips (often loop-stacking), saved as a curated arrangement-view manifest. 🟡 (arranger places + snapshots; the *editing/consolidation* loop is thin).

## 7. Scenes — vetted clip pairings (REDEFINED, 🟡)
A **scene = a specific clip combination vetted as good** (A·drums ch1 + B·vox ch3 + A·other ch2), **NOT a whole-state snapshot**.
- **Tag** the current combo as a scene while auditioning (Curate). 🔴 (today's `scene-memory` stores whole-state, PERF-07 — needs redefinition to clip-set).
- **Tracked persistently** — a scene follows its clips even as songs move across banks A↔B. 🔴
- **Shown in both Curate and Arrangement** views ("what I know sounds good"). 🟡 (Arrange shows scene markers; the clip-pairing semantics + Curate board need the redefinition).
- **Manual trigger now** + **SCENE◀/SCENE▶ cycle buttons** on the surface; single-button recall ⏸ deferred ("almost cheating"). 🟡

## 8. Production — arrangement view (🟡/open)
- Prechop → arranger places clips on the timeline, warping OFF, project tempo = manifest BPM, intro chunks, **re-anchor from a named locator**, snapshot export. ✅ (ARR-01→14; cc-036/037).
- **"Arranged set" — bank of 8 tracks (two songs) at a timeline point** → songs that *flow, arranged not performed*; **load 2 tracks at the same playhead position, overwriting what's there.** 🔴/open (dual-deck arrangement parity not fully explored).
- Vetted **scenes on the timeline**. 🟡 (depends on §7 redefinition).

## 9. taste-DB integration — recommendations (🟡)
- **Recommend engine**: 6-dimension scoring (tempo/key/groove/vocal/timbre/taste), **transition** vs **mashup** modes (+ `--tempo-lock`). ✅ (CUR-11) + popup server (CUR-12).
- **🟡 THE GAP — surfaced in the live product:** the companion **Mix-Next** must call this live to recommend **next-best songs** AND **stem-on-stem mixes** ("this drum loop under that vocal"), both **congruent and interestingly incongruent**, by tempo/key/style. The engine exists; the **stem-on-stem pairing recommendation + its wiring into Perform/Curate is owed.**

## 10. Cross-cutting (LOCKED)
- **Harden the edges** — boundary failure modes are where live friction boils over; **robustness is a product feature** (empty set, missing stem, wrong tempo, large set — UAT-14→17). ✅ mostly, 🧪 some need Live verify.
- **Persistence = custom manifest, hardened.** Ableton-native save ⏸ revisit only on a clear win. ✅ (PERF-11/18 save/reload).
- **Cross-machine** (build on one, sync, perform on another). ✅ sync script (CUR-13/INST-04); reproducibility hardened by the lean plan's path work.
- **Unified visual language** across the 4 device front panels + companion (one design system). ✅ (cc-040).

---

## Build backlog implied by the gaps (suggested order)
1. **punch-FX DSP** (§3) — the four effects as real audio + aural tune. *Biggest "lying pad" fix; high product value.*
2. **Companion real-data wiring** (§5/§9) — peaks + live clip state + real Mix-Next (incl. stem-on-stem recs). *Makes the centerpiece real.*
3. **Scenes redefinition** (§7) — clip-pairing model + persistent tracking + Curate board + SCENE◀▶. *Unblocks §5/§8 scene displays.*
4. **Curation pairs** (§6) — two-deck clip-granular audition + A↔B swap + pairing score. *Headline curation feature.*
5. **"No lying pads" audit** (§4) — remove/realize every inert control; FX bus → real sends.
6. **Pro-MK2 hardware confirm** (§2) + remaining 🧪 aural/Live UAT (see `SETFORGE-UAT-DRIVE-PLAN-AND-HARNESS-GAPS.md`).
7. **Refined-preset editing** (§6) + **arranged-set parity** (§8) — schedule the deferred curation/production depth.

## Pointers
- Product vision (source of truth): `~/zacharysbrown/maad_traash_muzak/mtm/Setforge-Product-Definition.md`.
- Feature catalog + status detail: `docs/FEATURE_INVENTORY.md` (58 features).
- Surface profile: `docs/specs/pro-mk2-surface.md`; punch-FX: `device/punch-fx/spec/punch-fx-spec.md`.
- Acceptance tests: `docs/UAT_PLAN.md`. Harness gaps: `docs/SETFORGE-UAT-DRIVE-PLAN-AND-HARNESS-GAPS.md`. Paths/install: `docs/SETFORGE-LEAN-RECONCILIATION-PLAN.md` + `docs/SETFORGE-FRESH-INSTALL-SPEC.md`.
