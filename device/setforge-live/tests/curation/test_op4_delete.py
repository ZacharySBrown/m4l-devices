"""Op 4 — delete a clip in Live, save, reload, verify the slot stays empty
and the manifest's chop list shrinks by one entry.

Sync's structural pass prunes any manifest chop whose identity didn't appear
on any live clip during the scan — so a deleted clip means a dropped chop.
"""

import json
import time


def test_delete_clip_persists(sandbox_set, loader, live):
    loader.activate_preset(0, settle_secs=5.0)
    sf_drums = live.find_track("sf-drums")

    target_slot = 2

    before = live.get_clip_state(sf_drums, target_slot)
    assert before.has_clip, f"slot {target_slot} must hold a clip pre-delete"
    target_identity = before.name.split("]")[0][4:]  # "1835/drums/2"

    live.delete_clip(sf_drums, target_slot)
    time.sleep(0.5)

    after = live.get_clip_state(sf_drums, target_slot)
    assert not after.has_clip, f"slot {target_slot} should be empty after delete"

    loader.save(settle_secs=3.0)
    loader.eject()
    loader.load_set(sandbox_set)
    loader.activate_preset(0, settle_secs=5.0)

    reloaded = live.get_clip_state(sf_drums, target_slot)
    assert not reloaded.has_clip, f"slot {target_slot} should still be empty after reload"

    from snapshot import sandbox_manifest_path
    with open(sandbox_manifest_path()) as f:
        manifest = json.load(f)
    drums = next(t for t in manifest["tracks"] if str(t.get("id")) == "1835") \
        ["stems"]["drums"]["chops"]
    surviving = [c for c in drums if c.get("identity") == target_identity]
    assert len(surviving) == 0, (
        f"manifest should have pruned chop with identity {target_identity!r}, "
        f"found {len(surviving)} surviving entries"
    )
    # Drums originally had 8 chops; after delete should have 7.
    assert len(drums) == 7, f"drums chop count should be 7 after delete, got {len(drums)}"
