# StatPhase → NamePhase: Card Deal Animation Design

**Status:** Approved — pre-build
**Date:** 2026-05-16
**Scope:** The full animation sequence from StatView exit through card deal, flip, and expand into NamePhase

---

## Context

This spec covers the transition from `StatPhase` through the card deal sequence into `NamePhase`. The sequence replaces the old BrandView approach. There is no prescreen or calibration phase — the sequence begins at StatView.

The target feel is **Harry Potter magic**: the card landing is chaotic and physical (earned realism), then the auto-organize is impossibly smooth — like an invisible hand guiding it. The contrast between mess and impossible precision is the magic beat.

Reference HTML prototype: `Vayl OB Sequence — Complete Spec v2.md` (StatView → BrandView → NameView 1 section)

---

## Architecture

**Approach:** Hybrid — SwiftUI drives card position/transform/flip, Canvas handles table surface and atmosphere. `VaylCardBack` and `VaylCardFace` render as native SwiftUI views. `TableSurfaceView` receives a new `rimBurst` parameter for the impact glow.

**Phase ownership:**
- `VaylDirector` owns macro phase state: `.statView` → `.nameInput`
- The card deal animation sequence is the opening beat of `NamePhase` — `NamePhase` owns the full arc from card entering to name submission
- A local `CardDealPhase` state machine inside `NamePhase` owns sub-animation state
- No child view advances `VaylDirector` directly — all dispatch intents

---

## Section 1 — Animation State Machine

```swift
enum CardDealPhase {
    case idle
    case dealing       // card in flight from dealer position
    case landing       // card hits table — rimBurst fires here
    case organizing    // card auto-drifts and rotates to center
    case settled       // placeholder copy beats play
    case flipping      // back → front, automatic after 1.2s timer
    case expanding     // card scales to fill screen
    case nameInput     // UI active — user types name, swipe-down to submit
}
```

**Random seed:** Landing angle and offset are generated once when `.dealing` starts and stored as local `@State`. Values are consistent if the animation replays within a session.

**Auto-advance timer:** On `.settled`, a `DispatchQueue.main.asyncAfter(1.2s)` fires to advance to `.flipping`. No user input required.

**No director handoff mid-sequence:** `NamePhase` is already the active macro phase. `VaylDirector` only advances (→ `.genderInput`) when the user submits their name from `.nameInput`.

---

## Section 2 — Card Physics

### Deal (in-flight)

Card originates off-screen top-right (~110% x, -15% y).

Randomized per deal:
- Landing rotation: `CGFloat.random(in: -7...7)` degrees
- Landing offset: random within ~40pt radius of center — never perfectly centered

Rotation and offset animate with slightly different spring responses so they don't arrive simultaneously — the card naturally tilts as it decelerates, which reads as realistic in-flight physics.

```swift
Animation.interpolatingSpring(
    mass: 1.1,
    stiffness: 160,
    damping: 18,
    initialVelocity: 6
)
```

### Landing → Organize

On `.landing`: card snaps to random resting position with a heavier, more decisive spring. `rimBurst` spikes to `1.0` simultaneously.

After a 0.3s beat, `.organizing` begins. The card drifts to center and rotates to 0°:

```swift
// Critically damped — zero overshoot, zero wobble
// Eerily smooth. Not how physics works. That's the point.
Animation.spring(response: 0.72, dampingFraction: 1.0)
```

The card arrives exactly at center and stops. No settle. No wobble. Like it was always going to be there.

### Flip (automatic)

Two sequential `scaleEffect(x:)` passes — horizontal collapse and expand, no rotation:

- First half: `scaleX` 1.0 → 0.0
- Midpoint: `VaylCardBack` swaps for `VaylCardFace` (invisible at scaleX == 0, undetectable)
- Second half: `scaleX` 0.0 → -1.0 (mirrored expansion)

```swift
Animation.spring(response: 0.38, dampingFraction: 0.82)
// Applied to each half independently
```

---

## Section 3 — Table Border Glow Burst

`TableSurfaceView` receives a new parameter:

```swift
struct TableSurfaceView: View {
    let fade: Double
    let rimBurst: Double  // 0.0 = resting, 1.0 = full impact glow
}
```

**Contract preserved:** `TableSurfaceView` remains stateless. No internal animation. Caller (the brand phase view) owns the burst value and timing. `VaylDirector` does not know about `rimBurst` — it is local animation state, not macro phase state.

**Implementation:** Inside `drawSpectrumRim`, `rimBurst` multiplies the rim gradient opacities and the base pass opacity. At `rimBurst == 0`, normal resting rim. At `rimBurst == 1.0`, full spectrum arc flare.

**Timing:** On `.landing`, the parent view fires:

```swift
rimBurst = 1.0
withAnimation(.timingCurve(0.2, 0.8, 0.4, 1.0, duration: 0.6)) {
    rimBurst = 0.0
}
```

Sharp spike on card impact, long tail decay — like a physical impact ripple. The burst does not radiate directionally from the landing point — it illuminates the full arc uniformly, which reads as the table responding to the card, not a UI effect.

---

## Section 4 — Flip + Expand to NamePhase

### Expand

Scale + fade composite. The card's resting center and size are known. Target scale factor is calculated from geometry at render time:

```swift
let expandScale = screenHeight / cardHeight
```

No `matchedGeometryEffect` — requires namespace coordination across view boundaries, which conflicts with the OB canvas layering architecture.

During expand:
- `TableSurfaceView.fade` animates to `0.0` (table disappears)
- `rimBurst` fades to `0.0`
- Card alpha stays `1.0` until the card fully covers the screen
- Card then fades out, revealing `OnboardingAtmosphere(config: .name)` beneath

### NameInput UI + Swipe-Down Exit

Once the card fills the screen and the UI fades in, the card becomes interactive. The user types their name on the card face.

**Submission gesture: swipe down.**
A `DragGesture` on the card detects a downward swipe past a threshold (~80pt). On release:
- Card charges — spectrum border wraps full perimeter, `AppAnimation.spring`, 150ms
- Single definitive haptic fires
- Card slides off the bottom edge of the screen
- `VaylDirector` dispatches to next phase (`.genderInput`)

The keyboard dismiss is implicit — the downward swipe naturally collapses the keyboard before the card exits, which should be verified on device.

No CTA button. The swipe is the only exit. Copy adjacent to the name field should hint at this if user research shows discoverability is an issue (TBD).

---

## Full Sequence

| Beat | Phase | What Happens |
|------|-------|--------------|
| StatView exits | `.statView` | Stat dims, table bare, intro placeholder copy |
| Table settle | — | Copy plays, overhead light present |
| Card enters | `.dealing` | Top-right origin, random physics arc |
| Impact | `.landing` | Messy landing, `rimBurst` spikes |
| Organize | `.organizing` | Card glides impossibly smoothly to center |
| Copy beats | `.settled` | Placeholder copy, card breathes, 1.2s timer |
| Flip | `.flipping` | Automatic, back → front, "The Deep" revealed |
| Expand | `.expanding` | Card scales to screen, table fades |
| Name input | `.nameInput` | UI fades in, user is inside the card, types name |
| Submit | swipe down | Border charges, card exits bottom, director → `.genderInput` |

---

## Open Items

- Placeholder copy: exact strings TBD — will be authored separately
- `rimBurst` multiplier values inside `drawSpectrumRim`: TBD at build time, tuned visually on device
- Intro copy timing relative to card deal: TBD — copy may overlap deal start or precede it
- OB → App transition architecture: still unresolved per v2 spec, out of scope here

---

## Performance Notes

Per OB v2 spec performance rules:
- `.drawingGroup()` on every `VaylCard` instance — always
- `hasAnimated` flag on the brand phase view — full theatre on first visit, settled state on return
- `rimBurst` animation must fire within 16ms of landing haptic — perceptual unity with audio-haptic layer
- Test on physical device — simulator will not surface `.drawingGroup()` + material blur conflicts
