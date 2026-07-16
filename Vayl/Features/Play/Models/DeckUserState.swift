//
//  DeckUserState.swift
//  Vayl
//

import Foundation
import SwiftData

// MARK: - DeckUserState
// Local user's star state for a deck. Partner star state and partner name
// are read separately from the couple's shared Supabase row — never stored
// here (see PlayStore.isStarredByPartner / partnerName).

@Model
final class DeckUserState {

    var deckId: String
    var coupleId: UUID
    var starredByMe: Bool
    var lastPlayed: Date?

    init(deckId: String, coupleId: UUID) {
        self.deckId = deckId
        self.coupleId = coupleId
        self.starredByMe = false
        self.lastPlayed = nil
    }
}
