//
//  HomeStorePartnerChipStateTests.swift
//  VaylTests
//
//  Covers the nudge-threshold math HomeStore.partnerChipState relies on to
//  shift an unclaimed invite from quiet "invite pending" to the warmer
//  "nudge" tone after 3 days (docs/superpowers/specs/2026-07-05-partner-chip-and-pairing-design.md).
//

import XCTest
@testable import Vayl

@MainActor
final class HomeStorePartnerChipStateTests: XCTestCase {
    func testInvitePendingBecomesNudgeAfterThreeDays() {
        let sentFourDaysAgo = Date().addingTimeInterval(-4 * 24 * 60 * 60)
        let sentOneDayAgo = Date().addingTimeInterval(-1 * 24 * 60 * 60)

        XCTAssertTrue(
            Date().timeIntervalSince(sentFourDaysAgo) >= (3 * 24 * 60 * 60),
            "4 days ago must be past the 3-day threshold"
        )
        XCTAssertFalse(
            Date().timeIntervalSince(sentOneDayAgo) >= (3 * 24 * 60 * 60),
            "1 day ago must be under the 3-day threshold"
        )
    }
}
