import XCTest
@testable import Vayl

@MainActor
final class PathLandmarkProgressTests: XCTestCase {
    func test_pathLandmarkState_rawValues_matchDatabaseCheckConstraint() {
        XCTAssertEqual(PathLandmarkState.curious.rawValue, "curious")
        XCTAssertEqual(PathLandmarkState.discussed.rawValue, "discussed")
        XCTAssertEqual(PathLandmarkState.planning.rawValue, "planning")
        XCTAssertEqual(PathLandmarkState.didIt.rawValue, "did_it")
        XCTAssertEqual(PathLandmarkState.skipped.rawValue, "skipped")
    }

    func test_discussedVia_rawValues_matchDatabaseCheckConstraint() {
        XCTAssertEqual(DiscussedVia.session.rawValue, "session")
        XCTAssertEqual(DiscussedVia.manual.rawValue, "manual")
    }
}
