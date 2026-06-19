//
//  RealtimeSessionService.swift
//  Vayl
//
//  Transport for the two-device Curated Session. Pure data access over Supabase —
//  no UI, no Store/AppState references, no SwiftData. Mirrors PairingService.
//
//  Phase A3: row CRUD only. The realtime channel (presence / postgres-changes /
//  broadcast) and the poll-fallback loop arrive in Phase B.
//

import Foundation
import Supabase
import OSLog

private let logger = Logger(subsystem: "com.vayl.app", category: "RealtimeSessionService")

private enum SupabaseTable {
    static let curatedSessions = "curated_sessions"
}

// MARK: - Status

enum CuratedSessionStatus: String, Codable, Sendable {
    case lobby, airlock, active, paused, complete, abandoned

    /// Statuses that count as an OPEN session (matches the partial unique index).
    static let openStatuses: [String] = [
        CuratedSessionStatus.lobby.rawValue,
        CuratedSessionStatus.airlock.rawValue,
        CuratedSessionStatus.active.rawValue,
        CuratedSessionStatus.paused.rawValue
    ]
}

// MARK: - Role (which partner slot to write)

enum SessionRole: String, Sendable {
    case a
    case b

    var bandwidthColumn: String { self == .a ? "a_bandwidth" : "b_bandwidth" }
    var consentColumn: String   { self == .a ? "a_consented" : "b_consented" }
    var presenceColumn: String  { self == .a ? "a_present" : "b_present" }
}

// MARK: - Draft (value snapshot of a SessionPlan — keeps SwiftData off this layer)

struct CuratedSessionDraft: Sendable {
    let deckId: String
    let deckVariant: String?
    let cardIds: [String]
    let perCardTimer: [String: Int]
    let globalTimerSeconds: Int?
}

// MARK: - DTO (one curated_sessions row)
// reveal_state (jsonb) is intentionally omitted until Phase D needs it — Codable
// ignores columns not listed in CodingKeys. Timestamps decode as String to avoid
// date-strategy coupling; Phase D parses timer_started_at when it builds the timer.

struct CuratedSessionDTO: Codable, Identifiable, Sendable {
    let id: UUID
    let coupleId: UUID
    let initiatorId: UUID
    let deckId: String
    let deckVariant: String?
    let cardIds: [String]
    let perCardTimer: [String: Int]
    let globalTimerSeconds: Int?
    let status: String
    let currentIndex: Int
    let aPresent: Bool
    let bPresent: Bool
    let aBandwidth: Float?
    let bBandwidth: Float?
    let aConsented: Bool
    let bConsented: Bool
    let timerStartedAt: String?
    let safeWordUsed: Bool
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case coupleId = "couple_id"
        case initiatorId = "initiator_id"
        case deckId = "deck_id"
        case deckVariant = "deck_variant"
        case cardIds = "card_ids"
        case perCardTimer = "per_card_timer"
        case globalTimerSeconds = "global_timer_seconds"
        case status
        case currentIndex = "current_index"
        case aPresent = "a_present"
        case bPresent = "b_present"
        case aBandwidth = "a_bandwidth"
        case bBandwidth = "b_bandwidth"
        case aConsented = "a_consented"
        case bConsented = "b_consented"
        case timerStartedAt = "timer_started_at"
        case safeWordUsed = "safe_word_used"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Insert payload (only settable columns)

private struct NewCuratedSession: Encodable {
    let coupleId: String
    let initiatorId: String
    let deckId: String
    let deckVariant: String?
    let cardIds: [String]
    let perCardTimer: [String: Int]
    let globalTimerSeconds: Int?
    let status: String

    enum CodingKeys: String, CodingKey {
        case coupleId = "couple_id"
        case initiatorId = "initiator_id"
        case deckId = "deck_id"
        case deckVariant = "deck_variant"
        case cardIds = "card_ids"
        case perCardTimer = "per_card_timer"
        case globalTimerSeconds = "global_timer_seconds"
        case status
    }
}

// MARK: - RealtimeSessionService

/// Pure data access for the curated_sessions table.
/// No UI knowledge, no state ownership. async/await only — errors rethrown.
final class RealtimeSessionService {

    private let supabase: SupabaseClient

    init(supabase: SupabaseClient = SupabaseManager.shared.client) {
        self.supabase = supabase
    }

    // MARK: Open / Fetch

    /// Creates a new `lobby` session row from a plan snapshot. Returns the created row.
    func openSession(
        coupleId: UUID,
        initiatorId: UUID,
        draft: CuratedSessionDraft
    ) async throws -> CuratedSessionDTO {
        let payload = NewCuratedSession(
            coupleId: coupleId.uuidString,
            initiatorId: initiatorId.uuidString,
            deckId: draft.deckId,
            deckVariant: draft.deckVariant,
            cardIds: draft.cardIds,
            perCardTimer: draft.perCardTimer,
            globalTimerSeconds: draft.globalTimerSeconds,
            status: CuratedSessionStatus.lobby.rawValue
        )

        let created: CuratedSessionDTO = try await supabase
            .from(SupabaseTable.curatedSessions)
            .insert(payload)
            .select()
            .single()
            .execute()
            .value

        logger.info("Opened session \(created.id) for couple \(coupleId)")
        return created
    }

    /// Returns the couple's current OPEN session (lobby/airlock/active/paused), if any.
    func fetchOpenSession(coupleId: UUID) async throws -> CuratedSessionDTO? {
        let rows: [CuratedSessionDTO] = try await supabase
            .from(SupabaseTable.curatedSessions)
            .select()
            .eq("couple_id", value: coupleId.uuidString)
            .in("status", values: CuratedSessionStatus.openStatuses)
            .order("created_at", ascending: false)
            .limit(1)
            .execute()
            .value

        return rows.first
    }

    /// Convenience: the couple id this profile belongs to, if any.
    /// (Used by the debug harness to resolve a manually-seeded test couple.)
    func fetchCoupleId(forProfileId profileId: UUID) async throws -> UUID? {
        struct CoupleIdRow: Decodable { let id: UUID }
        let rows: [CoupleIdRow] = try await supabase
            .from("couples")
            .select("id")
            .or("user_a.eq.\(profileId.uuidString),user_b.eq.\(profileId.uuidString)")
            .limit(1)
            .execute()
            .value
        return rows.first?.id
    }

    // MARK: Airlock mutators (one column each)

    func setBandwidth(sessionId: UUID, role: SessionRole, value: Float) async throws {
        try await supabase
            .from(SupabaseTable.curatedSessions)
            .update([role.bandwidthColumn: value])
            .eq("id", value: sessionId.uuidString)
            .execute()
    }

    func setConsent(sessionId: UUID, role: SessionRole, consented: Bool = true) async throws {
        try await supabase
            .from(SupabaseTable.curatedSessions)
            .update([role.consentColumn: consented])
            .eq("id", value: sessionId.uuidString)
            .execute()
    }

    func setPresence(sessionId: UUID, role: SessionRole, present: Bool) async throws {
        try await supabase
            .from(SupabaseTable.curatedSessions)
            .update([role.presenceColumn: present])
            .eq("id", value: sessionId.uuidString)
            .execute()
    }

    func setStatus(sessionId: UUID, status: CuratedSessionStatus) async throws {
        try await supabase
            .from(SupabaseTable.curatedSessions)
            .update(["status": status.rawValue])
            .eq("id", value: sessionId.uuidString)
            .execute()
    }

    // MARK: Advance (server-authoritative, conditional — prevents double-advance)

    /// Advances only if `current_index` still equals `expectedIndex`.
    /// Returns true if this call moved the pointer, false if the partner already did.
    @discardableResult
    func advance(sessionId: UUID, expectedIndex: Int) async throws -> Bool {
        let updated: [CuratedSessionDTO] = try await supabase
            .from(SupabaseTable.curatedSessions)
            .update(["current_index": expectedIndex + 1])
            .eq("id", value: sessionId.uuidString)
            .eq("current_index", value: expectedIndex)
            .select()
            .execute()
            .value

        return !updated.isEmpty
    }
}

// MARK: - SessionPresence
// The state each device announces on the channel. The presence KEY is the
// userId (set on the channel config below), so joins/leaves are keyed by user.

struct SessionPresence: Codable, Sendable {
    let userId: String
}

// MARK: - Realtime: presence (B1)
// B1 adds ONLY presence ("both here"). Postgres-changes (B2) and broadcast
// (B3/D) come later. The channel lifecycle (register listeners -> subscribe ->
// track) is orchestrated by the CONSUMER (the debug harness now, AirlockStore in
// B3) because that layer owns state. The service stays a pure factory + helpers.

extension RealtimeSessionService {

    /// Builds — does NOT subscribe — the couple's realtime channel, keyed by this
    /// user so presence joins/leaves are identifiable. The caller must register
    /// listeners (e.g. `presenceChange()`) BEFORE calling `subscribeWithError()`,
    /// and `track` only AFTER it is subscribed.
    func sessionChannel(coupleId: UUID, userId: UUID) -> RealtimeChannelV2 {
        supabase.channel("session:\(coupleId.uuidString)") { config in
            config.presence.key = userId.uuidString
        }
    }

    /// Announce this user as present. Call ONLY after the channel is subscribed.
    func trackPresence(on channel: RealtimeChannelV2, userId: UUID) async throws {
        try await channel.track(SessionPresence(userId: userId.uuidString))
    }

    /// Stop announcing and leave the channel (untrack + unsubscribe + remove).
    func leaveChannel(_ channel: RealtimeChannelV2) async {
        await channel.untrack()
        await supabase.removeChannel(channel)
    }
}
