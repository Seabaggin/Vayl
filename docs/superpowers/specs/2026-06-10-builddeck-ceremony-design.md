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

**Contents decision (user-confirmed):** the case contains the **starter prompt
deck** (`openerDeckType`), not the six credential cards. Their truths go into
the table; a gift forged from them comes out. Ensure `evaluateOpenerDeckType()`
has run before the reveal renders.

## The sequence

- **Beat 0 · Confirm & collapse** *(exists — keep)*: CTA dissolves; fan sweeps
  into a squared deck at table center. `exitDeckPoint` and `feltCenter` already
  agree; only the prop is wrong across the boundary.
- **Beat 1 · The swallow**: the deck sinks into the felt — slight scale-down,
  a glowing slit opens where it enters, soft thunk haptic. Anchor: card into a
  dealer's shoe.
- **Beat 2 · The forge** *(the interim)*: a roaming under-felt glow with
  escalating spectrum pulses along the table horizon (light under a door /
  under ice). Dealer retimed to the pulses: "From everything you've shown me…"
  → "…I'm building a deck that's yours alone."
- **Beat 3 · The eruption**: the slit flares; the case punches up through the
  felt with spring overshoot and light bleeding around the punch-through; lands
  floating where the hex foil catches its first band sweep. Heavy impact
  haptic. Reduce Motion: dignified fade-up, no punch.
- **Beat 4 · The invitation**: ~0.8s of stillness, then dealer: "This one's
  yours. Break it open." + **LiftHalo on the case** — the affordance taught in
  NamePhase paying off (cf. Opal's "tap to reveal your gem": explicit words +
  glow cue).
- **Beat 5 · The crack ceremony**: wire the existing engine — taps →
  `director.addFoilTear`; tears render on the case with colorway light-bleed
  escalating per tap; haptics escalate; third tap → bloom-flood → shatter.
  (Lattice-snapped cracks along hex grooves: later enhancement per the foil
  spec.)
- **Beat 6 · The reveal**: out of the bloom, the starter prompt deck presents
  in a card carousel (reuse `VaylCardCarousel`); browse freely.
- **Beat 7 · The letter**: the founder letter rises as a pull-up sheet over the
  carousel, deck still visible beneath. **Trigger deliberately open** (browsed-
  all vs dwell vs subtle CTA) until the user reviews their inspiration app.
  The current auto-advance 1.8s after the third crack is removed regardless —
  it would steamroll the carousel.

## What dies

- `DeckStack` (stroked-rect fake deck) → replaced by real card-back deck
  pixel-matched to confirmation's collapse
- The floating ribbon wrap (`DeckWrapView` as currently used) → forge glow
  carries the interim instead (reuse its internals if useful, else retire)
- `.transition(.opacity)` case arrival → eruption
- The dev "Continue" button → real crack ceremony
- `beginFoilDissolve`'s auto-advance to `.founderLetter` → reveal carousel,
  letter handoff per Beat 7

## Build segments (Build Protocol — each feel-verified on device before the next)

1. **Seam stitch** — BuildDeckPhase opens with a real-card-back deck at the
   exact collapse point. Done: tapping the CTA shows no detectable boundary.
   Constraints: BuildDeckPhase + (if needed) a shared deck-stack component;
   no director changes.
2. **The swallow** — sink + slit glow + haptic. Done: deck believably enters
   the table. Constraints: BuildDeckPhase only.
3. **The forge** — under-felt roaming glow + pulses + retimed dealer lines.
   Done: the interim reads as something being made. Constraints: BuildDeckPhase
   (+ DeckWrapView retire/repurpose).
4. **The eruption** — punch-through, spring landing, light burst, Reduce Motion
   fallback. Done: arrival feels caused, not silly. Constraints: BuildDeckPhase.
5. **The invitation** — stillness beat, dealer line, LiftHalo on the case.
   Done: a stranger knows to tap within 2 seconds. Constraints: BuildDeckPhase
   + LiftHalo reuse.
6. **Crack wiring** — taps → `addFoilTear`; tear rendering + colorway bleed on
   the case; escalating haptics; dissolve on the third. Done: three taps with
   mounting tension. Constraints: BuildDeckPhase, MetallicCaseView (tear
   overlay), VaylDirector (remove auto-advance only — `advance()` remains the
   sole phase gate).
7. **The reveal** — shatter bloom → starter prompt carousel; ensure
   `evaluateOpenerDeckType()` ran. Done: payoff lands, cards browseable.
   Constraints: BuildDeckPhase + VaylCardCarousel reuse.
8. **Letter handoff** — pull-up sheet rises over the carousel; trigger decided
   after inspo review. Done: smooth auto-proceed, no steamroll.
   Constraints: BuildDeckPhase, FounderLetterPhase entry, director.

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
- Beat 7 trigger choice — decided after the user reviews their inspiration app.
