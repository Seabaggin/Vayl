# BuildDeck — Finish the Reveal + Tempo Correction (S1–S4)

**Date:** 2026-06-13
**Extends / supersedes the tempo target of:** `docs/superpowers/specs/2026-06-10-builddeck-ceremony-design.md`
**Informed by:** the 2026-06-13 full-OB video+code audit (195 s preview capture; see memory `ob_sequencing_audit_2026_06_13`).

## Why

The 06-10 ceremony spec breaks BuildDeck into 8 segments. The 06-13 audit confirms **segments 1–6 render on screen**: seam stitch, dissolve-down (~t156–159), table-work, flat→vertical arrival, the *"This one's yours. Break it open."* invitation (~t169–171), and the 3-tap crack→bloom (~t172–177). Three things remain:

- **Segment 7 (the reveal) is unbuilt** — after the shatter the screen drops to a tiny dim card and then a dead void (t177–184). The "break it open → here's your deck" promise pays out nothing.
- **Segment 8 (the letter) is mis-sequenced** — the founder letter peeks straight out of that void, with no deck browse before it.
- The **autonomous runway overshot** the spec's ≤9 s target to ~22 s, with two stretches of empty/static screen (t160–165, deck gone and nothing risen; t177–184, post-shatter void) and the hex lattice peaking ~3 s before its own CTA.

## Tempo principle (retires the ≤9 s budget)

The mood is **sitting down at the table to begin NM exploration** — a threshold ritual. Pacing is **unhurried, deliberately a touch slower than typical app motion**, with weight on every beat. The ≤9 s number is retired as a goal.

**The gate is: no frame where nothing is moving.** Dead air ≠ slowness. Resolve every gap with *motion*, not by deleting time. Duration lands by feel; the only hard rule is zero frozen/empty frames. (This principle generalizes past BuildDeck — the bare-horizon beats between phases and the finale void tail are the same bug.)

## Scope

- Reveal presents as a **full, browseable `VaylCardCarousel`** against **designed placeholder cards** (one shared set, ~6 cards). Real per-`openerDeckType` prompt content is a later content pass.
- The **deck name + one-line purpose** for each of the 4 `openerDeckType` variants are drafted as short **working titles now**, so the reveal feels personalized to the user's answers. Provisional, lives with the segment.

## Segments (Build Protocol — each feel-verified on device before the next)

### S1 · The reveal — out of the bloom, the deck
- **One thing:** the shatter bloom-flood resolves *into the forged deck* at the same screen point (object continuity — the case becomes the deck); the **deck name lands as the genuine reveal** (the case wore `VAYL`; the deck wears its own name from `openerDeckType`); a one-line purpose sits above; a browseable `VaylCardCarousel` of placeholder cards fans below. No timer.
- **Done (device):** striking the third crack resolves — with **no void** — into a named deck that reads as "the thing I built," cards browseable; `evaluateOpenerDeckType()` confirmed to have run before render.
- **Constraints:** `BuildDeckPhase` + `MetallicCaseView` (bloom→deck handoff) + `VaylCardCarousel` reuse. Placeholder content only. **May not:** change `advance()` (sole phase gate), write `tableFade` outside the director, edit the `VaylCardFace` shell.
- **Reduce Motion:** cross-dissolve bloom→deck.
- **Feel-first:** bloom→deck materialization + name reveal felt in a reference (or Swift-on-device per the 3D/shader preference) before final timings.

### S2 · Letter handoff — after the deck, not instead of it
- **One thing:** remove the shatter→letter auto-jump; after the user browses a few cards **or** idles ~5–6 s, the founder letter rises to a labeled peek ("A note from the founder"); the **carousel squares back into the deck as the sheet rises**; pull/tap expands → `advance(.founderLetter)`.
- **Done (device):** browse/idle raises the peek; the deck visibly collapses under the rising sheet (throughline holds to the last frame); expansion advances the phase; no empty gap in the handoff.
- **Constraints:** `BuildDeckPhase` (peek trigger + carousel→deck collapse) + `FounderLetterPhase` (shared letterhead so the covering frame is identical across the swap). **May not:** break `advance()` as sole gate, write `tableFade` outside the director.
- **Documented fallback** (if the peek feels busy under the carousel on device): a delayed dealer-voiced "Take your deck" CTA pill — identical trigger logic.

### S3 · Tempo — unhurried but never empty
- **One thing:** eliminate the two empty/static stretches by **filling** them, keeping the deliberate pace of the living beats. t160–165 (deck under, nothing risen) becomes the **table's hero moment** — horizon + contour lines pulse and converge on the forge point, foil-glow builds where the deck submerged; push the forge oscillation until the interim visibly reads as "the table is making something." Keep its unhurried length; remove its emptiness. (The dark-flat case dwell folds into S4.)
- **Done (device):** scrub the ceremony frame-by-frame — there is no stretch where nothing is in motion; the pace still feels calm and weighty, not rushed.
- **Constraints:** `BuildDeckPhase` sleeps + canvas/table forge-ornament hooks (`tableForgeEnergy` / `tableRimBurst` + any forge-point ornament). **May not:** touch the crack engine; `tableFade` recede stays director-owned.
- **Feel-first:** retime in a reference — no guessed sleep values.

### S4 · Wake ↔ arrival sync
- **One thing:** drive `latticeWakeStart` so the hex lattice **ignites during the flat→vertical rise and peaks at the invitation + first strike**, holding vibrancy through "Break it open." (today it peaks ~t168, ~3 s before the CTA, then dims).
- **Done (device):** the case is at its most alive exactly when the dealer says "Break it open." and when the user strikes — never dimming into the CTA.
- **Constraints:** `BuildDeckPhase` (`latticeWakeStart` + rise timing) + `MetallicCaseView` (wake/pose drivers only). **May not:** change the crack engine.

## Reused / dies

- **Reuse:** `VaylCardCarousel` (as in ContextPhase), `MetallicCaseView` bloom/dissolve + pose, `FoilDeckTheme` / `openerDeckType`, `LiftHalo`, shared letterhead with `FounderLetterPhase`.
- **Dies:** the post-shatter void; the auto-advance-to-letter immediately after the third crack; the dark-flat dead-metal dwell.

## Reduce Motion
Reveal + arrival: cross-dissolve to the resolved state (deck present, named). Carousel: static but browseable. Letter handoff + final dissolve: opacity-only, `reduceMotionSafe`.

## Out of scope (later passes)
Real per-`openerDeckType` starter-prompt card **content** (ships against placeholders here). Finale signature write-on + descent/fade coordination = **S5** (separate). Demo/Name copy + re-teach = **S8/S9**.
