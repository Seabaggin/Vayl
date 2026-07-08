//
//  AcknowledgementRecord.swift
//  Vayl
//
//  Created by Bryan Jorden on 4/27/26.
//

//
//  AcknowledgementRecord.swift
//  Vayl
//
//  Location: Models/Persistence/AcknowledgementRecord.swift
//

import Foundation
import SwiftData

// MARK: - AcknowledgementRecord
// Records that a user tapped through the 3-card ground rules modal
// that appears between Card 1 and Card 2 of The Opener.
// Device only — never synced to Supabase.
//
// This is a legal and ethical record — never delete it.
// version field is critical — if acknowledgement copy ever changes,
// increment the version constant below. Any user with an older
// version number will see the updated acknowledgement again.
//
// cardsAcknowledged confirms sequential tapping — documents the
// interaction if the UI flow is ever questioned.
// acknowledgedAt is stored with full precision — never truncated.

@Model
final class AcknowledgementRecord {

    // MARK: - Current Version
    // Increment this when acknowledgement copy changes.
    // Users with a lower version will see the modal again.
    static let currentVersion = 1

    // MARK: - Identity

    var id: UUID
    var userId: UUID

    // MARK: - Acknowledgement

    var acknowledgedAt: Date
    var version: Int                // increment if copy changes — re-prompts old versions
    var cardsAcknowledged: [String] // which of the 3 statements were tapped, in order

    // MARK: - Init

    init(userId: UUID, cardsAcknowledged: [String]) {
        self.id = UUID()
        self.userId = userId
        self.acknowledgedAt = Date()
        self.version = AcknowledgementRecord.currentVersion
        self.cardsAcknowledged = cardsAcknowledged
    }

    // MARK: - Computed

    /// Whether this record is current or needs to be re-acknowledged.
    /// If copy has changed since this was recorded, the user sees
    /// the modal again.
    var isCurrent: Bool {
        version >= AcknowledgementRecord.currentVersion
    }

    /// Whether all three statements were acknowledged.
    /// Three is the expected count — if fewer, the flow was interrupted.
    var isComplete: Bool {
        cardsAcknowledged.count == 3
    }

    // MARK: - Preview Helpers

    static let example = AcknowledgementRecord(
        userId: UUID(),
        cardsAcknowledged: [
            "facilitate-not-diagnose",
            "open-doors-not-push",
            "credit-the-user"
        ]
    )
}
