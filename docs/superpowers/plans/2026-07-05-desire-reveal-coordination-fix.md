# Desire Reveal Coordination Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix two reveal-ceremony coordination bugs found on device testing — the teaser beat's
stars show no connecting lines, and the locked-matches list repeats the same lock icon on every
row instead of establishing it once.

**Architecture:** Two independent, sequential segments per the Vayl build protocol. Segment 1
extends `DesireConstellationView`'s line-drawing to the teaser beat at a dimmed opacity. Segment 2
extracts the locked list's per-row content into a new `_LockedPreviewRow` view carrying the
"Card Weight" visual materials (from `DesireAnswerPill`), with the lock glyph gated to only the
first row.

**Tech Stack:** SwiftUI, existing `AppColors` / `AppFonts` / `AppSpacing` / `AppRadius` /
`AppAnimation` token files. No new dependencies, no model or Service changes.

**Adaptation note:** Same as the prior Desire Map visual plan — this is feel/visual work, not
logic. Each task's verification is an `xcodebuild` compile check (which the agent runs) followed
by a device-pass note (for Bryan, not the agent).

**Reference:** `docs/superpowers/specs/2026-07-05-desire-reveal-coordination-fix-design.md` (spec).

---

## Segment 1 — Constellation: dimmed connections during the teaser beat

### Task 1: Draw dimmed lines between all stars in `.teasers` mode

**Files:**
- Modify: `Vayl/Features/Desire Map/Views/Components/DesireConstellationView.swift:101-121`

- [ ] **Step 1: Add a mode-dependent line opacity and enable teaser-beat lines**

Find this in `DesireConstellationView.swift`:

```swift
    // MARK: - Lines

    @ViewBuilder
    private func line(_ edge: ConstellationLayout.Edge, in size: CGSize) -> some View {
        let drawn = lineDrawn(edge)
        Path { path in
            path.move(to: scaled(stars[edge.a].point, size))
            path.addLine(to: scaled(stars[edge.b].point, size))
        }
        .trim(from: 0, to: drawn ? 1 : 0)
        .stroke(Color.white.opacity(0.5), style: StrokeStyle(lineWidth: 0.8, lineCap: .round))
        .animation(AppAnimation.desireLineDraw.reduceMotionSafe, value: drawn)
    }

    private func lineDrawn(_ edge: ConstellationLayout.Edge) -> Bool {
        switch mode {
        case .resolved:        return true
        case .assemble:        return revealed.contains(edge.a) && revealed.contains(edge.b)
        case .intro, .teasers: return false
        }
    }
```

Replace it with:

```swift
    // MARK: - Lines

    @ViewBuilder
    private func line(_ edge: ConstellationLayout.Edge, in size: CGSize) -> some View {
        let drawn = lineDrawn(edge)
        Path { path in
            path.move(to: scaled(stars[edge.a].point, size))
            path.addLine(to: scaled(stars[edge.b].point, size))
        }
        .trim(from: 0, to: drawn ? 1 : 0)
        .stroke(Color.white.opacity(lineOpacity), style: StrokeStyle(lineWidth: 0.8, lineCap: .round))
        .animation(AppAnimation.desireLineDraw.reduceMotionSafe, value: drawn)
    }

    private func lineDrawn(_ edge: ConstellationLayout.Edge) -> Bool {
        switch mode {
        case .resolved:  return true
        case .assemble:  return revealed.contains(edge.a) && revealed.contains(edge.b)
        case .teasers:   return true
        case .intro:     return false
        }
    }

    /// Teaser-beat lines read as a hint of connection, not a confirmed one — dimmer than
    /// the confident weight used once the sky is actually lit (resolved / mid-assembly).
    private var lineOpacity: Double {
        mode == .teasers ? 0.18 : 0.5
    }
```

This changes two things: `.teasers` now returns `true` from `lineDrawn` (previously grouped with
`.intro` under `false`), and the stroke's opacity comes from the new `lineOpacity` computed
property instead of the hardcoded `0.5`, so teaser-beat lines render dim while `.resolved`/
`.assemble` keep today's confident weight. `.intro` is unaffected — it still draws no lines
(only the hero star is revealed at that beat, nothing else to connect to).

- [ ] **Step 2: Build to verify**

Run: `xcodebuild -project Vayl.xcodeproj -scheme Vayl -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add "Vayl/Features/Desire Map/Views/Components/DesireConstellationView.swift"
git commit -m "fix(desire-map): draw dimmed connecting lines during the reveal's teaser beat"
```

- [ ] **Step 4: Device-pass checkpoint (Bryan, not the agent)**

Open the reveal ceremony and let it reach beat2/3 (the locked-teasers beat — you can force this
via the DEBUG "Reveal · Gather/Sweep/Constellate" buttons on Home if you don't want to wait on
real backend completion). Confirm: every star (the lit hero + the dim locked ones) now shows
connected by faint lines, distinctly dimmer than the bold lines that appear once the sky is
fully revealed.

---

## Segment 2 — Locked list rows: Card Weight materials + single lock icon

### Task 2: Extract `_LockedPreviewRow`, restyle, gate the lock icon to the first row

**Files:**
- Modify: `Vayl/Features/Desire Map/Views/Components/DesireRevealView.swift:429-498`

- [ ] **Step 1: Replace the `_LockedSection` block with an extracted row view**

Find this in `DesireRevealView.swift` (the whole `_LockedSection` section, including its header
comment):

```swift
// MARK: - Locked teasers section (beat2 + beat3)
// Blurred item names + lock glyphs, staggered in at 80ms each, matching desire-reveal.html.

private struct _LockedSection: View {
    let matches: [RevealMatch]
    let isVisible: Bool

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            ForEach(Array(matches.prefix(4).enumerated()), id: \.element.id) { i, match in
                HStack(spacing: AppSpacing.md) {
                    Text(match.itemName)
                        .font(AppFonts.bodyText)
                        .foregroundStyle(Color.white.opacity(0.30))
                        .blur(radius: 5)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Image(systemName: "lock.fill")
                        .font(AppFonts.caption)
                        .foregroundStyle(Color.white.opacity(0.30))
                }
                .padding(.horizontal, AppSpacing.md)
                .frame(height: 46)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .fill(AppColors.whisperFill)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .stroke(AppColors.borderDefault, lineWidth: 1)
                )
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 22)
                // Fix #5: tokenized locked-row stagger (was .easeOut 0.36 / 0.08 step),
                // reduceMotionSafe so it collapses to a fast opacity confirm.
                .animation(
                    AppAnimation.desireLockedRowEnter
                        .delay(Double(i) * AppAnimation.desireBeatStaggerStep)
                        .reduceMotionSafe,
                    value: isVisible
                )
            }

            // Count + spectrum hairline; delayed until all rows finish staggering in
            VStack(spacing: AppSpacing.xs) {
                Text("\(matches.count) more aligned desire\(matches.count == 1 ? "" : "s")")
                    .font(AppFonts.caption)
                    .foregroundStyle(Color.white.opacity(0.18))
                Rectangle()
                    .fill(LinearGradient(
                        colors: [AppColors.spectrumCyan, AppColors.spectrumPurple, AppColors.spectrumMagenta],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .frame(width: 60, height: 1)
                    .opacity(0.4)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, AppSpacing.sm)
            .opacity(isVisible ? 1 : 0)
            // Fix #5: tokenized count + hairline fade (was .easeOut 0.4 / 0.08 step / 0.14 base),
            // reduceMotionSafe so it collapses to a fast opacity confirm.
            .animation(
                AppAnimation.enter
                    .delay(Double(min(matches.count, 4)) * AppAnimation.desireBeatStaggerStep + AppAnimation.desireBeatStaggerBase)
                    .reduceMotionSafe,
                value: isVisible
            )
        }
    }
}
```

Replace it with:

```swift
// MARK: - Locked teasers section (beat2 + beat3)
// Card-Weight-styled preview rows, staggered in at 80ms each. Only the first row shows the
// lock glyph — blur alone communicates "locked" for the rest, so repeating the icon on every
// row would just be noise.

private struct _LockedSection: View {
    let matches: [RevealMatch]
    let isVisible: Bool

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            ForEach(Array(matches.prefix(4).enumerated()), id: \.element.id) { i, match in
                _LockedPreviewRow(itemName: match.itemName, showsLock: i == 0)
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : 22)
                    // Fix #5: tokenized locked-row stagger (was .easeOut 0.36 / 0.08 step),
                    // reduceMotionSafe so it collapses to a fast opacity confirm.
                    .animation(
                        AppAnimation.desireLockedRowEnter
                            .delay(Double(i) * AppAnimation.desireBeatStaggerStep)
                            .reduceMotionSafe,
                        value: isVisible
                    )
            }

            // Count + spectrum hairline; delayed until all rows finish staggering in
            VStack(spacing: AppSpacing.xs) {
                Text("\(matches.count) more aligned desire\(matches.count == 1 ? "" : "s")")
                    .font(AppFonts.caption)
                    .foregroundStyle(Color.white.opacity(0.18))
                Rectangle()
                    .fill(LinearGradient(
                        colors: [AppColors.spectrumCyan, AppColors.spectrumPurple, AppColors.spectrumMagenta],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .frame(width: 60, height: 1)
                    .opacity(0.4)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, AppSpacing.sm)
            .opacity(isVisible ? 1 : 0)
            // Fix #5: tokenized count + hairline fade (was .easeOut 0.4 / 0.08 step / 0.14 base),
            // reduceMotionSafe so it collapses to a fast opacity confirm.
            .animation(
                AppAnimation.enter
                    .delay(Double(min(matches.count, 4)) * AppAnimation.desireBeatStaggerStep + AppAnimation.desireBeatStaggerBase)
                    .reduceMotionSafe,
                value: isVisible
            )
        }
    }
}

// MARK: - Locked preview row (Card Weight materials, no interaction)
// Shares DesireAnswerPill's visual language — radius, top sheen, dim orb accent — without
// being a tappable/selectable component; this is a static, non-interactive preview row.

private struct _LockedPreviewRow: View {
    let itemName: String
    let showsLock: Bool

    var body: some View {
        ZStack(alignment: .top) {
            LinearGradient(colors: [.white.opacity(0.05), .clear], startPoint: .top, endPoint: .bottom)
                .frame(height: 14)

            HStack(spacing: AppSpacing.md) {
                orb
                Text(itemName)
                    .font(AppFonts.bodyText)
                    .foregroundStyle(Color.white.opacity(0.30))
                    .blur(radius: 5)
                    .lineLimit(1)
                Spacer(minLength: 0)
                if showsLock {
                    Image(systemName: "lock.fill")
                        .font(AppFonts.caption)
                        .foregroundStyle(Color.white.opacity(0.30))
                }
            }
            .padding(.horizontal, AppSpacing.md)
        }
        .frame(height: 46)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                .fill(AppColors.whisperFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                .stroke(AppColors.borderDefault, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
    }

    private var orb: some View {
        ZStack {
            Circle()
                .fill(.white)
                .frame(width: 17, height: 17)
                .blur(radius: 6)
                .opacity(0.35)
            Circle()
                .fill(.white)
                .frame(width: 7, height: 7)
                .opacity(0.5)
        }
        .frame(width: 17, height: 17)
    }
}
```

The row's own visual chrome (frame, background, overlay, corner radius, sheen, orb) now lives
inside `_LockedPreviewRow`; `_LockedSection` only owns the list layout and the entrance-stagger
modifiers applied per-row. `showsLock: i == 0` is the only place the "first row only" rule is
decided — every other row passes `false` and renders no icon at all.

- [ ] **Step 2: Build to verify**

Run: `xcodebuild -project Vayl.xcodeproj -scheme Vayl -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add "Vayl/Features/Desire Map/Views/Components/DesireRevealView.swift"
git commit -m "fix(desire-map): restyle locked reveal rows with Card Weight materials, single lock icon"
```

- [ ] **Step 4: Device-pass checkpoint (Bryan, not the agent)**

Open the reveal ceremony's teaser beat again (real flow, or the DEBUG buttons). Confirm: all
locked rows now share the rounded/sheen/orb look consistent with the rater's answer pills, only
the first row shows a padlock, and the other rows read as locked from the blur alone with no
icon. Confirm the existing staggered entrance timing feels unchanged.

---

## Self-review notes

- **Spec coverage:** Segment 1 (Task 1) covers the constellation dimmed-line requirement.
  Segment 2 (Task 2) covers both the Card-Weight row restyle and the single-lock-icon rule.
  Both spec requirements are covered.
- **Out-of-scope items respected:** No changes to `DesireMapListSheet.swift`, no changes to
  stagger timing values, no changes to the "N more aligned desires" count logic, no changes to
  `.intro` mode.
- **Type consistency:** `_LockedPreviewRow`'s `itemName: String` and `showsLock: Bool` are the
  only two properties introduced, and both are used exactly as named at the one call site in
  `_LockedSection`. `DesireConstellationView.Mode`'s four cases (`.intro`, `.teasers`,
  `.assemble`, `.resolved`) are all covered exactly once in both `lineDrawn(_:)`'s switch and are
  referenced consistently with the existing `Mode` enum — no new cases, no renamed cases.
- **No orphaned code:** Task 2 replaces `_LockedSection`'s inline row content in the same edit
  that introduces `_LockedPreviewRow` — nothing is left half-migrated.
