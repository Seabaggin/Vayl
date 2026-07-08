//
//  PulseSyncService.swift
//  Vayl
//
//  Full check-in history now syncs to `pulse_entries` — one row per day, keyed by
//  local calendar day (mirrors PulseStore.add()'s own day-level replace semantics).
//  This is the source of truth: PulseStore's UserDefaults cache is a fast local
//  mirror, not the origin, so a reinstall/device switch pulls history back down
//  via `fetchOwnEntries()`. `pulse_shared_capacity` itself is left in place,
//  untouched, and now unused.
//
//  Partner visibility is POSITION-ONLY, never the raw Q1-Q5 text answers — matches
//  the existing Settings promise ("Your partner sees your Pulse capacity, not your
//  answers.", SettingsPrivacyView.swift). `pulse_entries`' own RLS only ever grants
//  a caller their OWN rows; a partner's position data is read exclusively through
//  `get_partner_pulse_positions()`, a SECURITY DEFINER function that projects just
//  profile_id/entry_date/energy/openness/capacity_score and checks couple
//  membership + share_pulse_with_partner itself. Sharing on/off is owned by
//  Settings (SettingsPrivacyView -> SettingsStore -> SyncManager ->
//  ProfileService.updateSharePulse) — this file has no sharing-toggle methods of
//  its own; a second write path to the same column would just create drift.
//

import Foundation
import Supabase

/// Tri-state fetch outcome — lets a Store tell "the fetch failed, keep whatever
/// you have" apart from "the fetch succeeded and came back with zero rows"
/// (unpaired / sharing off / genuinely never logged). Optional collapsed both
/// into `nil`; this restores the distinction at the boundary so a Store can
/// signal a transient failure instead of quietly reading it as confirmed-empty.
enum PulseFetchOutcome {
    case success([PulseEntry])
    case failure
}

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

    private struct PulseEntryRow: Codable {
        let profileId:        UUID
        let coupleId:         UUID?
        let entryDate:        Date
        let firstCompletedAt: Date
        let energy:           Double
        let openness:         Double
        let capacityScore:    Double
        let nervousSystem:    String
        let focus:            String
        let feeling:          String
        let capacity:         String
        let speed:            String

        enum CodingKeys: String, CodingKey {
            case profileId        = "profile_id"
            case coupleId         = "couple_id"
            case entryDate        = "entry_date"
            case firstCompletedAt = "first_completed_at"
            case energy
            case openness
            case capacityScore = "capacity_score"
            case nervousSystem = "nervous_system"
            case focus, feeling, capacity, speed
        }

        var toPulseEntry: PulseEntry {
            let position = PulsePosition(energy: energy, openness: openness)
            return PulseEntry(
                date:          entryDate,
                capacityScore: capacityScore,
                glowColor:     position.quadrant.capacityColor,
                speed:         speed,
                nervousSystem: nervousSystem,
                focus:         focus,
                feeling:       feeling,
                capacity:      capacity,
                position:      position,
                createdAt:     firstCompletedAt
            )
        }
    }

    /// What `get_partner_pulse_positions()` returns — position + score only, no
    /// text. `toPulseEntry` fills the Q1-Q5 fields with empty placeholders since
    /// nothing ever renders them for a partner-sourced entry.
    private struct PartnerPositionRow: Decodable {
        let profileId:     UUID
        let entryDate:     Date
        let energy:        Double
        let openness:      Double
        let capacityScore: Double

        enum CodingKeys: String, CodingKey {
            case profileId     = "profile_id"
            case entryDate     = "entry_date"
            case energy, openness
            case capacityScore = "capacity_score"
        }

        var toPulseEntry: PulseEntry {
            let position = PulsePosition(energy: energy, openness: openness)
            return PulseEntry(
                date:          entryDate,
                capacityScore: capacityScore,
                glowColor:     position.quadrant.capacityColor,
                speed:         "",
                nervousSystem: "",
                focus:         "",
                feeling:       "",
                capacity:      nil,
                position:      position
            )
        }
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

    // MARK: - Full entry history

    /// Pushes one check-in as a full row, replacing any existing row for the SAME
    /// local calendar day (mirrors PulseStore.add()'s own day-level replace — a
    /// second check-in on the same day overwrites, it doesn't accumulate). Delete-
    /// then-insert rather than a DB-level upsert: "same day" is a local-timezone
    /// concept (Calendar.current), which doesn't map cleanly onto a timestamptz
    /// unique constraint. Fire-and-forget from the check-in; local save is already
    /// the source of truth for THIS session, this just keeps the server in sync.
    func pushEntry(_ entry: PulseEntry) async {
        guard let profile = await currentProfile() else { return }

        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: entry.date)
        guard let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart) else { return }
        let iso = ISO8601DateFormatter()

        _ = try? await supabase
            .from("pulse_entries")
            .delete()
            .eq("profile_id", value: profile.id.uuidString)
            .gte("entry_date", value: iso.string(from: dayStart))
            .lt("entry_date", value: iso.string(from: dayEnd))
            .execute()

        let position = entry.resolvedPosition
        let row = PulseEntryRow(
            profileId:        profile.id,
            coupleId:         profile.coupleId,
            entryDate:        entry.date,
            firstCompletedAt: entry.resolvedCreatedAt,
            energy:           position.energy,
            openness:         position.openness,
            capacityScore:    entry.capacityScore,
            nervousSystem:    entry.nervousSystem,
            focus:            entry.focus,
            feeling:          entry.feeling,
            capacity:         entry.capacity ?? "",
            speed:            entry.speed
        )
        _ = try? await supabase
            .from("pulse_entries")
            .insert(row)
            .execute()
    }

    /// The caller's own full history, oldest first — used to hydrate the local
    /// cache on launch (the "reinstall/new device" recovery path). `.failure` on
    /// any failure (offline, not signed in) — callers should treat `.failure` as
    /// "keep whatever's already local," never as "history is empty."
    func fetchOwnEntries() async -> PulseFetchOutcome {
        guard let profile = await currentProfile() else { return .failure }
        do {
            let rows: [PulseEntryRow] = try await supabase
                .from("pulse_entries")
                .select()
                .eq("profile_id", value: profile.id.uuidString)
                .order("entry_date", ascending: true)
                .execute()
                .value
            return .success(rows.map(\.toPulseEntry))
        } catch {
            return .failure
        }
    }

    /// The partner's history as bare positions (never the Q1-Q5 text answers),
    /// oldest first. `.success([])` covers not paired, not shared, or not yet
    /// logged (the function returns zero rows in those cases, not an error) —
    /// only a genuine RPC/network failure returns `.failure`, so callers can
    /// finally tell "confirmed no data" apart from "couldn't reach it." The
    /// returned PulseEntry's text fields are empty placeholders; nothing renders
    /// them for a partner entry (the Us layer only ever reads .resolvedPosition.quadrant).
    func fetchPartnerEntries() async -> PulseFetchOutcome {
        do {
            let rows: [PartnerPositionRow] = try await supabase
                .rpc("get_partner_pulse_positions")
                .execute()
                .value
            return .success(rows.sorted { $0.entryDate < $1.entryDate }.map(\.toPulseEntry))
        } catch {
            return .failure
        }
    }
}
