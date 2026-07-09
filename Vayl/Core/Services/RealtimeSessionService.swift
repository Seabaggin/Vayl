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

enum SessionRole: String, Codable, Sendable {
    case a
    case b

    var consentColumn: String { self == .a ? "a_consented" : "b_consented" }
    var presenceColumn: String { self == .a ? "a_present" : "b_present" }
    /// The seal flag this role owns inside a reveal_state per-card object.
    var sealedKey: String { self == .a ? "a_sealed" : "b_sealed" }
}

// MARK: - Draft (value snapshot of a SessionPlan — keeps SwiftData off this layer)

struct CuratedSessionDraft: Sendable {
    let deckId: String
    let deckVariant: String?
    let cardIds: [String]
    let perCardTimer: [String: Int]
    let globalTimerSeconds: Int?
}

// MARK: - RevealCardState (one card's flags inside curated_sessions.reveal_state)
// Shape on the wire (spec §6): {"card-07": {"a_sealed": true, "b_sealed": true, "revealed": true}}
// Absent flags mean false — the server only ever merges deltas in, so a card's
// object grows flag by flag. decodeIfPresent keeps partial objects valid.

struct RevealCardState: Codable, Sendable, Equatable {
    var aSealed: Bool
    var bSealed: Bool
    var revealed: Bool

    enum CodingKeys: String, CodingKey {
        case aSealed = "a_sealed"
        case bSealed = "b_sealed"
        case revealed
    }

    init(aSealed: Bool = false, bSealed: Bool = false, revealed: Bool = false) {
        self.aSealed = aSealed
        self.bSealed = bSealed
        self.revealed = revealed
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        aSealed  = try container.decodeIfPresent(Bool.self, forKey: .aSealed)  ?? false
        bSealed  = try container.decodeIfPresent(Bool.self, forKey: .bSealed)  ?? false
        revealed = try container.decodeIfPresent(Bool.self, forKey: .revealed) ?? false
    }

    /// Whether a given role has sealed this card.
    func sealed(for role: SessionRole) -> Bool {
        role == .a ? aSealed : bSealed
    }
}

// MARK: - DTO (one curated_sessions row)
// Timestamps decode as String to avoid date-strategy coupling; the player
// parses timer_started_at when it builds the timer.

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
    let revealState: [String: RevealCardState]
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
        case revealState = "reveal_state"
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

    #if DEBUG
    /// Simulator harness cleanup for repeated two-device runs. Production code
    /// should preserve active/paused sessions for reconnect instead of clearing
    /// them.
    func debugAbandonOpenSessions(coupleId: UUID) async throws {
        try await supabase
            .from(SupabaseTable.curatedSessions)
            .update(["status": CuratedSessionStatus.abandoned.rawValue])
            .eq("couple_id", value: coupleId.uuidString)
            .in("status", values: CuratedSessionStatus.openStatuses)
            .execute()
    }
    #endif

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

    // MARK: Timer + safety row ops (Section 2 scope; streams live in the extensions below)

    /// Stamps timer_started_at = now. Written by the role-a device when a timed
    /// card presents; the echoed UPDATE anchors both countdowns.
    func markTimerStarted(sessionId: UUID) async throws {
        try await supabase
            .from(SupabaseTable.curatedSessions)
            .update(["timer_started_at": ISO8601DateFormatter().string(from: Date())])
            .eq("id", value: sessionId.uuidString)
            .execute()
    }

    /// Replaces the per-card timer map ("keep going" removes one card's entry).
    /// Whole-map write: acceptable because only the tapping device writes it
    /// and the map is tiny; the echoed row is still the single truth.
    func setPerCardTimer(sessionId: UUID, timers: [String: Int]) async throws {
        try await supabase
            .from(SupabaseTable.curatedSessions)
            .update(["per_card_timer": timers])
            .eq("id", value: sessionId.uuidString)
            .execute()
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

// MARK: - Reveal state (merge-writes) + reveal broadcast
// Durable flags go through the update_reveal_state Postgres function — the
// client only ever sends its DELTA, the server deep-merges per card, so
// concurrent seals from both partners cannot clobber each other (spec §6).
// Ephemeral answer PAYLOADS ride Broadcast only and are never persisted.

extension RealtimeSessionService {

    private struct RevealStateParams: Encodable {
        let sessionId: UUID
        let delta: [String: [String: Bool]]

        enum CodingKeys: String, CodingKey {
            case sessionId = "p_session_id"
            case delta = "p_delta"
        }
    }

    /// Marks THIS role's seal flag on one card. Merge-write — never overwrites
    /// the partner's flag or sibling cards.
    func setSealed(sessionId: UUID, cardId: String, role: SessionRole) async throws {
        try await supabase
            .rpc("update_reveal_state", params: RevealStateParams(
                sessionId: sessionId,
                delta: [cardId: [role.sealedKey: true]]
            ))
            .execute()
    }

    /// Marks one card revealed (either device calls it after the countdown).
    func setRevealed(sessionId: UUID, cardId: String) async throws {
        try await supabase
            .rpc("update_reveal_state", params: RevealStateParams(
                sessionId: sessionId,
                delta: [cardId: ["revealed": true]]
            ))
            .execute()
    }

    /// Resets one card's flags (the reconnect re-prompt path: an in-flight
    /// broadcast answer was lost pre-reveal, so the card composes again).
    func clearRevealCard(sessionId: UUID, cardId: String) async throws {
        try await supabase
            .rpc("update_reveal_state", params: RevealStateParams(
                sessionId: sessionId,
                delta: [cardId: ["a_sealed": false, "b_sealed": false, "revealed": false]]
            ))
            .execute()
    }

    // MARK: Broadcast (ephemeral answer payloads + resend requests)

    /// Sends a sealed answer payload to the partner. Best-effort — the seal
    /// FLAG on the row is the durable authority; loss triggers the resend path.
    func sendReveal(_ envelope: RevealEnvelope, on channel: RealtimeChannelV2) async throws {
        try await channel.broadcast(event: BroadcastEvent.reveal, message: envelope)
    }

    /// Asks the partner to re-send their payload for one card (flag set on the
    /// row but the broadcast never arrived — RevealEngine's 5s watchdog).
    func requestResend(cardId: String, on channel: RealtimeChannelV2) async throws {
        try await channel.broadcast(event: BroadcastEvent.resend, message: ResendRequest(cardId: cardId))
    }

    /// Partner answer payloads arriving on the channel.
    /// SDK nesting (verified 2.48.0): broadcastStream yields the WHOLE message
    /// object; the Codable payload sits under its "payload" key.
    func revealBroadcasts(on channel: RealtimeChannelV2) -> AsyncStream<RevealEnvelope> {
        let raw = channel.broadcastStream(event: BroadcastEvent.reveal)
        return AsyncStream { continuation in
            let task = Task {
                for await message in raw {
                    guard let envelope = try? message["payload"]?.decode(as: RevealEnvelope.self) else {
                        logger.warning("reveal broadcast did not decode — ignored (resend path covers loss)")
                        continue
                    }
                    continuation.yield(envelope)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// Partner resend requests arriving on the channel.
    func resendRequests(on channel: RealtimeChannelV2) -> AsyncStream<String> {
        let raw = channel.broadcastStream(event: BroadcastEvent.resend)
        return AsyncStream { continuation in
            let task = Task {
                for await message in raw {
                    guard let request = try? message["payload"]?.decode(as: ResendRequest.self) else {
                        logger.warning("resend request did not decode — ignored")
                        continue
                    }
                    continuation.yield(request.cardId)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

// MARK: - Broadcast wire types

private enum BroadcastEvent {
    static let reveal = "reveal"
    static let resend = "reveal_resend"
}

struct ResendRequest: Codable, Sendable {
    let cardId: String
}

// MARK: - Typed presence delta

/// One presence change on the session channel, reduced to profile-id strings.
struct PresenceDelta: Sendable {
    let joinedIds: Set<String>
    let leftIds: Set<String>
}

// MARK: - Realtime streams + poll fallback + active-flip guard
// The CONSUMER registers all listeners BEFORE subscribeWithError() and tracks
// AFTER (the PresenceDebugStore-proven ordering). The service stays a pure
// factory + helpers.

extension RealtimeSessionService {

    /// Presence joins/leaves on the session channel, keyed by profile id.
    /// Register BEFORE subscribing.
    func presenceChanges(on channel: RealtimeChannelV2) -> AsyncStream<PresenceDelta> {
        let presence = channel.presenceChange()
        return AsyncStream { continuation in
            let task = Task {
                for await change in presence {
                    continuation.yield(PresenceDelta(
                        joinedIds: Set(change.joins.keys),
                        leftIds: Set(change.leaves.keys)
                    ))
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// Every UPDATE to THIS session row, decoded to the full DTO (including
    /// reveal_state — REPLICA IDENTITY FULL guarantees the whole post-image).
    /// Filtered by session id per spec §4.2. Register BEFORE subscribing.
    /// An UPDATE that fails to decode is logged and skipped — the consumer
    /// re-fetches on silence (the poll fallback proves reconstructability).
    func rowUpdates(on channel: RealtimeChannelV2, sessionId: UUID) -> AsyncStream<CuratedSessionDTO> {
        // Snake_case columns are handled by CuratedSessionDTO's explicit
        // CodingKeys, so a plain decoder is correct (no keyDecodingStrategy).
        let decoder = JSONDecoder()
        let changes = channel.postgresChange(
            UpdateAction.self,
            schema: "public",
            table: SupabaseTable.curatedSessions,
            filter: .eq("id", value: sessionId.uuidString)
        )
        return AsyncStream { continuation in
            let task = Task {
                for await change in changes {
                    guard let record = try? change.decodeRecord(
                        as: CuratedSessionDTO.self, decoder: decoder
                    ) else {
                        logger.warning("curated_sessions UPDATE did not decode — consumer should re-fetch")
                        continue
                    }
                    continuation.yield(record)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// Flips the row to `active` ONLY if it is still an open pre-active status
    /// (lobby/airlock) AND both partners are present AND both consented.
    /// Conditional on the server so a race between the two devices resolves to
    /// exactly one write. Returns true if THIS call performed the flip.
    /// Mirrors `advance(sessionId:expectedIndex:)`. (From plan 08, verified.)
    @discardableResult
    func flipToActiveIfBoth(sessionId: UUID) async throws -> Bool {
        let flipped: [CuratedSessionDTO] = try await supabase
            .from(SupabaseTable.curatedSessions)
            .update(["status": CuratedSessionStatus.active.rawValue])
            .eq("id", value: sessionId.uuidString)
            .in("status", values: [CuratedSessionStatus.lobby.rawValue,
                                   CuratedSessionStatus.airlock.rawValue])
            .eq("a_present", value: true)
            .eq("b_present", value: true)
            .eq("a_consented", value: true)
            .eq("b_consented", value: true)
            .select()
            .execute()
            .value

        return !flipped.isEmpty
    }

    /// Poll fallback tick (no realtime). Writes this device's presence
    /// heartbeat via the row, then reads the couple's open session back.
    /// Called on a timer by AirlockStore when realtime is unavailable.
    /// Modeled on PairingService.pollForClaim's re-fetch-per-tick shape but
    /// stateless — the loop lives in the Store. (From plan 08, verified.)
    func heartbeatOpenSession(coupleId: UUID, role: SessionRole) async throws -> CuratedSessionDTO? {
        if let open = try await fetchOpenSession(coupleId: coupleId) {
            try await setPresence(sessionId: open.id, role: role, present: true)
        }
        return try await fetchOpenSession(coupleId: coupleId)
    }
}
