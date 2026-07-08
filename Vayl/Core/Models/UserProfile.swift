//
//  UserProfile.swift
//  Vayl
//

import Foundation
import SwiftData

// MARK: - UserProfile
// One record per person. Created at the end of onboarding.
// Onboarding data is the source of truth for content routing
// throughout the entire app lifecycle — nothing here gets discarded.
//
// lastEntryRitualDate lives in UserDefaults — not here.
// pairingCode lives in Supabase only — never persisted locally
// beyond the pairing flow.
// archetype is invisible infrastructure — never shown to the user.

@Model
final class UserProfile {

    // MARK: - Identity

    var id: UUID
    var accountId: String?          // Sign in with Apple subject
    var displayName: String

    // Self — collected in GenderPhase (single spin, all modes)
    var genderIdentity: String?     // nil if user skipped or hasn't reached GenderPhase
    var pronouns: [String]          // user's own pronouns; empty if skipped

    // Partner — collected via pairing flow, never in GenderPhase
    // nil until partner completes their own onboarding and pairing syncs.
    var partnerGenderIdentity: String?
    var partnerPronouns: String?

    var createdAt: Date

    // MARK: - Onboarding Routing

    var nmStage: NMStage                        // curious / exploring / experienced
    var appMode: AppMode                        // together / solo
    var relationshipContext: String?            // ContextPhase — maps to RelationshipContext enum
    var situationalRegister: String?            // ContextPhase — maps to SituationalRegister enum
    var emotionalRegister: String?              // DemoPhase snapshot — maps to EmotionalRegister enum (was Compass Q3)
    var demoVerb: String?                       // DemoPhase snapshot — DemoVerb.rawValue ("I [verb] [noun]")
    var demoNoun: String?                       // DemoPhase snapshot — the noun the user typed
    var ageRange: AgeRange?                     // ContextPhase — set during relationalContext step
    var agency: String?                         // CompassPhase Q1 — maps to AgencySignal enum
    var motivation: String?                     // CompassPhase Q2 — maps to MotivationShape enum
    var compassNotes: [String]                  // CompassPhase optional notes — user only, never routed
    var archetype: ArchetypeTag                 // internal only — never shown
    var curiositySelections: [String]
    var nmCardResponse: String?                 // Card Reveal pill selection — nil if skipped. Kept for existing profiles.
    var openerDeckType: OpenerDeckType          // assigned silently after CuriosityPhase round 2

    // MARK: - Onboarding State

    var hasCompletedOnboarding: Bool
    var onboardingCompletedAt: Date?
    var onboardingDropoffScreen: String?        // analytics — where they left
    var groundRulesAcceptedAt: Date?            // written from home screen flow — never delete
    var acknowledgementAcceptedAt: Date?        // 3-card modal — never delete

    // MARK: - Link State

    var isLinked: Bool
    var coupleId: UUID?
    var linkedAt: Date?                         // when pairing completed — never delete
    var firstInviteSentAt: Date?                // when the FIRST invite code was generated for
                                                 // this pairing attempt — drives the nudge
                                                 // threshold, untouched by later regenerations.
                                                 // Cleared on successful link.

    // MARK: - Desire Map

    var hasCompletedDesireMap: Bool

    // MARK: - Identity Card (Map)
    // Net-new V1 identity, set on the Me Card and persisted here. Optional so the
    // additive change is a lightweight SwiftData migration (no real users yet).

    var flavor: String?         // Flavor.rawValue — explorer / anchor / catalyst / architect
    var chosenTitle: String?    // the Title chosen from the flavor's shortlist

    // MARK: - Init

    init(
        displayName: String = "",
        genderIdentity: String? = nil,
        pronouns: [String] = [],
        partnerGenderIdentity: String? = nil,
        partnerPronouns: String? = nil,
        nmStage: NMStage = .curious,
        appMode: AppMode = .together,
        relationshipContext: String? = nil,
        situationalRegister: String? = nil,
        emotionalRegister: String? = nil,
        demoVerb: String? = nil,
        demoNoun: String? = nil,
        ageRange: AgeRange? = nil,
        agency: String? = nil,
        motivation: String? = nil,
        compassNotes: [String] = [],
        archetype: ArchetypeTag = .curious,
        curiositySelections: [String] = [],
        nmCardResponse: String? = nil,
        openerDeckType: OpenerDeckType = .anxious,
        flavor: String? = nil,
        chosenTitle: String? = nil
    ) {
        self.id = UUID()
        self.accountId = nil
        self.displayName = displayName
        self.genderIdentity = genderIdentity
        self.pronouns = pronouns
        self.partnerGenderIdentity = partnerGenderIdentity
        self.partnerPronouns = partnerPronouns
        self.createdAt = Date()
        self.nmStage = nmStage
        self.appMode = appMode
        self.relationshipContext = relationshipContext
        self.situationalRegister = situationalRegister
        self.emotionalRegister = emotionalRegister
        self.demoVerb = demoVerb
        self.demoNoun = demoNoun
        self.ageRange = ageRange
        self.agency = agency
        self.motivation = motivation
        self.compassNotes = compassNotes
        self.archetype = archetype
        self.curiositySelections = curiositySelections
        self.nmCardResponse = nmCardResponse
        self.openerDeckType = openerDeckType
        self.hasCompletedOnboarding = false
        self.onboardingCompletedAt = nil
        self.onboardingDropoffScreen = nil
        self.groundRulesAcceptedAt = nil
        self.acknowledgementAcceptedAt = nil
        self.isLinked = false
        self.coupleId = nil
        self.linkedAt = nil
        self.firstInviteSentAt = nil
        self.hasCompletedDesireMap = false
        self.flavor = flavor
        self.chosenTitle = chosenTitle
    }

    // MARK: - Computed

    var displayInitial: String {
        String(displayName.prefix(1)).uppercased()
    }

    var linkState: LinkState {
        isLinked ? .linked : .unlinked
    }

    /// Default card intensity derived from NM stage.
    /// Never stored independently — always derived.
    var defaultIntensity: CardIntensity {
        nmStage.defaultDifficulty
    }

    // MARK: - Preview Helpers

    static let example = UserProfile(
        displayName: "Jordan",
        genderIdentity: "non-binary",
        pronouns: ["they/them"],
        nmStage: .curious,
        appMode: .together,
        emotionalRegister: nil,
        ageRange: nil
    )

    static let soloExample = UserProfile(
        displayName: "Riley",
        genderIdentity: "woman",
        pronouns: ["she/her"],
        nmStage: .curious,
        appMode: .solo,
        emotionalRegister: nil,
        ageRange: nil
    )

    static let linkedExample: UserProfile = {
        let p = UserProfile(
            displayName: "Alex",
            genderIdentity: "man",
            pronouns: ["he/him"],
            partnerGenderIdentity: "woman",
            nmStage: .exploring,
            appMode: .together,
            emotionalRegister: nil,
            ageRange: nil
        )
        p.isLinked = true
        p.coupleId = UUID()
        p.linkedAt = Date()
        p.hasCompletedOnboarding = true
        p.onboardingCompletedAt = Date()
        return p
    }()
}
