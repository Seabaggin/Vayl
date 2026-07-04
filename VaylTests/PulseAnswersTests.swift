import XCTest
@testable import Vayl

final class PulseAnswersTests: XCTestCase {

    // MARK: - Canonical quadrant coverage

    func test_expansive_energized_open() {
        let pos = PulseAnswers.position(["Energized", "Fully Outward", "Adventurous", "Overflowing", "Deep Dive"])
        XCTAssertEqual(pos.quadrant, .expansive, "High energy + open should land in Expansive")
    }

    func test_protective_exhausted_guarded() {
        let pos = PulseAnswers.position(["Exhausted", "Deeply Inward", "Sensitive", "Empty", "Solitude"])
        XCTAssertEqual(pos.quadrant, .protective, "Low energy + guarded should land in Protective")
    }

    func test_reactive_energized_guarded() {
        let pos = PulseAnswers.position(["Energized", "Deeply Inward", "Anxious", "Overflowing", "Solitude"])
        XCTAssertEqual(pos.quadrant, .reactive, "High energy + guarded should land in Reactive")
    }

    func test_receptive_exhausted_open() {
        let pos = PulseAnswers.position(["Exhausted", "Fully Outward", "Sensitive", "Empty", "Deep Dive"])
        XCTAssertEqual(pos.quadrant, .receptive, "Low energy + open should land in Receptive")
    }

    // MARK: - Axis range coverage

    func test_energy_axis_range() {
        // Only Q1 answered; the other questions contribute the neutral score.
        let low  = PulseAnswers.position(["Exhausted", nil, nil, nil, nil])
        let high = PulseAnswers.position(["Energized", nil, nil, nil, nil])
        XCTAssertLessThan(low.energy,     0.5)
        XCTAssertGreaterThan(high.energy, 0.5)
    }

    func test_openness_axis_range() {
        // Only Q2 answered; the other questions contribute the neutral score.
        let guarded = PulseAnswers.position([nil, "Deeply Inward", nil, nil, nil])
        let open    = PulseAnswers.position([nil, "Fully Outward", nil, nil, nil])
        XCTAssertLessThan(guarded.openness,  0.5)
        XCTAssertGreaterThan(open.openness,  0.5)
    }

    // MARK: - Unknown pill label returns neutral (no crash)

    func test_unknownLabel_returnsNeutral() {
        let pos = PulseAnswers.position(["Unknown", "Unknown", "Unknown", "Unknown", "Unknown"])
        XCTAssertEqual(pos.energy,   0.5, accuracy: 0.001)
        XCTAssertEqual(pos.openness, 0.5, accuracy: 0.001)
    }

    // MARK: - Unanswered questions land at centre

    func test_neutral_answers_nearCentre() {
        let pos = PulseAnswers.position([nil, nil, nil, nil, nil])
        XCTAssertEqual(pos.energy,   0.5, accuracy: 0.001)
        XCTAssertEqual(pos.openness, 0.5, accuracy: 0.001)
    }
}
