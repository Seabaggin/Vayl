# Couple Session — Mockup Fidelity Fixes Implementation Plan

> **Execution note:** Bryan asked to one-shot all fixes without a permission gate, so the skill's "offer execution choice" handoff is skipped — this plan is executed inline immediately after saving. It is written to be reviewed *after* the fact.
>
> **TDD adaptation:** This is SwiftUI feel work. Per project convention ([[feedback_no_sim_runs]] — Claude compile-verifies, Bryan device-checks feel) there are no unit tests; each task's "done" is **compiles + matches the named mockup behavior**, and the final gate is a clean `xcodebuild`. This overrides the skill's pytest-checkbox default.

**Goal:** Close the fidelity gaps found in the 2026-06-21 mockup-vs-Swift audit so the built flow matches `docs/prototypes/couple-session-{carousel,airlock,hero-v2,close}.html`.

**Architecture:** Additive, low-risk changes confined to the session feature ([SessionPlayerView](Vayl/Features/Sessions/SessionPlayerView.swift), [AirlockView](Vayl/Features/Sessions/AirlockView.swift)) plus two small touches to the pre-existing carousel ([CardCarousel](Vayl/Design/Components/Cards/CardCarousel.swift), [CardChestContainer](Vayl/Features/Home/Components/CardChestContainer.swift)). No store/persistence changes. No new files. Tokens only; rendering-geometry numbers stay local as in `ScoreRing`.

**Tech Stack:** SwiftUI (iOS 16+, Swift 6), AttributedString for keyword highlighting, `rotation3DEffect` for the deal flip, `UIApplication.shared.isIdleTimerDisabled` for keep-awake (not banned — only `keyWindow`/`UIScreen.main` are).

---

## Scope: 11 fixes across 4 files

| # | Gap (from audit) | File | Risk |
|---|---|---|---|
| 1 | Prompt keyword highlighting | SessionPlayerView | low |
| 2 | Card 3D flip on deal | SessionPlayerView | med |
| 3 | Warp flash on dive | SessionPlayerView | low |
| 4 | Screenshot protection on sensitive cards | SessionPlayerView | low |
| 5 | Keep-awake (no sleep mid-session) | SessionPlayerView | low |
| 6 | Breathing ring glow when ready | AirlockView | low |
| 7 | Sync-tutorial "i" sheet | AirlockView | low |
| 8 | Copy: session "~min" + bandwidth "shared" | AirlockView | low |
| 9 | "tap to add" / "added" affordance | CardCarousel | low |
| 10 | Fly-to-corner flourish on add | CardCarousel | med |
| 11 | Start-button copy "Settle in →" | CardChestContainer | low |

**Justified divergences (NOT fixed, documented):**
- Drawer says "Partner" not "Alex" — "Alex" was mockup sample data; the partner's real name isn't plumbed into this local front-end, and [[ob_voice_individual]] cautions against guessing the partner. Keep "Partner" until name plumbing exists.
- Carousel **depth label** ("warming up"/"deep") — the mockup labels are sequence-position semantics with no clean `Card` field (`intensity`/`register` don't map 1:1). Deferred pending a content decision; not guessed.

---

## Task 1: Prompt keyword highlighting (SessionPlayerView)

**Files:** Modify `Vayl/Features/Sessions/SessionPlayerView.swift` (the `screenLayer` prompt + add a helper).

The prompt is flat `Text(store.currentCard?.text ?? "")`. Use `Card.highlightWords` to color those substrings with the spectrum core color (solid, per [[spectrum_glow_recipe]] — color the word, not a gradient on text).

- [ ] **Replace the prompt Text in `screenLayer`:**
```swift
            if let card = store.currentCard {
                highlightedPrompt(card)
                    .font(AppFonts.display(26, weight: .medium, relativeTo: .title))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineSpacing(AppSpacing.xs)
                    .fixedSize(horizontal: false, vertical: true)
            }
```

- [ ] **Add the helper (builds an AttributedString, colors each highlight run):**
```swift
    private func highlightedPrompt(_ card: Card) -> Text {
        guard !card.highlightWords.isEmpty else { return Text(card.text) }
        var attributed = AttributedString(card.text)
        for word in card.highlightWords {
            var cursor = attributed.startIndex
            while let range = attributed[cursor...].range(of: word) {
                attributed[range].foregroundColor = AppColors.spectrumCyan
                cursor = range.upperBound
            }
        }
        return Text(attributed)
    }
```

**Done:** compiles; opener cards (e.g. "anchors", "tethered") render those words in spectrum cyan against textPrimary.

---

## Task 2: Card 3D flip on deal (SessionPlayerView)

**Files:** Modify `Vayl/Features/Sessions/SessionPlayerView.swift` (`dealingCard`).

Mockup pulls a **face-down** card from the fan that flips face-up as the hold completes, then dives. Drive a double-sided flip off `fill` (0 → back at 180°, 1 → front at 0°), swap faces at the 90° midpoint.

- [ ] **Replace `dealingCard` with a flipping double-sided card:**
```swift
    private var dealingCard: some View {
        let pulledScale = 0.42 + 0.58 * fill
        let pulledY = -300 * (1 - fill)
        let angle = Angle(degrees: 180 * Double(1 - fill))   // 180 = back, 0 = front
        let showFront = fill >= 0.5

        return ZStack {
            cardBackFace.opacity(showFront ? 0 : 1)
            cardFrontFace
                .opacity(showFront ? 1 : 0)
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
        }
        .frame(width: 300, height: 212)
        .rotation3DEffect(angle, axis: (x: 0, y: 1, z: 0), perspective: 0.4)
        .shadow(color: AppColors.shadowDeep, radius: 24, y: 12)
        .scaleEffect(diving ? 3.4 : pulledScale)
        .opacity(diving ? 0 : 1)
        .blur(radius: diving ? 6 : 0)
        .offset(y: diving ? -20 : pulledY)
        .allowsHitTesting(false)
    }

    private var cardFrontFace: some View {
        RoundedRectangle(cornerRadius: AppRadius.obCard, style: .continuous)
            .fill(AppColors.cardBg)
            .overlay(
                Text(pendingPrompt)
                    .font(AppFonts.prompt)
                    .foregroundStyle(AppColors.textBody)
                    .multilineTextAlignment(.center)
                    .padding(AppSpacing.lg)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.obCard, style: .continuous)
                    .strokeBorder(AppColors.spectrumBorder, lineWidth: 1.1)
            )
    }

    private var cardBackFace: some View {
        RoundedRectangle(cornerRadius: AppRadius.obCard, style: .continuous)
            .fill(AppColors.cardBg)
            .overlay(
                Text("VAYL")
                    .font(AppFonts.display(13, weight: .medium, relativeTo: .body))
                    .tracking(7)
                    .foregroundStyle(AppColors.spectrumText)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.obCard, style: .continuous)
                    .strokeBorder(AppColors.spectrumBorder.opacity(0.6), lineWidth: 1.1)
            )
    }
```

**Done:** compiles; holding shows the VAYL back pulling down, flipping to the prompt past halfway, then diving. Reduce-motion path unaffected (commit still uses `AppAnimation.fast`).

---

## Task 3: Warp flash on dive (SessionPlayerView)

**Files:** Modify `Vayl/Features/Sessions/SessionPlayerView.swift` (add overlay in `body` ZStack).

- [ ] **Add a warp flash layer after the dealing card, keyed to `diving` (skip under reduce motion):**
```swift
            if diving && !reduceMotion {
                RadialGradient(
                    colors: [AppColors.spectrumPurple.opacity(0.28),
                             AppColors.spectrumMagenta.opacity(0.08),
                             .clear],
                    center: .center, startRadius: 0, endRadius: 320
                )
                .scaleEffect(diving ? 2.2 : 0.4)
                .opacity(diving ? 0 : 0.3)
                .blendMode(.screen)
                .allowsHitTesting(false)
                .ignoresSafeArea()
            }
```

**Done:** compiles; a spectrum flash blooms and clears as the card dives.

---

## Task 4: Screenshot protection on sensitive cards (SessionPlayerView)

**Files:** Modify `Vayl/Features/Sessions/SessionPlayerView.swift` (the `screenLayer` use site).

`Card.isSensitive` is true on some opener cards; the player never protects them. Apply `.screenshotProtected()` conditionally via the existing `.if` helper.

- [ ] **Wrap the `screenLayer` in the body:**
```swift
            screenLayer
                .if(store.currentCard?.isSensitive == true) { $0.screenshotProtected() }
                .opacity(holding ? Double(1 - fill) : 1)
                .animation(reduceMotion ? AppAnimation.fast : AppAnimation.standard, value: holding)
```

**Done:** compiles; on a sensitive card the prompt is screenshot-obscured.

---

## Task 5: Keep-awake (SessionPlayerView)

**Files:** Modify `Vayl/Features/Sessions/SessionPlayerView.swift` (`onAppear`/`onDisappear`).

The screen can sleep mid-session. Disable the idle timer for the player's lifetime. `UIApplication.shared.isIdleTimerDisabled` is allowed (only `keyWindow`/`UIScreen.main` are iOS-26-banned).

- [ ] **Set/unset in lifecycle:**
```swift
        .onAppear {
            scheduleIdle()
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            idleTask?.cancel()
            UIApplication.shared.isIdleTimerDisabled = false
        }
```

**Done:** compiles; idle timer disabled while in-session, restored on exit.

---

## Task 6: Breathing ring glow (AirlockView)

**Files:** Modify `Vayl/Features/Sessions/AirlockView.swift` (the ready-glow circle + a state flag).

The ready-state glow is static; mockup breathes it.

- [ ] **Add a breathing flag and drive the glow opacity:**
```swift
    @State private var glowBreathe = false
```
- [ ] **Replace the glow circle in `ring`:**
```swift
            Circle()
                .stroke(AppColors.spectrumBorder, lineWidth: 13)
                .blur(radius: 7)
                .opacity(ringAlive && (syncPhase == .ready || syncPhase == .synced)
                         ? (glowBreathe ? 0.85 : 0.4) : 0)
                .ambientAnimation(
                    .easeInOut(duration: AppAnimation.ambientPulse * 1.5).repeatForever(autoreverses: true),
                    value: glowBreathe
                )
```
- [ ] **Kick the loop in `ring`'s `.onChange(of: syncPhase)`:** set `glowBreathe = true` when `ringAlive`.

**Done:** compiles; the ring glow breathes while ready, holds steady when synced.

---

## Task 7: Sync-tutorial "i" sheet (AirlockView)

**Files:** Modify `Vayl/Features/Sessions/AirlockView.swift` (info button in `syncArea`, `@State`, a `.vaylSheet`).

Mockup's info button opens a two-phone explainer + 3 steps.

- [ ] **State:** `@State private var showSyncTutorial = false`
- [ ] **Info button** (top-trailing of `syncArea`, before the ring), tapping sets `showSyncTutorial = true`:
```swift
            HStack {
                Spacer()
                Button { showSyncTutorial = true } label: {
                    Image(systemName: "info.circle")
                        .font(AppFonts.bodyMedium)
                        .foregroundStyle(AppColors.textSecondary)
                }
                .buttonStyle(.plain)
            }
```
- [ ] **Attach the sheet on `syncArea`:** `.vaylSheet(isPresented: $showSyncTutorial, detents: [.medium]) { syncTutorialSheet }`
- [ ] **Sheet content:**
```swift
    private var syncTutorialSheet: some View {
        VStack(spacing: AppSpacing.lg) {
            VStack(spacing: AppSpacing.xs) {
                Text("Syncing to begin")
                    .font(AppFonts.sectionHeading)
                    .foregroundStyle(AppColors.textPrimary)
                Text("A shared breath, on both phones at once.")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            HStack(spacing: AppSpacing.md) {
                tutorialPhone
                Image(systemName: "arrow.left.arrow.right")
                    .foregroundStyle(AppColors.textTertiary)
                tutorialPhone
            }
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                tutorialStep(1, "Both of you press and hold. Each ring fills.")
                tutorialStep(2, "On a shared count, release at the same time.")
                tutorialStep(3, "Land close enough and you're in. Off, and it resets.")
            }
            Button { showSyncTutorial = false } label: {
                Text("Got it")
                    .font(AppFonts.ctaLabel)
                    .foregroundStyle(AppColors.textBody)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                        .strokeBorder(AppColors.spectrumBorder.opacity(0.4), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(AppSpacing.lg)
    }

    private var tutorialPhone: some View {
        RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
            .fill(AppColors.cardBg)
            .frame(width: 76, height: 138)
            .overlay(Circle().strokeBorder(AppColors.spectrumBorder, lineWidth: 3).frame(width: 44, height: 44))
            .overlay(RoundedRectangle(cornerRadius: AppRadius.md).strokeBorder(AppColors.borderDefault, lineWidth: 1))
    }

    private func tutorialStep(_ n: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            Text("\(n)")
                .font(AppFonts.buttonLabelSmall)
                .foregroundStyle(AppColors.textBody)
                .frame(width: 20, height: 20)
                .overlay(Circle().strokeBorder(AppColors.borderDefault, lineWidth: 1))
            Text(text)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
            Spacer()
        }
    }
```

**Done:** compiles; "i" opens the explainer; "Got it" dismisses.

---

## Task 8: Airlock copy (AirlockView)

**Files:** Modify `Vayl/Features/Sessions/AirlockView.swift` (header label + bandwidth subtitle).

- [ ] **Session label — add a rough estimate (~2 min/card):**
```swift
            Text("The Opener · \(store.hand.count) \(store.hand.count == 1 ? "card" : "cards") · ~\(max(1, store.hand.count * 2)) min")
```
- [ ] **Bandwidth subtitle — restore the "shared" signal (generic, no partner name):**
```swift
            Text("how much you've got tonight · shared")
```

**Done:** compiles; matches mockup phrasing without hardcoding "Alex".

---

## Task 9: "tap to add" / "added" affordance (CardCarousel)

**Files:** Modify `Vayl/Design/Components/Cards/CardCarousel.swift` (`carouselCard`, hoisted helper to protect type-check time).

Mockup shows a "tap to add" hint that becomes a check when picked. The Swift has the check badge but no hint label.

- [ ] **Add a bottom-aligned hint overlay on the active card in selecting mode** (inside `carouselCard`, after the existing `.overlay(alignment: .topTrailing)`):
```swift
        .overlay(alignment: .bottom) {
            if selecting && isActive && phase == .carousel {
                selectHint(added: selectedIDs.contains(cards[i].id))
            }
        }
```
- [ ] **Hoisted helper (keeps the modifier chain's type-check fast):**
```swift
    private func selectHint(added: Bool) -> some View {
        Text(added ? "added ✓" : "tap to add")
            .font(AppFonts.buttonLabelSmall)
            .textCase(.uppercase)
            .foregroundStyle(added ? AppColors.spectrumCyan : AppColors.textSecondary)
            .padding(.bottom, AppSpacing.md)
    }
```

**Done:** compiles; the active card shows "tap to add", switching to "added ✓" once selected.

---

## Task 10: Fly-to-corner flourish (CardCarousel)

**Files:** Modify `Vayl/Design/Components/Cards/CardCarousel.swift` (additive state + an overlay + trigger on add; existing physics untouched).

Mockup flings a tapped card to the corner deck. The Swift keeps the better toggle-in-place model; this adds the *arc feedback* as a transient ghost without changing selection semantics. The ghost flies toward top-trailing (the corner-deck direction in `CardChestContainer`).

- [ ] **State:**
```swift
    @State private var flyGhost = false
```
- [ ] **Trigger on add** in the active-card `onTapGesture` (only when adding, only with motion):
```swift
            .onTapGesture {
                if phase == .carousel && isActive {
                    if selecting {
                        let isAdd = !selectedIDs.contains(cards[i].id)
                        onToggleSelect?(cards[i])
                        if isAdd && !reduceMotion { triggerFlyGhost() }
                    } else {
                        onCardAction?(cards[i], .startSession)
                    }
                }
            }
```
- [ ] **Ghost overlay** added to `cardStack` ZStack (after `carouselCards`):
```swift
            if flyGhost {
                RoundedRectangle(cornerRadius: AppRadius.obCard, style: .continuous)
                    .fill(AppColors.cardBg)
                    .overlay(RoundedRectangle(cornerRadius: AppRadius.obCard)
                        .strokeBorder(AppColors.spectrumBorder, lineWidth: 1))
                    .frame(width: cardW, height: cardH)
                    .scaleEffect(flyGhost ? 0.16 : 1.0)
                    .offset(x: flyGhost ? 130 : 0, y: flyGhost ? -150 : 0)
                    .opacity(flyGhost ? 0 : 1)
                    .allowsHitTesting(false)
                    .animation(AppAnimation.cardPocket, value: flyGhost)
            }
```
- [ ] **Trigger function** (resets after the pocket animation):
```swift
    private func triggerFlyGhost() {
        flyGhost = false
        DispatchQueue.main.async {
            withAnimation(AppAnimation.cardPocket) { flyGhost = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) { flyGhost = false }
        }
    }
```

**Done:** compiles; tapping to add flings a ghost card up-and-right toward the corner deck, then the badge confirms selection. Reduce-motion skips the ghost.

**Note (approximation):** the ghost targets the carousel frame's top-trailing, not the exact corner-deck coordinate in the parent — a true cross-component arc would need a shared `matchedGeometryEffect`; deferred as over-engineering for this pass.

---

## Task 11: Start-button copy (CardChestContainer)

**Files:** Modify `Vayl/Features/Home/Components/CardChestContainer.swift` (`startHandButton` label).

Mockup's CTA reads "Settle in →" (the airlock language); the Swift says "Start · N cards".

- [ ] **Replace the label Text:**
```swift
            Text("Settle in  →")
                .font(AppFonts.buttonLabel)
                .foregroundStyle(AppColors.void)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                        .fill(AppColors.spectrumBorder)
                )
```

**Done:** compiles; CTA reads "Settle in →".

---

## Task 12: Verify

- [ ] **Clean build into isolated DerivedData (Xcode GUI holds the shared lock):**
```bash
xcodebuild -project Vayl.xcodeproj -scheme Vayl \
  -destination 'generic/platform=iOS Simulator' \
  -configuration Debug -derivedDataPath /tmp/vayl-dd-verify build
```
Expected: `** BUILD SUCCEEDED **`, no errors/warnings in the touched files.

---

## Self-review

- **Coverage:** all 6 ranked audit gaps + the 4 minor ones have a task (1–11). The two divergences are documented as intentional, not skipped silently.
- **Type consistency:** `fill`, `diving`, `pendingPrompt`, `reduceMotion` already exist in SessionPlayerView; `ringAlive`/`syncPhase` exist in AirlockView; `selecting`/`selectedIDs`/`isActive`/`cardW`/`cardH`/`phase`/`reduceMotion` exist in CardCarousel. New state: `glowBreathe`, `showSyncTutorial`, `flyGhost` — all introduced in their task.
- **No placeholders:** every code step is complete.
- **Risk:** CardCarousel changes are additive (new overlays/state/functions), no edits to the hand-tuned spring chains; helpers hoisted to protect type-check time.

---

## Execution notes (2026-06-21 — all tasks done, BUILD SUCCEEDED)

Two tasks were refined during implementation for correct animation behavior (the plan snippets above were simplified):

- **Task 3 (warp flash):** driven by a `@State warpProgress: CGFloat` (0→1) instead of a raw `diving` ternary. The flash renders while `diving` and reads `scaleEffect(0.4 + warpProgress*1.8)` / `opacity(0.35*(1-warpProgress))`; `commitDeal` resets it to 0 then animates to 1 over `diveSeconds`. The plan's `diving ? 0 : 0.3` would have rendered the flash invisible. `warpFlash` is its own computed property.
- **Task 10 (fly-ghost):** driven by `flyGhostActive: Bool` + `flyProgress: CGFloat` rather than one bool — the ghost must exist at the start state (progress 0) before animating to the corner, or the `if`-gated insert appears already-gone. Trigger sets active=true + progress=0, animates progress→1 over `AppAnimation.cardPocket`, clears after 0.55s.

One build miss caught + fixed: the `warpFlash` property was referenced in `body` before being defined (compile error `cannot find 'warpFlash' in scope`), then added. Final: `** BUILD SUCCEEDED **`, zero errors/warnings in touched files (`/tmp/vayl_build6.log`).
