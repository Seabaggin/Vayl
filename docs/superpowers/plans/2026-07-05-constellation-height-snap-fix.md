# Constellation Height Snap Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The Desire Map reveal's constellation "pushes up" abruptly when the beat transitions from
beat1 (full-bleed) to beat2/beat3 (capped at 220pt to make room for the locked-teasers list) —
stars and lines jump to their new positions instead of animating smoothly.

**Architecture:** Root cause: `DesireConstellationView` positions every star/line as a fraction of
its own internal `GeometryReader`'s resolved size, which is dictated by the external
`.frame(maxHeight:)` constraint in `DesireRevealView`. That constraint currently toggles between a
literal `.infinity` and a finite `220` — SwiftUI cannot smoothly interpolate a frame height FROM
`.infinity` (there's no meaningful midpoint), so the height snaps instantly instead of animating,
and every star jumps in lockstep since they all resolve against that same suddenly-changed size.
Fix: wrap `beatReveal` in a `GeometryReader` and use its real, finite `geo.size.height` as the
"full" state instead of `.infinity`, so both states are genuine finite numbers the existing
`.animation(...)` call can actually interpolate between.

**Tech Stack:** SwiftUI. No new dependencies, no model changes.

**Adaptation note:** Feel/visual fix — verification is a clean compile (the agent) plus an
on-device confirmation that the compression now animates smoothly (Bryan).

---

## Task 1: Replace `.infinity` with a real, animatable height

**Files:**
- Modify: `Vayl/Features/Desire Map/Views/Components/DesireRevealView.swift:143-200`
  (`beatReveal`)

- [ ] **Step 1: Wrap `beatReveal` in a `GeometryReader` and use its finite height**

Find this in `DesireRevealView.swift`:

```swift
    private var beatReveal: some View {
        ZStack {
            // Tap-anywhere-to-advance background (nodes' own tap gestures take priority)
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    hapticTick += 1
                    store.advanceBeat()
                }

            VStack(spacing: 0) {
                // Beat progress dots (hidden when idle or fully revealed)
                if store.beatPhase != .idle && store.beatPhase != .revealed {
                    beatDots
                        .padding(.top, AppSpacing.xs)
                }

                // Overline
                Text(store.beatPhase == .revealed ? "Your shared sky" : "Where you meet")
                    .font(AppFonts.overline)
                    .foregroundStyle(AppColors.textTertiary)
                    .tracking(1.5)
                    .padding(.top, AppSpacing.md)
                    .opacity(store.beatPhase != .idle ? 1 : 0)
                    .animation(AppAnimation.desireStarIgnite.delay(0.10).reduceMotionSafe, value: store.beatPhase)

                // Constellation
                // Layout + hero placement live on the store (Blueprint C) — the view
                // only renders what it's handed.
                DesireConstellationView(
                    stars: store.placedStars,
                    edges: store.layout.edges,
                    variant: ceremonyVariant,
                    mode: constellationMode,
                    onTap: { id in
                        hapticTick += 1
                        if let match = store.matches.first(where: { $0.id.uuidString == id }) {
                            store.selectStar(match)
                        }
                    }
                )
                .frame(maxWidth: .infinity)
                // beat2/3 pull the sky in to make room for the locked rows; beat1 and the
                // unlocked sky are full-bleed — the constellation IS the screen (mockup 6/10).
                .frame(maxHeight: (store.beatPhase == .beat2 || store.beatPhase == .beat3) ? 220 : .infinity)
                .padding(.vertical, AppSpacing.lg)
                .opacity(store.beatPhase != .idle ? 1 : 0)
                // Fix #3b: opacity reveal gated behind reduceMotionSafe; the per-star ignite + line
                // draw live inside DesireConstellationView (also Reduce-Motion aware).
                .animation(AppAnimation.desireStarIgnite.reduceMotionSafe, value: store.beatPhase)

                // Bottom section: caption at beat1/revealed, locked rows at beat2/beat3
                bottomSection
                    .animation(AppAnimation.enter.reduceMotionSafe, value: store.beatPhase)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
```

Replace it with:

```swift
    private var beatReveal: some View {
        GeometryReader { geo in
            ZStack {
                // Tap-anywhere-to-advance background (nodes' own tap gestures take priority)
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        hapticTick += 1
                        store.advanceBeat()
                    }

                VStack(spacing: 0) {
                    // Beat progress dots (hidden when idle or fully revealed)
                    if store.beatPhase != .idle && store.beatPhase != .revealed {
                        beatDots
                            .padding(.top, AppSpacing.xs)
                    }

                    // Overline
                    Text(store.beatPhase == .revealed ? "Your shared sky" : "Where you meet")
                        .font(AppFonts.overline)
                        .foregroundStyle(AppColors.textTertiary)
                        .tracking(1.5)
                        .padding(.top, AppSpacing.md)
                        .opacity(store.beatPhase != .idle ? 1 : 0)
                        .animation(AppAnimation.desireStarIgnite.delay(0.10).reduceMotionSafe, value: store.beatPhase)

                    // Constellation
                    // Layout + hero placement live on the store (Blueprint C) — the view
                    // only renders what it's handed.
                    DesireConstellationView(
                        stars: store.placedStars,
                        edges: store.layout.edges,
                        variant: ceremonyVariant,
                        mode: constellationMode,
                        onTap: { id in
                            hapticTick += 1
                            if let match = store.matches.first(where: { $0.id.uuidString == id }) {
                                store.selectStar(match)
                            }
                        }
                    )
                    .frame(maxWidth: .infinity)
                    // beat2/3 pull the sky in to make room for the locked rows; beat1 and the
                    // unlocked sky are full-bleed — the constellation IS the screen (mockup 6/10).
                    // Both sides of this toggle are now a real, finite height (geo.size.height vs.
                    // 220) instead of `.infinity` vs. 220 — SwiftUI cannot smoothly interpolate a
                    // frame height FROM `.infinity` (there's no meaningful midpoint), so the old
                    // version snapped instantly instead of compressing, and every star (whose
                    // `.position()` is a fraction of this same frame's resolved size, via
                    // DesireConstellationView's own internal GeometryReader) jumped in lockstep
                    // rather than animating into its new spot.
                    .frame(maxHeight: (store.beatPhase == .beat2 || store.beatPhase == .beat3) ? 220 : geo.size.height)
                    .padding(.vertical, AppSpacing.lg)
                    .opacity(store.beatPhase != .idle ? 1 : 0)
                    // Fix #3b: opacity reveal gated behind reduceMotionSafe; the per-star ignite + line
                    // draw live inside DesireConstellationView (also Reduce-Motion aware).
                    .animation(AppAnimation.desireStarIgnite.reduceMotionSafe, value: store.beatPhase)

                    // Bottom section: caption at beat1/revealed, locked rows at beat2/beat3
                    bottomSection
                        .animation(AppAnimation.enter.reduceMotionSafe, value: store.beatPhase)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
```

The only structural change is wrapping the existing `ZStack` in `GeometryReader { geo in ... }` and
swapping the one `.infinity` in the `.frame(maxHeight:...)` toggle for `geo.size.height`. Every
other line is unchanged.

- [ ] **Step 2: Build to verify**

Run: `xcodebuild -project Vayl.xcodeproj -scheme Vayl -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build` (use `-derivedDataPath /tmp/vayl-plan-build` if the default DerivedData is locked by a live Xcode session).
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

Follow the git hygiene sequence: stage only the one file, run `git diff --cached --stat` and confirm
it shows exactly one file BEFORE committing, then commit, then run `git show --stat` and confirm
exactly one file again AFTER committing.

```bash
git add "Vayl/Features/Desire Map/Views/Components/DesireRevealView.swift"
git diff --cached --stat
# confirm exactly one file, THEN:
git commit -m "fix(desire-map): animate the constellation's height compression instead of snapping"
git show --stat HEAD
# confirm exactly one file again
```

- [ ] **Step 4: Device-pass checkpoint (Bryan, not the agent)**

Open the reveal and watch the beat1 -> beat2 transition. Confirm the constellation now visibly
compresses smoothly (stars and lines gliding into their new positions) instead of snapping/jumping
upward instantly.

---

## Self-review notes

- **Spec coverage:** The one requirement (fix the abrupt height-driven star/line jump) is covered
  by the one change.
- **No orphaned code:** `geo` is introduced by the new `GeometryReader` wrapper and used at exactly
  one point (the `.frame(maxHeight:...)` toggle) — no unused variable.
- **Out-of-scope respected:** No changes to `DesireConstellationView.swift`, `bottomSection`,
  `beatDots`, or any animation token definitions — this is purely about giving the existing
  `.frame(maxHeight:)` toggle two finite endpoints instead of one finite and one infinite.
