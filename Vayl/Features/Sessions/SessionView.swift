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

    private let prompts: [Card] = Array(Card.samples.prefix(5))

    private var currentPrompt: Card? {
        guard prompts.indices.contains(currentIndex) else { return nil }
        return prompts[currentIndex]
    }
    private var isLast: Bool { currentIndex >= prompts.count - 1 }

    var body: some View {
        ZStack {
            AppColors.pageBackground.ignoresSafeArea()

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
            Spacer(minLength: AppSpacing.md)        // was 12 → md (16), snap per handoff
            cardArea
            Spacer(minLength: AppSpacing.md)        // was 12 → md
            progressPips
            Spacer(minLength: AppSpacing.md)        // was 16 → md, exact
            bottomControls
        }
        .padding(.horizontal, AppSpacing.lg)        // was 20 → lg (24)
        .padding(.vertical, AppSpacing.md)          // was 16 → md, exact
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(AppIcons.chevronLeft)          // was "chevron.left"
                    .font(
                        Font.custom("Switzer-Semibold", size: 18, relativeTo: .body)
                    )                               // was .system(size: 18, weight: .semibold)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(minWidth: 44, minHeight: 44) // A11y: minimum hit target
            }
            .accessibilityLabel("Back")
            .accessibilityAddTraits(.isButton)

            Spacer()

            VStack(spacing: AppSpacing.xxs) {       // was 2 → xxs, exact
                Text("\(currentIndex + 1) of \(prompts.count)")
                    .font(AppFonts.overline)
                    .foregroundColor(AppColors.textTertiary)

                Text("The Opener")
                    .font(AppFonts.sectionLabelSmall)
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            // Phantom mirror — keeps title centred, never visible
            Image(AppIcons.chevronLeft)              // was "chevron.left"
                .font(
                    Font.custom("Switzer-Semibold", size: 18, relativeTo: .body)
                )                                   // was .system(size: 18, weight: .semibold)
                .foregroundColor(.clear)
                .frame(minWidth: 44, minHeight: 44)
                .accessibilityHidden(true)
        }
    }

    // MARK: - Prompt Card

    private var cardArea: some View {
        Text(currentPrompt?.text ?? "")
            .id(currentIndex)
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal:   .move(edge: .leading).combined(with: .opacity)
            ))
            .animation(AppAnimation.standard, value: currentIndex) // was .easeInOut(duration: 0.35)
    }

    // MARK: - Progress Pips

    private var progressPips: some View {
        HStack(spacing: AppSpacing.sm) {            // was 8 → sm, exact
            ForEach(0..<prompts.count, id: \.self) { i in
                Capsule()
                    .fill(i == currentIndex ? AppColors.accentPrimary : AppColors.borderSubtle)
                    .frame(width: i == currentIndex ? 24 : 8, height: 8)
                    .animation(AppAnimation.fast, value: currentIndex) // was .easeInOut(duration: 0.25)
            }
        }
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: AppSpacing.md) {            // was 16 → md, exact
            HStack(spacing: AppSpacing.md) {        // was 12 → md (16), snap per handoff

                // Skip — not ready for this card
                Button {
                    recordStatus(.skipped)
                    advanceCard()
                } label: {
                    HStack(spacing: AppSpacing.sm) { // was 6 → sm (8), snap per handoff
                        Image(AppIcons.forwardFill)  // was "forward.fill"
                            .font(
                                Font.custom("Switzer-Regular", size: 14, relativeTo: .caption)
                            )                       // was .system(size: 14)
                        Text("Not Ready")
                            .font(AppFonts.bodyMedium)
                    }
                    .foregroundColor(AppColors.textMuted)
                    .frame(maxWidth: .infinity, minHeight: 44) // A11y: min hit target
                    .padding(.vertical, AppSpacing.md)  // was 14 → md (16), snap
                    .cardStyle(cornerRadius: AppRadius.md) // was 12 → md, exact
                }
                .accessibilityLabel("Not Ready — skip this card")
                .accessibilityAddTraits(.isButton)

                // Bookmark — save for later
                Button {
                    recordStatus(.bookmarked)
                    advanceCard()
                } label: {
                    Image(AppIcons.bookmarkFill)     // was "bookmark.fill"
                        .font(
                            Font.custom("Switzer-Regular", size: 18, relativeTo: .body)
                        )                           // was .system(size: 18)
                        .foregroundColor(AppColors.accentPrimary)
                        .frame(width: 52, height: 48)
                        .cardStyle(cornerRadius: AppRadius.md) // was 12 → md, exact
                }
                .accessibilityLabel("Bookmark — save for later")
                .accessibilityAddTraits(.isButton)
            }

            // Discussed — primary action, full width
            Button {
                recordStatus(.discussed)
                advanceCard()
            } label: {
                HStack(spacing: AppSpacing.sm) {    // was 8 → sm, exact
                    Image(AppIcons.checkmarkCircle) // was "checkmark.circle.fill"
                        .font(
                            Font.custom("Switzer-Regular", size: 18, relativeTo: .body)
                        )                           // was .system(size: 18)
                    Text("We Discussed This")
                        .font(AppFonts.bodyMedium)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 44) // A11y: min hit target
                .padding(.vertical, AppSpacing.md)  // was 16 → md, exact
                .background(
                    LinearGradient(
                        colors: [AppColors.accentTertiary, AppColors.accentSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md)) // was 14 → md, snap
            }
            .accessibilityLabel("We Discussed This")
            .accessibilityAddTraits(.isButton)
        }
    }

    // MARK: - Session Complete

    private var sessionCompleteView: some View {
        VStack(spacing: AppSpacing.lg) {            // was 24 → lg, exact
            Spacer()

            Image(AppIcons.sparkles)                // was "sparkles"
                .font(
                    Font.custom("ClashDisplay-Bold", size: 48, relativeTo: .largeTitle)
                )                                   // was .system(size: 48)
                .foregroundStyle(AppColors.spectrumText)
                .accessibilityHidden(true)          // decorative

            let discussedCount  = cardStatuses.filter { $0.status == .discussed  }.count
            let skippedCount    = cardStatuses.filter { $0.status == .skipped    }.count
            let bookmarkedCount = cardStatuses.filter { $0.status == .bookmarked }.count

            VStack(spacing: AppSpacing.sm) {        // was 8 → sm, exact
                Text("Session Complete")
                    .font(AppFonts.screenTitle)
                    .foregroundColor(AppColors.textPrimary)
                Text("You discussed \(discussedCount) of \(prompts.count) prompts")
                    .font(AppFonts.bodyMedium)
                    .foregroundColor(AppColors.textSecondary)
                if bookmarkedCount > 0 {
                    Text("\(bookmarkedCount) bookmarked for later")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.accentPrimary)
                }
                if skippedCount > 0 {
                    Text("\(skippedCount) skipped — no pressure")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textMuted)
                }
            }
            .multilineTextAlignment(.center)

            GradientButton(title: "Done") {
                withAnimation(AppAnimation.standard) { // was bare withAnimation
                    currentIndex     = 0
                    sessionEnded     = false
                    cardStatuses     = []
                    sessionStartDate = .now
                    completedFully   = true
                }
            }
            .padding(.horizontal, AppSpacing.xxl)  // was 40 → xxl (48), snap per handoff

            Spacer()
        }
        .padding(AppSpacing.lg)                    // was 20 → lg (24)
    }

    // MARK: - Helpers

    /// Unused — advanceCard() handles all navigation. Retained to avoid API break.
    private func advance() {
        guard !isLast else { return }
        withAnimation(AppAnimation.standard) {     // was .easeInOut(duration: 0.35)
            currentIndex += 1
        }
    }

    private func recordStatus(_ status: CardStatus) {
        let promptText = currentPrompt?.text ?? ""
        cardStatuses.append((promptText: promptText, status: status))
    }

    private func advanceCard() {
        if currentIndex < prompts.count - 1 {
            withAnimation(AppAnimation.standard) { // was bare withAnimation
                currentIndex += 1
            }
        } else {
            saveSession()
            withAnimation(AppAnimation.standard) { // was bare withAnimation
                sessionEnded = true
            }
        }
    }

    private func saveSession() {
        // TODO: rewrite with CardSession when DataStore is updated
    }
}

#Preview {
    SessionView()
        .preferredColorScheme(.dark)
        .modelContainer(ModelContainer.previewContainer)
}
