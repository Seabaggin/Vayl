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
    let description: String             // 2-3 sentence intent copy — shown in deck detail
    let whenToUse: String?              // nil = no timing signal shown
    let goals: [String]                 // "By the end" bullets — empty = section hidden

    // Custom decode: description/whenToUse/goals fall back to defaults when
    // absent from older catalog entries, so catalog JSON can be back-filled
    // deck by deck without breaking decode.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        subtitle = try container.decode(String.self, forKey: .subtitle)
        category = try container.decode(DeckCategory.self, forKey: .category)
        intensity = try container.decode(CardIntensity.self, forKey: .intensity)
        cardCount = try container.decode(Int.self, forKey: .cardCount)
        isLocked = try container.decode(Bool.self, forKey: .isLocked)
        requiredEntitlement = try container.decodeIfPresent(String.self, forKey: .requiredEntitlement)
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        whenToUse = try container.decodeIfPresent(String.self, forKey: .whenToUse)
        goals = try container.decodeIfPresent([String].self, forKey: .goals) ?? []
    }
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
