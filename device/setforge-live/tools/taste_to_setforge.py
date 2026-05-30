#!/usr/bin/env python3
"""
Convert taste setlist_out data into setforge-live manifest + set JSON.

Usage:
  python3 tools/taste_to_setforge.py <taste_setlist_dir> <output_dir> [--set-name NAME]

Example:
  python3 tools/taste_to_setforge.py ~/zacharysbrown/taste/setlist_out ./sets --set-name rock_mix
"""

import json
import sys
import os
from pathlib import Path

def load_taste_data(setlist_dir):
    """Load all track data from taste's setlist_out directory."""
    stems_dir = Path(setlist_dir) / "stems"
    manifests_dir = Path(setlist_dir) / "manifests"
    tracklist = Path(setlist_dir) / "tracklist.md"

    # Parse tracklist.md for song names and set assignments
    track_names = {}  # deck_manifest_key -> { name, set_num, deck }
    set_assignments = {}  # set_num -> [{ deck, track_id, name }]

    if tracklist.exists():
        current_set = 0
        current_bpm = 0
        for line in tracklist.read_text().splitlines():
            line = line.strip()
            if line.startswith("## Set"):
                parts = line.split("—")
                current_set = int(line.split("Set")[1].split("—")[0].strip())
                if "BPM" in line:
                    bpm_part = line.split("~")[-1].split("BPM")[0].strip()
                    try:
                        current_bpm = float(bpm_part)
                    except ValueError:
                        pass
                if current_set not in set_assignments:
                    set_assignments[current_set] = []
            elif line.startswith("- **") and "·" in line:
                # Parse: - **A** · Artist — Song  ·  key · BPM
                parts = line.split("·")
                if len(parts) >= 2:
                    deck = parts[0].replace("-", "").replace("*", "").strip()
                    name = parts[1].strip()
                    if current_set in set_assignments:
                        set_assignments[current_set].append({
                            "deck": deck,
                            "name": name,
                            "set_bpm": current_bpm,
                        })

    # Load per-deck manifests to get track IDs (stem dir numbers)
    deck_tracks = {}  # "set{N}_{deck}" -> { track_id, bpm, stems, name }
    for mf in sorted(manifests_dir.glob("*.json")):
        data = json.loads(mf.read_text())
        key = mf.stem  # e.g., "set1_A"
        stems_info = {}
        for stem_name, stem_data in data.get("stems", {}).items():
            clips = stem_data.get("clips", [])
            if clips:
                audio_path = clips[0].get("audio_path", "")
                # Extract track ID from path: .../stems/2609/drums.wav -> 2609
                parts = audio_path.split("/stems/")
                if len(parts) > 1:
                    track_id = parts[1].split("/")[0]
                    stems_info[stem_name] = audio_path
                    if "track_id" not in deck_tracks.get(key, {}):
                        deck_tracks[key] = deck_tracks.get(key, {})
                        deck_tracks[key]["track_id"] = track_id

        if key in deck_tracks:
            deck_tracks[key]["bpm"] = data.get("bpm", 0)
            deck_tracks[key]["stems"] = stems_info
            deck_tracks[key]["song_name"] = data.get("song", {}).get("name", "")
            deck_tracks[key]["color_hue"] = data.get("song", {}).get("color_hue", 0.5)

    # Load stems.json for each track to get downbeat
    tracks = []
    seen_ids = set()
    for key, info in sorted(deck_tracks.items()):
        tid = info.get("track_id", "")
        if not tid or tid in seen_ids:
            continue
        seen_ids.add(tid)

        stems_json_path = stems_dir / tid / "stems.json"
        downbeat = 0
        tempo_data = {}
        if stems_json_path.exists():
            sdata = json.loads(stems_json_path.read_text())
            downbeat = 0
            if isinstance(sdata.get("tempo"), dict):
                downbeat = sdata["tempo"].get("first_downbeat_sec", 0)
                tempo_data = sdata["tempo"]

        # Map taste stem names to setforge names (vocals -> vox)
        stem_map = {}
        for taste_name, path in info.get("stems", {}).items():
            sf_name = taste_name
            if taste_name == "vocals":
                sf_name = "vox"
            stem_map[sf_name] = {"path": path, "sha": ""}

        bpm = info.get("bpm", 0)
        # Octave-fold BPM to 60-180 range
        while bpm > 180:
            bpm /= 2
        while bpm < 60:
            bpm *= 2

        tracks.append({
            "id": tid,
            "display_name": info.get("song_name", f"track_{tid}"),
            "artist": "",
            "bpm": round(bpm, 2),
            "downbeat_sec": round(downbeat, 3),
            "drift_bpm": 0,
            "grid_tightness_ms": 0,
            "octave_confidence": tempo_data.get("confidence", "unknown"),
            "varying": False,
            "energy": 0.5,
            "genre": "rock",
            "color_hue": f"#{int(info.get('color_hue', 0.5) * 360 % 360):02x}8080",
            "stems": stem_map,
            "chop_quant_override": None,
            "validated": True,
            "validated_at": "2026-05-24T00:00:00Z",
        })

    return tracks, set_assignments, deck_tracks


def build_manifest(tracks, set_name, global_tempo):
    """Build a setforge-live manifest.json."""
    return {
        "schema_version": "2.0",
        "set_id": set_name,
        "global_tempo_hint": global_tempo,
        "tracks": tracks,
    }


def build_set_json(tracks, set_name, global_tempo, set_assignments, deck_tracks):
    """Build a setforge-live set.json."""
    bank_a = [None] * 8
    bank_b = [None] * 8

    # Put set 2 tracks in bank A (they're ~136 BPM, good for chopping)
    a_idx = 0
    for key in sorted(deck_tracks.keys()):
        if key.startswith("set2_") and a_idx < 8:
            tid = deck_tracks[key].get("track_id")
            if tid:
                bank_a[a_idx] = {"track_id": tid, "scenes": []}
                a_idx += 1

    # Put set 3 tracks in bank A too
    for key in sorted(deck_tracks.keys()):
        if key.startswith("set3_") and a_idx < 8:
            tid = deck_tracks[key].get("track_id")
            if tid:
                bank_a[a_idx] = {"track_id": tid, "scenes": []}
                a_idx += 1

    # Put set 4 tracks in bank B
    b_idx = 0
    for key in sorted(deck_tracks.keys()):
        if key.startswith("set4_") and b_idx < 8:
            tid = deck_tracks[key].get("track_id")
            if tid:
                bank_b[b_idx] = {"track_id": tid, "scenes": []}
                b_idx += 1

    # Put set 5 tracks in bank B too
    for key in sorted(deck_tracks.keys()):
        if key.startswith("set5_") and b_idx < 8:
            tid = deck_tracks[key].get("track_id")
            if tid:
                bank_b[b_idx] = {"track_id": tid, "scenes": []}
                b_idx += 1

    # Setlist: all track IDs
    setlist = [t["id"] for t in tracks[:32]]

    return {
        "schema_version": "1.0",
        "name": set_name,
        "global_tempo": global_tempo,
        "preset_bank_A": bank_a,
        "preset_bank_B": bank_b,
        "setlist": setlist,
    }


def main():
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} <taste_setlist_dir> <output_dir> [--set-name NAME]")
        sys.exit(1)

    setlist_dir = sys.argv[1]
    output_dir = sys.argv[2]
    set_name = "taste_mix"

    for i, arg in enumerate(sys.argv):
        if arg == "--set-name" and i + 1 < len(sys.argv):
            set_name = sys.argv[i + 1]

    os.makedirs(output_dir, exist_ok=True)

    print(f"Converting taste data from {setlist_dir}...")
    tracks, set_assignments, deck_tracks = load_taste_data(setlist_dir)
    print(f"  Found {len(tracks)} unique tracks")

    # Use ~136 BPM as global tempo (matches sets 2-5)
    global_tempo = 136.0

    manifest = build_manifest(tracks, set_name, global_tempo)
    manifest_path = Path(output_dir) / f"{set_name}.manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2))
    print(f"  Wrote {manifest_path} ({len(tracks)} tracks)")

    set_json = build_set_json(tracks, set_name, global_tempo, set_assignments, deck_tracks)
    set_path = Path(output_dir) / f"{set_name}.set.json"
    set_path.write_text(json.dumps(set_json, indent=2))

    # Count how many slots are filled
    a_filled = sum(1 for s in set_json["preset_bank_A"] if s)
    b_filled = sum(1 for s in set_json["preset_bank_B"] if s)
    print(f"  Wrote {set_path} (bank A: {a_filled}, bank B: {b_filled}, setlist: {len(set_json['setlist'])})")

    print(f"\nTo load in setforge-loader:")
    print(f"  browse → {set_path}")


if __name__ == "__main__":
    main()
