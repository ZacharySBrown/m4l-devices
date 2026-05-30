"""Op 5 — duplicate a clip into another slot, save, reload, verify both
copies exist with distinct identities.

The duplicate carries the source clip's name (including the identity prefix)
to the destination. Sync's structural pass detects the duplicate identity and
stamps a fresh ID on the second occurrence, so both end up uniquely tracked.

To avoid mixing op 5 with op 4 (the destination slot starts with a clip we'd
overwrite), the test first deletes the destination slot, then copies into it.
The delete is a setup step; the assertions are about the copy.
"""

import json
import time


def _identity(name: str | None) -> str | None:
    if not name or not name.startswith("[sf:"):
        return None
    return name.split("]")[0][4:]


def test_copy_clip_creates_distinct_identity(sandbox_set, loader, live):
    loader.activate_preset(0, settle_secs=5.0)
    sf_drums = live.find_track("sf-drums")

    src_slot, dst_slot = 0, 6

    # Setup: clear dst so the copy lands in a clean slot
    live.delete_clip(sf_drums, dst_slot)
    time.sleep(0.3)

    before_src = live.get_clip_state(sf_drums, src_slot)
    assert before_src.has_clip
    src_identity = _identity(before_src.name)

    live.copy_clip(sf_drums, src_slot, sf_drums, dst_slot)
    time.sleep(0.5)

    after_src = live.get_clip_state(sf_drums, src_slot)
    after_dst = live.get_clip_state(sf_drums, dst_slot)
    assert after_src.has_clip, "source slot should still hold its clip"
    assert after_dst.has_clip, "destination should now hold the duplicate"
    # Pre-sync: duplicate carries source's name, so both share identity here.
    # Sync will stamp a fresh identity on the duplicate.

    loader.save(settle_secs=3.0)
    loader.eject()
    loader.load_set(sandbox_set)
    loader.activate_preset(0, settle_secs=5.0)

    reloaded_src = live.get_clip_state(sf_drums, src_slot)
    reloaded_dst = live.get_clip_state(sf_drums, dst_slot)
    assert reloaded_src.has_clip and reloaded_dst.has_clip

    src_id = _identity(reloaded_src.name)
    dst_id = _identity(reloaded_dst.name)
    assert src_id == src_identity, f"source identity should be preserved: got {src_id!r}"
    assert dst_id is not None and dst_id != src_identity, (
        f"destination should have a distinct identity, got {dst_id!r} (same as source)"
    )

    # Manifest: chop count should be the same as the original (we deleted one
    # for setup and added one via copy).
    from snapshot import sandbox_manifest_path
    with open(sandbox_manifest_path()) as f:
        manifest = json.load(f)
    drums = next(t for t in manifest["tracks"] if str(t.get("id")) == "1835") \
        ["stems"]["drums"]["chops"]
    assert len(drums) == 8, f"drums chop count should be 8 (delete + copy = net zero), got {len(drums)}"
    identities = [c.get("identity") for c in drums if c.get("identity")]
    assert len(set(identities)) == len(identities), (
        f"all chop identities should be unique, got duplicates in {identities}"
    )
