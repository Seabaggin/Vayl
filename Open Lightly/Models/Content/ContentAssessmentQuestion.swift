//
//  AssessmentQuestion.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import Foundation

// ============================================================
// AssessmentQuestion.swift
// A read-only content model representing one of the 20
// individual assessment questions.
//
// The assessment has 5 domains with 4 questions each.
// Question types are either scale (5-point Likert) or
// multi-select (pick all that apply).
//
// This struct is decoded from JSON bundled in the app.
// It is never modified at runtime.
//
// The user's ANSWERS are stored in SwiftData (AssessmentResponse),
// not here. This struct only describes the question itself.
//
// See PROJECT_SCOPE.md Section 8.1 for assessment design.
// See PROJECT_SCOPE.md Section 10 for scoring logic.
// See AppEnums.swift for AssessmentDomain, AssessmentQuestionType.
// ============================================================

// MARK: - QuestionOption
// A single selectable option within a multi-select question.
// Each option has a point value used in scoring.

struct ContentQuestionOption: Identifiable, Codable {
    let id: String    // option identifier within the question (e.g. "a")
    let text: String  // the option text shown to the user
    let points: Int   // point value awarded when this option is selected

    static let example = ContentQuestionOption(id: "a", text: "Listen and try to understand", points: 5)
}


// MARK: - AssessmentQuestion

struct ContentAssessmentQuestion: Identifiable, Codable {

    // MARK: - Properties

    // Question identifier (e.g. "Q1", "Q2", ... "Q20")
    let id: String

    // Which of the 5 scored domains this belongs to
    let domain: AssessmentDomain

    // The question text shown to the user
    let text: String

    // Scale or multiSelect
    let type: AssessmentQuestionType

    // Only present for multiSelect questions, nil for scale
    let options: [ContentQuestionOption]?

    // Scoring weight for this question within its domain
    let weight: Double

    // Position in the assessment (1-20)
    let sortOrder: Int

    // Optional "Why this matters" note shown below the question
    let contextNote: String?


    // MARK: - Computed Properties

    // Whether this is a 5-point Likert scale question.
    var isScale: Bool { type == .scale }

    // Whether this is a pick-all-that-apply question.
    var isMultiSelect: Bool { type == .multiSelect }

    // Convenience accessor for display
    var domainDisplayName: String { domain.displayName }


    // MARK: - Preview Helpers

    static let scaleExample = ContentAssessmentQuestion(
        id: "Q1",
        domain: .communication,
        text: "How comfortable do you feel bringing up difficult topics with your partner?",
        type: .scale,
        options: nil,
        weight: 1.0,
        sortOrder: 1,
        contextNote: "Open communication is consistently linked to successful ENM navigation."
    )

    static let multiSelectExample = ContentAssessmentQuestion(
        id: "Q10",
        domain: .communication,
        text: "When your partner shares something that hurts, what is your typical response?",
        type: .multiSelect,
        options: [
            ContentQuestionOption(id: "a", text: "Listen and try to understand", points: 5),
            ContentQuestionOption(id: "b", text: "Need time to process", points: 3),
            ContentQuestionOption(id: "c", text: "Ask clarifying questions", points: 4),
            ContentQuestionOption(id: "d", text: "Become defensive", points: 1),
            ContentQuestionOption(id: "e", text: "Shut down or withdraw", points: 1)
        ],
        weight: 1.0,
        sortOrder: 10,
        contextNote: "Conflict response patterns predict how couples handle ENM-related stress."
    )
}
