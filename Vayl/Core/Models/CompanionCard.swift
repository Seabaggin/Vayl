//
//  CompanionCard.swift
//  Vayl
//
//  STUB — "Desire Map companion cards." After a couple completes the Desire Map, a companion
//  card bridges a result into a next step: a short conversation prompt and/or a suggested deck
//  to open together. Linked from `DesireMatch.bridgeCardId`. Pure data shape (Model layer).
//  Real content (companion_cards.json) + per-item deck linkage is future work.
//

import Foundation

struct CompanionCard: Codable, Identifiable, Hashable {
    let id: String              // == DesireMatch.bridgeCardId
    let desireItemId: String    // the desire item this companion bridges
    let title: String
    let prompt: String          // the conversation companion prompt
    let suggestedDeckId: String?  // a deck to open next (stub link, nil until wired)
}

// MARK: - Tier

enum CompanionCardTier: String, Codable {
    case mutual
    case adjacent
    case consentOpened = "consent_opened"
}

// MARK: - Content pool (deserialized from companion_cards.json)

struct CompanionCardPool: Codable {
    let tier: CompanionCardTier
    let prompts: [CompanionCardPrompt]
}

struct CompanionCardPrompt: Codable, Identifiable {
    let id: String
    let text: String
}
