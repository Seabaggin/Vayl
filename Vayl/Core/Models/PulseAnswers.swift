// Vayl/Core/Models/PulseAnswers.swift
//
// Pure model: the Q1-Q5 check-in question/pill definitions, the weighted axis scoring
// that turns those answers into a PulsePosition, and the Uncharted variance check.
//
// Scoring model (spec §2):
//   • Each answer scores left → right: leftmost pill = 4, rightmost = 0.
//   • Each question carries an energy weight and an openness weight; Q3 (Vibe) is the only
//     question with asymmetric per-answer axis scores (Anxious is high-energy, low-openness).
//   • Raw Energy   = Σ(answerEnergyScore   × energyWeight)   / 9.6
//     Raw Openness = Σ(answerOpennessScore × opennessWeight) / 10.4
//   • Unanswered questions contribute a neutral score of 2.0, so the orb starts near centre
//     and drifts as each answer lands.
//
// NOTE (decorrelated weights): the three cross-axis weights are HALVED from the original spec
// (Q1 openness 0.3→0.15, Q4 openness 0.35→0.15, Q5 energy 0.2→0.1). The spec's weights made
// the two axes positively correlated, piling readings on the Expansive↔Protective diagonal
// (Expansive alone was 30.5% of all combinations). Trimming the secondary loadings lifts the
// off-diagonal corners (Reactive/Receptive) and drops Expansive to ~27% — a flatter map.
// Each divisor is 4 × Σ(its weights), so all-max still reaches 1.0 and all-neutral stays (0.5,0.5).

import Foundation

// MARK: - CheckInPill (pure model)

struct CheckInPill: Identifiable {
    let id             = UUID()
    let label: String
    /// Raw 0–4 axis scores for this answer (before the question's axis weights are applied).
    /// For every question except Q3 the two are equal (the answer's left→right position).
    let energyScore: Double
    let opennessScore: Double

    /// Symmetric answer (position value drives both axes equally).
    init(_ label: String, score: Double) {
        self.label = label
        self.energyScore = score
        self.opennessScore = score
    }

    /// Asymmetric answer (Q3 only) — distinct energy vs openness score.
    init(_ label: String, energy: Double, openness: Double) {
        self.label = label
        self.energyScore = energy
        self.opennessScore = openness
    }
}

// MARK: - CheckInQuestion (pure model)

struct CheckInQuestion {
    let text: String
    let pills: [CheckInPill]
    /// How strongly this question pushes each axis in the weighted sum.
    let energyWeight: Double
    let opennessWeight: Double
}

// MARK: - PulseAnswers

/// Static namespace for the five check-in questions, the weighted position mapping, and the
/// Uncharted variance check.
enum PulseAnswers {

    /// Score used for a question that hasn't been answered yet — neutral midpoint, so the
    /// orb sits near centre until answers pull it.
    static let neutralScore: Double = 2.0

    // MARK: - Question definitions
    // Pills are listed leftmost → rightmost; leftmost scores 4, rightmost scores 0.

    /// Q1 — nervous system. Weights: energy 1.0, openness 0.3.
    static let nervousSystem = CheckInQuestion(
        text: "How is your nervous system right now?",
        pills: [
            CheckInPill("Energized", score: 4),
            CheckInPill("Centered", score: 3),
            CheckInPill("Recharging", score: 2),
            CheckInPill("Overwhelmed", score: 1),
            CheckInPill("Exhausted", score: 0)
        ],
        energyWeight: 1.0, opennessWeight: 0.15
    )

    /// Q2 — emotional lean. Weights: energy 0.0, openness 1.0.
    static let focus = CheckInQuestion(
        text: "Where is your emotional energy leaning?",
        pills: [
            CheckInPill("Fully Outward", score: 4),
            CheckInPill("Reaching Out", score: 3),
            CheckInPill("Present", score: 2),
            CheckInPill("Needing Space", score: 1),
            CheckInPill("Deeply Inward", score: 0)
        ],
        energyWeight: 0.0, opennessWeight: 1.0
    )

    /// Q3 — vibe. Weights: energy 0.5, openness 0.5. The only asymmetric question:
    /// Anxious is a high-energy but low-openness state, so it can't ride a uniform scale.
    static let feeling = CheckInQuestion(
        text: "What's your vibe right now?",
        pills: [
            CheckInPill("Adventurous", energy: 4, openness: 4),
            CheckInPill("Warm", energy: 3, openness: 3),
            CheckInPill("Content", energy: 2, openness: 2),
            CheckInPill("Anxious", energy: 3, openness: 1),
            CheckInPill("Sensitive", energy: 1, openness: 1)
        ],
        energyWeight: 0.5, opennessWeight: 0.5
    )

    /// Q4 — capacity to give. Weights: energy 0.8, openness 0.35.
    static let capacity = CheckInQuestion(
        text: "How much do you have to give right now?",
        pills: [
            CheckInPill("Overflowing", score: 4),
            CheckInPill("Plenty", score: 3),
            CheckInPill("Just Enough", score: 2),
            CheckInPill("Running Low", score: 1),
            CheckInPill("Empty", score: 0)
        ],
        energyWeight: 0.8, opennessWeight: 0.15
    )

    /// Q5 — ideal speed right now. Weights: energy 0.2, openness 0.8.
    static let speed = CheckInQuestion(
        text: "What's the ideal speed right now?",
        pills: [
            CheckInPill("Deep Dive", score: 4),
            CheckInPill("Playful", score: 3),
            CheckInPill("Light Connection", score: 2),
            CheckInPill("Quietly Together", score: 1),
            CheckInPill("Solitude", score: 0)
        ],
        energyWeight: 0.1, opennessWeight: 0.8
    )

    /// All five questions in order — indices match the View's `answers` array.
    static let all: [CheckInQuestion] = [nervousSystem, focus, feeling, capacity, speed]

    // MARK: - Normalisers

    private static let energyDivisor: Double = 9.6    // = 4 × Σ(energy weights 2.4)
    private static let opennessDivisor: Double = 10.4   // = 4 × Σ(openness weights 2.6), so the axis reaches 1.0

    // MARK: - Position

    /// Resolve the five answer labels (nil = not yet answered) into a weighted 2D position.
    /// Unanswered questions contribute `neutralScore`, so the orb starts near centre and
    /// slides as answers land.
    static func position(_ answers: [String?]) -> PulsePosition {
        var rawEnergy   = 0.0
        var rawOpenness = 0.0
        for (i, question) in all.enumerated() {
            let pill = answeredPill(answers, i)
            let e = pill?.energyScore   ?? neutralScore
            let o = pill?.opennessScore ?? neutralScore
            rawEnergy   += e * question.energyWeight
            rawOpenness += o * question.opennessWeight
        }
        return PulsePosition(
            energy: rawEnergy   / energyDivisor,
            openness: rawOpenness / opennessDivisor
        )
    }

    // MARK: - Uncharted variance check (spec §5)

    /// Fires only when all five are answered and the answers are contradictory on BOTH axes.
    /// Energy signals:  Q1, Q3-energy, Q4.  Openness signals: Q2, Q3-openness, Q5.
    static func isUncharted(_ answers: [String?]) -> Bool {
        guard answers.count == all.count, answers.allSatisfy({ $0 != nil }) else { return false }
        guard
            let q1  = answeredPill(answers, 0)?.energyScore,
            let q2  = answeredPill(answers, 1)?.opennessScore,
            let q3  = answeredPill(answers, 2),
            let q4  = answeredPill(answers, 3)?.energyScore,
            let q5  = answeredPill(answers, 4)?.opennessScore
        else { return false }

        let energyContradicted   = axisContradicted(q1, q3.energyScore, q4)
        let opennessContradicted = axisContradicted(q2, q3.opennessScore, q5)
        return energyContradicted && opennessContradicted
    }

    /// One axis is "contradicted" when its two flanking signals disagree by ≥2, and the Q3
    /// signal (the `mid` argument) hugs one extreme rather than sitting in the middle.
    private static func axisContradicted(_ a: Double, _ mid: Double, _ b: Double) -> Bool {
        guard abs(a - b) >= 2 else { return false }
        let sorted = [a, mid, b].sorted()
        let lo = sorted[0], median = sorted[1], hi = sorted[2]
        let nearExtreme = abs(mid - hi) <= 1 || abs(mid - lo) <= 1
        return nearExtreme && mid != median
    }

    // MARK: - Space

    /// The full six-space classification for a set of answers.
    static func space(_ answers: [String?]) -> PulseSpace {
        PulseSpace.resolve(position(answers), isUncharted: isUncharted(answers))
    }

    // MARK: - Helpers

    private static func answeredPill(_ answers: [String?], _ index: Int) -> CheckInPill? {
        guard index < answers.count, index < all.count, let label = answers[index] else { return nil }
        return all[index].pills.first { $0.label == label }
    }
}
