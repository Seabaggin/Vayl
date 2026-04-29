//
//  OnboardingData.swift
//  Vayl
//

import Foundation

// Transient struct — lives only during the onboarding flow.
// Written to UserProfile on completion. Not persisted independently.
// Onboarding data is the source of truth for content routing
// throughout the entire app lifecycle — nothing here gets discarded.

struct OnboardingData {

    // ── Screen 1 — NameView ──────────────────────────────────────────
    var displayName: String = ""
    var pronouns: [String] = []
    var genderIdentity: String? = nil

    // ── Screen 2 — ModeSelectView ────────────────────────────────────
    // together: both partners talked, doing this as a couple
    // solo: in a relationship, conversation hasn't happened yet
    // browsing: just looking, two-tab experience, short onboarding
    var appMode: AppMode?

    // NMStage — shown on ModeSelectView for together and solo only
    // Not shown for browsing — they skip the experience question
    var nmStage: NMStage?

    // ── Screen 3 — CuriosityPickerView (together + solo only) ────────
    var communicationGoals: [String] = []
    var learningGoals: [String] = []
    var curiositySelections: [String] = []

    // ── Screen 4 — CardRevealView (together + solo only) ─────────────
    // Pill selection for archetype routing.
    // nil when user skips — archetype routing uses fallback.
    var nmCardResponse: String? = nil

    // ── Screen 5 — GroundRulesView (together + solo only) ────────────
    var groundRulesAcceptedAt: Date?
    var onboardingComplete: Bool = false
    var completedAt: Date?

    // ── Derived ───────────────────────────────────────────────────────

    /// Default card intensity derived from NM stage.
    /// Never stored independently — always derived.
    var defaultIntensity: CardIntensity {
        nmStage?.defaultDifficulty ?? .deepOcean
    }

    /// Whether this user goes through the full onboarding path.
    /// Browsing users skip everything after ModeSelectView.
    var isFullOnboarding: Bool {
        appMode == .together || appMode == .solo
    }

    /// Whether enough data exists to complete onboarding.
    var isReadyToComplete: Bool {
        guard let mode = appMode else { return false }
        switch mode {
        case .browsing:
            return !displayName.trimmingCharacters(in: .whitespaces).isEmpty
        case .together, .solo:
            return !displayName.trimmingCharacters(in: .whitespaces).isEmpty
                && nmStage != nil
                && groundRulesAcceptedAt != nil
        }
    }
}
