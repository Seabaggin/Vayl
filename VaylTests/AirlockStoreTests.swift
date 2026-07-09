//
//  AirlockStoreTests.swift
//  VaylTests
//
//  AirlockStore state machine against MockAirlockTransport — presence orders,
//  the poll fallback paths, the idempotent active flip, and role derivation
//  from the LOCAL profile id (never the auth id). No network, no channel.
//
//  Style note: whole-suite @MainActor + a polling waitUntil, matching
//  CoupleSessionPlaythroughTests. Timeouts are injected tiny so the poll and
//  presence-timeout paths resolve in milliseconds.
//

import XCTest
import SwiftData
@testable import Vayl

// MARK: - Mock transport

@MainActor
final class MockAirlockTransport: AirlockTransport {

    var openRow: CuratedSessionDTO?
    var connectError: Error?
    var flipResult = true
    private(set) var flipCount = 0
    private(set) var presenceWrites: [(role: SessionRole, present: Bool)] = []
    private(set) var consentWrites: [SessionRole] = []
    private(set) var heartbeatCount = 0
    /// Rows the poll loop hands back, consumed front-first; last repeats.
    var heartbeatRows: [CuratedSessionDTO] = []
    /// When true, heartbeatOpenSession returns nil regardless of heartbeatRows
    /// — simulates the row having fallen out of openStatuses (dead session).
    var heartbeatReturnsNil = false
    /// What fetchSession(id:) returns — the poll path's "is it really dead"
    /// check when heartbeatOpenSession comes back nil.
    var fetchSessionResult: CuratedSessionDTO?
    private(set) var fetchSessionCount = 0

    private(set) var presenceContinuation: AsyncStream<PresenceDelta>.Continuation?
    private(set) var rowsContinuation: AsyncStream<CuratedSessionDTO>.Continuation?

    struct MockError: Error {}

    func fetchOpenSession(coupleId: UUID) async throws -> CuratedSessionDTO? { openRow }

    var consentError: Error?

    func setConsent(sessionId: UUID, role: SessionRole, consented: Bool) async throws {
        if let consentError { throw consentError }
        consentWrites.append(role)
    }

    func setPresence(sessionId: UUID, role: SessionRole, present: Bool) async throws {
        presenceWrites.append((role, present))
    }

    func flipToActiveIfBoth(sessionId: UUID) async throws -> Bool {
        flipCount += 1
        return flipResult
    }

    func heartbeatOpenSession(coupleId: UUID, role: SessionRole) async throws -> CuratedSessionDTO? {
        heartbeatCount += 1
        if heartbeatReturnsNil { return nil }
        guard !heartbeatRows.isEmpty else { return openRow }
        return heartbeatRows.count > 1 ? heartbeatRows.removeFirst() : heartbeatRows[0]
    }

    func fetchSession(id: UUID) async throws -> CuratedSessionDTO? {
        fetchSessionCount += 1
        return fetchSessionResult
    }

    func connect(coupleId: UUID, profileId: UUID, sessionId: UUID) async throws -> AirlockStreams {
        if let connectError { throw connectError }
        let (presence, presenceCont) = AsyncStream<PresenceDelta>.makeStream()
        let (rows, rowsCont) = AsyncStream<CuratedSessionDTO>.makeStream()
        presenceContinuation = presenceCont
        rowsContinuation = rowsCont
        return AirlockStreams(presence: presence, rows: rows)
    }

    func disconnect() async {
        presenceContinuation?.finish()
        rowsContinuation?.finish()
    }
}

// MARK: - Row fixtures

private func makeRow(
    id: UUID = UUID(),
    coupleId: UUID,
    status: CuratedSessionStatus = .airlock,
    aPresent: Bool = false, bPresent: Bool = false,
    aBandwidth: Float? = nil, bBandwidth: Float? = nil,
    aConsented: Bool = false, bConsented: Bool = false
) -> CuratedSessionDTO {
    CuratedSessionDTO(
        id: id,
        coupleId: coupleId,
        initiatorId: UUID(),
        deckId: "the-opener",
        deckVariant: nil,
        cardIds: [],
        perCardTimer: [:],
        globalTimerSeconds: nil,
        status: status.rawValue,
        currentIndex: 0,
        aPresent: aPresent,
        bPresent: bPresent,
        aBandwidth: aBandwidth,
        bBandwidth: bBandwidth,
        aConsented: aConsented,
        bConsented: bConsented,
        timerStartedAt: nil,
        revealState: [:],
        createdAt: "2026-07-01T00:00:00Z",
        updatedAt: "2026-07-01T00:00:00Z"
    )
}

// MARK: - Tests

@MainActor
final class AirlockStoreTests: XCTestCase {

    // Isolated-deinit crash workaround (the DM-suite gotcha): app-hosted tests
    // abort with a libmalloc double-free in swift_task_deinitOnExecutorImpl
    // when an @Observable @MainActor object deallocates mid-suite. Retain every
    // store (and its @MainActor mock) for the life of the test process.
    private static var retained: [AnyObject] = []
    private static func retain(_ objects: AnyObject...) { retained.append(contentsOf: objects) }

    private func waitUntil(_ message: String,
                           timeout: TimeInterval = 4,
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

    private func makeStore(
        mock: MockAirlockTransport,
        coupleId: UUID,
        role: SessionRole = .a,
        presenceTimeout: TimeInterval = 60   // effectively off unless a test wants it
    ) -> AirlockStore {
        let store = AirlockStore(
            coupleId: coupleId,
            myProfileId: UUID(),
            role: role,
            transport: mock,
            presenceTimeout: presenceTimeout,
            pollInterval: 0.02
        )
        Self.retain(store, mock)
        return store
    }

    // MARK: Ladder

    func testHappyPathLadderReachesActive() async {
        let coupleId = UUID()
        let sessionId = UUID()
        let mock = MockAirlockTransport()
        mock.openRow = makeRow(id: sessionId, coupleId: coupleId)
        let store = makeStore(mock: mock, coupleId: coupleId, role: .a)

        await store.start()
        XCTAssertEqual(store.state, .waitingForPartner)
        XCTAssertEqual(store.transport, .realtime)
        // Presence heartbeat boolean written on connect.
        XCTAssertTrue(mock.presenceWrites.contains { $0.role == .a && $0.present })

        // Partner joins.
        mock.presenceContinuation?.yield(PresenceDelta(joinedIds: [UUID().uuidString], leftIds: []))
        await waitUntil("both present") { store.state == .bothPresent }

        // I lock in.
        let consented = await store.consent()
        XCTAssertTrue(consented)
        XCTAssertEqual(store.state, .consented)
        XCTAssertEqual(mock.consentWrites, [.a])

        // Partner's consent arrives on the row → activating → flip requested.
        mock.rowsContinuation?.yield(makeRow(
            id: sessionId, coupleId: coupleId,
            aPresent: true, bPresent: true,
            aConsented: true, bConsented: true
        ))
        await waitUntil("flip requested") { mock.flipCount == 1 }

        // The row flips (server-authoritative) → both devices go active on the UPDATE.
        mock.rowsContinuation?.yield(makeRow(
            id: sessionId, coupleId: coupleId, status: .active,
            aPresent: true, bPresent: true,
            aConsented: true, bConsented: true
        ))
        await waitUntil("active") { store.state == .active(sessionId: sessionId) }
    }

    func testActiveFlipIsIdempotent() async {
        let coupleId = UUID()
        let sessionId = UUID()
        let mock = MockAirlockTransport()
        mock.openRow = makeRow(id: sessionId, coupleId: coupleId)
        let store = makeStore(mock: mock, coupleId: coupleId, role: .a)

        await store.start()
        mock.presenceContinuation?.yield(PresenceDelta(joinedIds: [UUID().uuidString], leftIds: []))
        await store.consent()

        let bothConsented = makeRow(
            id: sessionId, coupleId: coupleId,
            aPresent: true, bPresent: true,
            aConsented: true, bConsented: true
        )
        // The same both-consented row lands three times (dupe UPDATEs happen).
        mock.rowsContinuation?.yield(bothConsented)
        mock.rowsContinuation?.yield(bothConsented)
        mock.rowsContinuation?.yield(bothConsented)

        await waitUntil("flip requested once") { mock.flipCount >= 1 }
        try? await Task.sleep(for: .milliseconds(100))
        XCTAssertEqual(mock.flipCount, 1, "didRequestFlip must gate re-issues locally")
    }

    func testPartnerLeavingRegressesLadder() async {
        let coupleId = UUID()
        let mock = MockAirlockTransport()
        mock.openRow = makeRow(coupleId: coupleId)
        let store = makeStore(mock: mock, coupleId: coupleId)

        await store.start()
        let partnerKey = UUID().uuidString
        mock.presenceContinuation?.yield(PresenceDelta(joinedIds: [partnerKey], leftIds: []))
        await waitUntil("both present") { store.state == .bothPresent }

        mock.presenceContinuation?.yield(PresenceDelta(joinedIds: [], leftIds: [partnerKey]))
        await waitUntil("back to waiting") { store.state == .waitingForPartner }
    }

    // MARK: Poll fallback

    func testConnectFailureFallsBackToPollAndReachesActive() async {
        let coupleId = UUID()
        let sessionId = UUID()
        let mock = MockAirlockTransport()
        mock.openRow = makeRow(id: sessionId, coupleId: coupleId)
        mock.connectError = MockAirlockTransport.MockError()
        // Poll ticks: partner present+consented, then (after our consent) active.
        mock.heartbeatRows = [
            makeRow(id: sessionId, coupleId: coupleId,
                    aPresent: true, bPresent: true, bConsented: true)
        ]
        let store = makeStore(mock: mock, coupleId: coupleId, role: .a)

        await store.start()
        XCTAssertEqual(store.transport, .poll)

        await waitUntil("poll sees partner") { store.partnerPresent }
        await store.consent()
        // In poll mode the flip winner advances locally.
        await waitUntil("active via poll") {
            if case .active = store.state { return true } else { return false }
        }
        XCTAssertEqual(mock.flipCount, 1)
        XCTAssertGreaterThanOrEqual(mock.heartbeatCount, 1)
    }

    func testPollModeClearsPartnerPresenceFromRow() async {
        // Regression (2026-07-07 review): row presence was a one-way latch, so
        // a partner leaving pre-active in poll mode never dropped the ladder.
        let coupleId = UUID()
        let sessionId = UUID()
        let mock = MockAirlockTransport()
        mock.openRow = makeRow(id: sessionId, coupleId: coupleId)
        mock.connectError = MockAirlockTransport.MockError()
        mock.heartbeatRows = [
            makeRow(id: sessionId, coupleId: coupleId, aPresent: true, bPresent: true),
            makeRow(id: sessionId, coupleId: coupleId, aPresent: true, bPresent: false)
        ]
        let store = makeStore(mock: mock, coupleId: coupleId, role: .a)

        await store.start()
        XCTAssertEqual(store.transport, .poll)
        await waitUntil("poll sees partner") { store.partnerPresent }
        await waitUntil("poll sees partner leave") { !store.partnerPresent }
        XCTAssertEqual(store.state, .waitingForPartner)
    }

    // MARK: Ended (Fix A — a dead session announces itself)

    func testAbandonedRowEndsSessionAndStaysSticky() async {
        let coupleId = UUID()
        let sessionId = UUID()
        let mock = MockAirlockTransport()
        mock.openRow = makeRow(id: sessionId, coupleId: coupleId)
        let store = makeStore(mock: mock, coupleId: coupleId)

        await store.start()
        XCTAssertEqual(store.state, .waitingForPartner)

        mock.rowsContinuation?.yield(makeRow(id: sessionId, coupleId: coupleId, status: .abandoned))
        await waitUntil("ended") { store.state == .ended }

        // A later presence join must not regress the sticky ended state.
        mock.presenceContinuation?.yield(PresenceDelta(joinedIds: [UUID().uuidString], leftIds: []))
        try? await Task.sleep(for: .milliseconds(50))
        XCTAssertEqual(store.state, .ended, "ended must be sticky like activating/active/failed")
    }

    func testPollDetectsDeadSessionViaFetchSessionAndStops() async {
        let coupleId = UUID()
        let sessionId = UUID()
        let mock = MockAirlockTransport()
        mock.openRow = makeRow(id: sessionId, coupleId: coupleId)
        mock.connectError = MockAirlockTransport.MockError()
        // Once in poll mode, the row has fallen out of openStatuses.
        mock.heartbeatReturnsNil = true
        mock.fetchSessionResult = makeRow(id: sessionId, coupleId: coupleId, status: .abandoned)
        let store = makeStore(mock: mock, coupleId: coupleId)

        await store.start()
        XCTAssertEqual(store.transport, .poll)
        await waitUntil("poll notices the dead session") { store.state == .ended }
        XCTAssertGreaterThanOrEqual(mock.fetchSessionCount, 1)

        // The loop must actually stop — no further heartbeats after ended.
        let countAtEnded = mock.heartbeatCount
        try? await Task.sleep(for: .milliseconds(60))
        XCTAssertEqual(mock.heartbeatCount, countAtEnded, "poll loop must break once ended")
    }

    func testPollTreatsMissingRowAsEnded() async {
        let coupleId = UUID()
        let sessionId = UUID()
        let mock = MockAirlockTransport()
        mock.openRow = makeRow(id: sessionId, coupleId: coupleId)
        mock.connectError = MockAirlockTransport.MockError()
        mock.heartbeatReturnsNil = true
        mock.fetchSessionResult = nil   // row genuinely gone
        let store = makeStore(mock: mock, coupleId: coupleId)

        await store.start()
        await waitUntil("missing row reads as ended") { store.state == .ended }
    }

    func testConsentFailureReportsAndDoesNotAdvance() async {
        // Regression (2026-07-07 review): a failed consent write left the view
        // latched "locked in" forever. The store must report the failure.
        let coupleId = UUID()
        let mock = MockAirlockTransport()
        mock.openRow = makeRow(coupleId: coupleId)
        mock.consentError = MockAirlockTransport.MockError()
        let store = makeStore(mock: mock, coupleId: coupleId, role: .a)

        await store.start()
        mock.presenceContinuation?.yield(PresenceDelta(joinedIds: [UUID().uuidString], leftIds: []))
        await waitUntil("both present") { store.state == .bothPresent }

        let consented = await store.consent()
        XCTAssertFalse(consented)
        XCTAssertFalse(store.selfConsented)
        XCTAssertEqual(store.state, .bothPresent, "a failed consent must not climb the ladder")
    }

    func testPresenceSilenceTimeoutDropsToPoll() async {
        let coupleId = UUID()
        let mock = MockAirlockTransport()
        mock.openRow = makeRow(coupleId: coupleId)
        // Connect succeeds but the streams stay silent.
        let store = makeStore(mock: mock, coupleId: coupleId, presenceTimeout: 0.05)

        await store.start()
        XCTAssertEqual(store.transport, .realtime)
        await waitUntil("timeout drops to poll") { store.transport == .poll }
    }

    func testNoOpenRowFails() async {
        let mock = MockAirlockTransport()
        mock.openRow = nil
        let store = makeStore(mock: mock, coupleId: UUID())

        await store.start()
        XCTAssertEqual(store.state, .failed(reason: "No open session for this couple."))
    }

    // MARK: Role derivation (profile id, never auth id)

    func testMakeDerivesRoleFromLocalCouple() throws {
        let container = ModelContainer.previewContainer
        let context = ModelContext(container)

        let profile = UserProfile(displayName: "Jordan")
        context.insert(profile)
        let coupleAsA = Couple(partnerAId: profile.id, partnerBId: UUID())
        context.insert(coupleAsA)
        try context.save()

        let mockA = MockAirlockTransport()
        let storeA = AirlockStore.make(
            coupleId: coupleAsA.id, modelContainer: container,
            transport: mockA
        )
        XCTAssertEqual(storeA?.role, .a)
        XCTAssertEqual(storeA?.myProfileId, profile.id)

        let coupleAsB = Couple(partnerAId: UUID(), partnerBId: profile.id)
        context.insert(coupleAsB)
        try context.save()

        let mockB = MockAirlockTransport()
        let storeB = AirlockStore.make(
            coupleId: coupleAsB.id, modelContainer: container,
            transport: mockB
        )
        XCTAssertEqual(storeB?.role, .b)

        // Retain both stores + mocks so the isolated deinit never runs mid-suite.
        if let storeA { Self.retain(storeA) }
        if let storeB { Self.retain(storeB) }
        Self.retain(mockA, mockB)
    }
}
