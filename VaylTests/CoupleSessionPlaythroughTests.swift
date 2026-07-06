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

    /// Drives the airlock the way a couple does: partner arrives (mock), each sets
    /// bandwidth, both sync, the phones-down transition resolves into card 1.
    private func crossAirlock(_ store: CoupleSessionStore,
                              bandwidth: CoupleSessionStore.Bandwidth) async {
        XCTAssertEqual(store.phase, .airlock)
        store.armPresence()
        store.setBandwidth(bandwidth)
        await waitUntil("partner never arrived") { store.partnerPresent }
        store.confirmSynced()
        XCTAssertEqual(store.phase, .transition)
        await waitUntil("transition never resolved to session") { store.phase == .session }
    }

    // MARK: - Full playthrough (happy path + a pass + a saved reflection)

    func test_fullCouplePlaythrough_persistsSessionAndReflection() async throws {
        var syncedPayloads: [SessionRecordPayload] = []
        let (store, container) = makeStore(cardCount: 4) { syncedPayloads.append($0) }

        await crossAirlock(store, bandwidth: .deep)

        // The partner opens; the drawer alternates from index 0.
        XCTAssertEqual(store.currentDrawer, .partner)
        XCTAssertEqual(store.positionLabel, "1 · 4")

        // Pass the first card, then deal through the rest.
        store.pass()
        XCTAssertEqual(store.index, 1)
        XCTAssertEqual(store.currentDrawer, .you)

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
        XCTAssertEqual(session.lockInBandwidthB ?? -1,
                       CoupleSessionStore.Bandwidth.deep.fraction, accuracy: 0.001)

        let progress = try ctx.fetch(FetchDescriptor<DeckProgress>())
        XCTAssertEqual(progress.count, 1)
        XCTAssertNotNil(progress.first?.completedAt)

        // The completed session is handed to the sync queue exactly once, with the
        // right tally (the real hook would push it to Supabase).
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

    // MARK: - Branch: skip the reflection

    func test_skipReflection_sessionSavedButNoReflection() async throws {
        let (store, container) = makeStore(cardCount: 3)
        await crossAirlock(store, bandwidth: .open)

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
        await crossAirlock(store, bandwidth: .light)

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
    }
}
