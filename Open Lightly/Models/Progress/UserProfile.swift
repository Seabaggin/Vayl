//
//  UserProfile.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import Foundation
import SwiftData

@Model
final class UserProfile: Identifiable {

    // MARK: - Identity

    var id: UUID = UUID()
    var name: String
    var createdAt: Date = Date()
    var pronouns: String
    var sexualOrientation: String
    var rolePreference: String

    // MARK: - Mode & Experience

    var userMode: String
    var experienceLevel: String
    var defaultDifficulty: String
    var nmFlavor: NMFlavor?

    // MARK: - Curiosity & Content

    var curiositySelections: [String]
    var surpriseMeEnabled: Bool

    // MARK: - Onboarding State

    var hasCompletedOnboarding: Bool = false
    var hasCompletedAssessment: Bool = false
    var mythBusterComplete: Bool
    var mythBusterSkipped: Bool
    var onboardingDropoffScreen: String?

    // MARK: - Account & Auth

    var accountId: String?
    var accountCreated: Bool

    // MARK: - Pairing

    var pairingCode: String = ""
    var isLinked: Bool = false
    var partnerLabel: PartnerLabel?

    // MARK: - Relationships

    @Relationship(deleteRule: .cascade)
    var assessmentResponses: [AssessmentResponse] = []

    @Relationship(deleteRule: .cascade)
    var desireRatings: [DesireRating] = []

    // MARK: - Init

    init(
        id: UUID = UUID(),
        name: String = "",
        createdAt: Date = Date(),
        pronouns: String = "they/them",
        sexualOrientation: String = "prefer not to say",
        rolePreference: String = "not sure",
        userMode: String = "solo",
        experienceLevel: String = "new",
        defaultDifficulty: String = "warm",
        nmFlavor: NMFlavor? = nil,
        pairingCode: String? = nil,
        isLinked: Bool = false,
        partnerLabel: PartnerLabel? = nil,
        hasCompletedOnboarding: Bool = false,
        hasCompletedAssessment: Bool = false
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.pronouns = pronouns
        self.sexualOrientation = sexualOrientation
        self.rolePreference = rolePreference
        self.userMode = userMode
        self.experienceLevel = experienceLevel
        self.defaultDifficulty = defaultDifficulty
        self.nmFlavor = nmFlavor
        self.pairingCode = pairingCode ?? UserProfile.generatePairingCode()
        self.isLinked = isLinked
        self.partnerLabel = partnerLabel
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.hasCompletedAssessment = hasCompletedAssessment
        self.curiositySelections = []
        self.surpriseMeEnabled = false
        self.mythBusterComplete = false
        self.mythBusterSkipped = false
        self.accountId = nil
        self.accountCreated = false
        self.onboardingDropoffScreen = nil
    }

    // MARK: - Computed Properties

    var displayInitial: String {
        String(name.prefix(1)).uppercased()
    }

    var isSolo: Bool { !isLinked }

    // MARK: - Static Helpers

    static func generatePairingCode() -> String {
        let words = [
            "HONEY", "SPARK", "FLAME", "BLOOM", "VELVET",
            "LUNAR", "EMBER", "BLUSH", "SUGAR", "CEDAR",
            "ROUGE", "PEARL", "CORAL", "DUSK", "HAVEN"
        ]
        let word = words.randomElement() ?? "SPARK"
        let number = Int.random(in: 10...99)
        return "\(word) \(number)"
    }

    // MARK: - Preview Helpers

    static let example = UserProfile(name: "Jordan")

    static let linkedExample: UserProfile = {
        let p = UserProfile(name: "Riley")
        p.isLinked = true
        p.partnerLabel = PartnerLabel.partnerA
        p.hasCompletedOnboarding = true
        p.hasCompletedAssessment = true
        p.pairingCode = "SPARK 42"
        return p
    }()
}
