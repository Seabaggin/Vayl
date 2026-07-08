# Desire Reveal Hero Row + Line Fade Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Correct two device-tested issues in the just-shipped reveal-ceremony fix: the locked
list excluded the one match that's actually revealed (making the whole list read as "all
locked"), and the teaser-beat connecting lines animate by tracing/growing across the screen
instead of fading in, which reads as messy.

**Architecture:** Two independent, sequential tasks. Task 1 adds a `heroMatch` derivation to
`DesireRevealStore` (reusing the existing hero-selection rule, not duplicating it a third time),
and reworks the locked list's row component so the hero renders fully visible (no blur, no lock,
a lit accent) as the first row, with every other row staying blurred and carrying no lock icon at
all — blur alone communicates "locked" now, fully removing the icon. Task 2 changes how
teaser-beat lines animate on: opacity fade-in instead of a trim/draw-on animation.

**Tech Stack:** SwiftUI, existing `AppColors` / `AppFonts` / `AppSpacing` / `AppRadius` /
`AppAnimation` token files. No new dependencies, no schema changes.

**Context:** This corrects `docs/superpowers/plans/2026-07-05-desire-reveal-coordination-fix.md`
(commits `beee97f`, `87eb0cf`) after Bryan's on-device pass. The original plan's `showsLock: i ==
0` interpretation was backwards — the intent was that the first row *reveals itself* (shows real,
legible text), not that it alone keeps a lock icon while the others lose it.

**Adaptation note:** Same as prior plans — this is feel/visual + light derived-state work, not
logic requiring unit tests. Each task's verification is an `xcodebuild` compile check (the agent
runs this) followed by a device-pass note (for Bryan).

---

## Task 1: Hero match in the locked list, remove the lock icon entirely

**Files:**
- Modify: `Vayl/Features/Desire Map/Store/DesireRevealStore.swift:65-119` (constellation section)
  and `:142-147` (derived section)
- Modify: `Vayl/Features/Desire Map/Views/Components/DesireRevealView.swift` (the `_LockedSection`
  call site and the `_LockedSection`/`_LockedPreviewRow` structs)

- [ ] **Step 1: Extract the hero-selection rule into a shared, reusable function on the store**

In `DesireRevealStore.swift`, find this inside `rebuildConstellation()`:

```swift
        // The hero rule (monetization-adjacent): the server-set free reveal wins the
        // hero slot; else the first mutual; else the first match.
        let hero = matches.first(where: { $0.isFreeReveal })
            ?? matches.first(where: { $0.alignment == .mutual })
            ?? matches.first
        let others = matches.filter { $0.id != hero?.id }
```

Replace it with:

```swift
        // The hero rule (monetization-adjacent): the server-set free reveal wins the
        // hero slot; else the first mutual; else the first match. Shared with `heroMatch`
        // below so the constellation's lit star and the locked list's visible row always
        // agree on which match is "the one revealed."
        let hero = Self.selectHero(from: matches)
        let others = matches.filter { $0.id != hero?.id }
```

- [ ] **Step 2: Add `heroMatch` and the shared `selectHero` helper to the derived section**

Find this in `DesireRevealStore.swift`:

```swift
    // MARK: - Derived

    var unlockedMatches: [RevealMatch] { matches.filter { !$0.isLocked } }
    var lockedMatches:   [RevealMatch] { matches.filter { $0.isLocked } }
    var lockedCount: Int { lockedMatches.count }
    var totalCount:  Int { matches.count }
```

Replace it with:

```swift
    // MARK: - Derived

    /// The one match everyone in the ceremony sees named — the constellation's hero star
    /// and the locked list's single visible row both derive from this same selection.
    var heroMatch: RevealMatch? { Self.selectHero(from: matches) }

    /// The hero-selection rule: the server-set free reveal wins; else the first mutual;
    /// else the first match. A shared `static` function so `rebuildConstellation()` and
    /// `heroMatch` can't drift into disagreeing about which match is the hero.
    private static func selectHero(from matches: [RevealMatch]) -> RevealMatch? {
        matches.first(where: { $0.isFreeReveal })
            ?? matches.first(where: { $0.alignment == .mutual })
            ?? matches.first
    }

    var unlockedMatches: [RevealMatch] { matches.filter { !$0.isLocked } }
    var lockedMatches:   [RevealMatch] { matches.filter { $0.isLocked } }
    var lockedCount: Int { lockedMatches.count }
    var totalCount:  Int { matches.count }
```

- [ ] **Step 3: Build to verify the store changes compile**

Run: `xcodebuild -project Vayl.xcodeproj -scheme Vayl -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build` (use `-derivedDataPath /tmp/vayl-plan-build` if the default DerivedData is locked by a live Xcode session).
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit the store change**

```bash
git add "Vayl/Features/Desire Map/Store/DesireRevealStore.swift"
git commit -m "refactor(desire-map): expose DesireRevealStore.heroMatch, dedupe hero-selection rule"
```

- [ ] **Step 5: Wire the hero into the locked list and remove the lock icon**

In `DesireRevealView.swift`, find the `_LockedSection` call site (in `bottomSection`'s
`.beat2, .beat3` case):

```swift
        case .beat2, .beat3:
            // Locked teasers + count
            _LockedSection(
                matches: store.lockedMatches,
                isVisible: store.beatPhase.rawValue >= 2
            )
```

Replace it with:

```swift
        case .beat2, .beat3:
            // Locked teasers + count
            _LockedSection(
                hero: store.heroMatch,
                matches: store.lockedMatches,
                isVisible: store.beatPhase.rawValue >= 2
            )
```

- [ ] **Step 6: Replace `_LockedSection` and `_LockedPreviewRow`**

Find the entire `_LockedSection` and `_LockedPreviewRow` structs (search for `// MARK: - Locked
teasers section`) — this is everything from that comment through the closing `}` of
`_LockedPreviewRow`. Replace the whole block with:

```swift
// MARK: - Locked teasers section (beat2 + beat3)
// The hero (the one match already revealed via the constellation) shows first, fully legible —
// otherwise this list reads as "everything is locked," which contradicts the lit star above it.
// Every other row stays blurred with NO lock icon at all: blur alone says "locked," so repeating
// the icon on every row (or even just one) is redundant noise.

private struct _LockedSection: View {
    let hero: RevealMatch?
    let matches: [RevealMatch]
    let isVisible: Bool

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            if let hero {
                _LockedPreviewRow(itemName: hero.itemName, isRevealed: true)
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : 22)
                    .animation(AppAnimation.desireLockedRowEnter.reduceMotionSafe, value: isVisible)
            }

            ForEach(Array(matches.prefix(4).enumerated()), id: \.element.id) { i, match in
                _LockedPreviewRow(itemName: match.itemName, isRevealed: false)
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : 22)
                    // Fix #5: tokenized locked-row stagger (was .easeOut 0.36 / 0.08 step),
                    // reduceMotionSafe so it collapses to a fast opacity confirm. Offset by
                    // one extra step so locked rows cascade in just after the hero row.
                    .animation(
                        AppAnimation.desireLockedRowEnter
                            .delay(Double(i + 1) * AppAnimation.desireBeatStaggerStep)
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
// Shares DesireAnswerPill's visual language — radius, top sheen, orb accent — without being a
// tappable/selectable component. `isRevealed` is the ONLY thing that distinguishes the hero row
// from a locked one: clear text + a lit magenta accent vs. blurred text + a dim white accent.

private struct _LockedPreviewRow: View {
    let itemName: String
    let isRevealed: Bool

    private var accent: Color { isRevealed ? AppColors.spectrumMagenta : .white }
    private var textColor: Color { isRevealed ? AppColors.textBright : Color.white.opacity(0.30) }

    var body: some View {
        ZStack(alignment: .top) {
            LinearGradient(colors: [.white.opacity(0.05), .clear], startPoint: .top, endPoint: .bottom)
                .frame(height: 14)

            HStack(spacing: AppSpacing.md) {
                orb
                Text(itemName)
                    .font(AppFonts.bodyText)
                    .foregroundStyle(textColor)
                    .blur(radius: isRevealed ? 0 : 5)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, AppSpacing.md)
        }
        .frame(height: 46)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                .fill(isRevealed ? AppColors.spectrumMagenta.opacity(0.08) : AppColors.whisperFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                .stroke(isRevealed ? AppColors.spectrumMagenta.opacity(0.35) : AppColors.borderDefault, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
    }

    private var orb: some View {
        ZStack {
            Circle()
                .fill(accent)
                .frame(width: 17, height: 17)
                .blur(radius: 6)
                .opacity(isRevealed ? 0.7 : 0.35)
            Circle()
                .fill(.white)
                .frame(width: 7, height: 7)
                .opacity(isRevealed ? 1.0 : 0.5)
        }
        .frame(width: 17, height: 17)
    }
}
```

Note what changed from the previous version: `showsLock: Bool` and the whole conditional
`Image(systemName: "lock.fill")` block are gone entirely — no row shows a lock icon anymore,
revealed or not. `isRevealed` now drives blur, text color, and the orb/background/border accent
instead.

- [ ] **Step 7: Build to verify**

Run: `xcodebuild -project Vayl.xcodeproj -scheme Vayl -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build` (use `-derivedDataPath /tmp/vayl-plan-build` if needed).
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 8: Commit**

```bash
git add "Vayl/Features/Desire Map/Views/Components/DesireRevealView.swift"
git commit -m "fix(desire-map): show the hero match in the locked list, drop the lock icon entirely"
```

- [ ] **Step 9: Device-pass checkpoint (Bryan, not the agent)**

Open the reveal's teaser beat. Confirm: the list now shows the free/mutual match's real name as
its first row (lit magenta accent, fully legible, no blur), with the other rows staying blurred
below it and showing no lock icon anywhere in the list.

---

## Task 2: Teaser-beat lines fade in instead of tracing on

**Files:**
- Modify: `Vayl/Features/Desire Map/Views/Components/DesireConstellationView.swift:101-121`
  (the `// MARK: - Lines` section, as it stands after the prior plan's Task 1)

- [ ] **Step 1: Split the line-reveal animation by mode**

Find this in `DesireConstellationView.swift` (this is the current state after the prior plan's
line-dimming fix):

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

Replace it with:

```swift
    // MARK: - Lines

    @ViewBuilder
    private func line(_ edge: ConstellationLayout.Edge, in size: CGSize) -> some View {
        let drawn = lineDrawn(edge)
        let path = Path { path in
            path.move(to: scaled(stars[edge.a].point, size))
            path.addLine(to: scaled(stars[edge.b].point, size))
        }
        if mode == .teasers {
            // Teaser-beat lines fade in already at full length. A trim/draw-on animation here
            // reads as lines being traced across the screen and thrown on top of the stars —
            // a plain opacity fade reads as a soft, ambient connection instead.
            path
                .stroke(Color.white.opacity(drawn ? lineOpacity : 0), style: StrokeStyle(lineWidth: 0.8, lineCap: .round))
                .animation(AppAnimation.enter.reduceMotionSafe, value: drawn)
        } else {
            path
                .trim(from: 0, to: drawn ? 1 : 0)
                .stroke(Color.white.opacity(lineOpacity), style: StrokeStyle(lineWidth: 0.8, lineCap: .round))
                .animation(AppAnimation.desireLineDraw.reduceMotionSafe, value: drawn)
        }
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

This keeps `.resolved`/`.assemble` on the existing trim-based draw-on animation (unchanged —
Bryan didn't flag those), and gives `.teasers` a plain opacity cross-fade at the line's full
length instead.

- [ ] **Step 2: Build to verify**

Run: `xcodebuild -project Vayl.xcodeproj -scheme Vayl -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build` (use `-derivedDataPath /tmp/vayl-plan-build` if needed).
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add "Vayl/Features/Desire Map/Views/Components/DesireConstellationView.swift"
git commit -m "fix(desire-map): teaser-beat constellation lines fade in instead of tracing on"
```

- [ ] **Step 4: Device-pass checkpoint (Bryan, not the agent)**

Open the reveal's teaser beat. Confirm: the dim connecting lines now fade in cleanly at their
full length rather than visibly growing/tracing across the stars.

---

## Self-review notes

- **Spec coverage:** Task 1 covers the hero-in-list requirement (including removing the lock
  icon entirely, per the corrected reading of "the lock icon is redundant if it's blurred").
  Task 2 covers the line-fade requirement. Both device-tested issues are covered.
- **Type consistency:** `_LockedPreviewRow`'s `isRevealed: Bool` replaces the old `showsLock:
  Bool` completely — no leftover references to `showsLock` anywhere (Task 1 Step 6 replaces the
  whole struct in one edit, so there's no half-migrated state). `DesireRevealStore.heroMatch`
  and `RevealMatch` are used consistently with their existing definitions — no new model fields.
- **No orphaned code:** `Self.selectHero(from:)` is introduced and immediately used at both of
  its two call sites (`rebuildConstellation()` and `heroMatch`) in the same commit.
- **Out-of-scope items respected:** No changes to `DesireMapListSheet.swift`, no changes to
  `.resolved`/`.assemble` line behavior, no changes to the "N more aligned desires" count logic
  (still driven by `matches.count`, i.e. the locked count only — the hero isn't "more," it's
  already shown).
