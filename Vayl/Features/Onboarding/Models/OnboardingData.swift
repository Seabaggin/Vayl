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
    var demoVerb: String?   // DemoVerb.rawValue
    var demoNoun: String?

    // ── NamePhase ────────────────────────────────────────────────────
    var displayName: String = ""

    // ── GenderPhase ──────────────────────────────────────────────────
    // Optional — "Prefer not to say" is a valid selection.
    // nil means the user has not yet reached this phase.
    // genderA / pronounsA set during GenderPhase (single spin, all modes).
    // genderB / pronounsB remain nil here — populated via pairing flow.
    var genderA: String?
    var pronounsA: String?
    var genderB: String?   // nil for solo — partner self-provides via pairing
    var pronounsB: String?   // nil for solo — partner self-provides via pairing

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
    var relationshipContext: String?   // RelationshipContext.rawValue
    var situationalRegister: String?   // SituationalRegister.rawValue
    var ageRange: AgeRange?            // set in the relationalContext phase (later segment)
    var relationshipTenure: RelationshipTenure?  // together mode only; nil for solo

    // ── CompassPhase (CUT from OB flow) ──────────────────────────────
    // CompassPhase was removed from onboarding: Context already infers register,
    // and asking agency/motivation cold up front was redundant. These signals are
    // relocated — agency is gauged later in the DesireMap (observed, not asked),
    // motivation is deferred to in-app behavior. ContextPhase is now the sole OB
    // calibration. These fields are RETAINED (likely reused by the DesireMap) but
    // are NOT written during onboarding. Do NOT re-add a Compass-style OB ask.
    var agency: String?   // AgencySignal.rawValue
    var motivation: String?   // MotivationShape.rawValue
    // EmotionalRegister.rawValue. Formerly Compass Q3 (cut); now written by the
    // DemoPhase snapshot card via DemoDictionary.register(verb:noun:).
    var emotionalRegister: String?
    var compassNotes: [String]     = []

    // ── CuriosityPhase ───────────────────────────────────────────────
    // The kept cards from the single aspirational sort ("What are you curious
    // to try?" / "What do you want more of?"). The old Round 1 feelings sort
    // (communicationGoals) was CUT 2026-07-04: Context already carries the
    // present-state signal, so the sort now collects direction only.
    // evaluateOpenerDeckType() reads this directly; future consumer = Learn.
    var curiositySelections: [String] = []

    // ── Derived / assigned ───────────────────────────────────────────
    // Assigned silently by VaylDirector.evaluateOpenerDeckType()
    // at the end of CuriosityPhase round 2. Never shown to the user.
    var openerDeckType: OpenerDeckType = .anxious

    // Set by OnboardingStore.commit() on successful UserProfile write.
    // nil until OB completes. Non-nil presence is the completion signal.
    var onboardingCompletedAt: Date?

    // ── Derived — never stored independently ─────────────────────────

    /// Whether enough data exists to commit to UserProfile.
    /// Wired as the commit gate in OnboardingStore.commit(data:): commit is blocked
    /// (returns false, sets lastCommitError = .incompleteData) when this is false.
    var isReadyToComplete: Bool {
        // curiositySelections is NOT required: passing on every sort card is a
        // valid outcome ("none of these yet"), and with a single 5-card round it
        // is a reachable one — an empty pool must never strand the user at commit.
        switch appMode {
        case .together, .solo:
            return !displayName.trimmingCharacters(in: .whitespaces).isEmpty
                && situationalRegister != nil
        }
    }
}
