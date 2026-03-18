//
//  CardProgress.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import Foundation
import SwiftData

// ============================================================
// CardProgress.swift
// A SwiftData model representing a couple-level progress record
// for a single content card.
//
// Each CardProgress instance tracks whether the card was
// discussed, skipped, or bookmarked during a session, along
// with optional timestamps and notes. CardProgress objects are
// owned by a Couple and link back to the couple via the
// `couple` relationship.
//
// Forward references: Couple model owns CardProgress via a
// cascade relationship and is defined in Couple.swift.
// ============================================================

@Model
final class CardProgress: Identifiable {

    // MARK: - Properties

    var id: UUID = UUID()

    // Matches ContentCard.id (e.g. "COMM-01")
    var cardID: String

    // Category identifier for the card (e.g. "communication")
    var categoryID: String

    // Per-card state tracked for the couple
    var status: CardStatus = CardStatus.notStarted

    // Timestamps for actions
    var discussedAt: Date? = nil
    var skippedAt: Date? = nil
    var bookmarkedAt: Date? = nil

    // Optional couple notes about this card
    var notes: String? = nil


    // MARK: - Relationships

    // The Couple that owns this CardProgress record. The inverse
    // relationship is declared on Couple.cardProgress and handles
    // cascade deletion when a Couple is removed.
    @Relationship
    var couple: Couple?


    // MARK: - Initializer

    init(
        cardID: String,
        categoryID: String,
        status: CardStatus = CardStatus.notStarted,
        discussedAt: Date? = nil,
        skippedAt: Date? = nil,
        bookmarkedAt: Date? = nil,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.cardID = cardID
        self.categoryID = categoryID
        self.status = status
        self.discussedAt = discussedAt
        self.skippedAt = skippedAt
        self.bookmarkedAt = bookmarkedAt
        self.notes = notes
    }


    // MARK: - Preview Helpers

    static let example = CardProgress(cardID: "COMM-01", categoryID: "communication")
}
