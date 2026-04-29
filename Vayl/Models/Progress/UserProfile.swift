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
    var pronouns: [String]
    var createdAt: Date

    // MARK: - Onboarding Routing

    var nmStage: NMStage                        // curious / exploring / experienced
    var appMode: AppMode                        // together / solo / browsing
    var emotionalRegister: EmotionalRegister    // anxious / excited / flexible
    var archetype: ArchetypeTag                 // internal only — never shown
    var curiositySelections: [String]
    var nmCardResponse: String?                 // Card Reveal pill selection — nil if skipped

    // MARK: - Onboarding State

    var hasCompletedOnboarding: Bool
    var onboardingCompletedAt: Date?
    var onboardingDropoffScreen: String?        // analytics — where they left
    var groundRulesAcceptedAt: Date?            // legal — never delete
    var acknowledgementAcceptedAt: Date?        // 3-card modal — never delete

    // MARK: - Link State

    var isLinked: Bool
    var coupleId: UUID?
    var linkedAt: Date?                         // when pairing completed — never delete

    // MARK: - Desire Map

    var hasCompletedDesireMap: Bool

    // MARK: - Init

    init(
        displayName: String = "",
        pronouns: [String] = [],
        nmStage: NMStage = .curious,
        appMode: AppMode = .together,
        emotionalRegister: EmotionalRegister = .flexible,
        archetype: ArchetypeTag = .curious,
        curiositySelections: [String] = [],
        nmCardResponse: String? = nil
    ) {
        self.id = UUID()
        self.accountId = nil
        self.displayName = displayName
        self.pronouns = pronouns
        self.createdAt = Date()
        self.nmStage = nmStage
        self.appMode = appMode
        self.emotionalRegister = emotionalRegister
        self.archetype = archetype
        self.curiositySelections = curiositySelections
        self.nmCardResponse = nmCardResponse
        self.hasCompletedOnboarding = false
        self.onboardingCompletedAt = nil
        self.onboardingDropoffScreen = nil
        self.groundRulesAcceptedAt = nil
        self.acknowledgementAcceptedAt = nil
        self.isLinked = false
        self.coupleId = nil
        self.linkedAt = nil
        self.hasCompletedDesireMap = false
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
        pronouns: ["they/them"],
        nmStage: .curious,
        appMode: .together,
        emotionalRegister: .flexible
    )

    static let soloExample = UserProfile(
        displayName: "Riley",
        pronouns: ["she/her"],
        nmStage: .curious,
        appMode: .solo,
        emotionalRegister: .anxious
    )

    static let linkedExample: UserProfile = {
        let p = UserProfile(
            displayName: "Alex",
            pronouns: ["he/him"],
            nmStage: .exploring,
            appMode: .together,
            emotionalRegister: .excited
        )
        p.isLinked = true
        p.coupleId = UUID()
        p.linkedAt = Date()
        p.hasCompletedOnboarding = true
        p.onboardingCompletedAt = Date()
        return p
    }()
}
