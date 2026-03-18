//
//  SupabaseAssessmentResponse.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/10/26.
//


//
//  AssessmentSyncService.swift
//  Open Lightly
//
//  Created in Batch 10 — Assessment Data Sync
//
//  PURPOSE:
//  Pushes assessment data from SwiftData to Supabase after the user
//  completes the individual assessment. Two tables get written:
//
//    1. `assessment_responses` — one row per question answered
//       (maps from local AssessmentResponse model)
//
//    2. `assessment_results` — one row per completed assessment
//       (maps from local AssessmentResult model)
//
//  HOW IT FITS:
//  The user takes the assessment → answers are saved to SwiftData as
//  AssessmentResponse objects → when they finish, an AssessmentResult
//  is computed and saved locally → THEN this service pushes both
//  the individual responses and the final result to Supabase.
//
//  SAME PATTERN AS EVERYTHING ELSE:
//  1. SwiftData saves first (instant, offline-capable)
//  2. This service pushes to Supabase (async, might fail)
//  3. If push fails → flag for retry on next app launch
//
//  WHO CALLS THIS:
//  SyncManager calls these methods. Views should NOT call this directly.
//

import Foundation
import Supabase
import Combine

// MARK: - Supabase DTOs

/// Maps one assessment answer to the `assessment_responses` table in Supabase.
/// This is a plain Codable struct — NOT a SwiftData model.
/// It mirrors the local AssessmentResponse but with snake_case column names.
struct SupabaseAssessmentResponse: Codable {

    /// Auto-generated UUID for this row (matches local AssessmentResponse.id)
    let id: UUID

    /// The user's auth UUID — links this response to a user.
    /// Column: auth_id (foreign key to user_profiles.auth_id)
    let authId: UUID

    /// Which question this answers (e.g. "Q1", "Q2").
    /// Matches ContentAssessmentQuestion.id from your content JSON.
    let questionId: String

    /// Which assessment domain this question belongs to
    /// (e.g. "communication", "trust", "emotionalSecurity").
    /// Stored as the raw string value of your AssessmentDomain enum.
    let domain: String

    /// For scale questions (1–5): the numeric value the user chose.
    /// Nil for multi-select questions.
    let scaleValue: Int?

    /// For multi-select questions: the option IDs the user picked
    /// (e.g. ["a", "c"]). Empty array for scale questions.
    let selectedOptionIds: [String]

    /// Points awarded for this answer, computed by your scoring logic.
    let score: Double

    /// When the user answered this question.
    let answeredAt: String  // ISO 8601 string for Postgres timestamptz

    /// Maps Swift camelCase → Postgres snake_case column names.
    enum CodingKeys: String, CodingKey {
        case id
        case authId = "auth_id"
        case questionId = "question_id"
        case domain
        case scaleValue = "scale_value"
        case selectedOptionIds = "selected_option_ids"
        case score
        case answeredAt = "answered_at"
    }
}

/// Maps the overall assessment outcome to the `assessment_results` table.
/// One row per user per completed assessment.
struct SupabaseAssessmentResult: Codable {

    /// Auto-generated UUID (matches local AssessmentResult.id)
    let id: UUID

    /// The user's auth UUID
    let authId: UUID

    /// Per-domain scores as a JSON object.
    /// Keys are domain raw values (e.g. "communication": 75.0).
    /// Postgres stores this as JSONB.
    let domainScores: [String: Double]

    /// The weighted overall score (0–100).
    let compositeScore: Double

    /// The readiness band derived from compositeScore
    /// (e.g. "ready", "notReady", "almostReady").
    /// Stored as the raw string value of your ReadinessLevel enum.
    let readinessLevel: String

    /// When the assessment was completed.
    let completedAt: String  // ISO 8601 string

    /// Maps Swift camelCase → Postgres snake_case column names.
    enum CodingKeys: String, CodingKey {
        case id
        case authId = "auth_id"
        case domainScores = "domain_scores"
        case compositeScore = "composite_score"
        case readinessLevel = "readiness_level"
        case completedAt = "completed_at"
    }
}

// MARK: - Service

@MainActor
class AssessmentSyncService: ObservableObject {

    /// Shared singleton — access with AssessmentSyncService.shared
    static let shared = AssessmentSyncService()

    /// Reference to the Supabase client for making API calls.
    private var supabase: SupabaseClient {
        SupabaseManager.shared.client
    }

    /// ISO 8601 formatter — converts Swift Dates to strings that
    /// Postgres understands (e.g. "2026-03-11T00:23:01Z").
    private let isoFormatter = ISO8601DateFormatter()

    private let profileService = ProfileService()

    // MARK: - Sync Responses

    /// Pushes all assessment responses for a user to Supabase.
    ///
    /// WHEN TO CALL:
    /// After the user completes the assessment and all AssessmentResponse
    /// objects have been saved to SwiftData.
    ///
    /// WHAT IT DOES:
    /// 1. Converts each local AssessmentResponse into a SupabaseAssessmentResponse
    /// 2. Sends them all to Supabase in one batch INSERT
    ///
    /// WHY BATCH INSERT?
    /// An assessment might have 20–30 questions. Sending one HTTP request
    /// per question would be slow. Supabase supports array inserts, so we
    /// send all responses in a single request.
    ///
    /// - Parameters:
    ///   - responses: Array of local SwiftData AssessmentResponse objects
    ///   - authId: The authenticated user's UUID
    func syncResponses(_ responses: [AssessmentResponse], authId: UUID) async throws {

        // Convert each local SwiftData model into a Supabase-compatible struct.
        // This is where we translate between the two worlds:
        //   - AssessmentResponse (SwiftData, uses enums, has relationships)
        //   - SupabaseAssessmentResponse (plain Codable, uses strings, flat)
        let supabaseResponses = responses.map { response in
            SupabaseAssessmentResponse(
                id: response.id,
                authId: authId,
                questionId: response.questionID,
                domain: response.domain.rawValue,         // Enum → String
                scaleValue: response.scaleValue,
                selectedOptionIds: response.selectedOptionIDs,
                score: response.score,
                answeredAt: isoFormatter.string(from: response.answeredAt)  // Date → String
            )
        }

        // Batch insert all responses in one HTTP request.
        // If some responses already exist (e.g., retry after partial failure),
        // Supabase will throw a conflict error. In production you might want
        // to use .upsert() instead of .insert() to handle this gracefully.
        try await supabase
            .from("assessment_responses")
            .insert(supabaseResponses)
            .execute()

        #if DEBUG
        print("✅ \(supabaseResponses.count) assessment responses synced to Supabase")
        #endif
    }

    // MARK: - Sync Result

    /// Pushes the final assessment result (scores + readiness level) to Supabase.
    ///
    /// WHEN TO CALL:
    /// After the assessment is scored and the AssessmentResult has been
    /// saved to SwiftData.
    ///
    /// - Parameters:
    ///   - result: The local SwiftData AssessmentResult object
    ///   - authId: The authenticated user's UUID
    func syncResult(_ result: AssessmentResult, authId: UUID) async throws {

        // Convert the local model to a Supabase-compatible struct.
        let supabaseResult = SupabaseAssessmentResult(
            id: result.id,
            authId: authId,
            domainScores: result.domainScores,                         // Already [String: Double]
            compositeScore: result.compositeScore,
            readinessLevel: result.readinessLevel.rawValue,            // Enum → String
            completedAt: isoFormatter.string(from: result.completedAt) // Date → String
        )

        // Insert the result. Using .single() because we expect exactly
        // one row to be created.
        try await supabase
            .from("assessment_results")
            .insert(supabaseResult)
            .execute()

        #if DEBUG
        print("✅ Assessment result synced to Supabase (score: \(result.compositeScore))")
        #endif
    }

    // MARK: - Sync Both (Convenience)

    /// Syncs both responses AND the result in one call.
    ///
    /// This is the method SyncManager should call. It handles both
    /// tables and provides a single success/failure point.
    ///
    /// - Parameters:
    ///   - responses: All AssessmentResponse objects from SwiftData
    ///   - result: The computed AssessmentResult from SwiftData
    ///   - authId: The authenticated user's UUID
    func syncAssessment(
        responses: [AssessmentResponse],
        result: AssessmentResult,
        authId: UUID
    ) async throws {
        _ = try await profileService.ensureProfileExists(authId: authId)
        try await syncResponses(responses, authId: authId)
        try await syncResult(result, authId: authId)

        #if DEBUG
        print("✅ Full assessment synced to Supabase")
        #endif
    }
}
