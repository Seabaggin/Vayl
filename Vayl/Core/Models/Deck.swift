//
//  Deck.swift
//  Vayl
//
//  Created by Bryan Jorden on 4/27/26.
//


//
//  Deck.swift
//  Vayl
//
//  Location: Models/Content/Deck.swift
//  Read-only. Loaded from JSON at runtime.
//  NEVER stored in SwiftData.
//  Progress against a deck → DeckProgress (SwiftData)
//  The String deckId on DeckProgress is the only join between them.
//

import Foundation

// MARK: - Deck

struct Deck: Codable, Identifiable {

    let id: String                          // stable — never changes even if title changes
    let title: String
    let subtitle: String
    let category: DeckCategory
    let act: Int                            // 1 / 2 / 3
    let intensity: CardIntensity            // deck-level default
    let isLocked: Bool
    let requiredEntitlement: String?        // nil = free, "core" = Core tier required
    let tags: [String]
    let sortOrder: Int
    let schemaVersion: Int                  // increment when deck content changes
    let cards: [Card]

    // MARK: - Derived

    /// Whether this deck is available to the given entitlement tier.
    func isAvailable(for tier: AccessTier) -> Bool {
        guard let required = requiredEntitlement else { return true }
        switch required {
        case "core": return tier == .core || tier == .pro
        case "pro":  return tier == .pro
        default:     return true
        }
    }

    /// Cards for a specific gender dynamic.
    /// Returns all cards when dynamic is .flexible or card is not gendered.
    func cards(for dynamic: GenderDynamic) -> [Card] {
        cards.filter { card in
            guard card.isGenderedCard, let genderedFor = card.genderedFor else {
                return true
            }
            return genderedFor == dynamic || dynamic == .flexible
        }
        .sorted { $0.sortOrder < $1.sortOrder }
    }

    /// Cards sorted by sortOrder — standard play order.
    var orderedCards: [Card] {
        cards.sorted { $0.sortOrder < $1.sortOrder }
    }

    /// Total card count for display.
    var cardCount: Int { cards.count }

    /// Whether this deck has a closing ritual card.
    var hasClosingRitual: Bool {
        cards.contains { $0.type == .closingRitual }
    }

    /// Whether this deck has an opening ritual card.
    var hasOpeningRitual: Bool {
        cards.contains { $0.type == .openingRitual }
    }
}

// MARK: - Deck Preview Helpers

extension Deck {

    /// Minimal preview deck — no real cards.
    /// Use for UI component previews only.
    static let preview = Deck(
        id: "preview-deck",
        title: "Preview Deck",
        subtitle: "For UI development only",
        category: .foundationEntry,
        act: 1,
        intensity: .deepOcean,
        isLocked: false,
        requiredEntitlement: nil,
        tags: ["preview"],
        sortOrder: 0,
        schemaVersion: 1,
        cards: []
    )

    /// Preview deck with sample card count for layout testing.
    static let previewWithCards = Deck(
        id: "preview-deck-cards",
        title: "The Opener",
        subtitle: "Where are we, actually.",
        category: .foundationEntry,
        act: 1,
        intensity: .deepOcean,
        isLocked: false,
        requiredEntitlement: nil,
        tags: ["foundation", "free", "entry"],
        sortOrder: 1,
        schemaVersion: 1,
        cards: Card.openerSamples
    )
}
