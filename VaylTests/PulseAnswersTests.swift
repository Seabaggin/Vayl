import XCTest
@testable import Vayl

final class PulseAnswersTests: XCTestCase {

    // MARK: - Canonical quadrant coverage

    func test_expansive_energized_open() {
        let pos = PulseAnswers.position(nervousSystem: "Energized", focus: "Reaching Out", feeling: "Adventurous")
        XCTAssertEqual(pos.quadrant, .expansive, "High energy + open should land in Expansive")
    }

    func test_protective_overwhelmed_guarded() {
        let pos = PulseAnswers.position(nervousSystem: "Overwhelmed", focus: "Deeply Inward", feeling: "Defensive")
        XCTAssertEqual(pos.quadrant, .protective, "Low energy + guarded should land in Protective")
    }

    func test_friction_energized_guarded() {
        let pos = PulseAnswers.position(nervousSystem: "Energized", focus: "Deeply Inward", feeling: "Defensive")
        XCTAssertEqual(pos.quadrant, .friction, "High energy + guarded should land in Friction")
    }

    func test_sovereign_overwhelmed_open() {
        let pos = PulseAnswers.position(nervousSystem: "Overwhelmed", focus: "Reaching Out", feeling: "Adventurous")
        XCTAssertEqual(pos.quadrant, .sovereign, "Low energy + open should land in Sovereign")
    }

    // MARK: - Axis range coverage

    func test_energy_axis_range() {
        let low  = PulseAnswers.position(nervousSystem: "Overwhelmed", focus: "Balanced", feeling: "Content")
        let high = PulseAnswers.position(nervousSystem: "Energized",   focus: "Balanced", feeling: "Content")
        XCTAssertLessThan(low.energy,    0.5)
        XCTAssertGreaterThan(high.energy, 0.5)
    }

    func test_openness_axis_range() {
        let guarded = PulseAnswers.position(nervousSystem: "Stable", focus: "Deeply Inward", feeling: "Defensive")
        let open    = PulseAnswers.position(nervousSystem: "Stable", focus: "Reaching Out",  feeling: "Adventurous")
        XCTAssertLessThan(guarded.openness,    0.5)
        XCTAssertGreaterThan(open.openness, 0.5)
    }

    // MARK: - Unknown pill label returns neutral (no crash)

    func test_unknownLabel_returnsNeutral() {
        let pos = PulseAnswers.position(nervousSystem: "Unknown", focus: "Unknown", feeling: "Unknown")
        XCTAssertEqual(pos.energy,   0.5, accuracy: 0.001)
        XCTAssertEqual(pos.openness, 0.5, accuracy: 0.001)
    }

    // MARK: - Stable / Balanced land near centre

    func test_neutral_answers_nearCentre() {
        let pos = PulseAnswers.position(nervousSystem: "Stable", focus: "Balanced", feeling: "Content")
        // "Content" has openness +0.5, so result leans slightly open — that's expected.
        XCTAssertEqual(pos.energy, 0.5, accuracy: 0.001)
        XCTAssertGreaterThanOrEqual(pos.openness, 0.5)
    }
}
