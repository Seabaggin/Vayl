# Curiosity Compass Card Face — Design

**Date:** 2026-06-10
**Status:** Approved (brainstorm via visual companion, V3 gimbal selected)

## Problem

The CuriosityPhase sort-card face used a static binoculars illustration. It was the
only OB phase symbol that wasn't a machine the user operates — typewriter keys fire
on typing, radio dials turn with the drum pickers, controller buttons chord on drag.
An earlier floating-question-marks direction was killed for preview/simulator
performance.

## Decision

Replace binoculars with a **gimbaled ship's compass** whose needle is driven by the
keep/pass swipe itself.

Metaphor branching: curiosity → seeking direction / not knowing what you want →
compass. The pile's card texts ("I don't know what I actually want") are literally
answered by a needle finding its bearing.

Rejected alternatives: resonance gauge (strong family fit, less poetic), radar sweep
(too techy for the parlor-vintage family), lantern (beam is a fill, violates the
1D-outline contract; overlaps the ExperienceLevel candle).

## Behavior

Deflection `d ∈ [-1, 1]` = horizontal drag ÷ commit threshold (95pt), clamped.

| Layer | Rotation | Notes |
|---|---|---|
| Needle | `d × 55°` | leads the gesture |
| Dial card (ticks + N) | `d × −27.5°` | counter-rotates, parallax |
| Outer gimbal ring | `d × 22°` | tilts with the drag |
| Bowl rings + hub | static | |

- Rotations applied via `.rotationEffect` on separate Canvas layers, so the
  director's `AppAnimation.cardSettle` snap-back springs the needle home for free.
- Dealer demo swipes animate the same `curiosityDragOffset`, so the tutorial
  demonstrates the compass without extra code.
- Only the top card (and flying card, held at ±1) carries content; deeper cards are
  shells. No idle/ambient animation — drag-reactive only (perf constraint).

## Visual

- 1D outline only, two passes (blurred glow + crisp), all strokes spectrum gradient
  (`spectrumCyan → spectrumPurple → spectrumMagenta`).
- Needle: north dart `spectrumCyan`, south dart `spectrumMagenta` (explicitly NOT
  red — user direction), reduced opacity on south.
- All geometry proportional to the illustration zone; no fixed pixels.
- Card layout unchanged: top 44% illustration, bottom 56% topic text.

## Code changes

1. `CuriosityCardFace.swift` → deleted; new `CompassCardFace.swift` in
   `Design/Components/Cards/CardFaces/`. (Note: `CompassSliderCardFace` /
   `CompassOptionCardFace` belong to CompassPhase — unrelated; naming follows the
   object convention like TypewriterCardFace.)
2. `VaylCardContent.curiosity` gains `deflection: Double = 0`.
3. `CuriosityPhase` feeds deflection for the top + flying cards.

Out of scope: VaylDirector, pile physics, card shell, other phases.
