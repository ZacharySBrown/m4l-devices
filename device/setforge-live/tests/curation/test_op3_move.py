"""Op 3 — move a clip from slot A to slot B, save, reload, verify persistence.

Within a session, sync tracks moves via the identity prefix in clip names.
Across save + reload, identity is *regenerated* from array position (it's a
within-session reconciliation mechanism, not a persistent ID). So the test
verifies the move by content (label) and column, not by identity prefix.
"""

import json
import time


def _label_in_name(name: str | None) -> str | None:
    """Strip the [sf:...] prefix to expose the human-readable label."""
    if not name:
        return None
    if name.startswith("[sf:"):
        return name.split("]", 1)[1].strip() if "]" in name else name
    return name


def test_move_clip_to_empty_slot_persists(sandbox_set, loader, live):
    loader.activate_preset(0, settle_secs=5.0)
    sf_drums = live.find_track("sf-drums")

    src_slot, dst_slot = 0, 5
    before_src = live.get_clip_state(sf_drums, src_slot)
    assert before_src.has_clip, f"sf-drums slot {src_slot} must hold a clip"
    src_label = _label_in_name(before_src.name)
    assert src_label == "MAIN [main]", f"unexpected source label: {src_label!r}"

    # Move (destructive: overwrites whatever was at dst)
    live.move_clip(sf_drums, src_slot, sf_drums, dst_slot)
    time.sleep(1.0)

    after_src = live.get_clip_state(sf_drums, src_slot)
    after_dst = live.get_clip_state(sf_drums, dst_slot)
    assert not after_src.has_clip, "source slot should be empty after move"
    assert after_dst.has_clip, "destination slot should hold the moved clip"
    assert _label_in_name(after_dst.name) == src_label, (
        f"destination label {_label_in_name(after_dst.name)!r} should match "
        f"source {src_label!r}"
    )

    loader.save(settle_secs=3.0)
    loader.eject()
    loader.load_set(sandbox_set)
    loader.activate_preset(0, settle_secs=5.0)

    reloaded_src = live.get_clip_state(sf_drums, src_slot)
    reloaded_dst = live.get_clip_state(sf_drums, dst_slot)
    assert not reloaded_src.has_clip, f"after reload, slot {src_slot} should still be empty"
    assert reloaded_dst.has_clip, f"after reload, slot {dst_slot} should hold the moved clip"
    assert _label_in_name(reloaded_dst.name) == src_label, (
        f"after reload, dst label={_label_in_name(reloaded_dst.name)!r}, expected {src_label!r}"
    )

    # Manifest: chop with label "MAIN" should now be at column 6 (dst+1)
    from snapshot import sandbox_manifest_path
    with open(sandbox_manifest_path()) as f:
        manifest = json.load(f)
    drums = next(t for t in manifest["tracks"] if str(t.get("id")) == "1835") \
        ["stems"]["drums"]["chops"]
    main_chops = [c for c in drums if c.get("label") == "MAIN"]
    assert len(main_chops) == 1, f"expected exactly one chop labelled MAIN, got {len(main_chops)}"
    assert main_chops[0]["column"] == dst_slot + 1, (
        f"moved chop's column={main_chops[0]['column']}, expected {dst_slot + 1}"
    )
