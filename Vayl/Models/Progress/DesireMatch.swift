//
//  DesireMatch.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import Foundation
import SwiftData

// ============================================================
// DesireMatch.swift
// A SwiftData model representing a positive alignment between two
// partners for a specific desire map item. A DesireMatch is only
// created when the alignment logic yields a positive result.
// Combinations involving a boundary never produce a DesireMatch.
//
// This model is owned by a Couple and records the alignment level
// as well as the original ratings from each partner.
// ============================================================

@Model
final class DesireMatch: Identifiable {

    // MARK: - Properties

    var id: UUID = UUID()

    // Matches ContentDesireItem.id (e.g. "desire-001")
    var desireItemId: String

    // The alignment level returned by the alignment engine
    var alignmentLevel: String

    // What partner A rated this item
    var ratingA: DesireLevel

    // What partner B rated this item
    var ratingB: DesireLevel

    // When this match was computed/stored
    var computedAt: Date = Date()

    // Optional: partner values, gap, bridge card
    var partnerAValue: String?
    var partnerBValue: String?
    var gapSize: Int?
    var bridgeCardId: String?


    // MARK: - Relationships

    // The Couple that owns this match record (inverse declared on Couple)
    @Relationship
    var couple: Couple?


    // MARK: - Initializer

    init(
        desireItemId: String,
        alignmentLevel: String,
        ratingA: DesireLevel,
        ratingB: DesireLevel,
        partnerAValue: String? = nil,
        partnerBValue: String? = nil,
        gapSize: Int? = nil,
        bridgeCardId: String? = nil
    ) {
        self.id = UUID()
        self.desireItemId = desireItemId
        self.alignmentLevel = alignmentLevel
        self.ratingA = ratingA
        self.ratingB = ratingB
        self.computedAt = Date()
        self.partnerAValue = partnerAValue
        self.partnerBValue = partnerBValue
        self.gapSize = gapSize
        self.bridgeCardId = bridgeCardId
    }


    // MARK: - Preview Helpers

    static let example = DesireMatch(desireItemId: "desire-001", alignmentLevel: AlignmentLevel.strongAlignment.rawValue, ratingA: DesireLevel.excitedAboutIt, ratingB: DesireLevel.openToIt)
}
