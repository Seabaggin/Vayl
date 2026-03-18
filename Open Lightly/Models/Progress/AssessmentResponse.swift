//
//  AssessmentResponse.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import Foundation
import SwiftData

// ============================================================
// AssessmentResponse.swift
// A SwiftData model representing one answer to an individual
// assessment question.
//
// Each AssessmentResponse is owned by a UserProfile and stores
// either a scale value (1-5) or a set of selected option IDs
// for multi-select questions. The response also carries a
// computed score (points awarded) and a timestamp.
//
// This model is decoded/created at runtime as users complete
// the individual assessment. The aggregate scoring and
// readiness evaluation happen elsewhere.
// ============================================================

@Model
final class AssessmentResponse: Identifiable {

    // MARK: - Properties

    var id: UUID = UUID()

    // Matches ContentAssessmentQuestion.id (e.g. "Q1")
    var questionID: String

    // Domain this question belongs to
    var domain: AssessmentDomain

    // For scale questions (1-5)
    var scaleValue: Int? = nil

    // For multi-select questions: selected option ids (e.g. ["a","c"]) 
    var selectedOptionIDs: [String] = []

    // Computed points awarded for this answer (updated by scoring logic)
    var score: Double = 0.0

    // When the question was answered
    var answeredAt: Date = Date()

    // MARK: - Relationships

    // Owner is the UserProfile that created this response.
    // The inverse relationship (UserProfile.assessmentResponses)
    // is defined on the UserProfile model and uses cascade delete.
    @Relationship
    var owner: UserProfile?


    // MARK: - Initializer

    init(
        questionID: String,
        domain: AssessmentDomain,
        scaleValue: Int? = nil,
        selectedOptionIDs: [String] = [],
        score: Double = 0.0
    ) {
        self.id = UUID()
        self.questionID = questionID
        self.domain = domain
        self.scaleValue = scaleValue
        self.selectedOptionIDs = selectedOptionIDs
        self.score = score
        self.answeredAt = Date()
    }


    // MARK: - Preview Helpers

    // Note: using .emotionalSecurity (matches AssessmentDomain case names)
    static let example = AssessmentResponse(questionID: "Q1", domain: .emotionalSecurity, scaleValue: 4, score: 4.0)
}
