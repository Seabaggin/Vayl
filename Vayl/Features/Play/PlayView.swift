//
//  PlayView.swift
//  Vayl — Play
//
//  Tab root + screen. Builds the PlayStore from the environment, then lays out
//  the Cards masthead (pinned), the active-deck hero + docked deck wall (or the
//  expanded canvas), with the float-in-space detail, the Begin ceremony, and
//  the session cover layered above.
//

import SwiftUI
import SwiftData

struct PlayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var store: PlayStore?
    @State private var scrollY: CGFloat = 0
    @Namespace private var deckZoom

    /// Inject a store for previews; nil in the app (built from the environment).
    var injectedStore: PlayStore? = nil

    /// 0 = hero full at rest, 1 = collapsed. Mirrors Home's scroll-linked hero transform
    /// (same ~320pt range). Reduce Motion pins it to 0 (plain scroll, no collapse).
    private var collapse: Double {
        reduceMotion ? 0 : min(1, max(0, Double(scrollY) / 320))
    }

    var body: some View {
        ZStack {
            AppColors.void.ignoresSafeArea()
            if let store = store ?? injectedStore {
                content(store)
            }
        }
        .task {
            if store == nil && injectedStore == nil {
                store = PlayStore(modelContainer: modelContext.container, appState: appState)
            }
        }
    }

    @ViewBuilder
    private func content(_ store: PlayStore) -> some View {
        ZStack(alignment: .top) {
            OnboardingAtmosphere(config: .stat).ignoresSafeArea()

            VStack(spacing: 0) {
                if store.isEmpty {
                    PlayMastheadView()
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.top, AppSpacing.xs)
                    PlayEmptyState(message: store.loadError) { store.retry() }
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: AppSpacing.xl) {
                            PlayMastheadView()
                                .padding(.horizontal, AppSpacing.lg)
                                .padding(.top, AppSpacing.xs)
                            PlayHeroView(store: store, collapse: collapse)
                            DeckWallView(store: store, namespace: deckZoom)
                        }
                        .padding(.top, AppSpacing.sm)
                        .padding(.bottom, AppSpacing.xxl * 2 + AppSpacing.lg)   // ~120pt tab-bar clearance
                    }
                    .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.y } action: { _, y in
                        scrollY = y
                    }
                }
            }

            DeckDetailView(store: store, namespace: deckZoom)

            if store.ceremonyDeckID != nil {
                DeckBeginCeremony(store: store)
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .animation(AppAnimation.enter, value: store.ceremonyDeckID)
        .vaylCover(isPresented: Binding(
            get: { store.sessionHand != nil },
            set: { if !$0 { store.endSession() } }
        )) {
            CardSessionContainerView(hand: store.sessionHand ?? [])
        }
        .vaylSheet(
            isPresented: Binding(
                get: { store.paywallDeck != nil },
                set: { if !$0 { store.dismissPaywall() } }
            ),
            heightFraction: 0.92
        ) {
            PaywallSheet(
                entry: .playDeck(name: store.paywallDeck?.title ?? "this deck"),
                onUnlocked: { store.dismissPaywall() }
            )
        }
    }

}

#if DEBUG
#Preview("Play") {
    PlayView(injectedStore: .preview)
        .environment(AppState())
        .environment(EntitlementStore(modelContainer: .previewContainer, appState: AppState()))
        .modelContainer(.previewContainer)
        .preferredColorScheme(.dark)
}
#endif
