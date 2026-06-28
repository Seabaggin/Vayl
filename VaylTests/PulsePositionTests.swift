// VaylTests/PulsePositionTests.swift

import XCTest
@testable import Vayl

final class PulsePositionTests: XCTestCase {

    // MARK: - Quadrant resolution

    func test_quadrants_byCorner() {
        XCTAssertEqual(PulsePosition(energy: 0.9, openness: 0.9).quadrant, .expansive)
        XCTAssertEqual(PulsePosition(energy: 0.9, openness: 0.1).quadrant, .friction)
        XCTAssertEqual(PulsePosition(energy: 0.1, openness: 0.9).quadrant, .sovereign)
        XCTAssertEqual(PulsePosition(energy: 0.1, openness: 0.1).quadrant, .protective)
    }

    func test_midlineTiesResolveTowardChargedOpen() {
        // >= 0.5 rule: midline ties go to charged/open side
        XCTAssertEqual(PulsePosition(energy: 0.5, openness: 0.5).quadrant, .expansive)
        XCTAssertEqual(PulsePosition(energy: 0.5, openness: 0.4).quadrant, .friction)
        XCTAssertEqual(PulsePosition(energy: 0.4, openness: 0.5).quadrant, .sovereign)
        XCTAssertEqual(PulsePosition(energy: 0.4, openness: 0.4).quadrant, .protective)
    }

    // MARK: - Clamping

    func test_clampsOutOfRange() {
        let p = PulsePosition(energy: 2, openness: -1)
        XCTAssertEqual(p.energy,   1, accuracy: 0.0001)
        XCTAssertEqual(p.openness, 0, accuracy: 0.0001)
    }

    func test_clampsLowBound() {
        let p = PulsePosition(energy: -0.5, openness: -0.5)
        XCTAssertEqual(p.energy,   0, accuracy: 0.0001)
        XCTAssertEqual(p.openness, 0, accuracy: 0.0001)
    }

    // MARK: - Distance

    func test_distance_oppositeCorners_isLargest() {
        let a = PulsePosition(energy: 1, openness: 1)
        let b = PulsePosition(energy: 0, openness: 0)
        XCTAssertEqual(a.distance(to: b), 2.0.squareRoot(), accuracy: 0.0001)
    }

    func test_distance_samePoint_isZero() {
        let a = PulsePosition(energy: 0.7, openness: 0.3)
        XCTAssertEqual(a.distance(to: a), 0, accuracy: 0.0001)
    }

    func test_distance_isSymmetric() {
        let a = PulsePosition(energy: 0.8, openness: 0.2)
        let b = PulsePosition(energy: 0.3, openness: 0.9)
        XCTAssertEqual(a.distance(to: b), b.distance(to: a), accuracy: 0.0001)
    }

    // MARK: - Legacy capacity score

    func test_capacityScore_roundTrip() {
        XCTAssertEqual(PulsePosition(energy: 1,   openness: 0.5).capacityScore, 4, accuracy: 0.0001)
        XCTAssertEqual(PulsePosition(energy: 0,   openness: 0.5).capacityScore, 1, accuracy: 0.0001)
        XCTAssertEqual(PulsePosition(energy: 0.5, openness: 0.5).capacityScore, 2.5, accuracy: 0.0001)
    }

    // MARK: - PulseEntry integration

    func test_legacyEntry_reconstructsPosition() {
        let e = PulseEntry(
            date: Date(), capacityScore: 4, glowColor: .cyan,
            speed: "x", nervousSystem: "x", focus: "x", feeling: "x", position: nil
        )
        XCTAssertEqual(e.resolvedPosition.energy,   1,   accuracy: 0.0001)
        XCTAssertEqual(e.resolvedPosition.openness, 0.5, accuracy: 0.0001)
        // energy 1 (>= 0.5 = charged) + openness 0.5 (>= 0.5 = open) -> expansive
        XCTAssertEqual(e.quadrant, .expansive)
    }

    func test_entryWithPosition_usesStoredPosition() {
        let pos = PulsePosition(energy: 0.2, openness: 0.2)
        let e = PulseEntry(
            date: Date(), capacityScore: 3.5, glowColor: .indigo,
            speed: "x", nervousSystem: "x", focus: "x", feeling: "x", position: pos
        )
        XCTAssertEqual(e.resolvedPosition, pos)
        XCTAssertEqual(e.quadrant, .protective)
    }

    func test_allQuadrants_haveDistinctColors() {
        let colors = PulseQuadrant.allCases.map { $0.capacityColor }
        XCTAssertEqual(Set(colors).count, PulseQuadrant.allCases.count,
                       "Each quadrant must map to a distinct PulseCapacityColor")
    }
}
