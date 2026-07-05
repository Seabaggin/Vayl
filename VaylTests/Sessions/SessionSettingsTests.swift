//
//  SessionSettingsTests.swift
//  VaylTests
//
//  Covers the derived soft-cap and the defaults of the two-knob session-settings
//  model.
//

import XCTest
@testable import Vayl

final class SessionSettingsTests: XCTestCase {
    func testUnhurriedHasNoTimer() { XCTAssertNil(SessionSettings(length: .unhurried).softCapMinutes) }
    func testShortAndFullHaveCaps() {
        XCTAssertEqual(SessionSettings(length: .short).softCapMinutes, 10)
        XCTAssertEqual(SessionSettings(length: .full).softCapMinutes, 20)
    }
    func testDefaults() {
        let s = SessionSettings()
        XCTAssertEqual(s.reader, .you); XCTAssertEqual(s.length, .full)
    }
}
