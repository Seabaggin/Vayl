//
//  DesireRevealStoreTests.swift
//  VaylTests
//
//  The reveal ceremony's decision logic: the 3-beat state machine, the free/locked derived
//  views, star-tap routing, and the server-truth reshape (review 2026-07-09): locked stubs,
//  the content-drift guard, the empty-reveal self-heal, the three-way EmptyReason split,
//  and beat-timed seen-stamps. Uses the DEBUG previewStore seam for pure state-machine
//  tests and a MockDesireSyncService subclass for load()/stamp paths (no network).
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

    // AppState hydrates coupleId from the app-hosted test runner's REAL UserDefaults, and
    // its setter persists — so any test (here or in another suite) that sets a coupleId
    // leaks it into every later `AppState()`. The unpaired fixtures below depend on a
    // clean slate, so scrub the key before each test.
    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "coupleId")
    }

    // MARK: - Mock service (overrides the network-touching reads; everything else unused)

    @MainActor
    final class MockDesireSyncService: DesireSyncService {
        var rows: [DesireMatchRow] = []
        var status: DesireMapStatusRow?
        var computeCalls = 0
        /// When set, computeMatches() swaps `rows` — simulates the self-heal recomputing.
        var rowsAfterCompute: [DesireMatchRow]?
        /// The `full` flag of each markRevealSeen call, in order.
        var seenStamps: [Bool] = []

        override func fetchMatches(coupleId: UUID) async throws -> [DesireMatchRow] { rows }
        override func fetchStatus(coupleId: UUID) async throws -> DesireMapStatusRow? { status }
        override func computeMatches() async throws -> ComputeMatchesResponse {
            computeCalls += 1
            if let rowsAfterCompute { rows = rowsAfterCompute }
            return ComputeMatchesResponse(status: "computed", track: nil, matchCount: rows.count)
        }
        override func markRevealSeen(coupleId: UUID, full: Bool) async throws {
            seenStamps.append(full)
        }
    }

    // MARK: - Fixtures

    // Free couple with a free + two locked matches (preview seam; unpaired → no network).
    private func freeStore() -> DesireRevealStore {
        let store = DesireRevealStore.previewStore(matches: [
            RevealMatch.sample("Slow mornings", .mutual, locked: false),
            RevealMatch.sample("New cities", .adjacent, locked: true),
            RevealMatch.sample("Big talks", .mutual, locked: true)
        ])
        Self.retain(store)
        return store
    }

    /// A paired store wired to a mock service — exercises the real load()/stamp paths.
    private func pairedStore(_ mock: MockDesireSyncService) -> DesireRevealStore {
        let appState = AppState()
        appState.coupleId = UUID()
        let entitlements = EntitlementStore(modelContainer: .previewContainer, appState: appState)
        let store = DesireRevealStore(appState: appState, entitlements: entitlements, service: mock)
        Self.retain(store, entitlements, appState, mock)
        return store
    }

    /// An UNLOCKED server row for a real corpus item (the content-drift guard requires
    /// the id to exist in desire_items.json, so pull one from the shipped content).
    private func namedRow(free: Bool = false, alignment: String = "mutual") throws -> DesireMatchRow {
        let itemId = try XCTUnwrap(ContentLoader.loadDesireItems().first).id
        return DesireMatchRow(id: UUID(), desireItemId: itemId, alignmentLevel: alignment,
                              isFreeReveal: free, bridgeCardId: nil, category: nil)
    }

    /// A LOCKED STUB as the server now sends it: identity withheld, teaser category only.
    private func stubRow(category: String? = "emotional") -> DesireMatchRow {
        DesireMatchRow(id: UUID(), desireItemId: nil, alignmentLevel: nil,
                       isFreeReveal: false, bridgeCardId: nil, category: category)
    }

    private func waitUntil(_ message: String,
                           timeout: TimeInterval = 3,
                           _ condition: () -> Bool) async {
        let start = Date()
        while !condition() {
            if Date().timeIntervalSince(start) > timeout {
                XCTFail("Timed out waiting: \(message)")
                return
            }
            try? await Task.sleep(for: .milliseconds(10))
        }
    }

    // MARK: - Initial state

    func test_initialState_isIdleBeforeSequence() {
        let store = freeStore()
        XCTAssertEqual(store.beatPhase, .idle)
        XCTAssertFalse(store.showPaywall)
        XCTAssertFalse(store.unlockPending)
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
        // Unpaired preview seam → the DEBUG path flips everything open synchronously
        // (there is no server to confirm against, so unlockPending resolves immediately).
        let store = freeStore()
        let locked = try XCTUnwrap(store.lockedMatches.first)
        store.startBeatSequence()
        store.advanceBeat()          // beat2
        store.selectStar(locked)     // beat3 + paywall open, via a locked-star tap
        store.handleUnlockSuccess()
        XCTAssertEqual(store.beatPhase, .revealed)
        XCTAssertFalse(store.showPaywall)
        XCTAssertFalse(store.unlockPending)
        XCTAssertEqual(store.lockedCount, 0, "every match unlocks")
    }

    // MARK: - Nothing-locked skip (server truth: no locked rows arrived)

    func test_startBeatSequence_allUnlocked_skipsStraightToRevealed() {
        // A Core couple (or a free couple whose only match is the free one) receives
        // zero locked rows — the store never consults entitlements, the rows decide.
        let store = DesireRevealStore.previewStore(matches: [
            RevealMatch.sample("Slow mornings", .mutual, free: true),
            RevealMatch.sample("New cities", .adjacent)
        ])
        Self.retain(store)
        store.startBeatSequence()
        XCTAssertEqual(store.beatPhase, .revealed, "nothing locked → no conversion beats")
    }

    // MARK: - Derived views

    func test_derivedMatchPartitions() {
        let store = freeStore()
        XCTAssertEqual(store.totalCount, 3)
        XCTAssertEqual(store.unlockedMatches.count, 1)
        XCTAssertEqual(store.lockedMatches.count, 2)
        XCTAssertEqual(store.lockedCount, 2)
    }

    // MARK: - Teaser title (locked stubs render category-only copy)

    func test_teaserTitle_withAndWithoutCategory() {
        let categorized = RevealMatch(id: UUID(), itemName: nil, itemCategory: "emotional",
                                      alignment: nil, isLocked: true, bridgeCardId: nil)
        XCTAssertEqual(categorized.teaserTitle, "A shared desire · EMOTIONAL")

        let uncategorized = RevealMatch(id: UUID(), itemName: nil, itemCategory: nil,
                                        alignment: nil, isLocked: true, bridgeCardId: nil)
        XCTAssertEqual(uncategorized.teaserTitle, "A shared desire")
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

    func test_closePaywall_rewindsBeat3ToBeat2() throws {
        // Review punch #13: beat3 MEANS "paywall open", so dismissing the paywall must
        // rewind to beat2 instead of stranding the ceremony in a phase whose sheet is gone.
        let store = freeStore()
        let locked = try XCTUnwrap(store.lockedMatches.first)
        store.startBeatSequence()
        store.advanceBeat()          // beat2
        store.selectStar(locked)     // beat3 + paywall
        store.closePaywall()
        XCTAssertFalse(store.showPaywall)
        XCTAssertEqual(store.beatPhase, .beat2, "dismissed paywall returns the ceremony to its resting beat")
    }

    // MARK: - load(): unpaired / waiting / self-heal / true zero (review §1.4 + §1.1)

    func test_load_unpaired_setsEmptyUnpaired() async {
        let mock = MockDesireSyncService()
        let appState = AppState()   // no coupleId
        let entitlements = EntitlementStore(modelContainer: .previewContainer, appState: appState)
        let store = DesireRevealStore(appState: appState, entitlements: entitlements, service: mock)
        Self.retain(store, entitlements, appState, mock)

        await store.load()
        XCTAssertEqual(store.phase, .empty(.unpaired))
    }

    func test_load_emptyWithoutBothComplete_waitsForPartner() async {
        let mock = MockDesireSyncService()
        mock.status = DesireMapStatusRow(track: nil, partnerAComplete: true, partnerBComplete: false)
        let store = pairedStore(mock)

        await store.load()
        XCTAssertEqual(store.phase, .empty(.waitingForPartner))
        XCTAssertEqual(mock.computeCalls, 0, "no self-heal while a partner is unfinished")
    }

    func test_load_selfHeal_recomputesOnceAndRecovers() async throws {
        let mock = MockDesireSyncService()
        mock.status = DesireMapStatusRow(track: nil, partnerAComplete: true, partnerBComplete: true)
        mock.rowsAfterCompute = [try namedRow(free: true)]
        let store = pairedStore(mock)

        await store.load()
        XCTAssertEqual(mock.computeCalls, 1, "bothComplete + zero rows fires compute exactly once")
        XCTAssertEqual(store.phase, .ready)
        XCTAssertEqual(store.matches.count, 1)
    }

    func test_load_selfHeal_stillEmptyIsTrueZero() async {
        let mock = MockDesireSyncService()
        mock.status = DesireMapStatusRow(track: nil, partnerAComplete: true, partnerBComplete: true)
        let store = pairedStore(mock)

        await store.load()
        XCTAssertEqual(mock.computeCalls, 1)
        XCTAssertEqual(store.phase, .empty(.noMatches))
    }

    // MARK: - load(): row mapping (server truth + content-drift guard)

    func test_load_mapsLockedStub_withoutIdentity() async throws {
        let mock = MockDesireSyncService()
        mock.rows = [try namedRow(free: true), stubRow(category: "emotional")]
        let store = pairedStore(mock)

        await store.load()
        XCTAssertEqual(store.phase, .ready)
        XCTAssertEqual(store.matches.count, 2)

        let stub = try XCTUnwrap(store.matches.first(where: { $0.isLocked }))
        XCTAssertNil(stub.itemName, "a locked stub never carries an identity")
        XCTAssertNil(stub.alignment)
        XCTAssertEqual(stub.teaserTitle, "A shared desire · EMOTIONAL")

        let named = try XCTUnwrap(store.matches.first(where: { !$0.isLocked }))
        XCTAssertNotNil(named.itemName, "the server sent it named → it renders named")
        XCTAssertTrue(named.isFreeReveal)
    }

    func test_load_dropsUnlockedRowWithUnknownItemId() async throws {
        // Content-drift guard (review addendum): never render a raw id slug.
        let mock = MockDesireSyncService()
        let drifted = DesireMatchRow(id: UUID(), desireItemId: "item_that_no_longer_exists",
                                     alignmentLevel: "mutual", isFreeReveal: false,
                                     bridgeCardId: nil, category: nil)
        mock.rows = [try namedRow(free: true), drifted]
        let store = pairedStore(mock)

        await store.load()
        XCTAssertEqual(store.phase, .ready)
        XCTAssertEqual(store.matches.count, 1, "the drifted row is skipped, not renamed")
    }

    // MARK: - Seen-stamps fire at the beats, not at load (review addendum)

    func test_seenStamps_notWrittenByLoad_freeStampedAtBeat2() async throws {
        let mock = MockDesireSyncService()
        mock.rows = [try namedRow(free: true), stubRow()]
        let store = pairedStore(mock)

        await store.load()
        XCTAssertEqual(store.phase, .ready)
        XCTAssertTrue(mock.seenStamps.isEmpty, "load() must not stamp — a back-out during loading would skip the ceremony")

        store.startBeatSequence()    // beat1 (one locked stub)
        store.advanceBeat()          // beat2 = the free reveal was actually seen
        await waitUntil("free stamp written at beat2") { mock.seenStamps == [false] }
    }

    func test_seenStamps_fullStampedWhenNothingLocked() async throws {
        let mock = MockDesireSyncService()
        mock.rows = [try namedRow(free: true)]
        let store = pairedStore(mock)

        await store.load()
        store.startBeatSequence()    // nothing locked → straight to .revealed
        XCTAssertEqual(store.beatPhase, .revealed)
        // Full viewing implies free viewing: both stamps land (two independent Tasks,
        // so assert content, not completion order).
        await waitUntil("free + full stamps written") {
            mock.seenStamps.count == 2 && mock.seenStamps.contains(false) && mock.seenStamps.contains(true)
        }
    }
}
