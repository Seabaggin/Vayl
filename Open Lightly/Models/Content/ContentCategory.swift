//
//  Category.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import Foundation

// ============================================================
// Category.swift
// A read-only content model representing one of the 6 topic
// categories that conversation cards are grouped into.
//
// This struct is decoded from JSON bundled in the app.
// It is never modified at runtime — it describes the structure
// of the content, not the user's progress through it.
//
// Progress tracking (how many cards completed, unlock state)
// lives in SwiftData models, not here.
//
// See PROJECT_SCOPE.md Section 8.2 for category definitions.
// See AppEnums.swift for CategoryType and CategoryPhase.
// ============================================================

struct ContentCategory: Identifiable, Codable {

    // MARK: - Properties

    // Unique identifier — matches CategoryType rawValue (e.g. "relationshipHealth")
    let id: String

    // Human-readable name shown in the UI
    let name: String

    // SF Symbol name used for the category icon
    let icon: String

    // Short description shown on the category selection screen
    let description: String

    // Which therapeutic phase this category belongs to
    let phase: CategoryPhase

    // Total number of cards in this category (content only)
    let cardCount: Int

    // Position in the recommended order (1-6)
    let sortOrder: Int

    // Whether this category requires prerequisites to unlock
    let requiresUnlock: Bool

    // Human-readable unlock description (e.g. "Complete 2 categories")
    let unlockRequirement: String?


    // MARK: - Computed Properties

    // Bridges the JSON id string to the type-safe CategoryType enum.
    var categoryType: CategoryType? {
        CategoryType(rawValue: id)
    }

    // Convenience alias. Actual unlock evaluation happens in the progress layer, not here.
    var isLocked: Bool { requiresUnlock }


    // MARK: - Preview Helpers

    static let example = ContentCategory(
        id: "relationshipHealth",
        name: "Relationship Health",
        icon: "heart.fill",
        description: "Communication, conflict resolution, and emotional intimacy",
        phase: .foundation,
        cardCount: 8,
        sortOrder: 1,
        requiresUnlock: false,
        unlockRequirement: nil
    )
}
