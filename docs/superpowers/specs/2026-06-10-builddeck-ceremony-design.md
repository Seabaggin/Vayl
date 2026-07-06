# BuildDeck Ceremony — Confirmation → Forge → Crack → Reveal → Letter

**Date:** 2026-06-10
**Status:** Approved direction, pending spec review
**Phases touched:** ConfirmationPhase (seam only), BuildDeckPhase, VaylDirector (crack flow), FounderLetterPhase (handoff trigger only)

## Context

The confirmation→buildDeck transition reads cartoonish. Diagnosis: it breaks
**object permanence three times in six seconds** —

1. The real fan collapses into a deck (good), then `advance(to: .buildDeck)`
   unmounts it.
2. BuildDeckPhase mounts a different prop: `DeckStack` is five stroked
   rounded-rects, not the card backs the user has handled for nine phases.
3. At ~5.4s `DeckStack` + ribbons vanish and `MetallicCaseView` cross-fades in
   at 1.45× size (`.transition(.opacity)`) — the cheapest transition in the
   vocabulary at the most ceremonial moment, with nothing causing it.

Secondary: dealer lines fire on fixed sleeps and overlap the case landing;
a dev "Continue" button sits under the ceremony; the director's crack engine
(`addFoilTear` → 3 taps → `beginFoilDissolve`) is built but unwired.

**Principle:** one object, transformed — never swapped. Every disappearance
shares a door with the corresponding appearance: the deck sinks INTO the felt,
the case erupts OUT of it — the table is the forge, and the interim glow is the
work being made. Anchor moments get stillness before and after.

**Narrative north star (user's words):** the cards fanned in ConfirmationPhase
*become* the deck we handle the rest of the way — a single perceived
deck-object: confirmed → squared → taken by the table → magic happens → bam,
their starter deck. The contents transform (credentials in, starter prompts
out); the OBJECT never breaks continuity. Even though the decks don't connect
in reality, the user is none the wiser — that perceived throughline IS the
trick, and every segment is judged against preserving it.

**Contents decision (user-confirmed):** the case contains the **starter prompt
deck** (`openerDeckType`), not the six credential cards. Their truths go into
the table; a gift forged from them comes out. Ensure `evaluateOpenerDeckType()`
has run before the reveal renders.

## The sequence

- **Beat 0 · Confirm & collapse** *(exists — keep)*: CTA dissolves; fan sweeps
  into a squared deck at table center. `exitDeckPoint` and `feltCenter` already
  agree; only the prop is wrong across the boundary.
- **Beat 1 · The dissolve-down**: the deck dissolves DOWN through the felt —
  no violence, no slit: the dissolve verb GenderPhase already established
  (`dissolution*` driver family), improved past its current 7/10 (directional
  wipe along the descent, dissolve-edge energy). Soft thunk haptic as the last
  of it goes under.
- **Beat 2 · The table's hero moment** *(the interim)*: the TABLE performs,
  using ornaments it already owns — the spectrum horizon and contour lines
  pulse/converge around the point where the deck went under ("something is
  happening under there"). No new props; the stage is the effect. Dealer
  retimed to the pulses: "From everything you've shown me…" → "…I'm building
  a deck that's yours alone."
- **Beat 3 · The arrival — three calm impossibilities**: (a) the cased deck
  **dissolves UP from the felt, lying flat** on the table (where cards belong);
  (b) it **rises from flat to fully vertical** (the case presents itself — the
  existing 3D projection already supports the rx sweep); (c) it **floats up as
  the table fades** in the background — ContextPhase's established grammar
  ("the table dissolves as the carousel assembles"). First band-sweep on the
  hex foil lands during the float. Each step breaks one more rule of physics
  while staying serene. Reduce Motion: cross-dissolve to the floating pose.
- **Beat 4 · The invitation**: ~0.8s of stillness, then dealer: "This one's
  yours. Break it open." + **LiftHalo on the case** — the affordance taught in
  NamePhase paying off (cf. Opal's milestone gem reveal: explicit words + glow
  cue).
- **Beat 5 · The crack ceremony**: wire the existing engine — taps →
  `director.addFoilTear`; tears render on the case with colorway light-bleed
  escalating per tap; haptics escalate; third tap → bloom-flood → shatter.
  Tap threshold stays tunable (feel-test 2 vs 3; could not verify Opal's
  count — 3 chosen for ritual arc: one is a button, two a coincidence, three
  a ritual). (Lattice-snapped cracks along hex grooves: later enhancement per
  the foil spec.)
- **Beat 6 · The reveal**: out of the bloom, the starter prompt deck presents
  in a card carousel (reuse `VaylCardCarousel`); **deck title appears above
  with a one-line description of the deck's purpose** (from `openerDeckType`).
  Browse freely — examine and play, no timer pressure.
- **Beat 7 · The letter — sheet peek**: after the user browses a few cards OR
  idles ~5–6s, the founder letter itself rises a sliver from the bottom — an
  iOS bottom-sheet peek, letterhead just visible, with a quiet label ("A note
  from the founder" / dealer: "One more thing…"). The carousel stays fully
  interactive above it. Pull or tap expands the sheet — that IS the
  transition: the peek renders in BuildDeck; full expansion fires
  `advance(to: .founderLetter)` where FounderLetterPhase owns the sheet. The
  carousel squares back into the deck beneath as the sheet rises, preserving
  the throughline to the last frame. The current auto-advance 1.8s after the
  third crack is removed regardless. The affordance is the destination — no
  button symbol. **Documented fallback:** if the peek feels busy under the
  carousel on device, swap to a delayed dealer-voiced CTA pill ("Take your
  deck") — the trigger logic is identical either way.
- **Beat 8 · The curtain (dismissal contract)**: expanded, the letter holds a
  single full detent (no medium stop, no accidental flick-away mid-signature)
  but pull-down stays available throughout — it is the COMPLETION gesture, not
  a cancel. While the sheet covers the screen, the stage behind it changes:
  table fades, home assembles (the existing `finishOnboarding()` mechanics,
  choreographed under the sheet). Pull-down → commit fires → on success the
  sheet completes its descent revealing HOME (theater curtain: the set changed
  behind it); on failure the sheet settles back up with a quiet retry surface
  (`commitFailed`) — nothing lost. Never hold the sheet hostage to the
  signature animation; speed-runners may dismiss unread because the letter is
  permanently re-readable from Settings/About (add that entry).

## What dies

- `DeckStack` (stroked-rect fake deck) → replaced by real card-back deck
  pixel-matched to confirmation's collapse
- The floating ribbon wrap (`DeckWrapView` as currently used) → forge glow
  carries the interim instead (reuse its internals if useful, else retire)
- `.transition(.opacity)` case arrival → eruption
- The dev "Continue" button → real crack ceremony
- `beginFoilDissolve`'s auto-advance to `.founderLetter` → reveal carousel,
  letter handoff per Beat 7

## Resolved issues (folded in pre-implementation)

- **Seam is double-broken today**: confirmation cards exit FACE-UP at 50%
  scale; BuildDeck's deck is full-size backs. Fix in segment 1: cards **turn
  face-down as they collapse** (their truths going private as they're
  submitted) and settle at the canonical `obCardWidth` deck scale at table
  center — both sides of the boundary meet at face-down / obCard size /
  feltCenter / angle 0.
- **Sheet continuity across the phase swap**: expand FULLY first, advance
  second — `advance(to: .founderLetter)` fires only once the sheet covers the
  screen, so the phase swap happens behind the curtain. A shared letterhead
  component guarantees the covering frame is identical on both sides.
- **Flat pose stresses the foil shader**: at rx ≈ −90° the front quad is
  near-degenerate (invBilinear noise, lattice aliasing at grazing angles).
  Mitigation designed in: the lattice + band FADE IN during the flat-to-
  vertical rise — the material wakes up as the deck stands.
- **Crack tears stored in face space**: `FoilTear` tap points convert to
  face-local UV at tap time (the foil's inverse-bilinear machinery) so cracks
  stick to the case while it floats — never screen-anchored.
- **Case embossing**: the sealed case wears **VAYL** (the house seals the
  gift); the starter deck's name lands at Beat 6 as a genuine reveal.
- **Duration budget**: the non-interactive stretch (confirm → invitation)
  targets **≤ 9s total**; every beat earns its milliseconds at the feel gates.
- Beat 6 content (starter prompt cards per `openerDeckType`) is trusted to a
  later content pass; segment 7 may ship against designed placeholders.

## Build segments (Build Protocol — each feel-verified on device before the next)

1. **Seam stitch** — confirmation exit: cards flip face-down mid-collapse and
   settle at obCard deck scale; BuildDeckPhase opens with a real card-back
   deck (VaylCardBack stack) pixel-matched at the same point. Done: tapping
   the CTA shows no detectable boundary. Constraints: ConfirmationPhase exit
   choreography + BuildDeckPhase deck prop; no director changes.
2. **The dissolve-down** — deck dissolves through the felt (GenderPhase verb,
   improved) + haptic. Done: deck believably passes under the table.
   Constraints: BuildDeckPhase only.
3. **The table's hero moment** — horizon + contour ornaments pulse/converge on
   the forge point; retimed dealer lines. Done: the interim reads as something
   being made by the table itself. Constraints: BuildDeckPhase (+ canvas/table
   ornament hooks if the ornaments live there; tableFade still director-only)
   (+ DeckWrapView retire/repurpose).
4. **The arrival** — dissolve-up flat on the felt → flat-to-vertical rise →
   float as the table fades (ContextPhase grammar); Reduce Motion
   cross-dissolve. Done: three calm impossibilities land serenely; first
   band-sweep during the float. Constraints: BuildDeckPhase + MetallicCaseView
   pose driving (rx sweep).
5. **The invitation** — stillness beat, dealer line, LiftHalo on the case.
   Done: a stranger knows to tap within 2 seconds. Constraints: BuildDeckPhase
   + LiftHalo reuse.
6. **Crack wiring** — taps → `addFoilTear`; tear rendering + colorway bleed on
   the case; escalating haptics; dissolve on the third. Done: three taps with
   mounting tension. Constraints: BuildDeckPhase, MetallicCaseView (tear
   overlay), VaylDirector (remove auto-advance only — `advance()` remains the
   sole phase gate).
7. **The reveal** — shatter bloom → starter prompt carousel + deck title and
   one-line purpose; ensure `evaluateOpenerDeckType()` ran. Done: payoff lands,
   cards browseable, the deck has a name. Constraints: BuildDeckPhase +
   VaylCardCarousel reuse.
8. **Letter handoff — sheet peek** — browse-or-idle trigger raises the founder
   letter to a labeled peek; pull/tap expands it (carousel squares into the
   deck beneath; expansion fires `advance(to: .founderLetter)`). Done: the exit
   never steamrolls play, proceeding is one obvious pull or tap, and the
   throughline holds to the last frame. Fallback if busy on device: delayed
   dealer-voiced CTA pill, same trigger. Constraints: BuildDeckPhase,
   FounderLetterPhase entry, director.

## Architecture constraints

- `director.advance()` stays the only phase gate; `tableFade` written only by
  the director.
- Views forward taps to the director; the crack state (`foilTears`,
  `foilIntegrity`) stays director-owned.
- All timings as `AppAnimation` tokens once felt-verified (no raw durations in
  final code); every looping effect `.ambientAnimation()`; Reduce Motion
  fallback per beat.
- Haptics per the tap contract (`.sensoryFeedback`), escalating weights through
  the crack ceremony.

## Verification

Per segment: clean build (shader untouched, but tear overlay may touch metal in
segment 6) → run on simulator/device → user confirms feel before the next
segment. The full ceremony is judged end-to-end from the confirmation CTA, not
per-beat in isolation, before segment 8 closes.

## Out of scope

- Lattice-snapped crack paths + hex shatter plates (foil spec follow-up).
- FounderLetterPhase content/visuals (separate design pass).
- Final Beat 7 copy + trigger thresholds — feel-tuned; user may refine after
  reviewing their inspiration app.
- Deck title/description copy per `openerDeckType` variant (content pass).
