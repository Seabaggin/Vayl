//
//  HomeRouterView.swift
//  Vayl
//
//  Thin view. Renders only.
//  All routing logic lives in HomeStore.
//  All state lives in HomeStore.
//  This file switches on store.homeState and renders the result.
//

import SwiftUI
import SwiftData

struct HomeRouterView: View {

    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    @State private var store: HomeStore? = nil

    // ── Session presentation ─────────────────────────────────────────────
    // Created here because HomeRouterView owns appState and modelContext.
    // Presented as a sheet over the home content.
    @State private var activeSession: SessionStore? = nil

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let layout = AppLayout.from(geo)

            Group {
                if let store {
                    routedContent(store: store, layout: layout)
                } else {
                    ProgressView()
                        .tint(AppColors.accentPrimary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .task {
            await bootstrapStore()
        }
        .sheet(item: $activeSession) { session in
            SessionView(store: session)
        }
    }

    // MARK: - Routed Content

    @ViewBuilder
    private func routedContent(store: HomeStore, layout: AppLayout) -> some View {
        ZStack {
            switch store.homeState {

            case .gated:
                HomeGateView(
                    isPaired: store.isPaired,
                    onStartMap: { /* route to DesireMapView */ }
                )
                .transition(.opacity)

            case .postReflection:
                PostMapReflectionView(
                    step: Binding(
                        get: { store.reflectionStep },
                        set: { _ in }
                    ),
                    onComplete: {
                        withAnimation(AppAnimation.enter) {
                            store.markPostReflectionDone()
                        }
                    },
                    onSkipAll: {
                        withAnimation(AppAnimation.enter) {
                            store.markPostReflectionDone()
                        }
                    }
                )
                .transition(.opacity)

            case .waiting:
                HomeWaitingView(
                    isPaired: store.isPaired,
                    partnerName: store.partnerName ?? "your partner",
                    onInvite: { /* open share sheet */ }
                )
                .transition(.opacity)

            case .matchReady:
                HomeMatchReadyView(
                    onReveal: { /* route to reveal / paywall */ }
                )
                .transition(.opacity)

            case .dashboard:
                dashboardContent(store: store)
                    .transition(.opacity)

            case .soloUnpaired:
                dashboardContent(store: store)
                    .transition(.opacity)
            }
        }
        .animation(AppAnimation.enter, value: store.homeState)
        .task {
            await store.loadAll()
        }

        #if DEBUG
        .overlay(alignment: .bottomTrailing) {
            debugControls(store: store, layout: layout)
        }
        #endif
    }

    // MARK: - Dashboard Content

    @ViewBuilder
    private func dashboardContent(store: HomeStore) -> some View {
        if let error = store.deckLoadError {
            VStack(spacing: AppSpacing.md) {
                Image(systemName: AppIcons.exclamationTriangle)
                    .font(AppFonts.heroTitle)
                    .foregroundStyle(AppColors.accentTertiary)

                Text("Couldn't load your deck")
                    .font(AppFonts.screenTitle)
                    .foregroundStyle(AppColors.textPrimary)

                Text(error)
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)

                Button("Try Again") {
                    Task { await store.loadDeck() }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(AppSpacing.xl)

        } else if store.isLoadingDeck || store.deck == nil {
            VStack(spacing: AppSpacing.sm) {
                ProgressView()
                    .tint(AppColors.accentPrimary)
                Text("Loading your deck...")
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textSecondary)
            }

        } else if let loadedDeck = store.deck {
            HomeDashboardView(
                displayName:         appState.displayName,
                partnerChipState:    store.partnerChipState,
                cards:               loadedDeck.orderedCards,
                desireMapState:      store.desireMapState,
                reflectionCardState: store.reflectionCardState,
                pickUpItems:         [],
                stageIndex:          store.stageIndex,
                cardsCompleted:      store.cardsCompleted,
                recentEvents:        [],
                isSolo:              store.isSolo,
                onCardAction:        { card, action in
                    handleCardAction(card: card, action: action, deck: loadedDeck, store: store)
                },
                onInvitePartner:     { appState.selectedTab = .map },
                onPartnerTap:        { appState.selectedTab = .map }
            )
        }
    }

    // MARK: - Card Action Handler

    /// Handles card actions from HomeDashboardView.
    /// Lives here because this view owns appState and modelContext.
    private func handleCardAction(card: Card, action: CardAction, deck: Deck, store: HomeStore) {
        switch action {

        case .startSession:
            // Resume from current progress — startIndex from store.cardsCompleted
            activeSession = SessionStore(
                deck: deck,
                startIndex: store.cardsCompleted,
                modelContainer: modelContext.container,
                appState: appState
            )

        case .navigateToPlay:
            appState.selectedTab = .play

        default:
            break
        }
    }

    // MARK: - Store Bootstrap

    private func bootstrapStore() async {
        guard store == nil else { return }
        store = HomeStore(
            modelContainer: modelContext.container,
            appState: appState
        )
    }

    // MARK: - Debug Controls

    #if DEBUG
    private func debugControls(store: HomeStore, layout: AppLayout) -> some View {
        VStack(alignment: .trailing, spacing: AppSpacing.sm) {
            Text("HomeState: \(String(describing: store.homeState))")
                .font(AppFonts.meta)
                .foregroundStyle(AppColors.textTertiary)

            Button(store.myMapComplete ? "Map ✓" : "Map ✗") {
                store.myMapComplete.toggle()
            }
            Button(store.postReflectionDone ? "Reflected ✓" : "Reflected ✗") {
                store.postReflectionDone.toggle()
            }
            Button(store.partnerMapComplete ? "Partner ✓" : "Partner ✗") {
                store.partnerMapComplete.toggle()
            }
            Button(store.revealDone ? "Reveal ✓" : "Reveal ✗") {
                store.revealDone.toggle()
            }
        }
        .font(AppFonts.overline)
        .foregroundStyle(AppColors.accentPrimary)
        .padding(AppSpacing.sm)
        .background(AppColors.cardBackground.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .padding(.trailing, AppSpacing.md)
        .bottomContentInset(layout)
    }
    #endif
}
