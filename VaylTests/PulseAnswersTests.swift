import XCTest
@testable import Vayl

@MainActor
final class PulseAnswersTests: XCTestCase {

    // MARK: - Canonical quadrant coverage

    func test_expansive_energized_open() {
        let pos = PulseAnswers.position(["Energized", "Reaching Out", "Adventurous", nil, nil])
        XCTAssertEqual(pos.quadrant, .expansive, "High energy + open should land in Expansive")
    }

    func test_protective_overwhelmed_guarded() {
        let pos = PulseAnswers.position(["Overwhelmed", "Deeply Inward", "Defensive", nil, nil])
        XCTAssertEqual(pos.quadrant, .protective, "Low energy + guarded should land in Protective")
    }

    func test_friction_energized_guarded() {
        let pos = PulseAnswers.position(["Energized", "Deeply Inward", "Defensive", nil, nil])
        XCTAssertEqual(pos.quadrant, .reactive, "High energy + guarded should land in Reactive")
    }

    func test_sovereign_overwhelmed_open() {
        // NOTE: "Overwhelmed" (score 1) lands energy exactly on the 0.5 midline under the
        // current decorrelated weights, which resolves to the charged side (see
        // PulsePositionTests.test_midlineTiesResolveTowardChargedOpen), not Receptive. Use
        // "Exhausted" (score 0), the most extreme low-energy pill, to unambiguously clear
        // the low-energy side while preserving this test's original intent.
        let pos = PulseAnswers.position(["Exhausted", "Reaching Out", "Adventurous", nil, nil])
        XCTAssertEqual(pos.quadrant, .receptive, "Low energy + open should land in Receptive")
    }

    // MARK: - Axis range coverage

    func test_energy_axis_range() {
        let low  = PulseAnswers.position(["Overwhelmed", "Balanced", "Content", nil, nil])
        let high = PulseAnswers.position(["Energized", "Balanced", "Content", nil, nil])
        XCTAssertLessThan(low.energy, 0.5)
        XCTAssertGreaterThan(high.energy, 0.5)
    }

    func test_openness_axis_range() {
        let guarded = PulseAnswers.position(["Stable", "Deeply Inward", "Defensive", nil, nil])
        let open    = PulseAnswers.position(["Stable", "Reaching Out", "Adventurous", nil, nil])
        XCTAssertLessThan(guarded.openness, 0.5)
        XCTAssertGreaterThan(open.openness, 0.5)
    }

    // MARK: - Unknown pill label returns neutral (no crash)

    func test_unknownLabel_returnsNeutral() {
        let pos = PulseAnswers.position(["Unknown", "Unknown", "Unknown", nil, nil])
        XCTAssertEqual(pos.energy, 0.5, accuracy: 0.001)
        XCTAssertEqual(pos.openness, 0.5, accuracy: 0.001)
    }

    // MARK: - Stable / Balanced land near centre

    func test_neutral_answers_nearCentre() {
        let pos = PulseAnswers.position(["Stable", "Balanced", "Content", nil, nil])
        // "Content" has openness +0.5, so result leans slightly open — that's expected.
        // Openness lands at 0.4999999999999999 here (binary floating-point division, not a
        // real sub-centre lean), so an accuracy-based comparison is used instead of a strict
        // >= 0.5, matching the tolerance style used elsewhere in this file.
        XCTAssertEqual(pos.energy, 0.5, accuracy: 0.001)
        XCTAssertEqual(pos.openness, 0.5, accuracy: 0.001)
    }
}
