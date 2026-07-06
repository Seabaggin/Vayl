//  DeckSummary.swift
//  Vayl — Play

import Foundation

/// Lightweight catalog row — everything the deck wall needs WITHOUT loading card
/// content. The full `Deck` (with `cards`) loads only when a deck is opened.
/// Decoded from `deck-catalog.json` (snake_case → camelCase via ContentLoader).
struct DeckSummary: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let category: DeckCategory
    let intensity: CardIntensity
    let cardCount: Int
    let isLocked: Bool                  // true = behind Vayl Core (one-time purchase)
    let requiredEntitlement: String?    // nil = free, "core" = Core tier
}

#if DEBUG
import SwiftUI
#Preview("Catalog decodes") {
    let summaries = (try? DeckCatalogService().loadSummaries()) ?? []
    return List(summaries) { s in
        VStack(alignment: .leading) {
            Text(s.title).font(.headline)
            Text("\(s.category.displayName) · \(s.intensity.displayName) · \(s.cardCount) cards\(s.isLocked ? " · Core" : "")")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
}
#endif
