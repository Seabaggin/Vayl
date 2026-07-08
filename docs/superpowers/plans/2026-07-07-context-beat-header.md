# Context Beat Header Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the transient, auto-dismissing pre-card `banner` context pill with a
persistent header that sits glued above the question, and center that
[kicker + question] block in the space between the draw row and the bottom
controls — matching `docs/superpowers/specs/2026-07-07-context-beat-header-design.md`.

**Architecture:** `banner`-type `context_beat_copy` stops routing through
`CoupleSessionStore.activeContextBeat` (the one-shot "show once, dismiss"
mechanism) entirely — that mechanism narrows to `interstitial` only. A new
`ContextKickerView` reads `Card.contextBeatCopy` directly and renders
persistently for as long as its card is current. `SessionPlayerView.screenLayer`
is restructured so the draw row stays pinned at the top (like the fan deck
above it) while the kicker+question(+back-flip) block centers independently
in the remaining space.

**Tech Stack:** SwiftUI, `@Observable` store, XCTest.

**Verification convention:** per project practice, build-verify (compile +
scoped unit test) is Claude's job; feel/motion/layout confirmation on device
is Bryan's. No task in this plan claims the layout "feels right" — only that
it matches the approved design.

---

### Task 1: `CoupleSessionStore` — narrow `activeContextBeat` to `interstitial` only

**Files:**
- Modify: `Vayl/Features/Sessions/CoupleSessionStore.swift:499-519` (`cardDidChange()`)
- Test: `VaylTests/CoupleSessionPlaythroughTests.swift`

- [ ] **Step 1: Write the failing test**

Add this test case to `VaylTests/CoupleSessionPlaythroughTests.swift`, alongside
the existing `test_fullCouplePlaythrough_persistsSessionAndReflection` etc.
(after line 76, inside the `CoupleSessionPlaythroughTests` class, using the
existing `makeStore`/`crossAirlock` helpers already defined in that file):

```swift
    // MARK: - Context beat gating (banner header vs. interstitial overlay)

    /// opener-01 has no beat, opener-02 is `.interstitial`, opener-05 is
    /// `.banner` (see Card.openerSamples). Banner must NOT arm activeContextBeat
    /// — it renders as a persistent ContextKickerView instead (SessionPlayerView),
    /// not the one-shot pre-card overlay.
    func test_contextBeat_armsForInterstitialOnly_notBanner() async throws {
        let (store, _) = makeStore(cardCount: 5)
        await crossAirlock(store)

        XCTAssertEqual(store.currentCard?.id, "opener-01")
        XCTAssertNil(store.activeContextBeat)

        store.dealNext()   // → opener-02, interstitial
        XCTAssertEqual(store.currentCard?.id, "opener-02")
        XCTAssertEqual(store.activeContextBeat?.type, .interstitial)
        XCTAssertEqual(store.activeContextBeat?.copy, store.currentCard?.contextBeatCopy)

        store.dealNext()   // → opener-03, no beat
        store.dealNext()   // → opener-04, no beat
        store.dealNext()   // → opener-05, banner
        XCTAssertEqual(store.currentCard?.id, "opener-05")
        XCTAssertEqual(store.currentCard?.contextBeatType, .banner)
        XCTAssertNil(store.activeContextBeat)
    }
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -project Vayl.xcodeproj -scheme Vayl -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:VaylTests/CoupleSessionPlaythroughTests/test_contextBeat_armsForInterstitialOnly_notBanner -quiet`

Expected: FAIL — the assertion on `opener-05` (`XCTAssertNil(store.activeContextBeat)`)
fails, because current `cardDidChange()` arms `activeContextBeat` for any
`hasContextBeat` card regardless of type.

If the sandbox can't boot a simulator to run this, build-verify instead
(`xcodebuild build -project Vayl.xcodeproj -scheme Vayl -destination 'generic/platform=iOS Simulator' -quiet`)
and flag for Bryan to run the test on device.

- [ ] **Step 3: Write minimal implementation**

Replace `Vayl/Features/Sessions/CoupleSessionStore.swift:499-519`:

```swift
    func cardDidChange() {
        showingCardBack = false
        revealRecomposing = false
        activeContextBeat = nil

        guard let card = currentCard else { return }

        if card.hasContextBeat,
           card.contextBeatType == .interstitial,
           let copy = card.contextBeatCopy,
           !beatShownCardIds.contains(card.id) {
            beatShownCardIds.insert(card.id)
            activeContextBeat = (.interstitial, copy)
        }

        if card.isRevealMechanic {
            revealEngine.beginCard(card.id)
        } else {
            revealEngine.teardown()
        }
    }
```

(Only the beat-arming block changed: `card.contextBeatType` is compared
directly against `.interstitial` instead of just unwrapped, and the tuple
construction hardcodes `.interstitial` since it's now the only case that
reaches this branch.)

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -project Vayl.xcodeproj -scheme Vayl -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:VaylTests/CoupleSessionPlaythroughTests -quiet`

Expected: PASS — all `CoupleSessionPlaythroughTests` cases pass, including the
new one.

- [ ] **Step 5: Commit**

```bash
git add Vayl/Features/Sessions/CoupleSessionStore.swift VaylTests/CoupleSessionPlaythroughTests.swift
git commit -m "fix(session): banner context beats no longer arm the pre-card overlay"
```

---

### Task 2: `ContextBeatType` doc comment — reflect banner's new meaning

**Files:**
- Modify: `Vayl/Core/Models/Enums/AppCardEnums.swift:205-212`

- [ ] **Step 1: Update the doc comment**

Replace lines 205-212:

```swift
/// Pre-card context beat type.
/// Banner is brief and auto-dismisses.
/// Interstitial is full screen and user-controlled.
/// Both appear before the card arrives — never on it.
enum ContextBeatType: String, Codable {
    case banner         // 1-2 lines, auto-dismiss 5 seconds, card dimmed behind
    case interstitial   // full screen, user controls dismissal
}
```

with:

```swift
/// Context beat type.
/// Banner is a short (1-2 line) kicker shown persistently above the card
/// while it's current (ContextKickerView) — it does NOT precede the card or
/// auto-dismiss.
/// Interstitial is full screen, appears BEFORE the card, user dismisses it.
enum ContextBeatType: String, Codable {
    case banner         // 1-2 lines, persistent header above the card (ContextKickerView)
    case interstitial   // full screen, before the card, user controls dismissal
}
```

- [ ] **Step 2: Build to verify it compiles**

Run: `xcodebuild build -project Vayl.xcodeproj -scheme Vayl -destination 'generic/platform=iOS Simulator' -quiet`

Expected: build succeeds (comment-only change).

- [ ] **Step 3: Commit**

```bash
git add Vayl/Core/Models/Enums/AppCardEnums.swift
git commit -m "docs(card): correct ContextBeatType doc comment for the banner header change"
```

---

### Task 3: `ContextBeatOverlayView` — drop the dead `banner` case

**Files:**
- Modify: `Vayl/Features/Sessions/Components/ContextBeatOverlayView.swift` (whole file)
- Modify: `Vayl/Features/Sessions/SessionPlayerView.swift:95-104`

After Task 1, nothing ever sets `activeContextBeat` to a `.banner` beat, so
`ContextBeatOverlayView`'s `banner` case is unreachable. Delete it and drop the
now-unused `type` parameter — the view only ever renders the interstitial now.

- [ ] **Step 1: Replace `ContextBeatOverlayView.swift`**

Replace the full contents of `Vayl/Features/Sessions/Components/ContextBeatOverlayView.swift`:

```swift
//
//  ContextBeatOverlayView.swift
//  Vayl
//
//  Full-screen pre-card context beat (spec §4.4, narrowed 2026-07-07 — the
//  old `banner` case moved to ContextKickerView, a persistent header on the
//  card itself). This view now only renders `interstitial`: full screen,
//  appears BEFORE the card presents, user-dismissed. Presentation only; the
//  store owns when a beat is active.
//

import SwiftUI

struct ContextBeatOverlayView: View {

    let copy: String
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            AppColors.void.ignoresSafeArea()
            VStack(spacing: AppSpacing.xl) {
                Text("worth knowing")
                    .font(AppFonts.overline)
                    .tracking(3)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.spectrumText)

                Text(copy)
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textBody)
                    .lineSpacing(AppSpacing.xs)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, AppSpacing.xl)

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onDismiss()
                } label: {
                    Text("got it")
                        .font(AppFonts.buttonLabel)
                        .foregroundStyle(AppColors.void)
                        .padding(.horizontal, AppSpacing.xl)
                        .padding(.vertical, AppSpacing.sm)
                        .background(Capsule().fill(AppColors.spectrumBorder))
                }
                .buttonStyle(.plain)
            }
        }
        .transition(.opacity)
    }
}
```

- [ ] **Step 2: Update the call site**

Replace `Vayl/Features/Sessions/SessionPlayerView.swift:95-104`:

```swift
            // Pre-card context beat (Section 3) — banner floats over the dimmed
            // card tap-through; interstitial holds until "got it".
            if let beat = store.activeContextBeat {
                ContextBeatOverlayView(
                    type: beat.type,
                    copy: beat.copy,
                    onDismiss: { store.dismissContextBeat() }
                )
                .zIndex(10)
            }
```

with:

```swift
            // Pre-card context beat (Section 3, narrowed 2026-07-07) — the only
            // remaining case is interstitial; it holds until "got it". Banner
            // now renders as a persistent ContextKickerView on the card itself
            // (see screenLayer).
            if let beat = store.activeContextBeat {
                ContextBeatOverlayView(
                    copy: beat.copy,
                    onDismiss: { store.dismissContextBeat() }
                )
                .zIndex(10)
            }
```

- [ ] **Step 3: Build to verify it compiles**

Run: `xcodebuild build -project Vayl.xcodeproj -scheme Vayl -destination 'generic/platform=iOS Simulator' -quiet`

Expected: build succeeds. No existing test references `ContextBeatOverlayView`
directly (confirmed by search before writing this plan), so no test changes
are needed here — Task 1's test already covers that banner beats no longer
reach this view at all.

- [ ] **Step 4: Commit**

```bash
git add Vayl/Features/Sessions/Components/ContextBeatOverlayView.swift Vayl/Features/Sessions/SessionPlayerView.swift
git commit -m "refactor(session): drop the dead banner case from ContextBeatOverlayView"
```

---

### Task 4: `ContextKickerView` — new component

**Files:**
- Create: `Vayl/Features/Sessions/Components/ContextKickerView.swift`

- [ ] **Step 1: Create the file**

```swift
//
//  ContextKickerView.swift
//  Vayl
//
//  Persistent context header for banner-type context_beat_copy (design spec
//  docs/superpowers/specs/2026-07-07-context-beat-header-design.md). Sits
//  glued directly above the question inside SessionPlayerView's centered
//  band. No dismiss affordance, no timer — visible for as long as its card
//  is current, and fades with the rest of screenLayer's existing dealing
//  animation (no independent wiring needed).
//

import SwiftUI

struct ContextKickerView: View {

    let copy: String

    var body: some View {
        Text(copy)
            .font(AppFonts.caption)
            .italic()
            .foregroundStyle(AppColors.textTertiary)
            .padding(.leading, AppSpacing.sm)
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(AppColors.spectrumPurple.opacity(0.5))
                    .frame(width: 2)
            }
    }
}

// MARK: - Preview

#Preview("Context Kicker") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        ContextKickerView(copy: "Jealousy has a memory. It's older than the two of you.")
            .padding(AppSpacing.xl)
    }
    .preferredColorScheme(.dark)
}
```

- [ ] **Step 2: Build to verify it compiles**

Run: `xcodebuild build -project Vayl.xcodeproj -scheme Vayl -destination 'generic/platform=iOS Simulator' -quiet`

Expected: build succeeds. This is a new, unused-so-far SwiftUI view — no unit
test, matching the project's existing convention of preview-only verification
for presentational components (`ContextBeatOverlayView`, `CardBackFlipView`
have none either).

- [ ] **Step 3: Commit**

```bash
git add Vayl/Features/Sessions/Components/ContextKickerView.swift
git commit -m "feat(session): add ContextKickerView, the persistent banner-context header"
```

---

### Task 5: Wire it in — `Card.hasContextKicker` + `SessionPlayerView` centered band

**Files:**
- Modify: `Vayl/Core/Models/Card.swift:48-51` (insert new derived property after `hasContextBeat`)
- Modify: `Vayl/Features/Sessions/SessionPlayerView.swift:170-188` (`screenLayer`)

- [ ] **Step 1: Add the gating property to `Card`**

Insert immediately after `hasContextBeat` (`Vayl/Core/Models/Card.swift:48-51`),
before `hasBackCopy`:

```swift
    /// Whether this card has a pre-card context beat.
    var hasContextBeat: Bool {
        contextBeatType != nil && contextBeatCopy != nil
    }

    /// Whether this card shows the persistent banner-context header
    /// (docs/superpowers/specs/2026-07-07-context-beat-header-design.md).
    /// Reveal mechanics get their own dedicated explanation screens instead —
    /// explicitly excluded here.
    var hasContextKicker: Bool {
        contextBeatType == .banner && !isRevealMechanic
    }
```

- [ ] **Step 2: Restructure `screenLayer`**

Replace `Vayl/Features/Sessions/SessionPlayerView.swift:170-188`:

```swift
    private var screenLayer: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            drawerRow
            if let card = store.currentCard {
                cardFace(card)
                if card.hasBackCopy, !card.isRevealMechanic {
                    CardBackFlipView(
                        backCopy: card.backCopy ?? "",
                        showingBack: store.showingCardBack,
                        onFlip: { store.flipCardBack() }
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppSpacing.xl)
        .padding(.bottom, 150)
        .frame(maxHeight: .infinity, alignment: .center)
    }
```

with:

```swift
    private var screenLayer: some View {
        VStack(alignment: .leading, spacing: 0) {
            drawerRow
                .padding(.bottom, AppSpacing.lg)

            if let card = store.currentCard {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    if card.hasContextKicker {
                        ContextKickerView(copy: card.contextBeatCopy ?? "")
                    }
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        cardFace(card)
                        if card.hasBackCopy, !card.isRevealMechanic {
                            CardBackFlipView(
                                backCopy: card.backCopy ?? "",
                                showingBack: store.showingCardBack,
                                onFlip: { store.flipCardBack() }
                            )
                        }
                    }
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppSpacing.xl)
        .padding(.bottom, 150)
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }
```

What changed and why: `drawerRow` is pulled out of the centered block and
given a fixed `AppSpacing.lg` bottom margin, matching the fan deck's own
top-pinned treatment above it — it no longer shifts position as card content
grows or shrinks. The card content (kicker + question, still `lg`-spaced from
the back-flip affordance exactly as before) is wrapped in its own
`.frame(maxHeight: .infinity, alignment: .center)`, which makes it expand to
fill the remaining space below `drawerRow` and center within *that* — not the
whole screen — so the existing `150`pt bottom clearance (unchanged, already
reserved for the controls) still applies. The kicker and question move as one
glued unit: `AppSpacing.sm` between them when the kicker is present, and no
extra gap at all when it isn't (SwiftUI's `VStack` only spaces children that
actually render).

- [ ] **Step 3: Build to verify it compiles**

Run: `xcodebuild build -project Vayl.xcodeproj -scheme Vayl -destination 'generic/platform=iOS Simulator' -quiet`

Expected: build succeeds.

- [ ] **Step 4: Hand off for device confirmation**

This step has no automated check — per project convention, layout/motion feel
is confirmed by Bryan on device, not simulated by Claude. Worth checking
specifically: `opener-05` (banner, short question — "What tends to trigger it
in you specifically?") for the kicker+question resting position, and a longer
no-kicker card (`opener-01`, "anchors/tethered") to confirm the band still
centers sensibly without one.

- [ ] **Step 5: Commit**

```bash
git add Vayl/Core/Models/Card.swift Vayl/Features/Sessions/SessionPlayerView.swift
git commit -m "feat(session): center the card band and wire in the persistent context kicker"
```
