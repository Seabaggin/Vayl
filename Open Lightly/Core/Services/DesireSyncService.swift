//
//  SupabaseDesireRating.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/10/26.
//


//
//  DesireSyncService.swift
//  Open Lightly
//
//  Created in Batch 10 — Desire Ratings Sync
//
//  PURPOSE:
//  Pushes desire map ratings from SwiftData to Supabase after the user
//  completes the desire map during onboarding (or updates ratings later).
//
//  TABLE: `desire_ratings`
//  Each row = one user's private rating for one desire item.
//
//  PRIVACY NOTE:
//  Desire ratings are PRIVATE — they are never shown to the partner directly.
//  They're only used server-side to compute DesireMatch results (overlapping
//  interests between two paired users). The raw ratings stay private.
//
//  SAME PATTERN:
//  1. SwiftData saves first (instant, offline-capable)
//  2. This service pushes to Supabase (async, might fail)
//  3. If push fails → SyncManager flags for retry
//

import Foundation
import Supabase
import Combine

// MARK: - Supabase DTO

/// Maps one desire rating to the `desire_ratings` table in Supabase.
/// Plain Codable struct — NOT a SwiftData model.
struct SupabaseDesireRating: Codable {
    let id: UUID
    let userId: UUID
    let desireItemId: String
    let rating: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case desireItemId = "desire_item_id"
        case rating
        case createdAt = "created_at"
    }
}

// MARK: - SupabaseDesireMatch DTO
struct SupabaseDesireMatch: Codable {
    let id: UUID
    let coupleId: UUID
    let desireItemId: String
    let alignmentLevel: String
    let partnerAValue: String?
    let partnerBValue: String?
    let gapSize: Int?
    let bridgeCardId: String?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case coupleId = "couple_id"
        case desireItemId = "desire_item_id"
        case alignmentLevel = "alignment_level"
        case partnerAValue = "partner_a_value"
        case partnerBValue = "partner_b_value"
        case gapSize = "gap_size"
        case bridgeCardId = "bridge_card_id"
        case createdAt = "created_at"
    }
}

// MARK: - Service

@MainActor
class DesireSyncService: ObservableObject {

    /// Shared singleton — access with DesireSyncService.shared
    static let shared = DesireSyncService()

    /// Reference to the Supabase client.
    private var supabase: SupabaseClient {
        SupabaseManager.shared.client
    }

    /// ISO 8601 formatter for converting Dates to Postgres-friendly strings.
    private let isoFormatter = ISO8601DateFormatter()

    private let profileService = ProfileService()

    // MARK: - Sync All Ratings

    /// Pushes all desire ratings for a user to Supabase in one batch.
    ///
    /// WHEN TO CALL:
    /// After the user completes the desire map during onboarding
    /// and all DesireRating objects have been saved to SwiftData.
    ///
    /// WHAT IT DOES:
    /// 1. Converts each local DesireRating into a SupabaseDesireRating
    /// 2. Sends them all to Supabase in one batch INSERT
    ///
    /// WHY BATCH INSERT?
    /// The desire map might have 30–50+ items. One HTTP request per rating
    /// would be painfully slow. Batch insert sends them all at once.
    ///
    /// - Parameters:
    ///   - ratings: Array of local SwiftData DesireRating objects
    ///   - authId: The authenticated user's UUID
    func syncRatings(_ ratings: [DesireRating], authId: UUID) async throws {
        _ = try await profileService.ensureProfileExists(authId: authId)

        // Convert local SwiftData models → Supabase Codable structs
        let supabaseRatings = ratings.map { rating in
            SupabaseDesireRating(
                id: rating.id,
                userId: authId,
                desireItemId: rating.desireItemId,
                rating: String(rating.rating.rawValue),                      // Rating enum → String
                createdAt: isoFormatter.string(from: rating.ratedAt)   // Date → String
            )
        }

        // Batch insert all ratings in one request
        try await supabase
            .from("desire_ratings")
            .insert(supabaseRatings)
            .execute()

        #if DEBUG
        print("✅ \(supabaseRatings.count) desire ratings synced to Supabase")
        #endif
    }
}
