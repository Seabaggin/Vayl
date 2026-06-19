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

    // ── DemoPhase (Snapshot Card) ────────────────────────────────────
    // The user's first card: "I [verb] [noun]." The verb (need/want/desire) and
    // the typed noun are kept raw; the derived EmotionalRegister is written into
    // `emotionalRegister` below (reviving the cut CompassPhase Q3 signal). nil
    // until the user reaches and seals the demo card.
    var demoVerb: String? = nil   // DemoVerb.rawValue
    var demoNoun: String? = nil

    // ── NamePhase ────────────────────────────────────────────────────
    var displayName: String = ""

    // ── GenderPhase ──────────────────────────────────────────────────
    // Optional — "Prefer not to say" is a valid selection.
    // nil means the user has not yet reached this phase.
    // genderA / pronounsA set during GenderPhase (single spin, all modes).
    // genderB / pronounsB remain nil here — populated via pairing flow.
    var genderA:   String? = nil
    var pronounsA: String? = nil
    var genderB:   String? = nil   // nil for solo — partner self-provides via pairing
    var pronounsB: String? = nil   // nil for solo — partner self-provides via pairing

    // ── ModeSelectPhase ──────────────────────────────────────────────
    // together: both partners talked, doing this as a couple
    // solo: in a relationship, conversation hasn't happened yet
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
    var ageRange: AgeRange? = nil            // set in the relationalContext phase (later segment)
    var relationshipTenure: RelationshipTenure? = nil  // together mode only; nil for solo

    // ── CompassPhase (CUT from OB flow) ──────────────────────────────
    // CompassPhase was removed from onboarding: Context already infers register,
    // and asking agency/motivation cold up front was redundant. These signals are
    // relocated — agency is gauged later in the DesireMap (observed, not asked),
    // motivation is deferred to in-app behavior. ContextPhase is now the sole OB
    // calibration. These fields are RETAINED (likely reused by the DesireMap) but
    // are NOT written during onboarding. Do NOT re-add a Compass-style OB ask.
    var agency: String?            = nil   // AgencySignal.rawValue
    var motivation: String?        = nil   // MotivationShape.rawValue
    // EmotionalRegister.rawValue. Formerly Compass Q3 (cut); now written by the
    // DemoPhase snapshot card via DemoDictionary.register(verb:noun:).
    var emotionalRegister: String? = nil
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

    /// Whether enough data exists to commit to UserProfile.
    /// Wired as the commit gate in OnboardingStore.commit(data:): commit is blocked
    /// (returns false, sets lastCommitError = .incompleteData) when this is false.
    var isReadyToComplete: Bool {
        switch appMode {
        case .together, .solo:
            return !displayName.trimmingCharacters(in: .whitespaces).isEmpty
                && situationalRegister != nil
                && !curiositySelections.isEmpty
        }
    }
}
