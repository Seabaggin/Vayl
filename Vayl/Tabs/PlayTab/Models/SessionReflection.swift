//
//  SessionReflection.swift
//  Vayl
//
//  Location: Models/Persistence/SessionReflection.swift
//
//  The private, per-person reflection captured at the close of a couple
//  card session. One row per person, per session. Device only — never
//  synced to Supabase (a reflection is for your own Mirror/Map, not shared).
//
//  This is the only place communication gets coached — after, by your own
//  noticing, never mid-session. It shapes the Map as trends, not grades.
//

import Foundation
import SwiftData

// MARK: - SessionReflection

@Model
final class SessionReflection {

    // MARK: - Identity

    var id: UUID
    var cardSessionId: UUID

    // MARK: - Reflection content

    /// Words picked from the bank (or typed) that fit how the session felt.
    /// Each carries no valence here — the Map derives trend from the word set.
    var words: [String]

    /// "who carried it" — 0.0 = you, 0.5 = even, 1.0 = partner.
    var carriedBalance: Double

    /// "did you feel heard" — 0.0 = not really, 1.0 = fully.
    var feltHeard: Double

    /// Optional free note — a line for future-you about tonight.
    var note: String?

    // MARK: - Timestamp

    var createdAt: Date

    // MARK: - Init

    init(
        cardSessionId: UUID,
        words: [String],
        carriedBalance: Double,
        feltHeard: Double,
        note: String? = nil
    ) {
        self.id = UUID()
        self.cardSessionId = cardSessionId
        self.words = words
        self.carriedBalance = carriedBalance
        self.feltHeard = feltHeard
        self.note = note
        self.createdAt = Date()
    }

    // MARK: - Preview Helper

    @MainActor static let example = SessionReflection(
        cardSessionId: UUID(),
        words: ["close", "honest"],
        carriedBalance: 0.5,
        feltHeard: 0.72,
        note: nil
    )
}
