# Constellation Cross-Fade Approach Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the animated frame-height resize between the reveal's full-bleed and compact
constellation states with two independently-sized, stable instances cross-faded via
`.transition(.opacity)` — so stars and lines never shift position at all; only their visibility
changes.

**Architecture:** The previous fix (`geo.size.height` instead of `.infinity`) made the frame-height
animation technically interpolate, but the underlying approach was wrong: `DesireConstellationView`
positions every star as a fraction of its own internal `GeometryReader`'s resolved size, so
*any* animated change to that size means animating every star's position simultaneously — which
reads as the sky shifting, with lines chasing wherever the stars land. The fix: stop resizing a
single view. Factor the `DesireConstellationView(...)` construction into one shared computed
property, mount it twice — once at the compact size, once at the full size — behind an `if/else`
keyed on `store.beatPhase`, and cross-fade between them with `.transition(.opacity)`. Since
`if/else` in a `ViewBuilder` swaps view identity (the old branch is removed, the new one inserted),
each instance's frame is fixed for its entire lifetime — its stars never move. This is the same
`.transition(.opacity)` phase-swap pattern already used everywhere else in this app for state
changes (e.g. `DesireMapView`'s `content` switch), not a new technique.

**Tech Stack:** SwiftUI. No new dependencies, no model changes.

**Adaptation note:** Feel/visual fix — verification is a clean compile (the agent) plus an
on-device confirmation that the transition now reads as a settle/cross-fade rather than a shift
(Bryan).

---

## Task 1: Factor out the shared constellation view

**Files:**
- Modify: `Vayl/Features/Desire Map/Views/Components/DesireRevealView.swift:143-209`
  (`beatReveal`)

- [ ] **Step 1: Replace the constellation section of `beatReveal` with a factored-out property +
  cross-fading `if/else`**

Find this in `DesireRevealView.swift` (inside `beatReveal`, the whole constellation block):

```swift
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
```

Replace it with:

```swift
                    // Constellation
                    // Layout + hero placement live on the store (Blueprint C) — the view
                    // only renders what it's handed.
                    //
                    // Beat2/3 pull the sky into a compact band to make room for the locked rows;
                    // beat1 and the unlocked sky are full-bleed — the constellation IS the screen
                    // (mockup 6/10). This used to be ONE `DesireConstellationView` instance whose
                    // frame height animated between the two sizes — but every star's `.position()`
                    // is a fraction of that same resolving frame (via the view's own internal
                    // GeometryReader), so animating the frame meant animating every star's position
                    // at once, reading as the sky shifting rather than settling in place, with
                    // lines chasing wherever the stars landed. Two independently-sized instances,
                    // cross-faded via `.transition(.opacity)` on an `if/else` (which swaps view
                    // identity — the old branch is removed, the new one inserted), avoids this
                    // entirely: each instance's frame never changes during its own lifetime, so its
                    // stars never move. This is the same phase-swap pattern already used everywhere
                    // else in this app (e.g. DesireMapView's `content` switch), not a new technique.
                    Group {
                        if store.beatPhase == .beat2 || store.beatPhase == .beat3 {
                            constellationView
                                .frame(maxWidth: .infinity, maxHeight: 220)
                                .transition(.opacity)
                        } else {
                            constellationView
                                .frame(maxWidth: .infinity, maxHeight: geo.size.height)
                                .transition(.opacity)
                        }
                    }
                    .padding(.vertical, AppSpacing.lg)
                    .opacity(store.beatPhase != .idle ? 1 : 0)
                    // Fix #3b: opacity reveal gated behind reduceMotionSafe; the per-star ignite + line
                    // draw live inside DesireConstellationView (also Reduce-Motion aware).
                    .animation(AppAnimation.desireStarIgnite.reduceMotionSafe, value: store.beatPhase)
```

- [ ] **Step 2: Add the `constellationView` computed property**

Find this in `DesireRevealView.swift` (immediately after `beatReveal`'s closing `}`):

```swift
    @ViewBuilder
    private var bottomSection: some View {
```

Replace it with (inserting the new property before `bottomSection`, everything else about
`bottomSection` unchanged):

```swift
    /// The constellation, factored out so both the full-bleed and compact frame sizes in
    /// `beatReveal` construct an identical instance — only the `.frame(...)` applied at each call
    /// site differs. Kept as a plain (non-`@ViewBuilder`) property since it's always exactly one
    /// view, not conditional content.
    private var constellationView: some View {
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
    }

    @ViewBuilder
    private var bottomSection: some View {
```

- [ ] **Step 3: Build to verify**

Run: `xcodebuild -project Vayl.xcodeproj -scheme Vayl -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build` (use `-derivedDataPath /tmp/vayl-plan-build` if the default DerivedData is locked by a live Xcode session).
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

Follow the git hygiene sequence: stage only the one file, run `git diff --cached --stat` and confirm
it shows exactly one file BEFORE committing, then commit, then run `git show --stat` and confirm
exactly one file again AFTER committing.

```bash
git add "Vayl/Features/Desire Map/Views/Components/DesireRevealView.swift"
git diff --cached --stat
# confirm exactly one file, THEN:
git commit -m "fix(desire-map): cross-fade between full and compact constellation sizes instead of resizing one instance"
git show --stat HEAD
# confirm exactly one file again
```

- [ ] **Step 5: Device-pass checkpoint (Bryan, not the agent)**

Open the reveal and watch both transitions: beat1 -> beat2 (full -> compact) and beat3 -> revealed
(compact -> full, if applicable to the test data). Confirm stars and lines no longer visibly shift
or reposition — the change should read as one version softly fading out while the other fades in,
with each version's stars already sitting correctly in place from the moment it's visible.

---

## Self-review notes

- **Spec coverage:** The one requirement (stop animating a single instance's frame; cross-fade
  between two stable instances instead) is covered by the one change.
- **No orphaned code:** `constellationView` is introduced and used at exactly two call sites (the
  `if` and `else` branches), both added in the same step — no half-migrated state.
- **Behavior at the beat2/beat3 boundary:** Because the `if/else` condition is
  `store.beatPhase == .beat2 || store.beatPhase == .beat3`, crossing that boundary in either
  direction (beat1->beat2, beat3->revealed for a free couple who saw the paywall) triggers the
  identity swap, fixing the originally-reported shift on both sides of it. Note this is narrower
  than "every possible transition": an already-Core couple's `.idle -> .beat1 -> .revealed` path
  never crosses `.beat2`/`.beat3` at all, so it stays on the same `else` branch the whole time —
  that path never had a frame-size change (both `.beat1` and `.revealed` are full-bleed), so there
  was no shift bug there to fix in the first place. The beat3->revealed swap IS new behavior this
  change introduces (the old single-instance version never remounted there, just resized) — that
  specific transition is worth an explicit look on the device pass, not just "builds clean."
- **Out-of-scope respected:** No changes to `DesireConstellationView.swift`, `ConstellationLayout`,
  `bottomSection`, `beatDots`, or any animation token definitions.
