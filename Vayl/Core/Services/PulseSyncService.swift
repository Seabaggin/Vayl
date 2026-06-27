//
//  PulseSyncService.swift
//  Vayl
//
//  Couples share CURRENT capacity (toggleable, on by default). This service
//  broadcasts the signed-in user's latest capacity to `pulse_shared_capacity`
//  (when sharing is on), reads the partner's current capacity, and flips the
//  share preference. The full pulse history stays device-local — only the single
//  current-capacity number is ever sent, and only the partner (same couple, if
//  the owner shares) can read it (enforced by RLS).
//

import Foundation
import Supabase

struct PulseSyncService {

    static let shared = PulseSyncService()

    private var supabase: SupabaseClient { SupabaseManager.shared.client }

    // The signed-in user's profile id + couple + share preference.
    private struct ProfileRow: Decodable {
        let id: UUID
        let coupleId: UUID?
        let sharePulseWithPartner: Bool
        enum CodingKeys: String, CodingKey {
            case id
            case coupleId = "couple_id"
            case sharePulseWithPartner = "share_pulse_with_partner"
        }
    }

    private struct CapacityRow: Decodable {
        let profileId: UUID
        let capacityScore: Double
        enum CodingKeys: String, CodingKey {
            case profileId = "profile_id"
            case capacityScore = "capacity_score"
        }
    }

    private struct CapacityUpsert: Encodable {
        let profile_id: String
        let couple_id: String?
        let capacity_score: Double
    }

    /// RLS scopes user_profiles SELECT to the caller's own row.
    private func currentProfile() async -> ProfileRow? {
        let rows: [ProfileRow]? = try? await supabase
            .from("user_profiles")
            .select("id, couple_id, share_pulse_with_partner")
            .execute()
            .value
        return rows?.first
    }

    /// Broadcast the latest capacity when sharing is on; clear it when off so
    /// nothing lingers server-side. Fire-and-forget from the check-in.
    func pushCurrentCapacity(score: Double) async {
        guard let profile = await currentProfile() else { return }

        if profile.sharePulseWithPartner {
            let row = CapacityUpsert(
                profile_id: profile.id.uuidString,
                couple_id: profile.coupleId?.uuidString,
                capacity_score: score
            )
            _ = try? await supabase
                .from("pulse_shared_capacity")
                .upsert(row, onConflict: "profile_id")
                .execute()
        } else {
            _ = try? await supabase
                .from("pulse_shared_capacity")
                .delete()
                .eq("profile_id", value: profile.id.uuidString)
                .execute()
        }
    }

    /// The partner's current capacity score, or nil (not paired / not shared /
    /// not yet logged). RLS returns only rows the caller may see.
    func fetchPartnerCapacity() async -> Double? {
        guard let profile = await currentProfile() else { return nil }
        let rows: [CapacityRow]? = try? await supabase
            .from("pulse_shared_capacity")
            .select("profile_id, capacity_score")
            .execute()
            .value
        // RLS yields own + partner's (if shared); the partner's is the one that
        // isn't ours.
        return rows?.first(where: { $0.profileId != profile.id })?.capacityScore
    }

    /// The current share preference (defaults true — on by default).
    func fetchSharing() async -> Bool {
        (await currentProfile())?.sharePulseWithPartner ?? true
    }

    /// Toggle the share preference. Turning it off also clears the broadcast row.
    func setSharing(_ enabled: Bool) async {
        guard let profile = await currentProfile() else { return }
        _ = try? await supabase
            .from("user_profiles")
            .update(["share_pulse_with_partner": enabled])
            .eq("id", value: profile.id.uuidString)
            .execute()
        if !enabled {
            _ = try? await supabase
                .from("pulse_shared_capacity")
                .delete()
                .eq("profile_id", value: profile.id.uuidString)
                .execute()
        }
    }
}
