// VaylTests/PulseHistoryTests.swift
//
// TDD for PulseHistory — lastLogged + pairedLastLoggedSpaces.
// Pure logic tests: count caps, carry-forward semantics, order preservation.

import XCTest
@testable import Vayl

final class PulseHistoryTests: XCTestCase {

    // MARK: - lastLogged

    func test_lastLogged_cappedAt30() {
        let entries = makeEntries(count: 90)
        XCTAssertEqual(PulseHistory.lastLogged(entries).count, 30)
    }

    func test_lastLogged_yieldsNewest30() {
        let entries = makeEntries(count: 90)
        let result  = PulseHistory.lastLogged(entries)
        // suffix(30) on ascending-sorted entries → last element is most recent (daysAgo=1).
        XCTAssertEqual(
            result.last?.date.timeIntervalSince1970 ?? 0,
            entries.last?.date.timeIntervalSince1970 ?? -1,
            accuracy: 1
        )
    }

    func test_lastLogged_fewEntries_noPadding() {
        XCTAssertEqual(PulseHistory.lastLogged(makeEntries(count: 5)).count, 5)
    }

    func test_lastLogged_empty_returnsEmpty() {
        XCTAssertTrue(PulseHistory.lastLogged([]).isEmpty)
    }

    func test_lastLogged_preservesAscendingOrder() {
        let entries = makeEntries(count: 10)
        let result  = PulseHistory.lastLogged(entries)
        for i in 0..<result.count - 1 {
            XCTAssertLessThanOrEqual(result[i].date, result[i + 1].date)
        }
    }

    // MARK: - pairedLastLogged

    func test_paired_nilBeforeFirstPartnerEntry() {
        let partner = [makeEntry(daysAgo: 5, energy: 0.9, openness: 0.9)]
        let mine    = [makeEntry(daysAgo: 10)]   // earlier than partner's first entry
        XCTAssertNil(PulseHistory.pairedLastLoggedSpaces(mine: mine, partner: partner).first?.partner)
    }

    func test_paired_carryForwardAfterFirstPartnerEntry() {
        let partner = [makeEntry(daysAgo: 5, energy: 0.9, openness: 0.9)]   // .expansive
        let mine    = [makeEntry(daysAgo: 3), makeEntry(daysAgo: 1)]
        let result  = PulseHistory.pairedLastLoggedSpaces(mine: mine, partner: partner)
        XCTAssertEqual(result[0].partner, .expansive)
        XCTAssertEqual(result[1].partner, .expansive)
    }

    func test_paired_quadrantUpdatesWhenPartnerHasNewerEntry() {
        let partner = [
            makeEntry(daysAgo: 10, energy: 0.1, openness: 0.1),   // .protective
            makeEntry(daysAgo: 2,  energy: 0.9, openness: 0.9),   // .expansive
        ]
        let mine = [
            makeEntry(daysAgo: 8),   // between the two → partner is .protective
            makeEntry(daysAgo: 1),   // after second → partner is .expansive
        ]
        let result = PulseHistory.pairedLastLoggedSpaces(mine: mine, partner: partner)
        XCTAssertEqual(result[0].partner, .protective)
        XCTAssertEqual(result[1].partner, .expansive)
    }

    func test_paired_noPartnerEntries_allNil() {
        let mine   = makeEntries(count: 5)
        let result = PulseHistory.pairedLastLoggedSpaces(mine: mine, partner: [])
        XCTAssertTrue(result.allSatisfy { $0.partner == nil })
    }

    func test_paired_countCapped() {
        let mine   = makeEntries(count: 90)
        let result = PulseHistory.pairedLastLoggedSpaces(mine: mine, partner: [])
        XCTAssertEqual(result.count, 30)
    }

    // MARK: - Helpers

    /// Returns `count` entries sorted ascending by date (oldest first), as PulseStore would.
    private func makeEntries(count: Int) -> [PulseEntry] {
        (1...count)
            .map { makeEntry(daysAgo: $0) }
            .sorted { $0.date < $1.date }
    }

    private func makeEntry(
        daysAgo:  Int,
        energy:   Double = 0.5,
        openness: Double = 0.5
    ) -> PulseEntry {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
        return PulseEntry(
            date:          date,
            capacityScore: 2.5,
            glowColor:     .indigo,
            speed:         "x",
            nervousSystem: "x",
            focus:         "x",
            feeling:       "x",
            position:      PulsePosition(energy: energy, openness: openness)
        )
    }
}
