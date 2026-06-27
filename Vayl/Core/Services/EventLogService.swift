//
//  EventLogService.swift
//  Vayl
//
//  Sync for the Event Log. Local SwiftData is the source of truth; this pushes entries
//  up (so they back up + shared entries reach the partner) and pulls down (so your own
//  entries restore on a new device and the partner's shared entries appear). RLS scopes
//  what `pull` returns: your own rows plus shared rows in your couple. Mirrors the
//  DesireSyncService client + DTO style.
//

import Foundation
import Supabase

struct EventLogUpsert: Encodable, Sendable {
    let id: String
    let author_id: String
    let couple_id: String?
    let occurred_on: String      // yyyy-MM-dd
    let title: String
    let note: String?
    let mood: String?
    let tags: [String]
    let who: String?
    let visibility: String
}

struct EventLogRow: Decodable, Identifiable, Sendable {
    let id: UUID
    let authorId: UUID
    let coupleId: UUID?
    let occurredOn: String       // yyyy-MM-dd
    let title: String
    let note: String?
    let mood: String?
    let tags: [String]
    let who: String?
    let visibility: String

    enum CodingKeys: String, CodingKey {
        case id, title, note, mood, tags, who, visibility
        case authorId = "author_id"
        case coupleId = "couple_id"
        case occurredOn = "occurred_on"
    }
}

@MainActor
final class EventLogService {

    private var supabase: SupabaseClient { SupabaseManager.shared.client }

    /// `date` column formatter — fixed, POSIX, so it round-trips regardless of locale.
    static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    func push(_ row: EventLogUpsert) async throws {
        try await supabase.from("event_log_entries").upsert([row], onConflict: "id").execute()
    }

    func delete(id: UUID) async throws {
        try await supabase.from("event_log_entries")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    /// RLS returns the caller's own entries plus shared entries in their couple.
    func pull() async throws -> [EventLogRow] {
        try await supabase.from("event_log_entries")
            .select("id, author_id, couple_id, occurred_on, title, note, mood, tags, who, visibility")
            .execute()
            .value
    }
}
