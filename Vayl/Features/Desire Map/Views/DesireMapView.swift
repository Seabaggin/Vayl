import SwiftUI
import SwiftData

// MARK: - DesireMapView
// Two-track card rater (View layer — reads DesireMapStore, forwards taps; no DB/Service).
// One desire per card; the four answers + which items appear are cohort-driven (store.track).
// Only the WEIGHT (DesireRatingValue) is stored — the displayed string is cohort copy.

struct DesireMapView: View {

    let store: DesireMapStore

    @Environment(\.dismiss) private var dismiss
    @State private var index: Int = 0
    @State private var hapticTick: Int = 0   // sensoryFeedback trigger

    var body: some View {
        ZStack {
            AppColors.void.ignoresSafeArea()
            content
        }
        .screenshotProtected()
        .sensoryFeedback(.impact(weight: .light), trigger: hapticTick)
        .onAppear {
            store.load()
            if let firstUnrated = store.items.firstIndex(where: { store.existingRating(for: $0.id) == nil }) {
                index = firstUnrated
            }
        }
    }

    // MARK: - Routing between states

    @ViewBuilder
    private var content: some View {
        if let error = store.loadError {
            emptyState(error)
        } else if store.items.isEmpty {
            emptyState("No desire items to show.")
        } else if index >= store.items.count {
            completionView
        } else {
            rater(item: store.items[index])
        }
    }

    // MARK: - Rater

    private func rater(item: DesireItem) -> some View {
        VStack(spacing: AppSpacing.md) {
            topBar
            card(for: item)
                .id(index)
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal:   .move(edge: .top).combined(with: .opacity)
                ))
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.top, AppSpacing.md)
        .padding(.bottom, AppSpacing.lg)
    }

    private var topBar: some View {
        HStack(spacing: AppSpacing.md) {
            Button { back() } label: {
                Image(systemName: "chevron.left")
                    .font(AppFonts.bodyMedium)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(AppColors.cardBg))
                    .overlay(Circle().stroke(AppColors.borderSubtle, lineWidth: 1))
            }
            .buttonStyle(PlainButtonStyle())
            .opacity(index == 0 ? 0.3 : 1)
            .disabled(index == 0)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                progressTrack
                Text("\(index + 1) of \(store.totalCount)")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textTertiary)
            }

            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textTertiary)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    private var progressTrack: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(AppColors.textTertiary.opacity(0.18))
                Capsule().fill(AppColors.spectrumBorder)
                    .frame(width: geo.size.width * progressRatio)
            }
        }
        .frame(height: 4)
        .animation(AppAnimation.standard, value: store.ratedCount)
    }

    private var progressRatio: CGFloat {
        guard store.totalCount > 0 else { return 0 }
        return CGFloat(store.ratedCount) / CGFloat(store.totalCount)
    }

    // MARK: - Card

    private func card(for item: DesireItem) -> some View {
        let answers = store.answers(for: item)
        return VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.sm) {
                Circle().fill(AppColors.spectrumCyan).frame(width: 5, height: 5)
                Text(item.category.uppercased())
                    .font(AppFonts.overline)
                    .foregroundColor(AppColors.textTertiary)
            }

            Text(item.name)
                .font(AppFonts.cardTitle)
                .foregroundColor(AppColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(item.description)
                .font(AppFonts.bodyText)
                .foregroundColor(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: AppSpacing.lg)

            Text("How do you feel about this?")
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textTertiary)

            VStack(spacing: AppSpacing.sm) {
                ForEach(Array(answers.enumerated()), id: \.offset) { idx, label in
                    if idx < DesireRatingValue.allCases.count {
                        let weight = DesireRatingValue.allCases[idx]
                        RatingRow(
                            label: label,
                            accent: accentColor(for: weight),
                            isBoundary: weight == .notForMe,
                            isSelected: store.existingRating(for: item.id) == weight
                        ) { choose(weight, for: item) }
                    }
                }
            }

            Text("🔒 Private to you — only matches you both share are ever revealed.")
                .font(AppFonts.meta)
                .foregroundColor(AppColors.textMuted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, AppSpacing.xs)
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.container)
                .fill(AppColors.cardBg)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.container)
                .stroke(AppColors.spectrumBorder, lineWidth: 1)
                .opacity(0.5)
        )
    }

    private func accentColor(for weight: DesireRatingValue) -> Color {
        switch weight {
        case .excitedAboutIt: return AppColors.spectrumCyan
        case .openToIt:       return AppColors.spectrumPurple
        case .probablyNot:    return AppColors.textTertiary
        case .notForMe:       return AppColors.spectrumMagenta
        }
    }

    // MARK: - Completion

    private var completionView: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()
            Circle()
                .fill(AppColors.spectrumBorder)
                .frame(width: 88, height: 88)
                .overlay(
                    Circle().fill(AppColors.void).frame(width: 74, height: 74)
                        .overlay(Text("✦").font(AppFonts.cardTitle).foregroundColor(AppColors.textPrimary))
                )
                .spectrumBorderGlow(intensity: 0.6)

            Text("Your Desire Map is complete")
                .font(AppFonts.sectionHeading)
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.center)

            Text("When your partner finishes theirs, you'll see what you share.")
                .font(AppFonts.bodyText)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            Text("🔒 Saved privately to your device")
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textMuted)

            Spacer()

            Button { dismiss() } label: {
                Text("Done")
                    .font(AppFonts.ctaLabel)
                    .foregroundColor(AppColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(
                        Capsule().stroke(AppColors.spectrumBorder, lineWidth: 1)
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, AppSpacing.xl)
        .padding(.vertical, AppSpacing.xxl)
    }

    // MARK: - Empty / error

    private func emptyState(_ message: String) -> some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "heart.text.square")
                .font(AppFonts.screenTitle)
                .foregroundColor(AppColors.textTertiary)
            Text("Desire Map unavailable")
                .font(AppFonts.cardTitle)
                .foregroundColor(AppColors.textPrimary)
            Text(message)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textTertiary)
                .multilineTextAlignment(.center)
            Button { dismiss() } label: {
                Text("Close").font(AppFonts.ctaLabel).foregroundColor(AppColors.textSecondary)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.top, AppSpacing.sm)
        }
        .padding(AppSpacing.xl)
    }

    // MARK: - Actions

    private func choose(_ weight: DesireRatingValue, for item: DesireItem) {
        store.rate(itemId: item.id, rating: weight)
        hapticTick += 1
        withAnimation(AppAnimation.spring) {
            index += 1
        }
    }

    private func back() {
        guard index > 0 else { return }
        withAnimation(AppAnimation.spring) {
            index -= 1
        }
    }
}

// MARK: - RatingRow

private struct RatingRow: View {
    let label: String
    let accent: Color
    let isBoundary: Bool
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.sm) {
                RoundedRectangle(cornerRadius: AppRadius.pill)
                    .fill(accent)
                    .frame(width: 4, height: 22)

                Text(label)
                    .font(AppFonts.bodyMedium)
                    .foregroundColor(AppColors.textPrimary)

                Spacer(minLength: 0)

                if isBoundary {
                    Text("🔒 private")
                        .font(AppFonts.meta)
                        .foregroundColor(AppColors.textMuted)
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .fill(isSelected ? accent.opacity(0.10) : AppColors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .stroke(isSelected ? accent : AppColors.borderSubtle, lineWidth: isSelected ? 1.5 : 1)
            )
            .scaleEffect(isSelected ? 0.98 : 1.0)
            .animation(AppAnimation.spring, value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Previews

#Preview("Curious — 18 items") {
    let container = ModelContainer.previewContainer
    container.mainContext.insert(UserProfile(displayName: "Jordan", nmStage: .curious))
    try? container.mainContext.save()
    let appState = AppState()
    let store = DesireMapStore(modelContainer: container, appState: appState)
    store.load()
    return DesireMapView(store: store)
        .environment(appState)
        .preferredColorScheme(.dark)
}

#Preview("Established — 12 items") {
    let container = ModelContainer.previewContainer
    container.mainContext.insert(UserProfile(displayName: "Jordan", nmStage: .experienced))
    try? container.mainContext.save()
    let appState = AppState()
    let store = DesireMapStore(modelContainer: container, appState: appState)
    store.load()
    return DesireMapView(store: store)
        .environment(appState)
        .preferredColorScheme(.dark)
}

