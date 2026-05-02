import SwiftUI
import SwiftData

struct ProgressDashboardView: View {
    // MARK: - Environment
    @Environment(\.modelContext) private var modelContext

    // TODO: DataStore should be injected via init, not rebuilt from environment on every access
    private var store: DataStore { DataStore(context: modelContext) }
    /// The single streak record — current streak, totals, etc.
    private var streak: StreakRecord { store.fetchOrCreateStreak() }
    /// All sessions ever, newest first.
    private var allSessions: [SessionRecord] { store.fetchAllSessions() }

    // MARK: - Placeholder Data
    private let categoryMeta: [(name: String, emoji: String)] = [
        ("Communication", "💬"),
        ("Sensory",        "🌡️"),
        ("Trust",          "🤝"),
        ("Adventure",      "🧭"),
        ("Romance",        "💕"),
        ("Playful",        "🎭")
    ]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: AppSpacing.xl) {            // was 28 → xl (32), snap per handoff
                header
                scoreSection
                categoryBreakdown
                recentActivity
            }
            .padding(.horizontal, AppSpacing.lg)        // was 20 → lg (24), snap per handoff
            .padding(.top, AppSpacing.md)               // was 16 → md, exact
            .padding(.bottom, AppSpacing.xxl)           // was 40 → xxl (48), snap per handoff
        }
        .background(AppColors.pageBackground.ignoresSafeArea())
        .screenshotProtected()
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: AppSpacing.xs) {                // was 4 → xs, exact
            Text("Progress")
                .font(AppFonts.screenTitle)
                .foregroundColor(AppColors.textPrimary)
            Text("\(totalCompleted) prompts rated · \(allSessions.count) sessions")
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textTertiary)
        }
    }

    // MARK: - Score Ring

    private var scoreSection: some View {
        VStack(spacing: AppSpacing.md) {                // was 16 → md, exact
            ScoreRing(score: overallScore, size: 120, lineWidth: 10)

            Text("Exploration Score")
                .font(AppFonts.bodyMedium)
                .foregroundColor(AppColors.textSecondary)

            Text("Based on prompts completed, variety, and consistency")
                .font(AppFonts.meta)
                .foregroundColor(AppColors.textMuted)
                .multilineTextAlignment(.center)
        }
        .padding(AppSpacing.lg)                         // was 20 → lg (24), snap per handoff
        .cardStyle(cornerRadius: AppRadius.lg)          // was cornerRadius: AppRadius.lg → lg, exact
    }

    // MARK: - Category Breakdown

    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) { // was 14 → md (16), snap per handoff
            SectionHeader("CATEGORIES")
                .padding(.leading, AppSpacing.xs)       // was 4 → xs, exact
            SettingsCard {
                VStack(spacing: AppSpacing.sm) {        // was 12 → sm (8), snap per handoff
                    ForEach(categoryMeta, id: \.name) { meta in
                        let stats = statsForCategory(meta.name)
                        categoryRow((
                            name:      meta.name,
                            emoji:     meta.emoji,
                            completed: stats.completed,
                            total:     stats.total
                        ))
                    }
                }
            }
        }
    }

    private func categoryRow(
        _ stat: (name: String, emoji: String, completed: Double, total: Double)
    ) -> some View {
        VStack(spacing: AppSpacing.sm) {                // was 6 → sm (8), snap per handoff
            HStack {
                Text(stat.emoji)
                    .font(
                        Font.custom("Switzer-Regular", size: 16, relativeTo: .body)
                    )                                   // was .system(size: 16)
                    // Note: emoji renders from system glyph regardless of font name —
                    // the constructor is required per rules even though the glyph is system-drawn

                Text(stat.name)
                    .font(AppFonts.bodyMedium)
                    .foregroundColor(AppColors.textPrimary)

                Spacer()

                Text("\(Int(stat.completed))/\(Int(stat.total))")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textTertiary)
            }

            ProgressBar(value: stat.completed, max: stat.total)
        }
    }

    // MARK: - Recent Activity

    private var recentActivity: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) { // was 14 → md (16), snap per handoff
            SectionHeader("RECENT SESSIONS")
                .padding(.leading, AppSpacing.xs)       // was 4 → xs, exact

            if allSessions.isEmpty {
                // Empty state — no sessions yet
                Text("No sessions yet. Start your first one!")
                    .font(AppFonts.bodyText)
                    .foregroundColor(AppColors.textMuted)
                    .frame(maxWidth: .infinity)
                    .padding(AppSpacing.lg)             // was 20 → lg (24), snap per handoff
                    .cardStyle()
            } else {
                VStack(spacing: 0) {
                    // Show up to 5 most recent sessions
                    ForEach(
                        Array(allSessions.prefix(5).enumerated()),
                        id: \.offset
                    ) { index, session in
                        if index > 0 {
                            Divider()
                                .background(AppColors.borderSubtle)
                        }
                        HStack {
                            VStack(alignment: .leading, spacing: AppSpacing.xxs) { // was 2 → xxs, exact
                                Text(session.category)
                                    .font(AppFonts.bodyMedium)
                                    .foregroundColor(AppColors.textPrimary)
                                Text(
                                    "\(session.promptsShown.count) prompts · \(session.durationSeconds / 60) min"
                                )
                                .font(AppFonts.meta)
                                .foregroundColor(AppColors.textMuted)
                            }
                            Spacer()
                            Text(session.date, style: .relative)
                                .font(AppFonts.caption)
                                .foregroundColor(AppColors.textTertiary)
                        }
                        .padding(.vertical, AppSpacing.sm)  // was 12 → sm (8), snap per handoff
                        .padding(.horizontal, AppSpacing.md) // was 16 → md, exact
                    }
                }
                .cardStyle()
            }
        }
    }

    // MARK: - Computed Properties

    /// Overall exploration score: weighted blend of total sessions, variety, and streak.
    /// Returns 0–100.
    private var overallScore: Int {
        let sessionScore  = min(Double(streak.totalSessions)    / 60.0,                              1.0) * 40
        let varietyScore  = min(Double(categoriesExplored)      / Double(categoryMeta.count),        1.0) * 30
        let streakScore   = min(Double(streak.currentStreak)    / 14.0,                              1.0) * 30
        return Int(sessionScore + varietyScore + streakScore)
    }

    /// How many distinct categories the user has completed at least one session in.
    private var categoriesExplored: Int {
        Set(allSessions.map(\.category)).count
    }

    /// Total prompts rated across all sessions.
    private var totalCompleted: Int { streak.totalPromptsRated }

    /// Builds a (completed, total) pair for a given category.
    /// completed = number of ratings in that category.
    /// total = completed + a buffer so the bar is never completely full too early.
    private func statsForCategory(_ name: String) -> (completed: Double, total: Double) {
        let ratings   = store.fetchRatings(forCategory: name)
        let completed = Double(ratings.count)
        let total     = max(completed, 10) // minimum 10 so bars don't look maxed out immediately
        return (completed, total)
    }
}

#Preview {
    ProgressDashboardView()
        .preferredColorScheme(.dark)
        .modelContainer(ModelContainer.previewContainer)
}
