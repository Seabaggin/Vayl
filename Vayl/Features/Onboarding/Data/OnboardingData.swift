//
// OnboardingData.swift
// Open Lightly
//

import Foundation

struct OnboardingData {
    // Screen 1 — Name + Gender Identity
    var displayName: String = ""
    // Raw string value from the gender identity picker.
    // nil = not provided or "Prefer not to say".
    var genderIdentity: String? = nil
    // Solo path only — captured in ContextView when
    // user selects a card implying a partner exists.
    // Couple path does not use this field —
    // partner sets their own gender in NameView.
    // nil = not provided or not applicable.
    var partnerPronouns: String? = nil

    // Screen 2 — Mode Select
    var explorationMode: ExplorationMode?

    // Screen 3 — Relationship Status (solo only)
    var relationshipStatus: RelationshipStatus?

    // Screen 4 — Relationship Context (branches on explorationMode)
    var relationshipContext: RelationshipContext?

    // Screen 4 — Personalize
    var nmStage: NMStage?

    // Screen 5 — Curiosity Picker
    var communicationGoals: [String] = []    // Section 1 selections
    var learningGoals: [String] = []         // Section 2 selections
    var curiositySelections: [String] = []   // Derived: communicationGoals + learningGoals

    // Screen 7 — Building Path (derived from nmStage)
    // Derived from nmStage — read by BuildingPathView.
    // Not stored. Returns "warm" if nmStage is nil.
    var defaultDifficulty: String {
        switch nmStage {
        case .curious:     return "warm"
        case .exploring:   return "medium"
        case .experienced: return "hot"
        case .none:        return "warm"
        }
    }

    // Screen 7.5 — Card Reveal (pill selection for archetype routing)
    // nil when user skips — archetype routing uses fallback.
    var nmCardResponse: String? = nil

    // Screen 8 — Ground Rules + completion
    var groundRulesAcceptedAt: Date?
    var onboardingComplete: Bool = false
    var completedAt: Date?
}
