// Features/Learn/Views/LearnView.swift
//
// The Learn tab: one screen — quizzes / research / content hub — over the
// OB atmosphere. It owns its content store and the three sheet presentations
// (research database, finding detail, resources overlay) directly.
//
// No Router/Dashboard split: Learn has no routing state machine (unlike Home),
// so the extra layer would be ceremony without payoff. If routing states ever
// appear, split a LearnRouterView back out the way Home does.

import SwiftUI

struct LearnView: View {
    @State private var store = LearnStore()
    @State private var showDatabase = false
    @State private var showResources = false
    @State private var selectedFinding: ResearchFinding?

    var body: some View {
        ZStack(alignment: .top) {
            AppColors.pageBackground.ignoresSafeArea()
            OnboardingAtmosphere(config: .stat).ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    header
                    QuizCarouselSection(quizzes: store.quizzes)
                    ResearchSection(
                        featured: store.featuredFinding,
                        carousel: store.carouselFindings,
                        totalCount: store.findingCount,
                        onOpenDatabase: { showDatabase = true },
                        onOpenFinding: { selectedFinding = $0 }
                    )
                    ContentHubSection(store: store)
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.md)
                .padding(.bottom, 120)   // clears the floating RacetrackTabBar
            }
        }
        .vaylSheet(isPresented: $showDatabase, heightFraction: 0.92) {
            ResearchDatabaseView(store: store, onOpenFinding: { f in
                showDatabase = false
                selectedFinding = f
            })
        }
        .vaylSheet(isPresented: $showResources, heightFraction: 0.82) {
            ResourcesOverlayView(resources: store.supportResources)
        }
        .vaylSheet(isPresented: detailBinding, heightFraction: 0.85) {
            if let f = selectedFinding {
                FindingDetailView(finding: f, store: store, onOpenFinding: { selectedFinding = $0 })
            }
        }
    }

    private var detailBinding: Binding<Bool> {
        Binding(get: { selectedFinding != nil },
                set: { if !$0 { selectedFinding = nil } })
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
            Button { showResources = true } label: {
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
    LearnView()
}
