// Features/Learn/Views/LearnDashboardView.swift
//
// The Learn tab content: header (title + Resources pill) over three
// colour-coded sections, on the OB atmosphere. Reads the store; all
// navigation is forwarded via closures to the Router.

import SwiftUI

struct LearnDashboardView: View {
    let store: LearnStore
    var onOpenDatabase: () -> Void = {}
    var onOpenResources: () -> Void = {}
    var onOpenFinding: (ResearchFinding) -> Void = { _ in }
    var onSelectQuiz: (LearnQuiz) -> Void = { _ in }

    var body: some View {
        ZStack(alignment: .top) {
            AppColors.pageBackground.ignoresSafeArea()
            OnboardingAtmosphere(config: .stat).ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    header
                    QuizCarouselSection(quizzes: store.quizzes, onSelect: onSelectQuiz)
                    ResearchSection(
                        featured: store.featuredFinding,
                        carousel: store.carouselFindings,
                        totalCount: store.findingCount,
                        onOpenDatabase: onOpenDatabase,
                        onOpenFinding: onOpenFinding
                    )
                    ContentHubSection(store: store)
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.md)
                .padding(.bottom, 120)   // clears the floating RacetrackTabBar
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Learn.")
                    .font(AppFonts.heroTitle)
                    .foregroundStyle(AppColors.spectrumText)
                Text("Build your frame before you need it")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }
            Spacer()
            Button(action: onOpenResources) {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "lifepreserver").foregroundStyle(AppColors.spectrumCyan)
                    Text("Resources").font(AppFonts.buttonLabel).foregroundStyle(AppColors.textBody)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .background(Capsule().fill(AppColors.cardBackground)
                    .overlay(Capsule().stroke(AppColors.borderSubtle, lineWidth: 1)))
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    LearnDashboardView(store: LearnStore())
}
