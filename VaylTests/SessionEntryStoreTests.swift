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
    private(set) var setStatusCalls: [(id: UUID, status: CuratedSessionStatus)] = []

    func fetchOpenSession(coupleId: UUID) async throws -> CuratedSessionDTO? {
        fetchCount += 1
        if let fetchError { throw fetchError }
        return openRow
    }

    func setStatus(sessionId: UUID, status: CuratedSessionStatus) async throws {
        setStatusCalls.append((sessionId, status))
        if openRow?.id == sessionId { openRow = nil }
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
    currentIndex: Int = 0,
    createdAt: Date = Date(),
    updatedAt: Date? = nil
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
        currentIndex: currentIndex,
        aPresent: false,
        bPresent: false,
        aBandwidth: nil,
        bBandwidth: nil,
        aConsented: false,
        bConsented: false,
        timerStartedAt: nil,
        revealState: [:],
        createdAt: iso.string(from: createdAt),
        updatedAt: iso.string(from: updatedAt ?? createdAt)
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

    // MARK: refresh() — resumable (active/paused) rows

    func test_refresh_activeRow_isResumable_evenForTheInitiator() async {
        let (container, appState, myProfileId, coupleId) = makeContext()
        let realtime = FakeSessionEntryRealtime()
        realtime.openRow = makeRow(
            coupleId: coupleId, initiatorId: myProfileId, status: .active,
            cardIds: ["opener-01", "opener-02", "opener-03"], currentIndex: 1
        )
        let store = makeStore(container: container, appState: appState, realtime: realtime)

        store.refresh()
        await waitUntil("pendingSession never set") { store.pendingSession != nil }

        XCTAssertEqual(store.pendingSession?.kind, .resume, "an active row is resumable regardless of who initiated it")
        XCTAssertEqual(store.pendingSession?.cardPosition, 2)
        XCTAssertEqual(store.pendingSession?.cardCount, 3)
    }

    func test_refresh_pausedRow_isResumable() async {
        let (container, appState, _, coupleId) = makeContext()
        let realtime = FakeSessionEntryRealtime()
        realtime.openRow = makeRow(coupleId: coupleId, initiatorId: UUID(), status: .paused)
        let store = makeStore(container: container, appState: appState, realtime: realtime)

        store.refresh()
        await waitUntil("pendingSession never set") { store.pendingSession != nil }

        XCTAssertEqual(store.pendingSession?.kind, .resume)
    }

    func test_refresh_staleActiveRow_isAutoAbandoned_andNotSurfaced() async {
        let (container, appState, _, coupleId) = makeContext()
        let realtime = FakeSessionEntryRealtime()
        let old = Date().addingTimeInterval(-13 * 3600)   // > 12h pendingMaxAgeHours
        let row = makeRow(coupleId: coupleId, initiatorId: UUID(), status: .active, updatedAt: old)
        realtime.openRow = row
        let store = makeStore(container: container, appState: appState, realtime: realtime)

        store.refresh()
        await waitUntil("fetch never completed") { realtime.fetchCount > 0 }
        await waitUntil("setStatus never called", timeout: 2) { !realtime.setStatusCalls.isEmpty }

        XCTAssertNil(store.pendingSession, "a stale open row is auto-abandoned, never surfaced")
        XCTAssertEqual(realtime.setStatusCalls.first?.id, row.id)
        XCTAssertEqual(realtime.setStatusCalls.first?.status, .abandoned)
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

    func test_accept_revalidatesAgainstServer_rowGone_setsJoinError_clearsPending_noLaunch() async {
        let (container, appState, _, coupleId) = makeContext()
        let realtime = FakeSessionEntryRealtime()
        realtime.openRow = makeRow(coupleId: coupleId, initiatorId: UUID(), status: .lobby)
        let store = makeStore(container: container, appState: appState, realtime: realtime)

        store.refresh()
        await waitUntil("pendingSession never set") { store.pendingSession != nil }

        // The initiator ended the lobby after this device rendered its cached invite.
        realtime.openRow = nil

        store.accept()
        await waitUntil("joinError never set") { store.joinError != nil }

        XCTAssertNil(store.acceptedLaunch, "a vanished row must never produce a launch")
        XCTAssertNil(store.pendingSession, "the dead banner is cleared")
        XCTAssertEqual(store.joinError, SessionEntryStore.joinErrorMessage)
    }

    func test_accept_withMissingCardId_setsJoinError_clearsPending_noLaunch() async {
        let (container, appState, _, coupleId) = makeContext()
        let realtime = FakeSessionEntryRealtime()
        realtime.openRow = makeRow(
            coupleId: coupleId, initiatorId: UUID(), status: .lobby,
            cardIds: ["opener-01", "does-not-exist", "opener-03"]
        )
        let store = makeStore(container: container, appState: appState, realtime: realtime)

        store.refresh()
        await waitUntil("pendingSession never set") { store.pendingSession != nil }

        store.accept()
        await waitUntil("joinError never set") { store.joinError != nil }

        XCTAssertNil(store.acceptedLaunch, "a missing card id must never shorten the hand into a launch")
        XCTAssertNil(store.pendingSession, "the dead banner must be cleared, not left to fail identically again")
        XCTAssertEqual(store.joinError, "Couldn't open that session. Make sure you're both on the latest version, then try again.")
    }

    func test_accept_withNoPendingSession_isANoOp() {
        let container = ModelContainer.previewContainer
        let appState = AppState()
        appState.coupleId = UUID()
        let store = makeStore(container: container, appState: appState, realtime: FakeSessionEntryRealtime())

        store.accept()
        XCTAssertNil(store.acceptedLaunch)
    }

    // MARK: resume()

    func test_resume_buildsLaunch_fromAnActiveRow() async {
        let (container, appState, myProfileId, coupleId) = makeContext()
        let realtime = FakeSessionEntryRealtime()
        realtime.openRow = makeRow(
            coupleId: coupleId, initiatorId: myProfileId, status: .active,
            cardIds: ["opener-01", "opener-02"]
        )
        let store = makeStore(container: container, appState: appState, realtime: realtime)

        store.refresh()
        await waitUntil("pendingSession never set") { store.pendingSession?.kind == .resume }

        store.resume()
        await waitUntil("acceptedLaunch never set") { store.acceptedLaunch != nil }

        let launch = store.acceptedLaunch!
        XCTAssertEqual(launch.entry, .initiator, "I initiated this row myself")
        XCTAssertEqual(launch.role, .a)
        XCTAssertEqual(launch.hand.map(\.id), ["opener-01", "opener-02"])
        XCTAssertNil(store.pendingSession)
    }

    func test_resume_revalidatesAgainstServer_rowGoneClearsPending_noLaunch() async {
        let (container, appState, _, coupleId) = makeContext()
        let realtime = FakeSessionEntryRealtime()
        realtime.openRow = makeRow(coupleId: coupleId, initiatorId: UUID(), status: .paused)
        let store = makeStore(container: container, appState: appState, realtime: realtime)

        store.refresh()
        await waitUntil("pendingSession never set") { store.pendingSession?.kind == .resume }

        // The row vanished server-side between refresh and the resume tap
        // (e.g. the other partner ended it from their device).
        realtime.openRow = nil

        store.resume()
        await waitUntil("fetch never re-ran") { realtime.fetchCount > 1 }
        try? await Task.sleep(for: .milliseconds(30))

        XCTAssertNil(store.acceptedLaunch, "a vanished row must never produce a launch")
        XCTAssertNil(store.pendingSession, "the dead banner is cleared")
    }

    func test_resume_withMissingCardId_setsJoinError_clearsPending_noLaunch() async {
        let (container, appState, myProfileId, coupleId) = makeContext()
        let realtime = FakeSessionEntryRealtime()
        realtime.openRow = makeRow(
            coupleId: coupleId, initiatorId: myProfileId, status: .active,
            cardIds: ["opener-01", "does-not-exist"]
        )
        let store = makeStore(container: container, appState: appState, realtime: realtime)

        store.refresh()
        await waitUntil("pendingSession never set") { store.pendingSession?.kind == .resume }

        store.resume()
        await waitUntil("joinError never set") { store.joinError != nil }

        XCTAssertNil(store.acceptedLaunch, "a missing card id must never shorten the hand into a launch")
        XCTAssertNil(store.pendingSession)
    }

    // MARK: endResumable()

    func test_endResumable_setsAbandoned_andClearsPending() async {
        let (container, appState, _, coupleId) = makeContext()
        let realtime = FakeSessionEntryRealtime()
        let row = makeRow(coupleId: coupleId, initiatorId: UUID(), status: .active)
        realtime.openRow = row
        let store = makeStore(container: container, appState: appState, realtime: realtime)

        store.refresh()
        await waitUntil("pendingSession never set") { store.pendingSession?.kind == .resume }

        store.endResumable()
        XCTAssertNil(store.pendingSession)

        await waitUntil("setStatus never called") { !realtime.setStatusCalls.isEmpty }
        XCTAssertEqual(realtime.setStatusCalls.first?.id, row.id)
        XCTAssertEqual(realtime.setStatusCalls.first?.status, .abandoned)
    }
}

// MARK: - PlayStoreOpenConflictTests
//
// Colocated here (not a new file) because VaylTests is a manually-wired
// PBXGroup — see this file's header comment. Covers PlayStore's "starting a
// new session while an existing active/paused row is unfinished must never
// dead-end" fix (spec 2026-07-09 §1.1): the conflict is detected instead of
// attempting an insert that would violate the one-open-per-couple index, and
// the three dialog resolutions (resume / start fresh / cancel) each do the
// right thing. Uses a fake PlaySessionOpening — same seam pattern as
// FakeSessionEntryRealtime above.

@MainActor
private final class FakePlaySessionOpening: PlaySessionOpening {
    var openRow: CuratedSessionDTO?
    var openSessionResult: Result<CuratedSessionDTO, Error> = .failure(URLError(.badServerResponse))
    private(set) var openSessionCalls = 0
    private(set) var setStatusCalls: [(id: UUID, status: CuratedSessionStatus)] = []

    func openSession(coupleId: UUID, initiatorId: UUID, draft: CuratedSessionDraft) async throws -> CuratedSessionDTO {
        openSessionCalls += 1
        switch openSessionResult {
        case .success(let dto): return dto
        case .failure(let error): throw error
        }
    }

    func fetchOpenSession(coupleId: UUID) async throws -> CuratedSessionDTO? {
        openRow
    }

    func setStatus(sessionId: UUID, status: CuratedSessionStatus) async throws {
        setStatusCalls.append((sessionId, status))
        if openRow?.id == sessionId {
            if status == .abandoned { openRow = nil }
        }
    }
}

@MainActor
final class PlayStoreOpenConflictTests: XCTestCase {

    private static var retained: [AnyObject] = []
    private static func retain(_ objects: AnyObject...) { retained.append(contentsOf: objects) }

    /// A fresh in-memory container with a local profile A paired to a random
    /// partner B, plus an AppState pointed at that couple (same fixture shape
    /// as SessionEntryStoreTests.makeContext()).
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
        realtime: FakePlaySessionOpening
    ) -> PlayStore {
        let entitlements = EntitlementStore(modelContainer: container, appState: appState)
        let store = PlayStore(
            modelContainer: container,
            appState: appState,
            entitlements: entitlements,
            coupleContext: CoupleContext(appState: appState, entitlements: entitlements, modelContainer: container),
            realtime: realtime
        )
        Self.retain(store, realtime, appState, entitlements)
        return store
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

    /// A minimal SessionPlan built from the-opener's real cards — mirrors how
    /// SessionBuilderView would hand PlayStore a plan.
    private func makePlan(deck: Deck) -> SessionPlan {
        SessionPlan(
            deckId: deck.id,
            cardIds: Array(deck.orderedCards.prefix(2).map(\.id)),
            perCardTimerSeconds: nil,
            globalTimerSeconds: nil,
            deckVariant: nil
        )
    }

    private func loadOpenerDeck() -> Deck {
        try! DeckCatalogService().loadDeck(id: "the-opener")
    }

    // MARK: open() detects the conflict, never attempts the insert

    func test_openSession_withActiveRowPresent_setsConflict_noInsertAttempted_noOpenError() async {
        let (container, appState, _, coupleId) = makeContext()
        let realtime = FakePlaySessionOpening()
        let conflictRow = makeRow(coupleId: coupleId, initiatorId: UUID(), status: .active)
        realtime.openRow = conflictRow
        let store = makeStore(container: container, appState: appState, realtime: realtime)
        let deck = loadOpenerDeck()

        store.builderDeck = deck   // builderDidFinish guards on the builder being open
        store.builderDidFinish(makePlan(deck: deck))

        await waitUntil("conflictSession never set") { store.conflictSession != nil }

        XCTAssertEqual(store.conflictSession?.id, conflictRow.id)
        XCTAssertEqual(realtime.openSessionCalls, 0, "an active/paused row must block the insert entirely")
        XCTAssertNil(store.openError)
        XCTAssertNil(store.launch)
    }

    func test_openSession_withPausedRowPresent_setsConflict() async {
        let (container, appState, _, coupleId) = makeContext()
        let realtime = FakePlaySessionOpening()
        realtime.openRow = makeRow(coupleId: coupleId, initiatorId: UUID(), status: .paused)
        let store = makeStore(container: container, appState: appState, realtime: realtime)
        let deck = loadOpenerDeck()

        store.builderDeck = deck   // builderDidFinish guards on the builder being open
        store.builderDidFinish(makePlan(deck: deck))

        await waitUntil("conflictSession never set") { store.conflictSession != nil }
        XCTAssertEqual(realtime.openSessionCalls, 0)
    }

    // MARK: startFreshFromConflict()

    func test_startFreshFromConflict_abandonsConflictRow_thenOpensWithRetainedPlan() async {
        let (container, appState, myId, coupleId) = makeContext()
        let realtime = FakePlaySessionOpening()
        let conflictRow = makeRow(coupleId: coupleId, initiatorId: UUID(), status: .active)
        realtime.openRow = conflictRow
        let store = makeStore(container: container, appState: appState, realtime: realtime)
        let deck = loadOpenerDeck()
        let plan = makePlan(deck: deck)

        store.builderDeck = deck   // builderDidFinish guards on the builder being open
        store.builderDidFinish(plan)
        await waitUntil("conflictSession never set") { store.conflictSession != nil }

        // Once the conflict row is abandoned, the retry insert should succeed.
        let freshRow = makeRow(coupleId: coupleId, initiatorId: myId, status: .lobby,
                                cardIds: plan.cardIds)
        realtime.openSessionResult = .success(freshRow)

        store.startFreshFromConflict()

        await waitUntil("launch never set") { store.launch != nil }

        XCTAssertEqual(realtime.setStatusCalls.first?.id, conflictRow.id)
        XCTAssertEqual(realtime.setStatusCalls.first?.status, .abandoned,
                       "the blocking row must be abandoned before retrying the open")
        XCTAssertEqual(realtime.openSessionCalls, 1)
        XCTAssertNil(store.conflictSession)
        XCTAssertEqual(store.launch?.hand.map(\.id), plan.cardIds)
    }

    // MARK: resumeConflict()

    func test_resumeConflict_rowStillActive_buildsLaunchFromConflictRow() async {
        let (container, appState, _, coupleId) = makeContext()
        let realtime = FakePlaySessionOpening()
        // Partner-initiated active row, mid-way through a different hand than
        // the plan the user just built — Resume must launch THIS row's hand.
        let conflictRow = makeRow(
            coupleId: coupleId, initiatorId: UUID(), status: .active,
            cardIds: ["opener-03", "opener-01"], currentIndex: 1
        )
        realtime.openRow = conflictRow
        let store = makeStore(container: container, appState: appState, realtime: realtime)
        let deck = loadOpenerDeck()

        store.builderDeck = deck   // builderDidFinish guards on the builder being open
        store.builderDidFinish(makePlan(deck: deck))
        await waitUntil("conflictSession never set") { store.conflictSession != nil }

        store.resumeConflict()
        await waitUntil("launch never set") { store.launch != nil }

        XCTAssertEqual(store.launch?.session?.id, conflictRow.id)
        XCTAssertEqual(store.launch?.hand.map(\.id), ["opener-03", "opener-01"],
                       "Resume launches the conflict row's hand, not the just-built plan")
        XCTAssertEqual(store.launch?.entry, .joiner, "the other partner initiated this row")
        XCTAssertEqual(store.launch?.role, .a)
        XCTAssertEqual(realtime.openSessionCalls, 0, "resuming never inserts a new row")
        XCTAssertNil(store.conflictSession)
    }

    func test_resumeConflict_revalidation_rowVanished_clearsConflict_thenProceedsWithPendingOpen() async {
        let (container, appState, myId, coupleId) = makeContext()
        let realtime = FakePlaySessionOpening()
        let conflictRow = makeRow(coupleId: coupleId, initiatorId: UUID(), status: .active)
        realtime.openRow = conflictRow
        let store = makeStore(container: container, appState: appState, realtime: realtime)
        let deck = loadOpenerDeck()
        let plan = makePlan(deck: deck)

        store.builderDeck = deck   // builderDidFinish guards on the builder being open
        store.builderDidFinish(plan)
        await waitUntil("conflictSession never set") { store.conflictSession != nil }

        // The row resolved itself between the conflict surfacing and the tap
        // (e.g. the partner ended it from their device).
        realtime.openRow = nil
        let freshRow = makeRow(coupleId: coupleId, initiatorId: myId, status: .lobby,
                                cardIds: plan.cardIds)
        realtime.openSessionResult = .success(freshRow)

        store.resumeConflict()

        await waitUntil("launch never set") { store.launch != nil }

        XCTAssertNil(store.conflictSession, "a vanished row clears the conflict rather than resuming a dead one")
        XCTAssertEqual(realtime.openSessionCalls, 1, "the originally-pending open proceeds once the conflict resolved itself")
        XCTAssertEqual(store.launch?.hand.map(\.id), plan.cardIds)
    }

    func test_resumeConflict_withMissingCardId_setsOpenError_noLaunch() async {
        let (container, appState, _, coupleId) = makeContext()
        let realtime = FakePlaySessionOpening()
        let conflictRow = makeRow(
            coupleId: coupleId, initiatorId: UUID(), status: .active,
            cardIds: ["opener-01", "does-not-exist"]
        )
        realtime.openRow = conflictRow
        let store = makeStore(container: container, appState: appState, realtime: realtime)
        let deck = loadOpenerDeck()

        store.builderDeck = deck   // builderDidFinish guards on the builder being open
        store.builderDidFinish(makePlan(deck: deck))
        await waitUntil("conflictSession never set") { store.conflictSession != nil }

        store.resumeConflict()
        await waitUntil("openError never set") { store.openError != nil }

        XCTAssertNil(store.launch, "a missing card id must never shorten the hand into a launch")
        XCTAssertNil(store.conflictSession)
        XCTAssertEqual(realtime.openSessionCalls, 0, "resuming never inserts a new row")
    }
}
