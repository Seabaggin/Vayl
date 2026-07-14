import XCTest
@testable import Vayl

@MainActor
final class CandleIntensityTests: XCTestCase {

    func test_orderedCasesMatchRowSlots() {
        XCTAssertEqual(CandleIntensity.ordered, [.curious, .exploring, .experienced])
    }

    func test_mapsToNMStage() {
        XCTAssertEqual(CandleIntensity.curious.nmStage, .curious)
        XCTAssertEqual(CandleIntensity.exploring.nmStage, .exploring)
        XCTAssertEqual(CandleIntensity.experienced.nmStage, .experienced)
    }
}
