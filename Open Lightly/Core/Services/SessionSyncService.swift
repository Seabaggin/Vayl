//
//  SupabaseCoupleSessionRecord.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/10/26.
//


//
//  SessionSyncService.swift
//  Open Lightly
//
//  Created in Batch 10 — Session Recording Sync
//
//  PURPOSE:
//  Pushes completed session records from SwiftData to Supabase
//  after each couple session ends (or is paused/resumed).
//
//  TABLE: `couple_session_records`
//  Each row = one session between a couple, tracking which cards
//  were discussed, which were skipped, timing, and metadata.
//
//  WHEN DOES A SESSION GET SYNCED?
//  - When the session status changes to .completed
//  - When the session is paused (partial sync for resume on other device)
//  - When safe word is used (session ends immediately)
//
//  NOTE ABOUT COUPLE ID:
//  Sessions are owned by a Couple, not a User. The coupleId comes
//  from the local Couple model (which was created during pairing
//  in Batch 9). If the user is in Solo mode, sessions are tracked
//  locally only and NOT synced to Supabase.
//
//  SAME PATTERN:
//  1. SwiftData saves the session locally (instant)
//  2. This service pushes to Supabase (async, might fail)
//  3. If push fails → SyncManager flags for retry
//

import Foundation
import Supabase
import Combine

// MARK: - Supabase DTO

/// Maps one session record to the `couple_session_records` table in Supabase.
/// Plain Codable struct — NOT a SwiftData model.
struct SupabaseCoupleSessionRecord: Codable {

    /// Auto-generated UUID (matches local CoupleSessionRecord.id)
    let id: UUID

    /// The couple's UUID — links this session to a specific couple.
    /// Foreign key to couples.id in Supabase.
    let coupleId: UUID

    /// Which content category this session covered (e.g. "communication").
    let categoryId: String

    /// The lifecycle state: "notStarted", "inProgress", "paused", "completed".
    /// Stored as the raw string value of your SessionStatus enum.
    let status: String

    /// Ordered list of card IDs that were discussed during this session.
    /// Stored as a Postgres text[] (array) or JSONB.
    let cardIdsDiscussed: [String]

    /// Card IDs the couple chose to skip.
    let cardIdsSkipped: [String]

    /// If paused/in-progress: which card is currently being displayed.
    /// Nil if the session is completed.
    let currentCardId: String?

    /// If paused: whose turn it is ("partnerA" or "partnerB").
    /// Nil if session is completed or not yet started.
    let currentTurn: String?

    /// Whether the safe word was invoked during this session.
    /// If true, the session ended early by design.
    let safeWordUsed: Bool

    /// Total session duration in seconds.
    let durationSeconds: Int

    /// When the session was started. Nil if status is still "notStarted".
    let startedAt: String?   // ISO 8601 string

    /// When the session was completed. Nil if not yet finished.
    let completedAt: String?  // ISO 8601 string

    /// Maps Swift camelCase → Postgres snake_case column names.
    enum CodingKeys: String, CodingKey {
        case id
        case coupleId = "couple_id"
        case categoryId = "category_id"
        case status
        case cardIdsDiscussed = "card_ids_discussed"
        case cardIdsSkipped = "card_ids_skipped"
        case currentCardId = "current_card_id"
        case currentTurn = "current_turn"
        case safeWordUsed = "safe_word_used"
        case durationSeconds = "duration_seconds"
        case startedAt = "started_at"
        case completedAt = "completed_at"
    }
}

// MARK: - Service

@MainActor
class SessionSyncService: ObservableObject {

    /// Shared singleton — access with SessionSyncService.shared
    static let shared = SessionSyncService()

    /// Reference to the Supabase client.
    private var supabase: SupabaseClient {
        SupabaseManager.shared.client
    }

    /// ISO 8601 formatter for Date → String conversion.
    private let isoFormatter = ISO8601DateFormatter()

    // MARK: - Helper: Convert Optional Date

    /// Safely converts an optional Date to an optional ISO 8601 string.
    /// Returns nil if the input date is nil (Supabase stores as NULL).
    private func isoString(from date: Date?) -> String? {
        guard let date = date else { return nil }
        return isoFormatter.string(from: date)
    }
}
