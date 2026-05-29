# ExperienceLevelPhase — Design Spec

**Date:** 2026-05-28
**Phase position:** after ModeSelectPhase → advances to ContextPhase
**Question it asks:** *Where are you in this lifestyle?*

A "Three Card Monte" mechanic: deal three candle cards face-down with crossing
arcs → shuffle → flip all face-up → tap to pick → swipe up to confirm →
`director.advance(to: .context)`. Each card shows a `CandleCardFace` at one of
three intensities representing experience level.

This spec supersedes the original `ExperienceLevelPhase — Full Spec.md` on one
point only: **render fidelity**. The original called for static outline candles;
this design uses living, clock-driven flames (full "v12" fidelity) while keeping
the outline-only geometry contract intact.

---

## The Three Cards

| id | Label | Subtitle | Flame |
|----|-------|----------|-------|
| 0 | Curious | "Just found the door." | Weak, wavering, ambient pulse |
| 1 | Exploring | "A few rooms in." | Steady, medium |
| 2 | Experienced | "You know this place." | Tall, strong, wax drips |

Selection maps `id → NMStage`. `OnboardingData.nmStage` is a **single value**
(no A/B split) — together mode makes **one** pick. Simpler than GenderPhase's
two-spin branching.

---

## Section 1 — Scale (validated)

The codebase OB card aspect ratio is 3:2 portrait (`obCardHeight = obCardWidth
× 1.5`), which matches the mockup's aspect exactly. Therefore every proportional
fraction in the candle geometry translates with **zero aspect distortion** —
only the absolute point size changes.

- **Three-card Monte row:** each card at `AppLayout.obTableCardWidth` (~118pt
  wide on a 393pt phone).
- **Selected/lifted card:** `obTableCardWidth × obTableCardCinematicScale`
  (~177pt wide).

Validated against a true-scale mockup (`docs/mockups/real-card-scale.html`): all
three intensities remain distinguishable at the 118pt table size; the spectrum
stroke and glow pass survive the downscale. Wax-drip detail is subtle at 118pt
but the silhouette difference carries the signal; drips pay off on the lift.
**No Monte-specific scale override is needed.**

---

## Section 2 — `CandleCardFace` (renderer)

A pure SwiftUI `Canvas` view. No state of its own — `time` is injected.

```swift
enum CandleIntensity { case curious, exploring, experienced }

struct CandleCardFace: View {
    let intensity: CandleIntensity
    let time: Double          // shared flame clock, injected from the phase
    let reduceMotion: Bool
}
```

**Geometry (outline only, proportional — unchanged from original spec):**
```swift
candleBodyW = cardWidth  * 0.18
candleBodyH = cardHeight * 0.35
wickH       = candleBodyH * 0.06

flameH(.curious)     = candleBodyH * 0.38
flameH(.exploring)   = candleBodyH * 0.52
flameH(.experienced) = candleBodyH * 0.68

waxDrips(.curious)     = 0
waxDrips(.exploring)   = 0
waxDrips(.experienced) = 2–3 curved strokes descending from body top edge
```

**Rendering rules:**
- 1D spectrum gradient outline only — cyan → purple → magenta. No fills.
- Two passes per shape: blurred low-opacity **glow** + crisp full-opacity
  **stroke**.
- `strokeLineCap: .round` on flame curves, `.square` on body geometry.

**Reconciling fidelity with the outline rule:** body, wick, and wax drips are
static vector geometry. The flame is *also* outline-only, but its silhouette
control points are recomputed each frame from `fbm(noise)` sampled at `time`.
The geometry contract is untouched — only the flame's control points move.

- Curious: low sway amplitude + scale pulse 0.88 → 1.0 (`.ambientAnimation()`).
- Exploring: steady, minimal sway.
- Experienced: tall, stronger sway.

**`time` is passed in, not owned.** One phase-level `TimelineView(.animation)`
produces a single clock; all three faces read the same value. This avoids three
unsynchronized timers each scheduling their own redraw (3× cost when all cards
are on-screen during deal/shuffle).

Under Reduce Motion: parent passes a frozen `time` → flames render static at a
representative phase, Curious pulse disabled.

---

## Section 3 — Choreography (`VaylDirector`)

Mirrors the proven gender pattern (`runGenderEntry` / `startGenderSequence` /
`cancelGenderSequence`). Per-card visual state is bundled into one struct because
the Monte has three cards (gender animated one via flat offset vars).

**New state on the director:**
```swift
enum MonteStage { case idle, dealing, shuffling, revealed, picked, confirming }

struct MonteCardState: Identifiable {
    let id: Int                  // 0,1,2 — also the CandleIntensity index
    var offset:    CGSize = .zero
    var rotation:  Double = 0
    var flipScaleX: Double = 1.0  // face-down (1) → mid (0) → face-up
    var faceUp:    Bool   = false
    var lifted:    Bool   = false
    var dismissed: Bool   = false
}

var monteCards: [MonteCardState] = []
var monteSelectedID: Int? = nil
var monteFlameTime0: Date = .now      // flame-clock anchor (frozen under Reduce Motion)
var monteStage: MonteStage = .idle
var monteShouldPocket: Bool = false   // View observes → advance (mirrors genderShouldPocket)
@ObservationIgnored var experienceSequenceTask: Task<Void, Never>? = nil
```

**Lifecycle methods (same split as gender):**
- `runExperienceLevelEntry()` — *sync, router-owned* (replaces the empty stub at
  `VaylDirector.swift:197`). Cancels any task, resets `monteCards` to three fresh
  face-down states, `monteStage = .idle`, `monteSelectedID = nil`. Idempotent.
- `startExperienceLevelSequence(screenSize:)` — *async, View-lifecycle-owned*
  (`.onAppear`, never the router). Runs scripted beats as one `Task`: deal
  (crossing arcs) → shuffle (2–3 passes) → simultaneous flip → `monteStage =
  .revealed`. Each beat awaits its `AppAnimation` duration. Task ends at
  `.revealed`, awaiting input.
- `cancelExperienceLevelSequence()` — `.onDisappear`. Cancels + nils the task.

**User-input methods (called from View gestures):**
- `selectMonteCard(_ id:)` — sets `monteSelectedID`, marks that card `lifted`,
  others `dismissed`, `monteStage = .picked`.
- `confirmExperienceSelection()` — writes `onboardingData.nmStage` from the
  selected id, pockets the lifted card (`pocketToCornerDeck`), sets
  `monteShouldPocket = true`. View observes and calls `advance(to: .context)` —
  **the only phase gate**.

**Flame clock lives in the View, not the director.** The director stores only
`monteFlameTime0` + discrete state. The phase's `TimelineView(.animation)`
computes `time = now − monteFlameTime0` and passes it to the three faces. Under
Reduce Motion the View passes a frozen delta. **Zero per-frame @Observable
writes** — the core reason for this architecture (Approach A).

---

## Section 4 — Build Protocol segments

Each segment does one thing, has an on-device done condition, and a
files-it-may-not-touch constraint. Build the candle first (static → alive), then
the Monte around it. The screen is functional by Segment 6; Segments 7–9 layer
spectacle on top.

| # | Does | Done when (on-device) | May not touch |
|---|------|------------------------|---------------|
| 1 | `CandleCardFace.swift` renders `.exploring` candle, outline, two passes, static | Renders at 177pt, spectrum reads cyan→purple→magenta, no fills | director, phase, shells |
| 2 | Add `CandleIntensity` branches: flame heights, Curious no-drips, Experienced drips | Three distinguishable **at 118pt** | director, phase |
| 3 | Add `time` param + fbm flame sway; Curious pulse 0.88→1.0 | Flames flicker smoothly, no stutter | director, phase |
| 4 | Reduce Motion: frozen-`time` static flame, pulse off | Reduce Motion on → candles still + legible | director, phase |
| 5 | Rewrite `ExperienceLevelPhase.swift`: 3 `VaylCardFace` shells in a row at table size, each with a `CandleCardFace`; `runExperienceLevelEntry()` (3 face-up cards); View `TimelineView` flame clock. No deal/shuffle/flip yet | Three live candle cards on the felt at table size, on the real phase | candle file, `advance()` logic, shells |
| 6 | Pick + confirm: tap lifts + dismisses others; swipe-up writes `nmStage`, `monteShouldPocket`, `advance(to: .context)`; haptics. Add `selectMonteCard`/`confirmExperienceSelection` | Tap → lift → swipe up → lands in ContextPhase. Screen works end-to-end | candle file, shells, other phases |
| 7 | Flip reveal: cards start face-down; `startExperienceLevelSequence` flips all three simultaneously on appear | Cards begin face-down, flip up together, right feel | candle file, pick/confirm |
| 8 | Deal: crossing-arc paths from dealer point, arriving face-down | Deal feels like a Monte deal | candle file, pick/confirm/flip |
| 9 | Shuffle: 2–3 position-swap passes between deal and flip | Shuffle reads as Monte; flip still lands cleanly | everything prior frozen |

**Files:**
- `CandleCardFace.swift` — **create**
- `ExperienceLevelPhase.swift` — **rewrite** (currently a stub)
- `VaylDirector.swift` — **extend** (state + 5 methods; fill `runExperienceLevelEntry` stub at line 197)

---

## Section 5 — Reduce Motion & performance

**Reduce Motion:**
- Flames freeze, Curious pulse off (Segment 4).
- Deal/shuffle/flip → cross-fade or instant placement; cards still arrive
  face-down and flip, so the mechanic survives without motion paths.
- Lift-on-pick → opacity/scale snap, not a sprung rise.
- `.ambientAnimation()` on the one looping animation (Curious pulse).

**Performance — the gate that decides Metal:**
- Verify on a **real device** (Canvas + fbm differs from simulator).
- Worst-case frame: deal/shuffle, all three flames animating while cards are in
  flight. Profile there.
- If it holds 60/120fps → stay in pure SwiftUI Canvas (expected outcome).
- If it drops frames → move **only** the blurred glow pass to a Metal
  `.layerEffect` (precedent: `HolographicShimmer.metal`, `VaylBorderEffect`);
  keep all vector geometry in Canvas. No pre-optimization.

---

## Architecture contracts (from CLAUDE.md)

- `ExperienceLevelPhase` is a View — renders and forwards taps only.
- Selection state lives on the director, not the View.
- `director.advance()` is the only phase gate (via `monteShouldPocket`).
- No fixed pixels — all geometry proportional to cardWidth/cardHeight.
- `VaylCardFace` shell used for all three cards; no View writes to
  `VaylCardModel`.
- No View calls a Service or database directly.
- All looping animation wrapped in `.ambientAnimation()`; Reduce Motion
  fallbacks throughout.
