import XCTest
@testable import Vayl

final class MonteRowGeometryTests: XCTestCase {

    func test_threeCentersReturned() {
        XCTAssertEqual(AppLayout.monteRowCenters(in: 393).count, 3)
    }

    func test_symmetricAroundMidpoint() {
        let c = AppLayout.monteRowCenters(in: 393)
        XCTAssertEqual(c[1], 393 / 2, accuracy: 0.001)
        XCTAssertEqual(c[0] + c[2], 393, accuracy: 0.001)
    }

    func test_pitchIsCardWidthPlusSmallGap() {
        let w: CGFloat = 393
        let expectedPitch = AppLayout.obTableCardWidth(in: w) + AppSpacing.sm
        let c = AppLayout.monteRowCenters(in: w)
        XCTAssertEqual(c[1] - c[0], expectedPitch, accuracy: 0.001)
        XCTAssertEqual(c[2] - c[1], expectedPitch, accuracy: 0.001)
    }

    func test_rowFitsOnSmallestPhone() {
        let w: CGFloat = 320
        let c = AppLayout.monteRowCenters(in: w)
        let halfCard = AppLayout.obTableCardWidth(in: w) / 2
        XCTAssertGreaterThanOrEqual(c[0] - halfCard, 0)
        XCTAssertLessThanOrEqual(c[2] + halfCard, w)
    }
}
