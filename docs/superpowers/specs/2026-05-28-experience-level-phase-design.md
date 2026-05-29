# ExperienceLevelPhase — Design Spec

**Date:** 2026-05-28
**Phase position:** after ModeSelectPhase → advances to ContextPhase
**Question it asks:** *Where are you in this lifestyle?*

A "Three Card Monte" mechanic: deal three cards face-down → organize into a
clean row → shuffle (theatre, 3–4s) → flip in succession revealing
Curious → Exploring → Experienced → tap to pick → swipe up to confirm →
`director.advance(to: .context)`. Each card reveals a `CandleCardFace` at one of
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

**Visual source of truth:** [`docs/mockups/real-card-scale.html`](../../mockups/real-card-scale.html)
— the validated v12 candle. The Swift `Canvas` is a **verbatim port of its
`drawFrame`**, function-for-function. The numbers below come from that file
(`getGeo`, line 46), *not* the original Full Spec (whose 0.18/0.35 outline
figures are superseded).

**Geometry (proportional to card size, from the validated mockup):**
```swift
// getGeo — body
candleBodyW = cardWidth  * 0.33     // bW
candleBodyH = cardHeight * 0.46     // bH
bodyTopY    = cardHeight * 0.28     // bY
cx          = cardWidth  / 2
wickH       = candleBodyH * 0.072

// Per-intensity flame + behavior live in FLAME_CFG (mockup lines 41–45):
//   curious     baseH 0.20, swayAmp 0.58, dim, smoke wisp, no drips
//   exploring   baseH 0.42, swayAmp 0.12, steady, wax pool, side run
//   experienced baseH 0.42, swayAmp 0.14, notched flame, wax pool + 4 wax drips
// flameH = candleBodyH * cfg.baseH ; flameW = candleBodyW * cfg.baseW
```

**Rendering model (v12 — a sanctioned exception to the outline-only OB rule):**
- The candle is the phase's one ambient hero symbol and was visually validated
  with fills, so it is an explicit, self-contained exception to CLAUDE.md's
  "1D outline only — no fills." Fills are confined to this file.
- Spectrum gradient (cyan #00C2FF → purple #6C3AE0 → magenta #FF006A) on every
  stroke and gradient.
- Multi-pass draw order exactly as `drawFrame`: ambient warm glow → blurred flame
  glow → blurred body glow → (curious cylinder fill) → crisp body stroke → top
  rim → wax pool → texture lines → side runs → ember → wick → crisp flame edges →
  inner core → tip glow → (curious smoke wisp / experienced wax drips).
- All absolute px values in the mockup are scaled by `S = cardWidth / 160` so the
  port is resolution-independent (the mockup already does this).

**Flame motion (the only per-frame-varying part):** `fbm(noise)` sampled at
`time` drives sway, flicker, height-mod, and breathe exactly as mockup lines
54–60. Curious also has the `0.88 → 1.0` ambient scale pulse. Body, wick, wax,
drips are static geometry; only flame control points and the ember/tip pulses
move.

**`time` is passed in, not owned.** One phase-level `TimelineView(.animation)`
produces a single clock; all three faces read the same value. This avoids three
unsynchronized timers each scheduling their own redraw (3× cost once all cards
are revealed face-up in the row).

Under Reduce Motion: parent passes a frozen `time` → flames render static at a
representative phase, Curious pulse disabled.

---

## Section 3 — Choreography (`CardThreeMonte.swift`)

All deal/organize/shuffle/flip/lift/confirm logic lives in a dedicated controller
in `CardPhysics`, modeled directly on the proven
[`CardMirrorDeal.swift`](../../../Vayl/Design/Components/Cards/CardPhysics/CardMirrorDeal.swift)
pattern. **No Monte state lives on `VaylDirector`** — the director's only
involvement is `advance(to: .context)` fired from the controller's `onConfirm`.

This follows the same ownership split CardMirrorDeal established:
- **Controller owns:** deal animation, organize, shuffle, flip, lift, confirm,
  reject, all card transforms, haptic triggers.
- **Caller (`ExperienceLevelPhase`) owns:** card content, the flame clock, phase
  advancement (forwarded to the director).

### Engine boundary — face-down vs face-up

```
CardFlightScene (SpriteKit textures, face-down)   SwiftUI live views (face-up)
  deal 3 backs in   →   ┊HANDOFF┊   →   organize · shuffle · flip · candles · pick · confirm
```

- **CardFlightScene does the deal-in travel only.** Three `dealCard` calls fly
  card-*back* textures from the dealer point to the row. Static textures are
  correct here because the cards are face-down. Each call passes
  `zPosition = dealIndex` (deal 1 → 0, deal 2 → 1, deal 3 → 2).
- **Everything after the deal is owned by `CardThreeMonteController`** in the
  SwiftUI layer — organize, the 3–4s shuffle, the flip, lift, and confirm. The
  shuffle is the whole reason this file exists.

### Deal-order z-invariant

A card's stacking depth is fixed the instant it is dealt and **never changes**
through organize + shuffle + flip: the 1st-dealt card always renders *beneath*
the 2nd and 3rd. Cards may physically overlap/rest on each other, but the 1st
can never sit on top. Carried from CardFlightScene's `zPosition` into the SwiftUI
layer as a permanent per-card `zIndex`.

**One exception:** the lifted (picked) card rises above all others while held.
When the other two fold back down, deal-order z resumes for them.

### Identity assigned at reveal — no shuffle tracking

Because the shuffle is pure theatre with no "real" card to follow, the three
nodes are anonymous backs during deal + shuffle. **Candle identity is assigned
only at the flip (step 4).** This eliminates all "which card is which" tracking
through the swaps. The flip reveals **Curious → Exploring → Experienced in
succession, always resolving to a clean left→right ordered row** (Curious left,
Exploring center, Experienced right) regardless of where the shuffle left things.

### Canonical row geometry (the reference frame — define first)

The "clean row" is the canonical coordinate frame that **every** subsequent step
references: organize snaps to it, shuffle swaps between its slots, flip lands on
it, lift/dismiss are computed relative to it. It must exist before any card moves.
Because it's geometry, it lives in `AppLayout` (alongside `obTableCardWidth`),
not invented inside the controller.

```swift
// AppLayout
/// X-centers (absolute, in container coords) of the three Monte row slots.
/// Slot 0 = left, 1 = center, 2 = right. These are the reference coordinates
/// shuffle swaps between and organize snaps to.
static func monteRowCenters(in containerWidth: CGFloat) -> [CGFloat] {
    let cardW = obTableCardWidth(in: containerWidth)   // ~118 on a 393pt phone
    let pitch = cardW + AppSpacing.sm                  // slot-to-slot distance; sm(8) = small gap
    let mid   = containerWidth / 2
    return [mid - pitch, mid, mid + pitch]
}
```

- **Pitch = `obTableCardWidth + AppSpacing.sm`** keeps the row edge-to-edge with a
  small gap. Because `obTableCardWidth` scales with screen width (`width * 0.30`,
  clamped), the row stays on-screen with consistent margins from SE (320pt) up —
  verified: rightmost edge fits within an 8pt margin on a 320pt container.
- The `AppSpacing.sm` gap is the one **feel value to tune on-device** at Segment 5
  (tighter for a denser deal, looser for breathing room). Everything else is
  derived, not guessed.
- **Lift / dismiss derive from this frame:** the lifted card animates to
  `mid` (center) at cinematic scale; the two dismissed cards fold back toward
  their own row slots (or the deal origin) — no independent coordinates.
- Row Y-center comes from the existing `AppLayout.obTableCardCenterY(in:)`, the
  same anchor CardMirrorDeal uses.

### Shuffle motion — lift-and-toss

There are no rendered hands; "real monte" is emulated entirely through card
motion. The shuffle uses a **lift-and-toss** model rather than flat sliding:

- As a card swaps slots, its `elevation` ramps `0 → 1 → 0` across the move — it
  lifts off the felt, crosses, and drops into the new slot. Elevation drives a
  small scale bump (~1.0 → 1.06) and `AppElevation.cardShadow(elevation:)` so the
  shadow grows and softens as the card rises (the depth cue that sells the toss).
- Cards cross in **arcs**, not straight lines — the lifted card travels a shallow
  curved path over the others. The deal-order `zIndex` decides who passes over
  whom; a lifted card still obeys its permanent z (a lifted 1st-dealt card crosses
  *under* a resting 3rd, which is what keeps the stack honest).
- 3–4 seconds, several swaps. Pure theatre — no identity tracked (see below).
- All swaps return every card to a `monteRowCenters` slot before the reveal, so
  the row is clean and ordered when flipping starts.
- **Tune on-device (Segment 9):** lift height / scale-bump amount, arc curvature,
  per-swap duration, number of swaps. These are feel values — start conservative,
  feel it, adjust.

### Controller shape (mirrors `CardMirrorDealController`)

```swift
enum ThreeMonteState: Equatable {
    case idle, dealing, organizing, shuffling, revealing, faceUp
    case lifted(CandleIntensity), confirming(CandleIntensity), done(CandleIntensity)
}

@Observable @MainActor
final class CardThreeMonteController {
    var state: ThreeMonteState = .idle

    // Per-card transforms — three of each (vs MirrorDeal's two).
    var offsets:    [CGSize] = [.zero, .zero, .zero]
    var angles:     [Double] = [0, 0, 0]
    var scales:     [Double] = [1, 1, 1]
    var alphas:     [Double] = [0, 0, 0]
    var flipScaleX: [Double] = [1, 1, 1]   // face-down (1) → mid (0) → face-up
    var showFace:   [Bool]   = [false, false, false]
    var elevations: [Double] = [0, 0, 0]   // 0 flat → 1 lifted; drives scale bump + AppElevation.cardShadow
    var zIndices:   [Double] = [0, 1, 2]   // permanent deal-order stacking
    var confirmHapticTrigger: Bool = false

    // deal(): CardFlightScene 3× (face-down backs) → onCardRested settles state
    // organize(): align to clean row (the reference image)
    // shuffle(): 3–4s theatrical position swaps, z-invariant held
    // reveal(): flip in succession → assign Curious/Exploring/Experienced L→R
    // lift(_:) / confirm(_:onLanded:onConfirm:) / cancel()  — as in MirrorDeal
}
```

### Flame clock — owned by the View, not the controller

The controller holds no per-frame state. The phase's `TimelineView(.animation)`
produces one `time` value and passes it to all three `CandleCardFace`s. **Zero
per-frame `@Observable` writes** — the core reason for this architecture
(Approach A). Under Reduce Motion the View passes a frozen `time`.

### `VaylDirector` touch points (minimal)

- `runExperienceLevelEntry()` (the empty stub at `VaylDirector.swift:197`) →
  resets/creates the controller for a clean entry.
- Controller's `onConfirm` → director writes `onboardingData.nmStage` from the
  chosen `CandleIntensity` and calls `advance(to: .context)` — **the only phase
  gate**.

---

## Section 4 — Build Protocol segments

Each segment does one thing, has an on-device done condition, and a
files-it-may-not-touch constraint. Two arcs: **build the candle (static → alive),
then build the Monte controller around it.** The screen is functional end-to-end
by Segment 6; Segments 7–9 layer the deal/shuffle/reveal spectacle on top.

| # | Does | Done when (on-device) | May not touch |
|---|------|------------------------|---------------|
| 1 | `CandleCardFace.swift` — port `drawFrame` body+flame skeleton for `.exploring` (static `time=0`): getGeo, body path, crisp body stroke, flame edges. `#Preview` at 177pt | Side-by-side with mockup `.exploring` at 177pt: body + flame match | controller, phase, shells |
| 2 | Port remaining v12 passes + all three `CandleIntensity` cases: curious (fill, smoke), exploring (rim, pool, side run), experienced (notch, pool, 4 drips, texture) | All three match the mockup and are distinguishable **at 118pt** | controller, phase |
| 3 | Wire `time` param → fbm sway/flicker/breathe (mockup 54–60); Curious pulse 0.88→1.0 | Flames flicker smoothly matching the mockup loop, no stutter | controller, phase |
| 4 | Reduce Motion: frozen-`time` static flame, pulse off | Reduce Motion on → candles still + legible | controller, phase |
| 5 | Add `AppLayout.monteRowCenters(in:)` (the canonical frame). Rewrite `ExperienceLevelPhase.swift`: render 3 `VaylCardFace` shells at those centers, table size, each with a `CandleCardFace`; View `TimelineView` flame clock. New `CardThreeMonte.swift` controller starts in `.faceUp` (cards present, ordered L→R). No deal/shuffle/flip yet | Three live candle cards in a clean row at the canonical centers, on the real phase; gap (`AppSpacing.sm`) tuned on-device | candle file, shells, `advance()` |
| 6 | Controller `lift` + `confirm`: tap lifts chosen card above all (z-exception) + folds others; swipe-up → `onConfirm` → director writes `nmStage` + `advance(to: .context)`; haptics | Tap → lift → swipe up → lands in ContextPhase. Screen works end-to-end | candle file, shells, other phases |
| 7 | Controller `reveal`: cards start face-down; flip in succession assigning Curious→Exploring→Experienced, resolving to ordered L→R row | Cards begin face-down, flip in succession, land ordered, right feel | candle file, lift/confirm |
| 8 | Controller `deal`: CardFlightScene 3× flies backs from dealer point, deal-order `zPosition`; `onCardRested` → controller `.dealing`→`.organizing` | Deal feels like a Monte deal; 1st-dealt stays underneath | candle file, lift/confirm/reveal |
| 9 | Controller `organize` + `shuffle`: settle to `monteRowCenters`, then 3–4s **lift-and-toss** swaps between slots (elevation 0→1→0 + scale bump + `cardShadow`, arced crossings), z-invariant held, then hand to reveal | Organize snaps to the canonical row; lift-and-toss reads convincingly for 3–4s (lift height / arc / timing tuned on-device); flip still lands ordered | everything prior frozen |

**Files:**
- `CandleCardFace.swift` — **create** in `CardFaces/` (alongside `ControllerCardFace`, `TypewriterCardFace`)
- `CardThreeMonte.swift` — **create** in `CardPhysics/` (the `CardThreeMonteController`; CardMirrorDeal is the template)
- `ExperienceLevelPhase.swift` — **rewrite** (currently a stub; thin View + flame clock)
- `VaylDirector.swift` — **minimal touch** (`runExperienceLevelEntry` stub at line 197 wires up the controller; `onConfirm` → `nmStage` + `advance`)
- `CardFlightScene.swift` — **read-only / reuse** (deal-in travel; only extend if true arcs are wanted later)

---

## Section 5 — Reduce Motion & performance

**Reduce Motion** (controller branches on `reduceMotion`):
- Flames freeze, Curious pulse off (Segment 4).
- Deal/organize/shuffle → skip the theatrical swaps; cards place directly into
  the clean row (a short fade), then flip in succession. The *mechanic* (choose
  your level) survives without the motion spectacle.
- Lift-on-pick → opacity/scale snap, not a sprung rise.
- `.ambientAnimation()` on the one looping animation (Curious pulse).

**Performance — the gate that decides Metal:**
- Verify on a **real device** (Canvas + fbm differs from simulator).
- Worst-case frame: **post-reveal**, all three live flames animating in the row
  (during deal/shuffle the cards are flameless SpriteKit backs — cheap). Profile
  the three-flame steady state, plus the lift transition. Profile there.
- If it holds 60/120fps → stay in pure SwiftUI Canvas (expected outcome).
- If it drops frames → move **only** the blurred glow pass to a Metal
  `.layerEffect` (precedent: `HolographicShimmer.metal`, `VaylBorderEffect`);
  keep all vector geometry in Canvas. No pre-optimization.

---

## Architecture contracts (from CLAUDE.md)

- `ExperienceLevelPhase` is a View — renders from controller state, forwards
  taps, owns the flame clock only.
- Deal/shuffle/selection state lives in `CardThreeMonteController` (CardPhysics),
  not the View and not the director — same ownership split as `CardMirrorDeal`.
- `director.advance()` is the only phase gate (fired from the controller's
  `onConfirm`).
- No fixed pixels — all geometry proportional to cardWidth/cardHeight.
- `VaylCardFace` shell used for all three cards; no View writes to
  `VaylCardModel`.
- No View calls a Service or database directly.
- All looping animation wrapped in `.ambientAnimation()`; Reduce Motion
  fallbacks throughout.
