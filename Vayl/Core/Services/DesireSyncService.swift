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

/// Value snapshot of a `DesireMapEntry`, taken on the main actor BEFORE any await so we
/// never touch a SwiftData `@Model` across a suspension point. ALL weights sync (incl.
/// `notForMe`) — boundaries are obscured at the reveal layer (edge fn), not withheld here.
struct PendingDesireRating: Sendable {
    let id: UUID
    let itemId: String
    let rating: DesireRatingValue
    let completedAt: Date

    init(_ entry: DesireMapEntry) {
        self.id = entry.id
        self.itemId = entry.itemId
        self.rating = entry.rating
        self.completedAt = entry.completedAt
    }
}

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

// MARK: - Service

@MainActor
class DesireSyncService {

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
    func syncRatings(_ ratings: [PendingDesireRating]) async throws {
        guard !ratings.isEmpty else { return }

        // desire_ratings.user_id is a FK to user_profiles.id — use the PROFILE id, not the auth uid.
        let authId = try await supabase.auth.session.user.id
        let profileId = try await profileService.ensureProfileExists(authId: authId)

        let rows = ratings.map { r in
            SupabaseDesireRating(
                id: r.id,
                userId: profileId,
                desireItemId: r.itemId,
                rating: r.rating.rawValue,
                createdAt: isoFormatter.string(from: r.completedAt)
            )
        }

        // Upsert on (user_id, desire_item_id) so re-rating updates in place.
        try await supabase
            .from("desire_ratings")
            .upsert(rows, onConflict: "user_id,desire_item_id")
            .execute()

        #if DEBUG
        print("✅ \(rows.count) desire ratings upserted to Supabase")
        #endif
    }

    // MARK: - Compute Matches (D3)

    /// Invokes the `compute-desire-matches` edge function: marks the caller's side complete and,
    /// if BOTH partners are done, computes `desire_matches` server-side. `isFreeReveal` is set by
    /// the function only (never the client). Call after ratings have synced.
    @discardableResult
    func computeMatches() async throws -> ComputeMatchesResponse {
        let response: ComputeMatchesResponse = try await supabase.functions.invoke(
            "compute-desire-matches",
            options: FunctionInvokeOptions()
        )
        return response
    }

    // MARK: - Read back (D-read)

    /// Reads the couple's computed matches. Selects ONLY client-safe columns — never
    /// `partner_a/b_value` (the partner's raw answer is never shown). RLS scopes to the couple.
    func fetchMatches(coupleId: UUID) async throws -> [DesireMatchRow] {
        try await supabase
            .from("desire_matches")
            .select("id, desire_item_id, alignment_level, is_free_reveal, bridge_card_id")
            .eq("couple_id", value: coupleId.uuidString)
            .execute()
            .value
    }

    /// Reads the couple's completion / reveal status, or nil if neither partner has finished.
    func fetchStatus(coupleId: UUID) async throws -> DesireMapStatusRow? {
        let rows: [DesireMapStatusRow] = try await supabase
            .from("desire_map_status")
            .select("track, partner_a_complete, partner_b_complete")
            .eq("couple_id", value: coupleId.uuidString)
            .execute()
            .value
        return rows.first
    }

    // MARK: - Reveal progress (per-user "Seen"; own-user RLS)

    /// This user's reveal viewing state for the couple, or nil if they have not opened it yet.
    func fetchRevealProgress(coupleId: UUID) async throws -> RevealProgressRow? {
        let authId = try await supabase.auth.session.user.id
        let profileId = try await profileService.ensureProfileExists(authId: authId)
        let rows: [RevealProgressRow] = try await supabase
            .from("desire_reveal_progress")
            .select("free_reveal_seen_at, full_reveal_seen_at")
            .eq("user_id", value: profileId.uuidString)
            .eq("couple_id", value: coupleId.uuidString)
            .execute()
            .value
        return rows.first
    }

    /// Stamp that this user watched the reveal. `full == false` stamps the free reveal;
    /// `full == true` stamps the post-unlock full reveal. Upsert on (user_id, couple_id);
    /// only the named column is written, so stamping one never clears the other.
    func markRevealSeen(coupleId: UUID, full: Bool) async throws {
        let authId = try await supabase.auth.session.user.id
        let profileId = try await profileService.ensureProfileExists(authId: authId)
        let now = isoFormatter.string(from: Date())
        var row: [String: String] = [
            "user_id": profileId.uuidString,
            "couple_id": coupleId.uuidString,
            "updated_at": now,
        ]
        row[full ? "full_reveal_seen_at" : "free_reveal_seen_at"] = now
        try await supabase
            .from("desire_reveal_progress")
            .upsert(row, onConflict: "user_id,couple_id")
            .execute()
    }
}

/// One computed match, client-safe — NO partner raw values (the edge fn stores them null).
struct DesireMatchRow: Decodable, Identifiable, Sendable {
    let id: UUID
    let desireItemId: String
    let alignmentLevel: String     // "mutual" | "adjacent"
    let isFreeReveal: Bool
    let bridgeCardId: String?

    enum CodingKeys: String, CodingKey {
        case id
        case desireItemId = "desire_item_id"
        case alignmentLevel = "alignment_level"
        case isFreeReveal = "is_free_reveal"
        case bridgeCardId = "bridge_card_id"
    }

    var matchType: DesireMatchType? { DesireMatchType(rawValue: alignmentLevel) }
}

/// The couple's completion + reveal state, client-safe.
struct DesireMapStatusRow: Decodable, Sendable {
    let track: String?
    let partnerAComplete: Bool
    let partnerBComplete: Bool

    enum CodingKeys: String, CodingKey {
        case track
        case partnerAComplete = "partner_a_complete"
        case partnerBComplete = "partner_b_complete"
    }

    var bothComplete: Bool { partnerAComplete && partnerBComplete }
}

/// Result of the `compute-desire-matches` edge function.
struct ComputeMatchesResponse: Decodable {
    let status: String       // "waiting" | "computed" | "unpaired"
    let track: String?
    let matchCount: Int?
}

/// This user's reveal viewing state, client-safe (own row only).
struct RevealProgressRow: Decodable, Sendable {
    let freeRevealSeenAt: String?
    let fullRevealSeenAt: String?

    enum CodingKeys: String, CodingKey {
        case freeRevealSeenAt = "free_reveal_seen_at"
        case fullRevealSeenAt = "full_reveal_seen_at"
    }

    var hasSeenFree: Bool { freeRevealSeenAt != nil }
    var hasSeenFull: Bool { fullRevealSeenAt != nil }
}
