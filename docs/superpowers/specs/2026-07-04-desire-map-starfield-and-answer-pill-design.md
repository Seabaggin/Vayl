# Desire Map — starfield consistency + answer pill redesign (2026-07-04)

Brainstormed with the human. Decision settled; this is the build spec. Visual reference:
`docs/prototypes/desire-map-visual-improvements.html` (option comparison) +
`docs/prototypes/desire-map-final-mockup.html` (finalized target).

## Problem
Two gaps in the Desire Map flow:
1. The ambient starfield (`_bgStars` + `Canvas` in `DesireMapView.swift`) only renders on the
   `.start` phase, so the rating/charted/mirror screens and the reveal's beat-reveal ("Where you
   meet") go flat by comparison to the intro screen.
2. `_RaterPill`'s answer rows are visually thin, and worse, the selected-state tint is hardcoded
   to `spectrumMagenta`/`spectrumPurple` regardless of which answer is chosen — a real bug, not a
   style choice. The mockup's per-answer coloring (cyan/purple/dim/magenta, matching each row's
   own spectrum position) has never actually landed in Swift.

## Decision

**Starfield** — wire the existing dust-field into every Desire Map screen it's currently missing
from: `DesireMapView`'s `.rating`/`.charted`/`.mirror`/`.ready` phases, and `DesireRevealView`'s
beat-reveal. Extract the shared star dataset + render logic out of `DesireMapView` into one small
reusable view so both files use the same thing instead of duplicating a 44-tuple array.

**Answer pill** — replace `_RaterPill` with a new "Card Weight" design (Option C from the mockup):
glow-orb leading accent (per-answer color), bigger lifted rows with a soft top sheen, lift +
accent-tinted shadow bloom on select, hint text morphs into a filled confirm checkmark. The
selected-state color is per-answer now, fixing the hardcoded-tint bug.

**Stays its own component.** Considered folding this into `SelectablePill` (the existing
selectable-option pill used in onboarding/settings) — rejected. SelectablePill is a centered
single-label capsule with no icon/hint slot and no per-instance accent color (its glow always
pulls from the global `accentPrimary`/`accentSecondary`/`accentTertiary` tokens); making Option C
fit would mean rewriting internals three other screens already depend on, not extending them. New
component: `DesireAnswerPill`, living in `Vayl/Features/Desire Map/Views/Components/`.

## Out of scope
- `SelectablePill` itself — untouched, no new variant added.
- Consolidating the 5 duplicate press-style structs found during this pass (`_RaterPressStyle`,
  `_DetailPressStyle`, `_PressScaleStyle`, `CiteButtonStyle`, `PressableCardStyle`) — real
  duplication, but a separate cleanup, not part of this build.
- `SelectablePill`'s stale `@Environment(\.colorScheme)` light-mode branches (violates the current
  V1 dark-only rule) — noted, not fixed here.
- `VaylButton` — untouched; it's a single full-width CTA, a different job from option selection.

## Segments (Vayl build protocol governs — one segment ships + gets a device pass before the next)

1. **Starfield wiring.** Extract `_bgStars` + its render logic out of `DesireMapView` into a
   shared `DesireStarfield` view (Reduce Motion / Low Power static-frame fallback preserved
   as-is). Use it (a) unconditionally in `DesireMapView` — remove the `raterPhase == .start` gate
   — and (b) newly in `DesireRevealView`'s beat-reveal background.
   **Constraints:** do not touch `_RaterPill`, `DesireConstellationView`, or the foreground
   `_StarAccum`/`_AccumStar` stars — this only adds the background dust layer.
   **Done:** rating/charted/mirror/reveal screens all show the same ambient dust as the intro
   screen; foreground accumulating stars and the constellation still read clearly against it;
   confirmed on device.

2. **Answer pill redesign.** New `DesireAnswerPill` component (Option C treatment, per-answer
   spectrum color) replacing `_RaterPill` in `DesireMapView`'s rater.
   **Constraints:** only touches the rater's answer list — no change to question transitions,
   star-rise sync, or the mirror/charted screens.
   **Done:** each answer's selected state tints in its own spectrum color, the row lifts with a
   matching shadow bloom, hint text swaps to a confirm checkmark; confirmed on device.
