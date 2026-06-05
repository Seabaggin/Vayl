# GenderPhase Confirm + Drum Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the text-hint "Swipe to confirm" with a card-swipe gesture (with an auto-tug affordance), remove the pronouns field, and polish the drum wheel with selection haptics, font-weight differentiation, and velocity-based momentum.

**Architecture:** All changes are confined to `GenderPhase.swift`. The view owns the three new pieces of purely-visual state (`cardTugOffset`, `borderPulseIntensity`, `lastCenteredIndex`). No director state is added — the tug sequence is an async Task fired from a view-side `onChange`. `confirmGenderSelection` continues to be called on the director, always passing `nil` for pronouns.

**Tech Stack:** SwiftUI, `UISelectionFeedbackGenerator` (UIKit, iOS 10+) for drum tick haptics, `DragGesture.Value.predictedEndTranslation` (iOS 16+) for momentum snap, `@MainActor` async Tasks for tug timing.

---

## File Map

| File | Change |
|------|--------|
| `Vayl/Features/Onboarding/Phases/GenderPhase.swift` | All changes — state, layout, gestures, animations |

No other files are touched.

---

### Task 1: Remove pronouns + simplify picker layout

**Files:**
- Modify: `Vayl/Features/Onboarding/Phases/GenderPhase.swift`

- [ ] **Step 1 — Delete `pronounsText` state and `pronounsFieldView`**

  Remove this line from the `@State` block:
  ```swift
  @State private var pronounsText: String = ""
  ```

  Remove the entire `pronounsFieldView` computed property (the `private var pronounsFieldView: some View { ... }` block).

- [ ] **Step 2 — Strip picker layer to drum-only**

  Replace `pickerLayer` with:
  ```swift
  private var pickerLayer: some View {
      Group {
          if director.genderPickerVisible {
              drumPickerView
                  .onAppear { drumBaseOffset = drumInitialOffset }
                  .transition(.opacity.animation(AppAnimation.standard.reduceMotionSafe))
          }
      }
      .offset(y: pickerOffsetY)
      .allowsHitTesting(director.genderPickerVisible)
  }
  ```

- [ ] **Step 3 — Simplify `pickerOffsetY` (no settle-adjust needed)**

  Replace the entire `pickerOffsetY` computed property with:
  ```swift
  /// Y-offset from ZStack centre to the drum centre.
  /// Positions the drum in the open space between the card top and the screen top.
  private var pickerOffsetY: CGFloat {
      director.genderCardOffset.height - cardHeight / 2 - AppSpacing.xxl - drumWindowH / 2
  }
  ```

- [ ] **Step 4 — Delete `confirmHintView`**

  Remove the entire `confirmHintView` computed property (the `private var confirmHintView: some View { ... }` block, including its `DragGesture`).

- [ ] **Step 5 — Build and preview**

  Open the "Full OB Flow" preview, jump to Gender phase. After reels settle, verify:
  - Picker shows only the drum wheel — no "Swipe to confirm" text, no pronouns field.
  - Drum appears and functions (drag scrolls, items snap).

---

### Task 2: Card swipe confirm with auto-tug affordance

**Files:**
- Modify: `Vayl/Features/Onboarding/Phases/GenderPhase.swift`

- [ ] **Step 1 — Add view-local state for tug and pulse**

  In the `// MARK: — Drum gesture state` block, add two new lines:
  ```swift
  @State private var cardTugOffset:        CGFloat = 0   // horizontal nudge for tug hint
  @State private var borderPulseIntensity: Double  = 0   // 0→1→0 during tug sequence
  ```

- [ ] **Step 2 — Add tug sequence trigger in `body`**

  In `body`, after the existing `.onChange(of: director.genderShouldPocket)` modifier, add:
  ```swift
  .onChange(of: director.genderReelSettleComplete) { _, complete in
      guard complete, !reduceMotion else { return }
      Task { @MainActor in
          // Wait for the winning-glow haptic burst to finish before hinting.
          try? await Task.sleep(for: .milliseconds(800))
          // Border pulse: spectrum glow charges up.
          withAnimation(.easeIn(duration: 0.18)) { borderPulseIntensity = 1.0 }
          try? await Task.sleep(for: .milliseconds(200))
          // Tug card right — fast, bouncy spring.
          withAnimation(.spring(response: 0.22, dampingFraction: 0.50)) { cardTugOffset = 22 }
          try? await Task.sleep(for: .milliseconds(230))
          // Spring back.
          withAnimation(AppAnimation.spring.reduceMotionSafe) { cardTugOffset = 0 }
          try? await Task.sleep(for: .milliseconds(320))
          // Border pulse fades out.
          withAnimation(.easeOut(duration: 0.28)) { borderPulseIntensity = 0.0 }
      }
  }
  ```

- [ ] **Step 3 — Apply tug offset and border pulse overlay to `cardLayer`**

  In `cardLayer`, find the chain that ends with:
  ```swift
  .offset(director.genderCardOffset)
  ```
  Replace it with:
  ```swift
  .offset(director.genderCardOffset)
  .offset(x: cardTugOffset)
  .overlay {
      RoundedRectangle(cornerRadius: AppRadius.obCard)
          .spectrumBorderGlow(intensity: borderPulseIntensity * 2.5)
          .opacity(borderPulseIntensity)
          .allowsHitTesting(false)
  }
  ```

- [ ] **Step 4 — Add swipe-right gesture to `cardLayer`**

  In `cardLayer`, after the `.scaleEffect(x: director.genderCardFlipScaleX, y: 1.0)` modifier (and before `.offset`), add:
  ```swift
  .gesture(
      DragGesture(minimumDistance: 30)
          .onEnded { value in
              // Only active after reels have settled.
              guard director.genderReelSettleComplete else { return }
              // Require a rightward swipe with limited vertical drift.
              guard value.translation.width  >  55  else { return }
              guard abs(value.translation.height) < 80 else { return }
              confirmedTrigger.toggle()   // triggers .sensoryFeedback(.success) in body
              director.confirmGenderSelection(pronouns: nil)
          }
  )
  ```

- [ ] **Step 5 — Build and preview**

  Jump to Gender phase. After reels settle:
  1. Wait ~1 second — verify card border pulses spectrum and card nudges right then springs back.
  2. Swipe the card right — verify success haptic fires and phase advances to experienceLevel.
  3. Test reduce-motion: enable in simulator → verify no tug animation, but card swipe still confirms.

---

### Task 3: Drum — selection haptic + font-weight differentiation

**Files:**
- Modify: `Vayl/Features/Onboarding/Phases/GenderPhase.swift`

- [ ] **Step 1 — Add `lastCenteredIndex` state**

  In the `// MARK: — Drum gesture state` block, add:
  ```swift
  @State private var lastCenteredIndex: Int = 0   // tracks previous item for selection haptic
  ```

- [ ] **Step 2 — Fire selection haptic on item change in `drumGesture.onChanged`**

  Replace the current `drumGesture` `onChanged` handler:
  ```swift
  // Current:
  .onChanged { value in
      drumDragOffset = value.translation.height
      director.updateGenderDrum(offset: drumScrollPosition)
  }
  ```
  With:
  ```swift
  .onChanged { value in
      drumDragOffset = value.translation.height
      let nowIdx = currentCenteredIndex
      if nowIdx != lastCenteredIndex {
          lastCenteredIndex = nowIdx
          UISelectionFeedbackGenerator().selectionChanged()
      }
      director.updateGenderDrum(offset: drumScrollPosition)
  }
  ```

- [ ] **Step 3 — Apply font-weight to selected drum item**

  In `drumPickerView`, find the `Text(option)` in the `ForEach` and replace it with:
  ```swift
  Text(option)
      .font(idx == currentCenteredIndex
          ? AppFonts.prompt.weight(.semibold)
          : AppFonts.prompt)
      .foregroundStyle(
          idx == currentCenteredIndex
              ? AppColors.textPrimary
              : AppColors.textSecondary
      )
      .frame(height: drumItemH)
      .animation(.none, value: currentCenteredIndex)  // prevent cross-fade on fast scroll
  ```

- [ ] **Step 4 — Build and verify**

  Jump to Gender phase. After picker appears:
  - Drag the drum slowly — verify a distinct tick haptic fires on each item change.
  - Verify the centred item renders visibly bolder than its neighbours.
  - Drag fast — verify no doubled or missed haptics at speed.

  > **Note:** If `AppFonts.prompt.weight(.semibold)` produces no visual difference (custom font may lack a semibold variant), fall back to using `AppFonts.display(AppFonts.promptSize, weight: .semibold, relativeTo: .title3)` — check with Bryan before substituting.

---

### Task 4: Drum — velocity-based momentum snap

**Files:**
- Modify: `Vayl/Features/Onboarding/Phases/GenderPhase.swift`

- [ ] **Step 1 — Replace `drumGesture.onEnded` with momentum-aware version**

  Replace the current `onEnded` handler:
  ```swift
  // Current:
  .onEnded { value in
      let n = director.genderOptions.count
      guard n > 0 else { return }
      let raw     = (drumInitialOffset - drumBaseOffset - drumDragOffset) / drumItemH
      let snapped = max(0, min(n - 1, Int(raw.rounded())))
      let newBase = drumInitialOffset - CGFloat(snapped) * drumItemH
      withAnimation(AppAnimation.spring.reduceMotionSafe) {
          drumBaseOffset = newBase
          drumDragOffset = 0
      }
      director.settleGenderDrum(index: snapped)
  }
  ```
  With:
  ```swift
  .onEnded { value in
      let n = director.genderOptions.count
      guard n > 0 else { return }
      // predictedEndTranslation extrapolates natural deceleration (iOS 16+).
      // Using it instead of raw translation gives the drum momentum when flicked.
      let raw     = (drumInitialOffset - drumBaseOffset - value.predictedEndTranslation.height) / drumItemH
      let snapped = max(0, min(n - 1, Int(raw.rounded())))
      let newBase = drumInitialOffset - CGFloat(snapped) * drumItemH
      withAnimation(AppAnimation.spring.reduceMotionSafe) {
          drumBaseOffset = newBase
          drumDragOffset = 0
      }
      lastCenteredIndex = snapped   // keep haptic tracking in sync after snap
      director.settleGenderDrum(index: snapped)
  }
  ```

- [ ] **Step 2 — Build and verify**

  Jump to Gender phase. After picker appears:
  - Slow drag: verify drum still snaps to nearest item (same as before).
  - Fast flick upward: verify drum travels 2–4 extra items before snapping (momentum carried).
  - Flick to edge of list: verify it clamps at item 0 or item 4 — never wraps or crashes.

---

## Self-Review

**Spec coverage:**
- ✅ Remove pronouns → Task 1
- ✅ Remove text hint → Tasks 1 + 2 (confirmHintView deleted, card swipe added)
- ✅ Auto-tug affordance with border pulse → Task 2
- ✅ Swipe card to confirm → Task 2
- ✅ Selection haptic on drum scroll → Task 3
- ✅ Font-weight on selected item → Task 3
- ✅ Velocity momentum → Task 4
- ✅ Reduce-motion respected → Task 2 (`guard !reduceMotion` before tug Task)

**Placeholder scan:** None. All code blocks are complete and show exact before/after.

**Type consistency:**
- `cardTugOffset: CGFloat` — used as `.offset(x: cardTugOffset)` ✅
- `borderPulseIntensity: Double` — used as `.spectrumBorderGlow(intensity: borderPulseIntensity * 2.5)` and `.opacity(borderPulseIntensity)` ✅
- `lastCenteredIndex: Int` — compared with `currentCenteredIndex: Int` (existing computed property) ✅
- `director.confirmGenderSelection(pronouns: nil)` — signature in `VaylDirector` is `func confirmGenderSelection(pronouns: String?)` ✅
- `value.predictedEndTranslation.height: CGFloat` — `DragGesture.Value.predictedEndTranslation` is `CGSize`, `.height` is `CGFloat` ✅
