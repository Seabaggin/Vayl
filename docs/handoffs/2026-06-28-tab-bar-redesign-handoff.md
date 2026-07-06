# Tab Bar Redesign Handoff
**Date:** 2026-06-28
**Branch:** feat/pulse-redesign-2d-circumplex
**Status:** Blocked — animation regression; file restored to last known-good state

---

## Goal

Replace the filled-pill racetrack tab bar with a cleaner design:

- Spectrum-colored icon only (no label, no filled pill background)
- Keep the draw/undraw racetrack ring animation (`Capsule().trim`)
- Industry-standard capsule bar: ~56pt tall, 32pt horizontal inset, 24pt icons

The bar should feel like the original but visually lighter — spectrum icon instead of white icon on a dark pill, ring around bare icon instead of around pill.

---

## Last Known-Good State

**Git SHA:** `597ce8f`
**File:** `Vayl/Design/Components/Navigation/RacetrackTabBar.swift`

The file has been restored to this commit. The animation works here.

Key structural facts about the working version:
- Selected state = dark filled pill (`pillBackground` + `.clipShape(Capsule())`)
- Racetrack border = `Capsule().trim(from:to:)` as `.overlay` AFTER `clipShape` (outside the clip, naturally constrained to pill frame)
- `withAnimation { trimValues[old] = 0 }` fires synchronously in `runSequence` — no `DispatchQueue.main.async` wrapper
- The trim animation propagates correctly because the `Capsule()` overlay sits inside the button label hierarchy at a fixed, pill-sized frame

---

## What Was Attempted This Session

### Round 1: Visual redesign
- Replaced filled pill with transparent background
- Switched icon foreground to `AppColors.spectrumText` (spectrum gradient) for selected state
- Removed labels
- Replaced `Capsule()` trim with `Circle()` trim (to ring around bare icon)
- Changed `RacetrackTabPill` → `TabIcon`

Result: draw animation worked, undraw stopped working.

### Round 2: ZStack restructure
The ring was moved out of the button label into a `ZStack` sibling:
```swift
ZStack {
    Button { ... }
    racetrackRing.allowsHitTesting(false)
}
```
Theory: the button's `.animation(value: isSelected)` was eating the `withAnimation` propagation to the ring inside the label.

Result: ring became unconstrained (ZStack + `frame(maxWidth: .infinity)` = ring fills full slot width ~62pt), bar became much thicker than intended. Undraw still broken.

### Round 3: Overlay on Button
Moved ring to `.overlay` on the Button (not inside label, not in ZStack):
```swift
Button { ... }
    .buttonStyle(.plain)
    .overlay(racetrackRing)
```
Button's natural size = 40pt (24pt icon + 8pt padding each side), ring constrained correctly. Size fixed.

Draw animation still worked. Undraw still broken.

Added `DispatchQueue.main.async` around the undraw `withAnimation` to give it a separate render pass away from the `selection = tab` batch. Still broken.

### Round 4: Animatable ViewModifier
```swift
private struct RacetrackRing: ViewModifier, Animatable {
    var trimEnd: CGFloat
    var animatableData: CGFloat { get { trimEnd } set { trimEnd = newValue } }
    func body(content: Content) -> some View {
        content.overlay(Circle().trim(from: 0, to: trimEnd).stroke(...))
    }
}
```
Applied as `.modifier(RacetrackRing(trimEnd: trimEnd))`. Worst result — animation broke entirely.

---

## Root Cause Hypothesis

The original `Capsule().trim` overlay worked because it lived **inside the button label**, anchored to the pill's clipped frame. It was part of the same view tree that `withAnimation` naturally walked.

Switching to `Circle()` outside the button's label (as `.overlay` or ZStack sibling) appears to break `withAnimation` propagation for the undraw — possibly because:

1. SwiftUI batches `selection = tab` with the synchronous `withAnimation { trimValues[old] = 0 }` into one render pass dominated by the non-animated selection change, stripping the animation from the trim update
2. The `Animatable` modifier approach didn't help — likely because `trimEnd` is a `let` constant on `TabIcon`, so when the parent re-renders with a new value, SwiftUI may be diffing it as a new view instance rather than animating the existing one

The undraw animation almost certainly requires the ring to be inside the button label hierarchy (like the original), OR the `trimValues` state to drive the animation from within the same view that owns it via a `@Binding` rather than a passed `let`.

---

## Recommended Next Approach

Keep the ring **inside** the button label as an overlay on the icon frame, not on the pill. This mirrors the original structure that proved the animation works:

```swift
Button(action: onTap) {
    Image(systemName: tab.icon)
        .font(.system(size: 24, weight: .regular))
        .foregroundStyle(isSelected ? AnyShapeStyle(AppColors.spectrumText) : AnyShapeStyle(AppColors.textSecondary))
        .frame(width: 24, height: 24)
        .padding(AppSpacing.sm)
        // Ring as overlay inside the label, constrained to the 40pt frame
        .overlay(
            Circle()
                .trim(from: 0, to: trimEnd)
                .stroke(
                    AngularGradient(colors: [...], center: .center),
                    style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: AppColors.accentPrimary.opacity(0.7), radius: 4)
        )
}
.buttonStyle(.plain)
```

No explicit `.animation(value: trimEnd)` needed — the `withAnimation` in `runSequence` should propagate naturally since the ring is inside the label, same as the working original. Do NOT add `.animation(value: isSelected)` to the icon foreground — that's what interfered with animation propagation in earlier iterations.

If undraw STILL doesn't work with the ring inside the label, the fallback is: keep `Capsule().trim` instead of `Circle().trim` (just scaled down, or with zero corner radius via a rounded rect shape), since that's what the original used and it's confirmed-working.

---

## Constraints for Next Attempt

- Do NOT touch `AppShell.swift` — tab bar positioning is correct (`.safeAreaInset` + `.padding(.top, sm) + .padding(.bottom, xs)`)
- Do NOT add explicit `.animation(value:)` on any icon foreground style — prior iterations confirmed it interferes
- Do NOT use `DispatchQueue.main.async` for the undraw — the original works without it; adding it made no difference
- Ring must live inside the button label hierarchy to match the structure that proved animatable
- `isAnimating` guard must stay — prevents mid-sequence taps from corrupting state
- `onAppear { trimValues[selection] = 1.0 }` must stay to initialize the selected ring on first load
