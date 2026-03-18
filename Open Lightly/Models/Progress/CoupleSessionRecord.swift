//
//  CoupleSessionRecord.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import Foundation
import SwiftData

// ============================================================
// CoupleSessionRecord.swift
// A SwiftData model representing one completed or in-progress
// couple session. It tracks which cards were discussed or
// skipped, timing, and session-level metadata.
//
// CoupleSessionRecord instances are owned by a Couple and stored
// as part of the couple's history. They are not responsible
// for storing per-card progress (that's CardProgress).
//
// Forward references: Couple model declares the inverse
// relationship and owns CoupleSessionRecord via a cascade rule.
// ============================================================

@Model
final class CoupleSessionRecord: Identifiable {

    // MARK: - Properties

    var id: UUID = UUID()

    // Which category this session covered (e.g. "communication")
    var categoryID: String

    // Lifecycle state of the session
    var status: SessionStatus = SessionStatus.notStarted

    // Ordered list of card IDs that were discussed in this session
    var cardIDsDiscussed: [String] = []

    // Cards the couple chose to skip
    var cardIDsSkipped: [String] = []

    // If paused/in-progress, which card is currently displayed
    var currentCardID: String? = nil

    // If paused, whose turn it is
    var currentTurn: TurnOrder? = nil

    // Whether the safe word was invoked during this session
    var safeWordUsed: Bool = false

    // Total duration in seconds
    var durationSeconds: Int = 0

    // Timestamps
    var startedAt: Date? = nil
    var completedAt: Date? = nil


    // MARK: - Relationships

    // The Couple that owns this session record (inverse declared on Couple)
    @Relationship
    var couple: Couple?


    // MARK: - Initializer

    init(
        categoryID: String,
        status: SessionStatus = SessionStatus.notStarted,
        cardIDsDiscussed: [String] = [],
        cardIDsSkipped: [String] = [],
        currentCardID: String? = nil,
        currentTurn: TurnOrder? = nil,
        safeWordUsed: Bool = false,
        durationSeconds: Int = 0,
        startedAt: Date? = nil,
        completedAt: Date? = nil
    ) {
        self.id = UUID()
        self.categoryID = categoryID
        self.status = status
        self.cardIDsDiscussed = cardIDsDiscussed
        self.cardIDsSkipped = cardIDsSkipped
        self.currentCardID = currentCardID
        self.currentTurn = currentTurn
        self.safeWordUsed = safeWordUsed
        self.durationSeconds = durationSeconds
        self.startedAt = startedAt
        self.completedAt = completedAt
    }


    // MARK: - Preview Helpers

    static let example = CoupleSessionRecord(categoryID: "communication")
}
