# Desire Map reveal ceremony — design

Date: 2026-06-27
Status: approved in prototype, ready for implementation planning
Feel references (approved on device):
- `docs/prototypes/desire-map-match-ceremony.html` — the two-seed star merge (the DNA)
- `docs/prototypes/desire-map-ceremony-variants.html` — the three telegraphed ceremonies, resolving into the real screen-10 look
- `docs/prototypes/desire-map-constellation-engine.html` — one generator handling any match count with shape variety

## Goal

Give the Desire Map reveal an earned, telegraphed ceremony that resolves into the existing "Your shared sky" constellation. It must:
- feel relational, not transactional (it is the paywall payoff),
- vary across couples so a new partner or a watched friend does not see the same thing,
- work for any match count (1 to 17) from one generator, with no hand-authored shapes,
- collapse to a dignified static state under Reduce Motion.

## Settled decisions (locked)

1. **The star is born from a two-seed merge.** Each shared desire star resolves from two faint seed points (your purple, their partner-magenta) drifting together and blooming into one bright white-cored star. This is the constant DNA in every variant and at every count. Stays in the desire colorway (magenta to purple, never cyan).
2. **Lines are smooth solid strokes that draw to produce the shape.** No dashes. A line draws once both its endpoints are lit. (The prototype's dashed look was a `pathLength` rendering bug; the real draw uses each line's geometric length for the dash offset.)
3. **The constellation is generated, not authored.**
   - Positions: a seeded golden-angle (phyllotaxis) spiral, perturbed by the couple seed (rotation + jitter + slight aspect squash). Even spread, no crowding, deterministic per seed.
   - Shape: a minimum spanning tree over the points (always one connected figure, never a web) plus one or two short extra links for richness.
   - Hero: the point nearest the centroid renders larger; it is the free-reveal star.
4. **Three telegraphed variants, picked by the couple seed.** Gather (stills, pulls light to center, hero forms, the rest radiate outward). Sweep (a soft band passes; pairs snap together in its wake, in spatial order). Constellate (all seed pairs appear, a held beat, then everything merges at once). The variant only sets the telegraph and the lighting order; it composes with any count and any seed.
5. **Seeded per couple.** A hash of `coupleId` picks both the layout seed and the variant index (0/1/2). No new storage. Re-pairing reshuffles naturally.
6. **Time is budgeted, size scales with count.** Per-star stagger shrinks as count grows (fixed assembly budget), so ten stars do not drag. Star size scales down with count. 1 match = a lone star, no lines, singular caption; 2 = a single link.
7. **Scope: the variant flavors the climactic full-sky assembly** — the moment the whole constellation lights, which is post-unlock for a free couple or immediate for an already-Core couple. The intimate beat-1 free star (the "you both marked this" opener) stays constant across variants: it always plays the single two-seed merge, no telegraph. The free funnel and the quiet first touch do not change.
8. **Reduce Motion** resolves instantly to the lit constellation with connected lines, no movement, identical end frame for all variants.

Out of scope here (tracked separately): retiring the dead `.ready`/readyBar (screen 5), and giving the "Everything you said" solo summary a post-reveal home.

## Architecture and components

Designed so each unit has one job, a clear interface, and can be tested or understood alone.

### 1. ConstellationLayout (new, pure — Model/util layer)
A pure function, no SwiftUI, fully unit-testable.

```
enum ConstellationLayout {
    struct Result { let points: [CGPoint]   // normalized 0...1
                    let edges: [(Int, Int)]
                    let heroIndex: Int }
    static func generate(count: Int, seed: UInt64) -> Result
}
```
- Deterministic: same (count, seed) yields the same result.
- Seeded RNG (e.g. SplitMix64) for rotation, jitter, aspect, and extra-edge choice.
- Phyllotaxis positions + Prim MST + short extras (threshold = ~1.35x mean MST edge length).
- `count == 0` returns empty; `count == 1` returns a single centered point, no edges.

### 2. CeremonyVariant (new — small enum + config)
```
enum CeremonyVariant: Int, CaseIterable { case gather, sweep, constellate
    static func resolve(coupleId: UUID) -> CeremonyVariant  // hash -> case
}
```
Each variant maps to an assembly config consumed by the field: telegraph kind, lighting-order rule (centroid-out / sweep-axis / simultaneous), and whether seeds pre-show (Constellate).

### 3. DesireStarView (extend the existing atom)
Add a "two-seed ignite" entrance. New input `ignites: Bool` (and it reads Reduce Motion).
- Two seed sublayers (cool = `AppColors.spectrumPurple` or the lighter flourish tint; warm = `AppColors.spectrumMagenta`) shown only during the entrance.
- On first becoming lit with `ignites && !reduceMotion`: seeds drift from a proportional offset to center and fade while the unified halo/glow/cross/core scales 0.2 -> 1 with overshoot and the sparkle pings.
- `ignites == false` or Reduce Motion: renders exactly as today (lit, no seeds).
- Geometry proportional to `size`; colors via `AppColors` only; do not add `.drawingGroup()`.

### 4. ConstellationField (extend)
- Consume `ConstellationLayout.Result` instead of computing its own phyllotaxis, and draw `edges` (MST + extras) instead of proximity pairs.
- Lines: smooth solid draw using each line's length for the dash; draw when both endpoints lit.
- Drive the lighting order + per-star stagger from the resolved `CeremonyVariant`; stagger = assemblyBudget / count (clamped); star size scales with count.
- Telegraph layer (gather pulse / sweep band) gated by variant and Reduce Motion.

### 5. DesireRevealStore / DesireRevealView (wire)
- Resolve `seed` and `CeremonyVariant` from `appState.coupleId` once, hand them to the field.
- The existing `BeatPhase` stays the controller: beat-1 lights the hero free star (constant two-seed merge, no telegraph); the `.revealed` state runs the full telegraphed assembly. Locked-teaser beats and the paywall are unchanged.

### 6. AppAnimation (tokens)
Port the approved curves: `desireStarMergeSettle = .timingCurve(0.34, 1.3, 0.5, 1, duration: 0.56)` (bloom), the seed drift, the line draw `.cubic-bezier(0.45, 0, 0.25, 1)` ~0.64s, plus telegraph durations (gather pulse, sweep). Reuse stagger tokens. Each documents its Reduce Motion fallback.

## Data flow

`coupleId` -> (seed, variant) -> `ConstellationLayout.generate(count, seed)` -> field renders stars (DesireStarView) at points and lines along edges -> `BeatPhase` drives: beat-1 hero merge, `.revealed` runs the variant's telegraph + ordered two-seed merges + line draws -> resolves to the static "Your shared sky".

## Edge cases

- **0 matches:** existing `.empty` state, unchanged.
- **1 match:** lone hero, no lines, "1 desire you share", no Full-map pill.
- **2 matches:** two stars, one link.
- **Many (to 17):** smaller stars, labels on the hero (tap reveals others), tighter stagger, capped extra edges.
- **Already-Core couple:** skips straight to the full assembly (no paywall), stamps full-seen.

## Testing

- Unit-test `ConstellationLayout`: determinism per seed; connectedness (every node reachable); correct counts for edge cases (0/1/2); no out-of-bounds points; hero is a valid index. (VaylTests; remember pbxproj wiring for new test files.)
- Unit-test `CeremonyVariant.resolve` determinism per `coupleId`.
- Animation feel is verified on device against the three prototypes (Bryan).

## Build segments (preview; full plan in the implementation plan)

1. **ConstellationLayout** generator + unit tests (pure, no UI).
2. **DesireStarView** two-seed ignite entrance + AppAnimation tokens (Reduce Motion fallback).
3. **ConstellationField** consumes the generator + MST line draw + size/stagger by count.
4. **CeremonyVariant** presets + `coupleId` seeding, wired through DesireRevealStore/View assembly (the three telegraphs).
5. **Reduce Motion + device tuning** pass.

Each segment is build-verified by Claude (xcodebuild) and feel-confirmed by Bryan on device before the next begins. Files NOT touched: the rater (`DesireMapView`/`_StarAccum`), `PaywallSheet`, `DesireMapListSheet`/`DesireMatchDetail`, the `BeatPhase` sequence/timing, `VaylCardFace`, director/`tableFade`.
