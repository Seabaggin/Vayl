import XCTest
@testable import Vayl

@MainActor
final class PathContentServiceTests: XCTestCase {
    func test_loadStyle_swinging_returnsThirteenLandmarksAcrossFivePhases() throws {
        let content = try PathContentService().loadStyle("swinging")
        XCTAssertEqual(content.phases.count, 5)
        XCTAssertEqual(content.landmarks.count, 13)
        XCTAssertEqual(content.landmarks.map(\.id).first, "fantasy-talk")
        XCTAssertEqual(content.landmarks.map(\.id).last, "solo-night")
    }
}
