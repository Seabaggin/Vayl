import XCTest
@testable import Vayl

@MainActor
final class MonteRowGeometryTests: XCTestCase {

    func test_monteFanLayout_centerIsUpright_outerAnglesAreSymmetric() {
        let layout = AppLayout.monteFanLayout(in: 393)
        XCTAssertEqual(layout.count, 3)
        // Center slot: no rotation, no horizontal offset.
        XCTAssertEqual(layout[1].angle, 0, accuracy: 0.001)
        XCTAssertEqual(layout[1].offset.width, 0, accuracy: 0.001)
        // Outer slots: mirror-image angles and offsets.
        XCTAssertEqual(layout[0].angle, -layout[2].angle, accuracy: 0.001)
        XCTAssertEqual(layout[0].offset.width, -layout[2].offset.width, accuracy: 0.001)
        // Fan fits with margin: outer card center within half a fan-card of the edge.
        let fanW = AppLayout.obFanCardWidth(in: 393)
        XCTAssertLessThan(abs(layout[2].offset.width) + fanW / 2, 393 / 2)
    }
}
