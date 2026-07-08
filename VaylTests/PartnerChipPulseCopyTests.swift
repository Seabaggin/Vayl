//
//  PartnerChipPulseCopyTests.swift
//  VaylTests
//
//  Coverage of PulsePosition -> tile copy for the partner chip's Pulse
//  quick-view tile.
//

import XCTest
@testable import Vayl

final class PartnerChipPulseCopyTests: XCTestCase {
    func testNilPositionShowsConfirmedEmptyCopy() {
        XCTAssertEqual(PartnerChipPulseCopy.tileText(for: nil), "No Pulse to show")
    }

    func testNilPositionWithFetchFailureShowsFailureCopy() {
        XCTAssertEqual(PartnerChipPulseCopy.tileText(for: nil, fetchFailed: true), "Couldn't check")
    }

    func testValidPositionShowsSpaceName() {
        // High energy + high openness -> unambiguously .expansive (well clear
        // of the 0.5 midline in both axes).
        let position = PulsePosition(energy: 0.9, openness: 0.9)
        XCTAssertEqual(position.quadrant, .expansive)
        XCTAssertEqual(PartnerChipPulseCopy.tileText(for: position), "The Expansive Space")
    }
}
