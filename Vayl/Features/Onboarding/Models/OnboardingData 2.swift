//
//  OnboardingData.swift
//  Vayl
//

import Foundation

// Transient struct — lives only during the onboarding flow.
// Written to UserProfile on completion via OnboardingStore.commit().
// Not persisted independently.
// Onboarding data is the source of truth for content routing
// throughout the entire app lifecycle — nothing here gets discarded.

struct OnboardingData {

    // ── NamePhase ────────────────────────────────────────────────────
    var displayName: String = ""

    // ── GenderPhase ──────────────────────────────────────────────────
    // Optional — "Prefer not to say" is a valid selection.
    // nil means the user has not yet reached this phase.
    var genderIdentity: String? = nil

    // ── ModeSelectPhase ──────────────────────────────────────────────
    // together: both partners talked, doing this as a couple
    // solo: in a relationship, conversation hasn't happened yet
    // browsing: just looking, two-tab experience
    var appMode: AppMode = .solo

    // ── ExperienceLevelPhase ─────────────────────────────────────────
    var nmStage: NMStage = .curious

    // ── ContextPhase ─────────────────────────────────────────────────
    // The emotional register card the user selected.
    // nil means the user has not yet reached this phase.
    var emotionalRegister: String? = nil

    // ── CuriosityPhase ───────────────────────────────────────────────
    // Round 1 — "What keeps coming up for you?"
    var communicationGoals: [String] = []
    // Round 2 — "What are you curious about?"
    var learningGoals: [String] = []
    // Combined pool of all curiosity selections across both rounds.
    // evaluateOpenerDeckType() reads this directly.
    var curiositySelections: [String] = []

    // ── Derived / assigned ───────────────────────────────────────────
    // Assigned silently by VaylDirector.evaluateOpenerDeckType()
    // at the end of CuriosityPhase round 2. Never shown to the user.
    var openerDeckType: OpenerDeckType = .anxious

    // Set by OnboardingStore.commit() on successful UserProfile write.
    // nil until OB completes. Non-nil presence is the completion signal.
    var onboardingCompletedAt: Date? = nil

    // ── Derived — never stored independently ─────────────────────────

    /// Default card intensity derived from NM stage.
    /// Always derived — never stored.
    var defaultIntensity: CardIntensity {
        nmStage.defaultDifficulty
    }

    /// Whether this user goes through the full onboarding path.
    /// Browsing users have a shorter path — no curiosity or context phases.
    var isFullOnboarding: Bool {
        appMode == .together || appMode == .solo
    }

    /// Whether enough data exists to commit to UserProfile.
    /// VaylDirector checks this before calling OnboardingStore.commit().
    var isReadyToComplete: Bool {
        switch appMode {
        case .browsing:
            return !displayName.trimmingCharacters(in: .whitespaces).isEmpty
        case .together, .solo:
            return !displayName.trimmingCharacters(in: .whitespaces).isEmpty
                && emotionalRegister != nil
                && !curiositySelections.isEmpty
        }
    }
}
