//
//  CoupleCapacityService.swift
//  Vayl
//
//  Read path for the PARTNER's shared capacity tier (Task 1, pre-roll).
//
//  Only the scalar `capacity_score` is ever shared cross-partner — never the
//  Q1-Q5 answers, never the quadrant. RLS on `pulse_shared_capacity` already
//  gates the read: a partner's row is visible only when (a) it belongs to your
//  couple AND (b) that profile has `user_profiles.share_pulse_with_partner =
//  true`. So the query is simply "the row in my couple that isn't mine" — the
//  share opt-in is enforced server-side, not re-checked here.
//
//  nil return = no shared row (unpaired, partner hasn't opted in, or partner
//  hasn't checked in yet). The store treats nil as "not checked in," never as
//  an error.
//

import Foundation
import Supabase

// MARK: - Model

/// The one scalar a partner shares. `updatedAt` is when they last checked in.
struct PartnerCapacity {
    let capacityScore: Double
    let updatedAt: Date
}

// MARK: - Service protocol

/// Read-only access to the partner's shared capacity scalar.
/// nil = no shared row (see file header). Throws only on transport/decode failure.
protocol CoupleCapacityService {
    func fetchPartnerCapacity() async throws -> PartnerCapacity?
}

// MARK: - PulseCapacityColor banding

extension PulseCapacityColor {
    /// Bands a raw capacity score into a display tier. Higher = more capacity.
    ///
    /// TODO(pre-roll Task 1): these thresholds (0.25 / 0.50 / 0.75) are placeholders.
    /// Verify against the real `capacity_score` range produced by PulseAnswers
    /// (see PulseAnswers / PulsePosition.capacityScore) before relying on the
    /// banding for anything user-facing — the score may not be a clean 0…1.
    init(capacityScore s: Double) {
        switch s {
        case ..<0.25: self = .rose
        case ..<0.50: self = .magenta
        case ..<0.75: self = .indigo
        default:      self = .cyan
        }
    }
}

// MARK: - Supabase implementation

/// Reads the partner's `pulse_shared_capacity` row. Follows the exact
/// PulseSyncService pattern: resolve the caller's own profile (RLS scopes
/// user_profiles SELECT to the caller's row), then select the couple's OTHER
/// capacity row. RLS on `pulse_shared_capacity` enforces the share opt-in.
struct SupabaseCoupleCapacityService: CoupleCapacityService {

    private var supabase: SupabaseClient { SupabaseManager.shared.client }

    /// The caller's own profile id + couple — same shape/keys as PulseSyncService.
    private struct ProfileRow: Decodable {
        let id: UUID
        let coupleId: UUID?
        enum CodingKeys: String, CodingKey {
            case id
            case coupleId = "couple_id"
        }
    }

    private struct CapacityRow: Decodable {
        let profileId:     UUID
        let capacityScore: Double
        let updatedAt:     Date
        enum CodingKeys: String, CodingKey {
            case profileId     = "profile_id"
            case capacityScore = "capacity_score"
            case updatedAt     = "updated_at"
        }
    }

    /// RLS scopes user_profiles SELECT to the caller's own row.
    private func currentProfile() async -> ProfileRow? {
        let rows: [ProfileRow]? = try? await supabase
            .from("user_profiles")
            .select("id, couple_id")
            .execute()
            .value
        return rows?.first
    }

    func fetchPartnerCapacity() async throws -> PartnerCapacity? {
        guard let me = await currentProfile(), let coupleId = me.coupleId else {
            return nil // not paired → no partner row to read
        }

        // Select the couple's capacity rows that aren't mine. RLS already limits
        // this to the partner's row and only when they've opted into sharing, so
        // at most one row comes back.
        let rows: [CapacityRow] = try await supabase
            .from("pulse_shared_capacity")
            .select("profile_id, capacity_score, updated_at")
            .eq("couple_id", value: coupleId.uuidString)
            .neq("profile_id", value: me.id.uuidString)
            .execute()
            .value

        guard let partner = rows.first else { return nil }
        return PartnerCapacity(capacityScore: partner.capacityScore,
                               updatedAt: partner.updatedAt)
    }
}
