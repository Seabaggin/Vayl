# OB Motion Token Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring every OB file onto the motion system — adopt the staple appliers where they exist, and tokenize all 32 raw animation values into named AppAnimation tokens — with ZERO feel change (every value moves verbatim).

**Architecture:** Values-only migration. Each raw `withAnimation(.easeOut(...))` / `.spring(...)` / `.timingCurve(...)` in OB code becomes a named token in `AppAnimation.swift` holding the exact same value, and the call site references the token. `OnboardingCanvasView.phaseHandoff` additionally adopts the new `AnyTransition.vaylDepth(.loud)` applier (same transition it hand-rolled). Three files are exempted with documentation comments because their values are computed, not constant.

**Tech Stack:** SwiftUI, existing `AppAnimation` token enum (Motion System section landed in commit 880b2d7), `AppMotion.swift` appliers.

**Verification model:** This is a feel-identical refactor — no unit tests exist for animation values, and none are added. The gates are: (1) the project builds, (2) the raw-value grep sweep returns empty at the end, (3) Bryan's device pass confirms no feel drift (per CLAUDE.md, build success ≠ done). Build command used throughout (isolated derived data — Bryan's Xcode may hold the default DB lock):

```bash
xcodebuild -project Vayl.xcodeproj -scheme Vayl -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/vayl-plan-dd build 2>&1 | grep -E "BUILD (SUCCEEDED|FAILED)|error:"
```

**Feel-identity rule for every task:** the token's value must be character-for-character the value removed from the call site. If a call site's value looks "wrong", tokenize it anyway and note it — re-tuning is device-pass work, never migration work.

---

### Task 1: phaseHandoff adopts the depth tokens + applier

**Files:**
- Modify: `Vayl/Features/Onboarding/Canvas/OnboardingCanvasView.swift` (the `phaseHandoff` computed var in `PhaseOverlayView`, ~lines 285–298)

- [ ] **Step 1: Replace the hand-rolled transition with the applier**

Old:

```swift
    private var phaseHandoff: AnyTransition {
        guard !reduceMotion else { return .opacity }
        // Confirmation → BuildDeck is a pixel-identical deck handoff (the collapsed
        // credential fan and BuildDeck's VaylDeckStack share point/size/face). A depth
        // scale would counter-scale the two near-identical decks about screen-centre and
        // double-image the swap. Both the leaving Confirmation and the arriving BuildDeck
        // evaluate this against the POST-advance phase, so keying on .buildDeck drops the
        // scale on BOTH sides of this one seam only — every other handoff keeps its depth.
        if director.phase == .buildDeck { return .opacity }
        return .asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 1.02)),
            removal:   .opacity.combined(with: .scale(scale: 0.97))
        )
    }
```

New (keep BOTH comments; the buildDeck exception is load-bearing):

```swift
    private var phaseHandoff: AnyTransition {
        // Confirmation → BuildDeck is a pixel-identical deck handoff (the collapsed
        // credential fan and BuildDeck's VaylDeckStack share point/size/face). A depth
        // scale would counter-scale the two near-identical decks about screen-centre and
        // double-image the swap. Both the leaving Confirmation and the arriving BuildDeck
        // evaluate this against the POST-advance phase, so keying on .buildDeck drops the
        // scale on BOTH sides of this one seam only — every other handoff keeps its depth.
        if director.phase == .buildDeck { return .opacity }
        // Staple 1, Loud register — the OB IS the loud register's reference implementation.
        // vaylDepth handles the Reduce Motion collapse to .opacity internally.
        return .vaylDepth(.loud)
    }
```

Note: `vaylDepth` reads `AppAnimation.depthLoudScaleIn/Out` (1.02 / 0.97 — the same literals removed here) and does its own `UIAccessibility.isReduceMotionEnabled` check, so the `guard !reduceMotion` line is intentionally dropped.

- [ ] **Step 1b: Delete the now-unused environment property**

`phaseHandoff` was the ONLY consumer of `PhaseOverlayView`'s reduce-motion environment value (`body`'s phase animation uses `.reduceMotionSafe`, which reads UIAccessibility directly). Remove this line from `PhaseOverlayView`:

```swift
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
```

- [ ] **Step 2: Build**

Run the build command from the header. Expected: `** BUILD SUCCEEDED **`, no new warnings mentioning OnboardingCanvasView.

- [ ] **Step 3: Commit**

```bash
git add Vayl/Features/Onboarding/Canvas/OnboardingCanvasView.swift
git commit -m "refactor(ob): phaseHandoff adopts vaylDepth(.loud) — literals promoted to tokens, zero feel change"
```

---

### Task 2: Name + Demo sequencer tokens

**Files:**
- Modify: `Vayl/App/Theme/AppAnimation.swift` (append inside the enum, after the Motion System section)
- Modify: `Vayl/Features/Onboarding/Canvas/Sequencers/NameSequencer.swift:217, :355`
- Modify: `Vayl/Features/Onboarding/Canvas/Sequencers/DemoSequencer.swift:298`

- [ ] **Step 1: Add the tokens**

Append inside `enum AppAnimation`, after the Motion System section's last member (`quietMaxTravel`), a new MARK:

```swift
    // MARK: — OB Ceremony Tokens (tokenized from raw call-site values, 2026-07-03)
    // Values moved VERBATIM from OB files during the motion-token migration — the token
    // contract ("zero raw values") now holds inside the OB too. All are Loud-register,
    // OB-only. Do not re-tune here without a device feel pass; do not reuse in main-app code.

    /// Spring — the name-entry write line kicking down as a character lands (NamePhase).
    /// Softer than keystrokeBounce (600/12): the line reacts, the key does the snapping.
    /// Reduce motion: skip — no bounce fires under reduce motion.
    static let writeLineBounce: Animation = .interpolatingSpring(stiffness: 320, damping: 16)

    /// Spring — the Demo noun field pulsing back after input is cleaned/capped (DemoPhase).
    /// Reduce motion: acceptable as-is — a 6pt settle, confirmation not travel.
    static let demoFieldPulse: Animation = .interpolatingSpring(stiffness: 320, damping: 14)

    /// 0.7s ease-out — the Name card being SET DOWN by the dealer (fades in a hair high +
    /// large, settles to rest). Not a deal: no flight, no slide. FEEL-GATE origin value.
    /// Reduce motion: skipped at call site — card appears at rest.
    static let cardSetDown: Animation = .easeOut(duration: 0.7)
```

- [ ] **Step 2: Swap the three call sites**

`NameSequencer.swift:217` — old:

```swift
        withAnimation(.interpolatingSpring(stiffness: 320, damping: 16)) {
            lineBounce = 0
        }
```

new:

```swift
        withAnimation(AppAnimation.writeLineBounce) {
            lineBounce = 0
        }
```

`NameSequencer.swift:355` — old:

```swift
        withAnimation(.easeOut(duration: 0.7)) {                           // FEEL-GATE: settle curve
```

new:

```swift
        withAnimation(AppAnimation.cardSetDown) {
```

`DemoSequencer.swift:298` — old:

```swift
        withAnimation(.interpolatingSpring(stiffness: 320, damping: 14)) { nounPulse = 0 }
```

new:

```swift
        withAnimation(AppAnimation.demoFieldPulse) { nounPulse = 0 }
```

- [ ] **Step 3: Build** — expected `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Commit**

```bash
git add Vayl/App/Theme/AppAnimation.swift \
  Vayl/Features/Onboarding/Canvas/Sequencers/NameSequencer.swift \
  Vayl/Features/Onboarding/Canvas/Sequencers/DemoSequencer.swift
git commit -m "refactor(ob): tokenize Name/Demo sequencer animation values — verbatim, zero feel change"
```

---

### Task 3: Curiosity tokens

**Files:**
- Modify: `Vayl/App/Theme/AppAnimation.swift` (append to the OB Ceremony Tokens MARK)
- Modify: `Vayl/Features/Onboarding/Canvas/Sequencers/CuriositySequencer.swift:193`
- Modify: `Vayl/Features/Onboarding/Phases/CuriosityPhase.swift:243`

- [ ] **Step 1: Add the token**

```swift
    /// 0.22s ease-in — the Curiosity DEMO card gliding partway off during the dealer's
    /// keep/pass demonstration (not the user's own throw — that's curiosityThrow).
    /// Reduce motion: the demo sequence is skipped entirely at the call site.
    static let curiosityDemoSwipe: Animation = .easeIn(duration: 0.22)
```

- [ ] **Step 2: Swap the call sites**

`CuriositySequencer.swift:193` — old:

```swift
        withAnimation(.easeIn(duration: 0.22)) {
            dragOffset = CGSize(width: dir * screenWidth * 0.28, height: 0)
        }
```

new:

```swift
        withAnimation(AppAnimation.curiosityDemoSwipe) {
            dragOffset = CGSize(width: dir * screenWidth * 0.28, height: 0)
        }
```

`CuriosityPhase.swift:243` — the raw `.easeOut(duration: 0.15)` IS the documented reduce-motion fallback value, which `AppAnimation.fast` holds exactly. Old:

```swift
            .animation(
                reduceMotion ? .easeOut(duration: 0.15)
                             : AppAnimation.cardSlide.delay(dealDelay),
                value: allCardsDealt
            )
```

new:

```swift
            .animation(
                reduceMotion ? AppAnimation.fast
                             : AppAnimation.cardSlide.delay(dealDelay),
                value: allCardsDealt
            )
```

- [ ] **Step 3: Build** — expected `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Commit**

```bash
git add Vayl/App/Theme/AppAnimation.swift \
  Vayl/Features/Onboarding/Canvas/Sequencers/CuriositySequencer.swift \
  Vayl/Features/Onboarding/Phases/CuriosityPhase.swift
git commit -m "refactor(ob): tokenize Curiosity demo-swipe + RM fallback — verbatim, zero feel change"
```

---

### Task 4: ThreeCardFan tokens (ExperienceLevel monte)

**Files:**
- Modify: `Vayl/App/Theme/AppAnimation.swift` (append to the OB Ceremony Tokens MARK)
- Modify: `Vayl/Design/Components/Cards/CardPhysics/ThreeCardFanController.swift:150, :176`

- [ ] **Step 1: Add the tokens**

```swift
    /// 0.42s ease-out — the monte fan OPENING into a ribbon spread before the turnover
    /// (ExperienceLevelPhase). FEEL-GATE origin value.
    /// Reduce motion: the spread sequence never runs (reveal() path).
    static let fanSpreadOpen: Animation = .easeOut(duration: 0.42)

    /// 0.42s ease-in-out — the spread RE-COLLECTING to the resting fan after the turnover.
    /// Symmetric ease: the close mirrors the open. Reduce motion: never runs.
    static let fanRecollect: Animation = .easeInOut(duration: 0.42)
```

- [ ] **Step 2: Swap the call sites**

`ThreeCardFanController.swift:150` — old: `withAnimation(.easeOut(duration: 0.42)) {` → new: `withAnimation(AppAnimation.fanSpreadOpen) {`

`ThreeCardFanController.swift:176` — old: `withAnimation(.easeInOut(duration: 0.42)) {` → new: `withAnimation(AppAnimation.fanRecollect) {`

- [ ] **Step 3: Build** — expected `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Commit**

```bash
git add Vayl/App/Theme/AppAnimation.swift \
  "Vayl/Design/Components/Cards/CardPhysics/ThreeCardFanController.swift"
git commit -m "refactor(ob): tokenize monte fan spread/recollect — verbatim, zero feel change"
```

---

### Task 5: CardMirrorDeal tokens (ModeSelect)

**Files:**
- Modify: `Vayl/App/Theme/AppAnimation.swift` (append to the OB Ceremony Tokens MARK)
- Modify: `Vayl/Design/Components/Cards/CardPhysics/CardMirrorDeal.swift:116, :290, :299, :316`

- [ ] **Step 1: Add the tokens**

```swift
    /// 0.88s deal-curve — the ModeSelect mirror deal: both cards travelling simultaneously
    /// from opposite screen edges, weighted deceleration (cubic 0,0,0.2,1 — the arrival
    /// family at its heaviest travel).
    /// Reduce motion: call path is guarded upstream by the phase's RM branch.
    static let mirrorDealTravel: Animation = .timingCurve(0, 0, 0.2, 1, duration: 0.88)

    /// 0.22s per half — the REJECTED mirror card turning face-down on confirm. Same cubic
    /// as cardFlipHalf (0.4, 0, 0.6, 1) but faster (0.22 vs 0.29): the discard turn is an
    /// aside, not a reveal. Two halves compose the 0.44s reject flip.
    static let mirrorRejectFlipHalf: Animation = .timingCurve(0.4, 0, 0.6, 1, duration: 0.22)

    /// 0.42s — the rejected card sliding back toward its origin and fading. Same
    /// ease-into-motion-then-accelerate-away cubic as cardPocket (0.4, 0, 1, 1), shorter:
    /// the discard leaves, it is not filed.
    static let mirrorRejectExit: Animation = .timingCurve(0.4, 0, 1, 1, duration: 0.42)
```

- [ ] **Step 2: Swap the four call sites**

`:116` — old: `withAnimation(.timingCurve(0, 0, 0.2, 1, duration: 0.88)) {` → new: `withAnimation(AppAnimation.mirrorDealTravel) {`

`:290` and `:299` — old (both): `withAnimation(.timingCurve(0.4, 0, 0.6, 1, duration: 0.22)) {` → new (both): `withAnimation(AppAnimation.mirrorRejectFlipHalf) {`

`:316` — old: `withAnimation(.timingCurve(0.4, 0, 1, 1, duration: 0.42)) {` → new: `withAnimation(AppAnimation.mirrorRejectExit) {`

- [ ] **Step 3: Build** — expected `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Commit**

```bash
git add Vayl/App/Theme/AppAnimation.swift \
  "Vayl/Design/Components/Cards/CardPhysics/CardMirrorDeal.swift"
git commit -m "refactor(ob): tokenize mirror-deal travel/reject animations — verbatim, zero feel change"
```

---

### Task 6: BuildDeck forge tokens (14 sites — the big one)

**Files:**
- Modify: `Vayl/App/Theme/AppAnimation.swift` (append to the OB Ceremony Tokens MARK)
- Modify: `Vayl/Features/Onboarding/Phases/BuildDeckPhase.swift:266, :269, :314, :362, :380, :381, :384, :419, :427, :456, :480, :497, :499, :524, :542, :545`

- [ ] **Step 1: Add the tokens**

```swift
    // — BuildDeck forge ceremony (Beats 1–7). All Loud-register, ceremony-class:
    //   these tokens must NEVER appear outside BuildDeckPhase / the OB canvas.

    /// Spring pair — the stage JOLT on a case strike: hard kick in (0.12/0.5), settle (0.32/0.7).
    static let strikeJolt:       Animation = .spring(response: 0.12, dampingFraction: 0.5)
    static let strikeJoltSettle: Animation = .spring(response: 0.32, dampingFraction: 0.7)

    /// Spring — the case yawing back to rest after a directional strike recoil.
    static let strikeRecoilReturn: Animation = .spring(response: 0.3, dampingFraction: 0.55)

    /// Spring — the case settling after an autonomous knock twitch (the deck wants out).
    /// Lower damping than strikeRecoilReturn: the knock wobbles, the strike is commanded.
    static let knockReturn: Animation = .spring(response: 0.35, dampingFraction: 0.5)

    /// Spring pair — the stage jolt on the SHATTER (third strike): heavier than a strike
    /// (0.18/0.6 in, 0.4/0.7 settle) — the climax lands harder than its wind-up.
    static let shatterJolt:       Animation = .spring(response: 0.18, dampingFraction: 0.6)
    static let shatterJoltSettle: Animation = .spring(response: 0.4, dampingFraction: 0.7)

    /// 0.5s ease-out — the white flash decaying after the case bursts.
    static let burstFlashDecay: Animation = .easeOut(duration: 0.5)

    /// 0.34s ease-in — the revealed deck (cards + title + CTA) sinking away on hand-off
    /// to the founder letter. FEEL-GATE origin value.
    static let deckExitSink: Animation = .easeIn(duration: 0.34)

    /// 0.5s ease-in-out — the founder letter sheet rising bottom → full. FEEL-GATE origin.
    static let letterRise: Animation = .easeInOut(duration: 0.5)

    /// 2.6s ease-in — the credential deck MELTING down through the felt (Beat 1).
    /// Ceremony-class duration: the forge's slowest, heaviest move.
    static let deckMeltDown: Animation = .easeIn(duration: 2.6)

    /// 1.0s ease-out — the forged case fading in on the felt (Beat 3a).
    static let caseFadeIn: Animation = .easeOut(duration: 1.0)

    /// 2.0s ease-in-out — the standing case taking the air and scaling up (Beat 3c dolly).
    static let caseFloatLift: Animation = .easeInOut(duration: 2.0)

    /// 1.4s ease-out — the table's rim + sway settling to rest as the felt lets the case go.
    static let forgeSettle: Animation = .easeOut(duration: 1.4)

    /// 1.2s ease-in-out — the case core lighting up once armed (contained energy).
    static let coreCharge: Animation = .easeInOut(duration: 1.2)

    /// 0.9s / 1.3s — one leg of the forge's rim-glow and topo-sway oscillations (Beat 1–2,
    /// "the table works"). Raw Doubles per the ambient-duration convention: build at the
    /// call site with .easeInOut(duration:) + .repeatForever(autoreverses: true).
    /// Reduce motion: the oscillation never starts (steady mid glow, still lines).
    static let forgeRimOscillation:  Double = 0.9
    static let forgeSwayOscillation: Double = 1.3
```

- [ ] **Step 2: Swap the sixteen call sites** (verbatim value → token; surrounding code unchanged)

| Line | Old | New |
|---|---|---|
| 266 | `withAnimation(.spring(response: 0.12, dampingFraction: 0.5)) { stagePunch = true }` | `withAnimation(AppAnimation.strikeJolt) { stagePunch = true }` |
| 269 | `withAnimation(.spring(response: 0.32, dampingFraction: 0.7)) { stagePunch = false }` | `withAnimation(AppAnimation.strikeJoltSettle) { stagePunch = false }` |
| 314 | `withAnimation(.spring(response: 0.3, dampingFraction: 0.55).reduceMotionSafe) {` | `withAnimation(AppAnimation.strikeRecoilReturn.reduceMotionSafe) {` |
| 362 | `withAnimation(.spring(response: 0.35, dampingFraction: 0.5).reduceMotionSafe) {` | `withAnimation(AppAnimation.knockReturn.reduceMotionSafe) {` |
| 380 | `withAnimation(.easeOut(duration: 0.5)) { burstFlashOpacity = 0 }` | `withAnimation(AppAnimation.burstFlashDecay) { burstFlashOpacity = 0 }` |
| 381 | `withAnimation(.spring(response: 0.18, dampingFraction: 0.6)) { stagePunch = true }` | `withAnimation(AppAnimation.shatterJolt) { stagePunch = true }` |
| 384 | `withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { stagePunch = false }` | `withAnimation(AppAnimation.shatterJoltSettle) { stagePunch = false }` |
| 419 | `withAnimation(.easeIn(duration: 0.34).reduceMotionSafe) { revealExiting = true }   // FEEL-GATE` | `withAnimation(AppAnimation.deckExitSink.reduceMotionSafe) { revealExiting = true }` |
| 427 | `withAnimation(.easeInOut(duration: 0.5).reduceMotionSafe) {          // FEEL-GATE: the rise` | `withAnimation(AppAnimation.letterRise.reduceMotionSafe) {` |
| 456 | `withAnimation(.easeIn(duration: 2.6).reduceMotionSafe) { deckMelt = 1 }` | `withAnimation(AppAnimation.deckMeltDown.reduceMotionSafe) { deckMelt = 1 }` |
| 480 | `withAnimation(.easeOut(duration: 1.0).reduceMotionSafe) { caseOpacity = 1 }` | `withAnimation(AppAnimation.caseFadeIn.reduceMotionSafe) { caseOpacity = 1 }` |
| 497 | `withAnimation(.easeInOut(duration: 2.0).reduceMotionSafe) { caseFloat = true }` | `withAnimation(AppAnimation.caseFloatLift.reduceMotionSafe) { caseFloat = true }` |
| 499 | `withAnimation(.easeOut(duration: 1.4).reduceMotionSafe) {` | `withAnimation(AppAnimation.forgeSettle.reduceMotionSafe) {` |
| 524 | `withAnimation(.easeInOut(duration: 1.2).reduceMotionSafe) { coreEnergy = 0.40 }` | `withAnimation(AppAnimation.coreCharge.reduceMotionSafe) { coreEnergy = 0.40 }` |
| 542 | `withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {` | `withAnimation(.easeInOut(duration: AppAnimation.forgeRimOscillation).repeatForever(autoreverses: true)) {` |
| 545 | `withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) {` | `withAnimation(.easeInOut(duration: AppAnimation.forgeSwayOscillation).repeatForever(autoreverses: true)) {` |

(Line numbers are pre-edit anchors; match on the old strings, which are unique in the file.)

- [ ] **Step 3: Build** — expected `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Commit**

```bash
git add Vayl/App/Theme/AppAnimation.swift Vayl/Features/Onboarding/Phases/BuildDeckPhase.swift
git commit -m "refactor(ob): tokenize the 16 BuildDeck forge animation values — verbatim, zero feel change"
```

---

### Task 7: Exemption comments + final sweep gate

**Files:**
- Modify: `Vayl/Features/Onboarding/Renders/AnimatedSignature.swift:~86` (above the three withAnimation calls)
- Modify: `Vayl/Design/Components/Cards/CardPhysics/CarouselPhysics.swift:~90`
- Modify: `Vayl/Features/Onboarding/Phases/ConfirmationPhase.swift:~255`
- Modify: `CLAUDE.md` (Violation Checklist)

- [ ] **Step 1: Document the three computed-value exemptions**

These sites construct animations from COMPUTED durations/parameters, so there is no constant to
tokenize — mark each so future sweeps skip them knowingly. Add directly above the respective calls:

`AnimatedSignature.swift` (one comment above the group of three):

```swift
        // TOKEN-EXEMPT: durations derive from per-stroke path lengths (geometry-driven),
        // not constants — there is no value to hoist into AppAnimation.
```

`CarouselPhysics.swift`:

```swift
        // TOKEN-EXEMPT: spring parameters come from the caller's CarouselConfig —
        // this is a parameterized engine, not a raw value.
```

`ConfirmationPhase.swift` (above the `.easeOut(duration: exitSpan)` call):

```swift
        // TOKEN-EXEMPT: exitSpan is computed from the per-card stagger so the fade
        // spans the whole gather — duration is derived, not a constant.
```

- [ ] **Step 2: Add the checklist line to CLAUDE.md**

In the `## Violation Checklist` section, after the line `- [ ] No raw colors, fonts, spacing, radius, or opacity in Views`, insert:

```markdown
- [ ] No raw animation curves/durations anywhere (Views, Stores, sequencers) — AppAnimation tokens only; screen/content transitions use a motion staple (`.vaylDepth` / `arrive` / tap contract), never ad hoc slides (spec: docs/superpowers/specs/2026-07-03-motion-system-design.md)
```

- [ ] **Step 3: Run the final sweep — must be empty**

```bash
grep -rn "\.easeOut(duration\|\.easeIn(duration\|\.easeInOut(duration\|\.timingCurve(\|interpolatingSpring(stiffness\|\.spring(response" \
  Vayl/Features/Onboarding Vayl/Design/Components/Cards/CardPhysics --include="*.swift" \
  | grep -v "AppAnimation\|AppDealerTyping\|TOKEN-EXEMPT-LINE" \
  | grep -vE "^\S+:\d+:\s*(//|///)" \
  | grep -v "AnimatedSignature.swift\|CarouselPhysics.swift\|ConfirmationPhase.swift"
```

Expected: no output. (The three exempted files are excluded by name; anything else that
surfaces is a missed site — tokenize it the same way before proceeding.)

- [ ] **Step 4: Build** — expected `** BUILD SUCCEEDED **`.

- [ ] **Step 5: Commit**

```bash
git add Vayl/Features/Onboarding/Renders/AnimatedSignature.swift \
  "Vayl/Design/Components/Cards/CardPhysics/CarouselPhysics.swift" \
  Vayl/Features/Onboarding/Phases/ConfirmationPhase.swift CLAUDE.md
git commit -m "refactor(ob): token-exempt comments for computed-value sites + motion checklist line"
```

---

## Out of scope (later plans, per spec §7)

- Tab bar `orbSnap` → `orbGlide` migration (step 2) — first *feelable* surface, its own pass.
- `vaylSheet` / `vaylCover` arrival adoption (step 3).
- Quiet depth at tab-content swaps (step 4), cascade + refusal call sites (step 5).

## Done means

All 7 tasks committed, final grep empty, build green — then **Bryan's device OB run-through
confirms zero feel drift** (same timings, same curves; nothing should look different at all).
