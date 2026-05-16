//
//  DesireMapEntry.swift
//  Vayl
//

import Foundation
import SwiftData

// MARK: - DesireMapEntry
// One person's private rating for a single Desire Map item.
// Replaces DesireRating.swift — delete that file once this compiles.
//
// CRITICAL — Most sensitive data in the app.
// Three enforcement layers — all three must hold simultaneously:
//   1. Swift: notForUs never included in any Supabase write payload
//   2. Edge Function: filters before writing to desire_matches table
//   3. Supabase RLS: partner cannot query desire_map_entries at all, ever
//
// userId is PRIVATE — never crosses to the partner's device or view.
// notForUs ratings NEVER leave the device under any circumstances.

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

    // MARK: - Computed

    /// Whether this entry should ever be included in a sync payload.
    /// notForUs entries always return false — they never leave the device.
    var isSyncable: Bool {
        rating != .notForUs
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

    // MARK: - Reveal State

    var fullRevealUnlocked: Bool    // true after paywall cleared
    var fullRevealAt: Date?
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
        self.fullRevealUnlocked = false
        self.fullRevealAt = nil
        self.waitingStateSince = nil
    }

    // MARK: - Preview Helpers

    static let example = DesireMapStatus(coupleId: UUID())

    static let waitingExample: DesireMapStatus = {
        let s = DesireMapStatus(coupleId: UUID())
        s.partnerAComplete = true
        s.partnerACompletedAt = Date()
        s.waitingStateSince = Date()
        return s
    }()

    static let bothCompleteExample: DesireMapStatus = {
        let s = DesireMapStatus(coupleId: UUID())
        s.partnerAComplete = true
        s.partnerBComplete = true
        s.partnerACompletedAt = Date()
        s.partnerBCompletedAt = Date()
        s.waitingStateSince = Date()
        return s
    }()
}
