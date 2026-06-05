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

    // MARK: - Desire Map State

    var matchesRevealed: Bool
    var desireMapRevealedAt: Date?

    // MARK: - Entitlement
    // Lives on Couple — one purchase unlocks both partners.
    // purchasedBy recorded for support only — never surfaced to either partner.

    var entitlementTier: AccessTier    // free / core / pro
    var coreUnlockedAt: Date?
    var coreUnlockedBy: UUID?               // support use only
    var isFoundingMember: Bool              // first year Pro free when Act 2 launches

    // MARK: - Relationships

    @Relationship(deleteRule: .cascade)
    var desireMatches: [DesireMatch] = []

    @Relationship(deleteRule: .cascade)
    var cardSessions: [CardSession] = []

    @Relationship(deleteRule: .cascade)
    var deckProgress: [DeckProgress] = []

    // MARK: - Init

    init(
        partnerAId: UUID,
        partnerBId: UUID,
        connectionType: ConnectionPlan = .primary
    ) {
        self.id = UUID()
        self.partnerAId = partnerAId
        self.partnerBId = partnerBId
        self.createdAt = Date()
        self.connectionType = connectionType
        self.sharedSafeWord = "red"
        self.matchesRevealed = false
        self.desireMapRevealedAt = nil
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
