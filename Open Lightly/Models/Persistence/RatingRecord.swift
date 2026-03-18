//
//  RatingRecord.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/9/26.
//


import Foundation
import SwiftData

// MARK: - RatingRecord
// Stores the user's reaction to a single prompt within a session.
// One RatingRecord per prompt shown — so a 5-prompt session creates 5 of these.
// Owned by a SessionRecord via cascade delete (parent dies, these die too).

@Model
final class RatingRecord {

    // MARK: - Identity

    /// Unique identifier for this rating. Auto-generated on creation.
    var id: UUID

    /// Timestamp of when the user rated this prompt.
    var date: Date

    // MARK: - Prompt Info

    /// The exact prompt text the user was shown.
    /// Stored as a String so we can display it in history/progress screens.
    var promptText: String

    /// The category this prompt belongs to (e.g. "Sensation", "Power").
    /// Raw string — convert back to your enum at read time.
    var category: String

    // MARK: - User Reaction

    /// What the user did with this prompt.
    /// "liked" = thumbs up / heart
    /// "disliked" = thumbs down
    /// "skipped" = swiped past without rating
    /// Stored as String to keep SwiftData happy — no enum storage issues.
    var reaction: String

    // MARK: - Relationship (Inverse)

    /// The session this rating belongs to.
    /// SwiftData auto-wires this as the inverse of SessionRecord.ratings.
    /// nil only if the record is orphaned (shouldn't happen with cascade delete).
    var session: SessionRecord?

    // MARK: - Init

    /// Creates a new RatingRecord.
    /// - Parameters:
    ///   - id: Auto-generated UUID. Override only for testing/previews.
    ///   - date: Defaults to now.
    ///   - promptText: The prompt string the user saw.
    ///   - category: Raw string of the prompt's category.
    ///   - reaction: "liked", "disliked", or "skipped".
    ///   - session: The parent SessionRecord. Set automatically when appended to session.ratings.
    init(
        id: UUID = UUID(),
        date: Date = .now,
        promptText: String,
        category: String,
        reaction: String,
        session: SessionRecord? = nil
    ) {
        self.id = id
        self.date = date
        self.promptText = promptText
        self.category = category
        self.reaction = reaction
        self.session = session
    }
}