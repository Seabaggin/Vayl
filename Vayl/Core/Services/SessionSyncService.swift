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
    let startedAt: Date
    let endedAt: Date?
    let cardsDiscussed: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case coupleId = "couple_id"
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
}
