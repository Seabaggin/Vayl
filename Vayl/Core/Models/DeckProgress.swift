//
//  DeckProgress.swift
//  Vayl
//
//  Created by Bryan Jorden on 4/27/26.
//


//
//  DeckProgress.swift
//  Vayl
//

import Foundation
import SwiftData

// MARK: - DeckProgress
// Tracks a couple's progress through a deck.
// Replaces CardProgress.swift — delete that file once this compiles.
//
// DeckProgress tracks where the couple is in a deck across sittings.
// Individual card outcomes live in CardResult — not here.
// currentCardIndex is which card to show next on resume.
// sessionNumber lives on CardSession — one deck can have multiple sessions.
// These are different things. Never collapse them.

@Model
final class DeckProgress {

    var id: UUID
    var coupleId: UUID
    var deckId: String          // String reference to JSON content ID
    var firstOpenedAt: Date?
    var completedAt: Date?
    var lastPlayedAt: Date?     // most-recent activity — drives "recent deck" on Home
    var currentCardIndex: Int   // persists mid-deck position — resume from here
    var isUnwrapped: Bool       // has the ceremonial unwrap animation fired

    init(coupleId: UUID, deckId: String) {
        self.id = UUID()
        self.coupleId = coupleId
        self.deckId = deckId
        self.firstOpenedAt = nil
        self.completedAt = nil
        self.lastPlayedAt = nil
        self.currentCardIndex = 0
        self.isUnwrapped = false
    }
}