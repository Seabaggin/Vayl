//
//  SessionSyncService.swift
//  Vayl
//
//  Handles asynchronous syncing of completed Card Sessions to Supabase.
//

import Foundation
import Supabase
import OSLog

private let logger = Logger(
    subsystem: "com.vayl.app",
    category: "SessionSyncService"
)

struct SessionRecordPayload: Codable {
    let id: UUID
    let coupleId: UUID
    /// JSON content deck id — lets a device that never wrote its own local row
    /// (partner's finishes, fresh installs) still render the entry. Optional:
    /// rows written before 2026-07-15 predate the column.
    let deckId: String?
    let startedAt: Date
    let endedAt: Date?
    let cardsDiscussed: Int

    enum CodingKeys: String, CodingKey {
        case id
        case coupleId = "couple_id"
        case deckId = "deck_id"
        case startedAt = "started_at"
        case endedAt = "ended_at"
        case cardsDiscussed = "cards_discussed"
    }
}

final class SessionSyncService {
    static let shared = SessionSyncService()
    private let supabase = SupabaseManager.shared.client

    /// Pushes a completed session payload to the remote `couple_session_records` table.
    func pushSession(payload: Data) async throws {
        guard let sessionData = try? JSONDecoder().decode(SessionRecordPayload.self, from: payload) else {
            logger.error("Failed to decode session payload")
            throw URLError(.cannotDecodeRawData)
        }

        try await supabase
            .from("couple_session_records")
            .upsert(sessionData)
            .execute()

        logger.info("Successfully synced session record: \(sessionData.id)")
    }

    /// Fetches the couple's shared session history — the record BOTH devices
    /// upsert into (server-side additive merge), so both partners' Record
    /// screens agree regardless of which device wrote what locally.
    func fetchSessions(coupleId: UUID) async throws -> [SessionRecordPayload] {
        try await supabase
            .from("couple_session_records")
            .select("id,couple_id,deck_id,started_at,ended_at,cards_discussed")
            .eq("couple_id", value: coupleId.uuidString)
            .order("started_at", ascending: false)
            .limit(50)
            .execute()
            .value
    }
}
