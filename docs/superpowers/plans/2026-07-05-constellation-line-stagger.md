# Constellation Line Stagger Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The reveal's teaser-beat connecting lines currently all fade in simultaneously (same
start time, same duration) — on-device feedback called this "looks stupid." Stagger each edge's
fade-in so the connections visibly radiate outward from the hero star instead of snapping in
together.

**Architecture:** One-file, two-spot change. `ConstellationLayout.buildEdges` already builds the
`edges` array via Prim's MST starting at the hero and growing nearest-neighbor-first, so the array
is already ordered "outward from the hero" — no new distance computation needed. Pass each edge's
array index into `line(_:in:)` and delay its fade-in animation by that index times the existing
`AppAnimation.desireBeatStaggerStep` token (the same one already driving the locked-row cascade
elsewhere in this ceremony).

**Tech Stack:** SwiftUI, existing `AppAnimation` token file. No new dependencies.

**Adaptation note:** Feel/visual tuning — the stagger step VALUE reused here is an existing,
already-tuned token (not a new guess), so this should need little further dialing, but final feel
confirmation is still Bryan's on-device pass.

---

## Task 1: Stagger the teaser-beat line fade-in by edge index

**Files:**
- Modify: `Vayl/Features/Desire Map/Views/Components/DesireConstellationView.swift` (the `ForEach`
  over `edges` in `body`, and the `line(_:in:)` function)

- [ ] **Step 1: Pass each edge's index into `line(_:in:)`**

Find this in `DesireConstellationView.swift` (in `body`):

```swift
                ForEach(Array(edges.enumerated()), id: \.offset) { _, edge in
                    line(edge, in: geo.size)
                }
```

Replace it with:

```swift
                ForEach(Array(edges.enumerated()), id: \.offset) { index, edge in
                    line(edge, index: index, in: geo.size)
                }
```

- [ ] **Step 2: Stagger the teaser-beat fade-in by that index**

Find this in `DesireConstellationView.swift`:

```swift
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
```

Replace it with:

```swift
    @ViewBuilder
    private func line(_ edge: ConstellationLayout.Edge, index: Int, in size: CGSize) -> some View {
        let drawn = lineDrawn(edge)
        let path = Path { path in
            path.move(to: scaled(stars[edge.a].point, size))
            path.addLine(to: scaled(stars[edge.b].point, size))
        }
        if mode == .teasers {
            // Teaser-beat lines fade in already at full length (a trim/draw-on animation here
            // reads as lines being traced across the screen and thrown on top of the stars).
            // Staggered by the edge's own index in `edges` — ConstellationLayout.buildEdges
            // grows its MST outward from the hero (nearest-neighbor-first), so that array order
            // already radiates outward from the hero star. Without the stagger every line faded
            // in at the exact same instant, reading as a single mechanical snap rather than the
            // connection spreading outward.
            path
                .stroke(Color.white.opacity(drawn ? lineOpacity : 0), style: StrokeStyle(lineWidth: 0.8, lineCap: .round))
                .animation(
                    AppAnimation.enter
                        .delay(Double(index) * AppAnimation.desireBeatStaggerStep)
                        .reduceMotionSafe,
                    value: drawn
                )
        } else {
            path
                .trim(from: 0, to: drawn ? 1 : 0)
                .stroke(Color.white.opacity(lineOpacity), style: StrokeStyle(lineWidth: 0.8, lineCap: .round))
                .animation(AppAnimation.desireLineDraw.reduceMotionSafe, value: drawn)
        }
    }
```

- [ ] **Step 3: Build to verify**

Run: `xcodebuild -project Vayl.xcodeproj -scheme Vayl -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build` (use `-derivedDataPath /tmp/vayl-plan-build` if the default DerivedData is locked by a live Xcode session).
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

Follow the git hygiene sequence: stage only the one file, run `git diff --cached --stat` and confirm
it shows exactly one file BEFORE committing, then commit, then run `git show --stat` and confirm
exactly one file again AFTER committing.

```bash
git add "Vayl/Features/Desire Map/Views/Components/DesireConstellationView.swift"
git diff --cached --stat
# confirm exactly one file, THEN:
git commit -m "fix(desire-map): stagger teaser-beat line fade-in so it radiates outward from the hero"
git show --stat HEAD
# confirm exactly one file again
```

- [ ] **Step 5: Device-pass checkpoint (Bryan, not the agent)**

Open the reveal's teaser beat. Confirm the connecting lines now fade in one after another,
radiating outward from the lit hero star, rather than all appearing simultaneously.

---

## Self-review notes

- **Spec coverage:** The one requirement (stagger the line fade-in, radiating from the hero) is
  covered by the one change.
- **Type consistency:** `line(_:in:)` becomes `line(_:index:in:)` — the plan updates both the
  function definition and its one call site in the same task, so there's no stale call site left
  calling the old two-parameter signature.
- **No new tokens invented:** `AppAnimation.desireBeatStaggerStep` already exists and is already
  used for exactly this kind of per-item cascade elsewhere in this same ceremony
  (`DesireRevealView.swift`'s `_LockedSection`) — reused, not reinvented.
- **Out-of-scope respected:** `.resolved`/`.assemble`'s line behavior (the `else` branch) is
  untouched — only the `.teasers` branch gains the stagger.
