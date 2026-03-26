//
// OnboardingData.swift
// Open Lightly
//

import Foundation

struct OnboardingData {
    // Screen 1 — Name + Pronouns
    var displayName: String = ""
    var pronouns: [PronounOption] = []
    // Solo path only — captured in ContextView when
    // user selects a card implying a partner exists.
    // Couple path does not use this field —
    // partner sets their own pronouns in NameView.
    // nil = not provided or not applicable.
    var partnerPronouns: String? = nil
    var customPronouns: String?

    // Screen 2 — Mode Select
    var explorationMode: ExplorationMode?

    // Screen 3 — Relationship Status (solo only)
    var relationshipStatus: RelationshipStatus?

    // Screen 4 — Relationship Context (branches on explorationMode)
    var relationshipContext: RelationshipContext?

    // Screen 4 — Personalize
    var nmStage: NMStage?
    var defaultDepth: Float = 0.3

    // Screen 5 — Curiosity Picker
    var communicationGoals: [String] = []    // Section 1 selections
    var learningGoals: [String] = []         // Section 2 selections
    var curiositySelections: [String] = []   // Derived: communicationGoals + learningGoals

    // Screen 6 — Pairing (couple only)
    var pairingId: String?

    // Screen 7 — Building Path (derived from nmStage)
    var defaultDifficulty: String = ""

    // Screen 8 — Ground Rules + completion
    var groundRulesAcceptedAt: Date?
    var onboardingComplete: Bool = false
    var completedAt: Date?

    // Solo Reflection
    var firstReflection: String?
    var firstReflectionCompleted: Bool = false
    var firstReflectionTimestamp: Date?
}

// MARK: - Enums

enum PronounOption: String, CaseIterable, Identifiable, Hashable {
    case sheHer = "she/her"
    case heHim = "he/him"
    case theyThem = "they/them"
    
    var id: String { rawValue }
}

enum ExplorationMode: String, CaseIterable {
    case solo
    case couple
    case browsing
}

enum RelationshipStatus: String, CaseIterable {
    case single
    case partneredOpen
    case partneredHidden
}

enum NMStage: String, CaseIterable {
    case curious
    case exploring
    case experienced
}

enum RelationshipContext: String, CaseIterable, Codable {
    // Solo contexts
    case single
    case partneredOpen
    case partneredHidden

    // Couple contexts
    case notTalked
    case talking
    case someExperience
    case needsReset
}
