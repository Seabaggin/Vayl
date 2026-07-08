//
//  SessionEntryStoreTests.swift
//  VaylTests
//
//  SessionEntryStore against a fake SessionEntryRealtime seam (added alongside
//  this suite — see SessionEntryStore.swift's "Realtime seam" section, same
//  pattern as AirlockTransport/LiveAirlockTransport). `catalog` (DeckCatalogService)
//  is left real — it's a pure bundled-JSON loader, no network, no fake needed
//  (same choice PathContentServiceTests makes for PathContentService).
//
//  Covers the entry/launch decision logic: which open rows become a joinable
//  banner (lobby/airlock, someone else's, not dismissed, not stale), and
//  accept() building the correct joiner SessionLaunch. Follows
//  AirlockStoreTests' pattern for the isolated-deinit retain workaround.
//

import XCTest
import SwiftData
@testable import Vayl

// MARK: - Fake

@MainActor
private final class FakeSessionEntryRealtime: SessionEntryRealtime {
    var openRow: CuratedSessionDTO?
    var fetchError: Error?
    private(set) var fetchCount = 0

    func fetchOpenSession(coupleId: UUID) async throws -> CuratedSessionDTO? {
        fetchCount += 1
        if let fetchError { throw fetchError }
        return openRow
    }
}

// MARK: - Row fixture (mirrors AirlockStoreTests' makeRow)

private func makeRow(
    id: UUID = UUID(),
    coupleId: UUID,
    initiatorId: UUID,
    deckId: String = "the-opener",
    status: CuratedSessionStatus = .lobby,
    cardIds: [String] = ["opener-01", "opener-02"],
    createdAt: Date = Date()
) -> CuratedSessionDTO {
    let iso = ISO8601DateFormatter()
    return CuratedSessionDTO(
        id: id,
        coupleId: coupleId,
        initiatorId: initiatorId,
        deckId: deckId,
        deckVariant: nil,
        cardIds: cardIds,
        perCardTimer: [:],
        globalTimerSeconds: nil,
        status: status.rawValue,
        currentIndex: 0,
        aPresent: false,
        bPresent: false,
        aBandwidth: nil,
        bBandwidth: nil,
        aConsented: false,
        bConsented: false,
        timerStartedAt: nil,
        revealState: [:],
        createdAt: iso.string(from: createdAt),
        updatedAt: iso.string(from: createdAt)
    )
}

// MARK: - Tests

@MainActor
final class SessionEntryStoreTests: XCTestCase {

    private static var retained: [AnyObject] = []
    private static func retain(_ objects: AnyObject...) { retained.append(contentsOf: objects) }

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.dismissedPendingSessionId)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.dismissedPendingSessionId)
        super.tearDown()
    }

    private func waitUntil(
        _ message: String,
        timeout: TimeInterval = 3,
        _ condition: () -> Bool
    ) async {
        let start = Date()
        while !condition() {
            if Date().timeIntervalSince(start) > timeout {
                XCTFail("Timed out waiting: \(message)")
                return
            }
            try? await Task.sleep(for: .milliseconds(10))
        }
    }

    /// A fresh in-memory container with a local profile A paired to a random
    /// partner B, plus an AppState pointed at that couple.
    private func makeContext() -> (container: ModelContainer, appState: AppState, myProfileId: UUID, coupleId: UUID) {
        let container = ModelContainer.previewContainer
        let context = ModelContext(container)
        let profile = UserProfile(displayName: "Me")
        context.insert(profile)
        let couple = Couple(partnerAId: profile.id, partnerBId: UUID())
        context.insert(couple)
        try? context.save()

        let appState = AppState()
        appState.coupleId = couple.id
        return (container, appState, profile.id, couple.id)
    }

    private func makeStore(
        container: ModelContainer,
        appState: AppState,
        realtime: FakeSessionEntryRealtime
    ) -> SessionEntryStore {
        let store = SessionEntryStore(
            modelContainer: container,
            appState: appState,
            realtime: realtime,
            partnerName: { "Partner" }
        )
        Self.retain(store, realtime, appState)
        return store
    }

    // MARK: refresh() — no couple

    func test_refresh_withNoCoupleId_clearsPendingSessionSynchronously() {
        let container = ModelContainer.previewContainer
        let appState = AppState()
        appState.coupleId = nil
        let store = makeStore(container: container, appState: appState, realtime: FakeSessionEntryRealtime())

        store.refresh()
        XCTAssertNil(store.pendingSession)
    }

    // MARK: refresh() — joinable pending banner

    func test_refresh_setsPendingSession_forPartnerInitiatedLobbyRow() async {
        let (container, appState, _, coupleId) = makeContext()
        let realtime = FakeSessionEntryRealtime()
        realtime.openRow = makeRow(coupleId: coupleId, initiatorId: UUID(), status: .lobby)
        let store = makeStore(container: container, appState: appState, realtime: realtime)

        store.refresh()
        await waitUntil("pendingSession never set") { store.pendingSession != nil }

        XCTAssertEqual(store.pendingSession?.initiatorName, "Partner")
        XCTAssertEqual(store.pendingSession?.deckTitle, "The Opener")
    }

    func test_refresh_ignoresRowIInitiatedMyself() async {
        let (container, appState, myProfileId, coupleId) = makeContext()
        let realtime = FakeSessionEntryRealtime()
        realtime.openRow = makeRow(coupleId: coupleId, initiatorId: myProfileId, status: .lobby)
        let store = makeStore(container: container, appState: appState, realtime: realtime)

        store.refresh()
        await waitUntil("fetch never completed") { realtime.fetchCount > 0 }
        try? await Task.sleep(for: .milliseconds(30))

        XCTAssertNil(store.pendingSession, "a self-initiated row is never a banner — I already know about it")
    }

    func test_refresh_ignoresActiveRows_reconnectIsTheCoversJob() async {
        let (container, appState, _, coupleId) = makeContext()
        let realtime = FakeSessionEntryRealtime()
        realtime.openRow = makeRow(coupleId: coupleId, initiatorId: UUID(), status: .active)
        let store = makeStore(container: container, appState: appState, realtime: realtime)

        store.refresh()
        await waitUntil("fetch never completed") { realtime.fetchCount > 0 }
        try? await Task.sleep(for: .milliseconds(30))

        XCTAssertNil(store.pendingSession, "active/paused rows are CoupleSessionStore.resumeIfNeeded's job, not a banner")
    }

    func test_refresh_ignoresStaleRows_olderThanMaxAge() async {
        let (container, appState, _, coupleId) = makeContext()
        let realtime = FakeSessionEntryRealtime()
        let old = Date().addingTimeInterval(-13 * 3600)   // > 12h pendingMaxAgeHours
        realtime.openRow = makeRow(coupleId: coupleId, initiatorId: UUID(), status: .lobby, createdAt: old)
        let store = makeStore(container: container, appState: appState, realtime: realtime)

        store.refresh()
        await waitUntil("fetch never completed") { realtime.fetchCount > 0 }
        try? await Task.sleep(for: .milliseconds(30))

        XCTAssertNil(store.pendingSession, "a walked-away-from lobby past the max age is not an invitation")
    }

    // MARK: dismissBanner()

    func test_dismissBanner_preventsTheSameRowFromResurfacing() async {
        let (container, appState, _, coupleId) = makeContext()
        let realtime = FakeSessionEntryRealtime()
        let row = makeRow(coupleId: coupleId, initiatorId: UUID(), status: .lobby)
        realtime.openRow = row
        let store = makeStore(container: container, appState: appState, realtime: realtime)

        store.refresh()
        await waitUntil("pendingSession never set") { store.pendingSession != nil }

        store.dismissBanner()
        XCTAssertNil(store.pendingSession)

        store.refresh()
        try? await Task.sleep(for: .milliseconds(60))
        XCTAssertNil(store.pendingSession, "dismissing must persist across a subsequent refresh of the SAME row")
    }

    // MARK: accept()

    func test_accept_buildsJoinerLaunch_withMatchingHandAndRole() async {
        let (container, appState, _, coupleId) = makeContext()
        let realtime = FakeSessionEntryRealtime()
        realtime.openRow = makeRow(
            coupleId: coupleId, initiatorId: UUID(), status: .lobby,
            cardIds: ["opener-01", "opener-03", "opener-05"]
        )
        let store = makeStore(container: container, appState: appState, realtime: realtime)

        store.refresh()
        await waitUntil("pendingSession never set") { store.pendingSession != nil }

        store.accept()
        await waitUntil("acceptedLaunch never set") { store.acceptedLaunch != nil }

        let launch = store.acceptedLaunch!
        XCTAssertEqual(launch.entry, .joiner)
        XCTAssertEqual(launch.role, .a, "the local profile is partnerA in makeContext()")
        XCTAssertEqual(launch.hand.map(\.id), ["opener-01", "opener-03", "opener-05"])
        XCTAssertNil(store.pendingSession, "accept() clears the banner once the launch is built")
    }

    func test_accept_withNoPendingSession_isANoOp() {
        let container = ModelContainer.previewContainer
        let appState = AppState()
        appState.coupleId = UUID()
        let store = makeStore(container: container, appState: appState, realtime: FakeSessionEntryRealtime())

        store.accept()
        XCTAssertNil(store.acceptedLaunch)
    }
}
