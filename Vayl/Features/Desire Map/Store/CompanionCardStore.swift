//
//  CompanionCardStore.swift
//  Vayl
//
//  STUB (Store layer). The connection point between a completed Desire Map and "what's next" —
//  it maps the couple's matches to companion cards that point at a conversation and/or a deck
//  to open together. Wires into the D4 reveal / D5 Map tab once those exist.
//
//  TODO: load real companion content (companion_cards.json) and resolve a real suggestedDeckId
//        per desire item/category; persist bridgeCardId from the edge fn. For now it returns a
//        placeholder companion per match so downstream surfaces have something to render.
//

import Foundation

@Observable
@MainActor
final class CompanionCardStore {

    /// Suggested companions for the couple's matches. STUB: one placeholder per match.
    func companions(for matches: [DesireMatch]) -> [CompanionCard] {
        matches.map { match in
            CompanionCard(
                id: match.bridgeCardId ?? "companion_\(match.itemId)",
                desireItemId: match.itemId,
                title: "Talk about it together",
                prompt: "You both leaned into this one — here's a place to start the conversation.",
                suggestedDeckId: suggestedDeckId(for: match)
            )
        }
    }

    /// The deck to suggest opening after the map for a given match.
    /// STUB → nil until desire item/category → deck mapping is wired.
    func suggestedDeckId(for match: DesireMatch) -> String? {
        // TODO: map match.itemId / desire category → a real deck id (e.g. a topic deck).
        nil
    }
}
