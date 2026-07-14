//
//  SessionSettingsTests.swift
//  VaylTests
//
//  Covers the card-count-scaled pace estimate, display labels, and defaults
//  of the two-knob session-settings model.
//

import XCTest
@testable import Vayl

final class SessionSettingsTests: XCTestCase {

    // MARK: - Pace scales to the selected card count

    func testNoRushHasNoTimer() {
        XCTAssertNil(SessionSettings.Length.unhurried.estimatedMinutes(cardCount: 5))
        XCTAssertNil(SessionSettings(length: .unhurried).softCapMinutes(cardCount: 5))
    }

    func testPaceScalesWithCardCount() {
        // Short ≈ 4 min/card, Full ≈ 7 min/card (a card is a full exchange).
        XCTAssertEqual(SessionSettings.Length.short.estimatedMinutes(cardCount: 4), 16)
        XCTAssertEqual(SessionSettings.Length.full.estimatedMinutes(cardCount: 4), 28)
        XCTAssertEqual(SessionSettings.Length.short.estimatedMinutes(cardCount: 3), 12)
        XCTAssertEqual(SessionSettings.Length.full.estimatedMinutes(cardCount: 5), 35)
    }

    func testSoftCapMirrorsEstimate() {
        XCTAssertEqual(SessionSettings(length: .short).softCapMinutes(cardCount: 5), 20)
        XCTAssertEqual(SessionSettings(length: .full).softCapMinutes(cardCount: 3), 21)
    }

    // MARK: - Display labels (enum rawValues stay stable)

    func testLengthDisplayLabels() {
        XCTAssertEqual(SessionSettings.Length.short.displayLabel, "Short")
        XCTAssertEqual(SessionSettings.Length.full.displayLabel, "Full")
        XCTAssertEqual(SessionSettings.Length.unhurried.displayLabel, "No Rush")
        // rawValue is the persisted/stable identity, not the label.
        XCTAssertEqual(SessionSettings.Length.unhurried.rawValue, "unhurried")
    }

    func testReaderDisplayLabels() {
        XCTAssertEqual(SessionSettings.Reader.you.displayLabel(partnerName: "Alex"), "You")
        XCTAssertEqual(SessionSettings.Reader.partner.displayLabel(partnerName: "Alex"), "Alex")
        XCTAssertEqual(SessionSettings.Reader.either.displayLabel(partnerName: "Alex"), "Dealer's Choice")
    }

    // MARK: - Defaults

    func testDefaults() {
        let s = SessionSettings()
        XCTAssertEqual(s.reader, .you)
        XCTAssertEqual(s.length, .full)
    }
}
