//
//  DesireRating.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import Foundation
import SwiftData

// ============================================================
// DesireRating.swift
// A SwiftData model storing one person's private rating for
// a single desire map item. Ratings are private and only used
// to compute DesireMatch results; the raw ratings are never
// exposed to the partner.
//
// This model is owned by a UserProfile and represents a single
// response on the Desire Map.
// ============================================================

@Model
final class DesireRating: Identifiable {

    // MARK: - Properties

    var id: UUID = UUID()

    // Matches ContentDesireItem.id (e.g. "desire-001")
    var desireItemId: String

    // Partner's private rating for this item
    var rating: DesireLevel

    // When the rating was recorded
    var ratedAt: Date = Date()


    // MARK: - Relationships

    // Owner is the UserProfile who created this rating. The inverse
    // relationship is defined on UserProfile.desireRatings and handles
    // cascade deletion when a UserProfile is removed.
    @Relationship
    var owner: UserProfile?


    // MARK: - Initializer

    init(
        desireItemId: String,
        rating: DesireLevel
    ) {
        self.id = UUID()
        self.desireItemId = desireItemId
        self.rating = rating
        self.ratedAt = Date()
    }


    // MARK: - Preview Helpers

    static let example = DesireRating(desireItemId: "desire-001", rating: DesireLevel.openToIt)
}
