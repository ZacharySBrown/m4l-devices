"""patcher — generic primitives for constructing Max for Live patcher JSON.

Extracted and cleaned from StemForge `v0/src/maxpat-builder/builder.py`. The
StemForge builder contains a lot of device-specific orchestration (v8ui canvas,
sf_state event routing); this module exposes only the primitives you need to
build any M4L device programmatically.

Pitfalls codified here (numbers reference the M4L Device Development Guide):
    #3   live.comment for dynamic text (not [comment])
    #5   [umenu] items space-separated, not comma-separated
    #6   patcher must include `project` field with amxdtype 1633771873
    #25  project block must include `searchpath: {}` or Live segfaults on .amxd load
    #7   [plugin~] / [plugout~] mandatory for audio effects
    #27  plugin~/plugout~ shape: text="plugin~" (no arg), numinlets=2, numoutlets=2
    #14  device_class='audio' → b'aaaa' sentinel (see amxd_pack.py)
    #17  [textbutton] outlet sends label text — chain through [t b] for bang
    #18  [live.dial] / [live.slider] need full saved_attribute_attributes

Use with amxd_pack.pack_amxd() to produce the final .amxd binary.
"""

from __future__ import annotations

from typing import Any

# The amxdtype magic value Max insists on inside the project field — without
# it, Max prints "fatal" on load. (Pitfall #6.)
AMXD_PROJECT_TYPE = 1633771873


# ── Primitive box / patchline helpers ────────────────────────────────────────


def box(
    obj_id: str,
    maxclass: str,
    rect: tuple[float, float, float, float],
    *,
    presentation: bool = False,
    presentation_rect: tuple[float, float, float, float] | None = None,
    numinlets: int = 1,
    numoutlets: int = 0,
    outlettype: list[str] | None = None,
    extras: dict[str, Any] | None = None,
) -> dict[str, Any]:
    """A single Max box (UI or logic). Returns a dict ready to append to boxes[]."""
    body: dict[str, Any] = {
        "id": obj_id,
        "maxclass": maxclass,
        "numinlets": numinlets,
        "numoutlets": numoutlets,
        "patching_rect": list(rect),
    }
    if outlettype is not None:
        body["outlettype"] = outlettype
    if presentation:
        body["presentation"] = 1
        body["presentation_rect"] = list(presentation_rect or rect)
    if extras:
        body.update(extras)
    return {"box": body}


def line(src_id: str, src_outlet: int, dst_id: str, dst_inlet: int) -> dict[str, Any]:
    """A patchline connecting src outlet → dst inlet."""
    return {
        "patchline": {
            "source": [src_id, src_outlet],
            "destination": [dst_id, dst_inlet],
        }
    }


def js_box(
    obj_id: str,
    filename: str,
    rect: tuple[float, float, float, float],
    *,
    scripting_name: str | None = None,
    numinlets: int = 1,
    numoutlets: int = 1,
    outlettype: list[str] | None = None,
) -> dict[str, Any]:
    """Classic [js] object (SpiderMonkey). Use this — NOT [node.script]
    (pitfall #1: node.script is broken on macOS 26+ when launched by Live)."""
    text = f"js {filename}"
    if scripting_name:
        text += f" @scripting_name {scripting_name}"
    if outlettype is None:
        outlettype = [""] * numoutlets
    return box(
        obj_id,
        "newobj",
        rect,
        numinlets=numinlets,
        numoutlets=numoutlets,
        outlettype=outlettype,
        extras={
            "text": text,
            "saved_object_attributes": {
                "filename": filename,
                "parameter_enable": 0,
            },
        },
    )


# ── Live UI element helpers (presentation-mode UI) ───────────────────────────


def live_dial(
    obj_id: str,
    rect: tuple[float, float, float, float],
    *,
    parameter_name: str,
    short_name: str | None = None,
    minimum: float = 0.0,
    maximum: float = 1.0,
    initial: float = 0.0,
    unit_style: int = 0,  # 0=int, 1=float, 2=hz, etc.
    presentation_rect: tuple[float, float, float, float] | None = None,
    extras: dict[str, Any] | None = None,
) -> dict[str, Any]:
    """[live.dial] knob with full parameter contract (pitfall #18: must include
    saved_attribute_attributes for automation to work)."""
    body_extras = {
        "varname": parameter_name,
        "saved_attribute_attributes": {
            "valueof": {
                "parameter_initial": [initial],
                "parameter_initial_enable": 1,
                "parameter_longname": parameter_name,
                "parameter_mmax": float(maximum),
                "parameter_mmin": float(minimum),
                "parameter_shortname": short_name or parameter_name,
                "parameter_type": 0,  # 0 = float, 1 = int, 2 = enum
                "parameter_unitstyle": unit_style,
            }
        },
    }
    if extras:
        body_extras.update(extras)
    return box(
        obj_id,
        "live.dial",
        rect,
        presentation=True,
        presentation_rect=presentation_rect,
        numinlets=1,
        numoutlets=2,  # value out + automation
        outlettype=["", "float"],
        extras=body_extras,
    )


def live_tab(
    obj_id: str,
    rect: tuple[float, float, float, float],
    *,
    parameter_name: str,
    items: list[str],
    initial: int = 0,
    presentation_rect: tuple[float, float, float, float] | None = None,
) -> dict[str, Any]:
    """[live.tab] segmented selector. Items are space-separated in Max
    convention (pitfall #5)."""
    return box(
        obj_id,
        "live.tab",
        rect,
        presentation=True,
        presentation_rect=presentation_rect,
        numinlets=1,
        numoutlets=2,
        outlettype=["", ""],
        extras={
            "varname": parameter_name,
            "saved_attribute_attributes": {
                "valueof": {
                    "parameter_enum": items,
                    "parameter_initial": [initial],
                    "parameter_initial_enable": 1,
                    "parameter_longname": parameter_name,
                    "parameter_shortname": parameter_name,
                    "parameter_type": 2,  # enum
                }
            },
        },
    )


def live_toggle(
    obj_id: str,
    rect: tuple[float, float, float, float],
    *,
    parameter_name: str,
    initial: int = 0,
    presentation_rect: tuple[float, float, float, float] | None = None,
) -> dict[str, Any]:
    """[live.toggle] checkbox. Use for dip-switch equivalents."""
    return box(
        obj_id,
        "live.toggle",
        rect,
        presentation=True,
        presentation_rect=presentation_rect,
        numinlets=1,
        numoutlets=1,
        outlettype=[""],
        extras={
            "varname": parameter_name,
            "saved_attribute_attributes": {
                "valueof": {
                    "parameter_initial": [initial],
                    "parameter_initial_enable": 1,
                    "parameter_longname": parameter_name,
                    "parameter_shortname": parameter_name,
                    "parameter_type": 1,  # int
                }
            },
        },
    )


def live_comment(
    obj_id: str,
    rect: tuple[float, float, float, float],
    *,
    text: str,
    presentation_rect: tuple[float, float, float, float] | None = None,
    fontsize: float = 11.0,
) -> dict[str, Any]:
    """[live.comment] for dynamic text labels. Do NOT use [comment] — it
    ignores `set` messages (pitfall #3)."""
    return box(
        obj_id,
        "live.comment",
        rect,
        presentation=True,
        presentation_rect=presentation_rect,
        numinlets=1,
        numoutlets=0,
        extras={"text": text, "fontsize": fontsize},
    )


def plugin_in(obj_id: str = "obj-plugin-in", *, channels: int = 2,
              rect: tuple[float, float, float, float] = (20, 20, 80, 22)) -> dict[str, Any]:
    """[plugin~] — mandatory for audio effects (pitfall #7).

    Pitfall #27: must match Live's canonical shape exactly:
      text="plugin~" (no channel-count arg),
      numinlets=2, numoutlets=2,
      outlettype=["signal","signal"].
    `channels` is currently ignored (M4L is hard-stereo); kept for API
    compatibility. Mismatched declarations (e.g. numinlets=1 with
    text="plugin~ 2") cause Max to delete patchcords with
    "plugin~: patchcord outlet out of range" at runtime.
    """
    return box(
        obj_id, "newobj", rect,
        numinlets=2, numoutlets=2,
        outlettype=["signal", "signal"],
        extras={"text": "plugin~"},
    )


def plugin_out(obj_id: str = "obj-plugout", *, channels: int = 2,
               rect: tuple[float, float, float, float] = (20, 400, 80, 22)) -> dict[str, Any]:
    """[plugout~] — mandatory for audio effects (pitfall #7).

    Pitfall #27: same canonical shape as `plugin~` —
      text="plugout~" (no arg), numinlets=2, numoutlets=2,
      outlettype=["signal","signal"]. (Yes, plugout~ has outlets too in
      the canonical M4L template; matching the reference is what matters.)
    """
    return box(
        obj_id, "newobj", rect,
        numinlets=2, numoutlets=2,
        outlettype=["signal", "signal"],
        extras={"text": "plugout~"},
    )


# ── Patcher envelope ─────────────────────────────────────────────────────────


def empty_patcher(
    *,
    width: int = 600,
    height: int = 220,
    presentation_size: tuple[int, int] | None = None,
    is_root: bool = True,
) -> dict[str, Any]:
    """Skeleton patcher dict with all the schema fields Max insists on.

    Returns a dict with empty boxes/lines lists ready for you to append.
    Root patchers (the device's outer patcher, the debug harness patcher)
    include the canonical `project` field with `amxdtype = 1633771873`
    and `searchpath = {}` (pitfalls #6 and #25). Subpatchers should pass
    `is_root=False` — Live's reference M4L template does NOT emit project
    blocks on subpatchers, and emitting one with empty `name` produces a
    "device patcher has no name!" warning per nested patcher.
    """
    if presentation_size is None:
        presentation_size = (width, height)
    p: dict[str, Any] = {
        "patcher": {
            "fileversion": 1,
            "appversion": {
                "major": 9, "minor": 0, "revision": 0,
                "architecture": "x64", "modernui": 1,
            },
            "classnamespace": "box",
            "rect": [100.0, 100.0, 100.0 + width, 100.0 + height],
            "openinpresentation": 1,
            "default_fontsize": 12.0,
            "default_fontface": 0,
            "default_fontname": "Arial",
            "gridonopen": 1,
            "gridsize": [15.0, 15.0],
            "gridsnaponopen": 1,
            "objectsnaponopen": 1,
            "statusbarvisible": 2,
            "toolbarvisible": 1,
            "lefttoolbarpinned": 0,
            "toptoolbarpinned": 0,
            "righttoolbarpinned": 0,
            "bottomtoolbarpinned": 0,
            "toolbars_unpinned_last_save": 0,
            "tallnewobj": 0,
            "boxanimatetime": 200,
            "enablehscroll": 1,
            "enablevscroll": 1,
            "devicewidth": float(presentation_size[0]),
            "description": "",
            "digest": "",
            "tags": "",
            "style": "",
            "subpatcher_template": "",
            "assistshowspatchername": 0,
            "boxes": [],
            "lines": [],
            "project": {
                "version": 1,
                "creationdate": 0,
                "modificationdate": 0,
                "viewrect": [0.0, 0.0, 300.0, 500.0],
                "autoorganize": 1,
                "hideprojectwindow": 1,
                "showdependencies": 1,
                "autolocalize": 0,
                "contents": {"patchers": {}},
                "layout": {},
                "searchpath": {},
                "detailsvisible": 0,
                "amxdtype": AMXD_PROJECT_TYPE,
                "readonly": 0,
                "devpathtype": 0,
                "devpath": ".",
                "sortmode": 0,
                "viewmode": 0,
            },
            "dependency_cache": [],
            "autosave": 0,
        }
    }
    if not is_root:
        del p["patcher"]["project"]
    return p


# ── Subpatcher / inlet / outlet / generic newobj / comment helpers ───────────


def newobj(
    obj_id: str,
    text: str,
    rect: tuple[float, float, float, float],
    *,
    numinlets: int = 1,
    numoutlets: int = 1,
    outlettype: list[str] | None = None,
    extras: dict[str, Any] | None = None,
) -> dict[str, Any]:
    """Generic [newobj] with the supplied object-text. Use this for Max
    objects that the bridge does not have a dedicated helper for (e.g.
    `biquad~`, `tapin~ 100`, `selector~ 2`, `expr ...`)."""
    if outlettype is None:
        outlettype = [""] * numoutlets
    body_extras: dict[str, Any] = {"text": text}
    if extras:
        body_extras.update(extras)
    return box(
        obj_id, "newobj", rect,
        numinlets=numinlets, numoutlets=numoutlets,
        outlettype=outlettype, extras=body_extras,
    )


def inlet_box(
    obj_id: str,
    idx: int,
    rect: tuple[float, float, float, float],
    *,
    signal: bool = True,
) -> dict[str, Any]:
    """[inlet] / [inlet~] for a subpatcher. `idx` is the 0-based port number
    Max uses on the parent subpatcher box (matches `lines[]` references).

    Pitfall #26: Max needs `index` AND a monotonically increasing
    `patching_rect[0]` X-coord matching the index order. Off-by-one or
    1-based indices here produce `patcher: patchcord inlet out of range`
    errors at runtime even though static analysis looks clean.

    Inlets/outlets are NOT instantiated via [newobj] with text "inlet~" —
    Max uses dedicated maxclass values "inlet" / "outlet" with no text.
    Signal vs control is determined by outlettype (["signal"] vs ["bang"]
    / [""])."""
    return box(
        obj_id, "inlet", rect,
        numinlets=0, numoutlets=1,
        outlettype=["signal" if signal else ""],
        extras={"comment": "", "index": idx},
    )


def outlet_box(
    obj_id: str,
    idx: int,
    rect: tuple[float, float, float, float],
    *,
    signal: bool = True,
) -> dict[str, Any]:
    """[outlet] / [outlet~] for a subpatcher. `idx` is the 0-based port number
    Max uses on the parent subpatcher box (matches `lines[]` references).

    See `inlet_box` for the indexing convention (pitfall #26).

    Outlets have no outlettype field at all (they emit nothing themselves —
    they receive at their inlet and forward to the parent box's outlet).
    Signal vs control is inferred at runtime from what's connected."""
    return box(
        obj_id, "outlet", rect,
        numinlets=1, numoutlets=0,
        outlettype=None,
        extras={"comment": "", "index": idx},
    )


def comment_box(
    obj_id: str,
    text: str,
    rect: tuple[float, float, float, float],
) -> dict[str, Any]:
    """Static [comment] box. NOT for dynamic text — use live_comment()
    if the contents change at runtime (pitfall #3)."""
    return box(
        obj_id, "comment", rect,
        numinlets=1, numoutlets=0,
        extras={"text": text},
    )


def subpatcher_box(
    obj_id: str,
    name: str,
    rect: tuple[float, float, float, float],
    inner_patcher: dict[str, Any],
    *,
    numinlets: int,
    numoutlets: int,
    outlettype: list[str] | None = None,
    extras: dict[str, Any] | None = None,
) -> dict[str, Any]:
    """A `[p name]` subpatcher box with an embedded patcher dict.

    Max stores embedded subpatchers as a `newobj` whose text is `p <name>`
    plus a `patcher` field on the box body holding the inner patcher.
    `inner_patcher` may be either the {"patcher": {...}} envelope returned
    by empty_patcher() or the inner patcher dict itself.
    """
    if outlettype is None:
        outlettype = ["signal" if i == 0 else "" for i in range(numoutlets)]
    inner = inner_patcher.get("patcher", inner_patcher) if isinstance(inner_patcher, dict) else inner_patcher
    body_extras: dict[str, Any] = {
        "text": f"p {name}",
        "patcher": inner,
        "saved_object_attributes": {
            "description": "",
            "digest": "",
            "globalpatchername": "",
        },
    }
    if extras:
        body_extras.update(extras)
    return box(
        obj_id, "newobj", rect,
        numinlets=numinlets, numoutlets=numoutlets,
        outlettype=outlettype, extras=body_extras,
    )


# ── gen~ codebox helper ──────────────────────────────────────────────────────


def gen_codebox(
    *,
    title: str,
    code: str,
    numinlets: int,
    numoutlets: int,
    outlettype: list[str] | None = None,
    inlettype: list[str] | None = None,
    patching_rect: tuple[float, float, float, float] = (100.0, 100.0, 200.0, 50.0),
    extra_args: str = "",
    box_id: str | None = None,
) -> dict[str, Any]:
    """Emit the patcher JSON for an embedded [gen~] codebox containing
    `code` as its DSL source. Returns the box dict callers can append to
    a patcher's `boxes` array.

    The result is structurally a `newobj` with text=`gen~ @title <title>`
    whose body carries an embedded sub-patcher containing a single
    `[codebox]` object. Max JIT-compiles the codebox text on patcher load.

    Args:
        title:         gen~ @title argument (e.g. "tl_saturate_dsp").
        code:          gen DSL source as a string. May contain newlines.
        numinlets:     number of signal inlets on the gen~ box.
        numoutlets:    number of signal outlets on the gen~ box.
        outlettype:    per-outlet type list (default: ["signal"] * numoutlets).
        inlettype:     per-inlet type list. Currently informational; gen~
                       infers signal inlets when omitted.
        patching_rect: (x, y, w, h) for the gen~ box on the parent patcher.
        extra_args:    appended verbatim to the gen~ text after the title
                       (e.g. " @expr 'foo'"). Caller is responsible for
                       any leading space.
        box_id:        explicit box id; auto-generated from `title` if None.

    The function is pure: no I/O, no side effects, returns a fresh dict.
    """
    if outlettype is None:
        outlettype = ["signal"] * numoutlets
    if box_id is None:
        box_id = f"obj-gen-{title}"

    text = f"gen~ @title {title}"
    if extra_args:
        # Allow caller to pass either " @foo bar" or "@foo bar".
        text += extra_args if extra_args.startswith(" ") else " " + extra_args

    # Inner codebox sub-patcher. The codebox itself mirrors the gen~ box's
    # inlet/outlet counts so Max can wire its compiled inputs/outputs.
    #
    # CRITICAL: gen~ derives its actual inlet/outlet count from `in N` and
    # `out N` operator boxes inside the inner patcher — NOT from the outer
    # newobj's numinlets/numoutlets attributes (which are descriptive only).
    # If the operator boxes are missing, gen~ falls back to 1-in/1-out and
    # Max prunes any patchcord targeting a higher index. Each `out N` also
    # needs a patchcord from the codebox's corresponding outlet, since
    # `outN = expr` assignments compile to signal flow that needs a
    # destination. `in N` → codebox patchcords are optional (the bindings
    # resolve by name) but we emit them too for visual clarity.
    #
    # Codebox specifics (verified against Cycling74/ease's
    # ease.gen.codebox_example.maxpat):
    #   - DSL source goes in the `code` field, NOT `text`. The `text` field
    #     is reserved for Max object instantiation args; codebox uses
    #     `code` for its DSL body. Writing DSL to `text` causes the codebox
    #     to compile empty, which propagates up: gen~ sees no inN/outN
    #     references in the codebox and exposes only 1in/1out at runtime.
    #   - Codebox `outlettype` is `[""]` (control-typed), not `["signal"]`.
    #     Signal-rate determination happens at the outer gen~ box and the
    #     `out N` operator boxes; the codebox sits inside that flow as a
    #     control-rate node.
    codebox_outlettype = [""] * numoutlets
    codebox_id = f"{box_id}-codebox"
    inner_boxes: list[dict[str, Any]] = []
    inner_lines: list[dict[str, Any]] = []

    # in N operator boxes (left column)
    for i in range(1, numinlets + 1):
        in_id = f"{box_id}-in{i}"
        inner_boxes.append({
            "box": {
                "id": in_id,
                "maxclass": "newobj",
                "text": f"in {i}",
                "numinlets": 0,
                "numoutlets": 1,
                "outlettype": [""],
                "patching_rect": [30.0 + 70.0 * (i - 1), 30.0, 30.0, 22.0],
            }
        })
        # in N → codebox inlet (i-1)
        inner_lines.append({
            "patchline": {
                "source": [in_id, 0],
                "destination": [codebox_id, i - 1],
            }
        })

    # codebox itself — DSL goes in `code`, not `text` (Max-specific quirk
    # for the `codebox` maxclass; verified against Cycling74-saved files).
    inner_boxes.append({
        "box": {
            "id": codebox_id,
            "maxclass": "codebox",
            "numinlets": numinlets,
            "numoutlets": numoutlets,
            "outlettype": codebox_outlettype,
            "patching_rect": [50.0, 100.0, 600.0, 400.0],
            "code": code,
        }
    })

    # out N operator boxes (bottom row)
    for i in range(1, numoutlets + 1):
        out_id = f"{box_id}-out{i}"
        inner_boxes.append({
            "box": {
                "id": out_id,
                "maxclass": "newobj",
                "text": f"out {i}",
                "numinlets": 1,
                "numoutlets": 0,
                "patching_rect": [30.0 + 70.0 * (i - 1), 540.0, 35.0, 22.0],
            }
        })
        # codebox outlet (i-1) → out N
        inner_lines.append({
            "patchline": {
                "source": [codebox_id, i - 1],
                "destination": [out_id, 0],
            }
        })

    inner_patcher = {
        "fileversion": 1,
        "appversion": {
            "major": 9, "minor": 0, "revision": 0,
            "architecture": "x64", "modernui": 1,
        },
        "classnamespace": "dsp.gen",
        "rect": [100.0, 100.0, 700.0, 600.0],
        "boxes": inner_boxes,
        "lines": inner_lines,
    }

    extras: dict[str, Any] = {
        "text": text,
        "patcher": inner_patcher,
        "rnboattrcache": {},
        "saved_object_attributes": {
            "exportfolder": "",
            "exportname": title,
            "wantsoutputcore": 0,
        },
    }
    # `inlettype` is not part of the documented gen~ box schema, but if a
    # caller passes one we stash it as an extra for forward-compat.
    if inlettype is not None:
        extras["inlettype"] = list(inlettype)

    return box(
        box_id, "newobj", tuple(patching_rect),
        numinlets=numinlets, numoutlets=numoutlets,
        outlettype=outlettype, extras=extras,
    )


def build_minimal_audio_effect(
    name: str,
    *,
    width: int = 600,
    height: int = 220,
) -> dict[str, Any]:
    """Smallest legal M4L audio effect: plugin~ → plugout~, presentation-empty.

    Used by Phase 0 round-trip verification to confirm the build pipeline
    works before any real DSP is wired.
    """
    p = empty_patcher(width=width, height=height)
    boxes = p["patcher"]["boxes"]
    lines = p["patcher"]["lines"]

    boxes.append(plugin_in("obj-plugin-in"))
    boxes.append(plugin_out("obj-plugout"))
    # plugin~ stereo → plugout~ stereo, both channels
    lines.append(line("obj-plugin-in", 0, "obj-plugout", 0))
    lines.append(line("obj-plugin-in", 1, "obj-plugout", 1))
    p["patcher"]["project"]["name"] = name
    return p


# ── Self-tests (run via `python -m stemforge_bridge.patcher`) ────────────────


def _run_self_tests() -> int:
    """Smoke tests for the bridge primitives. Returns process exit code."""
    import json as _json

    failures: list[str] = []

    def check(cond: bool, msg: str) -> None:
        if not cond:
            failures.append(msg)

    # ── gen_codebox ─────────────────────────────────────────────────────

    # 1) Round-trip: serializes cleanly, deserializes equivalent, codebox
    #    text matches the input.
    src = "In1=in 1; Out1=In1*2;"
    g = gen_codebox(title="test_dsp", code=src, numinlets=1, numoutlets=1)
    payload = _json.dumps(g)
    g2 = _json.loads(payload)
    check(g == g2, "gen_codebox: JSON round-trip not equal")
    inner_boxes = g2["box"]["patcher"]["boxes"]
    # Inner patcher has: N `in N` boxes + 1 codebox + M `out N` boxes
    expected_inner_count = 1 + 1 + 1  # 1 in, 1 codebox, 1 out for default test src
    check(len(inner_boxes) == expected_inner_count,
          f"gen_codebox: expected {expected_inner_count} inner boxes, got {len(inner_boxes)}")
    # Find the codebox specifically
    cb_box = next((b["box"] for b in inner_boxes if b["box"].get("maxclass") == "codebox"), None)
    check(cb_box is not None, "gen_codebox: codebox not found in inner_boxes")
    check(cb_box["code"] == src,
          f"gen_codebox: codebox code {cb_box['code']!r} != input {src!r}")
    check("text" not in cb_box,
          "gen_codebox: codebox must not have 'text' field (DSL goes in 'code')")
    check(cb_box["outlettype"] == [""],
          f"gen_codebox: codebox outlettype must be [''] (control), got {cb_box['outlettype']!r}")
    check(g2["box"]["text"] == "gen~ @title test_dsp",
          f"gen_codebox: outer text {g2['box']['text']!r}")
    # Verify in/out operator boxes were emitted with correct text
    in_boxes = [b["box"] for b in inner_boxes
                if b["box"].get("text", "").startswith("in ")]
    out_boxes = [b["box"] for b in inner_boxes
                 if b["box"].get("text", "").startswith("out ")]
    check(len(in_boxes) == 1, f"gen_codebox: expected 1 'in N' box, got {len(in_boxes)}")
    check(len(out_boxes) == 1, f"gen_codebox: expected 1 'out N' box, got {len(out_boxes)}")
    check(in_boxes[0]["text"] == "in 1", f"gen_codebox: in box text {in_boxes[0]['text']!r}")
    check(out_boxes[0]["text"] == "out 1", f"gen_codebox: out box text {out_boxes[0]['text']!r}")
    # Verify lines wire codebox → out 1 (and in 1 → codebox)
    inner_lines = g2["box"]["patcher"]["lines"]
    check(len(inner_lines) == 2, f"gen_codebox: expected 2 inner lines, got {len(inner_lines)}")

    # 2) outlettype defaults to ["signal"] * numoutlets when None
    g3 = gen_codebox(title="t", code="x;", numinlets=1, numoutlets=2)
    check(g3["box"]["outlettype"] == ["signal", "signal"],
          f"gen_codebox: default outlettype was {g3['box']['outlettype']!r}")

    # 3) Multiple outlets: numoutlets=3 → 3 outlettype entries on outer
    #    AND on inner codebox + 3 `out N` operator boxes.
    g4 = gen_codebox(title="t3", code="x;", numinlets=2, numoutlets=3)
    check(g4["box"]["numoutlets"] == 3, "gen_codebox: outer numoutlets")
    check(len(g4["box"]["outlettype"]) == 3,
          f"gen_codebox: outer outlettype len {len(g4['box']['outlettype'])}")
    g4_inner = g4["box"]["patcher"]["boxes"]
    g4_cb = next(b["box"] for b in g4_inner if b["box"].get("maxclass") == "codebox")
    check(g4_cb["numoutlets"] == 3,
          f"gen_codebox: inner codebox numoutlets {g4_cb['numoutlets']}")
    check(len(g4_cb["outlettype"]) == 3,
          f"gen_codebox: inner codebox outlettype len {len(g4_cb['outlettype'])}")
    check(g4_cb["numinlets"] == 2,
          f"gen_codebox: inner codebox numinlets {g4_cb['numinlets']}")
    g4_in_boxes = [b["box"] for b in g4_inner if b["box"].get("text","").startswith("in ")]
    g4_out_boxes = [b["box"] for b in g4_inner if b["box"].get("text","").startswith("out ")]
    check(len(g4_in_boxes) == 2, f"gen_codebox: 2 in boxes for numinlets=2, got {len(g4_in_boxes)}")
    check(len(g4_out_boxes) == 3, f"gen_codebox: 3 out boxes for numoutlets=3, got {len(g4_out_boxes)}")
    check([b["text"] for b in g4_in_boxes] == ["in 1", "in 2"],
          f"gen_codebox: in box texts {[b['text'] for b in g4_in_boxes]}")
    check([b["text"] for b in g4_out_boxes] == ["out 1", "out 2", "out 3"],
          f"gen_codebox: out box texts {[b['text'] for b in g4_out_boxes]}")

    # 4) Multi-line gen DSL: \n round-trips correctly (no escape mangling).
    multiline = "Param freq(440, min=20, max=20000);\nphase = phasor(freq);\nOut1 = cycle(phase);"
    g5 = gen_codebox(title="ml", code=multiline, numinlets=0, numoutlets=1)
    g5_rt = _json.loads(_json.dumps(g5))
    g5_cb = next(b["box"] for b in g5_rt["box"]["patcher"]["boxes"]
                 if b["box"].get("maxclass") == "codebox")
    rt_text = g5_cb["code"]
    check(rt_text == multiline,
          f"gen_codebox: multiline round-trip mismatch:\n  got: {rt_text!r}\n  expected: {multiline!r}")
    check("\n" in rt_text, "gen_codebox: newline lost in round-trip")

    # 5) Custom outlettype is respected
    g6 = gen_codebox(title="t6", code="x;", numinlets=1, numoutlets=2,
                     outlettype=["signal", ""])
    check(g6["box"]["outlettype"] == ["signal", ""],
          f"gen_codebox: custom outlettype {g6['box']['outlettype']!r}")

    # 6) extra_args appended (with and without leading space)
    g7 = gen_codebox(title="t7", code="x;", numinlets=1, numoutlets=1,
                     extra_args="@expr 'foo'")
    check(g7["box"]["text"] == "gen~ @title t7 @expr 'foo'",
          f"gen_codebox: extra_args text {g7['box']['text']!r}")
    g7b = gen_codebox(title="t7", code="x;", numinlets=1, numoutlets=1,
                      extra_args=" @expr 'foo'")
    check(g7b["box"]["text"] == "gen~ @title t7 @expr 'foo'",
          f"gen_codebox: leading-space extra_args text {g7b['box']['text']!r}")

    # 7) box_id auto vs. explicit
    check(g["box"]["id"] == "obj-gen-test_dsp",
          f"gen_codebox: auto box_id {g['box']['id']!r}")
    g8 = gen_codebox(title="t8", code="x;", numinlets=1, numoutlets=1,
                     box_id="my-explicit-id")
    check(g8["box"]["id"] == "my-explicit-id",
          f"gen_codebox: explicit box_id {g8['box']['id']!r}")

    # ── newobj / inlet_box / outlet_box / comment_box / subpatcher_box ─

    n = newobj("n1", "biquad~", (10, 10, 50, 22), numinlets=6, numoutlets=1,
               outlettype=["signal"])
    check(n["box"]["text"] == "biquad~", "newobj: text field")
    check(n["box"]["numinlets"] == 6 and n["box"]["numoutlets"] == 1,
          "newobj: inlet/outlet counts")
    check(n["box"]["outlettype"] == ["signal"], "newobj: outlettype")

    i_sig = inlet_box("i1", 1, (0, 0, 30, 30), signal=True)
    check(i_sig["box"]["maxclass"] == "inlet", "inlet_box: maxclass is 'inlet' (not newobj)")
    check("text" not in i_sig["box"], "inlet_box: no 'text' field (Max would try to instantiate it)")
    check(i_sig["box"]["index"] == 1, "inlet_box: index")
    check(i_sig["box"]["outlettype"] == ["signal"], "inlet_box: signal outlettype")
    i_ctl = inlet_box("i2", 2, (0, 0, 30, 30), signal=False)
    check(i_ctl["box"]["maxclass"] == "inlet", "inlet_box: control still uses maxclass 'inlet'")
    check(i_ctl["box"]["outlettype"] == [""], "inlet_box: control outlettype")

    o_sig = outlet_box("o1", 1, (0, 0, 30, 30), signal=True)
    check(o_sig["box"]["maxclass"] == "outlet", "outlet_box: maxclass is 'outlet' (not newobj)")
    check("text" not in o_sig["box"], "outlet_box: no 'text' field")
    check(o_sig["box"]["numoutlets"] == 0, "outlet_box: numoutlets is 0")
    check("outlettype" not in o_sig["box"], "outlet_box: no outlettype field (Max omits it)")

    c = comment_box("c1", "hello world", (0, 0, 200, 22))
    check(c["box"]["text"] == "hello world", "comment_box: text")
    check(c["box"]["maxclass"] == "comment", "comment_box: maxclass")

    inner = empty_patcher(width=200, height=100, is_root=False)
    sp = subpatcher_box("sp1", "my_sub", (0, 0, 200, 60), inner,
                        numinlets=2, numoutlets=2)
    check(sp["box"]["text"] == "p my_sub", "subpatcher_box: text")
    check("patcher" in sp["box"], "subpatcher_box: patcher field present")
    check(sp["box"]["patcher"] is inner["patcher"],
          "subpatcher_box: should embed inner patcher dict (envelope unwrapped)")
    check(sp["box"]["outlettype"] == ["signal", ""],
          f"subpatcher_box: default outlettype {sp['box']['outlettype']!r}")
    # Accept already-unwrapped inner too.
    sp2 = subpatcher_box("sp2", "my_sub", (0, 0, 200, 60),
                         inner["patcher"], numinlets=1, numoutlets=1)
    check(sp2["box"]["patcher"] is inner["patcher"],
          "subpatcher_box: already-unwrapped inner accepted")

    if failures:
        print("SELF-TEST FAILURES:")
        for f in failures:
            print(f"  - {f}")
        return 1
    print("ALL TESTS PASS")
    return 0


if __name__ == "__main__":
    import sys as _sys
    _sys.exit(_run_self_tests())
