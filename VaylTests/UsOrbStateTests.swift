// VaylTests/UsOrbStateTests.swift
//
// TDD for UsOrbState — the Us orb's per-half state machine (Map dashboard
// spec §3.3). Pure logic: quiet window, whole-vs-split, headline guard.

import XCTest
@testable import Vayl

final class UsOrbStateTests: XCTestCase {

    /// Fixed clock so day math never straddles a real midnight.
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func entry(daysAgo: Int) -> PulseEntry {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: now)!
        return PulseEntry(
            date:          date,
            capacityScore: 2.5,
            glowColor:     .rose,
            speed:         "Solitude",
            nervousSystem: "Centered",
            focus:         "Present",
            feeling:       "Content"
        )
    }

    // MARK: - halfState

    func test_halfState_emptyEntries_isUnwritten() {
        XCTAssertEqual(UsOrbState.halfState(entries: [], now: now), .unwritten)
    }

    func test_halfState_entryToday_isCurrent() {
        XCTAssertEqual(UsOrbState.halfState(entries: [entry(daysAgo: 0)], now: now), .current)
    }

    func test_halfState_entryJustInsideWindow_isCurrent() {
        let e = entry(daysAgo: UsOrbState.quietAfterDays - 1)
        XCTAssertEqual(UsOrbState.halfState(entries: [e], now: now), .current)
    }

    func test_halfState_entryExactlyAtWindow_isQuiet() {
        let e = entry(daysAgo: UsOrbState.quietAfterDays)
        XCTAssertEqual(UsOrbState.halfState(entries: [e], now: now), .quiet)
    }

    func test_halfState_oldEntry_isQuiet() {
        XCTAssertEqual(UsOrbState.halfState(entries: [entry(daysAgo: 30)], now: now), .quiet)
    }

    // MARK: - resolve

    func test_resolve_bothEmpty_isWholeUnwritten() {
        XCTAssertEqual(UsOrbState.resolve(mine: [], partner: [], now: now), .wholeUnwritten)
    }

    func test_resolve_oneSideEntry_earnsTheSplit() {
        let state = UsOrbState.resolve(mine: [entry(daysAgo: 0)], partner: [], now: now)
        XCTAssertEqual(state, .split(mine: .current, partner: .unwritten))
    }

    func test_resolve_bothCurrent() {
        let state = UsOrbState.resolve(mine: [entry(daysAgo: 1)],
                                       partner: [entry(daysAgo: 2)],
                                       now: now)
        XCTAssertEqual(state, .split(mine: .current, partner: .current))
    }

    // MARK: - allowsLiveComparison (headline guard)

    func test_allowsLiveComparison_trueOnlyWhenBothCurrent() {
        XCTAssertTrue(UsOrbState.split(mine: .current, partner: .current).allowsLiveComparison)
    }

    func test_allowsLiveComparison_falseWhenEitherSideNotCurrent() {
        XCTAssertFalse(UsOrbState.split(mine: .current, partner: .quiet).allowsLiveComparison)
        XCTAssertFalse(UsOrbState.split(mine: .quiet, partner: .current).allowsLiveComparison)
        XCTAssertFalse(UsOrbState.split(mine: .current, partner: .unwritten).allowsLiveComparison)
        XCTAssertFalse(UsOrbState.split(mine: .unwritten, partner: .unwritten).allowsLiveComparison)
        XCTAssertFalse(UsOrbState.wholeUnwritten.allowsLiveComparison)
    }
}
