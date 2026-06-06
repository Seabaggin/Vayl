# NamePhase Card Deal Animation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the full StatPhase → NamePhase card deal animation sequence: card enters from top-right with realistic physics, lands messily, auto-organizes with eerie precision, flips automatically to reveal "The Deep" Pensieve face, expands to fill the screen, and presents the name input UI with a swipe-down exit.

**Architecture:** Hybrid SwiftUI + Canvas. `NamePhase` owns a local `CardDealPhase` state machine that drives the full sequence. `VaylCardBack` and a new `OBDeepCardFace` Canvas view handle card rendering. `TableSurfaceView` receives a new `rimBurst` parameter for the impact glow burst.

**Tech Stack:** SwiftUI, Canvas, interpolatingSpring, TimelineView(.animation), DragGesture, AppLayout/AppColors/AppAnimation/AppGlows tokens

---

## File Map

| Action | File | Responsibility |
|--------|------|----------------|
| **Modify** | `Vayl/Features/Onboarding/Canvas/TableSurfaceView.swift` | Add `rimBurst: Double` parameter; wire into `drawSpectrumRim` |
| **Create** | `Vayl/Features/Onboarding/Canvas/OBDeepCardFace.swift` | Canvas renderer for "The Deep" Pensieve card face |
| **Modify** | `Vayl/Features/Onboarding/Phases/NamePhase.swift` | Full implementation: state machine, card deal physics, flip, expand, name input, swipe-down exit |

---

## Task 1: Add `rimBurst` to `TableSurfaceView`

**Files:**
- Modify: `Vayl/Features/Onboarding/Canvas/TableSurfaceView.swift`

- [ ] **Step 1: Add `rimBurst` parameter to the struct**

In `TableSurfaceView.swift`, change the struct definition from:

```swift
struct TableSurfaceView: View {
    let fade: Double
```

to:

```swift
struct TableSurfaceView: View {
    let fade: Double
    /// 0.0 = resting spectrum rim. 1.0 = full impact flare.
    /// Caller drives — VaylDirector does not own this value.
    var rimBurst: Double = 0
```

- [ ] **Step 2: Wire `rimBurst` into `drawSpectrumRim`**

`drawSpectrumRim` is called in the Canvas body. Pass `rimBurst` through:

```swift
drawSpectrumRim(
    context: context, size: size,
    cx: cx, cy: cy, tableR: tableR,
    TY: TY, W: W, dpX: dpX, dpY: dpY,
    rimBurst: rimBurst
)
```

Then update `drawSpectrumRim`'s signature and implementation. Find the function signature (around line 584):

```swift
func drawSpectrumRim(
    context: GraphicsContext,
    size:    CGSize,
    cx:      CGFloat,
    cy:      CGFloat,
    tableR:  CGFloat,
    TY:      CGFloat,
    W:       CGFloat,
    dpX:     CGFloat,
    dpY:     CGFloat
)
```

Change to:

```swift
func drawSpectrumRim(
    context:  GraphicsContext,
    size:     CGSize,
    cx:       CGFloat,
    cy:       CGFloat,
    tableR:   CGFloat,
    TY:       CGFloat,
    W:        CGFloat,
    dpX:      CGFloat,
    dpY:      CGFloat,
    rimBurst: Double
)
```

Inside the function, find `let baseOpacity: Double = 0.12` and replace it with:

```swift
// rimBurst spikes to 1.0 on card impact, decays to 0.0.
// Multiplies base pass opacity and rim gradient stops for the flare.
let burstMult   = 1.0 + rimBurst * 4.0
let baseOpacity = 0.12 * burstMult
```

Find where `rimGradient` is defined (the large Gradient with .spectrumCyan/.spectrumPurple/.spectrumMagenta stops) and replace it with:

```swift
let bo = min(rimBurst * 2.5, 1.0)  // burst opacity additive, capped
let rimGradient = Gradient(stops: [
    .init(color: AppColors.spectrumCyan.opacity(0.28 + bo * 0.50),    location: 0.00),
    .init(color: AppColors.spectrumCyan.opacity(0.55 + bo * 0.40),    location: 0.06),
    .init(color: AppColors.spectrumCyan.opacity(0.70 + bo * 0.30),    location: 0.26),
    .init(color: AppColors.spectrumPurple.opacity(0.88 + bo * 0.12),  location: 0.44),
    .init(color: AppColors.spectrumPurple.opacity(0.94 + bo * 0.06),  location: 0.50),
    .init(color: AppColors.spectrumPurple.opacity(0.88 + bo * 0.12),  location: 0.56),
    .init(color: AppColors.spectrumMagenta.opacity(0.70 + bo * 0.30), location: 0.74),
    .init(color: AppColors.spectrumMagenta.opacity(0.55 + bo * 0.40), location: 0.94),
    .init(color: AppColors.spectrumMagenta.opacity(0.28 + bo * 0.50), location: 1.00),
])
```

- [ ] **Step 3: Update the preview to verify the burst is visible**

In the `#Preview("Table Surface — Dark")` block at the bottom of `TableSurfaceView.swift`, change:

```swift
TableSurfaceView(fade: 1.0)
```

to:

```swift
TableSurfaceView(fade: 1.0, rimBurst: 0.8)
```

Build and run the preview. The spectrum arc should be noticeably brighter than the resting state. Then revert the preview back to `rimBurst: 0`.

- [ ] **Step 4: Verify build succeeds**

```bash
xcodebuild -scheme Vayl -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | grep -E "error:|Build succeeded"
```

Expected: `Build succeeded`

- [ ] **Step 5: Commit**

```bash
git add Vayl/Features/Onboarding/Canvas/TableSurfaceView.swift
git commit -m "feat: add rimBurst parameter to TableSurfaceView for card impact glow"
```

---

## Task 2: Build `OBDeepCardFace` — The Pensieve Canvas renderer

**Files:**
- Create: `Vayl/Features/Onboarding/Canvas/OBDeepCardFace.swift`

- [ ] **Step 1: Create the file with base structure and base layer**

Create `Vayl/Features/Onboarding/Canvas/OBDeepCardFace.swift`:

```swift
// Vayl/Features/Onboarding/Canvas/OBDeepCardFace.swift

import SwiftUI

// MARK: - OBDeepCardFace

/// Canvas renderer for "The Deep" OB card face.
/// Revealed on flip during the NamePhase card deal sequence.
/// Never used outside OB.
///
/// deepT: elapsed seconds since face became visible.
///        Drives swirl drift, particle movement, shimmer cycles, glow breathe.
///        Caller increments via TimelineView — this view never holds time state.
struct OBDeepCardFace: View {

    let deepT: Double

    // ── Seeded particle pool — generated once, stable across frames ────────────
    private let particles: [Particle] = Self.makeParticles()
    private let flecks:    [Fleck]    = Self.makeFlecks()

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let R    = AppRadius.obCard

            Canvas { context, size in
                drawBase(context: context, size: size, R: R)
                drawSwirl(context: context, size: size, deepT: deepT)
                drawParticles(context: context, size: size, deepT: deepT)
                drawShimmer(context: context, size: size, deepT: deepT)
                drawDepthGlow(context: context, size: size, deepT: deepT)
            }
            .clipShape(RoundedRectangle(cornerRadius: R))
            .overlay { DeepCardShell(size: geo.size, R: R) }
        }
    }
}

// MARK: - Seeded data types

private extension OBDeepCardFace {

    struct Particle {
        let x:       CGFloat   // normalised 0..1 of card width
        let y:       CGFloat   // normalised 0..1 of card height
        let driftA:  Double    // drift direction (radians)
        let driftSpd: Double   // drift speed (normalised units/s)
        let radius:  CGFloat   // base radius (pt)
        let opacity: Double    // max opacity
        let phase:   Double    // twinkle phase offset
    }

    struct Fleck {
        let x:      CGFloat
        let y:      CGFloat
        let period: Double    // full cycle duration (seconds)
        let phase:  Double    // start offset within cycle
        let radius: CGFloat
    }

    static func makeParticles() -> [Particle] {
        let rng: (Double) -> Double = { s in
            var x = sin(s) * 43758.5453
            x -= floor(x)
            return x
        }
        return (0 ..< 48).map { i in
            let fi = Double(i)
            return Particle(
                x:        CGFloat(rng(fi * 1.30)),
                y:        CGFloat(rng(fi * 2.71)),
                driftA:   rng(fi * 3.94) * .pi * 2,
                driftSpd: 0.006 + rng(fi * 5.13) * 0.012,
                radius:   CGFloat(1.5 + rng(fi * 6.37) * 2.0),
                opacity:  0.10 + rng(fi * 7.58) * 0.20,
                phase:    rng(fi * 8.81) * .pi * 2
            )
        }
    }

    static func makeFlecks() -> [Fleck] {
        let rng: (Double) -> Double = { s in
            var x = sin(s) * 43758.5453
            x -= floor(x)
            return x
        }
        return (0 ..< 4).map { i in
            let fi = Double(i)
            return Fleck(
                x:      CGFloat(0.12 + rng(fi * 11.3) * 0.76),
                y:      CGFloat(0.12 + rng(fi * 12.7) * 0.76),
                period: 2.2 + rng(fi * 13.9) * 1.6,
                phase:  rng(fi * 15.1) * 2.2,
                radius: CGFloat(0.8 + rng(fi * 16.3) * 0.8)
            )
        }
    }
}

// MARK: - Layer 0: Base

private extension OBDeepCardFace {

    func drawBase(context: GraphicsContext, size: CGSize, R: CGFloat) {
        let path = Path(roundedRect: CGRect(origin: .zero, size: size),
                        cornerRadius: R)
        context.fill(
            path,
            with: .radialGradient(
                Gradient(stops: [
                    .init(color: Color(red: 0.031, green: 0.016, blue: 0.094), location: 0.00),
                    .init(color: Color(red: 0.051, green: 0.024, blue: 0.157), location: 0.45),
                    .init(color: Color(red: 0.016, green: 0.008, blue: 0.055), location: 1.00),
                ]),
                center:      CGPoint(x: size.width / 2, y: size.height / 2),
                startRadius: 0,
                endRadius:   max(size.width, size.height) * 0.72
            )
        )
    }
}

// MARK: - Layer 1: Swirl

private extension OBDeepCardFace {

    // Two overlapping radial layers whose centres drift slowly in opposite
    // circular arcs. Creates organic undulation without per-pixel computation.
    func drawSwirl(context: GraphicsContext, size: CGSize, deepT: Double) {
        let W  = size.width
        let H  = size.height
        let cx = W / 2
        let cy = H / 2

        // Slow drift — period ≈ 10s per orbit
        let angle1 = deepT * ((.pi * 2) / 10.0)
        let angle2 = deepT * ((.pi * 2) / 13.5) + .pi  // opposite phase

        let orbitR: CGFloat = min(W, H) * 0.18

        let c1 = CGPoint(x: cx + cos(angle1) * orbitR, y: cy + sin(angle1) * orbitR * 0.55)
        let c2 = CGPoint(x: cx + cos(angle2) * orbitR, y: cy + sin(angle2) * orbitR * 0.55)

        let rect = CGRect(origin: .zero, size: size)

        // Layer A — deep indigo
        context.fill(rect, with: .radialGradient(
            Gradient(stops: [
                .init(color: Color(red: 0.102, green: 0.039, blue: 0.251).opacity(0.14), location: 0),
                .init(color: Color(red: 0.063, green: 0.016, blue: 0.188).opacity(0.06), location: 0.55),
                .init(color: .clear, location: 1),
            ]),
            center: c1, startRadius: 0, endRadius: min(W, H) * 0.55
        ))

        // Layer B — purple
        context.fill(rect, with: .radialGradient(
            Gradient(stops: [
                .init(color: Color(red: 0.165, green: 0.063, blue: 0.376).opacity(0.11), location: 0),
                .init(color: Color(red: 0.102, green: 0.039, blue: 0.251).opacity(0.05), location: 0.50),
                .init(color: .clear, location: 1),
            ]),
            center: c2, startRadius: 0, endRadius: min(W, H) * 0.48
        ))
    }
}

// MARK: - Layer 2: Particles

private extension OBDeepCardFace {

    func drawParticles(context: GraphicsContext, size: CGSize, deepT: Double) {
        let W = size.width
        let H = size.height
        // Fade in over first 1.5s
        let fadeIn = min(1.0, deepT / 1.50)
        guard fadeIn > 0 else { return }

        for p in particles {
            // Drift position — wraps at edges (toroidal)
            let driftX = (cos(p.driftA) * p.driftSpd * deepT).truncatingRemainder(dividingBy: 1.0)
            let driftY = (sin(p.driftA) * p.driftSpd * deepT).truncatingRemainder(dividingBy: 1.0)
            var nx = (p.x + driftX).truncatingRemainder(dividingBy: 1.0)
            var ny = (p.y + driftY).truncatingRemainder(dividingBy: 1.0)
            if nx < 0 { nx += 1 }
            if ny < 0 { ny += 1 }

            let px = nx * W
            let py = ny * H

            // Twinkle
            let tw = 0.65 + 0.35 * sin(deepT * 0.75 + p.phase)
            let a  = p.opacity * tw * fadeIn

            // Soft halo — 3× radius, low opacity
            let haloR = p.radius * 3.0
            context.fill(
                Path(ellipseIn: CGRect(x: px - haloR, y: py - haloR,
                                       width: haloR * 2, height: haloR * 2)),
                with: .radialGradient(
                    Gradient(colors: [
                        Color(red: 0.784, green: 0.722, blue: 1.0).opacity(a * 0.35),
                        .clear,
                    ]),
                    center: CGPoint(x: px, y: py),
                    startRadius: 0,
                    endRadius: haloR
                )
            )

            // Core — silver-lavender
            let coreR = p.radius
            context.fill(
                Path(ellipseIn: CGRect(x: px - coreR, y: py - coreR,
                                       width: coreR * 2, height: coreR * 2)),
                with: .color(Color(red: 0.784, green: 0.722, blue: 1.0).opacity(a))
            )
        }
    }
}

// MARK: - Layer 3: Surface Shimmer

private extension OBDeepCardFace {

    func drawShimmer(context: GraphicsContext, size: CGSize, deepT: Double) {
        let W = size.width
        let H = size.height
        let fadeIn = min(1.0, deepT / 0.80)
        guard fadeIn > 0 else { return }

        for f in flecks {
            // Cycle position in [0, 1) — sharp sin² peak
            let cyclePos = (deepT + f.phase).truncatingRemainder(dividingBy: f.period) / f.period
            let rawAlpha = pow(max(0.0, sin(cyclePos * .pi)), 2.0)
            let a = rawAlpha * 0.28 * fadeIn
            guard a > 0.002 else { continue }

            let px = f.x * W
            let py = f.y * H
            let haloR = f.radius * 9.0

            context.fill(
                Path(ellipseIn: CGRect(x: px - haloR, y: py - haloR,
                                       width: haloR * 2, height: haloR * 2)),
                with: .radialGradient(
                    Gradient(colors: [
                        Color(red: 0.824, green: 0.784, blue: 1.0).opacity(a),
                        .clear,
                    ]),
                    center: CGPoint(x: px, y: py),
                    startRadius: 0,
                    endRadius: haloR
                )
            )
        }
    }
}

// MARK: - Layer 4: Depth Glow

private extension OBDeepCardFace {

    // Single breathing source deep in the liquid.
    // Not at the surface — below it. Three-layer radial, 3.6s breathe cycle.
    func drawDepthGlow(context: GraphicsContext, size: CGSize, deepT: Double) {
        let cx = size.width  / 2
        let cy = size.height / 2

        // Fade in over 0.9s after flip
        let fadeIn  = min(1.0, deepT / 0.90)
        // Power-curve breathe — lingers at peak, dips quickly
        let breathe = 0.45 + 0.55 * pow(0.50 + 0.50 * sin(deepT * (.pi * 2 / 3.60)), 1.8)
        let gA      = fadeIn * breathe

        let r = min(size.width, size.height) / 2

        // Outer — wide diffuse warmth
        context.fill(
            Path(ellipseIn: CGRect(x: cx - r * 0.55, y: cy - r * 0.55,
                                   width: r * 1.10, height: r * 1.10)),
            with: .radialGradient(
                Gradient(stops: [
                    .init(color: Color(red: 0.227, green: 0.059, blue: 0.541).opacity(gA * 0.22), location: 0),
                    .init(color: Color(red: 0.424, green: 0.227, blue: 0.878).opacity(gA * 0.10), location: 0.5),
                    .init(color: .clear, location: 1),
                ]),
                center: CGPoint(x: cx, y: cy),
                startRadius: 0,
                endRadius: r * 0.55
            )
        )

        // Mid
        context.fill(
            Path(ellipseIn: CGRect(x: cx - r * 0.22, y: cy - r * 0.22,
                                   width: r * 0.44, height: r * 0.44)),
            with: .radialGradient(
                Gradient(stops: [
                    .init(color: Color(red: 0.424, green: 0.227, blue: 0.878).opacity(gA * 0.50), location: 0),
                    .init(color: Color(red: 0.424, green: 0.227, blue: 0.878).opacity(gA * 0.18), location: 0.5),
                    .init(color: .clear, location: 1),
                ]),
                center: CGPoint(x: cx, y: cy),
                startRadius: 0,
                endRadius: r * 0.22
            )
        )

        // Core — concentrated lavender
        context.fill(
            Path(ellipseIn: CGRect(x: cx - r * 0.08, y: cy - r * 0.08,
                                   width: r * 0.16, height: r * 0.16)),
            with: .radialGradient(
                Gradient(stops: [
                    .init(color: Color(red: 0.753, green: 0.659, blue: 1.0).opacity(gA * 0.88), location: 0),
                    .init(color: Color(red: 0.424, green: 0.227, blue: 0.878).opacity(gA * 0.50), location: 0.5),
                    .init(color: .clear, location: 1),
                ]),
                center: CGPoint(x: cx, y: cy),
                startRadius: 0,
                endRadius: r * 0.08
            )
        )

        // Pinpoint
        context.fill(
            Path(ellipseIn: CGRect(x: cx - 1.2, y: cy - 1.2, width: 2.4, height: 2.4)),
            with: .color(Color(red: 0.902, green: 0.863, blue: 1.0).opacity(gA * 0.70))
        )
    }
}

// MARK: - DeepCardShell

/// Spectrum shell overlay — same visual language as VaylCardFace.
/// Drawn as SwiftUI views over the Canvas so they sit above the clip boundary.
private struct DeepCardShell: View {
    let size: CGSize
    let R:    CGFloat

    var body: some View {
        ZStack {
            // Border glow
            RoundedRectangle(cornerRadius: R)
                .stroke(AppColors.spectrumPurple.opacity(0.18), lineWidth: 1)
                .blur(radius: 20)

            // Outer spectrum hairline
            RoundedRectangle(cornerRadius: R)
                .strokeBorder(AppColors.spectrumBorder, lineWidth: 1.1)
                .opacity(0.52)
                .padding(0.75)

            // Inset frame
            RoundedRectangle(cornerRadius: R - 4)
                .strokeBorder(AppColors.spectrumBorder, lineWidth: 0.55)
                .opacity(0.22)
                .padding(9)

            // Top hairline
            Path { p in
                p.move(to:    CGPoint(x: 14,              y: 0.75))
                p.addLine(to: CGPoint(x: size.width - 14, y: 0.75))
            }
            .stroke(AppColors.spectrumBorder.opacity(0.60), lineWidth: 1.2)
            .frame(width: size.width, height: size.height)

            // Bottom hairline
            Path { p in
                p.move(to:    CGPoint(x: 14,              y: size.height - 0.75))
                p.addLine(to: CGPoint(x: size.width - 14, y: size.height - 0.75))
            }
            .stroke(AppColors.spectrumBorder.opacity(0.60), lineWidth: 1.2)
            .frame(width: size.width, height: size.height)

            // ✦ Corner marks
            ZStack {
                ForEach([
                    CGPoint(x: 16,               y: 16),
                    CGPoint(x: size.width - 16,  y: 16),
                    CGPoint(x: 16,               y: size.height - 16),
                    CGPoint(x: size.width - 16,  y: size.height - 16),
                ], id: \.x) { pt in
                    Text("✦")
                        .font(AppFonts.label)
                        .foregroundStyle(Color.white.opacity(0.12))
                        .position(pt)
                }
            }
            .frame(width: size.width, height: size.height)
        }
    }
}

// MARK: - Preview

#Preview("The Deep — resting (deepT = 2.0)") {
    ZStack {
        Color.black.ignoresSafeArea()
        OBDeepCardFace(deepT: 2.0)
            .frame(width: 260, height: 385)
            .drawingGroup()
    }
    .preferredColorScheme(.dark)
}

#Preview("The Deep — just flipped (deepT = 0.1)") {
    ZStack {
        Color.black.ignoresSafeArea()
        OBDeepCardFace(deepT: 0.1)
            .frame(width: 260, height: 385)
            .drawingGroup()
    }
    .preferredColorScheme(.dark)
}
```

- [ ] **Step 2: Run the previews and verify visual output**

Open `OBDeepCardFace.swift` in Xcode. Run both previews.

Expected — "resting (deepT = 2.0)": Deep violet-indigo base, silver-lavender particles scattered across the surface, 1-2 shimmer flecks visible, soft breathing glow at center, spectrum shell visible.

Expected — "just flipped (deepT = 0.1)": Glow nearly absent (still fading in), particles barely visible, swirl not yet apparent. This is correct — the face reveals gradually.

- [ ] **Step 3: Verify build succeeds**

```bash
xcodebuild -scheme Vayl -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | grep -E "error:|Build succeeded"
```

Expected: `Build succeeded`

- [ ] **Step 4: Commit**

```bash
git add Vayl/Features/Onboarding/Canvas/OBDeepCardFace.swift
git commit -m "feat: add OBDeepCardFace — Pensieve deep water card face for NamePhase"
```

---

## Task 3: `NamePhase` — State Machine + Deal Physics

**Files:**
- Modify: `Vayl/Features/Onboarding/Phases/NamePhase.swift`

- [ ] **Step 1: Replace stub with full state machine skeleton**

Replace the entire contents of `NamePhase.swift` with:

```swift
// Vayl/Features/Onboarding/Phases/NamePhase.swift

import SwiftUI

// MARK: - CardDealPhase

/// Sub-phase state machine local to NamePhase.
/// VaylDirector stays at macro level (.nameInput).
/// This enum drives the card deal animation sequence.
private enum CardDealPhase {
    case idle
    case dealing       // card in flight from top-right
    case landing       // card hits table — rimBurst fires
    case organizing    // eerie auto-drift to center
    case settled       // copy beats, 1.2s timer
    case flipping      // back → Deep face, automatic
    case expanding     // card scales to fill screen
    case nameInput     // UI active, swipe-down to submit
}

// MARK: - NamePhase

struct NamePhase: View {

    let director:   VaylDirector
    let screenSize: CGSize

    // ── Deal state ─────────────────────────────────────────────────────────────
    @State private var dealPhase:    CardDealPhase = .idle
    @State private var cardOffset:   CGSize        = .zero
    @State private var cardAngle:    Double        = 0
    @State private var cardAlpha:    Double        = 0
    @State private var rimBurst:     Double        = 0

    // Landing seed — generated once, stable across replays in session
    @State private var landingAngle:  Double = 0
    @State private var landingOffset: CGSize = .zero

    // ── Flip state ─────────────────────────────────────────────────────────────
    @State private var flipScaleX: Double = 1.0
    @State private var showFace:   Bool   = false
    @State private var deepT:      Double = 0
    @State private var faceStartDate: Date? = nil

    // ── Expand state ───────────────────────────────────────────────────────────
    @State private var cardScale:  Double = 1.0
    @State private var tableFade:  Double = 1.0
    @State private var cardScreenAlpha: Double = 1.0

    // ── Name input state ───────────────────────────────────────────────────────
    @State private var name:      String  = ""
    @State private var uiAlpha:   Double  = 0
    @State private var dragY:     CGFloat = 0
    @State private var isCharging: Bool   = false

    // ── Card geometry ──────────────────────────────────────────────────────────
    private var cardWidth:  CGFloat { AppLayout.obCardWidth(in: screenSize) }
    private var cardHeight: CGFloat { AppLayout.obCardHeight(in: screenSize) }

    // Starting position — off-screen top-right
    private var dealOrigin: CGSize {
        CGSize(
            width:  screenSize.width  * 0.60,
            height: -screenSize.height * 0.58
        )
    }

    var body: some View {
        ZStack {
            // Table surface — fades out during expand
            TableSurfaceView(fade: tableFade, rimBurst: rimBurst)

            // Card layer
            TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { tl in
                let _ = updateDeepT(date: tl.date)
                cardLayer
            }

            // Name input UI — appears after expand
            if dealPhase == .nameInput {
                nameInputLayer
                    .opacity(uiAlpha)
            }
        }
        .onAppear { seedLanding(); startDeal() }
    }

    // MARK: - Card Layer

    private var cardLayer: some View {
        Group {
            if !showFace {
                VaylCardBack()
            } else {
                OBDeepCardFace(deepT: deepT)
            }
        }
        .frame(width: cardWidth, height: cardHeight)
        .scaleEffect(x: flipScaleX, y: 1.0)
        .scaleEffect(cardScale)
        .offset(cardOffset)
        .rotationEffect(.degrees(cardAngle))
        .opacity(cardAlpha * cardScreenAlpha)
        .drawingGroup()
    }

    // MARK: - Name Input Layer

    private var nameInputLayer: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: AppSafeArea.top + 58)

            // Back button
            Circle()
                .strokeBorder(Color.white.opacity(0.07), lineWidth: 1)
                .frame(width: 30, height: 30)
                .overlay {
                    Text("←")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.25))
                }
                .padding(.bottom, 32)

            // Header
            VStack(alignment: .leading, spacing: 0) {
                Text("Let's get")
                    .font(AppFonts.screenTitle)
                    .foregroundStyle(AppColors.textPrimary)
                Text("acquainted.")
                    .font(AppFonts.screenTitle)
                    .foregroundStyle(AppColors.spectrumBorder)
            }
            .padding(.bottom, 32)

            // Name field
            VStack(alignment: .leading, spacing: 5) {
                Text("WHAT DO I CALL YOU?")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.spectrumPurple.opacity(0.78))
                    .tracking(2.5)

                TextField("", text: $name)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)
                    .tint(AppColors.spectrumCyan)

                // Write line
                Rectangle()
                    .fill(AppColors.spectrumBorder.opacity(0.60))
                    .frame(height: 2)

                // Glow under write line
                Rectangle()
                    .fill(AppColors.spectrumBorder.opacity(0.15))
                    .frame(height: 8)
                    .blur(radius: 4)
                    .padding(.top, -6)
            }

            Divider()
                .background(AppColors.spectrumPurple.opacity(0.12))
                .padding(.vertical, 24)

            Spacer()

            Text("terms · privacy")
                .font(AppFonts.caption)
                .foregroundStyle(Color.white.opacity(0.09))
                .tracking(2)
                .frame(maxWidth: .infinity, alignment: .center)

            Spacer().frame(height: AppSafeArea.bottom + 42)
        }
        .padding(.horizontal, 32)
        .gesture(
            DragGesture()
                .onChanged { v in dragY = v.translation.height }
                .onEnded   { v in handleSwipeDown(v.translation.height) }
        )
    }

    // MARK: - deepT update

    @discardableResult
    private func updateDeepT(date: Date) -> Double {
        guard showFace, let start = faceStartDate else { return 0 }
        deepT = date.timeIntervalSince(start)
        return deepT
    }
}
```

- [ ] **Step 2: Build to verify the skeleton compiles**

```bash
xcodebuild -scheme Vayl -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | grep -E "error:|Build succeeded"
```

Expected: `Build succeeded` (stub functions not yet added — add empty implementations if needed to silence errors)

- [ ] **Step 3: Add `seedLanding` and `startDeal`**

Add these methods to `NamePhase` (inside the struct, after the body):

```swift
// MARK: - Deal sequence

private func seedLanding() {
    landingAngle  = Double.random(in: -7...7)
    landingOffset = CGSize(
        width:  CGFloat.random(in: -38...38),
        height: CGFloat.random(in: -28...28)
    )
}

private func startDeal() {
    // Place card at origin (invisible)
    cardOffset = dealOrigin
    cardAngle  = -14
    cardAlpha  = 0
    dealPhase  = .dealing

    // Fade in card as it enters
    withAnimation(.linear(duration: 0.14)) {
        cardAlpha = 1
    }

    // Deal flight — rotation and offset use slightly different springs
    // so they don't arrive simultaneously, producing natural tilt in flight
    withAnimation(
        .interpolatingSpring(mass: 1.1, stiffness: 160, damping: 18, initialVelocity: 6)
    ) {
        cardOffset = landingOffset
        cardAngle  = landingAngle
    }

    // Offset arrives first (~920ms), then trigger landing
    Task {
        try? await Task.sleep(for: .milliseconds(940))
        triggerLanding()
    }
}

private func triggerLanding() {
    dealPhase = .landing

    // rimBurst spike with long decay
    rimBurst = 1.0
    withAnimation(.timingCurve(0.2, 0.8, 0.4, 1.0, duration: 0.6)) {
        rimBurst = 0.0
    }

    // Short beat then organize
    Task {
        try? await Task.sleep(for: .milliseconds(300))
        triggerOrganize()
    }
}

private func triggerOrganize() {
    dealPhase = .organizing

    // Critically damped — zero overshoot. Eerie precision.
    withAnimation(.spring(response: 0.72, dampingFraction: 1.0)) {
        cardOffset = .zero
        cardAngle  = 0
    }

    Task {
        try? await Task.sleep(for: .milliseconds(780))
        dealPhase = .settled
        // 1.2s settled beat, then flip
        try? await Task.sleep(for: .milliseconds(1200))
        triggerFlip()
    }
}
```

- [ ] **Step 4: Add forward-declaration stubs so the file compiles before Task 4**

Add these stubs immediately after `triggerOrganize`. Task 4 will replace them with real implementations:

```swift
private func triggerFlip()                  { /* Task 4 */ }
private func triggerExpand()                { /* Task 4 */ }
private func triggerNameInput()             { /* Task 4 */ }
private func submitName()                   { /* Task 5 */ }
private func handleSwipeDown(_ y: CGFloat)  { /* Task 5 */ }
```

- [ ] **Step 5: Build to verify**

```bash
xcodebuild -scheme Vayl -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | grep -E "error:|Build succeeded"
```

Expected: `Build succeeded`

- [ ] **Step 6: Commit**

```bash
git add Vayl/Features/Onboarding/Phases/NamePhase.swift
git commit -m "feat: NamePhase — card deal state machine, physics, landing, organize"
```

---

## Task 4: Flip + Expand

**Files:**
- Modify: `Vayl/Features/Onboarding/Phases/NamePhase.swift`

- [ ] **Step 1: Replace the three Task 3 stubs with real `triggerFlip`, `triggerExpand`, `triggerNameInput` implementations**

Remove the stub lines added in Task 3 Step 4 and replace with:

```swift
private func triggerFlip() {
    dealPhase = .flipping

    // First half — collapse to scaleX == 0
    withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
        flipScaleX = 0.0
    }

    Task {
        try? await Task.sleep(for: .milliseconds(190))
        // Swap face at the invisible midpoint — undetectable
        showFace = true
        faceStartDate = Date()

        // Second half — expand mirrored (negative = face-up)
        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            flipScaleX = -1.0
        }

        try? await Task.sleep(for: .milliseconds(660))
        triggerExpand()
    }
}

private func triggerExpand() {
    dealPhase = .expanding

    let scaleX = screenSize.width  / cardWidth
    let scaleY = screenSize.height / cardHeight
    let target = max(scaleX, scaleY) * 1.04  // 4% overshoot ensures full bleed

    withAnimation(.easeIn(duration: 0.55)) {
        tableFade = 0.0
    }
    withAnimation(.timingCurve(0.4, 0.0, 0.2, 1.0, duration: 1.05)) {
        cardScale = target
    }

    Task {
        try? await Task.sleep(for: .milliseconds(550))
        withAnimation(.easeIn(duration: 0.35)) {
            cardScreenAlpha = 0.0
        }
        try? await Task.sleep(for: .milliseconds(380))
        triggerNameInput()
    }
}

private func triggerNameInput() {
    dealPhase = .nameInput
    withAnimation(.easeOut(duration: 0.52)) {
        uiAlpha = 1.0
    }
}
```

- [ ] **Step 2: Build and run in simulator to verify full sequence**

```bash
xcodebuild -scheme Vayl -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | grep -E "error:|Build succeeded"
```

Expected: `Build succeeded`

Run on iPhone 17 Pro simulator. Verify in order:
- Card enters from top-right ✓
- Lands off-center with rotation ✓
- Drifts impossibly smoothly to center ✓
- Rim glows on impact ✓
- Flips — back disappears, Deep face appears ✓
- Pensieve atmosphere fades in on Deep face ✓
- Card expands to fill screen ✓
- Card fades revealing atmosphere beneath ✓
- NameInput UI appears ✓

- [ ] **Step 3: Commit**

```bash
git add Vayl/Features/Onboarding/Phases/NamePhase.swift
git commit -m "feat: NamePhase — flip animation and card expand to full screen"
```

---

## Task 5: Name Input UI + Swipe-Down Exit

**Files:**
- Modify: `Vayl/Features/Onboarding/Phases/NamePhase.swift`

- [ ] **Step 1: Add `handleSwipeDown` method**

```swift
// MARK: - Submission

private func handleSwipeDown(_ translationY: CGFloat) {
    guard dealPhase == .nameInput, translationY > 80 else {
        // Reset drag if threshold not met
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            dragY = 0
        }
        return
    }

    guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
        // No name entered — shake feedback, don't submit
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            dragY = 0
        }
        return
    }

    submitName()
}

private func submitName() {
    isCharging = true

    // Haptic
    let impact = UIImpactFeedbackGenerator(style: .heavy)
    impact.impactOccurred()

    // Store name in director
    director.onboardingData.name = name.trimmingCharacters(in: .whitespaces)

    // UI fades out
    withAnimation(.easeIn(duration: 0.20)) {
        uiAlpha = 0
    }

    // Card slides off bottom
    withAnimation(.spring(response: 0.48, dampingFraction: 0.88)) {
        dragY = screenSize.height * 1.2
    }

    Task {
        try? await Task.sleep(for: .milliseconds(480))
        director.advance(to: .gender)
    }
}
```

- [ ] **Step 2: Wire `dragY` into the nameInputLayer offset**

In the `nameInputLayer` computed property, wrap the `VStack` in an `.offset(y: dragY)` modifier:

```swift
private var nameInputLayer: some View {
    VStack(alignment: .leading, spacing: 0) {
        // ... (existing content unchanged)
    }
    .padding(.horizontal, 32)
    .offset(y: dragY)   // ← add this line
    .gesture(
        DragGesture()
            .onChanged { v in
                if v.translation.height > 0 {
                    dragY = v.translation.height
                }
            }
            .onEnded { v in handleSwipeDown(v.translation.height) }
    )
}
```

- [ ] **Step 3: Add a preview for the name input state**

At the bottom of `NamePhase.swift`, add:

```swift
#Preview("NamePhase — name input state") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        OBDeepCardFace(deepT: 3.0)
            .ignoresSafeArea()
            .drawingGroup()

        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 58)
            Text("Let's get").font(AppFonts.screenTitle).foregroundStyle(AppColors.textPrimary)
            Text("acquainted.").font(AppFonts.screenTitle).foregroundStyle(AppColors.spectrumBorder)
            Spacer()
        }
        .padding(.horizontal, 32)
    }
    .preferredColorScheme(.dark)
}
```

- [ ] **Step 4: Verify on device — swipe-down discoverability**

On a physical device:
- Type a name
- Swipe down — card should charge border (if charging animation implemented — TBD), then slide off bottom
- App advances to GenderPhase

If the `isCharging` border charge animation is not yet implemented in `VaylCardFace`/shell, that's an open item — the swipe-down exit still functions correctly without it.

- [ ] **Step 5: Build final verification**

```bash
xcodebuild -scheme Vayl -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | grep -E "error:|Build succeeded"
```

Expected: `Build succeeded`

- [ ] **Step 6: Final commit**

```bash
git add Vayl/Features/Onboarding/Phases/NamePhase.swift
git commit -m "feat: NamePhase — name input UI, swipe-down exit, director advance to gender"
```

---

## Open Items (not blocking this plan)

- **Border charge animation on submit:** The spectrum border wrapping full perimeter on swipe release (per spec) requires a `isCharging` modifier on `DeepCardShell`. Tracked separately.
- **Intro/dealer copy beats:** Placeholder text during `.settled` phase — copy authored separately, wired in after.
- **Audio-haptic layer:** Landing thwack + organize silence + flip sound. Separate audio pass.
- **`hasAnimated` flag:** First-visit full theatre vs settled state on return. Add once full sequence is verified on device.
- **`OnboardingData.name` property:** Verify this property exists on `OnboardingData` before Task 5 Step 1. If not, add it.

---

## Device Testing Checklist

Run on physical device (not simulator) before marking complete:

- [ ] Card deal physics feel flowy — not stiff or instant
- [ ] Landing feels like a real card hitting a table
- [ ] Organize drift feels eerie — impossibly smooth, no wobble
- [ ] Rim burst visible on landing impact
- [ ] Flip is clean — no visible swap artifact at midpoint
- [ ] The Deep atmosphere fades in gradually after flip
- [ ] Expand covers full screen with no visible card border at edges
- [ ] Pensieve particles and shimmer visible (dim, not obvious)
- [ ] Depth glow breathes visibly
- [ ] Name field accepts keyboard input
- [ ] Swipe-down at < 80pt snaps back
- [ ] Swipe-down at > 80pt with name typed → submits and advances
- [ ] Swipe-down with empty name → haptic feedback, no advance
- [ ] `.drawingGroup()` renders correctly (test on device — simulator unreliable)
