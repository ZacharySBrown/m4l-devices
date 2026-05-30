"""Vocal stem — long bar-grid-aligned chops load and persist edits correctly.

Vocal chops differ from drum chops in two ways that stress the loader's
rounding/warp-marker logic:
  - they're long (e.g. 16 bars / 64 beats / ~39 sec at 98 BPM) so any
    drift in length_sec → beat conversion compounds visibly
  - they ship with .asd files containing beat-this-derived per-bar warp
    markers (the bar-grid alignment), which fixWarpMarkers then flattens
    to uniform-tempo before clip-fire

This test verifies the long-loop case: load preset 0 (1835), confirm a
multi-bar vocal chop fires at exactly an integer beat count matching
length_sec/secPerBeat, then shrink the loop in half, save, reload, and
confirm both the shortened loop and the still-untouched neighbor land
on clean integer beats.
"""

import json
import time

from snapshot import sandbox_manifest_path


def test_vocal_chops_load_at_integer_beats(sandbox_set, loader, live):
    loader.activate_preset(0, settle_secs=5.0)
    sf_vox = live.find_track("sf-vox")

    # Read the manifest to know what to expect
    with open(sandbox_manifest_path()) as f:
        m = json.load(f)
    t = next(t for t in m["tracks"] if str(t.get("id")) == "1835")
    track_bpm = t["bpm"]
    sec_per_beat = 60.0 / track_bpm
    vox_chops = t["stems"]["vox"]["chops"]

    # Walk through each fired vocal slot and verify integer-beat loop_end
    for slot, mc in enumerate(vox_chops):
        st = live.get_clip_state(sf_vox, slot)
        if not st.has_clip:
            continue
        if st.warping != 1:
            continue
        expected_beats = round(mc["length_sec"] / sec_per_beat)
        assert abs(st.loop_end - expected_beats) < 0.05, (
            f"sf-vox slot {slot} ({mc.get('label')}): loop_end={st.loop_end} "
            f"should be ~{expected_beats} beats (length_sec={mc['length_sec']}, "
            f"track_bpm={track_bpm})"
        )
        # Stronger: it must be an integer
        assert abs(st.loop_end - round(st.loop_end)) < 0.05, (
            f"sf-vox slot {slot} loop_end={st.loop_end} is not integer-beat — "
            f"loop will drift against the global grid"
        )


def test_vocal_loop_edit_persists(sandbox_set, loader, live):
    """Edit a long vocal loop in half, save, reload — verify the edit
    persisted at a clean integer-beat boundary and the untouched
    neighbor is unchanged.

    Vocal slots are each their own bar length (e.g. slot 0 = 16 bars,
    slot 1 = 8 bars, slot 2 = 4 bars). We edit slot 0 (the longest) and
    assert slot 1 is bit-for-bit the same as before.
    """
    loader.activate_preset(0, settle_secs=5.0)
    sf_vox = live.find_track("sf-vox")

    before_0 = live.get_clip_state(sf_vox, 0)
    before_1 = live.get_clip_state(sf_vox, 1)
    assert before_0.has_clip and before_1.has_clip
    assert before_0.warping == 1

    original_loop_end_0 = before_0.loop_end
    original_loop_end_1 = before_1.loop_end
    # Halve the long vocal — e.g. 64 → 32 beats
    new_loop_end = original_loop_end_0 / 2.0
    live.edit_clip_markers(sf_vox, 0, loop_end=new_loop_end)
    time.sleep(0.5)
    loader.save(settle_secs=3.0)

    loader.eject()
    loader.load_set(sandbox_set)
    loader.activate_preset(0, settle_secs=5.0)

    after_0 = live.get_clip_state(sf_vox, 0)
    after_1 = live.get_clip_state(sf_vox, 1)

    # Edited chop: integer-beat, persisted at new shorter length
    assert after_0.has_clip and after_0.warping == 1
    rounded_0 = round(after_0.loop_end)
    assert abs(after_0.loop_end - rounded_0) < 0.05, (
        f"edited vocal loop_end={after_0.loop_end} should round to integer beats"
    )
    assert abs(after_0.loop_end - new_loop_end) < 1.0, (
        f"edited vocal loop didn't persist: edited to {new_loop_end}, "
        f"got back {after_0.loop_end}"
    )
    assert after_0.loop_end < original_loop_end_0, (
        f"edited vocal should have shrunk: was {original_loop_end_0}, now {after_0.loop_end}"
    )

    # Untouched neighbor: unchanged, integer-beat
    assert after_1.has_clip and after_1.warping == 1
    rounded_1 = round(after_1.loop_end)
    assert abs(after_1.loop_end - rounded_1) < 0.05, (
        f"untouched vocal[1] loop_end={after_1.loop_end} should be integer beats — "
        f"long loops are where length_sec→beats drift compounds"
    )
    assert abs(after_1.loop_end - original_loop_end_1) < 0.05, (
        f"untouched vocal[1] should be unchanged: was {original_loop_end_1}, "
        f"now {after_1.loop_end} — neighbor got corrupted by our edit"
    )

    # Manifest sanity: both chops' length_sec / sec_per_beat must round
    # cleanly — the long-loop drift case
    with open(sandbox_manifest_path()) as f:
        m = json.load(f)
    t = next(t for t in m["tracks"] if str(t.get("id")) == "1835")
    sec_per_beat = 60.0 / t["bpm"]
    for ch in t["stems"]["vox"]["chops"][:2]:
        beats_continuous = ch["length_sec"] / sec_per_beat
        assert abs(beats_continuous - round(beats_continuous)) < 0.1, (
            f"vox chop {ch.get('label')!r} length_sec={ch['length_sec']} "
            f"doesn't map to integer beats at track BPM "
            f"({beats_continuous:.4f}) — long loops will accumulate drift"
        )
