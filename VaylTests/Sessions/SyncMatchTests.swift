import XCTest
@testable import Vayl

final class SyncMatchTests: XCTestCase {
    func testWithinToleranceIsSynced() {
        // 0.08 apart ≤ 0.12 tolerance
        XCTAssertTrue(SyncMatch.isSynced(you: 0.62, partner: 0.70, tolerance: AppAnimation.syncReleaseTolerance))
    }
    func testApartIsMiss() {
        XCTAssertFalse(SyncMatch.isSynced(you: 0.30, partner: 0.72, tolerance: AppAnimation.syncReleaseTolerance))
    }
    func testExactlyAtToleranceIsSynced() {
        // boundary is inclusive (<=)
        XCTAssertTrue(SyncMatch.isSynced(you: 0.50, partner: 0.62, tolerance: 0.12))
    }
    func testToleranceTokenValue() {
        XCTAssertEqual(AppAnimation.syncReleaseTolerance, 0.12, accuracy: 0.0001)
    }
}
