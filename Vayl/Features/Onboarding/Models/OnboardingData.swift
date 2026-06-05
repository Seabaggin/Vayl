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
    // Solo:     genderA / pronounsA set; genderB / pronounsB remain nil.
    // Together: both A and B set after spin 2.
    var genderA:   String? = nil
    var pronounsA: String? = nil
    var genderB:   String? = nil   // nil for solo / browsing
    var pronounsB: String? = nil   // nil for solo / browsing

    // ── ModeSelectPhase ──────────────────────────────────────────────
    // together: both partners talked, doing this as a couple
    // solo: in a relationship, conversation hasn't happened yet
    // browsing: just looking, two-tab experience
    var appMode: AppMode = .solo

    // ── ExperienceLevelPhase ─────────────────────────────────────────
    var nmStage: NMStage = .curious

    // ── ContextPhase ─────────────────────────────────────────────────
    // The relationship-context card the user selected, plus the situational
    // register derived from it. ContextPhase NEVER writes emotionalRegister —
    // that field belongs to CompassPhase Q3 exclusively.
    // nil means the user has not yet reached this phase.
    var relationshipContext: String? = nil   // RelationshipContext.rawValue
    var situationalRegister: String? = nil   // SituationalRegister.rawValue

    // ── CompassPhase (CUT from OB flow) ──────────────────────────────
    // CompassPhase was removed from onboarding: Context already infers register,
    // and asking agency/motivation cold up front was redundant. These signals are
    // relocated — agency is gauged later in the DesireMap (observed, not asked),
    // motivation is deferred to in-app behavior. ContextPhase is now the sole OB
    // calibration. These fields are RETAINED (likely reused by the DesireMap) but
    // are NOT written during onboarding. Do NOT re-add a Compass-style OB ask.
    var agency: String?            = nil   // AgencySignal.rawValue
    var motivation: String?        = nil   // MotivationShape.rawValue
    var emotionalRegister: String? = nil   // EmotionalRegister.rawValue — Compass Q3
    var compassNotes: [String]     = []

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
                && situationalRegister != nil
                && !curiositySelections.isEmpty
        }
    }
}
