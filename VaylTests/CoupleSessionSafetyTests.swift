//
//  CoupleSessionSafetyTests.swift
//  VaylTests
//
//  CoupleSessionStore's safety controls (pause, per-card "keep going" timer
//  reset) via the same in-memory ModelContainer + injected no-op sync hook
//  pattern as CoupleSessionPlaythroughTests. New file (not appended to the
//  playthrough suite) per the audit's file-organization guidance.
//
//  SCOPE — what's NOT covered here, and why:
//  `partnerLost()` / `partnerReturned()` (the ~15s presence-grace path) are
//  `private`, reachable only through `SessionSyncCoordinator`'s presence
//  callback, which requires a live `RealtimeSessionService` — a concrete
//  final class with no protocol seam. Driving that path would mean either
//  faking a concrete Supabase-backed service (out of scope for an additive
//  test seam) or restructuring CoupleSessionStore's remote-sync wiring, which
//  this file explicitly avoids (a scene-phase reconnect method also landed
//  on that store in the same pass — not tested here either, same reason).
//  Flagged, not faked.
//  Likewise, `refreshTimer()`'s countdown-from-anchor behavior only engages
//  once `timerStartedAtRaw` is set by `applyRemoteRow` (also private, also
//  remote-only) — so the local/pure-debug path this suite drives never has a
//  running timer to expire. What IS synchronously reachable and covered:
//  `togglePause()`'s local state round-trip, and `keepGoing()` /
//  `refreshTimer()`'s no-timer-armed idempotence (no crash, correct nil/false
//  resting state) on the pure-local path.
//

import XCTest
import SwiftData
@testable import Vayl

@MainActor
final class CoupleSessionSafetyTests: XCTestCase {

    // Isolated-deinit workaround (same gotcha as the DM/Airlock suites): retain
    // every @Observable @MainActor store for the process lifetime.
    private static var retained: [AnyObject] = []
    private static func retain(_ objects: AnyObject...) { retained.append(contentsOf: objects) }

    /// Same in-memory setup as CoupleSessionPlaythroughTests: a fresh
    /// container + AppState + a local (non-remote) store over a small hand,
    /// with tiny airlock/transition beats and a no-op sync hook.
    private func makeStore(
        cardCount: Int = 3
    ) -> CoupleSessionStore {
        let container = ModelContainer.previewContainer
        let appState = AppState()
        appState.coupleId = UUID()
        let hand = Array(Card.openerSamples.prefix(cardCount))
        let store = CoupleSessionStore(
            hand: hand,
            modelContainer: container,
            appState: appState,
            presenceSeconds: 0.01,
            transitionSeconds: 0.01,
            enqueueSync: { _ in }
        )
        Self.retain(store, appState)
        return store
    }

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

    private func crossAirlock(_ store: CoupleSessionStore) async {
        store.armPresence()
        await waitUntil("partner never arrived") { store.partnerPresent }
        store.confirmSynced()
        await waitUntil("transition never resolved to session") { store.phase == .session }
    }

    // MARK: togglePause()

    func test_togglePause_flipsIsPaused_onLocalPath() async {
        let store = makeStore()
        await crossAirlock(store)

        XCTAssertFalse(store.isPaused)
        store.togglePause()
        XCTAssertTrue(store.isPaused)
    }

    func test_togglePause_roundTrips_backToUnpaused() async {
        let store = makeStore()
        await crossAirlock(store)

        store.togglePause()
        XCTAssertTrue(store.isPaused)
        store.togglePause()
        XCTAssertFalse(store.isPaused, "a second toggle must resume, not stay latched paused")
    }

    func test_togglePause_isSafeWithNoRemoteSync() async {
        // `realtime`/`remoteSessionId` are nil on the local/DEBUG path — the
        // guard inside togglePause() must skip the server write without
        // throwing or blocking the local flip.
        let store = makeStore()
        await crossAirlock(store)

        for _ in 0..<4 { store.togglePause() }
        XCTAssertFalse(store.isPaused, "four toggles nets back to unpaused")
    }

    // MARK: keepGoing() / refreshTimer() — no-timer-armed resting state

    func test_refreshTimer_withNoRemoteAnchor_leavesTimerAtRest() async {
        // Pure-local sessions never receive a `timerStartedAt` anchor (that
        // only arrives via the private applyRemoteRow), so refreshTimer()
        // must resolve to the "no timer" resting state rather than crash or
        // spin up a countdown against a missing anchor.
        let store = makeStore()
        await crossAirlock(store)

        store.refreshTimer()
        XCTAssertNil(store.timerRemaining)
        XCTAssertFalse(store.timerElapsed)
    }

    func test_keepGoing_isIdempotent_whenNoTimerIsRunning() async {
        let store = makeStore()
        await crossAirlock(store)

        store.keepGoing()
        XCTAssertNil(store.timerRemaining)
        XCTAssertFalse(store.timerElapsed)

        // Calling it again (e.g. a double-tap) must not crash or change state.
        store.keepGoing()
        XCTAssertNil(store.timerRemaining)
        XCTAssertFalse(store.timerElapsed)
    }

    func test_keepGoing_onASingleCardHand_staysAtRest() async {
        // Minimal hand: keepGoing()'s guards (no timer armed, no remote row)
        // must resolve to the resting state without touching anything else.
        let store = makeStore(cardCount: 1)
        await crossAirlock(store)
        XCTAssertNotNil(store.currentCard)

        store.keepGoing()
        XCTAssertFalse(store.timerElapsed)
        XCTAssertNil(store.timerRemaining)
        XCTAssertEqual(store.phase, .session, "keepGoing never advances or ends the session")
    }

    // MARK: Partner liveness heartbeat — freshness computation
    // registerPartnerHeartbeat / evaluatePartnerHeartbeat are the pure core of
    // the fast-disconnect path (last_seen columns). The wire loops themselves
    // need a live RealtimeSessionService (same seam limitation as partnerLost,
    // documented in the header), so these tests drive the computation directly.

    private static let iso: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    func test_heartbeat_neverSeen_staysFresh_fallsBackToPresence() async {
        // Before the first partner heartbeat ever arrives, last_seen is null
        // — the pill must trust presence alone, never read null as "gone".
        let store = makeStore()
        XCTAssertNil(store.partnerLastSeenAt)
        store.evaluatePartnerHeartbeat(now: Date())
        XCTAssertTrue(store.partnerHeartbeatFresh)
    }

    func test_heartbeat_fresh_readsConnected() async {
        let store = makeStore()
        let now = Date()
        store.registerPartnerHeartbeat(raw: Self.iso.string(from: now))
        store.evaluatePartnerHeartbeat(now: now.addingTimeInterval(5))
        XCTAssertTrue(store.partnerHeartbeatFresh, "5s-old heartbeat is inside the 10s window")
    }

    func test_heartbeat_stale_flipsNotConnected() async {
        let store = makeStore()
        let now = Date()
        store.registerPartnerHeartbeat(raw: Self.iso.string(from: now))
        store.evaluatePartnerHeartbeat(
            now: now.addingTimeInterval(CoupleSessionStore.heartbeatFreshWindow + 1)
        )
        XCTAssertFalse(store.partnerHeartbeatFresh, "a heartbeat past the window means the partner is gone")
    }

    func test_heartbeat_freshAfterStale_recovers() async {
        let store = makeStore()
        let now = Date()
        store.registerPartnerHeartbeat(raw: Self.iso.string(from: now))
        store.evaluatePartnerHeartbeat(now: now.addingTimeInterval(20))
        XCTAssertFalse(store.partnerHeartbeatFresh)

        // Partner comes back: a newer stamp flips the pill back.
        store.registerPartnerHeartbeat(raw: Self.iso.string(from: now.addingTimeInterval(19)))
        store.evaluatePartnerHeartbeat(now: now.addingTimeInterval(20))
        XCTAssertTrue(store.partnerHeartbeatFresh)
    }

    func test_heartbeat_laggingRead_neverRegresses() async {
        let store = makeStore()
        let now = Date()
        store.registerPartnerHeartbeat(raw: Self.iso.string(from: now))
        // A stale poll result arriving late must not roll the stamp backwards.
        store.registerPartnerHeartbeat(raw: Self.iso.string(from: now.addingTimeInterval(-30)))
        XCTAssertEqual(store.partnerLastSeenAt.map { Self.iso.string(from: $0) }, Self.iso.string(from: now))
    }

    func test_heartbeat_unparseableOrNil_isIgnored() async {
        let store = makeStore()
        store.registerPartnerHeartbeat(raw: nil)
        store.registerPartnerHeartbeat(raw: "not-a-timestamp")
        XCTAssertNil(store.partnerLastSeenAt)
        store.evaluatePartnerHeartbeat(now: Date())
        XCTAssertTrue(store.partnerHeartbeatFresh)
    }

    func test_heartbeat_doesNotAffectLocalDebugPill() async {
        // The pure-local path (isLive == false) keeps its mock presence pill;
        // a stale heartbeat must not bleed into it.
        let store = makeStore()
        await crossAirlock(store)
        let now = Date()
        store.registerPartnerHeartbeat(raw: Self.iso.string(from: now))
        store.evaluatePartnerHeartbeat(now: now.addingTimeInterval(60))
        XCTAssertFalse(store.partnerHeartbeatFresh)
        XCTAssertTrue(store.partnerConnected, "local DEBUG pill reads the mock partnerPresent, not the heartbeat")
    }
}
