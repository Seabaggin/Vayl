# Map Tab Dashboard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the finalized Map dashboard: the Me/Us lens system (gated on linking, with a one-shot reveal ceremony), the complete Pulse pillar (fixed-footprint Me card, compact split-orb Us card with the unwritten/current/quiet state machine, rebuilt PulseFullView), and the Us-lens vault door.

**Spec:** `docs/superpowers/specs/2026-07-05-map-tab-dashboard-design.md`

**Architecture:** All lens state lives in `MapStore` (`layer`, `hasUs`, `usRevealSeen`). Pulse half-state resolution is a pure, tested model (`UsOrbState`). Views stay dumb: MapView renders sublabel + tint from store state; new `MapUsPulseCard` renders whatever `UsOrbState` says. The dashboard slims down; detail moves into `PulseFullView` (currently a stub — this plan rebuilds it with a me/us mode).

**Tech stack:** SwiftUI, SwiftData, existing Pulse components (`PulseAura`, `PulseCyclingAura`, `PulseField`, `PulseCapsule`, `PulseHistoryGrid`), Swift Testing in VaylTests.

**Build-verify command (every task):**
```bash
xcodebuild -project Vayl.xcodeproj -scheme Vayl -destination 'generic/platform=iOS Simulator' -derivedDataPath .build-claude CODE_SIGNING_ALLOWED=NO build 2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)"
```
Claude compile-verifies only; Bryan runs feel checks on device (listed per task as **Device done-condition**, checked at his pass, not blocking the next task's compile work).

---

## Task 1: `UsOrbState` — the per-half state machine (pure logic, TDD)

**Files:**
- Create: `Vayl/Features/Pulse/Models/UsOrbState.swift`
- Create: `VaylTests/UsOrbStateTests.swift`
- Modify: `Vayl.xcodeproj/project.pbxproj` (VaylTests is a MANUAL PBXGroup — new test files need wiring; follow the existing `AA00000N…` id convention used by the other test files)

**Constraints:** touches no views, no stores. Pure `Foundation`.

- [ ] **Step 1: Write the failing tests**

```swift
// VaylTests/UsOrbStateTests.swift
import Testing
import Foundation
@testable import Vayl

@Suite("UsOrbState")
struct UsOrbStateTests {

    private func entry(daysAgo: Int, now: Date) -> PulseEntry {
        var e = PulseEntry.previews[0]
        e.date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: now)!
        return e
    }

    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func neverCheckedInIsUnwritten() {
        #expect(UsOrbState.halfState(entries: [], now: now) == .unwritten)
    }

    @Test func entryWithinWindowIsCurrent() {
        let e = [entry(daysAgo: 0, now: now)]
        #expect(UsOrbState.halfState(entries: e, now: now) == .current)
        let edge = [entry(daysAgo: UsOrbState.quietAfterDays - 1, now: now)]
        #expect(UsOrbState.halfState(entries: edge, now: now) == .current)
    }

    @Test func oldEntryIsQuiet() {
        let e = [entry(daysAgo: UsOrbState.quietAfterDays, now: now)]
        #expect(UsOrbState.halfState(entries: e, now: now) == .quiet)
        let older = [entry(daysAgo: 30, now: now)]
        #expect(UsOrbState.halfState(entries: older, now: now) == .quiet)
    }

    @Test func wholeOrbUnwrittenOnlyWhenBothEmpty() {
        #expect(UsOrbState.resolve(mine: [], partner: [], now: now) == .wholeUnwritten)
    }

    @Test func firstEntryByEitherEarnsTheSplit() {
        let mine = [entry(daysAgo: 0, now: now)]
        let r = UsOrbState.resolve(mine: mine, partner: [], now: now)
        #expect(r == .split(mine: .current, partner: .unwritten))
    }

    @Test func headlineGuardNeverComparesQuietData() {
        let fresh = [entry(daysAgo: 0, now: now)]
        let old   = [entry(daysAgo: 10, now: now)]
        // Either side quiet/unwritten → live comparison is off.
        #expect(UsOrbState.resolve(mine: fresh, partner: old, now: now).allowsLiveComparison == false)
        #expect(UsOrbState.resolve(mine: fresh, partner: fresh, now: now).allowsLiveComparison == true)
    }
}
```

- [ ] **Step 2: Wire the test file into the VaylTests target in project.pbxproj** (mirror an existing `AA…` entry — PBXBuildFile, PBXFileReference, VaylTests group children, Sources build phase). Verify with `grep -c UsOrbStateTests Vayl.xcodeproj/project.pbxproj` → expect ≥ 3.

- [ ] **Step 3: Run tests, verify they FAIL** (`UsOrbState` not defined)

```bash
xcodebuild -project Vayl.xcodeproj -scheme Vayl -destination 'platform=iOS Simulator,name=iPhone 16' -derivedDataPath .build-claude CODE_SIGNING_ALLOWED=NO test -only-testing:VaylTests/UsOrbStateTests 2>&1 | tail -5
```

- [ ] **Step 4: Implement**

```swift
// Vayl/Features/Pulse/Models/UsOrbState.swift
//
// The Us orb's per-half state machine (spec §3.3). Pure logic — no SwiftUI.
// One rule users learn: cycling = unwritten, solid = current, ember = quiet.

import Foundation

enum UsOrbState: Equatable {

    /// Neither partner has EVER checked in → one whole cycling orb.
    /// The first entry by either partner earns the split.
    case wholeUnwritten
    case split(mine: HalfState, partner: HalfState)

    enum HalfState: Equatable {
        case unwritten   // never checked in → cycling ramp
        case current     // entry within the quiet window → solid space color
        case quiet       // has history, none within window → ember (0.6 α, desaturated)
    }

    /// Spec §3.3: the second, deeper threshold (isPositionStale = not-today only
    /// softens copy). Start value 4 — FEEL: tune on device.
    static let quietAfterDays = 4

    static func halfState(entries: [PulseEntry], now: Date = Date()) -> HalfState {
        guard let last = entries.last?.date else { return .unwritten }
        let days = Calendar.current.dateComponents([.day], from: last, to: now).day ?? .max
        return days < quietAfterDays ? .current : .quiet
    }

    static func resolve(mine: [PulseEntry], partner: [PulseEntry], now: Date = Date()) -> UsOrbState {
        if mine.isEmpty && partner.isEmpty { return .wholeUnwritten }
        return .split(mine: halfState(entries: mine, now: now),
                      partner: halfState(entries: partner, now: now))
    }

    /// Headline guard (spec §3.3): the relational read may only compute distance
    /// when BOTH halves are current.
    var allowsLiveComparison: Bool {
        if case .split(.current, .current) = self { return true }
        return false
    }
}
```

(If `PulseEntry.date` is `let`, adjust the test helper to construct a `PulseEntry` via its memberwise/initializer instead of mutating a preview — check `Vayl/Core/Models/PulseEntry.swift` first.)

- [ ] **Step 5: Run tests, verify PASS** (same command). Watch for the known `@MainActor` isolated-deinit retain-pool gotcha if the suite touches stores — this suite shouldn't.

- [ ] **Step 6: Commit** — `feat(pulse): UsOrbState per-half state machine with quiet window + headline guard`

---

## Task 2: Shared Pulse card footprint (`AppLayout` token + Me card)

**Files:**
- Modify: `Vayl/App/Theme/AppLayout.swift` (add token)
- Modify: `Vayl/Features/Map/Components/MapPulseHero.swift`

**Constraints:** may not touch MapUsLayer, PulseFullView, MapView's lens logic.

- [ ] **Step 1: Add the token** — in AppLayout (near the OB card sizing helpers):

```swift
/// The Map dashboard Pulse card — ONE height shared by the Me and Us lenses so
/// the lens flip never shifts the slots below (spec §1). Orb sizes derive from it.
static let mapPulseCardHeight: CGFloat = 218
/// Me aura ≈ 104/218, Us split orb ≈ 98/218 of the card (mockup ratios).
static var mapMeAuraSize: CGFloat  { mapPulseCardHeight * 0.48 }
static var mapUsOrbSize: CGFloat   { mapPulseCardHeight * 0.45 }
```

- [ ] **Step 2: Pin MapPulseHero to the footprint.** Wrap its card content in `.frame(height: AppLayout.mapPulseCardHeight)` and replace its hardcoded aura sizing (currently `auraSize: 60` at `MapPulseHero.swift:224`) with `AppLayout.mapMeAuraSize`, layout centered: eyebrow row top ("The Pulse · you" / tap hint), aura centered, state line + substate + today-line below. Keep the existing unwritten (`PulseCyclingAura`) and stale (`PulseFieldEntry.staleOpacity` + softened copy) behavior — states are already correct here, this task is geometry only.

- [ ] **Step 3: Compile-verify.** Expected: BUILD SUCCEEDED.

- [ ] **Step 4: Commit** — `feat(map): shared mapPulseCardHeight token; Me Pulse card pinned to the fixed footprint`

**Device done-condition:** Me Pulse card reads as the mockup (centered aura, fixed height); no visual regression in the check-in affordance.

---

## Task 3: Lens gating + reveal flag in MapStore (TDD)

**Files:**
- Modify: `Vayl/Features/Map/MapStore.swift`
- Create: `VaylTests/MapStoreLensTests.swift` (+ pbxproj wiring as Task 1 Step 2)

- [ ] **Step 1: Write the failing tests**

```swift
// VaylTests/MapStoreLensTests.swift
import Testing
import Foundation
@testable import Vayl

@MainActor
@Suite("MapStore lens gating")
struct MapStoreLensTests {

    @Test func usRequiresLinkAndPartnerName() {
        let store = MapStore()
        // No couple configured → no partner name → no Us.
        #expect(store.hasUs == false)
    }

    @Test func layerSnapsToMeWhenUsDisappears() {
        let store = MapStore()
        store.layer = .us
        store.enforceLensGate()          // hasUs == false here
        #expect(store.layer == .me)
    }

    @Test func revealFlagRoundTrips() {
        let defaults = UserDefaults(suiteName: "MapStoreLensTests")!
        defaults.removePersistentDomain(forName: "MapStoreLensTests")
        let store = MapStore(defaults: defaults)
        #expect(store.usRevealSeen == false)
        store.markUsRevealSeen()
        #expect(store.usRevealSeen == true)
        store.resetUsReveal()            // unlink path (spec §2.3)
        #expect(store.usRevealSeen == false)
    }
}
```

- [ ] **Step 2: Run tests → FAIL** (`hasUs`, `enforceLensGate`, initializer not defined).

- [ ] **Step 3: Implement in MapStore**

```swift
// MARK: - Lens gating (spec §2.3)

/// Us exists only after linking: partner identity loaded. Views must render
/// no toggle, no sublabel contrast, no Us content when this is false.
var hasUs: Bool { !partnerName.isEmpty }

/// If the Us lens vanished (unlink, partner cleared), snap back to Me.
func enforceLensGate() {
    if !hasUs && layer == .us { layer = .me }
}

// MARK: - Us reveal ceremony flag (spec §2.4)

private let defaults: UserDefaults
private static let usRevealKey = "map.usRevealSeen"

init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
}

var usRevealSeen: Bool { defaults.bool(forKey: Self.usRevealKey) }
func markUsRevealSeen() { defaults.set(true, forKey: Self.usRevealKey) }
/// Unlink resets the flag so a future re-link earns the ceremony again.
func resetUsReveal() { defaults.set(false, forKey: Self.usRevealKey) }
```

Call `resetUsReveal()` from the unlink flow: in `SettingsStore.unlink()` (or wherever `linkState` flips to `.unlinked`), clear the same UserDefaults key — grep `func unlink` in `Vayl/Features/Settings/SettingsStore.swift` and add `UserDefaults.standard.set(false, forKey: "map.usRevealSeen")` with a comment pointing at this spec. (One key, two writers is acceptable here; the string lives in one `static let` if you prefer — expose `MapStore.resetUsRevealGlobally()` as a static.)

- [ ] **Step 4: Run tests → PASS. Compile-verify the app target.**
- [ ] **Step 5: Commit** — `feat(map): lens gating (hasUs) + persisted usRevealSeen flag with unlink reset`

---

## Task 4: Lens sublabel, ambient tint, and gating in MapView

**Files:**
- Modify: `Vayl/Features/Map/MapView.swift`

**Constraints:** no changes to MapUsLayer/MapPulseHero content; masthead + chrome only.

- [ ] **Step 1: Gate the toggle.** In `nameToggle`, the partner button already hides when `partner.isEmpty`; additionally guard all Us rendering on `store.hasUs`, and add `.onChange(of: store.hasUs) { _, _ in store.enforceLensGate() }` on the screen ZStack. Also call `store.enforceLensGate()` in `.task`.

- [ ] **Step 2: Lens sublabel.** In `masthead`, under the existing subtitle, add (only when `store.hasUs` — no contrast to draw pre-link, spec §2.3):

```swift
if store.hasUs {
    Text(store.layer == .us ? "Shared · you both see this" : "Only you")
        .font(AppFonts.caption)
        .foregroundStyle(store.layer == .us
            ? AppColors.spectrumMagenta.opacity(0.8)
            : AppColors.spectrumCyan.opacity(0.8))
        .transition(.opacity)
        .accessibilityLabel(store.layer == .us
            ? "Shared lens: your partner sees this too"
            : "Private lens: only you see this")
}
```

- [ ] **Step 3: Ambient lens tint.** Above the `OnboardingAtmosphere` (do NOT modify atmosphere internals), add a lens-keyed wash:

```swift
RadialGradient(
    colors: [ (store.layer == .us ? AppColors.spectrumMagenta : AppColors.spectrumPurple)
                .opacity(0.10), .clear ],
    center: .top, startRadius: 0, endRadius: 420
)
.ignoresSafeArea()
.animation(AppAnimation.slow, value: store.layer)
.allowsHitTesting(false)
```

(Opacity 0.10 start value — FEEL: tune on device. Static per lens: not a loop, so no ambient gate needed; the flip animates via the user-initiated layer change.)

- [ ] **Step 4: Compile-verify. Commit** — `feat(map): lens sublabel + ambient lens tint; Us fully gated on hasUs`

**Device done-condition:** flipping lenses visibly re-tints the sky and swaps the sublabel; unpaired build shows name-alone masthead with no sublabel.

---

## Task 5: `SplitOrbView` + `MapUsPulseCard` — the compact Us card

**Files:**
- Create: `Vayl/Features/Map/Components/MapUsPulseCard.swift` (card + SplitOrbView + per-half rendering)
- Modify: `Vayl/Features/Map/Components/MapUsLayer.swift` (replace the inline full-width field block with the card; keep stats/align sections untouched for now)

**Constraints:** may not touch PulseField/PulseCapsule/PulseHistoryGrid sources (they move, unmodified, in Task 6). No new colors — space colors come from the existing `AuraColors`/`PulseSpace` mapping used by MapUsLayer today.

- [ ] **Step 1: Build the card**

```swift
// Vayl/Features/Map/Components/MapUsPulseCard.swift
//
// The Us lens Pulse card (spec §3.2–3.3): same footprint as the Me card.
// Split orb left, relational read right. Per-half states from UsOrbState.

import SwiftUI

struct MapUsPulseCard: View {
    let myEntries:      [PulseEntry]
    let partnerEntries: [PulseEntry]
    let partnerName:    String
    let relativeDay:    (Date) -> String     // PulseStore.relativeDay — injected, no store ref
    var onTap:          (() -> Void)? = nil

    private var state: UsOrbState { UsOrbState.resolve(mine: myEntries, partner: partnerEntries) }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("THE PULSE · TOGETHER")
                    .font(AppFonts.overline).tracking(2)
                    .foregroundStyle(AppColors.spectrumMagenta)
                Spacer()
                Text("tap to open").font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }
            switch state {
            case .wholeUnwritten:
                wholeUnwrittenBody
            case .split(let mine, let partner):
                splitBody(mine: mine, partner: partner)
            }
        }
        .padding(AppSpacing.md)
        .frame(height: AppLayout.mapPulseCardHeight)
        .frame(maxWidth: .infinity)
        .vaylGlassCard(accent: AppColors.spectrumMagenta, radius: AppRadius.container)
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
    }

    // Neither has EVER checked in: one whole cycling orb — the split is earned
    // by the first entry (spec §3.3).
    private var wholeUnwrittenBody: some View {
        HStack(spacing: AppSpacing.lg) {
            PulseCyclingAura(size: AppLayout.mapUsOrbSize)
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("The Pulse starts\nwith a check-in")
                    .font(AppFonts.display(19, weight: .semibold, relativeTo: .title3))
                    .foregroundStyle(AppColors.textPrimary)
                Text("One check-in from either of you begins the shared read.")
                    .font(AppFonts.caption).foregroundStyle(AppColors.textSecondary)
            }
        }
        .frame(maxHeight: .infinity)
    }

    private func splitBody(mine: UsOrbState.HalfState, partner: UsOrbState.HalfState) -> some View {
        HStack(spacing: AppSpacing.lg) {
            SplitOrbView(
                mine: half(mine, entries: myEntries),
                partner: half(partner, entries: partnerEntries),
                size: AppLayout.mapUsOrbSize
            )
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text(headline(mine: mine, partner: partner))
                    .font(AppFonts.display(19, weight: .semibold, relativeTo: .title3))
                    .foregroundStyle(AppColors.textPrimary)
                namesRead(mine: mine, partner: partner)
                if partner == .quiet, let last = partnerEntries.last?.date {
                    // Acknowledgment, never pressure (spec §3.3): one line, NO CTA.
                    Text("\(partnerName) hasn't checked in since \(relativeDay(last))")
                        .font(AppFonts.caption).foregroundStyle(AppColors.textTertiary)
                }
            }
        }
        .frame(maxHeight: .infinity)
    }

    private func half(_ s: UsOrbState.HalfState, entries: [PulseEntry]) -> SplitOrbView.Half {
        switch s {
        case .unwritten: return .cycling
        case .current:   return .solid(space(entries))
        case .quiet:     return .ember(space(entries))
        }
    }
    private func space(_ entries: [PulseEntry]) -> PulseSpace {
        entries.last?.space ?? .neutral
    }

    private func headline(mine: UsOrbState.HalfState, partner: UsOrbState.HalfState) -> String {
        let s = UsOrbState.resolve(mine: myEntries, partner: partnerEntries)
        guard s.allowsLiveComparison,
              let me = myEntries.last?.resolvedPosition,
              let them = partnerEntries.last?.resolvedPosition else {
            // Headline guard (spec §3.3): freshest-truth phrasing, never a live read.
            if partner == .unwritten { return "\(partnerName) hasn't\nchecked in yet" }
            return "Your last reads,\nside by side"
        }
        return me.distance(to: them) > 0.45 ? "A wide day" : "Close today"
    }

    @ViewBuilder
    private func namesRead(mine: UsOrbState.HalfState, partner: UsOrbState.HalfState) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            if mine != .unwritten, let s = myEntries.last?.space {
                Text("You in \(s.displayName)")
                    .font(AppFonts.caption).foregroundStyle(AppColors.spectrumCyan)
            }
            if partner != .unwritten, let s = partnerEntries.last?.space {
                Text("\(partnerName) in \(s.displayName)")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .opacity(partner == .quiet ? PulseFieldEntry.staleOpacity : 1)
            }
        }
    }
}

// MARK: - SplitOrbView

/// A single orb of two diagonal halves. Rendering rules (spec §3.3):
/// solid = space color · cycling = the unwritten ramp · ember = last color at the
/// SHARED 0.6 floor (PulseFieldEntry.staleOpacity — never lower) + desaturation.
/// One animation per property: the whole orb breathes scale; a cycling half
/// animates only its own fill.
struct SplitOrbView: View {
    enum Half { case cycling, solid(PulseSpace), ember(PulseSpace) }
    let mine: Half
    let partner: Half
    var size: CGFloat = 98

    @State private var breathing = false

    var body: some View {
        ZStack {
            halfShape(mine, top: true)
            halfShape(partner, top: false)
            // seam + rim highlights (mockup: 135° hairline + top-left glass shine)
            Rectangle().fill(Color.white.opacity(0.22))
                .frame(width: size * 1.5, height: 1.2)
                .rotationEffect(.degrees(-45))
            Circle().strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .scaleEffect(breathing ? 1.045 : 1.0)
        .ambientAnimation(AppAnimation.ambientPulse, value: breathing)
        .onAppear { breathing = true }
    }

    @ViewBuilder
    private func halfShape(_ half: Half, top: Bool) -> some View {
        let mask = HalfCircle(top: top)
        switch half {
        case .solid(let space):
            auraFill(space).clipShape(mask)
        case .ember(let space):
            auraFill(space)
                .saturation(0.4)                              // FEEL: tune on device
                .opacity(PulseFieldEntry.staleOpacity)        // 0.6 — the shared floor, never lower
                .clipShape(mask)
        case .cycling:
            PulseCyclingAura(size: size).clipShape(mask)
        }
    }

    private func auraFill(_ space: PulseSpace) -> some View {
        // Reuse the exact space→AuraColors mapping MapUsLayer uses today for its
        // field entries (grep `AuraColors` usage there and mirror it) — no new colors.
        PulseAura(energy: 0.5, openness: 0.5, size: size)     // replace with space-keyed ramp init per that mapping
    }
}

private struct HalfCircle: Shape {
    let top: Bool
    func path(in r: CGRect) -> Path {
        var p = Path()
        if top { p.move(to: .init(x: r.minX, y: r.maxY)); p.addLine(to: .init(x: r.minX, y: r.minY)); p.addLine(to: .init(x: r.maxX, y: r.minY)) }
        else   { p.move(to: .init(x: r.minX, y: r.maxY)); p.addLine(to: .init(x: r.maxX, y: r.maxY)); p.addLine(to: .init(x: r.maxX, y: r.minY)) }
        p.closeSubpath()
        return p
    }
}
```

Note on `auraFill`: MapUsLayer already derives per-space ramps for its field entries — copy that exact derivation (space → `AuraColors` → `PulseAura(ramp:size:)`) so the halves use canonical space colors. The `PulseAura(energy:openness:)` line above is the fallback only if no space-keyed init exists.

- [ ] **Step 2: Swap it into MapUsLayer.** Replace the full-width field block (`fieldBlock`, the GeometryReader square at `MapUsLayer.swift:147-208`) and its headline/copy section with `MapUsPulseCard(myEntries: pulse.entries, partnerEntries: partnerEntries, partnerName: partnerName, relativeDay: pulse.relativeDay, onTap: onOpenPulse)` — add an `onOpenPulse: (() -> Void)?` parameter to MapUsLayer, wired from MapView to `showPulseSheet = true`. Delete the now-unused fieldBlock helpers **but keep `usGridPairs` and the grid** (they move in Task 6 — leave the `PulseHistoryGrid` where it is for this task so nothing is orphaned mid-plan).

- [ ] **Step 3: Compile-verify. Commit** — `feat(map): compact split-orb Us Pulse card (UsOrbState-driven); demolish inline field`

**Device done-condition:** Me↔Us flip holds the Pulse slot perfectly still; ember half is clearly faded but unambiguously colored; quiet line reads as acknowledgment (no button).

---

## Task 6: Rebuild `PulseFullView` with me/us modes; interior lens toggle

**Files:**
- Modify: `Vayl/Features/Pulse/PulseFullView.swift` (currently a stub)
- Modify: `Vayl/Features/Map/Components/MapUsLayer.swift` (remove the split grid — it moves here)
- Modify: `Vayl/Features/Map/MapView.swift` (pass store + entries)

- [ ] **Step 1: Rebuild PulseFullView.** Structure (composing ONLY existing components — this view is assembly, not invention):

```swift
struct PulseFullView: View {
    @Bindable var mapStore: MapStore              // interior lens toggle writes back (spec §2.2)
    var myEntries:      [PulseEntry]
    var partnerEntries: [PulseEntry]
    var partnerName:    String
    var onDismiss:      (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            interiorHeader                         // small name-toggle (reuse MapView's grammar at
                                                   // display(22)) + lens sublabel line (spec §2.5)
            ScrollView {
                switch mapStore.layer {
                case .me: meBody                   // last-30 grid: PulseHistoryGrid(mode: .me(...))
                case .us: usBody                   // PulseField square + PulseCapsule (the block
                                                   // deleted from MapUsLayer in Task 5, restored
                                                   // here verbatim) + split grid:
                                                   // PulseHistoryGrid(mode: .us(pairs, partnerName:))
                }
            }
        }
        .padding(AppSpacing.lg)
    }
}
```

Move `usGridPairs` (`PulseHistory.pairedLastLoggedSpaces`) and the Task-5-preserved grid + the field/capsule block from MapUsLayer into here. The Us mode only renders when `mapStore.hasUs`; the interior toggle hides otherwise. Guard: opening from Me shows Me mode; the interior toggle flips `mapStore.layer` so dismissing lands on the same lens you switched to (single source of truth — spec §2.2).

- [ ] **Step 2: Wire MapView.** `PulseFullView(mapStore: store, myEntries: pulse.entries, partnerEntries: store.partnerEntries, partnerName: store.partnerName, onDismiss: { showPulseSheet = false })`. MapUsLayer loses its grid section entirely; its remaining content is stats/align (untouched).

- [ ] **Step 3: Compile-verify. Commit** — `feat(pulse): rebuild PulseFullView with me/us modes + interior lens toggle; move field/grids off the dashboard`

**Device done-condition:** tap Pulse in Me → grid view; flip to Us inside → field + capsule + split grid; dismiss → dashboard is in Us.

---

## Task 7: The Us reveal ceremony (one-shot)

**Files:**
- Modify: `Vayl/Features/Map/MapView.swift`

**Constraints:** reactive one-shot — NO `.ambientAnimation`, no LPM gate (user feedback always plays); Reduce Motion collapses to crossfade + dealer line (spec §2.4). No new effect components — staged opacity/blur/spring on the existing masthead + a dealer-line Text. (Optional HolographicText upgrade is a feel-pass item, not this task.)

- [ ] **Step 1: Ceremony state + trigger.** In MapView:

```swift
@State private var revealStage: Int = 0        // 0 dormant · 1 name arriving · 2 flipped+line · 3 done
@Environment(\.accessibilityReduceMotion) private var reduceMotion

private var shouldPlayReveal: Bool {
    store.hasUs && !store.usRevealSeen
}

private func playUsReveal() {
    guard shouldPlayReveal else { return }
    store.markUsRevealSeen()                   // mark FIRST — a mid-ceremony backgrounding must not replay
    if reduceMotion {
        withAnimation(AppAnimation.enter) { store.layer = .us; revealStage = 2 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
            withAnimation(AppAnimation.exit) { revealStage = 3 }
        }
        return
    }
    withAnimation(AppAnimation.slow) { revealStage = 1 }                    // "& Alex" ignites
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        withAnimation(AppAnimation.spring) { store.layer = .us; revealStage = 2 }  // self-performing flip
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
        withAnimation(AppAnimation.exit) { revealStage = 3 }                // dealer line fades
    }
}
```

Trigger from both arrival paths (spec §2.4): `.task { … playUsReveal() }` after the store loads, AND `.onChange(of: store.hasUs) { _, has in if has { playUsReveal() } }` (link completing while on Map — the joiner flow).

- [ ] **Step 2: Render the stages.** During stage 1, the partner name renders through an igniting treatment instead of its resting dim state: opacity 0 → 1 with `.blur(radius: stage < 1 ? 6 : 0)` and the spectrum style applied from stage 1 on (reuses the existing `nameToggle` Texts — pass `revealStage` down or compute inline). Stage ≥ 2 shows the dealer line under the sublabel:

```swift
if revealStage == 2 {
    Text("\(store.partnerName) is here. Tap a name to change whose map you're reading.")
        .font(AppFonts.caption)
        .foregroundStyle(AppColors.textSecondary)
        .transition(.opacity)
}
```

The sky tint + sublabel flip come free from Task 4 (they key off `store.layer`).

- [ ] **Step 3: Compile-verify. Commit** — `feat(map): one-shot Us reveal ceremony (name ignition → self-performing flip → dealer line)`

**Device done-condition (the segment's real gate):** fresh install → pair → open Map: ceremony plays once, lands in Us, never replays on revisit; total < ~3s; RM variant is a clean crossfade. Timing values are FEEL — Bryan tunes the two delays on device.

---

## Task 8: Vault door card (Us lens) with spin-open

**Files:**
- Create: `Vayl/Features/Map/Components/VaultDoorCard.swift`
- Modify: `Vayl/Features/Map/Components/MapUsLayer.swift` (append the door below stats/align)
- Modify: `Vayl/Features/Map/MapView.swift` (door → spin → `showVault = true`)

**Constraints:** Us lens only (spec §1 interim); opens the EXISTING VaultSheet; `appState.vaultOpenPending` path must keep working (it bypasses the spin — programmatic, no gesture to reward).

- [ ] **Step 1: Build the door.** Emblem = the six-spoke diamond-lattice mark from the mockup, drawn as a `Canvas`/`Path` group with the spectrum gradient (crisp pass + `.spectrumBorderGlow`-style blurred pass per the OB card face rules), title "Our Vault", sum line "Where you meet · Agreements · The record", stat line from existing data (`alignItems.count` shared · agreements count when VaultStore exposes it, else omit · `sessions.count` sessions), "Open ›" in magenta.

```swift
struct VaultDoorCard: View {
    let summary: String
    let statLine: String
    var onOpen: () -> Void

    @State private var spinning = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            guard !reduceMotion else { onOpen(); return }     // RM: plain arrival, no spin
            withAnimation(AppAnimation.spring) { spinning = true }
            // Cover arrives overlapping the spin's tail (spec §4: total < 0.5s).
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                onOpen()
                spinning = false
            }
        } label: {
            VStack(spacing: AppSpacing.sm) {
                VaultEmblem()                                  // the lattice mark, 74pt
                    .frame(width: 74, height: 74)
                    .rotationEffect(.degrees(spinning ? 60 : 0))   // one lattice-spoke step
                Text("Our Vault")
                    .font(AppFonts.display(15, weight: .semibold, relativeTo: .headline))
                    .foregroundStyle(AppColors.textPrimary)
                Text(summary).font(AppFonts.caption).foregroundStyle(AppColors.textSecondary)
                Text(statLine).font(AppFonts.overline).foregroundStyle(AppColors.textTertiary)
                Text("Open ›").font(AppFonts.caption.bold()).foregroundStyle(AppColors.spectrumMagenta)
            }
            .padding(AppSpacing.md)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PressableCardStyle())
        .vaylGlassCard(accent: AppColors.spectrumMagenta, radius: AppRadius.container)
    }
}
```

(`VaultEmblem`: port the mockup SVG — circle r32 ring, six spokes at 60°, rotated square core — as a Path in the same file. All geometry proportional to the 74pt frame.)

- [ ] **Step 2: Mount in MapUsLayer** below the align section, `onOpen` → the existing `onOpenVault` closure (already plumbed to `showVault = true`).
- [ ] **Step 3: Compile-verify. Commit** — `feat(map): Our Vault door card with spin-open into VaultSheet`

**Device done-condition:** tap → handle turns → sheet arrives riding the spin's tail; feels < 0.5s; RM skips the spin.

---

## Task 9: Pulse consent caption + privacy toggle check

**Files:**
- Modify: `Vayl/Features/Map/Components/MapPulseHero.swift` (caption)
- Verify/modify: `Vayl/Features/Settings/SettingsPrivacyView.swift`

- [ ] **Step 1: The caption (spec §3.4).** On the Me Pulse card, under the today-line, one quiet line shown only when linked: `Text("Your read also appears in your shared orb").font(AppFonts.caption).foregroundStyle(AppColors.textMuted)` — gate on a new `isLinked` parameter passed from MapView (`store.hasUs`).
- [ ] **Step 2: Verify the toggle exists:** `grep -n "share_pulse\|sharePulse" -r Vayl/`. If SettingsPrivacyView already surfaces `share_pulse_with_partner`, done. If the column has no UI, add a `Toggle("Share my Pulse with my partner")` row to SettingsPrivacyView bound through SettingsStore to the profile column (mirror the adjacent privacy-toggle rows' exact pattern in that file), and make `MapStore.loadPartnerPulse` / the Us orb respect the partner's flag (server already filters if RLS-backed — verify by reading `PulseSyncService.fetchPartnerEntries`).
- [ ] **Step 3: Compile-verify. Commit** — `feat(pulse): shared-orb consent caption; surface share_pulse_with_partner toggle`

---

## Task 10: Sweep — violation checklist + device handoff

- [ ] **Step 1: Violation checklist pass over every touched file** (CLAUDE.md): no raw colors/fonts/durations (ceremony delays are choreography constants — name them in one `private enum RevealTiming` if more than two appear), every tap has press+haptic, loops use `.ambientAnimation`, no bottom-clearance additions (tab content), empty states present (wholeUnwritten card, unpaired masthead).
- [ ] **Step 2: Full test suite + build:** run VaylTests; compile-verify.
- [ ] **Step 3: Commit any sweep fixes; update the roadmap artifact** (`docs/roadmap/vayl-build-roadmap.html` BUILD_ROADMAP block) marking the Map dashboard build.
- [ ] **Step 4: Hand Bryan the device checklist** (the per-task Device done-conditions above, plus: lens flip slot-stability, ceremony once-only across relaunch, unlink→re-link replays ceremony, quiet ember legibility in bright light).

---

## Self-review notes

- Spec coverage: §1 skeleton (T2/T5), §2.1–2.5 (T3/T4/T7), §3.1 (T2), §3.2 (T5/T6), §3.3 (T1/T5), §3.4 (T9), §3.5 (T5 ambient gates), §4 vault spin (T8); §4 tabs+gear already built; §6 interim slots respected (MapRecord untouched, Me-lens vault door absent).
- Known unknowns called out inline rather than hidden: `PulseEntry` mutability (T1), space→AuraColors derivation (T5), share-toggle existence (T9). Each has a concrete verification command or file pointer.
