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
    /// Scripts the PARTNER's sync-round signals into the store.
    private(set) var syncContinuation: AsyncStream<SyncSignal>.Continuation?
    /// Everything THIS device broadcast for the sync round.
    private(set) var syncSends: [SyncSignal] = []
    var syncSendError: Error?

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
        let (sync, syncCont) = AsyncStream<SyncSignal>.makeStream()
        presenceContinuation = presenceCont
        rowsContinuation = rowsCont
        syncContinuation = syncCont
        return AirlockStreams(presence: presence, rows: rows, sync: sync)
    }

    func sendSyncSignal(_ signal: SyncSignal) async throws {
        if let syncSendError { throw syncSendError }
        syncSends.append(signal)
    }

    func disconnect() async {
        presenceContinuation?.finish()
        rowsContinuation?.finish()
        syncContinuation?.finish()
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

    func testRestartWithTerminalRowEndsInsteadOfFailing() async {
        // Scene-phase restart: the first run knew a session id; while we were
        // backgrounded the row went terminal, so fetchOpenSession now reads
        // nil. That is "the session ended", not a failed-lobby.
        let coupleId = UUID()
        let sessionId = UUID()
        let mock = MockAirlockTransport()
        mock.openRow = makeRow(id: sessionId, coupleId: coupleId)
        let store = makeStore(mock: mock, coupleId: coupleId)

        await store.start()
        XCTAssertEqual(store.state, .waitingForPartner)

        // The row goes terminal while backgrounded.
        mock.openRow = nil
        mock.fetchSessionResult = makeRow(id: sessionId, coupleId: coupleId, status: .abandoned)

        await store.handleScenePhaseActive()
        XCTAssertEqual(store.state, .ended, "a known session gone terminal must read ended, not failed")
        XCTAssertGreaterThanOrEqual(mock.fetchSessionCount, 1)
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

// MARK: - Sync lock-in round (Segments 3–5, spec 2026-07-08)
// Scripts MockAirlockTransport through full sync rounds: both-arm → go →
// releases → verdict → consent; misses + easing; the round timeout; the
// backstop; partner cancel. Colocated here because VaylTests is a manual
// PBXGroup (new files need pbxproj wiring).

@MainActor
final class AirlockSyncRoundTests: XCTestCase {

    private static var retained: [AnyObject] = []
    private static func retain(_ objects: AnyObject...) { retained.append(contentsOf: objects) }

    /// Fast feel numbers so rounds resolve in milliseconds. Geometry values
    /// (floor/tolerance) stay at .standard — the classifier maths must match prod.
    private func fastConfig(
        backstopAfterMisses: Int = 4,
        countdownStep: Double = 0.01,
        sweep: Double = 0.25,
        timeoutMargin: Double = 0.1
    ) -> SyncConfig {
        var config = SyncConfig.standard
        config.countdownStepSeconds = countdownStep
        config.sweepSeconds = sweep
        config.roundTimeoutMarginSeconds = timeoutMargin
        config.resultHoldSeconds = 60   // keep verdicts assertable, no auto-drain
        config.backstopAfterMisses = backstopAfterMisses
        return config
    }

    private func waitUntil(_ message: String,
                           timeout: TimeInterval = 4,
                           _ condition: () -> Bool) async {
        let start = Date()
        while !condition() {
            if Date().timeIntervalSince(start) > timeout {
                XCTFail("Timed out waiting: \(message)")
                return
            }
            try? await Task.sleep(for: .milliseconds(5))
        }
    }

    /// Store started over a connected mock — sync coordinator exists.
    private func makeStartedStore(
        mock: MockAirlockTransport,
        config: SyncConfig
    ) async -> AirlockStore {
        let coupleId = UUID()
        mock.openRow = makeRow(coupleId: coupleId)
        let store = AirlockStore(
            coupleId: coupleId,
            myProfileId: UUID(),
            role: .a,
            transport: mock,
            presenceTimeout: 60,
            pollInterval: 0.02,
            syncConfig: config
        )
        Self.retain(store, mock)
        await store.start()
        XCTAssertNotNil(store.sync, "coordinator must exist once the transport is connected")
        return store
    }

    /// Drives one round to the sweeping phase: local arm + partner arm → go →
    /// 3-2-1 → sweeping. Role .a leads, so `go` must appear in syncSends.
    private func reachSweep(_ sync: SyncLockInCoordinator, mock: MockAirlockTransport) async {
        sync.arm()
        XCTAssertEqual(sync.phase, .arming)
        await waitUntil("arm broadcast") { mock.syncSends.contains(.arm(.a)) }
        mock.syncContinuation?.yield(.arm(.b))
        await waitUntil("leader broadcasts go") { mock.syncSends.contains(.go(.a)) }
        await waitUntil("sweeping") {
            if case .sweeping = sync.phase { return true } else { return false }
        }
    }

    // (a) Both arm → go → both valid releases within tolerance → inSync → consent.
    func testInSyncRoundWritesConsent() async {
        let mock = MockAirlockTransport()
        let store = await makeStartedStore(mock: mock, config: fastConfig())
        guard let sync = store.sync else { return }

        await reachSweep(sync, mock: mock)
        sync.release(fraction: 0.5)   // 180° — past the 120° floor
        await waitUntil("release broadcast") {
            mock.syncSends.contains { if case .release(role: .a, angle: 180) = $0 { return true } else { return false } }
        }
        mock.syncContinuation?.yield(.release(role: .b, angle: 190))   // gap 10° ≤ 18°

        await waitUntil("in sync") { sync.phase == .result(.inSync) }
        await waitUntil("consent written") { mock.consentWrites == [.a] }
        XCTAssertEqual(sync.misses, 0)
        XCTAssertFalse(sync.backstopAvailable)
        XCTAssertTrue(store.selfConsented)
    }

    // (b) Releases outside tolerance → miss verdict, misses increments, NO consent.
    func testMissOutsideToleranceCountsAndDoesNotConsent() async {
        let mock = MockAirlockTransport()
        let store = await makeStartedStore(mock: mock, config: fastConfig())
        guard let sync = store.sync else { return }

        await reachSweep(sync, mock: mock)
        sync.release(fraction: 130.0 / 360.0)                          // 130°
        mock.syncContinuation?.yield(.release(role: .b, angle: 300))   // gap 170° — far apart

        await waitUntil("miss recorded") { sync.misses == 1 }
        // Case-match, not exact Double equality (the fraction→angle round trip
        // can carry float error).
        guard case .result(.farApart) = sync.phase else {
            return XCTFail("expected a farApart verdict, got \(sync.phase)")
        }
        XCTAssertTrue(mock.consentWrites.isEmpty, "a miss must never write consent")
        XCTAssertFalse(sync.backstopAvailable)
        // Silent easing: the next round's tolerance widens by one step.
        XCTAssertEqual(sync.config.tolerance(afterMisses: sync.misses),
                       sync.config.toleranceDegrees + sync.config.easingStepDegrees)
    }

    // (c) Partner release never arrives → round timeout → gentle reset, miss counted.
    func testPartnerReleaseTimeoutIsInconclusiveMiss() async {
        let mock = MockAirlockTransport()
        let config = fastConfig(sweep: 0.05, timeoutMargin: 0.05)
        let store = await makeStartedStore(mock: mock, config: config)
        guard let sync = store.sync else { return }

        await reachSweep(sync, mock: mock)
        sync.release(fraction: 0.5)
        // Partner's release is lost — the timeout must treat the round as an
        // inconclusive retry with the neutral "once more?" copy.
        await waitUntil("timeout miss") { sync.misses == 1 }
        XCTAssertEqual(sync.phase, .result(.soClose(gapDegrees: 0)))
        XCTAssertTrue(mock.consentWrites.isEmpty)
    }

    // (d) Misses reach the backstop → backstopAvailable.
    func testBackstopAppearsAfterConfiguredMisses() async {
        let mock = MockAirlockTransport()
        let config = fastConfig(backstopAfterMisses: 2, sweep: 0.05, timeoutMargin: 0.05)
        let store = await makeStartedStore(mock: mock, config: config)
        guard let sync = store.sync else { return }

        for round in 1...2 {
            // Timeout misses are the shortest scriptable path to N misses.
            await reachSweep(sync, mock: mock)
            sync.release(fraction: 0.5)
            await waitUntil("miss \(round)") { sync.misses == round }
            // Drain back to idle for the next round (the prod path is the
            // resultHold auto-drain; the partner cancel is equivalent). Wait
            // for the reset to land before arming again.
            if round < 2 {
                mock.syncContinuation?.yield(.cancel(.b))
                await waitUntil("idle before round \(round + 1)") { sync.phase == .idle }
            }
        }
        XCTAssertTrue(sync.backstopAvailable, "backstop must appear after N consecutive misses")
        XCTAssertTrue(mock.consentWrites.isEmpty, "the backstop only ever flags — consent stays a user tap")
    }

    // (e) Partner cancel mid-countdown → both reset to idle.
    func testPartnerCancelDuringCountdownResetsToIdle() async {
        let mock = MockAirlockTransport()
        // Slow countdown so the cancel demonstrably lands mid-3-2-1.
        let config = fastConfig(countdownStep: 0.3)
        let store = await makeStartedStore(mock: mock, config: config)
        guard let sync = store.sync else { return }

        sync.arm()
        mock.syncContinuation?.yield(.arm(.b))
        await waitUntil("countdown running") {
            if case .countdown = sync.phase { return true } else { return false }
        }
        mock.syncContinuation?.yield(.cancel(.b))
        await waitUntil("idle after partner cancel") { sync.phase == .idle }
        XCTAssertEqual(sync.misses, 0, "a cancel is not a miss")
        XCTAssertTrue(mock.consentWrites.isEmpty)
    }

    // Local disarm during arming broadcasts cancel and resets.
    func testLocalDisarmBroadcastsCancel() async {
        let mock = MockAirlockTransport()
        let store = await makeStartedStore(mock: mock, config: fastConfig())
        guard let sync = store.sync else { return }

        sync.arm()
        XCTAssertEqual(sync.phase, .arming)
        sync.disarm()
        XCTAssertEqual(sync.phase, .idle)
        await waitUntil("cancel broadcast") { mock.syncSends.contains(.cancel(.a)) }
    }

    // Own echoes are ignored: our own arm coming back must not read as the partner.
    func testOwnEchoIsIgnored() async {
        let mock = MockAirlockTransport()
        let store = await makeStartedStore(mock: mock, config: fastConfig())
        guard let sync = store.sync else { return }

        sync.arm()
        mock.syncContinuation?.yield(.arm(.a))   // own echo
        try? await Task.sleep(for: .milliseconds(50))
        XCTAssertEqual(sync.phase, .arming, "an own echo must never start the round")
        XCTAssertFalse(mock.syncSends.contains(.go(.a)))
    }

    // Success + consent write failure → round resets so the couple can go again.
    func testConsentFailureAfterSyncResetsRound() async {
        let mock = MockAirlockTransport()
        mock.consentError = MockAirlockTransport.MockError()
        let store = await makeStartedStore(mock: mock, config: fastConfig())
        guard let sync = store.sync else { return }

        await reachSweep(sync, mock: mock)
        sync.release(fraction: 0.5)
        mock.syncContinuation?.yield(.release(role: .b, angle: 185))
        await waitUntil("round resets on failed consent") { sync.phase == .idle }
        XCTAssertFalse(store.selfConsented)
    }

    // Poll fallback: no channel → no coordinator (view falls back to HoldToLockInRing).
    func testPollModeHasNoSyncCoordinator() async {
        let coupleId = UUID()
        let mock = MockAirlockTransport()
        mock.openRow = makeRow(coupleId: coupleId)
        mock.connectError = MockAirlockTransport.MockError()
        let store = AirlockStore(
            coupleId: coupleId, myProfileId: UUID(), role: .a,
            transport: mock, presenceTimeout: 60, pollInterval: 0.02,
            syncConfig: fastConfig()
        )
        Self.retain(store, mock)
        await store.start()
        XCTAssertEqual(store.transport, .poll)
        XCTAssertNil(store.sync, "poll mode has no broadcasts — no sync round")
    }
}
