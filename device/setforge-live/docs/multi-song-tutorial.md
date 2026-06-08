# SetForge Live — Multi-Song Mode: A Performance Tutorial

This is a hands-on manual for performing with the SetForge Live device and a
Launchpad MK2. Read it like a music-software manual: it walks you through the
gestures, what you'll see on the pads, and what you'll hear. It documents the
device **as it actually behaves today** — where a feature is only half-wired or
purely cosmetic, this guide says so plainly so you don't waste a set chasing a
sound that won't come.

Hardware assumptions: one Launchpad MK2 (grid + the two side-button columns).
A second Launchpad is optional and only adds the standalone control surface.

> **Orientation note.** Throughout this guide, **row 1 is the top row of the
> grid** and **row 8 is the bottom row**, matching what you see on the device.
> Columns run 1 (left) to 8 (right).

---

## 1. The four views

SetForge gives you four ways to look at and play your loaded music. They are not
four separate "screens" you cycle through — three of them live on the main grid
(Grid 1) and you flip between them with quick gestures, while the fourth is an
overlay.

| View | What it's for | How you enter it |
|---|---|---|
| **Solo** | The default. Play chops from one preset across the four stem rows. | This is where you start. You're in Solo whenever you're not in another view. |
| **Per-row** | Each of the four stem rows can pull from a *different* preset at once. | **Double-tap the SOLO pad** (row 7, column 3). |
| **Dual-song** | Two whole songs side by side — deck X on the top half, deck Y on the bottom half. | **Top-right side button** (the topmost button in the right-hand column). Hold to peek, double-tap to latch. |
| **Control** | A standalone control surface (setlist + FX selectors). Overlays Grid 1. | **Top-left side button** (the topmost button in the left-hand column). Hold to peek, double-tap to latch. |

A few things worth knowing up front:

- **Solo and Per-row are mutually exclusive** — you're in one or the other.
- **Dual-song temporarily suspends** whatever you were doing (Solo *or* Per-row)
  and restores it when you leave. Your per-row stem assignments survive a
  dual-song peek untouched.
- **Control view is an overlay**, not a true sibling view. You can technically be
  in Control while Per-row or Dual-song state is still live underneath. It hijacks
  Grid 1 to show the control surface; leaving it drops you back exactly where you
  were.

Solo and Per-row are covered next; the side-button views follow.

---

## 2. Solo mode basics

Solo is home base. The grid is laid out like this:

| Row | Contents |
|---|---|
| 1 | **drums** chops (8 columns) — ORANGE |
| 2 | **bass** chops — BLUE |
| 3 | **other** chops — YELLOW / olive |
| 4 | **vox** chops — GREEN |
| 5 | **Bank A** presets (slots 0–7) |
| 6 | **Bank B** presets (slots 8–15) |
| 7 | Modifiers (HOLD, MUTE, SOLO, REV, STUT, HALF, DBL, KILL) |
| 8 | Scenes (8 save/recall slots) |

### Load a preset

1. Look at rows 5 and 6 — these are your preset banks. A pad that holds a loaded
   preset shows a colored tile; an empty slot is nearly black.
2. **Tap a preset pad** on row 5 (bank A) or row 6 (bank B). That preset becomes
   active, and its four stems light up the chop rows above.

The four stem rows (1–4) all source their chops from this single active preset.
Each stem keeps its identity color so you always know which row is which:

- **Row 1 — drums — ORANGE**
- **Row 2 — bass — BLUE**
- **Row 3 — other — YELLOW / olive** (this is a warm olive, *not* grey)
- **Row 4 — vox — GREEN**

### Play chops

- A **playable** chop sits at the soft (dim) version of its stem color.
- **Tap a chop pad** to launch it. The pad jumps to the **bright** version of its
  stem color while it's playing.
- **Tap the playing chop again** (or a different chop in the same row) to stop or
  replace it. Each stem row plays one chop at a time.
- A chop tile shown in a dark red (`[40,0,0]`) is **disabled** for this preset —
  there's nothing there to play in that column.

That's the whole core loop: pick a preset, fire chops across the four stems,
swap chops as you go. Everything else in this guide builds on it.

---

## 3. Per-row mode walkthrough

Per-row mode is the first power feature. It lets each of the four stem rows pull
its chops from a **different preset at the same time** — drums from one song,
bass from another, and so on.

### Entering per-row mode

1. Find the **SOLO pad: row 7, column 3.**
2. **Double-tap it** (two taps within about 0.4 seconds).

What happens on entry:

- The SOLO pad **latches yellow** — that's your "you are in per-row mode" light.
  It stays lit the whole time you're in the mode.
- All four stem rows are seeded from whatever preset was active when you entered,
  so at first nothing sounds different — drums, bass, other, and vox are all
  pointing at the same song.
- The grid repaints once to its per-row state.

> **No flash, no pulse.** Entering per-row mode does a single clean repaint. There
> is **no entry animation** — no pulsing column, no one-shot flash. If you were
> expecting a little light show, that's not in the device; the static color cues
> below are how you read the mode.

### Reassigning a row to a different preset

This is the gesture you came for. To point a stem row at a new song:

1. **Hold down a chop pad** in the stem row you want to reassign (any of its 8
   chop pads, rows 1–4). Keep holding it.
   - *Side effect:* holding that pad also fires the chop normally, so you'll hear
     it play. That's expected.
2. While still holding, **tap a preset** on row 5 (bank A) or row 6 (bank B).
3. That stem row is now sourced from the tapped preset. Release the chop pad.

You can hold pads in **more than one stem row at once** and a single preset tap
will reassign all of the held rows together.

What you'll hear: the reassignment is **immediate**. The new preset's clips for
that stem load right away, and if a chop was already playing in that row,
SetForge hot-swaps it to the matching column in the new source on the fly (or
stops it cleanly if the new source has nothing in that column). Live's own
clip-launch quantization still governs the exact moment a launched clip starts —
SetForge does not add its own boundary on top of that.

### Reading the visual cues

- **SOLO pad** stays **latched yellow** for the whole session.
- **Column 1 of a reassigned stem row** changes its background tint to the
  **source preset's palette color**, so you can tell at a glance which row is
  pulling from which song.
  - **Caveat:** that column-1 tint is **suppressed while the column-1 chop is
    actually playing.** A playing chop always shows the bright stem color, which
    takes priority over the source tint. So if you have chop 1 held in that row,
    you won't see the source indicator until it stops.

### Exiting per-row mode

1. **Double-tap the SOLO pad again** (row 7, column 3).

On exit:

- The active preset becomes whatever the **drums row** was sourced from — this is
  deterministic, so you always know where you land.
- The SOLO pad's yellow latch clears, and you're back in Solo mode.
- Your per-row assignments stop affecting playback (they're set aside, not
  actively used). Held audio keeps playing through the transition.

---

## 4. Staging walkthrough (preparing decks for dual-song)

Before you play a dual-song mashup, you **stage** the two songs you want — one to
**deck X** and one to **deck Y**. Staging pre-loads the music so dual-song entry
is instant.

### The deck-setup button

- The staging button is the **second button from the top in the right-hand
  column** (the one just below the dual-song toggle).
- **Hold it down** to enter staging. While held, it lights **solid bright white.**
- While you hold it, row 5 and row 6 stop acting as normal preset banks and
  instead assign presets to decks.

### Staging the two decks

While holding the deck-setup button:

- **Tap a preset on row 5 → stages it to deck X** (bank A presets).
- **Tap a preset on row 6 → stages it to deck Y** (bank B presets).

So: row 5 = deck X, row 6 = deck Y. Top half of your eventual dual-song grid
comes from the row-5 pick; bottom half from the row-6 pick.

### Visual feedback — the two-color flash

When you stage a deck, its pad starts a **two-color flash** so you can see at a
glance what's loaded where:

- **Deck X pads (row 5)** flash between the **preset's color** and **white.**
- **Deck Y pads (row 6)** flash between the **preset's color** and a **soft blue.**

This flashing is how you confirm a deck is staged. The two halves use different
second colors (white vs. soft blue) specifically so you can tell deck X from
deck Y at a glance.

### Pre-loading is instant

Staging a deck **pre-loads its clips immediately.** The moment you tap the preset
while holding deck-setup, SetForge loads that song's stems into the deck's
dedicated tracks — all the chops, with their warp and loop settings — right then.
There's a brief follow-up pass a few seconds later that tidies the warp markers,
but the audible clips are in place from the instant you stage. By the time you
open dual-song view, both songs are ready to fire.

### Releasing and idle state

- **Release the deck-setup button** to leave staging. Rows 5/6 go back to normal
  preset banks.
- After release, the deck-setup button shows a **dim white** glow if *either*
  deck is staged, or goes **fully off** if nothing is staged yet.

### If you stage an empty slot

If you tap a preset slot that's **empty, still loading, or in an error state,**
SetForge **flashes that pad red** for about half a second and **does not stage
it** — the deck stays as it was. Pick a loaded slot instead.

> **Honest limitation.** SetForge only checks the *slot state* before staging. If
> a slot looks loaded but a stem's audio file is actually missing on disk, the
> pre-load can come up short **without** a red flash and **without** clearing the
> deck — the deck will appear staged but may have missing or zero clips. Keep your
> sets tidy and your files in place.

---

## 5. Dual-song walkthrough

Dual-song view puts **two whole songs on the grid at once** — deck X on the top
four rows, deck Y on the bottom four — so you can mash drums from one song
against vox from another, layer two drum loops, and so on.

Stage your two decks first (Section 4). If you haven't staged, SetForge will fall
back to the most-recently-active bank-A preset for deck X and most-recently-active
bank-B preset for deck Y — but staging is the reliable path, and the fallback only
remembers the slot, it doesn't pre-load on its own.

### Entering dual-song view

The dual-song toggle is the **topmost button in the right-hand column.**

- **Hold it down → momentary peek.** You're in dual-song view as long as you hold;
  **release** to drop back to where you were.
- **Double-tap it (within ~0.4s) → latch.** You stay in dual-song view hands-free.
  **Double-tap again** to leave.

When dual-song is active, the toggle button lights **bright white.** (When you're
not in dual-song but something is staged, it shows a mid white; off when nothing's
staged.)

### The dual-song grid

All eight grid rows become stems, split across the two decks:

| Rows | Deck | Stems (top to bottom of each half) |
|---|---|---|
| 1–4 | **Deck X** | row 1 drums, row 2 bass, row 3 other, row 4 vox |
| 5–8 | **Deck Y** | row 5 drums, row 6 bass, row 7 other, row 8 vox |

Each row keeps its **stem color** (orange/blue/olive/green), soft when idle and
bright when that column is playing. Empty cells are off; disabled chops show the
dark red tile.

### Playing across both decks (chording)

Every pad in dual-song view fires a chop on its deck+stem. Because the two decks
have **independent drum rows** (row 1 = deck X drums, row 5 = deck Y drums), you
can **chord drums on drums** — fire a kick pattern from deck X on row 1 and layer
a different drum chop from deck Y on row 5 at the same time. The same goes for any
pair of stems across the two halves.

Within a single deck+stem, tapping a new column replaces what was playing; tapping
the playing column again stops it.

### Per-row launch quantization

Each stem launches on its own musical grid, so chops drop in tight no matter when
you tap:

| Stem | Snaps to |
|---|---|
| **drums** | 1/16 note |
| **bass** | 1 bar |
| **other** | 1/4 note |
| **vox** | 1/2 note |

Drums respond almost instantly (1/16), while bass waits for the downbeat (1 bar)
so basslines stay locked to the phrase. Plan your gestures around this — tapping a
bass chop mid-bar means it lands on the next bar line, not right away.

### Exiting dual-song view

- If you **peeked** (held the button): **release** to exit.
- If you **latched** (double-tapped): **double-tap again** to exit.

On exit, you return to whatever you were doing before — Solo or Per-row, with your
per-row stem assignments intact.

---

## 6. How the views interact

A few rules tie everything together. Knowing these keeps you from surprising
yourself mid-set.

- **Held audio keeps playing across every view transition.** Flipping into
  per-row, peeking dual-song, opening control view — none of these stop sound
  that's already playing. The only thing that stops everything is PANIC.

- **Per-row state survives a dual-song peek.** If you're in per-row mode and you
  peek (or latch) into dual-song, your `rowSources` assignments are saved and
  restored. Drop out of dual-song and your per-row rig is exactly as you left it.

- **Per-row is suspended, not destroyed, during dual-song.** While dual-song is
  active, the per-row reassignment gesture is unavailable (the grid is showing two
  decks). It comes right back when you leave.

- **Control view is an overlay.** Entering control view doesn't disturb your
  per-row or dual-song state underneath; leaving control view drops you back onto
  whatever Grid 1 was showing.

### PANIC — the safety net

When a set gets away from you, **PANIC** stops everything and returns you to Solo.

- **Gesture: triple-tap the PANIC side button** — the **bottom button in the
  left-hand column.** The three taps must come within ~1 second of each other.
  (You can also trigger it from the transport row, column 8, with the same
  triple-tap.) Intermediate taps post "panic 1/3" and "panic 2/3" so you know it's
  arming.
- **What PANIC does:** stops all chops, clears all latched modifiers, bypasses FX,
  stops all clips, and returns you to **Solo** view. If you were in dual-song, it
  clears that too.
- **What PANIC does *not* do:** it does **not** clear your staged decks (deck X /
  deck Y stay loaded), it does **not** reset the active preset, and it does **not**
  leave control view if you were overlaying it. So after a PANIC you're back in
  Solo with a clean slate of sound, but your staging is still ready to go.

> Note: PANIC is the **triple-tap** gesture, and it is **not** the same thing as
> the **KILL** modifier (row 7, column 8). KILL is a separate row-7 pad — see the
> next section.

---

## 7. A word on the row-7 modifiers (read before you rely on them)

Row 7 has eight modifier pads, labeled **HOLD, MUTE, SOLO, REV, STUT, HALF, DBL,
KILL** (columns 1–8). They all *light up* and respond to taps, but most of them
**do not change the sound** in the current device. Here's the honest breakdown so
you don't go hunting for an effect that isn't wired:

- **HOLD (col 1) — partial.** Its real, working job is **SHIFT**: hold it while
  tapping a preset to switch the active preset *without* migrating your held chops,
  and hold it while tapping a scene pad to **save** to that scene instead of
  recalling. It does **not** give you a true one-shot "play once and stop" — that
  part isn't implemented.

- **SOLO (col 3) — this is the per-row toggle.** Despite the name, it does **not**
  solo a stem. **Double-tapping it enters/exits per-row mode** (Section 3). That's
  its only function.

- **MUTE, REV, STUT, HALF, DBL, KILL (cols 2, 4, 5, 6, 7, 8) — visual-only
  stubs.** These six pads latch and light up, and they're even saved into scenes,
  but **they have no effect on audio whatsoever.** There is no mute, no reverse, no
  stutter/retrigger, no half-speed, no double-speed, and no kill behind them in the
  shipped device. Treat them as placeholders.

(The Grid 2 / control-view FX selectors — FX target, filter sweep, throws — are
likewise **visual/status only** in this build; they color pads and update the
status text but do not process audio.)

---

## 8. Common workflows

Three concrete sequences you'll reach for in a real set.

### Workflow A — Set up a dual-song mashup mid-set

You're playing in Solo and you want to drop into a two-song mashup.

1. **Hold the deck-setup button** (2nd from top, right column).
2. **Tap a preset on row 5** — it starts its preset↔white flash. Deck X is staged
   and pre-loaded.
3. **Tap a preset on row 6** — it starts its preset↔soft-blue flash. Deck Y is
   staged and pre-loaded.
4. **Release the deck-setup button.** The button settles to dim white (something's
   staged).
5. When you're ready, **double-tap the dual-song toggle** (top-right side button)
   to latch into dual-song view. Both songs are already loaded, so the switch is
   instant.
6. Now chord across the grid — deck X drums (row 1) against deck Y vox (row 8),
   layer the two drum rows (1 and 5), whatever the moment calls for. Remember the
   per-stem quantization: drums snap tight, bass waits for the bar.
7. **Double-tap the dual-song toggle again** to drop back to Solo when the mashup's
   done.

### Workflow B — Swap a stem in per-row mode while drums keep playing

You're playing a groove and you want to pull the bassline from a different song
without dropping the beat.

1. **Double-tap the SOLO pad** (row 7, col 3) to enter per-row mode. The pad
   latches yellow.
2. Make sure your **drums** are playing (fire a drums chop on row 1 if they aren't).
3. **Hold a chop pad on the bass row** (row 2) — it'll fire that bass chop while
   you hold it.
4. While holding, **tap the preset** (row 5 or 6) for the song whose bass you want.
   The bass row instantly reloads from that preset and hot-swaps any playing bass
   chop. **Your drums never stop.**
5. Release the bass pad. Column 1 of the bass row now carries that source preset's
   color tint (unless its column-1 chop is the one playing).
6. Repeat for any other row you want to re-source. Drums (and everything else
   you've left playing) keep going throughout.
7. **Double-tap SOLO** to exit when you're done — the active preset lands on
   whatever your drums row was pulling from.

### Workflow C — Quick momentary dual-song peek

You want to grab one hit from a second song without committing to dual-song view.

1. Make sure deck Y (or both decks) is staged (Workflow A, steps 1–4).
2. **Hold** the dual-song toggle (top-right side button) — you're now peeking into
   dual-song, grid split top/bottom.
3. **Tap the chop** you want from the deck-Y half (rows 5–8) or deck-X half
   (rows 1–4).
4. **Release** the toggle — you snap right back to where you were (Solo or
   Per-row), with your per-row assignments and any held audio intact.

---

## 9. Quick reference card

**Views & entry gestures**

| View | Enter | Exit |
|---|---|---|
| Solo | default / exit any other view | — |
| Per-row | double-tap SOLO (row 7, col 3) | double-tap SOLO again |
| Dual-song | top-right side button — hold to peek / double-tap to latch | release (peek) / double-tap (latch) |
| Control | top-left side button — hold to peek / double-tap to latch | release / double-tap |
| Staging | hold deck-setup (2nd-from-top, right column) | release |

**Stem colors (rows = stems)**

| Row | Stem | Color |
|---|---|---|
| 1 | drums | ORANGE |
| 2 | bass | BLUE |
| 3 | other | YELLOW / olive |
| 4 | vox | GREEN |

**Dual-song launch quantization**

| Stem | Snap |
|---|---|
| drums | 1/16 |
| bass | 1 bar |
| other | 1/4 |
| vox | 1/2 |

**Staging flash colors**

- Deck X (row 5): preset color ↔ white
- Deck Y (row 6): preset color ↔ soft blue

**PANIC:** triple-tap the bottom-left side button (or transport col 8) within ~1s
→ stops everything, returns to Solo. (Staging and active preset are *not* cleared.)

**Working row-7 modifiers:** HOLD (= SHIFT: preset-no-migrate / scene-save) and
SOLO (= per-row toggle). The other six (MUTE, REV, STUT, HALF, DBL, KILL) light up
but do nothing to the audio.
