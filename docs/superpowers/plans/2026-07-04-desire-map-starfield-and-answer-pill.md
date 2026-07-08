# Desire Map — Starfield Consistency + Answer Pill Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring the ambient starfield to every Desire Map screen (not just the intro), and replace
the answer-selection row with the approved "Card Weight" design — fixing the hardcoded
selected-state color bug along the way.

**Architecture:** Two independent, sequential segments per the Vayl build protocol (each ships and
gets a device pass before the next starts). Segment 1 extracts the existing star-dust render logic
into a shared `DesireStarfield` view and wires it into every screen that's missing it. Segment 2
replaces `_RaterPill` with a new standalone `DesireAnswerPill` component whose selected-state color
is derived from the answer's own `DesireRatingValue`, not passed in by the caller.

**Tech Stack:** SwiftUI, existing `AppColors` / `AppFonts` / `AppSpacing` / `AppRadius` /
`AppAnimation` token files. No new dependencies, no model or Service changes.

**Adaptation note:** This is visual/feel work, not logic. Per `CLAUDE.md`'s Build Protocol, the
done condition for each task is "builds clean + Bryan confirms the feel on device," not an
automated test — Vayl doesn't unit-test SwiftUI view rendering. Every task's verification step is
therefore an `xcodebuild` compile check (which the agent runs) followed by a device-pass note (for
Bryan, not the agent — the agent doesn't have simulator/device access here).

**Reference:** `docs/superpowers/specs/2026-07-04-desire-map-starfield-and-answer-pill-design.md`
(spec) · `docs/prototypes/desire-map-final-mockup.html` (visual target).

---

## Segment 1 — Starfield consistency

### Task 1: Extract `DesireStarfield` as a shared view

**Files:**
- Create: `Vayl/Features/Desire Map/Views/Components/DesireStarfield.swift`
- Modify: `Vayl/Features/Desire Map/Views/Components/DesireMapView.swift:226-285` (remove the
  extracted code; body/call site update happens in Task 2)

- [ ] **Step 1: Create the new file with the extracted star data + renderer**

```swift
//
//  DesireStarfield.swift
//  Vayl
//

import SwiftUI

/// Ambient background dust-field shared by every Desire Map screen — rating, charted,
/// mirror, and the reveal's beat sequence. Previously lived only on `DesireMapView`'s
/// `.start` screen; extracted so `DesireRevealView` can share the identical field instead
/// of duplicating the dataset. Static positions + per-star twinkle period, unchanged from
/// the original tuning.
struct DesireStarfield: View {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let stars: [(x: Double, y: Double, d: Double, base: Double, period: Double)] = [
        (0.08, 0.04, 1.2, 0.20, 0), (0.52, 0.03, 1.0, 0.14, 0), (0.75, 0.12, 0.7, 0.10, 0),
        (0.42, 0.16, 0.8, 0.12, 0), (0.05, 0.28, 0.9, 0.18, 0), (0.35, 0.32, 0.7, 0.08, 0),
        (0.80, 0.30, 1.2, 0.15, 0), (0.70, 0.35, 0.8, 0.10, 0), (0.60, 0.50, 0.9, 0.12, 0),
        (0.32, 0.55, 1.3, 0.08, 0), (0.05, 0.58, 0.8, 0.07, 0), (0.45, 0.65, 1.0, 0.09, 0),
        (0.15, 0.70, 0.7, 0.07, 0), (0.62, 0.78, 0.9, 0.07, 0), (0.38, 0.82, 1.2, 0.08, 0),
        (0.10, 0.85, 0.6, 0.06, 0), (0.72, 0.88, 1.0, 0.07, 0), (0.50, 0.92, 0.8, 0.05, 0),
        (0.30, 0.20, 0.9, 0.13, 0), (0.90, 0.14, 0.7, 0.09, 0), (0.18, 0.44, 0.8, 0.10, 0),
        (0.85, 0.50, 0.7, 0.08, 0), (0.25, 0.62, 1.0, 0.08, 0), (0.68, 0.62, 0.8, 0.07, 0),
        (0.95, 0.72, 0.6, 0.06, 0), (0.55, 0.88, 0.9, 0.06, 0),
        (0.92, 0.07, 0.9, 0.20, 3.2), (0.28, 0.10, 1.5, 0.22, 4.8),
        (0.18, 0.18, 1.1, 0.18, 3.8), (0.65, 0.08, 1.3, 0.20, 4.1),
        (0.87, 0.21, 1.0, 0.16, 2.9), (0.55, 0.25, 1.4, 0.22, 4.5),
        (0.12, 0.38, 1.0, 0.18, 3.6), (0.48, 0.42, 1.1, 0.16, 2.7),
        (0.22, 0.45, 1.5, 0.20, 4.2), (0.90, 0.44, 0.8, 0.14, 3.4),
        (0.78, 0.60, 1.0, 0.12, 4.7), (0.88, 0.72, 1.1, 0.10, 3.1),
        (0.58, 0.15, 1.2, 0.18, 4.0), (0.40, 0.75, 1.3, 0.10, 2.8),
        (0.96, 0.38, 0.9, 0.12, 3.9), (0.02, 0.52, 1.0, 0.10, 4.3),
        (0.73, 0.48, 0.8, 0.12, 2.6), (0.14, 0.96, 1.1, 0.08, 3.7),
    ]

    var body: some View {
        Group {
            if reduceMotion || AppAnimation.lowPower {
                // Reduce Motion / Low Power: one static frame — no periodic twinkle loop.
                // Twinkling stars (period > 0) hold at their base opacity.
                Canvas { ctx, size in
                    for star in Self.stars {
                        let r = star.d / 2
                        let x = size.width * star.x
                        let y = size.height * star.y
                        ctx.fill(
                            Path(ellipseIn: CGRect(x: x - r, y: y - r, width: star.d, height: star.d)),
                            with: .color(.white.opacity(star.base))
                        )
                    }
                }
            } else {
                TimelineView(.periodic(from: .now, by: 0.067)) { timeline in
                    Canvas { ctx, size in
                        let elapsed = timeline.date.timeIntervalSinceReferenceDate
                            .truncatingRemainder(dividingBy: 1000)
                        for (idx, star) in Self.stars.enumerated() {
                            let opacity: Double = star.period > 0
                                ? 0.2 + (sin((elapsed / star.period + Double(idx) * 0.37) * .pi * 2) * 0.5 + 0.5) * 0.6
                                : star.base
                            let r = star.d / 2
                            let x = size.width * star.x
                            let y = size.height * star.y
                            ctx.fill(
                                Path(ellipseIn: CGRect(x: x - r, y: y - r, width: star.d, height: star.d)),
                                with: .color(.white.opacity(opacity))
                            )
                        }
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

#Preview("Desire Starfield") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        DesireStarfield()
    }
    .preferredColorScheme(.dark)
}
```

- [ ] **Step 2: Build to verify the new file compiles on its own**

Run: `xcodebuild -project Vayl.xcodeproj -scheme Vayl -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`
Expected: `** BUILD SUCCEEDED **` (the old `_bgStars`/`starField` in `DesireMapView.swift` still
exist too at this point, so there will be a harmless duplicate-dataset situation, not a duplicate
*symbol* — `DesireStarfield` and `DesireMapView._bgStars` have different names. No conflict.)

- [ ] **Step 3: Commit**

```bash
git add "Vayl/Features/Desire Map/Views/Components/DesireStarfield.swift"
git commit -m "feat(desire-map): extract shared DesireStarfield view"
```

---

### Task 2: Wire `DesireStarfield` into `DesireMapView`, remove the `.start`-only gate

**Files:**
- Modify: `Vayl/Features/Desire Map/Views/Components/DesireMapView.swift:64-104` (body),
  `:226-285` (delete `_bgStars` + `starField`)

- [ ] **Step 1: Replace the gated starfield in `body` with the unconditional shared view**

In `DesireMapView.swift`, find (around line 64-79):

```swift
    var body: some View {
        ZStack {
            AppColors.void.ignoresSafeArea()
            OnboardingAtmosphere(config: atmosphereConfig).ignoresSafeArea()
            if raterPhase == .start {
                starField.ignoresSafeArea()
            }

            content
```

Replace with:

```swift
    var body: some View {
        ZStack {
            AppColors.void.ignoresSafeArea()
            OnboardingAtmosphere(config: atmosphereConfig).ignoresSafeArea()
            DesireStarfield().ignoresSafeArea()

            content
```

This makes the dust-field render on every `raterPhase` (`.start`, `.rating`, `.charted`, `.mirror`,
`.ready`) instead of only `.start` — it now sits behind the rater, the charted node diagram, and
the mirror's scroll content too.

- [ ] **Step 2: Delete the now-unused `_bgStars` array and `starField` computed property**

Delete this whole block from `DesireMapView.swift` (originally lines 226-285, the exact line
numbers will have shifted slightly after Step 1's edit — search for the `// MARK: - Star field`
comment to locate it):

```swift
    // MARK: - Star field (S2.1 background, 44 stars ~18 twinkling)

    private static let _bgStars: [(Double, Double, Double, Double, Double)] = [
        // ... full array ...
    ]

    private var starField: some View {
        Group {
            // ... full Canvas/TimelineView implementation ...
        }
        .allowsHitTesting(false)
    }
```

Everything between (and including) the `// MARK: - Star field` comment and the closing `}` of
`starField` goes.

- [ ] **Step 3: Build to verify**

Run: `xcodebuild -project Vayl.xcodeproj -scheme Vayl -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`
Expected: `** BUILD SUCCEEDED **` — no "unused" warnings for `_bgStars`/`starField` (they're gone),
no missing-symbol errors.

- [ ] **Step 4: Commit**

```bash
git add "Vayl/Features/Desire Map/Views/Components/DesireMapView.swift"
git commit -m "feat(desire-map): starfield now renders on every rater phase, not just .start"
```

- [ ] **Step 5: Device-pass checkpoint (Bryan, not the agent)**

Open the Desire Map on device/simulator and step through `.start` → `.rating` → finish all
questions → `.charted` → `.mirror`. Confirm: the same ambient dust is visible behind the question
card, the charted node diagram, and the mirror's answer groups — not just the intro screen. The
foreground accumulating stars (`_StarAccum`) and the charted-screen nodes should still read
clearly against it (they're brighter/larger and unaffected by this change).

---

### Task 3: Wire `DesireStarfield` into `DesireRevealView`'s beat-reveal

**Files:**
- Modify: `Vayl/Features/Desire Map/Views/Components/DesireRevealView.swift:36-53` (body)

- [ ] **Step 1: Add the starfield to the reveal's background layer**

Find (around line 36-46):

```swift
    var body: some View {
        ZStack(alignment: .bottom) {
            // ── Background ──────────────────────────────
            AppColors.void.ignoresSafeArea()
            OnboardingAtmosphere(config: .cardReveal).ignoresSafeArea()

            // ── Content ─────────────────────────────────
```

Replace with:

```swift
    var body: some View {
        ZStack(alignment: .bottom) {
            // ── Background ──────────────────────────────
            AppColors.void.ignoresSafeArea()
            OnboardingAtmosphere(config: .cardReveal).ignoresSafeArea()
            DesireStarfield().ignoresSafeArea()

            // ── Content ─────────────────────────────────
```

Because this sits at the top of the ZStack (before any phase-specific content), it covers every
phase of the reveal — loading, empty, and every beat (`beat1`/`beat2`/`beat3`/`revealed`) — with no
further per-phase branching needed.

- [ ] **Step 2: Build to verify**

Run: `xcodebuild -project Vayl.xcodeproj -scheme Vayl -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add "Vayl/Features/Desire Map/Views/Components/DesireRevealView.swift"
git commit -m "feat(desire-map): add DesireStarfield to the reveal's beat sequence"
```

- [ ] **Step 4: Device-pass checkpoint (Bryan, not the agent)**

Open the reveal (`DesireRevealView` preview "Free reveal — 1 lit + 3 locked" or on-device flow).
Confirm the dust-field is visible behind "Where you meet," the constellation still reads clearly
against it, and it persists through the paywall/full-map sheet states without looking cluttered
behind the sheet scrim.

---

## Segment 2 — Answer pill redesign

### Task 4: Build the `DesireAnswerPill` component

**Files:**
- Create: `Vayl/Features/Desire Map/Views/Components/DesireAnswerPill.swift`

- [ ] **Step 1: Create the component**

```swift
//
//  DesireAnswerPill.swift
//  Vayl
//

import SwiftUI

/// Desire Map's answer-selection row — the "Card Weight" treatment approved 2026-07-04
/// (docs/prototypes/desire-map-final-mockup.html). Replaces `_RaterPill`.
///
/// Deliberately its own component, not a `SelectablePill` variant: SelectablePill is a
/// centered single-label capsule with no icon/hint slot and no per-instance accent color.
/// Retrofitting Option C onto it would mean rewriting internals three other screens
/// (onboarding, settings) already depend on.
///
/// The selected-state color is derived from `weight` itself, not passed in by the caller —
/// this is the fix for the shipped bug where every row tinted the same hardcoded
/// magenta/purple regardless of which answer was actually chosen.
struct DesireAnswerPill: View {
    let label: String
    let hint: String
    let weight: DesireRatingValue
    let isSelected: Bool
    let action: () -> Void

    /// "Not for me" always shows the private-answer lock, never the confirm checkmark —
    /// matches the existing app's `isBoundary` behavior (the reassuring checkmark never
    /// appears on the one answer whose whole point is that it stays private).
    private var isPrivateAnswer: Bool { weight == .notForMe }

    /// The row's own spectrum color. `.probablyNot` ("nervous") has no hue in the mockup —
    /// it's white-based, dimmed via opacity at each usage site below.
    private var accent: Color {
        switch weight {
        case .excitedAboutIt: return AppColors.spectrumCyan
        case .openToIt:       return AppColors.spectrumPurple
        case .probablyNot:    return .white
        case .notForMe:       return AppColors.spectrumMagenta
        }
    }

    /// Contrast color for text/icons drawn on top of a filled `accent` circle.
    private var onAccent: Color {
        weight == .probablyNot ? AppColors.void : .white
    }

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .top) {
                // Top sheen — faint highlight cap, clipped to the row's rounded corners below.
                LinearGradient(colors: [.white.opacity(0.05), .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: 18)

                HStack(spacing: AppSpacing.md) {
                    orb
                    Text(label)
                        .font(AppFonts.bodyMedium)
                        .foregroundStyle(isSelected ? AppColors.textBright : AppColors.textSecondary)
                    Spacer(minLength: 0)
                    trailing
                }
                .padding(.horizontal, AppSpacing.md)
            }
            .frame(height: 62)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                    .fill(isSelected ? AnyShapeStyle(accent.opacity(0.10)) : AnyShapeStyle(AppColors.whisperFill))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                    .stroke(isSelected ? accent.opacity(0.5) : AppColors.borderSubtle, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
            .shadow(color: isSelected ? accent.opacity(0.35) : .clear, radius: 13, y: 10)
            .offset(y: isSelected ? -3 : 0)
            .animation(AppAnimation.spring, value: isSelected)
        }
        .buttonStyle(_AnswerPressStyle())
    }

    private var orb: some View {
        ZStack {
            Circle()
                .fill(accent)
                .frame(width: 17, height: 17)
                .blur(radius: 6)
                .opacity(0.7)
            Circle()
                .fill(.white)
                .frame(width: 7, height: 7)
        }
        .frame(width: 17, height: 17)
    }

    @ViewBuilder
    private var trailing: some View {
        if isPrivateAnswer {
            Image(systemName: "lock.fill")
                .font(AppFonts.meta)
                .foregroundStyle(AppColors.textTertiary.opacity(0.6))
        } else if isSelected {
            ZStack {
                Circle().fill(accent).frame(width: 23, height: 23)
                Image(systemName: "checkmark")
                    .font(AppFonts.meta)
                    .foregroundStyle(onAccent)
            }
            .transition(.scale.combined(with: .opacity))
        } else if !hint.isEmpty {
            Text(hint)
                .font(AppFonts.meta)
                .foregroundStyle(AppColors.textTertiary)
                .transition(.opacity)
        }
    }
}

// MARK: - Press style

private struct _AnswerPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(AppAnimation.fast, value: configuration.isPressed)
    }
}

// MARK: - Previews

#Preview("Answer pills — all four states") {
    VStack(spacing: AppSpacing.sm) {
        DesireAnswerPill(label: "Yes — that excites me", hint: "i want this", weight: .excitedAboutIt, isSelected: true) {}
        DesireAnswerPill(label: "I'm curious to try it", hint: "i'm curious", weight: .openToIt, isSelected: false) {}
        DesireAnswerPill(label: "I'm nervous about it", hint: "not right now", weight: .probablyNot, isSelected: false) {}
        DesireAnswerPill(label: "Not for me", hint: "", weight: .notForMe, isSelected: false) {}
    }
    .padding(AppSpacing.lg)
    .background(AppColors.void)
    .preferredColorScheme(.dark)
}
```

- [ ] **Step 2: Build to verify the new file compiles**

Run: `xcodebuild -project Vayl.xcodeproj -scheme Vayl -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add "Vayl/Features/Desire Map/Views/Components/DesireAnswerPill.swift"
git commit -m "feat(desire-map): add DesireAnswerPill (Card Weight design, per-answer color)"
```

---

### Task 5: Replace `_RaterPill` with `DesireAnswerPill` in `DesireMapView`'s rater, delete dead code

**Files:**
- Modify: `Vayl/Features/Desire Map/Views/Components/DesireMapView.swift` (rater answer loop,
  `accentColor(for:)` helper, `_RaterPill` struct)

- [ ] **Step 1: Replace the answer loop's pill call**

Find (in the `rater(item:)` method):

```swift
                    VStack(spacing: AppSpacing.sm) {
                        ForEach(Array(answers.enumerated()), id: \.offset) { idx, label in
                            if idx < DesireRatingValue.allCases.count {
                                let weight = DesireRatingValue.allCases[idx]
                                _RaterPill(
                                    label: label,
                                    hint: pillHint(for: weight),
                                    accent: accentColor(for: weight),
                                    isBoundary: weight == .notForMe,
                                    isSelected: store.existingRating(for: item.id) == weight
                                ) { choose(weight, for: item) }
                            }
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
```

Replace with:

```swift
                    VStack(spacing: AppSpacing.sm) {
                        ForEach(Array(answers.enumerated()), id: \.offset) { idx, label in
                            if idx < DesireRatingValue.allCases.count {
                                let weight = DesireRatingValue.allCases[idx]
                                DesireAnswerPill(
                                    label: label,
                                    hint: pillHint(for: weight),
                                    weight: weight,
                                    isSelected: store.existingRating(for: item.id) == weight
                                ) { choose(weight, for: item) }
                            }
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
```

- [ ] **Step 2: Delete the now-unused `accentColor(for:)` helper**

Delete from `DesireMapView.swift` (in the `// MARK: - Actions` section):

```swift
    private func accentColor(for weight: DesireRatingValue) -> Color {
        switch weight {
        case .excitedAboutIt: return AppColors.spectrumCyan
        case .openToIt:       return AppColors.spectrumPurple
        case .probablyNot:    return AppColors.textTertiary
        case .notForMe:       return AppColors.spectrumMagenta
        }
    }
```

This is the exact hardcoded-mapping the spec flagged — it's now superseded by `DesireAnswerPill`'s
own internal `accent` computed property, which is the single source of truth for answer color.

- [ ] **Step 3: Delete the now-unused `_RaterPill` struct**

Delete the entire `_RaterPill` struct from `DesireMapView.swift` (the `// MARK: - Rater pill (S2.2,
replaces RatingRow)` section, roughly the old lines 778-836 — search for `private struct _RaterPill`
to locate it precisely, since line numbers have shifted from the earlier edits in this file).

- [ ] **Step 4: Build to verify**

Run: `xcodebuild -project Vayl.xcodeproj -scheme Vayl -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`
Expected: `** BUILD SUCCEEDED **` — no leftover references to `_RaterPill` or `accentColor(for:)`
anywhere in the file (both are fully removed, not just unused).

- [ ] **Step 5: Commit**

```bash
git add "Vayl/Features/Desire Map/Views/Components/DesireMapView.swift"
git commit -m "refactor(desire-map): rater uses DesireAnswerPill, delete dead _RaterPill + accentColor(for:)"
```

- [ ] **Step 6: Device-pass checkpoint (Bryan, not the agent)**

Step through the rater on device. Confirm: each answer's selected state now tints in *its own*
spectrum color (excited → cyan, curious → purple, nervous → dim white, not-for-me → magenta) — not
always magenta/purple regardless of which was picked. Confirm the row lifts with a matching
shadow bloom on select, the hint text morphs into a filled checkmark (except "Not for me," which
always shows the lock), and the whole thing still reads well against the now-visible starfield
from Segment 1.

---

## Self-review notes

- **Spec coverage:** Starfield → Tasks 1-3 (extract, wire into `DesireMapView`, wire into
  `DesireRevealView`). Answer pill → Tasks 4-5 (new component, replace call site + delete dead
  code). Both spec segments are covered.
- **Out-of-scope items respected:** No changes to `SelectablePill`, no press-style consolidation,
  no `VaylButton` changes — nothing in this plan touches those files.
- **Type consistency:** `DesireAnswerPill`'s `weight: DesireRatingValue` parameter name and the
  four-case switch (`excitedAboutIt` / `openToIt` / `probablyNot` / `notForMe`) match the existing
  `DesireRatingValue` enum used everywhere else in `DesireMapView.swift` (`store.rate(itemId:
  rating:)`, `store.existingRating(for:)`, `pillHint(for:)`) — no renamed cases.
- **No orphaned code:** Task 5 explicitly deletes both `_RaterPill` and `accentColor(for:)` in the
  same task that stops calling them, so nothing is left half-migrated.
