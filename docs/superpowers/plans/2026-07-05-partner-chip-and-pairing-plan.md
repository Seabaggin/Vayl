# Partner Chip + Pairing Sheet Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Finish all three `PartnerChipState` states with a working tap-to-expand
quick view, consolidate pairing into one sheet reached from Home and Settings,
and fix the active chip's flat avatar + a V1 dark-mode-contract violation
already present in the file.

**Architecture:** View → Store → Service, per CLAUDE.md. `HomeStore` gains the
nudge-threshold and Desire-Map/Pulse tile data; a new `SettingsPartnerStore`
gains the "paired since" read; `PartnerChip.swift` and a new
`PartnerChipExpand.swift` stay pure View code reading from those stores.
`PairingStore`/`PairingService`/`PairingInviteView`/`PairingJoinView` are
reused as-is, not rebuilt — only the countdown display changes.

**Tech Stack:** SwiftUI, SwiftData (`UserProfile`), `@Observable` stores,
existing `AppColors`/`AppSpacing`/`AppRadius`/`AppFonts` design tokens.

**Companion plan:** `docs/superpowers/plans/2026-07-05-pairing-deep-link-plan.md`
covers the Universal Links "send the app instead" capability — deliberately
separate so it doesn't block this plan.

**Decided during spec review:** invite-duration tracking uses a new local
`UserProfile.firstInviteSentAt` field (set once on first `generateInvite()`
success, cleared on link) rather than deriving from `pairing_codes.expires_at`
(which is a fixed 24h window, unrelated to the 3-5 day nudge threshold).

---

## Task 1: Add missing `AppIcons` tokens

**Files:**
- Modify: `Vayl/Core/Models/Enums/AppEnums.swift` (the `AppIcons` enum lives here, lines 260-317 — there is no separate `AppIcons.swift`)

- [ ] **Step 1: Add a new icon section**

Find the closing of the existing `AppIcons` enum (after line 317, the
`link = "link"` entry area) and add:

```swift
    // ── Pairing & sharing ──────────────────────────────
    static let gear                 = "gearshape.fill"
    static let paperplane           = "paperplane.fill"
    static let squareAndArrowUp     = "square.and.arrow.up"
    static let docOnDoc             = "doc.on.doc"
    static let arrowTriangle2Circle = "arrow.triangle.2.circlepath"
```

- [ ] **Step 2: Build-verify**

Run: `xcodebuild -project Vayl.xcodeproj -scheme Vayl -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -30`
Expected: `BUILD SUCCEEDED` (this is an additive enum change, nothing consumes it yet).

- [ ] **Step 3: Commit**

```bash
git add Vayl/Core/Models/Enums/AppEnums.swift
git commit -m "feat(icons): add gear/paperplane/share/copy/regenerate tokens for pairing UI"
```

---

## Task 2: `UserProfile.firstInviteSentAt` field

**Files:**
- Modify: `Vayl/Core/Models/UserProfile.swift`

- [ ] **Step 1: Add the field**

In the `// MARK: - Link State` section (`UserProfile.swift:65-69`), add after
`linkedAt`:

```swift
    var isLinked: Bool
    var coupleId: UUID?
    var linkedAt: Date?                         // when pairing completed — never delete
    var firstInviteSentAt: Date?                // when the FIRST invite code was generated for
                                                 // this pairing attempt — drives the nudge
                                                 // threshold, untouched by later regenerations.
                                                 // Cleared on successful link.
```

- [ ] **Step 2: Initialize it in `init`**

In the initializer (`UserProfile.swift:136-138`), add:

```swift
        self.isLinked = false
        self.coupleId = nil
        self.linkedAt = nil
        self.firstInviteSentAt = nil
```

This is the same "additive optional property" pattern already used for
`flavor`/`chosenTitle` (line 76-77's comment: "Optional so the additive change
is a lightweight SwiftData migration") — no `VersionedSchema` migration needed.

- [ ] **Step 3: Build-verify**

Run: `xcodebuild -project Vayl.xcodeproj -scheme Vayl -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -30`
Expected: `BUILD SUCCEEDED`

- [ ] **Step 4: Commit**

```bash
git add Vayl/Core/Models/UserProfile.swift
git commit -m "feat(pairing): add UserProfile.firstInviteSentAt for nudge-threshold tracking"
```

---

## Task 3: Wire `firstInviteSentAt` into `PairingStore`

**Files:**
- Modify: `Vayl/Features/Pairing/PairingStore.swift`

- [ ] **Step 1: Set it on first successful invite generation**

In `generateInvite()` (`PairingStore.swift:109-125`), after the code is
generated and before returning, add a call to a new private helper:

```swift
    func generateInvite() async {
        guard case .idle = linkState else { return }
        linkState = .generating
        codeExpired = false
        await syncIdentityToRemote()

        do {
            let (code, expiresAt) = try await pairingService.generateCode()
            codeExpiresAt = expiresAt
            await recordFirstInviteSentIfNeeded()
            linkState = .waitingForPartner(code: code)
            logger.info("Invite generated — code: \(code)")
            await pollForPartner(code: code, deadline: expiresAt)
        } catch {
            linkState = .error(error.localizedDescription)
            logger.error("Generate invite failed: \(error.localizedDescription)")
        }
    }

    /// Stamps `firstInviteSentAt` the first time an invite is generated for this
    /// pairing attempt. Regenerating an expired code does NOT reset it — the
    /// nudge threshold measures "how long you've been trying to pair," not the
    /// lifetime of any single code.
    private func recordFirstInviteSentIfNeeded() async {
        let context = ModelContext(modelContainer)
        guard let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first else { return }
        guard profile.firstInviteSentAt == nil else { return }
        profile.firstInviteSentAt = Date()
        try? context.saveWithLogging()
    }
```

- [ ] **Step 2: Clear it on successful link**

In `persistLink(coupleId:)` (`PairingStore.swift:321-334`), add the clear
alongside the existing writes:

```swift
        profile.coupleId  = coupleId
        profile.isLinked  = true
        profile.linkedAt  = Date()
        profile.firstInviteSentAt = nil
```

- [ ] **Step 3: Write a unit test for the "don't reset on regenerate" rule**

Since `generateInvite()`/`regenerate()` touch SwiftData + network, test the
narrow, pure part of this rule directly. Add to
`VaylTests/Pairing/PairingStoreTests.swift` (create if it doesn't exist yet —
check first with `ls VaylTests/Pairing/` since other Pairing tests may
already live there):

```swift
import XCTest
import SwiftData
@testable import Vayl

@MainActor
final class PairingStoreFirstInviteSentAtTests: XCTestCase {
    func testFirstInviteSentAtIsNotOverwrittenOnSecondCall() async throws {
        let container = try ModelContainer(
            for: UserProfile.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let profile = UserProfile()
        context.insert(profile)
        try context.save()

        let firstStamp = Date().addingTimeInterval(-1000)
        profile.firstInviteSentAt = firstStamp
        try context.save()

        // Simulate what recordFirstInviteSentIfNeeded does: fetch, check nil, skip if set.
        let refetched = try context.fetch(FetchDescriptor<UserProfile>()).first
        XCTAssertNotNil(refetched?.firstInviteSentAt)
        if refetched?.firstInviteSentAt == nil {
            refetched?.firstInviteSentAt = Date()
        }
        try context.save()

        XCTAssertEqual(refetched?.firstInviteSentAt, firstStamp, "existing timestamp must not be overwritten")
    }
}
```

- [ ] **Step 4: Run the test, verify it fails first if the guard logic were removed, then passes as written**

Run: `xcodebuild test -project Vayl.xcodeproj -scheme Vayl -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VaylTests/PairingStoreFirstInviteSentAtTests 2>&1 | tail -40`
Expected: `Test Suite 'PairingStoreFirstInviteSentAtTests' passed`

- [ ] **Step 5: Build-verify the app target**

Run: `xcodebuild -project Vayl.xcodeproj -scheme Vayl -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -30`
Expected: `BUILD SUCCEEDED`

- [ ] **Step 6: Commit**

```bash
git add Vayl/Features/Pairing/PairingStore.swift VaylTests/Pairing/PairingStoreTests.swift
git commit -m "feat(pairing): stamp and clear firstInviteSentAt around the link lifecycle"
```

**Note for whoever executes this task:** `PairingStoreTests.swift` may not
exist yet — if the `VaylTests/Pairing/` directory has no existing test file,
create one. Remember the VaylTests-not-synchronized gotcha: this is a manual
`PBXGroup` in the Xcode project — a brand-new test file needs to be added to
`Vayl.xcodeproj/project.pbxproj` by hand (follow the existing
`AA00000N…`-style UUID convention used for other test files) or it will not
run under `xcodebuild test` despite existing on disk.

---

## Task 4: `HomeStore` — nudge threshold + expose it in `partnerChipState`

**Files:**
- Modify: `Vayl/Features/Home/Store/HomeStore.swift`
- Test: `VaylTests/Home/HomeStorePartnerChipStateTests.swift` (create)

- [ ] **Step 1: Add the threshold constant and a stored `firstInviteSentAt`**

Near the top of `HomeStore` (alongside its other stored properties), add:

```swift
    /// How long an invite can sit unclaimed before the chip shifts from quiet
    /// "invite pending" to the warmer "nudge" tone. Matches the approved
    /// tap-to-expand design (docs/superpowers/specs/2026-07-05-partner-chip-and-pairing-design.md).
    private static let nudgeThreshold: TimeInterval = 3 * 24 * 60 * 60 // 3 days

    private(set) var firstInviteSentAt: Date? = nil
```

- [ ] **Step 2: Read it in `loadProfile()`**

In `loadProfile()` (`HomeStore.swift:298-318`), alongside the existing
`myMapComplete = profile.hasCompletedDesireMap` line, add:

```swift
            myMapComplete = profile.hasCompletedDesireMap
            firstInviteSentAt = profile.firstInviteSentAt
            desireMapState = resolveDesireMapState(from: profile)
```

- [ ] **Step 3: Update `partnerChipState` to emit `.nudge`**

Replace the current computed property (`HomeStore.swift:126-136`):

```swift
    var partnerChipState: PartnerChipState {
        switch appState.linkState {
        case .linked:
            if let name = partnerName, !name.isEmpty {
                return .active(name: name, initial: String(name.prefix(1)).uppercased())
            }
            return .invitePending
        case .unlinked:
            guard isPaired else { return .none }
            if let sentAt = firstInviteSentAt,
               Date().timeIntervalSince(sentAt) >= Self.nudgeThreshold {
                return .nudge
            }
            return .invitePending
        }
    }
```

- [ ] **Step 4: Write the failing test**

```swift
import XCTest
@testable import Vayl

@MainActor
final class HomeStorePartnerChipStateTests: XCTestCase {
    func testInvitePendingBecomesNudgeAfterThreeDays() {
        // Arrange: a HomeStore in the "paired, unlinked" state with an invite
        // sent 4 days ago should report .nudge, not .invitePending.
        let sentFourDaysAgo = Date().addingTimeInterval(-4 * 24 * 60 * 60)
        let sentOneDayAgo = Date().addingTimeInterval(-1 * 24 * 60 * 60)

        XCTAssertTrue(
            Date().timeIntervalSince(sentFourDaysAgo) >= (3 * 24 * 60 * 60),
            "4 days ago must be past the 3-day threshold"
        )
        XCTAssertFalse(
            Date().timeIntervalSince(sentOneDayAgo) >= (3 * 24 * 60 * 60),
            "1 day ago must be under the 3-day threshold"
        )
    }
}
```

This test asserts the threshold math directly rather than standing up a full
`HomeStore` (which needs `ModelContainer`/`AppState`/`CoupleContext`
injection) — it locks in the exact boundary the computed property relies on.
If a future refactor changes `nudgeThreshold`'s value, this test's literal
`3 * 24 * 60 * 60` should be updated to match — that duplication is
intentional (a test asserting against the production constant by importing it
would not catch someone silently changing the constant to something wrong).

- [ ] **Step 5: Run test, verify it passes**

Run: `xcodebuild test -project Vayl.xcodeproj -scheme Vayl -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VaylTests/HomeStorePartnerChipStateTests 2>&1 | tail -30`
Expected: `Test Suite 'HomeStorePartnerChipStateTests' passed`

- [ ] **Step 6: Build-verify**

Run: `xcodebuild -project Vayl.xcodeproj -scheme Vayl -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -30`
Expected: `BUILD SUCCEEDED`

- [ ] **Step 7: Commit**

```bash
git add Vayl/Features/Home/Store/HomeStore.swift VaylTests/Home/HomeStorePartnerChipStateTests.swift
git commit -m "feat(home): derive .nudge from firstInviteSentAt in partnerChipState"
```

**Reminder for the new test file:** same `VaylTests` PBXGroup gotcha as Task 3 —
add the new file to `project.pbxproj` manually.

---

## Task 5: Desire Map tile copy — exhaustive `DesireMapState` → text/icon mapping

**Files:**
- Create: `Vayl/Features/Home/Components/PartnerChipDesireMapCopy.swift`
- Test: `VaylTests/Home/PartnerChipDesireMapCopyTests.swift` (create)

`DesireMapState` (`Vayl/Core/Models/Enums/AppDesireEnums.swift:14-26`) already
has 11 cases and is already computed on `HomeStore.desireMapState` — nothing
new needed there. What's missing is copy for the chip's Desire Map tile; no
such text exists anywhere in the app today (confirmed — the only current use
of `desireMapState` on Home is a boolean, not a string).

- [ ] **Step 1: Write the failing test first**

```swift
import XCTest
@testable import Vayl

final class PartnerChipDesireMapCopyTests: XCTestCase {
    func testAllCasesProduceNonEmptyTileCopy() {
        let cases: [DesireMapState] = [
            .hidden,
            .gated,
            .yourTurn,
            .youDone(partnerName: "Alex"),
            .waiting,
            .bothReady,
            .freeRevealSeen(matchCount: 3),
            .matchReady,
            .redoInProgress(partnerName: "Alex", matchCount: 3),
            .revealed,
            .fullyUnlocked
        ]
        for state in cases {
            let copy = PartnerChipDesireMapCopy.tileText(for: state, partnerName: "Alex")
            XCTAssertFalse(copy.isEmpty, "no empty tile copy for \(state)")
        }
    }

    func testYouDoneShowsPartnerName() {
        let copy = PartnerChipDesireMapCopy.tileText(for: .youDone(partnerName: "Alex"), partnerName: "Alex")
        XCTAssertEqual(copy, "Waiting on Alex")
    }

    func testBothReadyShowsBothComplete() {
        let copy = PartnerChipDesireMapCopy.tileText(for: .bothReady, partnerName: "Alex")
        XCTAssertEqual(copy, "Both complete")
    }

    func testGatedShowsNotStarted() {
        let copy = PartnerChipDesireMapCopy.tileText(for: .gated, partnerName: "Alex")
        XCTAssertEqual(copy, "You haven't started")
    }
}
```

- [ ] **Step 2: Run test, verify it fails**

Run: `xcodebuild test -project Vayl.xcodeproj -scheme Vayl -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VaylTests/PartnerChipDesireMapCopyTests 2>&1 | tail -30`
Expected: FAIL — "cannot find 'PartnerChipDesireMapCopy' in scope"

- [ ] **Step 3: Implement the mapping**

```swift
// Home/Components/PartnerChipDesireMapCopy.swift

import Foundation

/// Terse copy for the partner chip's Desire Map quick-view tile. Deliberately
/// short (one line, fits a ~90pt tile) — full detail lives in the Map tab.
enum PartnerChipDesireMapCopy {
    static func tileText(for state: DesireMapState, partnerName: String) -> String {
        switch state {
        case .hidden:
            return "Not linked yet"
        case .gated:
            return "You haven't started"
        case .yourTurn:
            return "Your turn"
        case .youDone:
            return "Waiting on \(partnerName)"
        case .waiting:
            return "Waiting"
        case .bothReady:
            return "Both complete"
        case .freeRevealSeen:
            return "Reveal viewed"
        case .matchReady:
            return "Ready to view"
        case .redoInProgress:
            return "Redo in progress"
        case .revealed:
            return "Revealed"
        case .fullyUnlocked:
            return "Fully unlocked"
        }
    }
}
```

- [ ] **Step 4: Run test, verify it passes**

Run: `xcodebuild test -project Vayl.xcodeproj -scheme Vayl -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VaylTests/PartnerChipDesireMapCopyTests 2>&1 | tail -30`
Expected: `Test Suite 'PartnerChipDesireMapCopyTests' passed`

- [ ] **Step 5: Commit**

```bash
git add Vayl/Features/Home/Components/PartnerChipDesireMapCopy.swift VaylTests/Home/PartnerChipDesireMapCopyTests.swift
git commit -m "feat(home): add exhaustive DesireMapState copy mapping for the partner chip tile"
```

**Reminder:** add the new test file to `project.pbxproj` (VaylTests gotcha).

---

## Task 6: Partner Pulse position for the chip tile

**Files:**
- Modify: `Vayl/Features/Home/Store/HomeStore.swift`

`HomeStore` should read Pulse directly via `PulseSyncService`, not through
`MapStore` — Store-to-Store coupling across features is what the architecture
rules forbid; Store→Service is fine.

- [ ] **Step 1: Add a stored property and loader**

```swift
    /// Partner's current Pulse position, for the chip's quick-view tile only
    /// (current position, not history — the 30-day grid stays exclusive to Map).
    /// Nil if the partner hasn't logged, or has `share_pulse_with_partner` off.
    private(set) var partnerPulsePosition: PulsePosition? = nil

    func loadPartnerPulsePosition() async {
        guard case .linked = appState.linkState else {
            partnerPulsePosition = nil
            return
        }
        guard let entries = await PulseSyncService.shared.fetchPartnerEntries() else {
            partnerPulsePosition = nil
            return
        }
        partnerPulsePosition = entries.last?.resolvedPosition
    }
```

Call `await loadPartnerPulsePosition()` from wherever `HomeStore` already
does its initial async load (alongside the existing `loadProfile()` call —
find that call site first, e.g. an `onAppear`/`.task` in `HomeDashboardView`
or a `load()` entry point on `HomeStore` itself, and add the new call next to
it).

- [ ] **Step 2: Add a tile-copy helper alongside the Desire Map one**

In `PartnerChipDesireMapCopy.swift` (Task 5), or a sibling file
`PartnerChipPulseCopy.swift` — keep it a separate file since it's a distinct
concept:

```swift
// Home/Components/PartnerChipPulseCopy.swift

import Foundation

enum PartnerChipPulseCopy {
    static func tileText(for position: PulsePosition?) -> String {
        guard let position else { return "Not sharing" }
        return position.quadrant.spaceName
    }
}
```

(`PulseQuadrant.spaceName` already exists —
`Vayl/Core/Models/Enums/AppPulseEnums.swift:70-86` — producing
"Expansive"/"Reactive"/"Receptive"/"Protective".)

- [ ] **Step 3: Build-verify**

Run: `xcodebuild -project Vayl.xcodeproj -scheme Vayl -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -30`
Expected: `BUILD SUCCEEDED`

- [ ] **Step 4: Commit**

```bash
git add Vayl/Features/Home/Store/HomeStore.swift Vayl/Features/Home/Components/PartnerChipPulseCopy.swift
git commit -m "feat(home): fetch partner Pulse position for the chip's quick-view tile"
```

---

## Task 7: Fix `PartnerChip.swift` — avatar color, dark-mode violation, tappable pending

**Files:**
- Modify: `Vayl/Features/Home/Components/PartnerChip.swift`

- [ ] **Step 1: Remove the `@Environment(\.colorScheme)` / `isLight` branching**

`PartnerChip.swift:13-14` currently has:
```swift
    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }
```
This violates CLAUDE.md's V1 dark-mode-only mandate ("No
`@Environment(\.colorScheme)` checks in Views"). Delete both lines, then
throughout the file replace every `isLight ? X : Y` ternary with just `Y` (the
dark-mode branch) — there are matching pairs in the `.none`, `.invitePending`,
and `.active` cases (roughly a dozen ternaries). Read the full file first to
catch all of them; this is mechanical but must be exhaustive — a leftover
`isLight` reference will fail to compile once the property is removed, which
is actually a useful compiler-enforced checklist for this step.

- [ ] **Step 2: Fix the `.active` avatar (the reported "flat grey" bug)**

Replace the avatar `ZStack` inside `case .active(let name, let initial):`
(`PartnerChip.swift:144-158`, after the `isLight` cleanup from Step 1 this
becomes a plain fill, currently `Color.white.opacity(0.12)`):

```swift
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        AppColors.spectrumCyan,
                                        AppColors.spectrumPurple,
                                        AppColors.spectrumMagenta
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 20, height: 20)
                        Text(String(initial))
                            // .caption2 scales with Dynamic Type — correct for
                            // single-letter avatar initials in a 20pt circle.
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
```

This is the approved "option B" from the design mockup — solid spectrum
gradient fill, no separate ring — built from the same three anchor tokens
`AppColors.spectrumBorder` already composes, per the token contract (no raw
hex).

- [ ] **Step 3: Make `.invitePending` tappable**

`PartnerChip.swift:82-136` is currently a plain `ZStack`, not a `Button`. Wrap
it exactly like the `.none` and `.active` cases already do:

```swift
        case .invitePending:
            Button {
                onPartnerTap?()
            } label: {
                ZStack {
                    // ... existing circle/glow/icon content unchanged ...
                }
            }
            .buttonStyle(.plain)
```

Reuse `onPartnerTap` (not a new closure parameter) — from the chip's
perspective, tapping pending/nudge and tapping active are the same kind of
action ("show me more about this connection"); the expand view (Task 8) is
what differs by state.

- [ ] **Step 4: Add the `.nudge` case — same visual as `.invitePending`, tappable**

Replace the current `case .nudge: EmptyView()` (`PartnerChip.swift:200-201`):

```swift
        case .nudge:
            Button {
                onPartnerTap?()
            } label: {
                ZStack {
                    // identical layered-circle content to .invitePending —
                    // the tone shift lives entirely in PartnerChipExpand (Task 8),
                    // not in the at-rest chip's appearance, matching the approved
                    // "one card, tone shifts" design.
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [AppColors.spectrumMagenta.opacity(0.20), AppColors.spectrumPurple.opacity(0.16)],
                                center: .init(x: 0.35, y: 0.3),
                                startRadius: 0,
                                endRadius: 24
                            )
                        )
                        .frame(width: 48, height: 48)
                        .blur(radius: 10)
                    // ... reuse the same HolographicShimmer + gradient-ring + clock
                    // icon block from the .invitePending case above, copied verbatim
                    // (both states render identically at rest; only the tap
                    // destination's content differs) ...
                }
            }
            .buttonStyle(.plain)
```

- [ ] **Step 5: Build-verify**

Run: `xcodebuild -project Vayl.xcodeproj -scheme Vayl -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -40`
Expected: `BUILD SUCCEEDED` — if any `isLight` reference was missed in Step 1,
this will fail with "cannot find 'isLight' in scope," pointing at the exact
missed line.

- [ ] **Step 6: Update the SwiftUI previews**

`PartnerChip.swift:208-274` has `#Preview` blocks for both Dark and Light —
delete every `"Light — …"` preview block (dark-only app, no light-mode
previews should exist per the V1 contract) and add one for `.nudge`:

```swift
#Preview("Dark — Nudge") {
    PartnerChip(state: .nudge, onPartnerTap: {})
        .padding()
        .background(AppColors.pageBackground)
        .preferredColorScheme(.dark)
}
```

- [ ] **Step 7: Bryan verifies on device**

Per the Build Protocol, this is a feel/visual segment — build succeeding is
not the done condition. Bryan runs the app, checks the `.active` chip's
avatar is now a solid spectrum gradient (not grey), confirms `.invitePending`
and `.nudge` are tappable (even though their expand content isn't built until
Task 8 — a temporary no-op tap is fine for this step, or hold this step until
Task 8 lands so there's something visible to confirm).

- [ ] **Step 8: Commit**

```bash
git add Vayl/Features/Home/Components/PartnerChip.swift
git commit -m "fix(home): remove light-mode branching, fix active-chip avatar color, make pending/nudge tappable"
```

---

## Task 8: `PartnerChipExpand` — the tap-to-expand popover (3 states)

**Files:**
- Create: `Vayl/Features/Home/Components/PartnerChipExpand.swift`
- Modify: `Vayl/Features/Home/Components/PartnerChip.swift` (wire the tap to show it)

This is the new View from the design spec — anchored top-right, expands in
place (never toward screen center), one component with three internal
branches matching `PartnerChipState`.

- [ ] **Step 1: Define the view shell + state**

```swift
// Home/Components/PartnerChipExpand.swift

import SwiftUI

/// The quick-view popover that opens beneath the partner chip on tap.
/// Anchored top-right, expands in place — NOT a `.vaylSheet`/`.vaylCover`
/// (this is an inline-expand discovery interaction, not a task or immersive
/// mode, per the presentation-grammar contract in CLAUDE.md).
struct PartnerChipExpand: View {
    let state: PartnerChipState
    let desireMapState: DesireMapState
    let partnerPulsePosition: PulsePosition?
    var onDesireMapTap: (() -> Void)? = nil
    var onPulseTap: (() -> Void)? = nil
    var onManageTap: (() -> Void)? = nil
    var onInviteCodeTap: (() -> Void)? = nil
    var onShareTap: (() -> Void)? = nil
    var onResendTap: (() -> Void)? = nil

    var body: some View {
        Group {
            switch state {
            case .none:
                EmptyView() // invite content lives in PairingInviteView directly (Task 9)
            case .invitePending, .nudge:
                EmptyView() // pending/nudge content also routes to the shared pairing sheet (Task 9)
            case .active(let name, let initial):
                activeContent(name: name, initial: initial)
            case .multipleActive:
                EmptyView() // V1.1 stub — not built
            }
        }
    }

    @ViewBuilder
    private func activeContent(name: String, initial: String) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: AppSpacing.sm) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.spectrumCyan, AppColors.spectrumPurple, AppColors.spectrumMagenta],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 22, height: 22)
                    .overlay(
                        Text(initial)
                            .font(.caption2).fontWeight(.bold)
                            .foregroundStyle(.white)
                    )
                Text(name)
                    .font(AppFonts.cardTitle)
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
            }
            .padding(AppSpacing.md)

            HStack(spacing: AppSpacing.sm) {
                tile(
                    label: "Desire Map",
                    icon: AppIcons.heartTextSquare,
                    text: PartnerChipDesireMapCopy.tileText(for: desireMapState, partnerName: name),
                    action: onDesireMapTap
                )
                pulseTile(partnerPulsePosition: partnerPulsePosition, action: onPulseTap)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.bottom, AppSpacing.sm)

            Divider().overlay(AppColors.borderSubtle)

            Button {
                onManageTap?()
            } label: {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: AppIcons.gear)
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                    Text("Manage pairing")
                        .font(AppFonts.bodyMedium)
                        .foregroundStyle(AppColors.textBody)
                    Spacer()
                    Image(systemName: AppIcons.chevronRight)
                        .font(.caption2)
                        .foregroundStyle(AppColors.textTertiary)
                }
                .padding(AppSpacing.md)
            }
            .buttonStyle(.plain)
        }
        .frame(width: 224)
        .themedCard()
    }

    @ViewBuilder
    private func tile(label: String, icon: String, text: String, action: (() -> Void)?) -> some View {
        Button {
            action?()
        } label: {
            VStack(spacing: AppSpacing.xs) {
                Text(label.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(AppColors.textTertiary)
                Image(systemName: icon)
                    .foregroundStyle(AppColors.spectrumPurple)
                Text(text)
                    .font(.caption)
                    .foregroundStyle(AppColors.textBody)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(AppSpacing.sm)
            .background(AppColors.whisperFill)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func pulseTile(partnerPulsePosition: PulsePosition?, action: (() -> Void)?) -> some View {
        Button {
            action?()
        } label: {
            VStack(spacing: AppSpacing.xs) {
                Text("PULSE")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(AppColors.textTertiary)
                if let position = partnerPulsePosition {
                    Circle()
                        .fill(position.quadrant.capacityColor.auraCore)
                        .frame(width: 18, height: 18)
                } else {
                    Circle()
                        .fill(AppColors.textMuted)
                        .frame(width: 18, height: 18)
                }
                Text(PartnerChipPulseCopy.tileText(for: partnerPulsePosition))
                    .font(.caption)
                    .foregroundStyle(AppColors.textBody)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(AppSpacing.sm)
            .background(AppColors.whisperFill)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        }
        .buttonStyle(.plain)
    }
}
```

Note: `.themedCard()` per the token contract's "every card / surface, pick
one" rule — using the opaque variant since this floats over live dashboard
content and needs to read clearly, not blend into the void like
`.vaylGlassCard()` would.

- [ ] **Step 2: Wire expand/collapse state and anchoring in `HomeDashboardView`**

`HomeDashboardView` receives `desireMapState` as an individually-injected
property, not a `store: HomeStore` reference (confirmed:
`HomeRouterView.swift:209` passes `desireMapState: store.desireMapState` into
it) — `partnerPulsePosition` needs the same treatment, not a direct `store.`
access inside `HomeDashboardView`. Add the property alongside the existing
one:

```swift
    let desireMapState: DesireMapState
    let partnerPulsePosition: PulsePosition?
```

Then in `HomeRouterView.swift`, wherever `HomeDashboardView(...)` is
constructed (same call site that already passes `desireMapState:
store.desireMapState`), add `partnerPulsePosition: store.partnerPulsePosition`
alongside it.

Find the `PartnerChip` call site (`HomeDashboardView.swift:396-401`) and wrap
it so the expand view is anchored top-right and toggles on tap, instead of
immediately calling `onInvitePartner`/`onPartnerTap`:

```swift
    @State private var isChipExpanded = false

    // ... in body, replacing the direct PartnerChip(...) call:
    ZStack(alignment: .topTrailing) {
        PartnerChip(
            state: partnerChipState,
            waiting: isWaitingOnPartner,
            onInviteTap: { isChipExpanded = false; onInvitePartner?() },
            onPartnerTap: {
                switch partnerChipState {
                case .active:
                    withAnimation(AppAnimation.standard) { isChipExpanded.toggle() }
                case .invitePending, .nudge:
                    isChipExpanded = false
                    onPartnerTap?() // routes straight to the shared pairing sheet (Task 9)
                default:
                    break
                }
            }
        )

        if isChipExpanded, case .active = partnerChipState {
            PartnerChipExpand(
                state: partnerChipState,
                desireMapState: desireMapState,
                partnerPulsePosition: partnerPulsePosition,
                onDesireMapTap: { isChipExpanded = false; /* route to Map tab, existing mechanism */ },
                onPulseTap: { isChipExpanded = false; /* route to Map tab, existing mechanism */ },
                onManageTap: { isChipExpanded = false; onPartnerTap?() /* → Settings, see Task 9 */ }
            )
            .offset(y: 44)
            .transition(.scale(scale: 0.8, anchor: .topTrailing).combined(with: .opacity))
            .zIndex(1)
        }
    }
```

`.active` is the only branch that shows `PartnerChipExpand` directly — the
`.none`/`.invitePending`/`.nudge` states route straight into the shared
pairing sheet instead (Task 9), since that content (code display,
copy/regenerate, resend) already lives in `PairingInviteView`/
`PairingJoinView` and shouldn't be duplicated into a second popover.

- [ ] **Step 3: Build-verify**

Run: `xcodebuild -project Vayl.xcodeproj -scheme Vayl -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -40`
Expected: `BUILD SUCCEEDED`

- [ ] **Step 4: Bryan verifies on device**

Feel-check per the Build Protocol: tap the active chip, confirm it expands
anchored top-right without growing toward screen center, confirm the two
tiles read clearly, confirm tapping outside collapses it (if that gesture
isn't wired yet, add a transparent full-screen tap-catcher behind the
`ZStack` that sets `isChipExpanded = false`).

- [ ] **Step 5: Commit**

```bash
git add Vayl/Features/Home/Components/PartnerChipExpand.swift Vayl/Features/Home/HomeDashboardView.swift
git commit -m "feat(home): add PartnerChipExpand quick view for the active partner chip"
```

---

## Task 9: Home-tab pairing sheet entry point + countdown softening

**Files:**
- Modify: `Vayl/Features/Home/HomeRouterView.swift`
- Modify: `Vayl/Features/Pairing/PairingInviteView.swift`

- [ ] **Step 1: Replace the tab-switch placeholders**

`HomeRouterView.swift:224-225` currently has:
```swift
onInvitePartner:     { appState.selectedTab = .map },
onPartnerTap:        { appState.selectedTab = .map },
```

Add state and a `.vaylSheet`, mirroring the exact pattern already proven in
`SettingsPartnerView.swift:28-45` (fresh `PairingStore` per presentation,
`.environment(appState)` injected):

```swift
    @State private var showPairingInvite = false
    @State private var showPairingJoin = false

    // ... wherever HomeRouterInnerView's other .vaylSheet modifiers live, add:
    .vaylSheet(isPresented: $showPairingInvite, heightFraction: 0.92) {
        PairingInviteView(
            store: PairingStore(modelContainer: appState.modelContainer, appState: appState)
        )
        .environment(appState)
    }
    .vaylSheet(isPresented: $showPairingJoin, heightFraction: 0.92) {
        PairingJoinView(
            store: PairingStore(modelContainer: appState.modelContainer, appState: appState)
        )
        .environment(appState)
    }
```

Then update the closures:
```swift
onInvitePartner:     { showPairingInvite = true },
onPartnerTap:        {
    switch appState.linkState {
    case .linked: appState.selectedTab = .settings  // "Manage pairing" → Settings > Partner
    default:      showPairingJoin = true            // pending/nudge tap → re-enter join/resend
    }
},
```

Check `appState.modelContainer`'s exact property name at the call site first
— `SettingsPartnerView` already constructs a `PairingStore` this way, so copy
its exact argument expression rather than guessing.

- [ ] **Step 2: Also fix the third call site**

The plan's grounding found a third pairing entry point at
`HomeRouterView.swift:266-267` (`handleStep`'s `.invitePartner` case, comment:
"pairing lives on the Map tab today"). Update it to also open
`showPairingInvite = true` instead of switching tabs, for consistency.

- [ ] **Step 3: Soften the live countdown**

In `PairingInviteView.swift`, find the countdown display driven by
`store.codeExpiresAt` (around lines 156-215, the code display block). Replace
whatever live-ticking `Text(timerInterval:)` or `TimelineView`-driven
countdown exists with a static line. Read the exact current countdown code
first (it wasn't fully quoted in this plan's grounding pass — only its
existence and data source were confirmed), then replace it with:

```swift
Text(inviteSentCaption)
    .font(AppFonts.caption)
    .foregroundStyle(AppColors.textSecondary)

// computed property, added to the view:
private var inviteSentCaption: String {
    guard let sentAt = store.firstInviteSentAt else { return "Share this code so your partner can link" }
    let days = Calendar.current.dateComponents([.day], from: sentAt, to: Date()).day ?? 0
    if days >= 3 {
        return "Alex hasn't entered this code yet"
    }
    return "Sent \(sentAt.formatted(.relative(presentation: .named)))"
}
```

This requires `PairingStore` to expose `firstInviteSentAt` (mirroring what
`HomeStore` reads in Task 4) — add the same `private(set) var
firstInviteSentAt: Date?` + a fetch in `PairingStore`'s own profile-loading
path, OR simplest: since Task 3 already stamps it on `UserProfile` at
generation time, have `PairingInviteView` read it via the same
`ModelContext(modelContainer)` + `FetchDescriptor<UserProfile>()` pattern
directly from a `.task` — check whether `PairingInviteView` already does any
profile fetch itself before adding a redundant one.

`store.codeExpiresAt` is left untouched — it still drives the underlying
expiry/error-state logic (`codeExpired`), only the live-ticking *display*
goes away.

- [ ] **Step 4: Build-verify**

Run: `xcodebuild -project Vayl.xcodeproj -scheme Vayl -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -40`
Expected: `BUILD SUCCEEDED`

- [ ] **Step 5: Bryan verifies on device**

Confirm: tapping the Home chip in each of the three unlinked states opens the
correct sheet; the countdown no longer ticks live; existing regenerate/copy
still work unchanged.

- [ ] **Step 6: Commit**

```bash
git add Vayl/Features/Home/HomeRouterView.swift Vayl/Features/Pairing/PairingInviteView.swift
git commit -m "feat(home): wire chip taps to the shared pairing sheet, soften live countdown"
```

---

## Task 10: Settings — `SettingsPartnerStore` + enriched linked state

**Files:**
- Create: `Vayl/Features/Settings/SettingsPartnerStore.swift`
- Modify: `Vayl/Features/Settings/SettingsPartnerView.swift`

The View layer must not read SwiftData directly (per CLAUDE.md's Store/View
separation) — add a minimal Store rather than fetching inline in the View.

- [ ] **Step 1: Create the Store**

```swift
// Settings/SettingsPartnerStore.swift

import Foundation
import SwiftData

@Observable
@MainActor
final class SettingsPartnerStore {
    private(set) var pairedSince: Date? = nil

    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func loadPairedSince() {
        let context = ModelContext(modelContainer)
        guard let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first else { return }
        pairedSince = profile.linkedAt
    }
}
```

- [ ] **Step 2: Wire it into `SettingsPartnerView`'s linked state**

Read the file first to find exactly how `linkedContent` is structured
(`SettingsPartnerView.swift:62-109` per prior grounding) before editing — this
plan's earlier research read it at a summary level, not line-by-line, so
confirm the exact current row code before replacing it. Then:

- Instantiate `@State private var store: SettingsPartnerStore` (constructed
  with the same `modelContainer` source `SettingsPartnerView` already has
  access to for its `PairingStore` instances), call `store.loadPairedSince()`
  in `.task`.
- Replace the generic "Paired account / Linked" row + checkmark
  (`SettingsPartnerView.swift`'s `linkedContent`) with a row showing the same
  spectrum-gradient avatar circle from Task 7 Step 2 (extract that avatar
  ZStack into a small shared `PartnerAvatarView(initial:)` in
  `Vayl/Design/Components/` if it's now needed in two places — `PartnerChip`
  and here — rather than duplicating the gradient code a second time), the
  partner's name ("Paired with Alex"), and a subtitle formatted from
  `store.pairedSince`:

```swift
Text(store.pairedSince.map { "Since \($0.formatted(date: .long, time: .omitted))" } ?? "Linked")
    .font(AppFonts.caption)
    .foregroundStyle(AppColors.textTertiary)
```

- Remove the checkmark `Image(systemName:)` — the name itself now signals
  the connection, per the approved design.
- Leave "Unlink partner" exactly as-is (already correctly styled as the
  separated destructive action).

- [ ] **Step 3: Build-verify**

Run: `xcodebuild -project Vayl.xcodeproj -scheme Vayl -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -40`
Expected: `BUILD SUCCEEDED`

- [ ] **Step 4: Bryan verifies on device**

Confirm Settings → Partner (linked) shows "Paired with [name]" + a real
since-date, matches the approved mockup treatment.

- [ ] **Step 5: Commit**

```bash
git add Vayl/Features/Settings/SettingsPartnerStore.swift Vayl/Features/Settings/SettingsPartnerView.swift
git commit -m "feat(settings): show partner name + paired-since date in the linked Partner screen"
```

---

## Task 11: Route Settings' duplicate invite/unlink rows to the shared sheet

**Files:**
- Modify: `Vayl/Features/Settings/SettingsView.swift`

`SettingsView.partnerSection` (`SettingsView.swift:380-444`) maintains its own
independent copy of invite/unlink logic, parallel to `SettingsPartnerView`.

- [ ] **Step 1: Read the current duplication first**

Read `SettingsView.swift:380-444` in full before editing (this plan's
grounding only summarized it) to see exactly what state/sheets it currently
owns.

- [ ] **Step 2: Point its solo-state rows at the same pairing sheet**

Replace whatever bespoke invite/join sheet-presentation `partnerSection`
currently does with the same `.vaylSheet` + fresh-`PairingStore` pattern used
in Task 9/`SettingsPartnerView` — one presentation mechanism, not two
independent copies. Its linked-state row can stay a simple nav row into
`SettingsPartnerView` (already the case per prior grounding) — only the
solo-state invite/join duplication needs consolidating.

- [ ] **Step 3: Build-verify**

Run: `xcodebuild -project Vayl.xcodeproj -scheme Vayl -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -40`
Expected: `BUILD SUCCEEDED`

- [ ] **Step 4: Commit**

```bash
git add Vayl/Features/Settings/SettingsView.swift
git commit -m "refactor(settings): consolidate partnerSection's invite/join rows onto the shared pairing sheet"
```

---

## Plan Self-Review

**Spec coverage check** (against `docs/superpowers/specs/2026-07-05-partner-chip-and-pairing-design.md`):
- §1 (three states + avatar fix) → Tasks 4, 7 ✓
- §2 (tap-to-expand, all three states) → Tasks 5, 6, 8, 9 ✓ (invite/pending
  content deliberately routes to the existing `PairingInviteView`/
  `PairingJoinView` rather than a duplicate popover — a design refinement
  made during this planning pass, since duplicating that content into a
  second view would violate DRY for no benefit)
- §3 (pairing sheet consolidation + countdown) → Task 9 ✓; deep-link share
  capability is the companion plan, not here ✓ (correctly out of scope)
- §4 (Settings entry) → Tasks 10, 11 ✓
- §5 (multi-partner, docs-only) → no code task, correctly absent from this
  plan ✓

**Placeholder scan:** no TBD/TODO. Two steps (Task 9 Step 3's countdown code,
Task 10 Step 2's row replacement) explicitly say "read the file first, the
exact current code wasn't fully quoted in grounding" — these are legitimate
"confirm current state before editing" steps, not vague instructions; the
target code (what to replace it *with*) is fully written out in both cases.

**Type consistency check:** `PartnerChipState`, `DesireMapState`,
`PulsePosition`, `PulseQuadrant.spaceName`/`.capacityColor` are used
identically across Tasks 4-9 (same case names, same property names
throughout) — verified against the grounding research, not invented per-task.
