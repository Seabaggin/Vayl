//
//  StreakRecord.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/9/26.
//


import Foundation
import SwiftData

// MARK: - StreakRecord
// Tracks the user's consecutive-day usage streaks.
// Only ONE StreakRecord should exist at any time — it gets updated, not duplicated.
// DataStore will handle the "fetch or create" logic to enforce this.

@Model
final class StreakRecord {

    // MARK: - Identity

    /// Unique identifier. Only one record exists, but SwiftData requires a stable ID.
    var id: UUID

    // MARK: - Current Streak

    /// How many consecutive days the user has completed at least one session.
    /// Resets to 1 if they miss a day, increments if they play on consecutive days.
    var currentStreak: Int

    /// The date the user last completed a session.
    /// Used to determine if today is consecutive (yesterday or today)
    /// or if the streak should reset.
    var lastActiveDate: Date

    // MARK: - Best Streak

    /// The longest streak the user has ever achieved.
    /// Only updates when currentStreak surpasses it — never decreases.
    var longestStreak: Int

    // MARK: - Stats

    /// Total number of sessions completed across all time.
    /// Incremented by 1 every time a session is saved, regardless of streaks.
    var totalSessions: Int

    /// Total number of prompts the user has rated across all sessions.
    /// Useful for milestone badges or progress displays.
    var totalPromptsRated: Int

    // MARK: - Init

    /// Creates a new StreakRecord with fresh-start defaults.
    /// - Parameters:
    ///   - id: Auto-generated UUID. Override only for testing/previews.
    ///   - currentStreak: Defaults to 0 (no sessions yet).
    ///   - lastActiveDate: Defaults to .distantPast so first session always counts.
    ///   - longestStreak: Defaults to 0.
    ///   - totalSessions: Defaults to 0.
    ///   - totalPromptsRated: Defaults to 0.
    init(
        id: UUID = UUID(),
        currentStreak: Int = 0,
        lastActiveDate: Date = .distantPast,
        longestStreak: Int = 0,
        totalSessions: Int = 0,
        totalPromptsRated: Int = 0
    ) {
        self.id = id
        self.currentStreak = currentStreak
        self.lastActiveDate = lastActiveDate
        self.longestStreak = longestStreak
        self.totalSessions = totalSessions
        self.totalPromptsRated = totalPromptsRated
    }
}