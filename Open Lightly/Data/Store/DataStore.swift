import Foundation
import SwiftData

// MARK: - DataStore
// Central persistence layer for Open Lightly.
// Every read/write to SwiftData goes through here.
// Instantiated with a ModelContext from the environment.
//
// Usage:
//   let store = DataStore(context: modelContext)
//   store.saveSession(...)

final class DataStore {

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Sessions

    /// Saves a completed session along with its individual prompt ratings.
    /// Also updates the streak record.
    ///
    /// - Parameters:
    ///   - category: Raw string of the session's primary category
    ///   - difficulty: Raw string of the session's difficulty level
    ///   - promptsShown: Array of prompt text strings shown during the session
    ///   - durationSeconds: Total session length in seconds
    ///   - reactions: Array of tuples — each has the prompt text, category, and reaction string
    ///   - partnerName: Optional partner display name (nil for solo)
    ///   - completedFully: false if the user safe-worded out early
    func saveSession(
        category: String,
        difficulty: String,
        promptsShown: [String],
        durationSeconds: Int,
        reactions: [(promptText: String, category: String, reaction: String)],
        partnerName: String?,
        completedFully: Bool
    ) {
        // 1. Create the parent session record
        let session = SessionRecord(
            category: category,
            difficulty: difficulty,
            promptsShown: promptsShown,
            durationSeconds: durationSeconds,
            partnerName: partnerName,
            completedFully: completedFully
        )
        context.insert(session)

        // 2. Create a RatingRecord for each reaction, linked to the session
        for reaction in reactions {
            let rating = RatingRecord(
                promptText: reaction.promptText,
                category: reaction.category,
                reaction: reaction.reaction,
                session: session
            )
            context.insert(rating)
        }

        // 3. Update the streak
        let streak = fetchOrCreateStreak()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let lastActive = calendar.startOfDay(for: streak.lastActiveDate)

        if lastActive == today {
            // Already logged today — just bump counts
        } else if calendar.isDate(lastActive, equalTo: today - 86400, toGranularity: .day) {
            // Consecutive day — extend streak
            streak.currentStreak += 1
        } else {
            // Gap — reset streak
            streak.currentStreak = 1
        }

        if streak.currentStreak > streak.longestStreak {
            streak.longestStreak = streak.currentStreak
        }

        streak.lastActiveDate = .now
        streak.totalSessions += 1
        streak.totalPromptsRated += reactions.count

        try? context.save()
    }

    /// Fetches all sessions, newest first.
    func fetchAllSessions() -> [SessionRecord] {
        let descriptor = FetchDescriptor<SessionRecord>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Fetches sessions for a specific category.
    func fetchSessions(forCategory category: String) -> [SessionRecord] {
        let descriptor = FetchDescriptor<SessionRecord>(
            predicate: #Predicate { $0.category == category },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    // MARK: - Ratings

    /// Fetches all ratings with a specific reaction (e.g. "liked", "disliked", "skipped").
    func fetchRatings(byReaction reaction: String) -> [RatingRecord] {
        let descriptor = FetchDescriptor<RatingRecord>(
            predicate: #Predicate { $0.reaction == reaction }
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Fetches all ratings for a specific category.
    func fetchRatings(forCategory category: String) -> [RatingRecord] {
        let descriptor = FetchDescriptor<RatingRecord>(
            predicate: #Predicate { $0.category == category }
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    // MARK: - Desire Map Ratings

    /// Fetches a single rating record by prompt ID (used for desire map items).
    /// Returns nil if no rating exists yet for this prompt.
    func fetchRating(forPromptId promptId: String) -> RatingRecord? {
        let descriptor = FetchDescriptor<RatingRecord>(
            predicate: #Predicate { $0.promptText == promptId }
        )
        return try? context.fetch(descriptor).first
    }

    /// Saves or updates a desire map rating.
    /// Desire ratings are stored as RatingRecords with no parent session.
    func saveDesireRating(itemId: String, category: String, level: DesireLevel) {
        if let existing = fetchRating(forPromptId: itemId) {
            existing.reaction = String(level.rawValue)
        } else {
            let record = RatingRecord(
                promptText: itemId,
                category: category,
                reaction: String(level.rawValue),
                session: nil
            )
            context.insert(record)
        }
        try? context.save()
    }

    // MARK: - Streak

    /// Fetches the single streak record, or creates one if none exists.
    /// There should only ever be one StreakRecord in the store.
    func fetchOrCreateStreak() -> StreakRecord {
        let descriptor = FetchDescriptor<StreakRecord>()
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let streak = StreakRecord()
        context.insert(streak)
        try? context.save()
        return streak
    }

    // MARK: - User Profile

    /// Fetches the current user's profile, or creates a default one.
    /// There should only ever be one UserProfile on device.
    func fetchOrCreateProfile() -> UserProfile {
        let descriptor = FetchDescriptor<UserProfile>()
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let profile = UserProfile()
        context.insert(profile)
        try? context.save()
        return profile
    }

    /// Saves any pending changes to the user profile.
    func saveProfile() {
        try? context.save()
    }

    // MARK: - Danger Zone

    /// Deletes a single session and its child ratings (cascade).
    func deleteSession(_ session: SessionRecord) {
        context.delete(session)
        try? context.save()
    }

    /// Nukes everything. Used for "Start Over" in Settings.
    /// Deletes all sessions, ratings, streak, and user profile.
    func deleteAllData() {
        // Sessions (ratings cascade automatically)
        let sessions = fetchAllSessions()
        for session in sessions {
            context.delete(session)
        }

        // Streak
        let streakDescriptor = FetchDescriptor<StreakRecord>()
        if let streaks = try? context.fetch(streakDescriptor) {
            for streak in streaks {
                context.delete(streak)
            }
        }

        // User Profile
        let profileDescriptor = FetchDescriptor<UserProfile>()
        if let profiles = try? context.fetch(profileDescriptor) {
            for profile in profiles {
                context.delete(profile)
            }
        }

        try? context.save()
    }
}
