//
//  PartnerChipDesireMapCopyTests.swift
//  VaylTests
//
//  Exhaustive coverage of DesireMapState -> tile copy for the partner chip's
//  Desire Map quick-view tile.
//

import XCTest
@testable import Vayl

@MainActor
final class PartnerChipDesireMapCopyTests: XCTestCase {
    func testAllCasesProduceNonEmptyTileCopy() {
        let cases: [DesireMapState] = [
            .hidden,
            .gated,
            .yourTurn,
            .youDone(partnerName: "Alex"),
            .waiting,
            .bothReady,
            .freeRevealSeen(matchCount: 3),
            .matchReady,
            .redoInProgress(partnerName: "Alex", matchCount: 3),
            .revealed,
            .fullyUnlocked
        ]
        for state in cases {
            let copy = PartnerChipDesireMapCopy.tileText(for: state, partnerName: "Alex")
            XCTAssertFalse(copy.isEmpty, "no empty tile copy for \(state)")
        }
    }

    func testYouDoneShowsPartnerName() {
        let copy = PartnerChipDesireMapCopy.tileText(for: .youDone(partnerName: "Alex"), partnerName: "Alex")
        XCTAssertEqual(copy, "Waiting on Alex")
    }

    func testBothReadyShowsBothComplete() {
        let copy = PartnerChipDesireMapCopy.tileText(for: .bothReady, partnerName: "Alex")
        XCTAssertEqual(copy, "Both complete")
    }

    func testGatedShowsNotStarted() {
        let copy = PartnerChipDesireMapCopy.tileText(for: .gated, partnerName: "Alex")
        XCTAssertEqual(copy, "You haven't started")
    }
}
