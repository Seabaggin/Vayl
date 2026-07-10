//
//  CoupleSessionPlaythroughTests.swift
//  VaylTests
//
//  Simulates a couple playing a quickplay card session end to end by driving
//  CoupleSessionStore — the source of truth the thin session views forward taps
//  to. Each test walks the real sequence (airlock → sync → deal the hand →
//  close → reflection) and asserts the persistence a playthrough produces.
//
//  SCOPE — read this: this is a SINGLE-DEVICE playthrough with the partner
//  mocked inside the store (presence + the sync release are simulated). The
//  real two-device / two-account path is Segments 6-9 (Realtime), which is not
//  built yet — so a literal "two accounts on two phones" test is not yet
//  possible. This covers the full game logic + persistence one device drives.
//
//  Side effect: saving a session calls SyncManager.enqueueSyncTask, which writes
//  to the real app container and kicks a background push. It is swallowed
//  (try? + detached Task) and mirrors SessionStore — it does not affect these
//  assertions, which read the in-memory container the store was given.
//

import XCTest
import SwiftData
import Supabase
@testable import Vayl

@MainActor
final class CoupleSessionPlaythroughTests: XCTestCase {

    // MARK: - Setup helpers

    /// A fresh in-memory container + an AppState with a couple, plus a store over
    /// the first `cardCount` opener cards. A no-op sync hook is injected by default
    /// so the offline queue (on-disk app container + network) never runs in tests.
    private func makeStore(
        cardCount: Int,
        enqueueSync: @escaping @MainActor (SessionRecordPayload) -> Void = { _ in }
    ) -> (CoupleSessionStore, ModelContainer) {
        let container = ModelContainer.previewContainer
        let appState = AppState()
        appState.coupleId = UUID()
        let hand = Array(Card.openerSamples.prefix(cardCount))
        let store = CoupleSessionStore(
            hand: hand,
            modelContainer: container,
            appState: appState,
            presenceSeconds: 0.01,        // resolve the airlock without a real-time wait
            transitionSeconds: 0.01,
            enqueueSync: enqueueSync
        )
        return (store, container)
    }

    /// Polls `condition` on the main actor until true or the timeout elapses.
    private func waitUntil(_ message: String,
                           timeout: TimeInterval = 6,
                           _ condition: () -> Bool) async {
        let start = Date()
        while !condition() {
            if Date().timeIntervalSince(start) > timeout {
                XCTFail("Timed out waiting: \(message)")
                return
            }
            try? await Task.sleep(for: .milliseconds(40))
        }
    }

    /// Drives the airlock the way a couple does: partner arrives (mock), both
    /// lock in, the phones-down transition resolves into card 1.
    private func crossAirlock(_ store: CoupleSessionStore) async {
        XCTAssertEqual(store.phase, .airlock)
        store.armPresence()
        await waitUntil("partner never arrived") { store.partnerPresent }
        store.confirmSynced()
        XCTAssertEqual(store.phase, .transition)
        await waitUntil("transition never resolved to session") { store.phase == .session }
    }

    // MARK: - Context beat gating (banner header vs. interstitial overlay)

    /// opener-01 has no beat, opener-02 is `.interstitial`, opener-05 is
    /// `.banner` (see Card.openerSamples). Banner must NOT arm activeContextBeat
    /// — it renders as a persistent ContextKickerView instead (SessionPlayerView),
    /// not the one-shot pre-card overlay.
    func test_contextBeat_armsForInterstitialOnly_notBanner() async throws {
        let (store, _) = makeStore(cardCount: 5)
        await crossAirlock(store)

        XCTAssertEqual(store.currentCard?.id, "opener-01")
        XCTAssertNil(store.activeContextBeat)

        store.dealNext()   // → opener-02, interstitial
        XCTAssertEqual(store.currentCard?.id, "opener-02")
        XCTAssertEqual(store.activeContextBeat?.type, .interstitial)
        XCTAssertEqual(store.activeContextBeat?.copy, store.currentCard?.contextBeatCopy)

        store.dealNext()   // → opener-03, no beat
        store.dealNext()   // → opener-04, no beat
        store.dealNext()   // → opener-05, banner
        XCTAssertEqual(store.currentCard?.id, "opener-05")
        XCTAssertEqual(store.currentCard?.contextBeatType, .banner)
        XCTAssertNil(store.activeContextBeat)
    }

    // MARK: - Full playthrough (happy path + a pass + a saved reflection)

    func test_fullCouplePlaythrough_persistsSessionAndReflection() async throws {
        var syncedPayloads: [SessionRecordPayload] = []
        let (store, container) = makeStore(cardCount: 4) { syncedPayloads.append($0) }

        await crossAirlock(store)

        // Role A opens (even indices) — the DEBUG launch is role .a, so index 0
        // is this device's draw, and the drawer alternates from there.
        XCTAssertEqual(store.currentDrawer, .you)
        XCTAssertEqual(store.drawingRoleLabel, "A")
        XCTAssertEqual(store.positionLabel, "1 · 4")

        // Pass the first card, then deal through the rest.
        store.pass()
        XCTAssertEqual(store.index, 1)
        XCTAssertEqual(store.currentDrawer, .partner)
        XCTAssertEqual(store.drawingRoleLabel, "B")

        while store.phase == .session {
            store.dealNext()
        }

        // The last deal finishes the session and lands on the close.
        XCTAssertEqual(store.phase, .close)
        let sessionId = try XCTUnwrap(store.savedSessionId)

        // The CardSession + per-card results persisted to the store's container.
        let ctx = ModelContext(container)
        let sessions = try ctx.fetch(FetchDescriptor<CardSession>())
        XCTAssertEqual(sessions.count, 1)
        let session = try XCTUnwrap(sessions.first)
        XCTAssertEqual(session.id, sessionId)
        XCTAssertEqual(session.cardsAttempted, 4)
        XCTAssertEqual(session.cardsSkipped, 1)            // the pass
        XCTAssertEqual(session.cardsDiscussed, 3)
        XCTAssertEqual(session.cardResults.count, 4)

        let progress = try ctx.fetch(FetchDescriptor<DeckProgress>())
        XCTAssertEqual(progress.count, 1)
        XCTAssertNotNil(progress.first?.completedAt)
        XCTAssertEqual(progress.first?.currentCardIndex, 0)   // completion resets the resume point
        XCTAssertNotNil(progress.first?.firstOpenedAt)
        XCTAssertNotNil(progress.first?.lastPlayedAt)

        // The completed session is handed to the sync queue exactly once. On this
        // pure-local (DEBUG) launch remoteSessionId is nil, so the payload falls
        // back to the local session id — the two-device case (payload keyed by
        // the shared remote id instead) is covered by
        // test_twoDeviceLaunch_syncPayloadKeyedByRemoteSessionId below.
        XCTAssertEqual(syncedPayloads.count, 1)
        XCTAssertEqual(syncedPayloads.first?.cardsDiscussed, 3)
        XCTAssertEqual(syncedPayloads.first?.id, sessionId)

        // The couple writes a private reflection at the close.
        store.reflectionWords = ["close", "honest"]
        store.carriedBalance = 0.6
        store.feltHeard = 0.85
        store.reflectionNote = "  stayed with it  "
        store.saveReflection()
        XCTAssertEqual(store.phase, .done)

        let reflections = try ctx.fetch(FetchDescriptor<SessionReflection>())
        XCTAssertEqual(reflections.count, 1)
        let reflection = try XCTUnwrap(reflections.first)
        XCTAssertEqual(reflection.cardSessionId, sessionId)
        XCTAssertEqual(Set(reflection.words), ["close", "honest"])
        XCTAssertEqual(reflection.note, "stayed with it")   // trimmed on save
    }

    // MARK: - Two-device: sync payload keyed by the shared remote session id

    /// A fake RealtimeSessionService: never actually reached (armPresence /
    /// confirmSynced are the DEBUG-airlock helpers and don't touch `realtime`),
    /// it only exists so the store's two-device init path has something to hold.
    private func fakeRealtimeService() -> RealtimeSessionService {
        let url = URL(string: "https://example.invalid")!
        return RealtimeSessionService(supabase: SupabaseClient(supabaseURL: url, supabaseKey: "test-key"))
    }

    /// Fix A regression coverage: a two-device launch (session != nil) must key
    /// the sync payload by the SHARED remote session id, not the local per-device
    /// UUID — otherwise each device uploads its own row and a two-device session
    /// produces two remote records instead of one upserted row.
    func test_twoDeviceLaunch_syncPayloadKeyedByRemoteSessionId() async throws {
        let remoteId = UUID()
        let hand = Array(Card.openerSamples.prefix(3))
        let dto = CuratedSessionDTO(
            id: remoteId,
            coupleId: UUID(),
            initiatorId: UUID(),
            deckId: hand.first?.deckId ?? "unknown",
            deckVariant: nil,
            cardIds: hand.map(\.id),
            perCardTimer: [:],
            globalTimerSeconds: nil,
            status: CuratedSessionStatus.active.rawValue,
            currentIndex: 0,
            aPresent: true,
            bPresent: true,
            aBandwidth: nil,
            bBandwidth: nil,
            aConsented: true,
            bConsented: true,
            timerStartedAt: nil,
            revealState: [:],
            createdAt: ISO8601DateFormatter().string(from: Date()),
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        let launch = SessionLaunch(hand: hand, entry: .initiator, role: .a, session: dto)

        let container = ModelContainer.previewContainer
        let appState = AppState()
        appState.coupleId = dto.coupleId
        var syncedPayloads: [SessionRecordPayload] = []
        let store = CoupleSessionStore(
            launch: launch,
            modelContainer: container,
            appState: appState,
            realtime: fakeRealtimeService(),
            presenceSeconds: 0.01,
            transitionSeconds: 0.01,
            enqueueSync: { syncedPayloads.append($0) }
        )

        XCTAssertEqual(store.remoteSessionId, remoteId)

        await crossAirlock(store)
        while store.phase == .session { store.dealNext() }
        XCTAssertEqual(store.phase, .close)

        let savedId = try XCTUnwrap(store.savedSessionId)
        XCTAssertNotEqual(savedId, remoteId, "local SwiftData id should stay the per-device UUID")

        XCTAssertEqual(syncedPayloads.count, 1)
        XCTAssertEqual(syncedPayloads.first?.id, remoteId, "sync payload must be keyed by the shared remote session id")
    }

    // MARK: - Whole-session budget: threshold, still-here, never re-fires

    /// The budget check fires once elapsed crosses the planned budget, and
    /// "We're still here" clears it for the rest of the session (spec §1.7).
    func test_sessionBudget_firesAtThreshold_stillHereClearsForGood() async throws {
        let remoteId = UUID()
        let hand = Array(Card.openerSamples.prefix(3))
        let dto = CuratedSessionDTO(
            id: remoteId,
            coupleId: UUID(),
            initiatorId: UUID(),
            deckId: hand.first?.deckId ?? "unknown",
            deckVariant: nil,
            cardIds: hand.map(\.id),
            perCardTimer: [:],
            globalTimerSeconds: 120,          // a 2-minute planned budget
            status: CuratedSessionStatus.active.rawValue,
            currentIndex: 0,
            aPresent: true,
            bPresent: true,
            aBandwidth: nil,
            bBandwidth: nil,
            aConsented: true,
            bConsented: true,
            timerStartedAt: nil,
            revealState: [:],
            createdAt: ISO8601DateFormatter().string(from: Date()),
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        let launch = SessionLaunch(hand: hand, entry: .initiator, role: .a, session: dto)
        let appState = AppState()
        appState.coupleId = dto.coupleId
        let store = CoupleSessionStore(
            launch: launch,
            modelContainer: ModelContainer.previewContainer,
            appState: appState,
            realtime: fakeRealtimeService(),
            presenceSeconds: 0.01,
            transitionSeconds: 0.01,
            enqueueSync: { _ in }
        )
        await crossAirlock(store)
        XCTAssertEqual(store.budgetMinutes, 2)

        // Under budget: silent.
        store.evaluateSessionBudget(now: Date().addingTimeInterval(60))
        XCTAssertFalse(store.budgetCheckPresented)

        // A paused room is never interrupted, even past budget.
        store.togglePause()
        store.evaluateSessionBudget(now: Date().addingTimeInterval(121))
        XCTAssertFalse(store.budgetCheckPresented, "the check never fires over a paused room")
        store.togglePause()

        // Past budget: the soft check fires.
        store.evaluateSessionBudget(now: Date().addingTimeInterval(121))
        XCTAssertTrue(store.budgetCheckPresented)

        // "We're still here" clears the budget and it never asks again.
        store.budgetStillHere()
        XCTAssertFalse(store.budgetCheckPresented)
        store.evaluateSessionBudget(now: Date().addingTimeInterval(600))
        XCTAssertFalse(store.budgetCheckPresented, "a cleared budget never re-fires")
    }

    // MARK: - Close-screen stats derive from the SHARED row (created_at + confirmed index)

    /// Two-device close stats must agree across devices: minutes come from the
    /// row's created_at (not this device's store-construction time), and the
    /// "cards deep" count floors at the row's confirmed index so a relaunched
    /// device with empty local records never shows 0.
    func test_closeStats_deriveFromSharedRow() async throws {
        let remoteId = UUID()
        let hand = Array(Card.openerSamples.prefix(5))
        let createdAt = Self.rowTimestamp(secondsAgo: 200)   // > 3 minutes ago
        let coupleId = UUID()
        func row(currentIndex: Int) -> CuratedSessionDTO {
            CuratedSessionDTO(
                id: remoteId,
                coupleId: coupleId,
                initiatorId: UUID(),
                deckId: hand.first?.deckId ?? "unknown",
                deckVariant: nil,
                cardIds: hand.map(\.id),
                perCardTimer: [:],
                globalTimerSeconds: nil,
                status: CuratedSessionStatus.active.rawValue,
                currentIndex: currentIndex,
                aPresent: true,
                bPresent: true,
                aBandwidth: nil,
                bBandwidth: nil,
                aConsented: true,
                bConsented: true,
                timerStartedAt: nil,
                revealState: [:],
                createdAt: createdAt,
                updatedAt: createdAt
            )
        }
        let dto = row(currentIndex: 0)
        let launch = SessionLaunch(hand: hand, entry: .joiner, role: .b, session: dto)
        let appState = AppState()
        appState.coupleId = dto.coupleId
        let store = CoupleSessionStore(
            launch: launch,
            modelContainer: ModelContainer.previewContainer,
            appState: appState,
            realtime: fakeRealtimeService(),
            presenceSeconds: 0.01,
            transitionSeconds: 0.01,
            enqueueSync: { _ in }
        )

        // (a) Minutes derive from the row's created_at, not the local Date()
        // captured at store construction (which would read "1 min" here).
        XCTAssertTrue(store.sessionStatLine.hasSuffix("3 min"),
                      "expected minutes from row created_at, got \(store.sessionStatLine)")

        // (b) Cards deep floors at the shared confirmed index when local
        // records are empty (the relaunched-joiner case).
        XCTAssertEqual(store.closeCardsDeep, 0)
        store.applyRemoteRow(row(currentIndex: 3))
        XCTAssertTrue(store.records.isEmpty, "this device recorded nothing locally")
        XCTAssertEqual(store.discussedCount, 0)
        XCTAssertEqual(store.closeCardsDeep, 3, "close count must floor at the row's confirmed index")
        XCTAssertTrue(store.sessionStatLine.hasPrefix("3 cards"),
                      "the stat line must agree with the close headline, got \(store.sessionStatLine)")
    }

    private static func rowTimestamp(secondsAgo: TimeInterval) -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.string(from: Date().addingTimeInterval(-secondsAgo))
    }

    // MARK: - Branch: skip the reflection

    func test_skipReflection_sessionSavedButNoReflection() async throws {
        let (store, container) = makeStore(cardCount: 3)
        await crossAirlock(store)

        while store.phase == .session { store.dealNext() }
        XCTAssertEqual(store.phase, .close)

        store.skipReflection()
        XCTAssertEqual(store.phase, .done)

        let ctx = ModelContext(container)
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<CardSession>()).count, 1)
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<SessionReflection>()).count, 0)
    }

    // MARK: - Branch: end well mid-session

    func test_endEarlyMidSession_savesCleanClose() async throws {
        let (store, container) = makeStore(cardCount: 6)
        await crossAirlock(store)

        // Deal two cards, then "end well" from the re-center sheet.
        store.dealNext()
        store.dealNext()
        XCTAssertEqual(store.index, 2)
        store.endEarly()

        XCTAssertEqual(store.phase, .close)
        let ctx = ModelContext(container)
        let session = try XCTUnwrap(try ctx.fetch(FetchDescriptor<CardSession>()).first)
        // 2 dealt (discussed) + the current card ended (skipped) = 3 attempted.
        XCTAssertEqual(session.cardsAttempted, 3)
        XCTAssertEqual(session.cardsDiscussed, 2)
        XCTAssertEqual(session.cardsSkipped, 1)

        // Ending early is a clean close, NOT a completion: the deck stays
        // resumable at where the couple left off (2026-07-07 review, B5).
        let progress = try XCTUnwrap(try ctx.fetch(FetchDescriptor<DeckProgress>()).first)
        XCTAssertNil(progress.completedAt)
        XCTAssertEqual(progress.currentCardIndex, 3)
        XCTAssertNotNil(progress.lastPlayedAt)
    }
}
