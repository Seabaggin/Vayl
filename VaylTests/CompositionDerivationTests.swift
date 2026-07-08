import XCTest
@testable import Vayl

// Spec §9 derivation: both partners' OB gender answers → the composition to
// PROPOSE at link completion, or nil → silent .flexible. Inputs are the raw
// GenderPhase drum strings (GenderSequencer.options) or nil when declined.
// Source of truth: GenderDynamic.proposal in AppCardEnums.swift.
final class CompositionDerivationTests: XCTestCase {

    func test_binaryPairsDeriveTheirComposition() {
        XCTAssertEqual(GenderDynamic.proposal(myGender: "Man", partnerGender: "Woman"), .mf)
        XCTAssertEqual(GenderDynamic.proposal(myGender: "Man", partnerGender: "Man"), .mm)
        XCTAssertEqual(GenderDynamic.proposal(myGender: "Woman", partnerGender: "Woman"), .ff)
    }

    func test_derivationIsSymmetric() {
        // Both devices derive independently — order must not matter.
        XCTAssertEqual(
            GenderDynamic.proposal(myGender: "Woman", partnerGender: "Man"),
            GenderDynamic.proposal(myGender: "Man", partnerGender: "Woman")
        )
    }

    func test_transAnswersCountOnTheirStatedAxis() {
        XCTAssertEqual(GenderDynamic.proposal(myGender: "Trans Man", partnerGender: "Woman"), .mf)
        XCTAssertEqual(GenderDynamic.proposal(myGender: "Trans Woman", partnerGender: "Trans Woman"), .ff)
        XCTAssertEqual(GenderDynamic.proposal(myGender: "Trans Man", partnerGender: "Man"), .mm)
    }

    func test_nonBinaryOrMissingAnswerMeansNoProposal() {
        XCTAssertNil(GenderDynamic.proposal(myGender: "Non-binary", partnerGender: "Man"))
        XCTAssertNil(GenderDynamic.proposal(myGender: "Man", partnerGender: "Non-binary"))
        XCTAssertNil(GenderDynamic.proposal(myGender: nil, partnerGender: "Woman"))
        XCTAssertNil(GenderDynamic.proposal(myGender: nil, partnerGender: nil))
    }

    func test_inputNormalization() {
        // The remote round-trip must not break derivation on casing/whitespace.
        XCTAssertEqual(GenderDynamic.proposal(myGender: " man ", partnerGender: "WOMAN"), .mf)
        XCTAssertNil(GenderDynamic.proposal(myGender: "manly", partnerGender: "Woman"))
    }
}
