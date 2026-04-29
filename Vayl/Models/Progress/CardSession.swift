//
//  CardSession.swift
//  Vayl
//

import Foundation
import SwiftData

// MARK: - CardSession
// Represents one sitting with a deck.
// Sessions belong to a couple — they are shared events, not individual ones.
// A deck can have multiple sessions — sessionNumber tracks which pass this is.
// sessionNumber is not the same as currentCardIndex on DeckProgress.
// One tracks which sitting, the other tracks which card.

@Model
final class CardSession {

    var id: UUID
    var coupleId: UUID          // sessions are couple-owned — never userId
    var deckId: String          // String reference to JSON content ID — not a UUID FK
    var startedAt: Date
    var completedAt: Date?
    var sessionNumber: Int      // which pass through this deck (1, 2, 3...)
    var cardsAttempted: Int
    var cardsDiscussed: Int
    var cardsSkipped: Int
    var cardsBookmarked: Int
    var lockInBandwidthA: Float?    // 0.0-1.0 — from Lock In, feeds PulseStore
    var lockInBandwidthB: Float?    // 0.0-1.0 — from Lock In, feeds PulseStore

    @Relationship(deleteRule: .cascade)
    var cardResults: [CardResult]

    init(coupleId: UUID, deckId: String) {
        self.id = UUID()
        self.coupleId = coupleId
        self.deckId = deckId
        self.startedAt = Date()
        self.completedAt = nil
        self.sessionNumber = 1
        self.cardsAttempted = 0
        self.cardsDiscussed = 0
        self.cardsSkipped = 0
        self.cardsBookmarked = 0
        self.lockInBandwidthA = nil
        self.lockInBandwidthB = nil
        self.cardResults = []
    }
}

// MARK: - CardResult
// Tracks the outcome of a single card within a session.
// cardId is a String reference to the JSON content ID — never a UUID FK.
// The String cardId on CardResult is the only join between
// the SwiftData progress layer and the JSON content layer.

@Model
final class CardResult {

    var id: UUID
    var sessionId: UUID
    var cardId: String          // String reference to JSON content ID
    var status: CardStatus      // discussed / skipped / bookmarked
    var completedAt: Date

    init(sessionId: UUID, cardId: String, status: CardStatus) {
        self.id = UUID()
        self.sessionId = sessionId
        self.cardId = cardId
        self.status = status
        self.completedAt = Date()
    }
}

// MARK: - SoloSession
// Tracks a solo prep deck session for an unlinked user.
// Used only for the 5-card solo prep deck — before a partner is linked.
// coupleId does not exist yet for this user — this model owns
// the session independently on their userId.
// When the user links a partner, SoloSession stays on their record
// permanently as historical context. It is never deleted or converted.

@Model
final class SoloSession {

    var id: UUID
    var userId: UUID            // owned by the individual — never a coupleId
    var deckId: String          // always the solo prep deck in V1
    var startedAt: Date
    var completedAt: Date?
    var cardsDiscussed: Int
    var cardsSkipped: Int

    init(userId: UUID, deckId: String) {
        self.id = UUID()
        self.userId = userId
        self.deckId = deckId
        self.startedAt = Date()
        self.completedAt = nil
        self.cardsDiscussed = 0
        self.cardsSkipped = 0
    }
}