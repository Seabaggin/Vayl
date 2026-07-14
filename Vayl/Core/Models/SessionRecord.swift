//
//  SessionRecord.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/9/26.
//

import Foundation
import SwiftData

// MARK: - SessionRecord
// Represents a single completed (or ended-early) play session.
// One row is created each time the user finishes or exits SessionView.
// Stored via SwiftData — persists across app launches.

@Model
final class SessionRecord {

    // MARK: - Identity

    /// Unique identifier for this session. Auto-generated on creation.
    var id: UUID

    /// Timestamp of when the session was started/saved.
    var date: Date

    // MARK: - Session Metadata

    /// The category chosen for this session (e.g. "Sensation", "Power").
    /// Stored as a raw String so SwiftData doesn't choke on enums.
    /// Convert back to your enum at read time: Category(rawValue: category)
    var category: String

    /// The difficulty level selected (e.g. "warm", "hot", "blazing").
    /// Maps to PromptDifficulty.rawValue — same string-storage reason.
    var difficulty: String

    /// Ordered list of every prompt text the user was shown during this session.
    /// Stored as [String] — SwiftData handles array serialization automatically.
    var promptsShown: [String]

    /// How long the session lasted, in seconds.
    /// Captured from the timer in SessionView when the session ends.
    var durationSeconds: Int

    // MARK: - Partner (Optional — preps for Batch 9 pairing)

    /// Name of the partner, if this was a paired session.
    /// nil for solo sessions. Will be populated once Batch 9 pairing lands.
    var partnerName: String?

    // MARK: - Completion Status

    /// true = user reached the final prompt normally.
    /// false = user ended the session early.
    var completedFully: Bool

    // MARK: - Relationships

    /// All per-prompt ratings tied to this session.
    /// Cascade delete rule: deleting a SessionRecord automatically
    /// deletes all of its child RatingRecords — no orphaned data.
    @Relationship(deleteRule: .cascade)
    var ratings: [RatingRecord] = []

    // MARK: - Init

    /// Creates a new SessionRecord with sensible defaults.
    /// - Parameters:
    ///   - id: Auto-generated UUID. Override only for testing/previews.
    ///   - date: Defaults to now. Override for mock data.
    ///   - category: Raw string of the session's category.
    ///   - difficulty: Raw string of PromptDifficulty case.
    ///   - promptsShown: Array of prompt texts shown this session.
    ///   - durationSeconds: Total session time in seconds.
    ///   - partnerName: Optional partner name (nil = solo).
    ///   - completedFully: Whether the session ended naturally.
    init(
        id: UUID = UUID(),
        date: Date = .now,
        category: String,
        difficulty: String,
        promptsShown: [String],
        durationSeconds: Int,
        partnerName: String? = nil,
        completedFully: Bool = true
    ) {
        self.id = id
        self.date = date
        self.category = category
        self.difficulty = difficulty
        self.promptsShown = promptsShown
        self.durationSeconds = durationSeconds
        self.partnerName = partnerName
        self.completedFully = completedFully
    }
}
