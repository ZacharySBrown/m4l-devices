"""Op 6 (composite) — copy a clip into multiple slots, edit one copy's
markers independently, save, reload, verify each slot keeps its own markers.

The workflow that motivates this: load a full vocal stem at slot 0, copy it
to slots 1-3, then chop each copy to a different vocal section (verse 1,
chorus, verse 2, bridge) by editing their loop markers.

Composes:
  - duplicate-identity detection in syncPresetClips Pass 2 (cloneChop +
    fresh identity stamp)
  - independent property extraction per cloned chop
  - column field persistence on reload (the fix from this session)

If any of those break, slot 2's edited markers will get clobbered by the
source's markers, or all 4 slots will end up identical after reload.
"""

import json
import time

from snapshot import sandbox_manifest_path


def test_copy_to_multiple_slots_then_edit_one(sandbox_set, loader, live):
    loader.activate_preset(0, settle_secs=5.0)
    sf_drums = live.find_track("sf-drums")

    src_slot = 0

    # Clear slots 1-3 so the copies land in clean targets
    for s in (1, 2, 3):
        live.delete_clip(sf_drums, s)
    time.sleep(0.5)

    # Copy slot 0 into 1, 2, 3
    for dst in (1, 2, 3):
        live.copy_clip(sf_drums, src_slot, sf_drums, dst)
        time.sleep(0.3)

    # Verify all 4 slots hold a clip pre-edit
    for s in (0, 1, 2, 3):
        st = live.get_clip_state(sf_drums, s)
        assert st.has_clip, f"slot {s} should hold a clip after copy"
        assert st.warping == 1

    # Now edit slot 2's loop independently (shrink to 2 beats)
    live.edit_clip_markers(sf_drums, 2, loop_end=2.0)
    time.sleep(0.5)

    # Pre-save sanity: slot 2 short, others full
    pre_save = {s: live.get_clip_state(sf_drums, s).loop_end for s in (0, 1, 2, 3)}
    assert abs(pre_save[2] - 2.0) < 0.01, f"slot 2 didn't take the edit: {pre_save}"
    for s in (0, 1, 3):
        assert pre_save[s] > 3.0, f"slot {s} loop_end shouldn't have shrunk: {pre_save}"

    loader.save(settle_secs=3.0)
    loader.eject()
    loader.load_set(sandbox_set)
    loader.activate_preset(0, settle_secs=5.0)

    post_reload = {s: live.get_clip_state(sf_drums, s) for s in (0, 1, 2, 3)}
    for s in (0, 1, 2, 3):
        assert post_reload[s].has_clip, f"slot {s} should hold a clip after reload"

    # Slot 2 should still be ~2 beats; the others ~4 beats. The fix's
    # rounding lands integers, so allow ±0.05.
    assert abs(post_reload[2].loop_end - 2.0) < 0.05, (
        f"slot 2's shorter loop didn't persist: {post_reload[2].loop_end}"
    )
    for s in (0, 1, 3):
        assert post_reload[s].loop_end > 3.0, (
            f"slot {s} loop got corrupted on reload: {post_reload[s].loop_end} "
            f"(should be ~4, others: {[(k, v.loop_end) for k,v in post_reload.items()]})"
        )

    # Manifest: should now have 4 chops at columns 1,2,3,4 (cols 5-8 we
    # didn't touch, so still 4 original chops there → 8 total). Chops at
    # cols 1,2,4 should be full-length; col 3 (slot 2) should be ~half.
    with open(sandbox_manifest_path()) as f:
        manifest = json.load(f)
    drums = next(t for t in manifest["tracks"] if str(t.get("id")) == "1835") \
        ["stems"]["drums"]["chops"]
    by_col = {c["column"]: c for c in drums}
    assert by_col[3]["length_sec"] < by_col[1]["length_sec"] / 1.5, (
        f"col 3 length should be ~half col 1's; got "
        f"col1={by_col[1]['length_sec']}, col3={by_col[3]['length_sec']}"
    )
    for col in (1, 2, 4):
        assert by_col[col]["length_sec"] > by_col[3]["length_sec"] * 1.5, (
            f"col {col} length should be ~2× col 3's; got "
            f"col{col}={by_col[col]['length_sec']}, col3={by_col[3]['length_sec']}"
        )
