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
    /// Hub presentations live here, not in ContentHubSection. `.vaylSheet` is an
    /// overlay sized from its host's geometry, so a sheet attached to a section
    /// inside this ScrollView measured the SECTION — the scrim dimmed the screen
    /// while the sheet resolved to a fraction of a section. Screens present;
    /// sections compose.
    @State private var selectedHubItem: HubItem?
    @State private var showAllVoices = false
    /// Rest-zeroed scroll offset driving the masthead collapse (see MastheadCollapse).
    @State private var scrollY: CGFloat = 0

    var body: some View {
        ZStack(alignment: .top) {
            AppColors.pageBackground.ignoresSafeArea()
            // The Knowledge Hub card sits at ~27–56% of screen height — inside the
            // default 0.52 void-only zone — so its clear glass had nothing behind it
            // and read as flat charcoal. The `.learn` atmosphere raises the bloom and
            // the lowered maskStart unmasks it, so colour rises behind the card and
            // the lit→dark transition is gradual, not a hard cut. Learn-only; the
            // shared 0.52 / .stat contract for every other screen is untouched.
            OnboardingAtmosphere(config: .learn, maskStart: 0.18).ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    header
                    if store.loadError != nil {
                        loadErrorNotice
                    }
                    ResearchSection(
                        items: store.referencePreview,
                        onOpenDatabase: { showDatabase = true },
                        onOpenFinding: { selectedFinding = $0 }
                    )
                    ContentHubSection(
                        store: store,
                        onSelect: { selectedHubItem = $0 },
                        onSeeAllVoices: { showAllVoices = true }
                    )
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.md)
                .padding(.bottom, AppSpacing.lg)   // breathing room only; tab-bar clearance is the AppShell .safeAreaInset's job
            }
            // Top scroll-edge: the masthead dissolves under the Dynamic Island as
            // it scrolls up, instead of hard-cutting at the safe-area line.
            .scrollTopEdgeFade()
            // Rest-zeroed offset feeding the masthead shrink (header, below).
            .mastheadScrollReader($scrollY)
        }
        .vaylCover(isPresented: $showDatabase, confirmOnExit: false) {
            ResearchDatabaseView(store: store, onOpenFinding: { f in
                showDatabase = false
                selectedFinding = f
            })
        }
        .vaylSheet(isPresented: $showResources, heightFraction: 0.75) {
            ResourcesOverlayView(resources: store.supportResources)
        }
        .vaylSheet(item: $selectedFinding, heightFraction: 0.85) { finding in
            FindingDetailView(finding: finding, store: store, onOpenFinding: { selectedFinding = $0 })
        }
        .vaylSheet(item: $selectedHubItem, heightFraction: 0.7) { item in
            ContentItemSheet(item: item)
        }
        .vaylSheet(isPresented: $showAllVoices, heightFraction: 0.85) {
            VoicesListSheet(store: store, onSelect: { voice in
                showAllVoices = false
                selectedHubItem = .voice(voice)
            })
        }
    }

    private var loadErrorNotice: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: AppIcons.exclamationTriangle)
                .font(AppFonts.body(16, weight: .regular, relativeTo: .body))
                .foregroundStyle(AppColors.textTertiary)
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text("Some content didn't load")
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(AppColors.textPrimary)
                Text("Part of Learn couldn't be read. Anything below is what loaded.")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .vaylGlassCard()
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Learn.")
                    .font(AppFonts.tabMasthead)
                    .vaylDisplayTracking(40)   // tabMasthead is display(40); tighten optically
                    .foregroundStyle(AppColors.spectrumText)
                Text("Build your frame before you need it")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }
            // Only the wordmark + subline shrink; the Resources button stays put
            // (trailing controls hold, like iOS large-title bar buttons).
            .mastheadCollapse(scrollY: scrollY)
            Spacer()
            Button { showResources = true } label: {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: AppIcons.lifepreserver)
                        .foregroundStyle(AppColors.spectrumText)   // gradient symbol (in place of a gradient border)
                    Text("Resources")
                        .font(AppFonts.buttonLabel)
                        .foregroundStyle(AppColors.textBody)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .background(HolographicShimmer().opacity(0.7))      // same shimmer as the CTA
                .clipShape(Capsule())
                .overlay(Capsule().stroke(AppColors.borderSubtle, lineWidth: 1))  // plain hairline, not gradient
            }
            .buttonStyle(PressableCardStyle())
        }
    }
}

#Preview {
    LearnView()
}
