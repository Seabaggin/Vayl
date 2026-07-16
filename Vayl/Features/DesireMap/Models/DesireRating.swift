//
//  DesireMapEntry.swift
//  Vayl
//

import Foundation
import SwiftData

// MARK: - DesireMapEntry
// One person's private rating for a single Desire Map item.
//
// PRIVACY: matches the ratified "sync-all, obscure at the match layer" posture
// (see DesireRatingValue in AppDesireEnums). userId is PRIVATE and never shown to
// the partner. All four weights sync to desire_ratings, INCLUDING notForMe. The
// boundary is enforced partner-vs-partner, not by withholding at upload:
//   1. Supabase RLS: a partner can never query your desire_ratings, ever.
//   2. Edge function: notForMe is excluded from desire_matches, so it never
//      surfaces in the shared reveal.
// The old "notForMe never leaves the device" model is retired.

@Model
final class DesireMapEntry {

    // MARK: - Identity

    var id: UUID
    var userId: UUID            // PRIVATE — never crosses to partner
    var itemId: String          // one of 17 canonical item IDs
    var rating: DesireRatingValue
    var completedAt: Date

    // MARK: - Init

    init(userId: UUID, itemId: String, rating: DesireRatingValue) {
        self.id = UUID()
        self.userId = userId
        self.itemId = itemId
        self.rating = rating
        self.completedAt = Date()
    }

}

// MARK: - DesireMapStatus
// Tracks completion state per couple — NOT individual ratings.
// Both partners can read the partnerXComplete booleans.
// Neither partner can ever read the other's DesireMapEntry records.
// waitingStateSince is stored explicitly — never derived from completion dates.

@Model
final class DesireMapStatus {

    // MARK: - Identity

    var id: UUID
    var coupleId: UUID

    // MARK: - Completion State

    var partnerAComplete: Bool
    var partnerBComplete: Bool
    var partnerACompletedAt: Date?
    var partnerBCompletedAt: Date?

    // MARK: - Waiting State
    // Reveal/unlock state is NOT mirrored here: Available = bothComplete (above),
    // Unlocked = couples.access_tier (EntitlementStore), Seen = desire_reveal_progress.

    var waitingStateSince: Date?    // set when first partner completes — powers 7-day timer

    // MARK: - Computed

    var bothComplete: Bool {
        partnerAComplete && partnerBComplete
    }

    var waitingForPartner: Bool {
        partnerAComplete != partnerBComplete
    }

    // MARK: - Init

    init(coupleId: UUID) {
        self.id = UUID()
        self.coupleId = coupleId
        self.partnerAComplete = false
        self.partnerBComplete = false
        self.partnerACompletedAt = nil
        self.partnerBCompletedAt = nil
        self.waitingStateSince = nil
    }

    // MARK: - Preview Helpers

    @MainActor static let example = DesireMapStatus(coupleId: UUID())

    @MainActor static let waitingExample: DesireMapStatus = {
        let s = DesireMapStatus(coupleId: UUID())
        s.partnerAComplete = true
        s.partnerACompletedAt = Date()
        s.waitingStateSince = Date()
        return s
    }()

    @MainActor static let bothCompleteExample: DesireMapStatus = {
        let s = DesireMapStatus(coupleId: UUID())
        s.partnerAComplete = true
        s.partnerBComplete = true
        s.partnerACompletedAt = Date()
        s.partnerBCompletedAt = Date()
        s.waitingStateSince = Date()
        return s
    }()
}
