# OB Phase Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix two UX framing issues in onboarding — ModeSelect copy reframe (situational vs identity language) and GenderPhase slot machine → vintage radio tuner.

**Architecture:** ModeSelect is a pure copy change. GenderPhase replaces the SlotMachineCardFace Canvas illustration with RadioTunerCardFace, removes the autonomous reel-spin sequence, adds a pronouns drum alongside the existing gender drum, and updates VaylDirector state accordingly. The slot machine component is preserved for future reuse.

**Tech Stack:** SwiftUI, Swift 6, iOS 16+ baseline, @Observable VaylDirector, Canvas-based card face illustrations.

---

## File Map

| Action | File | Change |
|--------|------|--------|
| Modify | `Vayl/Features/Onboarding/Phases/ModeSelectPhase.swift` | Card title strings + lift copy strings |
| Create | `Vayl/Design/Components/Cards/CardFaces/RadioTunerCardFace.swift` | New Canvas illustration |
| Modify | `Vayl/Design/Components/Cards/VaylCardContent.swift` | Add `.radioTuner` case |
| Modify | `Vayl/Design/Components/Cards/VaylCardFace.swift` | Handle `.radioTuner` in switch |
| Modify | `Vayl/Features/Onboarding/Canvas/VaylDirector.swift` | Remove slot machine state, add radio/pronouns state, rewrite `runGenderFlipAndSpin` |
| Modify | `Vayl/Features/Onboarding/Phases/GenderPhase.swift` | Replace SlotMachineCardFace, add pronouns drum, remove reel observers |

---

## Task 1 — ModeSelect Copy Reframe

**Files:**
- Modify: `Vayl/Features/Onboarding/Phases/ModeSelectPhase.swift`

### Context
The dealer line is already correct ("Anyone at the table with you?"). Only three string literals need changing: the lift-copy title and both placeholder lift-copy subtitles.

- [ ] **Step 1: Change the lift-copy title strings**

In `liftCopyLayer(text:side:)` at the top of the function body, line ~79:

```swift
// BEFORE
let title = side == .left ? "Solo" : "Shared Journey"

// AFTER
let title = side == .left ? "Just me for now" : "We're both here"
```

- [ ] **Step 2: Update the placeholder lift copy subtitles**

In `scheduleLiftText(for:)`, the two PLACEHOLDER strings:

```swift
// BEFORE
let text = side == .left
    ? "I'm looking for clarity."
    : "Starting the conversation together."

// AFTER
let text = side == .left
    ? "Starting on my own — for now."
    : "We're doing this together."
```

- [ ] **Step 3: Verify in simulator**

Run the app. Navigate to ModeSelectPhase. Lift the left card → confirm "Just me for now" appears as the large header with "Starting on my own — for now." below. Lift the right card → "We're both here" / "We're doing this together." confirm message appears. Swipe up to confirm — advance works correctly.

- [ ] **Step 4: Commit**

```bash
git add Vayl/Features/Onboarding/Phases/ModeSelectPhase.swift
git commit -m "fix(ob): reframe ModeSelect copy from identity to situational language"
```

---

## Task 2 — RadioTunerCardFace: Static Illustration

**Files:**
- Create: `Vayl/Design/Components/Cards/CardFaces/RadioTunerCardFace.swift`

### Context
Pure Canvas illustration — no @State, no gestures. Follows the same pattern as `SlotMachineCardFace.swift`: viewbox in internal units, scale factor `s`, two render passes (glow + crisp), spectrum gradient on all strokes.

Vintage radio anatomy: rectangular cabinet with rounded corners, rectangular speaker grille in upper-center with horizontal lines, two round dials (left = gender, right = pronouns), frequency band strip at bottom with a tuning needle, thin antenna from top-right.

Parameters:
- `signalStrength: Double` — 0.0 (static/searching) → 1.0 (locked signal). Drives glow intensity on band + needle.
- `leftDialProgress: Double` — 0.0–1.0 across gender option range. Rotates left dial needle.
- `rightDialProgress: Double` — same for pronouns.

- [ ] **Step 1: Create the file**

Create `Vayl/Design/Components/Cards/CardFaces/RadioTunerCardFace.swift`:

```swift
// Vayl/Design/Components/Cards/CardFaces/RadioTunerCardFace.swift

import SwiftUI

/// Vintage radio face for GenderPhase.
///
/// Pure Canvas illustration — owns nothing but pixels.
/// No @State, no gestures. All live state passes in from GenderPhase via VaylDirector.
///
/// Canvas geometry
/// ───────────────
/// Viewbox:  160 × 110 internal units
/// Scale:    s = (cardWidth * 0.72) / 160
/// Cabinet:  160 × 110, cornerRadius 12 — fills viewbox
/// Grille:   rect ~80 × 52, upper center, horizontal lines
/// Dials:    r ≈ 12, flanking the grille
/// Band:     rect full-width, bottom of cabinet
/// Antenna:  diagonal line, top-right corner
struct RadioTunerCardFace: View {

    let cardWidth:  CGFloat
    let cardHeight: CGFloat

    /// 0.0 = searching (static look), 1.0 = signal locked (band + needle glow fully on)
    var signalStrength:    Double = 0
    /// 0.0–1.0 maps across the gender options list → rotates left dial needle
    var leftDialProgress:  Double = 0
    /// 0.0–1.0 maps across the pronouns options list → rotates right dial needle
    var rightDialProgress: Double = 0

    private var illustrationWidth:  CGFloat { cardWidth  * 0.72 }
    private var illustrationHeight: CGFloat { illustrationWidth * (110.0 / 160.0) }

    // 240° sweep, centred so 0% = bottom-left, 50% = top, 100% = bottom-right
    private func dialAngleDeg(_ progress: Double) -> Double {
        -120.0 + progress * 240.0
    }

    var body: some View {
        Canvas { context, size in

            let s: CGFloat = illustrationWidth / 160.0

            // ── Cabinet geometry ───────────────────────────────────────────
            let cabW: CGFloat = 160 * s
            let cabH: CGFloat = 110 * s
            let cabR: CGFloat = 12  * s
            let cabX: CGFloat = (size.width  - cabW) / 2
            let cabY: CGFloat = (size.height - cabH) * 0.38

            // ── Spectrum gradient (illustration-space) ─────────────────────
            let specGrad = Gradient(stops: [
                .init(color: AppColors.spectrumCyan,    location: 0.00),
                .init(color: AppColors.spectrumPurple,  location: 0.50),
                .init(color: AppColors.spectrumMagenta, location: 1.00),
            ])
            let shading = GraphicsContext.Shading.linearGradient(
                specGrad,
                startPoint: CGPoint(x: cabX,        y: cabY),
                endPoint:   CGPoint(x: cabX + cabW,  y: cabY + cabH)
            )

            // ── Antenna ────────────────────────────────────────────────────
            let antBaseX = cabX + cabW * 0.78
            let antBaseY = cabY
            let antTipX  = antBaseX + 16 * s
            let antTipY  = cabY - 26 * s
            var antPath  = Path()
            antPath.move(to:    CGPoint(x: antBaseX, y: antBaseY))
            antPath.addLine(to: CGPoint(x: antTipX,  y: antTipY))

            // ── Cabinet ────────────────────────────────────────────────────
            let cabinetPath = Path(roundedRect: CGRect(
                x: cabX, y: cabY, width: cabW, height: cabH
            ), cornerRadius: cabR)

            // ── Speaker grille ─────────────────────────────────────────────
            // Rectangular area in upper center with clipped horizontal lines
            let grilleX = cabX + cabW * 0.22
            let grilleY = cabY + cabH * 0.10
            let grilleW = cabW * 0.56
            let grilleH = cabH * 0.48
            let grilleR: CGFloat = 4 * s
            let grillePath = Path(roundedRect: CGRect(
                x: grilleX, y: grilleY, width: grilleW, height: grilleH
            ), cornerRadius: grilleR)

            var grilleLinesPath = Path()
            let lineCount = 6
            for i in 0..<lineCount {
                let t = CGFloat(i + 1) / CGFloat(lineCount + 1)
                let y = grilleY + t * grilleH
                grilleLinesPath.move(to:    CGPoint(x: grilleX + 4 * s,            y: y))
                grilleLinesPath.addLine(to: CGPoint(x: grilleX + grilleW - 4 * s,  y: y))
            }

            // ── Dials ──────────────────────────────────────────────────────
            let dialR: CGFloat = 11 * s
            let dialCY = grilleY + grilleH * 0.5
            let leftDialCX  = cabX + cabW * 0.115
            let rightDialCX = cabX + cabW * 0.885
            let leftDialPath  = Path(ellipseIn: CGRect(
                x: leftDialCX  - dialR, y: dialCY - dialR,
                width: dialR * 2, height: dialR * 2
            ))
            let rightDialPath = Path(ellipseIn: CGRect(
                x: rightDialCX - dialR, y: dialCY - dialR,
                width: dialR * 2, height: dialR * 2
            ))

            func needleEnd(cx: CGFloat, cy: CGFloat, progressFrac: Double) -> CGPoint {
                let deg = dialAngleDeg(progressFrac)
                let rad = deg * .pi / 180.0
                return CGPoint(
                    x: cx + dialR * 0.58 * CGFloat(sin(rad)),
                    y: cy - dialR * 0.58 * CGFloat(cos(rad))
                )
            }

            var leftNeedlePath  = Path()
            leftNeedlePath.move(to:    CGPoint(x: leftDialCX,  y: dialCY))
            leftNeedlePath.addLine(to: needleEnd(cx: leftDialCX,  cy: dialCY, progressFrac: leftDialProgress))

            var rightNeedlePath = Path()
            rightNeedlePath.move(to:    CGPoint(x: rightDialCX, y: dialCY))
            rightNeedlePath.addLine(to: needleEnd(cx: rightDialCX, cy: dialCY, progressFrac: rightDialProgress))

            // ── Frequency band strip ───────────────────────────────────────
            let bandPad = cabW * 0.08
            let bandX   = cabX + bandPad
            let bandY   = cabY + cabH * 0.76
            let bandW   = cabW - bandPad * 2
            let bandH   = cabH * 0.11
            let bandPath = Path(roundedRect: CGRect(
                x: bandX, y: bandY, width: bandW, height: bandH
            ), cornerRadius: 2 * s)

            // Needle marker: tracks leftDialProgress along the band
            let needleX = bandX + bandW * CGFloat(leftDialProgress)
            var bandNeedlePath = Path()
            bandNeedlePath.move(to:    CGPoint(x: needleX, y: bandY - 2 * s))
            bandNeedlePath.addLine(to: CGPoint(x: needleX, y: bandY + bandH + 2 * s))

            let sig = CGFloat(signalStrength)

            // ── Pass 1: Glow ───────────────────────────────────────────────
            context.drawLayer { ctx in
                ctx.addFilter(.blur(radius: 3 * s))
                ctx.opacity = 0.22 + Double(0.16 * sig)
                ctx.stroke(cabinetPath, with: shading, style: StrokeStyle(lineWidth: 7 * s))
                ctx.stroke(grillePath,  with: shading, style: StrokeStyle(lineWidth: 5 * s))
                ctx.stroke(bandPath,    with: shading, style: StrokeStyle(lineWidth: 7 * s))
            }
            // Band needle glow scales with signal lock
            if sig > 0 {
                context.drawLayer { ctx in
                    ctx.addFilter(.blur(radius: 2.5 * s))
                    ctx.opacity = Double(sig * 0.70)
                    ctx.stroke(bandNeedlePath, with: shading, style: StrokeStyle(lineWidth: 3 * s, lineCap: .round))
                }
            }

            // ── Pass 2: Crisp ──────────────────────────────────────────────

            // Cabinet
            context.stroke(cabinetPath, with: shading,
                style: StrokeStyle(lineWidth: 1.2 * s, lineCap: .square, lineJoin: .miter))

            // Antenna
            context.stroke(antPath, with: shading,
                style: StrokeStyle(lineWidth: 0.8 * s, lineCap: .round))

            // Speaker grille outline
            context.stroke(grillePath, with: shading,
                style: StrokeStyle(lineWidth: 1.0 * s))

            // Speaker grille lines (clipped, dimmed)
            var grilleCtx = context
            grilleCtx.clip(to: grillePath)
            grilleCtx.opacity = 0.40
            grilleCtx.stroke(grilleLinesPath, with: shading,
                style: StrokeStyle(lineWidth: 0.6 * s, lineCap: .round))

            // Dials
            context.stroke(leftDialPath,  with: shading, style: StrokeStyle(lineWidth: 1.0 * s))
            context.stroke(rightDialPath, with: shading, style: StrokeStyle(lineWidth: 1.0 * s))

            // Dial needles
            context.stroke(leftNeedlePath,  with: shading,
                style: StrokeStyle(lineWidth: 1.2 * s, lineCap: .round))
            context.stroke(rightNeedlePath, with: shading,
                style: StrokeStyle(lineWidth: 1.2 * s, lineCap: .round))

            // Frequency band
            context.stroke(bandPath, with: shading,
                style: StrokeStyle(lineWidth: 1.0 * s))

            // Band needle (fully visible when signal locked, dimmer while tuning)
            var needleCtx = context
            needleCtx.opacity = Double(0.35 + 0.65 * sig)
            needleCtx.stroke(bandNeedlePath, with: shading,
                style: StrokeStyle(lineWidth: 1.0 * s, lineCap: .round))
        }
        .frame(width: cardWidth, height: cardHeight)
    }
}

// MARK: - Previews

#Preview("Static — signal 0") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        RadioTunerCardFace(
            cardWidth:  AppLayout.obCardWidth(in: 390),
            cardHeight: AppLayout.obCardHeight(in: 390),
            signalStrength: 0,
            leftDialProgress: 0.5,
            rightDialProgress: 0.2
        )
        .frame(
            width:  AppLayout.obCardWidth(in: 390),
            height: AppLayout.obCardHeight(in: 390)
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("Locked — signal 1") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        RadioTunerCardFace(
            cardWidth:  AppLayout.obCardWidth(in: 390),
            cardHeight: AppLayout.obCardHeight(in: 390),
            signalStrength: 1,
            leftDialProgress: 0.4,
            rightDialProgress: 0.6
        )
        .frame(
            width:  AppLayout.obCardWidth(in: 390),
            height: AppLayout.obCardHeight(in: 390)
        )
    }
    .preferredColorScheme(.dark)
}
```

- [ ] **Step 2: Verify preview in Xcode**

Open the preview canvas for `RadioTunerCardFace.swift`. Confirm:
- Cabinet outline visible with spectrum gradient
- Speaker grille with horizontal lines inside
- Two dials with needles pointing at their dial progress positions
- Frequency band at the bottom with needle
- "Locked" preview shows noticeably brighter band glow vs "Static"

**Do not proceed until the illustration looks like a radio.** Adjust geometry constants (`cabW`, `cabH`, dial positions, grille proportions) until it reads clearly. All changes are in the `Canvas` block — no structural code changes needed.

- [ ] **Step 3: Commit**

```bash
git add Vayl/Design/Components/Cards/CardFaces/RadioTunerCardFace.swift
git commit -m "feat(ob): add RadioTunerCardFace canvas illustration"
```

---

## Task 3 — VaylCardContent + VaylCardFace: Wire Up .radioTuner

**Files:**
- Modify: `Vayl/Design/Components/Cards/VaylCardContent.swift`
- Modify: `Vayl/Design/Components/Cards/VaylCardFace.swift`

- [ ] **Step 1: Add case to VaylCardContent**

In `VaylCardContent.swift`, replace the `.slotMachine` case comment and add `.radioTuner` below it:

```swift
/// Slot machine symbol face — used during GenderPhase.
/// Preserved for future reuse in card draw / prompt reveal mechanics.
case slotMachine

/// Vintage radio tuner face — used during GenderPhase.
/// signalStrength 0.0 (scanning) → 1.0 (locked). Dial progress 0.0–1.0.
case radioTuner(signalStrength: Double, leftDialProgress: Double, rightDialProgress: Double)
```

- [ ] **Step 2: Add case to VaylCardFace**

In `VaylCardFace.swift`, in the `if let content { switch content {` block (around line 74), add after the `.slotMachine` case:

```swift
case .radioTuner(let sig, let left, let right):
    RadioTunerCardFace(
        cardWidth:         size.width,
        cardHeight:        size.height,
        signalStrength:    sig,
        leftDialProgress:  left,
        rightDialProgress: right
    )
```

- [ ] **Step 3: Build to confirm no errors**

```bash
xcodebuild -scheme Vayl -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | grep -E "error:|Build succeeded"
```

Expected: `Build succeeded`

- [ ] **Step 4: Commit**

```bash
git add Vayl/Design/Components/Cards/VaylCardContent.swift Vayl/Design/Components/Cards/VaylCardFace.swift
git commit -m "feat(ob): add .radioTuner case to VaylCardContent + VaylCardFace"
```

---

## Task 4 — VaylDirector: Replace Slot Machine State with Radio State

**Files:**
- Modify: `Vayl/Features/Onboarding/Canvas/VaylDirector.swift`

### Context
Remove slot machine–specific state variables. Add pronouns drum state. Add `genderSignalStrength` (drives RadioTunerCardFace). Rename `genderReelSettleComplete` to `genderBothSettled` (computed: both drums settled).

State variables to REMOVE (slot machine only):
- `genderHandleOffset: CGFloat`
- `genderHandlePullComplete: Bool`
- `genderReelOffsets: [CGFloat]`
- `genderReelsSpinning: Bool`
- `genderSettledSymbols: [Int?]`
- `genderActiveReel: Int?`
- `genderReelSettleComplete: Bool`

State variables to ADD:
```swift
// Radio tuner
var genderSignalStrength:       Double  = 0    // 0 = searching, 1 = locked; drives RadioTunerCardFace
// Pronouns drum (mirrors gender drum pattern)
var genderPronounsOptions:      [String] = ["she/her", "he/him", "they/them", "ze/zir", "any pronouns", "prefer not to say"]
var genderPronounsDrumOffset:   CGFloat  = 0
var genderPronounsSelectedIndex: Int     = 0
var genderPronounsDrumSettled:  Bool     = false
```

Computed property to ADD (replaces `genderReelSettleComplete`):
```swift
var genderBothSettled: Bool { genderDrumSettled && genderPronounsDrumSettled }
```

- [ ] **Step 1: Remove slot machine state variables**

In the `@Observable @MainActor class VaylDirector` state block, delete these lines:
```swift
var genderHandleOffset:       CGFloat = 0
var genderHandlePullComplete: Bool    = false
var genderReelOffsets:        [CGFloat]  = [0, 0, 0]
var genderReelsSpinning:      Bool       = false
var genderSettledSymbols:     [Int?]     = [nil, nil, nil]
var genderActiveReel:         Int?       = nil
var genderReelSettleComplete: Bool       = false
```

- [ ] **Step 2: Add radio + pronouns state variables**

In the same state block, after `var genderDrumSettled: Bool = false`, add:

```swift
// Radio tuner signal state
var genderSignalStrength:        Double   = 0
// Pronouns drum
var genderPronounsOptions:       [String] = ["she/her", "he/him", "they/them", "ze/zir", "any pronouns", "prefer not to say"]
var genderPronounsDrumOffset:    CGFloat  = 0
var genderPronounsSelectedIndex: Int      = 0
var genderPronounsDrumSettled:   Bool     = false
```

- [ ] **Step 3: Add genderBothSettled computed property**

After the new state variables block (still inside the class), add:

```swift
var genderBothSettled: Bool { genderDrumSettled && genderPronounsDrumSettled }
```

- [ ] **Step 4: Update runGenderEntry() to reset new state**

In `runGenderEntry()`, remove resets for deleted state variables and add resets for new ones. The function should reset:

```swift
func runGenderEntry() {
    genderCardOffset         = .zero
    genderCardFlipScaleX     = 1.0
    genderCardFaceUp         = false
    genderCardVisible        = false
    genderCardSettled        = false
    genderDealerLineVisible  = false
    genderBeatComplete       = false
    genderDealerLine         = "Let's find your place at the table."
    genderSignalStrength     = 0
    genderSwipeHintActive    = false
    genderPickerVisible      = false
    genderOptions            = [
        "Man", "Woman", "Trans Man", "Trans Woman", "Non-binary",
    ]
    genderDrumOffset         = 0
    genderSelectedIndex      = 0
    genderDrumSettled        = false
    genderPronounsDrumOffset    = 0
    genderPronounsSelectedIndex = 0
    genderPronounsDrumSettled   = false
    genderShouldPocket       = false
}
```

- [ ] **Step 5: Update settleGenderDrum() to check genderBothSettled**

Replace the body of `settleGenderDrum(index:)` — remove all `genderSettledSymbols` and `genderActiveReel` writes. After setting `genderDrumSettled = true`, check `genderBothSettled` and fire the signal-lock sequence if both are settled:

```swift
func settleGenderDrum(index: Int) {
    genderSelectedIndex = index
    genderDrumSettled   = true
    if genderBothSettled { fireBothSettled() }
}
```

- [ ] **Step 6: Add settleGenderPronounsDrum()**

Add a new method mirroring `settleGenderDrum`:

```swift
func settleGenderPronounsDrum(index: Int) {
    genderPronounsSelectedIndex = index
    genderPronounsDrumSettled   = true
    if genderBothSettled { fireBothSettled() }
}
```

- [ ] **Step 7: Add fireBothSettled() — signal lock + dealer line**

```swift
/// Called once when both drums are settled. Locks the signal and shows "Found it."
private func fireBothSettled() {
    withAnimation(AppAnimation.standard) {
        genderSignalStrength = 1.0
    }
    withAnimation(AppAnimation.textProject.reduceMotionSafe) {
        genderDealerLine        = "Found it."
        genderDealerLineVisible = true
    }
    beginGenderSwipeHint()
}
```

- [ ] **Step 8: Update updateGenderDrum() — remove genderSettledSymbols write**

In `updateGenderDrum(offset:)`, remove the line:
```swift
genderSettledSymbols = [nil, nil, nil]  // REMOVE
genderActiveReel  = nil                  // REMOVE
```
Keep only:
```swift
func updateGenderDrum(offset: CGFloat) {
    genderDrumOffset  = offset
    genderDrumSettled = false
    genderSwipeHintActive = false
    if genderBothSettled {
        withAnimation(AppAnimation.standard) { genderSignalStrength = 0 }
        withAnimation(AppAnimation.textProject.reduceMotionSafe) { genderDealerLineVisible = false }
    }
}
```

- [ ] **Step 9: Add updateGenderPronounsDrum()**

```swift
func updateGenderPronounsDrum(offset: CGFloat) {
    genderPronounsDrumOffset  = offset
    genderPronounsDrumSettled = false
    genderSwipeHintActive     = false
    if genderBothSettled {
        withAnimation(AppAnimation.standard) { genderSignalStrength = 0 }
        withAnimation(AppAnimation.textProject.reduceMotionSafe) { genderDealerLineVisible = false }
    }
}
```

- [ ] **Step 10: Update confirmGenderSelection() to pass pronouns**

In `confirmGenderSelection(pronouns:)`, derive the actual pronouns value from `genderPronounsSelectedIndex`:

```swift
func confirmGenderSelection(pronouns: String?) {
    genderSwipeHintActive = false
    onboardingData.genderA   = genderOptions[genderSelectedIndex]
    onboardingData.pronounsA = pronouns ?? (
        genderPronounsOptions.indices.contains(genderPronounsSelectedIndex)
            ? genderPronounsOptions[genderPronounsSelectedIndex]
            : nil
    )
    withAnimation(AppAnimation.fast.reduceMotionSafe)    { genderPickerVisible = false }
    withAnimation(AppAnimation.cardPocket.reduceMotionSafe) { genderCardVisible = false }
    dissolutionT       = 0
    genderShouldPocket = true
}
```

- [ ] **Step 11: Build to confirm no errors**

```bash
xcodebuild -scheme Vayl -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | grep -E "error:|Build succeeded"
```

Expected: `Build succeeded` — GenderPhase.swift will have errors until Task 5 but focus on VaylDirector compiling cleanly.

- [ ] **Step 12: Commit**

```bash
git add Vayl/Features/Onboarding/Canvas/VaylDirector.swift
git commit -m "refactor(ob): replace slot machine director state with radio tuner + pronouns state"
```

---

## Task 5 — VaylDirector: Power-On Sequence (Replace Reel Spin)

**Files:**
- Modify: `Vayl/Features/Onboarding/Canvas/VaylDirector.swift`

### Context
`runGenderFlipAndSpin()` currently does: flip card → handle pull + reel spin (3 phases, ~1s total) → show picker. Replace with: flip card → brief power-on beat → show picker. The crystallisation sequence (Segment 1) and flip (Segment 2 beat A+B) are unchanged.

- [ ] **Step 1: Replace runGenderFlipAndSpin()**

Find `private func runGenderFlipAndSpin() async` and replace its entire body with:

```swift
@MainActor
private func runGenderFlipAndSpin() async {

    // ── Flip half 1 — collapse scaleX to 0 ───────────────────────────────
    withAnimation(AppAnimation.cardFlipHalf.reduceMotionSafe) {
        genderCardFlipScaleX = 0.0
    }
    try? await Task.sleep(for: .milliseconds(300))
    guard !Task.isCancelled else { return }

    // Face swap at scaleX = 0 — card is invisible, no visual pop
    genderCardFaceUp = true

    // Flip half 2 — expand scaleX back to 1
    withAnimation(AppAnimation.cardFlipHalf.reduceMotionSafe) {
        genderCardFlipScaleX = 1.0
    }
    try? await Task.sleep(for: .milliseconds(300))
    guard !Task.isCancelled else { return }

    // Beat C: hold so the radio face registers before dealer line fades
    try? await Task.sleep(for: .milliseconds(300))
    guard !Task.isCancelled else { return }
    genderBeatComplete = true

    // ── Power-on beat — brief pause before picker appears ─────────────────
    // Radio face is visible at signalStrength=0 (searching look).
    // Dealer line fades out, picker fades in after a short beat.
    try? await Task.sleep(for: .milliseconds(400))
    guard !Task.isCancelled else { return }

    withAnimation(AppAnimation.textProject.reduceMotionSafe) {
        genderDealerLineVisible = false
    }
    try? await Task.sleep(for: .milliseconds(180))
    guard !Task.isCancelled else { return }

    withAnimation(AppAnimation.standard.reduceMotionSafe) {
        genderPickerVisible = true
    }
}
```

- [ ] **Step 2: Update reduce-motion path in runGenderRise()**

In the `if reduceMotion { ... return }` block inside `runGenderRise`, remove all slot machine state writes and update to match new state:

```swift
if reduceMotion {
    genderCardOffset         = CGSize(width: 0, height: restY)
    genderCardVisible        = true
    dissolutionT             = 1
    genderCardSettled        = true
    genderDealerLineVisible  = false
    genderCardFaceUp         = true
    genderCardFlipScaleX     = 1.0
    genderBeatComplete       = true
    genderSignalStrength     = 0
    genderSwipeHintActive    = false
    genderPickerVisible      = true
    genderDrumOffset         = 0
    genderSelectedIndex      = 0
    genderDrumSettled        = false
    genderPronounsDrumOffset    = 0
    genderPronounsSelectedIndex = 0
    genderPronounsDrumSettled   = false
    genderShouldPocket       = false
    return
}
```

- [ ] **Step 3: Remove symbolSlotH from VaylDirector**

If there is a `let symbolSlotH: CGFloat = 58` or similar stored on the class (used in the old reel spin code), delete it. It's only needed by `SlotMachineCardFace` which is now self-contained.

- [ ] **Step 4: Build to confirm no errors**

```bash
xcodebuild -scheme Vayl -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | grep -E "error:|Build succeeded"
```

- [ ] **Step 5: Commit**

```bash
git add Vayl/Features/Onboarding/Canvas/VaylDirector.swift
git commit -m "refactor(ob): replace autonomous reel spin with radio power-on sequence"
```

---

## Task 6 — GenderPhase: Wire RadioTunerCardFace + Pronouns Drum

**Files:**
- Modify: `Vayl/Features/Onboarding/Phases/GenderPhase.swift`

### Context
Three changes: (1) Replace `SlotMachineCardFace` overlay with `RadioTunerCardFace` driven by director state. (2) Remove the `onChange(of: director.genderReelsSpinning)` observer and the `sensoryFeedback` for reel haptics. (3) Add a second drum picker (pronouns) beside the existing one. The confirm swipe is now gated on `director.genderBothSettled`.

- [ ] **Step 1: Remove reel-specific state and observers from the body**

In `GenderPhase.body`, remove:
```swift
// REMOVE this entire modifier:
.sensoryFeedback(.impact(weight: .medium), trigger: director.genderActiveReel) { _, new in
    new != nil
}

// REMOVE this entire onChange:
.onChange(of: director.genderReelsSpinning) { _, spinning in
    guard !spinning else { return }
    withAnimation(AppAnimation.spring.reduceMotionSafe) {
        drumBaseOffset = drumInitialOffset - CGFloat(director.genderSelectedIndex) * drumItemH
        drumDragOffset = 0
    }
    lastCenteredIndex = director.genderSelectedIndex
}
```

- [ ] **Step 2: Replace SlotMachineCardFace overlay with RadioTunerCardFace**

In `cardLayer`, find the `VaylCardFace().overlay(SlotMachineCardFace(...))` block and replace it:

```swift
// BEFORE
VaylCardFace()
    .overlay(
        SlotMachineCardFace(
            cardWidth:      cardWidth,
            cardHeight:     cardHeight,
            handleOffset:   director.genderHandleOffset,
            reelOffsets:    director.genderReelOffsets,
            settledSymbols: director.genderSettledSymbols,
            activeReel:     director.genderActiveReel
        )
    )
    .opacity(density * sharp)

// AFTER
VaylCardFace()
    .overlay(
        RadioTunerCardFace(
            cardWidth:         cardWidth,
            cardHeight:        cardHeight,
            signalStrength:    director.genderSignalStrength,
            leftDialProgress:  director.genderOptions.isEmpty ? 0 :
                Double(director.genderSelectedIndex) / Double(max(1, director.genderOptions.count - 1)),
            rightDialProgress: director.genderPronounsOptions.isEmpty ? 0 :
                Double(director.genderPronounsSelectedIndex) / Double(max(1, director.genderPronounsOptions.count - 1))
        )
    )
    .opacity(density * sharp)
```

- [ ] **Step 3: Gate swipe-confirm on genderBothSettled**

In the `cardLayer` DragGesture `.onEnded`, change the guard:

```swift
// BEFORE
guard director.genderReelSettleComplete else { return }

// AFTER (both occurrences — .onChanged and .onEnded)
guard director.genderBothSettled else { return }
```

- [ ] **Step 4: Add pronouns drum state variables to the View**

After the existing drum state variables, add:

```swift
// Pronouns drum state (mirrors gender drum)
@State private var pronounsBaseOffset:   CGFloat = 0
@State private var pronounsDragOffset:   CGFloat = 0
@State private var pronounsLastCentered: Int     = 0
@State private var pronounsHapticGen:    UISelectionFeedbackGenerator = UISelectionFeedbackGenerator()
```

- [ ] **Step 5: Add pronouns drum computed properties**

After the existing drum computed properties, add:

```swift
private var pronounsInitialOffset: CGFloat {
    CGFloat((director.genderPronounsOptions.count - 1) / 2) * drumItemH
}

private var pronounsScrollPosition: CGFloat {
    pronounsInitialOffset - pronounsBaseOffset - pronounsDragOffset
}

private var pronounsCurrentCenteredIndex: Int {
    let n = director.genderPronounsOptions.count
    guard n > 0 else { return 0 }
    let raw = (pronounsInitialOffset - pronounsBaseOffset - pronounsDragOffset) / drumItemH
    return max(0, min(n - 1, Int(raw.rounded())))
}
```

- [ ] **Step 6: Update pickerLayer to show two side-by-side drums**

Replace `pickerLayer` with a version that renders both drums side by side:

```swift
private var pickerLayer: some View {
    Group {
        if director.genderPickerVisible {
            HStack(spacing: AppSpacing.xl) {
                drumPickerView(
                    options:        director.genderOptions,
                    baseOffset:     $drumBaseOffset,
                    dragOffset:     $drumDragOffset,
                    lastCentered:   $lastCenteredIndex,
                    hapticGen:      drumHapticGen,
                    initialOffset:  drumInitialOffset,
                    scrollPosition: drumScrollPosition,
                    centeredIndex:  currentCenteredIndex,
                    onUpdate:       { director.updateGenderDrum(offset: $0) },
                    onSettle:       { director.settleGenderDrum(index: $0) }
                )
                drumPickerView(
                    options:        director.genderPronounsOptions,
                    baseOffset:     $pronounsBaseOffset,
                    dragOffset:     $pronounsDragOffset,
                    lastCentered:   $pronounsLastCentered,
                    hapticGen:      pronounsHapticGen,
                    initialOffset:  pronounsInitialOffset,
                    scrollPosition: pronounsScrollPosition,
                    centeredIndex:  pronounsCurrentCenteredIndex,
                    onUpdate:       { director.updateGenderPronounsDrum(offset: $0) },
                    onSettle:       { director.settleGenderPronounsDrum(index: $0) }
                )
            }
            .onAppear {
                drumBaseOffset    = drumInitialOffset
                pronounsBaseOffset = pronounsInitialOffset
                drumHapticGen.prepare()
                pronounsHapticGen.prepare()
            }
            .transition(.opacity)
        }
    }
    .offset(y: pickerOffsetY)
    .allowsHitTesting(director.genderPickerVisible)
}
```

- [ ] **Step 7: Refactor drumPickerView into a parameterised function**

Replace the existing `private var drumPickerView` computed property with a parameterised function so both drums can reuse it:

```swift
private func drumPickerView(
    options:        [String],
    baseOffset:     Binding<CGFloat>,
    dragOffset:     Binding<CGFloat>,
    lastCentered:   Binding<Int>,
    hapticGen:      UISelectionFeedbackGenerator,
    initialOffset:  CGFloat,
    scrollPosition: CGFloat,
    centeredIndex:  Int,
    onUpdate:       @escaping (CGFloat) -> Void,
    onSettle:       @escaping (Int) -> Void
) -> some View {
    let stripOffset = baseOffset.wrappedValue + dragOffset.wrappedValue

    return ZStack {
        Color.clear

        VStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.offset) { idx, option in
                Text(option)
                    .font(idx == centeredIndex
                        ? AppFonts.prompt.weight(.semibold)
                        : AppFonts.prompt)
                    .foregroundStyle(
                        idx == centeredIndex
                            ? AppColors.textPrimary
                            : AppColors.textSecondary
                    )
                    .frame(height: drumItemH)
                    .animation(.none, value: centeredIndex)
            }
        }
        .offset(y: stripOffset)
        .allowsHitTesting(false)
        .mask(
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.00),
                    .init(color: .black, location: 0.28),
                    .init(color: .black, location: 0.72),
                    .init(color: .clear, location: 1.00),
                ],
                startPoint: .top, endPoint: .bottom
            )
        )

        VStack(spacing: drumItemH - 1) {
            Rectangle().fill(AppColors.spectrumBorder).frame(height: 0.5)
            Rectangle().fill(AppColors.spectrumBorder).frame(height: 0.5)
        }
        .frame(height: drumItemH)
        .allowsHitTesting(false)
    }
    .frame(width: screenSize.width * 0.28, height: drumWindowH)
    .contentShape(Rectangle())
    .clipped()
    .gesture(
        DragGesture()
            .onChanged { value in
                director.endGenderSwipeHint()
                dragOffset.wrappedValue = value.translation.height
                let nowIdx = centeredIndex
                if nowIdx != lastCentered.wrappedValue {
                    lastCentered.wrappedValue = nowIdx
                    hapticGen.selectionChanged()
                }
                onUpdate(scrollPosition)
            }
            .onEnded { value in
                let n = options.count
                guard n > 0 else { return }
                let raw     = (initialOffset - baseOffset.wrappedValue - value.predictedEndTranslation.height) / drumItemH
                let snapped = max(0, min(n - 1, Int(raw.rounded())))
                let newBase = initialOffset - CGFloat(snapped) * drumItemH
                withAnimation(AppAnimation.spring.reduceMotionSafe) {
                    baseOffset.wrappedValue  = newBase
                    dragOffset.wrappedValue  = 0
                }
                lastCentered.wrappedValue = snapped
                onSettle(snapped)
            }
    )
}
```

- [ ] **Step 8: Update pickerOffsetY to account for two side-by-side drums**

The offset positions the drums above the card. Width doesn't change but verify the vertical position still clears the card:

```swift
// pickerOffsetY is unchanged — it centres the drum block above the card top.
// No change needed; HStack doesn't affect vertical positioning.
```

- [ ] **Step 9: Build and run in simulator**

```bash
xcodebuild -scheme Vayl -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | grep -E "error:|Build succeeded"
```

Run full OB in simulator. Navigate to GenderPhase. Confirm:
- Card deals, crystallises, flips to reveal the radio face (not slot machine)
- Brief beat then two side-by-side drum pickers appear above the card
- Scrolling the left drum moves the left dial needle on the card face
- Scrolling the right drum moves the right dial needle
- When both drums are settled, dealer line "Found it." appears and signal glow brightens on the band
- Swiping up on the card (only available after both settled) pockets the card and advances to ExperienceLevelPhase
- Corner deck card appears after confirm

- [ ] **Step 10: Commit**

```bash
git add Vayl/Features/Onboarding/Phases/GenderPhase.swift
git commit -m "feat(ob): wire RadioTunerCardFace + pronouns drum into GenderPhase"
```

---

## Task 7 — End-to-End Verification

Run the full OB flow as both user types and confirm all data writes.

- [ ] **Verification 1: Solo user ModeSelect**

Run OB. Tap through to ModeSelectPhase. Confirm:
- Dealer line: "Anyone at the table with you?"
- Left card lifts → "Just me for now" + "Starting on my own — for now."
- Right card lifts → "We're both here" + "We're doing this together."
- Swipe left card up → advances to GenderPhase

- [ ] **Verification 2: GenderPhase end-to-end**

Continue from Verification 1. Confirm:
- Radio card face visible (not slot machine)
- Both drums scrollable, dial needles respond
- "Found it." appears only after both drums settled
- Signal glow visible on frequency band when locked
- Swipe up on card after both settled → card pockets → ExperienceLevelPhase loads

- [ ] **Verification 3: Data writes on OB completion**

Add a temporary `print` before `OnboardingStore.commit(data:)` or check UserProfile after completion. Confirm:
- `genderA` = selected gender string (not nil)
- `pronounsA` = selected pronouns string (not nil)
- `appMode` = `.solo` (for this test run)
- `openerDeckType` is set (evaluateOpenerDeckType fired)

- [ ] **Verification 4: Corner deck**

Confirm `.gender` credential card appears in the corner deck after GenderPhase confirm (same as before — no change to credential append logic).

- [ ] **Final commit (if any cleanup needed)**

```bash
git add -p
git commit -m "fix(ob): verification cleanup"
```

---

## Notes

**Slot machine preserved:** `SlotMachineCardFace.swift` and `VaylCardContent.case slotMachine` are kept intact. Best future reuse: card draw / conversation prompt reveal in the deck game feature — the randomness mechanic is correct there.

**Geometry tuning:** RadioTunerCardFace geometry constants (`cabW`, `cabH`, dial positions, grille proportions) may need adjustment after seeing it on device. All tuning is inside the `Canvas` block in `RadioTunerCardFace.swift` — no other files affected.

**Pronouns list:** Current options: `["she/her", "he/him", "they/them", "ze/zir", "any pronouns", "prefer not to say"]`. Adjust in `runGenderEntry()` reset and the stored property default in VaylDirector — both are the same array, keep them in sync.
