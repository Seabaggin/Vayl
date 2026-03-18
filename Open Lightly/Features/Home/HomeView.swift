import SwiftUI
import SwiftData

struct HomeView: View {
    // MARK: - Placeholder Data
    private let categories: [(emoji: String, title: String, completed: Int, total: Int)] = [
        ("bubble.left.and.bubble.right.fill", "Communication", 3, 12),
        ("hand.raised.fingers.spread.fill", "Sensory", 1, 10),
        ("lock.shield.fill", "Trust", 0, 8),
        ("compass.drawing", "Adventure", 2, 14),
        ("heart.fill", "Romance", 5, 10),
        ("theatermasks.fill", "Playful", 0, 6)
    ]
    
    @Environment(\.modelContext) private var modelContext
    
    /// Live DataStore instance built from the environment context.
    private var store: DataStore { DataStore(context: modelContext) }
    /// The single streak record — holds streaks, totals, last active date.
    private var streak: StreakRecord { store.fetchOrCreateStreak() }
    /// All sessions ever, newest first.
    private var allSessions: [SessionRecord] { store.fetchAllSessions() }
    /// The most recent session, if one exists.
    private var lastSession: SessionRecord? { allSessions.first }
    /// Overall progress based on total sessions vs a milestone target (e.g. 60 sessions).
    /// Adjust the denominator as the app grows.
    private var overallProgress: Double {
        let target = 60.0
        return min(Double(streak.totalSessions) / target, 1.0)
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 32) {
                header
                streakBanner
                ringSection
                lastSessionCard
                categoryGrid
                startButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .background(AppColors.background.ignoresSafeArea())
    }
    
    // MARK: - Header
    private var header: some View {
        VStack(spacing: 6) {
            KeywordHighlightText(
                fullText: "Open Lightly",
                keywords: [("Open", "cyan"), ("Lightly", "magenta")],
                font: AppFonts.heroTitle
            )
            
            Text("Your intimacy journey")
                .font(AppFonts.bodyText)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
    
    // MARK: - Streak Banner
    private var streakBanner: some View {
        HStack(spacing: 16) {
            // Streak flame
            VStack(spacing: 4) {
                Text("🔥")
                    .font(.system(size: 28))
                Text("\(streak.currentStreak)")
                    .font(AppFonts.sectionHeader)
                    .foregroundColor(AppColors.textPrimary)
                Text("day streak")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textTertiary)
            }
            .frame(maxWidth: .infinity)

            // Divider
            Rectangle()
                .fill(AppColors.border)
                .frame(width: 1, height: 48)

            // Total sessions
            VStack(spacing: 4) {
                Text("💫")
                    .font(.system(size: 28))
                Text("\(streak.totalSessions)")
                    .font(AppFonts.sectionHeader)
                    .foregroundColor(AppColors.textPrimary)
                Text("sessions")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textTertiary)
            }
            .frame(maxWidth: .infinity)

            // Divider
            Rectangle()
                .fill(AppColors.border)
                .frame(width: 1, height: 48)

            // Best streak
            VStack(spacing: 4) {
                Text("⭐")
                    .font(.system(size: 28))
                Text("\(streak.longestStreak)")
                    .font(AppFonts.sectionHeader)
                    .foregroundColor(AppColors.textPrimary)
                Text("best streak")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textTertiary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .cardStyle(background: AppColors.surfaceBg, cornerRadius: 16)
    }
    
    // MARK: - Progress Ring
    private var ringSection: some View {
        VStack(spacing: 12) {
            ProgressRingView(progress: overallProgress, lineWidth: 8, size: 100)
            
            Text("\(streak.totalPromptsRated) prompts rated")
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textTertiary)
        }
    }
    
    // MARK: - Category Grid
    private var categoryGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("CATEGORIES")
                .padding(.leading, 4)
            
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 14),
                    GridItem(.flexible(), spacing: 14)
                ],
                spacing: 14
            ) {
                ForEach(categories, id: \.title) { cat in
                    CategoryTileView(
                        emoji: cat.emoji,
                        title: cat.title,
                        completedCards: cat.completed,
                        totalCards: cat.total
                    )
                }
            }
        }
    }
    
    // MARK: - Last Session
    @ViewBuilder
    private var lastSessionCard: some View {
        if let session = lastSession {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader("LAST SESSION")
                    .padding(.leading, 4)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(session.category)
                            .font(AppFonts.bodyText)
                            .foregroundColor(AppColors.textPrimary)

                        Text("\(session.promptsShown.count) prompts · \(session.durationSeconds / 60) min")
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.textTertiary)
                    }

                    Spacer()

                    Text(session.date, style: .relative)
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textMuted)
                }
                .padding(16)
                .cardStyle(background: AppColors.surfaceBg, cornerRadius: 12)
            }
        }
    }
    
    // MARK: - CTA
    private var startButton: some View {
        GradientButton(title: "Begin Session") {
            // Navigation wired in later
            #if DEBUG
            print("[HomeView] Navigate to session")
            #endif
        }
        .padding(.top, 8)
    }
}

#Preview {
    HomeView()
        .preferredColorScheme(.dark)
        .modelContainer(ModelContainer.previewContainer)
}
