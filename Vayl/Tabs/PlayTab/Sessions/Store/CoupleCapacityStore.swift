//
//  CoupleCapacityStore.swift
//  Vayl
//
//  Owns the partner's shared-capacity read state for the session lane (Task 1,
//  read path only — nothing here writes capacity or touches the check-in flow).
//
//  Reads the partner's scalar via CoupleCapacityService, bands it into a
//  PulseCapacityColor tier, and exposes a "partner hasn't checked in" signal for
//  the absent case. Any error collapses to the same not-checked-in state — a
//  transient fetch failure should read as "no data yet," never surface as an
//  error to a session view.
//

import Foundation

@Observable
@MainActor
final class CoupleCapacityStore {

    /// The partner's banded capacity tier, or nil when there's no shared row.
    private(set) var partnerTier: PulseCapacityColor?

    /// True when there is no partner capacity to show (unpaired, not opted in,
    /// not yet checked in, or a fetch failure). Distinct from `partnerTier == nil`
    /// only in intent — this is the flag a view reads to render the empty state.
    private(set) var partnerNotCheckedIn = false

    private let service: CoupleCapacityService

    /// `service` nil-resolves inside the MainActor-isolated body to the real
    /// Supabase implementation — so Views can construct the store without
    /// touching the Service layer; tests keep injecting their mock.
    init(service: CoupleCapacityService? = nil) {
        self.service = service ?? SupabaseCoupleCapacityService()
    }

    /// Loads the partner's capacity tier. Idempotent; safe to call on appear.
    func load() async {
        do {
            if let cap = try await service.fetchPartnerCapacity() {
                partnerTier = PulseCapacityColor(capacityScore: cap.capacityScore)
                partnerNotCheckedIn = false
            } else {
                partnerTier = nil
                partnerNotCheckedIn = true
            }
        } catch {
            partnerTier = nil
            partnerNotCheckedIn = true
        }
    }
}
