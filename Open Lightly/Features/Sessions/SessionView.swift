import SwiftUI
import SwiftData

struct SessionView: View {
    // MARK: - State
    @State private var currentIndex: Int = 0
    @State private var showSafeWordConfirm: Bool = false
    @State private var sessionEnded: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    @Environment(\.modelContext) private var modelContext
    @State private var cardStatuses: [(promptText: String, status: CardStatus)] = []
    @State private var sessionStartDate: Date = .now
    @State private var completedFully: Bool = true
    
    private let prompts: [Prompt] = Prompt.samples.isEmpty
        ? SessionView.fallbackPrompts
        : Array(Prompt.samples.prefix(5))
    
    private var currentPrompt: Prompt { prompts[currentIndex] }
    private var isLast: Bool { currentIndex >= prompts.count - 1 }
    
    var body: some View {
        ZStack {
            // Background
            AppColors.background.ignoresSafeArea()
            
            if sessionEnded {
                sessionCompleteView
            } else {
                sessionContent
            }
        }
        .screenshotProtected()
    }
    
    // MARK: - Main Session Content
    private var sessionContent: some View {
        VStack(spacing: 0) {
            topBar
            Spacer(minLength: 12)
            cardArea
            Spacer(minLength: 12)
            progressPips
            Spacer(minLength: 16)
            bottomControls
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text("\(currentIndex + 1) of \(prompts.count)")
                    .font(AppFonts.overline)
                    .foregroundColor(AppColors.textTertiary)
                
                Text(currentPrompt.category.displayName)
                    .font(AppFonts.sectionLabelSmall)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            // Balanced spacer for centering
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.clear)
        }
    }
    
    // MARK: - Prompt Card
    private var cardArea: some View {
        ConversationCard(prompt: currentPrompt)
            .id(currentPrompt.id) // force re-render on change
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            .animation(.easeInOut(duration: 0.35), value: currentIndex)
    }
    
    // MARK: - Progress Pips
    private var progressPips: some View {
        HStack(spacing: 8) {
            ForEach(0..<prompts.count, id: \.self) { i in
                Capsule()
                    .fill(i == currentIndex ? AppColors.cyan : AppColors.border)
                    .frame(width: i == currentIndex ? 24 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.25), value: currentIndex)
            }
        }
    }
    
    // MARK: - Bottom Controls
    private var bottomControls: some View {
        VStack(spacing: 16) {
            // Reaction buttons — like or dislike the current prompt
            HStack(spacing: 12) {
                // Skip — not ready for this card
                Button {
                    recordStatus(.skipped)
                    advanceCard()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 14))
                        Text("Not Ready")
                            .font(AppFonts.bodyMedium)
                    }
                    .foregroundColor(AppColors.textMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .cardStyle(cornerRadius: 12)
                }

                // Bookmark — save for later
                Button {
                    recordStatus(.bookmarked)
                    advanceCard()
                } label: {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.cyan)
                        .frame(width: 52, height: 48)
                        .cardStyle(cornerRadius: 12)
                }
            }

            // Discussed — primary action, full width below
            Button {
                recordStatus(.discussed)
                advanceCard()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                    Text("We Discussed This")
                        .font(AppFonts.bodyMedium)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [AppColors.magenta, AppColors.purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }
    
    // MARK: - Session Complete
    private var sessionCompleteView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.spectrumText)
            
            // Summary of discussed, skipped, and bookmarked counts
            let discussedCount = cardStatuses.filter { $0.status == .discussed }.count
            let skippedCount = cardStatuses.filter { $0.status == .skipped }.count
            let bookmarkedCount = cardStatuses.filter { $0.status == .bookmarked }.count
            VStack(spacing: 8) {
                Text("Session Complete")
                    .font(AppFonts.screenTitle)
                    .foregroundColor(AppColors.textPrimary)
                Text("You discussed \(discussedCount) of \(prompts.count) prompts")
                    .font(AppFonts.bodyMedium)
                    .foregroundColor(AppColors.textSecondary)
                if bookmarkedCount > 0 {
                    Text("\(bookmarkedCount) bookmarked for later")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.cyan)
                }
                if skippedCount > 0 {
                    Text("\(skippedCount) skipped — no pressure")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textMuted)
                }
            }
            .multilineTextAlignment(.center)

            GradientButton(title: "Done") {
                // Reset session to fresh state — dismiss() doesn't work in a tab
                withAnimation {
                    currentIndex = 0
                    sessionEnded = false
                    cardStatuses = []
                    sessionStartDate = .now
                    completedFully = true
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding(20)
    }
    
    // MARK: - Helpers
    private func advance() {
        guard !isLast else { return }
        withAnimation(.easeInOut(duration: 0.35)) {
            currentIndex += 1
        }
    }
    
    /// Records the user's action on the current card.
    private func recordStatus(_ status: CardStatus) {
        let promptText = prompts[currentIndex].text
        cardStatuses.append((promptText: promptText, status: status))
    }

    /// Moves to the next card or ends the session.
    private func advanceCard() {
        if currentIndex < prompts.count - 1 {
            withAnimation {
                currentIndex += 1
            }
        } else {
            // Session complete
            saveSession()
            withAnimation {
                sessionEnded = true
            }
        }
    }

    /// Saves the session + all ratings to SwiftData, then shows the complete screen.
    private func saveSession() {
        let store = DataStore(context: modelContext)
        let duration = Int(Date().timeIntervalSince(sessionStartDate))
        store.saveSession(
            category: prompts.first?.category.rawValue ?? "Prompt",
            difficulty: "easy",
            promptsShown: prompts.map(\.text),
            durationSeconds: duration,
            reactions: cardStatuses.map { (
                promptText: $0.promptText,
                category: prompts.first?.category.rawValue ?? "Prompt",
                reaction: $0.status.rawValue
            ) },
            partnerName: nil,
            completedFully: completedFully
        )
    }
    
    // Fallback if Prompt.samples is empty
    static let fallbackPrompts: [Prompt] = [
        Prompt(text: "What makes you feel most safe in our relationship?",
               highlightWords: ["safe"], category: .prompt, difficulty: .easy,
               meta: "Warm-up", whoStarts: .partnerA),
        Prompt(text: "Describe a moment you felt deeply connected to your partner.",
               highlightWords: ["deeply connected"], category: .reflect, difficulty: .light,
               meta: "Reflection", whoStarts: .partnerB),
        Prompt(text: "What boundary would you like to explore expanding?",
               highlightWords: ["boundary", "explore"], category: .explore, difficulty: .medium,
               meta: "Exploration", whoStarts: .either),
        Prompt(text: "Share a fantasy you haven't voiced yet.",
               highlightWords: ["fantasy"], category: .fantasy, difficulty: .deep,
               meta: "Deep dive", isSensitive: true, whoStarts: .partnerA),
        Prompt(text: "What does ultimate vulnerability look like for you?",
               highlightWords: ["ultimate", "vulnerability"], category: .deepDive, difficulty: .sensitive,
               meta: "Intimate", isSensitive: true, canSkip: true, whoStarts: .both)
    ]
}

#Preview {
    SessionView()
        .preferredColorScheme(.dark)
        .modelContainer(ModelContainer.previewContainer)
}
