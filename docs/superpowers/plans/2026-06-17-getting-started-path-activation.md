# Getting Started — "The Path" Activation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Home shows the full dashboard from day one with a compact "Your first steps" card that expands *outward* (matched-geometry morph) into a "Path" overlay — the couple's first steps to their reveal — over a blurred Home, dismissing back into the card.

**Architecture:** A pure `GettingStarted` model derives the step list + progress from existing `HomeStore` flags. The dashboard renders even when the map isn't done (the `.gated`/`.postReflection`/`.waiting` router cases render `dashboardContent`, not `HomeGateView`), and shows a `GettingStartedEntryCard`. Tapping it toggles a `showPath` overlay hosted in `HomeRouterView`: the Home blurs, a scrim fades in, and `GettingStartedPathView` morphs from the entry card via `matchedGeometryEffect(anchor: .center)` (expand-out, not down). `HomeStore.homeState` and `isTabLocked()` are unchanged, so tab-gating still works.

**Tech Stack:** SwiftUI (iOS 26.2 target), `@Observable` stores, SwiftData (read-only here), `matchedGeometryEffect` (pattern already used in `CardChestContainer`). No new dependencies.

**Visual spec:** the approved mock `docs/prototypes/desire-home-path-overlay.html` (Home base + blurred-backdrop Path overlay) and the heartbeat Pulse already shipped in `PulseGraph.swift`. The morph must **expand outward from the bar** (`anchor: .center`), not grow downward.

**Testing note (project reality):** Per `[[feedback_no_sim_runs]]`, Claude compile-verifies (`xcodebuild`); Bryan device-tests feel. Only the pure derivation logic (Task 1) is unit-tested (TDD). UI tasks use compile-verify + a device-verify checkpoint (Task 8). This follows the codebase's established verification pattern.

**Build command (every compile step):**
```bash
xcodebuild build -scheme Vayl -destination 'generic/platform=iOS Simulator' -configuration Debug 2>&1 | grep -E "BUILD SUCCEEDED|BUILD FAILED|error:"
```
Expected: `** BUILD SUCCEEDED **`

---

## File Structure

- **Create** `Vayl/Features/Home/Models/GettingStarted.swift` — `GettingStartedStepKind` enum, `GettingStartedStep` (kind + state), `GettingStarted` (steps + progress + nextStep) and its pure `resolve(...)` factory. One responsibility: derive the activation state. No SwiftUI.
- **Create** `Vayl/Features/Home/Components/GettingStartedEntryCard.swift` — the compact dashboard card (progress ring + next-step label + chevron). Source of the matched-geometry morph.
- **Create** `Vayl/Features/Home/Views/GettingStartedPathView.swift` — the overlay card: intro + the spectrum step journey + close + privacy footer. Destination of the morph.
- **Modify** `Vayl/Features/Home/Store/HomeStore.swift` — add `gettingStarted: GettingStarted` computed; no state-machine change.
- **Modify** `Vayl/Features/Home/Views/HomeRouterView.swift` — render `dashboardContent` for `.gated`/`.postReflection`/`.waiting`; host the `showPath` overlay + `@Namespace` + blur + scrim; route step actions.
- **Modify** `Vayl/Features/Home/Views/HomeDashboardView.swift` — accept `gettingStarted` + a `pathNamespace` + `onOpenPath`; insert `GettingStartedEntryCard` between the greeting block and the deck chest; add a `pathOpen` blur.
- **Create** `VaylTests/Home/GettingStartedTests.swift` — unit tests for `GettingStarted.resolve`.

`HomeGateView.swift` is **retired from routing** (no longer rendered) but kept on disk; its reassurance copy is reused in `GettingStartedPathView`.

---

## Task 1: GettingStarted model + derivation (TDD)

**Files:**
- Create: `Vayl/Features/Home/Models/GettingStarted.swift`
- Test: `VaylTests/Home/GettingStartedTests.swift`

- [ ] **Step 1: Write the failing test**

Create `VaylTests/Home/GettingStartedTests.swift`:
```swift
import XCTest
@testable import Vayl

final class GettingStartedTests: XCTestCase {

    func test_day1_paired_nothingDone_mapIsActive_inviteAutoDone() {
        let gs = GettingStarted.resolve(myMapComplete: false, isPaired: true, partnerMapComplete: false, revealDone: false)
        XCTAssertEqual(gs.steps.map(\.kind), [.profile, .mapDesires, .invitePartner, .seeReveal])
        XCTAssertEqual(gs.state(of: .profile), .done)            // onboarding finished
        XCTAssertEqual(gs.state(of: .invitePartner), .done)      // already paired
        XCTAssertEqual(gs.state(of: .mapDesires), .active)       // the next action
        XCTAssertEqual(gs.state(of: .seeReveal), .locked)
        XCTAssertEqual(gs.nextStep?.kind, .mapDesires)
        XCTAssertEqual(gs.completedCount, 2)                     // profile + invite
        XCTAssertEqual(gs.totalCount, 4)
        XCTAssertFalse(gs.isComplete)
    }

    func test_unpaired_inviteIsActiveAfterMap() {
        let gs = GettingStarted.resolve(myMapComplete: true, isPaired: false, partnerMapComplete: false, revealDone: false)
        XCTAssertEqual(gs.state(of: .mapDesires), .done)
        XCTAssertEqual(gs.state(of: .invitePartner), .active)    // unpaired → inviting is the next action
        XCTAssertEqual(gs.nextStep?.kind, .invitePartner)
    }

    func test_bothDone_revealIsActive() {
        let gs = GettingStarted.resolve(myMapComplete: true, isPaired: true, partnerMapComplete: true, revealDone: false)
        XCTAssertEqual(gs.state(of: .seeReveal), .active)
        XCTAssertEqual(gs.nextStep?.kind, .seeReveal)
    }

    func test_allDone_isComplete_noNext() {
        let gs = GettingStarted.resolve(myMapComplete: true, isPaired: true, partnerMapComplete: true, revealDone: true)
        XCTAssertTrue(gs.isComplete)
        XCTAssertNil(gs.nextStep)
        XCTAssertEqual(gs.completedCount, 4)
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run:
```bash
xcodebuild test -scheme Vayl -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VaylTests/GettingStartedTests 2>&1 | grep -E "error:|Compiling|FAIL"
```
Expected: FAIL — `cannot find 'GettingStarted' in scope`.

- [ ] **Step 3: Write the model**

Create `Vayl/Features/Home/Models/GettingStarted.swift`:
```swift
//
//  GettingStarted.swift
//  Vayl
//
//  Pure derivation of the post-onboarding "first steps" activation (Model layer — no SwiftUI).
//  The displayed Path + entry card both read this. Derived from HomeStore flags; never stored.
//

import Foundation

enum GettingStartedStepKind: String, CaseIterable, Hashable {
    case profile        // set up your space (onboarding)
    case mapDesires     // rate the desire map
    case invitePartner  // pair with your partner
    case seeReveal      // the couple reveal (gated)
}

enum GettingStartedStepState: Hashable {
    case done
    case active     // the single current next action
    case upcoming   // not yet, but reachable
    case locked     // blocked until earlier steps finish
}

struct GettingStartedStep: Identifiable, Hashable {
    let kind: GettingStartedStepKind
    let state: GettingStartedStepState
    var id: GettingStartedStepKind { kind }

    var title: String {
        switch kind {
        case .profile:       return "Set up your space"
        case .mapDesires:    return "Map your desires"
        case .invitePartner: return "Bring in your partner"
        case .seeReveal:     return "See what you share"
        }
    }
    var subtitle: String {
        switch kind {
        case .profile:       return "Done in onboarding"
        case .mapDesires:    return "Rate what you want, privately"
        case .invitePartner: return "They map theirs too"
        case .seeReveal:     return "Unlocks when you both finish"
        }
    }
}

struct GettingStarted: Equatable {
    let steps: [GettingStartedStep]

    func state(of kind: GettingStartedStepKind) -> GettingStartedStepState {
        steps.first { $0.kind == kind }?.state ?? .locked
    }
    var nextStep: GettingStartedStep? { steps.first { $0.state == .active } }
    var completedCount: Int { steps.filter { $0.state == .done }.count }
    var totalCount: Int { steps.count }
    var isComplete: Bool { completedCount == totalCount }
    var progress: Double { totalCount == 0 ? 0 : Double(completedCount) / Double(totalCount) }

    /// Derive the activation from the couple's real flags. `profile` is always done (we only reach
    /// Home post-onboarding). `invitePartner` is done when already paired. Exactly one step is
    /// `.active` (the next action); everything after it is `.locked`.
    static func resolve(myMapComplete: Bool, isPaired: Bool, partnerMapComplete: Bool, revealDone: Bool) -> GettingStarted {
        let done: Set<GettingStartedStepKind> = {
            var s: Set<GettingStartedStepKind> = [.profile]
            if myMapComplete { s.insert(.mapDesires) }
            if isPaired { s.insert(.invitePartner) }
            if revealDone { s.insert(.seeReveal) }
            return s
        }()
        // `seeReveal` only becomes reachable (active) once BOTH partners have mapped.
        let order: [GettingStartedStepKind] = [.profile, .mapDesires, .invitePartner, .seeReveal]
        var activeAssigned = false
        let steps: [GettingStartedStep] = order.map { kind in
            if done.contains(kind) { return GettingStartedStep(kind: kind, state: .done) }
            // reveal is gated on both-complete regardless of order position
            let reachable = (kind != .seeReveal) || (myMapComplete && partnerMapComplete)
            if reachable && !activeAssigned {
                activeAssigned = true
                return GettingStartedStep(kind: kind, state: .active)
            }
            return GettingStartedStep(kind: kind, state: reachable ? .upcoming : .locked)
        }
        return GettingStarted(steps: steps)
    }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run:
```bash
xcodebuild test -scheme Vayl -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VaylTests/GettingStartedTests 2>&1 | grep -E "error:|Test Suite.*passed|FAIL"
```
Expected: all four tests pass.

- [ ] **Step 5: Commit**
```bash
git add Vayl/Features/Home/Models/GettingStarted.swift VaylTests/Home/GettingStartedTests.swift
git commit -m "feat(home): GettingStarted activation model + derivation"
```

---

## Task 2: Expose `gettingStarted` on HomeStore

**Files:**
- Modify: `Vayl/Features/Home/Store/HomeStore.swift` (add a computed property near `homeState`, ~line 30)

- [ ] **Step 1: Add the computed property**

In `HomeStore`, directly under the `homeState` computed property, add:
```swift
    /// The post-onboarding "first steps" activation, derived from the same flags as `homeState`.
    var gettingStarted: GettingStarted {
        GettingStarted.resolve(
            myMapComplete: myMapComplete,
            isPaired: isPaired,
            partnerMapComplete: partnerMapComplete,
            revealDone: revealDone
        )
    }
```
(`isPaired` already exists on `HomeStore` as `appState.appMode == .together`.)

- [ ] **Step 2: Compile-verify**

Run the build command. Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Commit**
```bash
git add Vayl/Features/Home/Store/HomeStore.swift
git commit -m "feat(home): expose gettingStarted on HomeStore"
```

---

## Task 3: GettingStartedEntryCard (the compact dashboard card)

**Files:**
- Create: `Vayl/Features/Home/Components/GettingStartedEntryCard.swift`

- [ ] **Step 1: Write the view**

Create the file:
```swift
import SwiftUI

/// Compact "Your first steps" card on the dashboard. Tapping it opens the Path overlay.
/// Carries the matched-geometry source so the card morphs (expands out) into the overlay.
struct GettingStartedEntryCard: View {
    let gettingStarted: GettingStarted
    let namespace: Namespace.ID
    let isHidden: Bool          // true while the overlay is open (source handed to the overlay card)
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.md) {
                ProgressRingView(progress: gettingStarted.progress, size: 38)

                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text("Your first steps")
                        .font(AppFonts.overline)
                        .foregroundColor(AppColors.textTertiary)
                    Text(gettingStarted.nextStep?.title ?? "All set")
                        .font(AppFonts.bodyMedium)
                        .foregroundColor(AppColors.textPrimary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textTertiary)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.md)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .fill(AppColors.cardBg)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .stroke(AppColors.spectrumBorder, lineWidth: 1)
                    .opacity(0.45)
            )
            .matchedGeometryEffect(id: "gettingStartedPath", in: namespace, anchor: .center, isSource: !isHidden)
            .opacity(isHidden ? 0 : 1)   // hidden while the overlay owns the matched frame
        }
        .buttonStyle(PlainButtonStyle())
    }
}
```
Note: `ProgressRingView` already exists (used in the old `DesireMapView` progress summary). It takes `progress:` + `size:`.

- [ ] **Step 2: Compile-verify** (build command). Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Commit**
```bash
git add Vayl/Features/Home/Components/GettingStartedEntryCard.swift
git commit -m "feat(home): GettingStartedEntryCard (matched-geometry source)"
```

---

## Task 4: GettingStartedPathView (the overlay journey card)

**Files:**
- Create: `Vayl/Features/Home/Views/GettingStartedPathView.swift`

- [ ] **Step 1: Write the view**

Create the file:
```swift
import SwiftUI

/// The "Path" overlay card — the couple's first steps to their reveal. Destination of the
/// matched-geometry morph from GettingStartedEntryCard. Presented over a blurred Home.
struct GettingStartedPathView: View {
    let gettingStarted: GettingStarted
    let namespace: Namespace.ID
    let onSelect: (GettingStartedStepKind) -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Begin together")
                    .font(AppFonts.overline)
                    .foregroundStyle(AppColors.spectrumText)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textTertiary)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(AppColors.cardBackground))
                }
                .buttonStyle(PlainButtonStyle())
            }

            Text("Three steps to your first reveal.")
                .font(AppFonts.cardTitle)
                .foregroundColor(AppColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, AppSpacing.sm)

            Text("Each one brings the two of you closer to what you share.")
                .font(AppFonts.bodyText)
                .foregroundColor(AppColors.textSecondary)
                .padding(.top, AppSpacing.xs)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(gettingStarted.steps.enumerated()), id: \.element.id) { idx, step in
                    PathStepRow(
                        step: step,
                        isLast: idx == gettingStarted.steps.count - 1,
                        onTap: { if step.state == .active { onSelect(step.kind) } }
                    )
                }
            }
            .padding(.top, AppSpacing.lg)

            Text("🔒 Private to you — only what you both share is ever revealed")
                .font(AppFonts.meta)
                .foregroundColor(AppColors.textMuted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, AppSpacing.lg)
        }
        .padding(AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.xl)
                .fill(AppColors.cardBg)
        )
        .overlay(alignment: .top) {
            RoundedRectangle(cornerRadius: AppRadius.pill)
                .fill(AppColors.spectrumBorder)
                .frame(height: 2)
                .padding(.horizontal, AppSpacing.lg)
        }
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.xl)
                .stroke(AppColors.spectrumBorder, lineWidth: 1)
                .opacity(0.5)
        )
        .matchedGeometryEffect(id: "gettingStartedPath", in: namespace, anchor: .center, isSource: true)
    }
}

/// One node on the Path: a spectrum rail + a state-styled node + copy.
private struct PathStepRow: View {
    let step: GettingStartedStep
    let isLast: Bool
    let onTap: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            ZStack(alignment: .top) {
                if !isLast {
                    Rectangle()
                        .fill(rail)
                        .frame(width: 2)
                        .padding(.top, 30)
                }
                node
            }
            .frame(width: 30)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(step.title)
                    .font(AppFonts.bodyMedium)
                    .foregroundColor(step.state == .active ? AppColors.textPrimary : AppColors.textSecondary)
                Text(step.subtitle)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textTertiary)
                if step.state == .active {
                    Text("Start →")
                        .font(AppFonts.caption.weight(.semibold))
                        .foregroundColor(AppColors.spectrumCyan)
                        .padding(.top, AppSpacing.xs)
                }
            }
            .padding(.bottom, isLast ? 0 : AppSpacing.lg)
            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }

    private var rail: Color {
        switch step.state {
        case .done:    return AppColors.spectrumPurple
        default:       return AppColors.textTertiary.opacity(0.25)
        }
    }

    @ViewBuilder private var node: some View {
        switch step.state {
        case .done:
            Circle().fill(AppColors.spectrumBorder)
                .frame(width: 30, height: 30)
                .overlay(Image(systemName: "checkmark").font(AppFonts.caption).foregroundColor(.white))
        case .active:
            Circle().fill(AppColors.cardBg)
                .frame(width: 30, height: 30)
                .overlay(Circle().stroke(AppColors.spectrumCyan, lineWidth: 2))
                .spectrumBorderGlow(intensity: 0.6)
        case .upcoming:
            Circle().fill(AppColors.cardBg)
                .frame(width: 30, height: 30)
                .overlay(Circle().stroke(AppColors.borderSubtle, lineWidth: 2))
        case .locked:
            Circle().fill(AppColors.cardBg)
                .frame(width: 30, height: 30)
                .overlay(Image(systemName: "lock.fill").font(AppFonts.meta).foregroundColor(AppColors.textTertiary))
        }
    }
}
```
Notes: `AppColors.spectrumText` and `AppColors.spectrumBorder` are the LinearGradient tokens (per CLAUDE.md). If `spectrumText` isn't usable as `foregroundStyle`, substitute `AppColors.spectrumCyan`. `.spectrumBorderGlow(intensity:)` exists (used elsewhere). The active-node glow + the heartbeat are already established tokens.

- [ ] **Step 2: Compile-verify** (build command). If a token name errors (e.g. `spectrumText`), swap for the nearest confirmed token (`spectrumCyan`) and rebuild. Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Commit**
```bash
git add Vayl/Features/Home/Views/GettingStartedPathView.swift
git commit -m "feat(home): GettingStartedPathView overlay (matched-geometry destination)"
```

---

## Task 5: Host the overlay + render the dashboard from day one (HomeRouterView)

**Files:**
- Modify: `Vayl/Features/Home/Views/HomeRouterView.swift` (state ~14–29; switch ~60–117; dashboard call ~167–183)

- [ ] **Step 1: Add the namespace + open state**

In `HomeRouterView`, alongside `activeSession`/`activeMap`:
```swift
    @Namespace private var pathNamespace
    @State private var showPath = false
```

- [ ] **Step 2: Render the dashboard (not the gate) for the day-1 state + add the overlay**

Route ONLY `.gated` (the brand-new, pre-map state) to the dashboard. Leave `.postReflection`, `.waiting`, `.matchReady` on their dedicated views (`PostMapReflectionView`, `HomeWaitingView`, `HomeMatchReadyView`) — this feature is the day-1 activation, not a rework of those flows. `homeState` + `isTabLocked` are untouched, so tabs stay gated. In `routedContent`, change:
```swift
        case .gated:
            HomeGateView(
                isPaired: store.isPaired,
                onStartMap: { activeMap = DesireMapStore(modelContainer: modelContext.container, appState: appState) }
            )
            .transition(.opacity)
```
to:
```swift
        case .gated:
            dashboardContent(store)        // dashboard from day one; the activation Path lives on it
```
Then wrap the whole `ZStack { switch … }` content so the overlay sits above it. At the end of `routedContent`, after the `ZStack`'s switch but inside the ZStack, add the scrim + overlay:
```swift
        ZStack {
            switch store.homeState { … }    // existing

            if showPath {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture { withAnimation(AppAnimation.spring) { showPath = false } }

                GettingStartedPathView(
                    gettingStarted: store.gettingStarted,
                    namespace: pathNamespace,
                    onSelect: { kind in
                        withAnimation(AppAnimation.spring) { showPath = false }
                        handleStep(kind, store: store)
                    },
                    onClose: { withAnimation(AppAnimation.spring) { showPath = false } }
                )
                .padding(.horizontal, AppSpacing.lg)
                .transition(.opacity)
            }
        }
        .animation(AppAnimation.spring, value: showPath)
        // existing: .animation(AppAnimation.enter, value: store.homeState) + .task { await store.loadAll() }
```

- [ ] **Step 3: Add the step-action router**

Add a private method on `HomeRouterView`:
```swift
    private func handleStep(_ kind: GettingStartedStepKind, store: HomeStore) {
        switch kind {
        case .mapDesires:
            activeMap = DesireMapStore(modelContainer: modelContext.container, appState: appState)
        case .invitePartner:
            appState.selectedTab = .map     // pairing lives on the Map tab today (PairingSettingsView)
        case .seeReveal, .profile:
            break                            // reveal = D4 (not built); profile already done
        }
    }
```

- [ ] **Step 4: Pass the activation into the dashboard**

In `dashboardContent(store:)`, pass the new params to `HomeDashboardView` (added in Task 6):
```swift
        HomeDashboardView(
            // …existing params…
            gettingStarted: store.gettingStarted,
            pathNamespace: pathNamespace,
            pathOpen: showPath,
            onOpenPath: { withAnimation(AppAnimation.spring) { showPath = true } }
        )
```

- [ ] **Step 5: Compile-verify** (build command). Expected: `** BUILD SUCCEEDED **`. (Task 6 must land together — `HomeDashboardView` needs the new params. Do Task 6 before this builds clean; commit them together.)

- [ ] **Step 6: Commit** (with Task 6)
```bash
git add Vayl/Features/Home/Views/HomeRouterView.swift
git commit -m "feat(home): dashboard-from-day-one + Path overlay host with matched-geometry morph"
```

---

## Task 6: Insert the entry card on the dashboard + blur when open

**Files:**
- Modify: `Vayl/Features/Home/Views/HomeDashboardView.swift` (init params; body greeting→chest slot ~125; blur on body)

- [ ] **Step 1: Add the new init params**

Add stored properties to `HomeDashboardView`:
```swift
    let gettingStarted: GettingStarted
    let pathNamespace: Namespace.ID
    let pathOpen: Bool
    let onOpenPath: () -> Void
```
Add them to the memberwise init / call site accordingly (it's a value-type View — add to the parameter list in declaration order, before the `on…` closures).

- [ ] **Step 2: Insert the entry card in the scroll VStack**

In `body`, immediately after `greetingBlock` (and its padding) and before `CardChestContainer`, add:
```swift
                    if !gettingStarted.isComplete {
                        GettingStartedEntryCard(
                            gettingStarted: gettingStarted,
                            namespace: pathNamespace,
                            isHidden: pathOpen,
                            onTap: onOpenPath
                        )
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.top, AppSpacing.lg)
                        .opacity(greetingVisible ? 1 : 0)   // ride the existing entrance stagger
                    }
```

- [ ] **Step 3: Blur the dashboard while the overlay is open**

On the outermost content of `body` (the `ZStack`/`GeometryReader` root), add:
```swift
        .blur(radius: pathOpen ? 9 : 0)
        .animation(AppAnimation.spring, value: pathOpen)
```
(Apply to the dashboard content only — not to the overlay, which is hosted above it in `HomeRouterView`.)

- [ ] **Step 4: Avoid a double "map" prompt**

The `DesireMapIndicator` block (renders for `desireMapState != .hidden`) would duplicate the entry card's "map your desires" for a day-1 user. Gate it so it only shows once the activation is complete:
```swift
                    if gettingStarted.isComplete && desireMapState != .hidden && desireMapState != .fullyUnlocked {
                        DesireMapIndicator(state: desireMapState, onReveal: …, onUnlock: …, onRemind: …)
                            .padding(.horizontal, AppSpacing.lg)
                    }
```

- [ ] **Step 5: Compile-verify** (build command, together with Task 5). Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 6: Commit** (with Task 5, same commit as Task 5 Step 6 — or a paired commit).

---

## Task 7: Step-completion Moment (lightweight)

**Files:**
- Modify: `Vayl/Features/Home/Views/HomeRouterView.swift` (`handleStep`, and on return from the rater)

A full "Moments" UI doesn't exist (only `MilestoneRecord` + `HomeEvent` strings). Keep this minimal: a haptic + (if a toast/banner component exists) a warm line; otherwise a no-op stub with a TODO. **Do not build a Moments system here.**

- [ ] **Step 1: Add a haptic on opening a step**

In `handleStep`, before the switch:
```swift
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
```

- [ ] **Step 2: TODO marker for the real Moment**

Add a comment where the rater completes (the `DesireMapStore` completion path already syncs): 
```swift
        // TODO(Moments): when gettingStarted advances a step (e.g. map → invite), fire a warm
        // HomeEvent/Moment ("First Spark") via the (future) Moments surface. No silent flag.
```

- [ ] **Step 3: Compile-verify + commit**
```bash
git add Vayl/Features/Home/Views/HomeRouterView.swift
git commit -m "feat(home): light haptic on step open + Moments TODO"
```

---

## Task 8: Device verification (Bryan)

Not automatable — Claude compile-verifies; Bryan runs on device.

- [ ] **Step 1: Reach the day-1 Home.** Fresh install → onboard → land on Home. Confirm the **full dashboard renders** (not the old gate) with the **"Your first steps" card** between the wordmark and the deck.
- [ ] **Step 2: Open the Path.** Tap the card → it **expands outward** (centered morph, not growing downward) into the Path overlay; Home **blurs** behind. Confirm the steps show correct states (Set up ✓, Map active, Invite ✓-if-paired, Reveal locked).
- [ ] **Step 3: Dismiss.** Tap ✕ or the dimmed area → the card **shrinks back into the bar**, Home un-blurs.
- [ ] **Step 4: Route a step.** Tap "Map your desires → Start" → the rater opens (existing `activeMap`). Complete it → re-open Home → the card progress advances; the active step moves to the next.
- [ ] **Step 5: Tabs still gated.** Confirm Play/Map remain locked pre-completion (state machine unchanged).
- [ ] **Step 6: Tune the morph feel.** Adjust `AppAnimation.spring` (or a dedicated duration) so the expand-out feels right; confirm `anchor: .center` reads as "expanding out," not "down."

---

## Self-Review

**Spec coverage:**
- Dashboard from day one → Task 5 (route `.gated` to `dashboardContent`; later states keep their dedicated views).
- "Your first steps" entry card → Tasks 3, 6.
- Expand-OUT morph (not down) → `matchedGeometryEffect(anchor: .center)` in Tasks 3 + 4; tuned in Task 8.
- Blurred Home behind + scrim + fade back → Tasks 5 (scrim/overlay) + 6 (dashboard blur).
- Steps derive from real state → Tasks 1, 2.
- Step actions (map/invite/reveal) → Task 5 `handleStep`.
- Tabs stay gated (state machine intact) → Task 5 (homeState/isTabLocked unchanged).
- Moments → Task 7 (deliberately stubbed; full system out of scope).

**Placeholder scan:** none — all views have full code; the only intentional stub is the Moments surface (Task 7), which is explicitly out of scope and marked TODO.

**Type consistency:** `GettingStarted` / `GettingStartedStep` / `GettingStartedStepKind` / `.resolve(...)` / `state(of:)` / `nextStep` / `progress` / `isComplete` used consistently across Tasks 1, 2, 3, 4, 6. Matched-geometry id `"gettingStartedPath"` identical in the entry card (source when closed) and the path view (source when open). `pathNamespace` threaded HomeRouterView → HomeDashboardView → GettingStartedEntryCard, and HomeRouterView → GettingStartedPathView.

**Open risks to verify during build:**
- `AppColors.spectrumText` as a `foregroundStyle` — if it doesn't conform, use `AppColors.spectrumCyan` (Task 4 note).
- `HomeDashboardView`'s init is large; adding params means updating the call site in `HomeRouterView.dashboardContent` (Task 5 Step 4) — they must land in the same build.
- matchedGeometryEffect across the scroll view ↔ overlay can flicker if both are briefly `isSource: true`; the `isHidden`/`isSource` toggle (entry source when closed, path source when open) prevents that.
