# Desire reveal — constellation coordination + locked-row restyle (2026-07-05)

Brainstormed with the human. Decision settled; this is the build spec. Follow-on to
`docs/superpowers/specs/2026-07-04-desire-map-starfield-and-answer-pill-design.md`.

## Problem

Testing the reveal ceremony's teaser beat (beat2/3 — one free match lit, the rest dim, a
locked-matches list below) surfaced two coordination bugs:

1. **Constellation stars read as disconnected.** `DesireConstellationView.lineDrawn(_:)`
   returns `false` for both `.intro` and `.teasers` modes — during the teaser beat, every
   star (hero + locked) floats independently with no line between any of them, when the
   whole point of a constellation is that they're one connected sky.
2. **The locked-matches list repeats the same signal four times.** Every row in
   `_LockedSection` (in `DesireRevealView.swift`) shows a `lock.fill` icon next to blurred
   text — but the blur alone already reads as "locked, not yet visible." Four identical
   padlocks in a row is noise, not information. The rows also use `AppRadius.md` and a flat
   fill with no accent, out of step with the "Card Weight" pill language just built for the
   rater ([DesireAnswerPill](../../../Vayl/Features/Desire%20Map/Views/Components/DesireAnswerPill.swift)).

## Decision

**Constellation (teaser beat):** draw lines between every star during `.teasers`, at a
dimmed opacity distinct from the confident post-reveal line weight. Star brightness logic
(`starState` — hero lit, locked dim) is already correct and stays untouched; this is purely
adding the missing connective lines, dimmed to signal "part of the same sky, not yet
confirmed."

**Locked list rows:** a new sibling row style, not a literal reuse of `DesireAnswerPill`
(that component is built for tappable answer selection — hint text, checkmark morph,
weight-driven color — none of which applies to a static locked preview row). The new style
borrows `DesireAnswerPill`'s materials only: `AppRadius.xl` corners, the same top-sheen
gradient cap, and a dim white orb accent (the same blur+core recipe as `DesireAnswerPill`'s
`.probablyNot` state — no spectrum color, since the match's category is unrevealed).

Only the **first** row shows the `lock.fill` glyph. Every other row shows blurred text and
the orb accent, no icon — one lock establishes "these are locked," the rest rely on the
blur alone. The existing staggered entrance animation and the "N more aligned desires"
hairline caption underneath are unchanged.

## Out of scope

- `DesireMapListSheet.swift` (the full-map sheet's own locked rows) — not flagged, not
  touched.
- Timing/stagger values for the row entrance — unchanged.
- The "N more aligned desires" count logic — unchanged.
- `.intro` mode (beat1) — only the hero shows there; no lines needed since there's nothing
  else revealed to connect to yet.

## Segments (Vayl build protocol governs)

1. **Constellation line fix.** `DesireConstellationView.swift`: `lineDrawn(_:)` returns
   `true` for `.teasers`; line stroke opacity becomes mode-dependent (dim for `.teasers`,
   the existing confident value for `.resolved`/post-reveal `.assemble`).
   **Constraint:** no change to star reveal/brightness logic, telegraph, or `.intro`/`.assemble` timelines.
   **Done:** during the teaser beat, all stars (hero + locked) show connected by dim lines;
   the hero remains the only bright/lit star; confirmed on device.

2. **Locked row restyle.** `DesireRevealView.swift`: extract `_LockedSection`'s per-row
   content into a new private row view carrying the Card-Weight materials (radius, sheen,
   dim orb) with a `showsLock: Bool` flag wired so only index 0 passes `true`.
   **Constraint:** only the row's internal visual content changes — entrance animation,
   stagger timing, and the count/hairline footer are untouched.
   **Done:** only the first locked row shows a padlock; all rows share the new visual
   language; confirmed on device.
