//
//  Card.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import Foundation

// ============================================================
// Card.swift
// A read-only content model representing a single conversation
// card within a category.
//
// Cards are the core content unit of the app. Each card is
// a prompt, education block, education+prompt, or cool-off
// exercise that couples work through during a session.
//
// This struct is decoded from JSON bundled in the app.
// It is never modified at runtime.
//
// Per-card progress (discussed, skipped, bookmarked) lives
// in SwiftData models (CardProgress), not here.
//
// See PROJECT_SCOPE.md Section 8.2-8.3 for card definitions.
// See AppEnums.swift for CardType, Difficulty, Sensitivity, TurnOrder.
// ============================================================

struct ContentCard: Identifiable, Codable {

    // MARK: - Properties

    // Unique card ID using category prefix + number (e.g. "RH-1", "IJ-3")
    let id: String

    // Matches CategoryType raw value (e.g. "relationshipHealth")
    let categoryID: String

    // prompt, education, educationPrompt, or coolOff
    let type: CardType

    // Optional card title (education cards may have one)
    let title: String?

    // The main text shown on the card. Always present.
    let promptText: String

    // Additional education content shown above the prompt on educationPrompt cards.
    let educationText: String?

    // Who speaks first on this card (.partnerA or .partnerB)
    let speakingTurnFirst: TurnOrder

    // Emotional intensity level
    let difficulty: Difficulty

    // Determines screenshot protection behavior
    let sensitivity: Sensitivity

    // Position within the category
    let sortOrder: Int

    // Whether this card is available in the free tier
    let isFree: Bool

    // Optional "why this matters" note shown below the prompt
    let contextNote: String?


    // MARK: - Computed Properties

    // Bridges the JSON categoryID to the type-safe enum.
    var categoryType: CategoryType? { CategoryType(rawValue: categoryID) }

    // Whether this card has an education component.
    var isEducation: Bool { type == .education || type == .educationPrompt }

    // Whether this card requires partner discussion.
    var hasPrompt: Bool { type == .prompt || type == .educationPrompt }

    // Whether the app should activate screenshot protection for this card.
    var requiresScreenshotProtection: Bool { sensitivity != .low }


    // MARK: - Preview Helpers

    static let promptExample = ContentCard(
        id: "RH-1",
        categoryID: "relationshipHealth",
        type: .prompt,
        title: nil,
        promptText: "What does our relationship look like when we're at our best?",
        educationText: nil,
        speakingTurnFirst: .partnerA,
        difficulty: .easy,
        sensitivity: .low,
        sortOrder: 1,
        isFree: true,
        contextNote: "Starting with strengths builds a foundation for harder conversations."
    )

    static let educationPromptExample = ContentCard(
        id: "IJ-2",
        categoryID: "insecurities",
        type: .educationPrompt,
        title: "Understanding Jealousy",
        promptText: "When was the last time you felt jealous? What was underneath it?",
        educationText: "Jealousy is not a single emotion — it's a cluster of feelings including fear, anger, and sadness. Identifying the root feeling helps you communicate what you actually need.",
        speakingTurnFirst: .partnerB,
        difficulty: .medium,
        sensitivity: .medium,
        sortOrder: 2,
        isFree: false,
        contextNote: nil
    )
}
