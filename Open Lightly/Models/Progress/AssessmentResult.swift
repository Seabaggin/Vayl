//
//  AssessmentResult.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import Foundation
import SwiftData

// ============================================================
// AssessmentResult.swift
// A SwiftData model representing the overall result of the
// individual assessment for one user.
//
// Stores per-domain scores (as raw string keys for persistence),
// the composite weighted score, and the resulting readiness band.
// This is owned by a UserProfile and stored per person.
//
// Note: domainScores uses string keys (AssessmentDomain.rawValue)
// because SwiftData cannot persist dictionaries keyed by enums.
// ============================================================

@Model
final class AssessmentResult: Identifiable {

    // MARK: - Properties

    var id: UUID = UUID()

    // Keys are AssessmentDomain.rawValue (e.g. "communication")
    var domainScores: [String: Double] = [:]

    // Weighted overall score (0-100)
    var compositeScore: Double = 0.0

    // Overall readiness band derived from compositeScore
    var readinessLevel: ReadinessLevel = ReadinessLevel.notReady

    // When the assessment was completed
    var completedAt: Date = Date()

    // MARK: - Relationships

    // Owner is the UserProfile that owns this result
    @Relationship
    var owner: UserProfile?


    // MARK: - Initializer

    init(
        domainScores: [String: Double] = [:],
        compositeScore: Double = 0.0,
        readinessLevel: ReadinessLevel = ReadinessLevel.notReady
    ) {
        self.id = UUID()
        self.domainScores = domainScores
        self.compositeScore = compositeScore
        self.readinessLevel = readinessLevel
        self.completedAt = Date()
    }


    // MARK: - Preview Helpers

    static let example = AssessmentResult(
        domainScores: [
            "communication": 75.0,
            "trust": 70.0,
            "emotionalSecurity": 68.0,
            "sexualOpenness": 72.0,
            "boundaryAwareness": 73.0
        ],
        compositeScore: 72.0,
        readinessLevel: .ready
    )
}
