// Vayl/Core/Models/PulseAnswers.swift
//
// Pure model: the Q1-Q5 check-in question/pill definitions and the axis mapping
// that turns those answers into a PulsePosition. Extracted from DailyCheckInView
// so Segment 3's PulseCheckInView can consume it directly.

import Foundation

// MARK: - CheckInPill (pure model)

struct CheckInPill: Identifiable {
    let id            = UUID()
    let label:        String
    /// Energy delta (Q1) or openness delta (Q2, Q3). Zero for Q4/Q5.
    let energyDelta:  Double
    let opennessDelta: Double
    let glowOverride: PulseCapacityColor?

    init(_ label: String, energy: Double = 0, openness: Double = 0, glow: PulseCapacityColor? = nil) {
        self.label         = label
        self.energyDelta   = energy
        self.opennessDelta = openness
        self.glowOverride  = glow
    }
}

// MARK: - CheckInQuestion (pure model)

struct CheckInQuestion {
    let text:  String
    let pills: [CheckInPill]
}

// MARK: - PulseAnswers

/// Static namespace for the five check-in questions and the position mapping.
enum PulseAnswers {

    // MARK: - Question definitions

    /// Q1: nervous system -> energy axis
    static let nervousSystem = CheckInQuestion(
        text: "How is your nervous system right now?",
        pills: [
            CheckInPill("Overwhelmed",  energy: -1.0),
            CheckInPill("Exhausted",    energy: -0.5),
            CheckInPill("Stable",       energy:  0.0),
            CheckInPill("Recharging",   energy: +0.5),
            CheckInPill("Energized",    energy: +1.0),
        ]
    )

    /// Q2: focus -> openness axis
    static let focus = CheckInQuestion(
        text: "Where is your focus naturally pulling you?",
        pills: [
            CheckInPill("Deeply Inward",  openness: -0.75),
            CheckInPill("Just Me",        openness: -0.25),
            CheckInPill("Balanced",       openness:  0.0),
            CheckInPill("Reaching Out",   openness: +0.75),
        ]
    )

    /// Q3: feeling -> openness axis (secondary)
    static let feeling = CheckInQuestion(
        text: "What's the loudest feeling underneath?",
        pills: [
            CheckInPill("Defensive",   openness: -0.5),
            CheckInPill("Anxious",     openness: -0.5),
            CheckInPill("Content",     openness: +0.5),
            CheckInPill("Secure",      openness: +0.75),
            CheckInPill("Adventurous", openness: +1.0),
        ]
    )

    /// Q4: glow colour (capacity tier) - no axis effect
    static let glowColor = CheckInQuestion(
        text: "How is your overall capacity to hold space?",
        pills: [
            CheckInPill("Empty",    glow: .rose),
            CheckInPill("Low",      glow: .magenta),
            CheckInPill("Good",     glow: .indigo),
            CheckInPill("Abundant", glow: .cyan),
        ]
    )

    /// Q5: desired speed tonight - no axis effect
    static let speed = CheckInQuestion(
        text: "What's the ideal speed for tonight?",
        pills: [
            CheckInPill("Solitude"),
            CheckInPill("Just Proximity"),
            CheckInPill("Light Connection"),
            CheckInPill("Deep Dive"),
            CheckInPill("Playful"),
        ]
    )

    /// All five questions in order.
    static let all: [CheckInQuestion] = [nervousSystem, focus, feeling, glowColor, speed]

    // MARK: - Axis mapping

    /// Resolve the five canonical answers into a 2D PulsePosition.
    /// - Parameters:
    ///   - nervousSystemAnswer: Q1 pill label
    ///   - focusAnswer: Q2 pill label
    ///   - feelingAnswer: Q3 pill label
    /// - Returns: a clamped PulsePosition (energy derived from Q1; openness from Q2+Q3 averaged).
    static func position(
        nervousSystem nervousSystemAnswer: String,
        focus focusAnswer: String,
        feeling feelingAnswer: String
    ) -> PulsePosition {
        let energyDelta   = delta(for: nervousSystemAnswer, in: nervousSystem, axis: .energy)
        let opennessDeltaQ2 = delta(for: focusAnswer,         in: focus,         axis: .openness)
        let opennessDeltaQ3 = delta(for: feelingAnswer,        in: feeling,       axis: .openness)

        // Energy: start mid (0.5), shift by Q1 delta (range -1...+1 -> result 0...1 before clamp)
        let energy   = 0.5 + energyDelta * 0.5

        // Openness: start mid (0.5), blend Q2 (weight 0.6) + Q3 (weight 0.4)
        let openness = 0.5 + (opennessDeltaQ2 * 0.6 + opennessDeltaQ3 * 0.4) * 0.5

        return PulsePosition(energy: energy, openness: openness)
    }

    // MARK: - Helpers

    private enum Axis { case energy, openness }

    private static func delta(for label: String, in question: CheckInQuestion, axis: Axis) -> Double {
        guard let pill = question.pills.first(where: { $0.label == label }) else { return 0 }
        return axis == .energy ? pill.energyDelta : pill.opennessDelta
    }
}
