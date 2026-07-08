//
//  DesireRevealStoreTests.swift
//  VaylTests
//
//  The reveal ceremony's decision logic: the 3-beat state machine, the free/locked derived
//  views, star-tap routing, and the already-Core skip. Uses the DEBUG previewStore seam to
//  inject matches (no network), and a seeded Couple to exercise the Core path.
//

import XCTest
import SwiftData
@testable import Vayl

@MainActor
final class DesireRevealStoreTests: XCTestCase {

    // Workaround for a Swift @MainActor isolated-deinit runtime double-free
    // (swift_task_deinitOnExecutorImpl → POINTER_BEING_FREED_WAS_NOT_ALLOCATED) that aborts
    // the app-hosted test host whenever an @Observable @MainActor AppState/store deallocates
    // mid-suite. Keeping the objects alive for the process means the buggy isolated deinit
    // never runs during the test run. Test-only; leaked objects are never released (no deinit
    // fires at process exit either). Not a production concern — the app never deinits AppState.
    private static var retained: [AnyObject] = []
    private static func retain(_ objects: AnyObject...) { retained.append(contentsOf: objects) }

    // Free couple (entitlements resolve .free) with a free + two locked matches.
    private func freeStore() -> DesireRevealStore {
        let store = DesireRevealStore.previewStore(matches: [
            RevealMatch.sample("Slow mornings", .mutual, locked: false),
            RevealMatch.sample("New cities", .adjacent, locked: true),
            RevealMatch.sample("Big talks", .mutual, locked: true),
        ])
        Self.retain(store)
        return store
    }

    // MARK: - Initial state

    func test_initialState_isIdleBeforeSequence() {
        let store = freeStore()
        XCTAssertEqual(store.beatPhase, .idle)
        XCTAssertFalse(store.showPaywall)
        XCTAssertFalse(store.isFullyUnlocked)
    }

    // MARK: - Beat sequence (free path)

    func test_startBeatSequence_freeCouple_entersBeat1() {
        let store = freeStore()
        store.startBeatSequence()
        XCTAssertEqual(store.beatPhase, .beat1)
    }

    func test_startBeatSequence_isIdempotent() {
        let store = freeStore()
        store.startBeatSequence()
        store.startBeatSequence()        // second call is a no-op (guard on .idle)
        XCTAssertEqual(store.beatPhase, .beat1)
    }

    func test_advanceBeat_walksBeat1ToBeat2_thenRests() {
        let store = freeStore()
        store.startBeatSequence()
        XCTAssertEqual(store.beatPhase, .beat1)

        store.advanceBeat()
        XCTAssertEqual(store.beatPhase, .beat2)
        XCTAssertFalse(store.showPaywall, "the paywall never auto-rises")

        // A second tap-anywhere has nothing further to skip to — the ceremony rests at
        // beat2 until the user taps a locked star (selectStar), never from a generic tap.
        store.advanceBeat()
        XCTAssertEqual(store.beatPhase, .beat2)
        XCTAssertFalse(store.showPaywall)
    }

    func test_selectStar_lockedReopensPaywallAfterClose() throws {
        let store = freeStore()
        let locked = try XCTUnwrap(store.lockedMatches.first)
        store.startBeatSequence()
        store.advanceBeat()          // beat2
        store.selectStar(locked)     // beat3 + paywall, via an explicit locked-star tap
        store.closePaywall()
        XCTAssertFalse(store.showPaywall)

        store.selectStar(locked)     // tapping the locked star again re-raises the paywall
        XCTAssertEqual(store.beatPhase, .beat3)
        XCTAssertTrue(store.showPaywall)
    }

    func test_advanceBeat_fromIdleIsNoOp() {
        let store = freeStore()
        store.advanceBeat()
        XCTAssertEqual(store.beatPhase, .idle)
    }

    // MARK: - Unlock in place

    func test_handleUnlockSuccess_jumpsToRevealedAndClosesPaywall() throws {
        let store = freeStore()
        let locked = try XCTUnwrap(store.lockedMatches.first)
        store.startBeatSequence()
        store.advanceBeat()          // beat2
        store.selectStar(locked)     // beat3 + paywall open, via a locked-star tap
        store.handleUnlockSuccess()
        XCTAssertEqual(store.beatPhase, .revealed)
        XCTAssertFalse(store.showPaywall)
    }

    // MARK: - Already-Core skip

    func test_startBeatSequence_coreCouple_skipsStraightToRevealed() throws {
        let container = ModelContainer.previewContainer
        let context = ModelContext(container)
        let couple = Couple(partnerAId: UUID(), partnerBId: UUID())
        couple.entitlementTier = .core
        context.insert(couple)
        try context.save()

        let appState = AppState()
        appState.coupleId = couple.id
        let entitlements = EntitlementStore(modelContainer: container, appState: appState)
        XCTAssertTrue(entitlements.isCore, "seeded Core couple resolves isCore")

        let store = DesireRevealStore(appState: appState, entitlements: entitlements)
        Self.retain(store, entitlements, appState)
        store.startBeatSequence()
        XCTAssertEqual(store.beatPhase, .revealed, "Core couples skip the conversion beats")
    }

    // MARK: - Derived views

    func test_derivedMatchPartitions() {
        let store = freeStore()
        XCTAssertEqual(store.totalCount, 3)
        XCTAssertEqual(store.unlockedMatches.count, 1)
        XCTAssertEqual(store.lockedMatches.count, 2)
        XCTAssertEqual(store.lockedCount, 2)
    }

    // MARK: - Star tap routing

    func test_selectStar_lockedOpensPaywall() throws {
        let store = freeStore()
        let locked = try XCTUnwrap(store.lockedMatches.first)
        store.selectStar(locked)
        XCTAssertTrue(store.showPaywall)
        XCTAssertNil(store.selectedMatch)
    }

    func test_selectStar_unlockedOpensDetail() throws {
        let store = freeStore()
        let unlocked = try XCTUnwrap(store.unlockedMatches.first)
        store.selectStar(unlocked)
        XCTAssertEqual(store.selectedMatch, unlocked)
        XCTAssertFalse(store.showPaywall)
    }

    // MARK: - Sheet plumbing

    func test_openAndDismissSheets() {
        let store = freeStore()
        store.openFullMap()
        XCTAssertTrue(store.showFullMap)

        store.dismissSheets()
        XCTAssertFalse(store.showFullMap)
        XCTAssertNil(store.selectedMatch)
    }

    func test_closePaywallLeavesBeatUntouched() throws {
        let store = freeStore()
        let locked = try XCTUnwrap(store.lockedMatches.first)
        store.startBeatSequence()
        store.advanceBeat()          // beat2
        store.selectStar(locked)     // beat3 + paywall
        store.closePaywall()
        XCTAssertFalse(store.showPaywall)
        XCTAssertEqual(store.beatPhase, .beat3, "closing the paywall does not rewind the ceremony")
    }
}
