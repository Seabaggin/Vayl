import XCTest
@testable import Vayl

@MainActor
final class SyncRoundTests: XCTestCase {

    // MARK: - SyncConfig

    func test_standardConfig_defaults() {
        let c = SyncConfig.standard
        XCTAssertEqual(c.floorDegrees, 120)
        XCTAssertEqual(c.toleranceDegrees, 18)
        XCTAssertEqual(c.sweepSeconds, 3.5, accuracy: 0.001)
        XCTAssertEqual(c.backstopAfterMisses, 4)
    }

    func test_toleranceEasing_widensPerMissThenCaps() {
        let c = SyncConfig.standard   // step 6, cap 48
        XCTAssertEqual(c.tolerance(afterMisses: 0), 18, accuracy: 0.001)
        XCTAssertEqual(c.tolerance(afterMisses: 1), 24, accuracy: 0.001)
        XCTAssertEqual(c.tolerance(afterMisses: 3), 36, accuracy: 0.001)
        XCTAssertEqual(c.tolerance(afterMisses: 99), 48, accuracy: 0.001) // capped
    }

    func test_reducedPrecision_startsWiderAndSlower() {
        let c = SyncConfig.reducedPrecision
        XCTAssertGreaterThan(c.toleranceDegrees, SyncConfig.standard.toleranceDegrees)
        XCTAssertGreaterThan(c.sweepSeconds, SyncConfig.standard.sweepSeconds)
    }

    // MARK: - SyncRound

    private func round(misses: Int = 0) -> SyncRound {
        SyncRound(config: .standard, misses: misses)
    }

    // classify (elapsedFraction of the sweep → release kind)
    func test_classify_belowFloor_isTooEarly() {
        // floor 120° = fraction 0.333…
        if case .tooEarly(let a) = round().classify(elapsedFraction: 0.2) {
            XCTAssertEqual(a, 72, accuracy: 0.5)
        } else { XCTFail("expected tooEarly") }
    }

    func test_classify_atOrPastFull_isOvershoot() {
        XCTAssertEqual(round().classify(elapsedFraction: 1.0), .overshoot)
        XCTAssertEqual(round().classify(elapsedFraction: 1.4), .overshoot)
    }

    func test_classify_betweenFloorAndFull_isValid() {
        if case .valid(let a) = round().classify(elapsedFraction: 0.5) {
            XCTAssertEqual(a, 180, accuracy: 0.5)
        } else { XCTFail("expected valid") }
    }

    // circular gap
    func test_gap_isCircular() {
        XCTAssertEqual(SyncRound.gap(60, 65), 5, accuracy: 0.001)
        XCTAssertEqual(SyncRound.gap(355, 5), 10, accuracy: 0.001)   // wraps
        XCTAssertEqual(SyncRound.gap(95, 355), 100, accuracy: 0.001) // Bryan's fail example
    }

    // judge
    func test_judge_withinTolerance_isInSync() {
        let v = round().judge(mine: .valid(angle: 200), partner: .valid(angle: 212))
        XCTAssertEqual(v, .inSync)  // gap 12 ≤ 18
    }

    func test_judge_justOutside_isSoClose() {
        let v = round().judge(mine: .valid(angle: 200), partner: .valid(angle: 224))
        XCTAssertEqual(v, .soClose(gapDegrees: 24)) // 18 < 24 ≤ 27 (1.5×)
    }

    func test_judge_wayOff_isFarApart() {
        let v = round().judge(mine: .valid(angle: 130), partner: .valid(angle: 300))
        XCTAssertEqual(v, .farApart(gapDegrees: 170))
    }

    func test_judge_selfEarly_takesPriority() {
        let v = round().judge(mine: .tooEarly(angle: 40), partner: .valid(angle: 200))
        XCTAssertEqual(v, .selfTooEarly)
    }

    func test_judge_partnerOvershoot() {
        let v = round().judge(mine: .valid(angle: 200), partner: .overshoot)
        XCTAssertEqual(v, .partnerOvershoot)
    }

    func test_judge_easedToleranceAdmitsWiderGap() {
        // after 2 misses tolerance = 30, so gap 28 now passes
        let v = round(misses: 2).judge(mine: .valid(angle: 200), partner: .valid(angle: 228))
        XCTAssertEqual(v, .inSync)
    }

    func test_backstop_reachedAtConfiguredMisses() {
        XCTAssertFalse(round(misses: 3).backstopReached)
        XCTAssertTrue(round(misses: 4).backstopReached)
    }
}
