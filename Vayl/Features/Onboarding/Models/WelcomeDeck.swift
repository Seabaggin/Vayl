// Vayl/Features/Onboarding/Models/WelcomeDeck.swift
import SwiftUI

/// The forged starter deck revealed at the end of BuildDeck. Identity derives
/// from `OpenerDeckType` (set by `VaylDirector.evaluateOpenerDeckType()` at the
/// end of Curiosity). Card CONTENT is placeholder pending the content pass;
/// name + purpose + colorway are real so the reveal feels personalised.
///
/// Each type now maps to a REAL catalog deck (`OpenerDeckType.welcomeDeckId`,
/// stubs in Resources/Decks/opener-*.json) that Play features after OB. The
/// content pass must keep this display copy and those decks in sync: name ==
/// deck title (uppercased), purpose == deck subtitle, cards == the deck's cards.
struct WelcomeDeck: Equatable {
    let name: String        // the genuine name reveal
    let purpose: String     // one line above the carousel
    let colorway: FoilColorway

    /// Placeholder prompt cards — shared set; the content pass replaces these.
    /// Tuple shape mirrors `VaylCardFace.context(number:title:subtitle:detail:)`.
    static let placeholderCards: [(number: String, title: String, subtitle: String, detail: String)] = [
        ("01", "Name it", "What pulled you toward this", "A first card to open the conversation."),
        ("02", "Out loud", "Say one true thing", "Practice putting words to the want."),
        ("03", "The edge", "Where it gets tender", "The place you usually go quiet."),
        ("04", "Their side", "What you'd want to hear", "Imagine it from across the table."),
        ("05", "Small step", "One thing this week", "Low stakes, real movement."),
        ("06", "Check in", "How it actually felt", "Come back and tell the truth about it.")
    ]

    // provisional working titles — map to OpenerDeckType semantics; content pass renames
    static func of(_ type: OpenerDeckType) -> WelcomeDeck {
        switch type {
        case .anxious:        return .init(name: "STEADY", purpose: "Start slow. Find your footing.", colorway: .solo)
        case .excited:        return .init(name: "OPENING", purpose: "Lean into the momentum.", colorway: .solo)
        case .reflectiveCalm: return .init(name: "RETURN", purpose: "Revisit what you already know.", colorway: .solo)
        case .reflectiveOpen: return .init(name: "WIDER", purpose: "Build on the ground you've covered.", colorway: .solo)
        }
    }
}
