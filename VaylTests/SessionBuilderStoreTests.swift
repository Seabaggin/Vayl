//
//  SessionBuilderStoreTests.swift
//  VaylTests
//
//  Builder rules: trim floor, closing-ritual protection, same-as-last
//  persistence (isolated UserDefaults suite), remaining-hand seeding.
//  Card fixtures ride on Card.openerSamples (10 real opener cards) plus a
//  synthetic closing ritual — Card is a Codable struct, cheap to construct.
//

import XCTest
@testable import Vayl

@MainActor
final class SessionBuilderStoreTests: XCTestCase {

    // Isolated-deinit crash workaround (the DM-suite gotcha): retain every
    // @Observable @MainActor store for the life of the test process.
    private static var retained: [AnyObject] = []
    private static func retain(_ objects: AnyObject...) { retained.append(contentsOf: objects) }

    private static let suiteName = "SessionBuilderStoreTests"
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: Self.suiteName)
        defaults.removePersistentDomain(forName: Self.suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: Self.suiteName)
        super.tearDown()
    }

    // MARK: - Fixtures

    private func closingRitual(sortOrder: Int) -> Card {
        Card(
            id: "test-closing", deckId: "the-opener",
            text: "Before you put the phones down, each of you name one thing you heard tonight.",
            highlightWords: [], type: .closingRitual, intensity: .deepOcean,
            whoStarts: .both, isSensitive: false, canSkip: false,
            register: .flexible, contextBeatType: nil, contextBeatCopy: nil,
            backCopy: nil, isGenderedCard: false, genderedFor: nil,
            sortOrder: sortOrder
        )
    }

    /// First `n` opener samples + a closing ritual at the end.
    private func hand(_ n: Int) -> [Card] {
        Array(Card.openerSamples.prefix(n)) + [closingRitual(sortOrder: n + 1)]
    }

    private func makeStore(cards: [Card], startIndex: Int = 0) -> SessionBuilderStore {
        let store = SessionBuilderStore(
            deckId: "the-opener", cards: cards,
            startIndex: startIndex, defaults: defaults
        )
        Self.retain(store)
        return store
    }

    // MARK: - Seeding

    func testDefaultIsAuthoredOrderRemainingHandUntimed() {
        let store = makeStore(cards: hand(5), startIndex: 2)
        // 6 cards total (5 + closing), resume at 2 → 4 remain, authored order.
        XCTAssertEqual(store.entries.map(\.cardId),
                       ["opener-03", "opener-04", "opener-05", "test-closing"])
        let plan = store.plan
        XCTAssertEqual(plan.deckId, "the-opener")
        XCTAssertNil(plan.perCardTimerSeconds)
        XCTAssertNil(plan.globalTimerSeconds)
    }

    func testNearlyFinishedDeckResetsToFullHand() {
        // startIndex leaves only 2 remaining (< minimum 3) → full hand seeds.
        let store = makeStore(cards: hand(5), startIndex: 4)
        XCTAssertEqual(store.cardCount, 6)
    }

    // MARK: - Trim floor

    func testTrimStopsAtThreeCards() {
        let store = makeStore(cards: hand(3))   // 4 cards
        XCTAssertTrue(store.canTrim("opener-01"))
        store.trim("opener-01")                 // → 3 cards, at the floor
        XCTAssertEqual(store.cardCount, 3)
        XCTAssertFalse(store.canTrim("opener-02"))
        store.trim("opener-02")                 // refused
        XCTAssertEqual(store.cardCount, 3)
    }

    // MARK: - Closing ritual protection

    func testClosingRitualCannotBeTrimmed() {
        let store = makeStore(cards: hand(5))   // 6 cards, plenty of headroom
        XCTAssertFalse(store.canTrim("test-closing"))
        store.trim("test-closing")
        XCTAssertTrue(store.entries.contains { $0.cardId == "test-closing" })
        // Ordinary cards still trim fine at the same count.
        store.trim("opener-01")
        XCTAssertEqual(store.cardCount, 5)
    }

    func testTrimmedCardCanBeRestored() {
        let store = makeStore(cards: hand(5))
        store.trim("opener-02")
        XCTAssertEqual(store.trimmed.map(\.cardId), ["opener-02"])
        store.restore("opener-02")
        XCTAssertTrue(store.entries.contains { $0.cardId == "opener-02" })
        XCTAssertTrue(store.trimmed.isEmpty)
    }

    // MARK: - Timers

    func testTimerCycleFollowsLadderAndLandsInPlan() {
        let store = makeStore(cards: hand(5))
        store.cycleTimer(for: "opener-01")      // nil → 60
        XCTAssertEqual(store.entries.first?.timerSeconds, 60)
        let plan = store.plan
        XCTAssertEqual(plan.perCardTimerSeconds?["opener-01"], 60)
        XCTAssertNil(plan.perCardTimerSeconds?["opener-02"])
    }

    // MARK: - Same as last time

    func testStartPersistsAndLastPlanRoundTrips() {
        let store = makeStore(cards: hand(5))
        store.trim("opener-01")
        store.cycleTimer(for: "opener-02")
        let started = store.start()

        // A fresh builder over the same deck sees the remembered plan.
        let fresh = makeStore(cards: hand(5))
        let last = fresh.lastPlan
        XCTAssertNotNil(last)
        XCTAssertEqual(last?.cardIds, started.cardIds)
        XCTAssertEqual(last?.perCardTimerSeconds?["opener-02"], 60)
    }

    func testLastPlanWithStaleCardIdsIsRejected() {
        let store = makeStore(cards: hand(5))
        _ = store.start()
        // The composition-filtered hand changed (a card vanished): stale plan hides.
        let narrower = makeStore(cards: Array(hand(5).dropFirst(2)))
        XCTAssertNil(narrower.lastPlan)
    }

    func testNoLastPlanBeforeFirstStart() {
        let store = makeStore(cards: hand(5))
        XCTAssertNil(store.lastPlan)
    }

    // MARK: - Quick start

    func testQuickStartIsTheUntimedDefaultAndPersists() {
        let store = makeStore(cards: hand(5))
        store.cycleTimer(for: "opener-01")           // authored a timer…
        let quick = store.quickStartPlan()           // …quick start ignores it
        XCTAssertNil(quick.perCardTimerSeconds)
        XCTAssertEqual(quick.cardIds, store.entries.map(\.cardId))
        XCTAssertNotNil(makeStore(cards: hand(5)).lastPlan)   // remembered
    }
}
