"""verifiers — deterministic checks that encode the 20 hard-won M4L pitfalls.

Each verifier is a pure function: takes a target (patcher dict, .amxd path,
spec dict, etc.) and returns a Result. Verifiers are the layer-3 of the
code-as-harness architecture — they catch illegal actions before the
build ships, and feed structured errors back to the LLM for refinement.

Adding a verifier:
    1. Add a function below following the `verify_*` naming convention
    2. Register it in the appropriate registry (PATCHER_VERIFIERS,
       AMXD_VERIFIERS, or SPEC_VERIFIERS)
    3. Reference the pitfall # from m4l_device_development_guide.md in
       the docstring
    4. Add a test fixture under tests/dsp/test_verifiers.py
"""

from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Callable

from stemforge_bridge import amxd_pack


@dataclass
class Result:
    """A single verifier result."""
    verifier: str
    passed: bool
    pitfall: str | None = None      # e.g., "#7" — links to dev guide
    detail: str = ""
    fix_hint: str = ""
    extra: dict[str, Any] = field(default_factory=dict)


def _box_text(box: dict[str, Any]) -> str:
    body = box.get("box", {})
    return str(body.get("text", "") or body.get("maxclass", ""))


def _has_box(boxes: list[dict[str, Any]], predicate: Callable[[dict], bool]) -> bool:
    return any(predicate(b) for b in boxes)


# ── Patcher-level verifiers ──────────────────────────────────────────────────


def verify_project_field(patcher_dict: dict[str, Any]) -> Result:
    """Pitfall #6: Max prints 'fatal' if `project` field is missing or
    `project.amxdtype` is not 1633771873."""
    p = patcher_dict.get("patcher", {})
    proj = p.get("project")
    if not proj:
        return Result("project_field_present", False, "#6",
                      "patcher missing `project` field",
                      "use stemforge_bridge.patcher.empty_patcher() — it sets this")
    if proj.get("amxdtype") != 1633771873:
        return Result("project_field_present", False, "#6",
                      f"patcher.project.amxdtype = {proj.get('amxdtype')!r}, must be 1633771873",
                      "set project.amxdtype = patcher.AMXD_PROJECT_TYPE")
    return Result("project_field_present", True, "#6")


def verify_plugin_pair_canonical_shape(patcher_dict: dict[str, Any]) -> Result:
    """Pitfall #27: `[plugin~]` and `[plugout~]` boxes must match Live's
    canonical M4L template shape exactly:

      text="plugin~" / "plugout~" (NO channel-count argument),
      numinlets=2, numoutlets=2,
      outlettype=["signal", "signal"].

    Divergent shapes (e.g. text="plugin~ 2", numinlets=1) cause Max to
    delete patchcords at runtime with "plugin~: patchcord outlet out of
    range" / "plugout~: patchcord inlet out of range". The headless
    .maxpat verifier doesn't catch this — Max's loader is permissive,
    only the runtime DSP graph build is strict.
    """
    p = patcher_dict.get("patcher", {})
    boxes = p.get("boxes", [])
    issues: list[str] = []
    for b in boxes:
        bx = b.get("box", {})
        text = bx.get("text", "")
        for kind in ("plugin~", "plugout~"):
            if text == kind or text.startswith(kind + " "):
                if text != kind:
                    issues.append(f"{bx.get('id')}: text={text!r}, must be {kind!r} (no arg)")
                if bx.get("numinlets") != 2:
                    issues.append(f"{bx.get('id')}: numinlets={bx.get('numinlets')}, must be 2")
                if bx.get("numoutlets") != 2:
                    issues.append(f"{bx.get('id')}: numoutlets={bx.get('numoutlets')}, must be 2")
                if bx.get("outlettype") != ["signal", "signal"]:
                    issues.append(f"{bx.get('id')}: outlettype={bx.get('outlettype')!r}, must be ['signal','signal']")
                break
    if issues:
        return Result("plugin_pair_canonical_shape", False, "#27",
                      "; ".join(issues),
                      "use plugin_in()/plugin_out() helpers (canonical shape)")
    return Result("plugin_pair_canonical_shape", True, "#27")


def verify_inlet_outlet_indices(patcher_dict: dict[str, Any]) -> Result:
    """Pitfall #26: Subpatcher `[inlet]` / `[outlet]` boxes must carry
    explicit 0-based `index` attributes forming a contiguous {0..N-1}
    set per direction, AND `patching_rect[0]` X-coords must be
    monotonically increasing in index order.

    If indices are 1-based or sparse, Max's runtime DSP-graph build
    deletes patchcords with `patcher: patchcord [in|out]let out of range`
    even though `numinlets`/`numoutlets` and `lines[]` pass static checks.
    Headless `.maxpat` load-verifiers (pitfall #24) miss this because
    Max's loader is permissive; only the runtime DSP graph is strict.
    """
    def _check(boxes: list, kind: str) -> str | None:
        these = [b["box"] for b in boxes if b.get("box", {}).get("maxclass") == kind]
        if not these:
            return None
        indices = [b.get("index") for b in these]
        if any(idx is None or not isinstance(idx, int) for idx in indices):
            return f"{kind} box(es) missing integer `index` attribute: {indices}"
        n = len(these)
        if sorted(indices) != list(range(n)):
            return (f"{kind} indices {sorted(indices)} not contiguous {{0..{n-1}}} — "
                    f"likely 1-based or has gaps")
        sorted_by_idx = sorted(these, key=lambda b: b["index"])
        xs = [b.get("patching_rect", [0])[0] for b in sorted_by_idx]
        if xs != sorted(xs) or len(set(xs)) != len(xs):
            return (f"{kind} patching_rect[0] X-coords {xs} not strictly monotonic "
                    f"in index order — Max's spatial fallback will assign indices wrong")
        return None

    def _walk(p: dict, path: str) -> list[str]:
        errs = []
        boxes = p.get("boxes", [])
        for kind in ("inlet", "outlet"):
            err = _check(boxes, kind)
            if err:
                errs.append(f"{path}: {err}")
        for b in boxes:
            sub = b.get("box", {}).get("patcher")
            if sub:
                bid = b.get("box", {}).get("id", "?")
                errs.extend(_walk(sub, f"{path}.{bid}"))
        return errs

    root = patcher_dict.get("patcher", {})
    errs = _walk(root, "patcher")
    if errs:
        return Result("inlet_outlet_indices", False, "#26",
                      "; ".join(errs[:5]) + (f"; +{len(errs)-5} more" if len(errs) > 5 else ""),
                      "use 0-based `idx` in inlet_box/outlet_box; ensure X-coords are monotonic")
    return Result("inlet_outlet_indices", True, "#26")


def verify_project_searchpath(patcher_dict: dict[str, Any]) -> Result:
    """Pitfall #25: Live's M4L runtime calls `project_deserialize_searchpath`
    unconditionally during `.amxd` load. If `project.searchpath` is missing,
    `dictionary_getkeys_ordered` is invoked on a NULL dict and Live segfaults
    in `pthread_mutex_lock` before any patcher boxes are created.

    Max IDE loading `.maxpat` directly does NOT hit this code path, so the
    headless load-verifier can pass while Live still crashes. An empty
    `searchpath: {}` is sufficient — the field just needs to exist as a dict.
    """
    p = patcher_dict.get("patcher", {})
    proj = p.get("project") or {}
    sp = proj.get("searchpath")
    if not isinstance(sp, dict):
        return Result("project_searchpath_present", False, "#25",
                      f"patcher.project.searchpath is {type(sp).__name__}, "
                      f"must be a dict (even empty {{}})",
                      "make_patcher_skeleton emits the canonical project shape")
    return Result("project_searchpath_present", True, "#25")


def verify_plugin_pair_for_audio(patcher_dict: dict[str, Any], *,
                                 device_class: str = "audio") -> Result:
    """Pitfall #7: audio effects MUST include `[plugin~ N]` and `[plugout~ N]`
    or Ableton silently rejects the device."""
    if device_class != "audio":
        return Result("plugin_pair_required", True, "#7", "n/a (not audio class)")
    boxes = patcher_dict.get("patcher", {}).get("boxes", [])
    has_plugin = _has_box(boxes, lambda b: _box_text(b).startswith("plugin~"))
    has_plugout = _has_box(boxes, lambda b: _box_text(b).startswith("plugout~"))
    if not has_plugin:
        return Result("plugin_pair_required", False, "#7",
                      "audio device missing `plugin~` box",
                      "patcher.plugin_in() returns the correct box")
    if not has_plugout:
        return Result("plugin_pair_required", False, "#7",
                      "audio device missing `plugout~` box",
                      "patcher.plugin_out() returns the correct box")
    return Result("plugin_pair_required", True, "#7")


def verify_no_node_script(patcher_dict: dict[str, Any]) -> Result:
    """Pitfall #1: `node.script` is broken on macOS 26+ when launched from
    Live (Team ID mismatch under hardened runtime). Use `[shell]` + `[js]`."""
    boxes = patcher_dict.get("patcher", {}).get("boxes", [])
    bad = [b for b in boxes if "node.script" in _box_text(b)]
    if bad:
        return Result("no_node_script", False, "#1",
                      f"found {len(bad)} `node.script` box(es) — broken on macOS 26+",
                      "replace with `[shell]` + `[js]` pair (see stemforge_bridge.patcher)")
    return Result("no_node_script", True, "#1")


def verify_no_static_comment_for_dynamic(patcher_dict: dict[str, Any]) -> Result:
    """Pitfall #3: `[comment]` ignores `set` messages. For text that updates
    at runtime, use `[live.comment]`. We can't detect intent, but we can
    flag suspicious `[comment]` boxes that are wired to a message source."""
    boxes = patcher_dict.get("patcher", {}).get("boxes", [])
    lines = patcher_dict.get("patcher", {}).get("lines", [])
    comment_ids = {b["box"]["id"] for b in boxes
                   if b.get("box", {}).get("maxclass") == "comment"}
    wired_comment_ids = set()
    for ln in lines:
        dst = ln.get("patchline", {}).get("destination", [None])
        if dst[0] in comment_ids:
            wired_comment_ids.add(dst[0])
    if wired_comment_ids:
        return Result(
            "no_static_comment_for_dynamic", False, "#3",
            f"`[comment]` boxes receiving messages: {sorted(wired_comment_ids)}",
            "swap [comment] → [live.comment] (patcher.live_comment helper)",
        )
    return Result("no_static_comment_for_dynamic", True, "#3")


def verify_live_dial_param_attrs(patcher_dict: dict[str, Any]) -> Result:
    """Pitfall #18: `[live.dial]` without full `saved_attribute_attributes`
    silently fails to expose the param to Live automation."""
    boxes = patcher_dict.get("patcher", {}).get("boxes", [])
    bad = []
    for b in boxes:
        body = b.get("box", {})
        if body.get("maxclass") == "live.dial":
            saa = body.get("saved_attribute_attributes", {})
            valueof = saa.get("valueof", {})
            required = ["parameter_longname", "parameter_mmin", "parameter_mmax"]
            missing = [k for k in required if k not in valueof]
            if missing:
                bad.append((body.get("id"), missing))
    if bad:
        return Result(
            "live_dial_param_attrs", False, "#18",
            f"{len(bad)} live.dial box(es) missing required param attrs: {bad[:3]}",
            "use patcher.live_dial(...) — it sets the full saved_attribute_attributes",
        )
    return Result("live_dial_param_attrs", True, "#18")


def verify_umenu_items_format(patcher_dict: dict[str, Any]) -> Result:
    """Pitfall #5: `[umenu]` items must be space-separated. Comma-separated
    items become one big merged item silently."""
    boxes = patcher_dict.get("patcher", {}).get("boxes", [])
    bad = []
    for b in boxes:
        body = b.get("box", {})
        if body.get("maxclass") == "umenu":
            items = body.get("items") or body.get("@items")
            if isinstance(items, str) and "," in items:
                bad.append(body.get("id"))
    if bad:
        return Result(
            "umenu_items_space_separated", False, "#5",
            f"{len(bad)} umenu box(es) have comma-separated items: {bad}",
            "switch separator: 'a,b,c' → 'a b c'",
        )
    return Result("umenu_items_space_separated", True, "#5")


# ── .amxd container verifiers ────────────────────────────────────────────────


def verify_amxd_magic(amxd_path: str | Path) -> Result:
    """Pitfall #14: container header sentinel determines device class.
    `b'aaaa'` for audio, `b'mmmm'` for midi, `b'iiii'` for instrument.
    Wrong sentinel → Ableton rejects."""
    raw = Path(amxd_path).read_bytes()
    if raw[:4] != b"ampf":
        return Result("amxd_magic", False, "#14",
                      f"missing 'ampf' magic at offset 0: {raw[:4]!r}", "")
    sentinel = raw[8:12]
    if sentinel not in (b"aaaa", b"mmmm", b"iiii"):
        return Result("amxd_magic", False, "#14",
                      f"unknown class sentinel at offset 8: {sentinel!r}",
                      "use amxd_pack.pack_amxd(..., device_class='audio'|'midi'|'instrument')")
    return Result("amxd_magic", True, "#14",
                  detail=f"sentinel={sentinel.decode()}")


def verify_amxd_round_trip(amxd_path: str | Path) -> Result:
    """The .amxd binary unpacks back to a valid patcher dict."""
    try:
        result = amxd_pack.unpack_amxd(amxd_path)
        if "patcher" not in result.get("patcher", {}):
            return Result("amxd_round_trip", False, None,
                          "unpacked .amxd lacks 'patcher' key", "")
        return Result("amxd_round_trip", True, None,
                      f"unpacked OK; device_type={result['device_type']}")
    except Exception as e:
        return Result("amxd_round_trip", False, None,
                      f"unpack failed: {e}",
                      "regenerate via amxd_pack.pack_amxd")


# ── Spec-level verifiers (pedal.yaml) ────────────────────────────────────────


def verify_spec_required_fields(spec: dict[str, Any]) -> Result:
    """Spec must have device, parameters, signal_chain, modules, manual_steps."""
    required = ["device", "parameters", "signal_chain", "modules"]
    missing = [k for k in required if k not in spec]
    if missing:
        return Result("spec_required_fields", False, None,
                      f"missing top-level keys: {missing}",
                      "see specs/templates/pedal.schema.yaml")
    return Result("spec_required_fields", True, None)


def verify_signal_chain_modules_exist(spec: dict[str, Any]) -> Result:
    """Every name in signal_chain must have a corresponding `modules` entry."""
    chain = spec.get("signal_chain", [])
    modules = spec.get("modules", {})
    missing = [name for name in chain if name not in modules]
    if missing:
        return Result("signal_chain_modules_exist", False, None,
                      f"signal_chain references undefined modules: {missing}",
                      "add a modules.<name> entry per signal_chain item")
    return Result("signal_chain_modules_exist", True, None)


def verify_param_refs_resolve(spec: dict[str, Any]) -> Result:
    """Every modules.<m>.references_params name must be a defined parameter."""
    param_names = {p["name"] for p in spec.get("parameters", [])}
    issues = []
    for mname, mod in (spec.get("modules") or {}).items():
        for pname in (mod.get("references_params") or []):
            if pname not in param_names:
                issues.append((mname, pname))
    if issues:
        return Result("param_refs_resolve", False, None,
                      f"undefined param refs: {issues}",
                      "fix typo OR add missing entry to spec.parameters")
    return Result("param_refs_resolve", True, None)


# ── Registries ───────────────────────────────────────────────────────────────


PATCHER_VERIFIERS: list[Callable[[dict[str, Any]], Result]] = [
    verify_project_field,
    verify_project_searchpath,
    verify_inlet_outlet_indices,
    verify_plugin_pair_for_audio,
    verify_plugin_pair_canonical_shape,
    verify_no_node_script,
    verify_no_static_comment_for_dynamic,
    verify_live_dial_param_attrs,
    verify_umenu_items_format,
]

AMXD_VERIFIERS: list[Callable[[str | Path], Result]] = [
    verify_amxd_magic,
    verify_amxd_round_trip,
]

SPEC_VERIFIERS: list[Callable[[dict[str, Any]], Result]] = [
    verify_spec_required_fields,
    verify_signal_chain_modules_exist,
    verify_param_refs_resolve,
]


def run_all(target: Any, *, kind: str) -> list[Result]:
    """Run all verifiers for `kind`. Returns list of Results (pass + fail).

    The `load` kind invokes runtime load verifiers (pitfall #24) which
    require a real Max install. They live in `forge_device.load_verifier`
    and are imported lazily so `run_all(..., kind="patcher")` doesn't drag
    in `subprocess`/`platform` machinery on cold paths.
    """
    if kind == "patcher":
        return [v(target) for v in PATCHER_VERIFIERS]
    if kind == "amxd":
        return [v(target) for v in AMXD_VERIFIERS]
    if kind == "spec":
        return [v(target) for v in SPEC_VERIFIERS]
    if kind == "load":
        from forge_device.load_verifier import LOAD_VERIFIERS
        return [v(target) for v in LOAD_VERIFIERS]
    raise ValueError(f"unknown verifier kind: {kind}")
