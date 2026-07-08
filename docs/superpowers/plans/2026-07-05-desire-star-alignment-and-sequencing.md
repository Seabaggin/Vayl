# Desire Star Alignment + Beat1 Sequencing Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix two related bugs in the Desire Map reveal's constellation found on device: the hero
star's glyph doesn't align with its own connecting line (a label-layout bug), and beat1 shows only
the hero star in isolation before the rest of the sky pops in later (a sequencing bug) — the whole
star system should be present from the start, dim, with only the hero growing brighter in place.

**Architecture:** Two independent, sequential fixes in two different files. Task 1 fixes
`DesireStarView`'s layout so a star's label never shifts what `.position(...)` centers on. Task 2
changes `DesireConstellationView`'s beat1 (`.intro`) timeline so all stars render from the start
(locked ones dim, static) and only the hero plays the ignite entrance.

**Tech Stack:** SwiftUI. No new dependencies, no model changes.

**Context:** Both bugs were found during the on-device pass following
`docs/superpowers/plans/2026-07-05-desire-reveal-hero-row-and-line-fade.md`. `DesireStarView` has
exactly one consumer (`DesireConstellationView`), confirmed via repo-wide grep — Task 1 is safe to
land without checking other call sites.

**Adaptation note:** Same as prior plans — verification is an `xcodebuild` compile check (the
agent runs this) plus a device-pass note (for Bryan).

---

## Task 1: Fix the star glyph/label alignment bug

**Files:**
- Modify: `Vayl/Features/Desire Map/Views/Components/DesireStarView.swift:90-129` (`body`)

- [ ] **Step 1: Pin the star's reported layout size to just the glyph, top-aligned**

Find this in `DesireStarView.swift`:

```swift
    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            ZStack {
                // Two-seed entrance — a cool (you) and warm (them) point converging as the star
                // ignites. Present only while the entrance plays; otherwise no seeds, instant bloom.
                if playsEntrance {
                    seedView(color: AppColors.spectrumPurple,  dx: -seedOffset)
                    seedView(color: AppColors.spectrumMagenta, dx:  seedOffset)
                }

                ZStack {
                    haloLayer
                    glowLayer
                    if ring == .dashed {
                        ringLayer
                    }
                    coreLayer
                    crossLayer
                    if state == .lit {
                        sparkleLayer
                    }
                }
                .scaleEffect(bloomed ? 1 : entranceStartScale)
                .opacity(bloomed ? 1 : 0)
            }
            .frame(width: haloSize, height: haloSize)

            if let label {
                Text(label)
                    .font(AppFonts.body(10, weight: .semibold, relativeTo: .caption2))
                    .foregroundStyle(Color.white)
                    .shadow(color: Color.black.opacity(0.85), radius: 2)
                    .shadow(color: AppColors.spectrumMagenta.opacity(0.55), radius: 5)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(width: labelWidth)
                    .opacity(bloomed ? 1 : 0)
            }
        }
        .onAppear { startEntrance() }
        .task(id: "\(state == .lit)-\(!reduceMotion)") {
            guard !reduceMotion, state == .lit else { return }
            await sparkleLoop()
        }
    }
```

Replace it with:

```swift
    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            ZStack {
                // Two-seed entrance — a cool (you) and warm (them) point converging as the star
                // ignites. Present only while the entrance plays; otherwise no seeds, instant bloom.
                if playsEntrance {
                    seedView(color: AppColors.spectrumPurple,  dx: -seedOffset)
                    seedView(color: AppColors.spectrumMagenta, dx:  seedOffset)
                }

                ZStack {
                    haloLayer
                    glowLayer
                    if ring == .dashed {
                        ringLayer
                    }
                    coreLayer
                    crossLayer
                    if state == .lit {
                        sparkleLayer
                    }
                }
                .scaleEffect(bloomed ? 1 : entranceStartScale)
                .opacity(bloomed ? 1 : 0)
            }
            .frame(width: haloSize, height: haloSize)

            if let label {
                Text(label)
                    .font(AppFonts.body(10, weight: .semibold, relativeTo: .caption2))
                    .foregroundStyle(Color.white)
                    .shadow(color: Color.black.opacity(0.85), radius: 2)
                    .shadow(color: AppColors.spectrumMagenta.opacity(0.55), radius: 5)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(width: labelWidth)
                    .opacity(bloomed ? 1 : 0)
            }
        }
        // A star with a label is visually taller than one without (VStack + label height), but
        // the constellation lines and `.position(...)` in DesireConstellationView must always
        // target the GLYPH's centre, not the glyph+label group's centre. Pinning the reported
        // frame to just the glyph's own haloSize×haloSize box, top-aligned, keeps the label a
        // pure visual overflow below that box (SwiftUI doesn't clip un-clipped overflow) without
        // it ever shifting what external `.position(...)` calls centre on. Without this, any
        // labeled star (currently: the hero) renders visibly offset from its own connecting line.
        .frame(width: haloSize, height: haloSize, alignment: .top)
        .onAppear { startEntrance() }
        .task(id: "\(state == .lit)-\(!reduceMotion)") {
            guard !reduceMotion, state == .lit else { return }
            await sparkleLoop()
        }
    }
```

- [ ] **Step 2: Build to verify**

Run: `xcodebuild -project Vayl.xcodeproj -scheme Vayl -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build` (use `-derivedDataPath /tmp/vayl-plan-build` if the default DerivedData is locked by a live Xcode session).
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add "Vayl/Features/Desire Map/Views/Components/DesireStarView.swift"
git commit -m "fix(desire-map): pin star's layout frame to the glyph so labels don't shift its position anchor"
```

- [ ] **Step 4: Device-pass checkpoint (Bryan, not the agent)**

Open the reveal's teaser beat. Confirm the hero star (the one with a visible label) now sits
exactly where its connecting lines meet, matching the other (unlabeled) stars.

---

## Task 2: The whole star system is present from beat1; only the hero ignites

**Files:**
- Modify: `Vayl/Features/Desire Map/Views/Components/DesireConstellationView.swift` (`ignites`,
  `starState(_:_:)`, `applyMode()`)

- [ ] **Step 1: Make `ignites` per-star instead of view-wide**

Find this in `DesireConstellationView.swift`:

```swift
    // MARK: - Per-star rendering

    /// New stars ignite (two-seed merge) during the intro hero beat and the full assembly only.
    private var ignites: Bool { mode == .intro || mode == .assemble }

    private func starState(_ index: Int, _ star: Star) -> DesireStarView.StarState {
        (mode == .teasers && star.isLocked) ? .dim : .lit
    }
```

Replace it with:

```swift
    // MARK: - Per-star rendering

    /// Only the hero plays the two-seed ignite entrance during `.intro` — it's the one star
    /// growing brighter in a system that's already fully present; every other star is simply
    /// there from the start, dim and static, not arriving. During `.assemble` every star ignites
    /// as the telegraphed ceremony reveals it, which is unchanged.
    private func ignites(_ index: Int) -> Bool {
        switch mode {
        case .intro:              return index == heroIndex
        case .assemble:           return true
        case .teasers, .resolved: return false
        }
    }

    private func starState(_ index: Int, _ star: Star) -> DesireStarView.StarState {
        ((mode == .teasers || mode == .intro) && star.isLocked) ? .dim : .lit
    }
```

- [ ] **Step 2: Update the call site to use the per-star `ignites(_:)`**

Find this in `DesireConstellationView.swift` (in `body`):

```swift
                ForEach(Array(stars.enumerated()), id: \.element.id) { index, star in
                    if revealed.contains(index) {
                        DesireStarView(
                            size: star.size,
                            state: starState(index, star),
                            label: showsLabel(star) ? star.label : nil,
                            cadence: star.cadence,
                            ignites: ignites,
                            ring: (star.isAdjacent && !star.isLocked) ? .dashed : .none
                        )
                        .position(x: star.point.x * geo.size.width,
                                  y: star.point.y * geo.size.height)
                        .onTapGesture { onTap?(star.id) }
                    }
                }
```

Replace it with:

```swift
                ForEach(Array(stars.enumerated()), id: \.element.id) { index, star in
                    if revealed.contains(index) {
                        DesireStarView(
                            size: star.size,
                            state: starState(index, star),
                            label: showsLabel(star) ? star.label : nil,
                            cadence: star.cadence,
                            ignites: ignites(index),
                            ring: (star.isAdjacent && !star.isLocked) ? .dashed : .none
                        )
                        .position(x: star.point.x * geo.size.width,
                                  y: star.point.y * geo.size.height)
                        .onTapGesture { onTap?(star.id) }
                    }
                }
```

- [ ] **Step 3: Reveal every star from beat1 onward**

Find this in `DesireConstellationView.swift` (`applyMode()`):

```swift
    private func applyMode() async {
        sweepVisible = false
        gatherContracted = false
        sweepProgress = 0
        switch mode {
        case .intro:
            revealed = stars.isEmpty ? [] : [heroIndex]
        case .teasers, .resolved:
            revealed = Set(stars.indices)
        case .assemble:
            revealed = []
            await runAssembly()
        }
    }
```

Replace it with:

```swift
    private func applyMode() async {
        sweepVisible = false
        gatherContracted = false
        sweepProgress = 0
        switch mode {
        case .intro, .teasers, .resolved:
            // The whole sky is present from beat1 onward — the hero is already in its rightful
            // place among the rest, simply lit while they sit dim. It ignites there in place;
            // it doesn't arrive alone and get a system overlaid onto it later.
            revealed = Set(stars.indices)
        case .assemble:
            revealed = []
            await runAssembly()
        }
    }
```

- [ ] **Step 4: Build to verify**

Run: `xcodebuild -project Vayl.xcodeproj -scheme Vayl -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build` (use `-derivedDataPath /tmp/vayl-plan-build` if needed).
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add "Vayl/Features/Desire Map/Views/Components/DesireConstellationView.swift"
git commit -m "fix(desire-map): show the whole star system from beat1, only the hero ignites in place"
```

- [ ] **Step 6: Device-pass checkpoint (Bryan, not the agent)**

Open the reveal from the very start (beat1). Confirm: all 5 stars (or however many total matches)
are visible immediately — the 4 non-hero ones sitting dim and static in their real positions —
while only the hero plays its two-seed ignite/brighten animation. Confirm beat2's transition to
lines/locked-list no longer looks like stars "arriving" — they were already there.

---

## Self-review notes

- **Spec coverage:** Task 1 covers the label/position misalignment. Task 2 covers the beat1
  sequencing ("star shown, then overlaid onto a system that pops in" complaint).
- **Type consistency:** `ignites` changes from a stored computed `Bool` to a function
  `ignites(_ index: Int) -> Bool` — Task 2 Step 2 updates the one call site in the same task, so
  there's no half-migrated state. `starState(_:_:)`'s signature is unchanged (still takes
  `index`/`star`, still returns `DesireStarView.StarState`) — only its body's condition changes.
- **No orphaned code:** `DesireStarView` has exactly one consumer (`DesireConstellationView`,
  confirmed via repo-wide grep before this plan was written) — Task 1's frame change has no other
  call site to break.
- **Out-of-scope respected:** No changes to `lineDrawn(_:)`/`lineOpacity` (already correct from
  the prior plan), no changes to `.assemble`'s telegraphed ceremony or `runAssembly()`, no changes
  to `showsLabel(_:)`.
