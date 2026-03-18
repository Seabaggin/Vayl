//
//  Couple.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import Foundation
import SwiftData

@Model
final class Couple: Identifiable {

    // MARK: - Properties

    var id: UUID = UUID()
    var createdAt: Date = Date()

    // References to the two partners. No cascade — deleting
    // a Couple does NOT delete the UserProfiles.
    var partnerA: UserProfile?
    var partnerB: UserProfile?

    // MARK: - Shared Settings

    /// Safe word agreed upon by both partners.
    /// Default traffic light system: "red" / "yellow" / "green"
    /// Can be customized during onboarding or in Settings.
    var sharedSafeWord: String = "red"

    /// Whether kink map mutual matches have been revealed.
    /// Stays false until both partners complete their ratings
    /// and tap "Reveal Matches."
    var matchesRevealed: Bool = false

    // MARK: - Relationships

    @Relationship(deleteRule: .cascade)
    var cardProgress: [CardProgress] = []

    @Relationship(deleteRule: .cascade)
    var sessionRecords: [CoupleSessionRecord] = []

    @Relationship(deleteRule: .cascade)
    var desireMatches: [DesireMatch] = []

    // MARK: - Initializer

    init(
        partnerA: UserProfile? = nil,
        partnerB: UserProfile? = nil,
        sharedSafeWord: String = "red"
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.partnerA = partnerA
        self.partnerB = partnerB
        self.sharedSafeWord = sharedSafeWord
    }

    // MARK: - Preview Helpers

    static let example = Couple()
}
