//
//  Couple.swift
//  Vayl
//

import Foundation
import SwiftData

// MARK: - Couple
// Represents a linked partner connection.
// Entitlement lives here — one purchase covers both partners.
// No hierarchy displayed to either partner.
//
// When a Couple is dissolved the record is archived not deleted.
// UserProfile records survive independently.
// coreUnlockedBy is recorded for support only — never shown to either partner.

@Model
final class Couple {

    // MARK: - Identity

    var id: UUID
    var partnerAId: UUID
    var partnerBId: UUID
    var createdAt: Date

    // MARK: - Connection Type

    var connectionType: ConnectionPlan  // primary ($24.99) / additional ($7.99)

    // MARK: - Shared Config

    var sharedSafeWord: String          // default "red" — only shared config
    var relationshipTenure: RelationshipTenure?  // set by first together-mode partner during OB

    // MARK: - Entitlement
    // Lives on Couple — one purchase unlocks both partners.
    // purchasedBy recorded for support only — never surfaced to either partner.

    var entitlementTier: AccessTier    // free / core / pro
    var coreUnlockedAt: Date?
    var coreUnlockedBy: UUID?               // support use only
    var isFoundingMember: Bool              // first year Pro free when Act 2 launches

    // MARK: - Relationships
    // deleteRule .nullify (not .cascade): per the type's own contract above, a
    // dissolved Couple is ARCHIVED, not deleted — its history must survive. Cascade
    // would wipe every session / progress / match on unlink (the Seg 9 footgun).
    // The child rows keep their own coupleId UUID, so the history stays attributable.

    @Relationship(deleteRule: .nullify)
    var desireMatches: [DesireMatch] = []

    @Relationship(deleteRule: .nullify)
    var cardSessions: [CardSession] = []

    @Relationship(deleteRule: .nullify)
    var deckProgress: [DeckProgress] = []

    // MARK: - Init

    init(
        partnerAId: UUID,
        partnerBId: UUID,
        connectionType: ConnectionPlan = .primary,
        relationshipTenure: RelationshipTenure? = nil
    ) {
        self.id = UUID()
        self.partnerAId = partnerAId
        self.partnerBId = partnerBId
        self.createdAt = Date()
        self.connectionType = connectionType
        self.sharedSafeWord = "red"
        self.relationshipTenure = relationshipTenure
        self.entitlementTier = .free
        self.coreUnlockedAt = nil
        self.coreUnlockedBy = nil
        self.isFoundingMember = false
    }

    // MARK: - Computed

    /// Whether the full Desire Map reveal is available.
    var canRevealDesireMap: Bool {
        entitlementTier != .free
    }

    // MARK: - Preview Helpers

    static let example = Couple(
        partnerAId: UUID(),
        partnerBId: UUID()
    )
}
