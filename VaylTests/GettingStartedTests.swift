import XCTest
@testable import Vayl

@MainActor
final class GettingStartedTests: XCTestCase {

    func test_day1_paired_nothingDone_mapIsActive_inviteAutoDone() {
        let gs = GettingStarted.resolve(myMapComplete: false, isPaired: true, partnerMapComplete: false, revealDone: false)
        XCTAssertEqual(gs.steps.map(\.kind), [.profile, .mapDesires, .invitePartner, .seeReveal])
        XCTAssertEqual(gs.state(of: .profile), .done)            // onboarding finished
        XCTAssertEqual(gs.state(of: .invitePartner), .done)      // already paired
        XCTAssertEqual(gs.state(of: .mapDesires), .active)       // the next action
        XCTAssertEqual(gs.state(of: .seeReveal), .locked)
        XCTAssertEqual(gs.nextStep?.kind, .mapDesires)
        XCTAssertEqual(gs.completedCount, 2)                     // profile + invite
        XCTAssertEqual(gs.totalCount, 4)
        XCTAssertFalse(gs.isComplete)
    }

    func test_unpaired_inviteIsActiveAfterMap() {
        let gs = GettingStarted.resolve(myMapComplete: true, isPaired: false, partnerMapComplete: false, revealDone: false)
        XCTAssertEqual(gs.state(of: .mapDesires), .done)
        XCTAssertEqual(gs.state(of: .invitePartner), .active)    // unpaired → inviting is the next action
        XCTAssertEqual(gs.nextStep?.kind, .invitePartner)
    }

    func test_bothDone_revealIsActive() {
        let gs = GettingStarted.resolve(myMapComplete: true, isPaired: true, partnerMapComplete: true, revealDone: false)
        XCTAssertEqual(gs.state(of: .seeReveal), .active)
        XCTAssertEqual(gs.nextStep?.kind, .seeReveal)
    }

    func test_allDone_isComplete_noNext() {
        let gs = GettingStarted.resolve(myMapComplete: true, isPaired: true, partnerMapComplete: true, revealDone: true)
        XCTAssertTrue(gs.isComplete)
        XCTAssertNil(gs.nextStep)
        XCTAssertEqual(gs.completedCount, 4)
    }
}
