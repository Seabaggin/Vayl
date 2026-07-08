# Constellation Fixed Frame Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Every previous attempt to resize/cross-fade the constellation between beat1 (full-bleed)
and beat2/3 (compact) has produced a visible jump or abrupt landing. Stop changing the
constellation's size or identity at all, for the entire ceremony — give it one constant frame
(the top half of the screen) from beat1 through revealed, so nothing about its layout ever
changes across beats.

**Architecture:** Replace the `Group { if/else }` cross-fade (which still let the surrounding
layout snap between two different slot sizes) with a single `DesireConstellationView` instance at
a constant `.frame(maxHeight: geo.size.height * 0.5)` — no toggle, no `.transition`, no identity
swap. `bottomSection` below it (caption in beat1/revealed, locked list in beat2/3) already fades
its own content in and out independently; with the constellation's slot size now fixed for good,
`bottomSection` simply has a stable amount of room reserved below it at all times, instead of
needing the constellation to shrink to make room.

**Tech Stack:** SwiftUI. No new dependencies, no model changes.

**Context:** This supersedes `docs/superpowers/plans/2026-07-05-constellation-cross-fade-approach.md`
(commit `ba39611`) after on-device testing found the cross-fade still produced an abrupt jump —
the surrounding VStack layout was snapping to the new branch's slot size immediately even though
only the star opacity was animating. Removing the size change entirely, rather than trying to
animate or cross-fade it, is the fix Bryan asked for directly.

**Adaptation note:** Feel/visual fix — verification is a clean compile (the agent) plus an
on-device confirmation that beat transitions no longer move the constellation at all (Bryan).

---

## Task 1: Give the constellation one constant frame for the whole ceremony

**Files:**
- Modify: `Vayl/Features/Desire Map/Views/Components/DesireRevealView.swift:143-230`
  (`beatReveal`, `constellationView`)

- [ ] **Step 1: Replace the toggling `Group { if/else }` with one constant-frame instance**

Find this in `DesireRevealView.swift` (inside `beatReveal`, the constellation section):

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

Replace it with:

```swift
                    // Constellation
                    // Layout + hero placement live on the store (Blueprint C) — the view
                    // only renders what it's handed.
                    //
                    // ONE constant frame — half the screen's height — for the entire ceremony,
                    // beat1 through revealed. Two earlier attempts tried to give beat1 a dramatic
                    // full-bleed size and beat2/3 a smaller one (first by animating a single
                    // instance's frame height, then by cross-fading between two differently-sized
                    // instances); both still produced a visible jump or abrupt landing, because
                    // every star's `.position()` is a fraction of whatever frame the constellation
                    // resolves to, and the surrounding VStack's layout snapped to the new slot size
                    // the moment the beat changed even when the star content tried to animate.
                    // Removing the size change entirely removes the whole family of bugs: nothing
                    // about the constellation's layout ever changes across beats, so its stars and
                    // lines never move. `bottomSection` below it already fades its own content in
                    // and out independently — it now simply has a stable amount of room reserved
                    // below the constellation at all times, instead of needing it to shrink.
                    constellationView
                        .frame(maxWidth: .infinity, maxHeight: geo.size.height * 0.5)
                        .padding(.vertical, AppSpacing.lg)
                        .opacity(store.beatPhase != .idle ? 1 : 0)
                        // Fix #3b: opacity reveal gated behind reduceMotionSafe; the per-star ignite + line
                        // draw live inside DesireConstellationView (also Reduce-Motion aware).
                        .animation(AppAnimation.desireStarIgnite.reduceMotionSafe, value: store.beatPhase)
```

- [ ] **Step 2: Simplify `constellationView`'s doc comment (its two call sites are now one)**

Find this in `DesireRevealView.swift`:

```swift
    /// The constellation, factored out so both the full-bleed and compact frame sizes in
    /// `beatReveal` construct an identical instance — only the `.frame(...)` applied at each call
    /// site differs. Kept as a plain (non-`@ViewBuilder`) property since it's always exactly one
    /// view, not conditional content.
    private var constellationView: some View {
```

Replace it with:

```swift
    /// The constellation. Factored out of `beatReveal` for readability — it's still exactly one
    /// call site now, but keeping it separate keeps `beatReveal`'s body scannable.
    private var constellationView: some View {
```

The body of `constellationView` (the `DesireConstellationView(...)` construction itself) is
unchanged — only the doc comment above it changes, since the "two call sites" it used to describe
no longer exist.

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
git commit -m "fix(desire-map): fix the constellation to one constant frame for the whole ceremony"
git show --stat HEAD
# confirm exactly one file again
```

- [ ] **Step 5: Device-pass checkpoint (Bryan, not the agent)**

Open the reveal and step through beat1 -> beat2 -> beat3 -> revealed (or however far the test data
goes). Confirm the constellation's size and position never change at any point — stars and lines
should sit completely still throughout; only the caption/locked-list content below it, and each
star's own brightness/ignite state, should change.

---

## Self-review notes

- **Spec coverage:** The one requirement (stop resizing/cross-fading the constellation; fix it to
  a constant top-half frame for the whole ceremony) is covered by the one change.
- **Type consistency:** `constellationView`'s signature and body are unchanged — only its doc
  comment and its single call site's modifiers change. No stale references to the removed `if`
  branch's `220` constant or the `.transition(.opacity)` calls remain anywhere in the file.
- **No orphaned code:** The `Group`/`if`/`else` structure is removed entirely in the same step that
  introduces its replacement — nothing half-migrated.
- **Out-of-scope respected:** No changes to `DesireConstellationView.swift`, `ConstellationLayout`,
  `bottomSection`'s own body, `beatDots`, or any animation token definitions.
