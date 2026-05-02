//
//  HomeRouterView.swift
//  Vayl
//

import SwiftUI

enum HomeState: Equatable {
    case gated
    case postReflection
    case waiting
    case matchReady
    case dashboard
}

struct HomeRouterView: View {

    @Environment(\.colorScheme) private var colorScheme
    @Environment(AppState.self) private var appState

    // ── Desire map state ─────────────────────────────────────────────────
    #if DEBUG
    @State private var myMapComplete:      Bool    = true
    @State private var partnerMapComplete: Bool    = true
    @State private var partnerName:        String? = "Alex"
    @State private var revealDone:         Bool    = true
    @State private var postReflectionDone: Bool    = true
    #else
    @State private var myMapComplete:      Bool    = false
    @State private var partnerMapComplete: Bool    = false
    @State private var partnerName:        String? = nil
    @State private var revealDone:         Bool    = false
    @State private var postReflectionDone: Bool    = false
    #endif
    @State private var reflectionStep: Int = 1

    // ── Deck loading ─────────────────────────────────────────────────────
    @State private var deck: Deck? = nil
    @State private var deckLoadError: String? = nil
    @State private var isLoadingDeck: Bool = false

    // ── Derived from AppState ────────────────────────────────────────────
    private var isPaired: Bool {
        appState.appMode == .together
    }

    private var isSolo: Bool {
        appState.appMode == .solo
    }

    // ── Single computed property drives all routing ──────────────────────
    private var homeState: HomeState {
        guard myMapComplete else                        { return .gated }
        guard postReflectionDone else                   { return .postReflection }
        guard partnerMapComplete else                   { return .waiting }
        guard revealDone else                           { return .matchReady }
        return .dashboard
    }

    var body: some View {
        GeometryReader { geo in
            let layout = AppLayout.from(geo)
            ZStack {
                switch homeState {

            case .gated:
                HomeGateView(
                    isPaired: isPaired,
                    onStartMap: { /* route to DesireMapView */ }
                )
                .transition(.opacity)

            case .postReflection:
                PostMapReflectionView(
                    step: $reflectionStep,
                    onComplete: {
                        withAnimation(AppAnimation.enter) {
                            postReflectionDone = true
                        }
                    },
                    onSkipAll: {
                        withAnimation(AppAnimation.enter) {
                            postReflectionDone = true
                        }
                    }
                )
                .transition(.opacity)

            case .waiting:
                HomeWaitingView(
                    isPaired: isPaired,
                    partnerName: "your partner",
                    onInvite: { /* open share sheet */ }
                )
                .transition(.opacity)

            case .matchReady:
                HomeMatchReadyView(
                    onReveal: { /* route to reveal / paywall */ }
                )
                .transition(.opacity)

            case .dashboard:
                dashboardContent
                    .transition(.opacity)
                }
            }
            .animation(AppAnimation.enter, value: homeState)
            .task {
                await loadDeck()
            }

            #if DEBUG
            .overlay(alignment: .bottomTrailing) {
                debugControls(layout: layout)
            }
            #endif
        }
    }

    // MARK: - Dashboard Content

    @ViewBuilder
    private var dashboardContent: some View {
        if let error = deckLoadError {
            // ── Load failure — visible error, never silent ────────────────
            VStack(spacing: AppSpacing.md) {
                Image(AppIcons.exclamationTriangle)
                    .font(Font.custom("ClashDisplay-Bold", size: 36, relativeTo: .largeTitle))
                    .foregroundStyle(AppColors.accentTertiary)

                Text("Couldn't load your deck")
                    .font(AppFonts.screenTitle)
                    .foregroundStyle(AppColors.textPrimary)

                Text(error)
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)

                Button("Try Again") {
                    Task { await loadDeck() }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(AppSpacing.xl)

        } else if isLoadingDeck || deck == nil {
            // ── Loading state ─────────────────────────────────────────────
            VStack(spacing: AppSpacing.sm) {
                ProgressView()
                    .tint(AppColors.accentPrimary)
                Text("Loading your deck...")
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textSecondary)
            }

        } else if let loadedDeck = deck {
            // ── Real content ──────────────────────────────────────────────
            HomeDashboardView(
                displayName:         appState.displayName,
                partnerChipState:    isPaired ? .invitePending : .none,
                cards:               loadedDeck.orderedCards,
                desireMapState:      .hidden,
                reflectionCardState: .hidden,
                pickUpItems:         [],
                stageIndex:          1,
                cardsCompleted:      0,
                recentEvents:        [],
                isSolo:              isSolo,
                onInvitePartner:     { appState.selectedTab = .map },
                onPartnerTap:        { appState.selectedTab = .map }
            )
        }
    }

    // MARK: - Deck Loading

    private func loadDeck() async {
        isLoadingDeck = true
        deckLoadError = nil

        do {
            let loaded = try ContentLoader.loadDeck(id: "the-opener")
            deck = loaded
        } catch {
            deckLoadError = error.localizedDescription
        }

        isLoadingDeck = false
    }

    // MARK: - Tab Lock Helper

    static func isTabLocked(_ tab: AppTab, homeState: HomeState) -> Bool {
        switch homeState {
        case .dashboard:
            return false
        default:
            return tab == .play || tab == .map
        }
    }

    // MARK: - Debug Controls

    #if DEBUG
    private func debugControls(layout: AppLayout) -> some View {
        VStack(alignment: .trailing, spacing: AppSpacing.sm) {
            Text("HomeState: \(String(describing: homeState))")
                .font(Font.custom("Switzer-Medium", size: 10, relativeTo: .caption2))
                .foregroundStyle(AppColors.textTertiary)

            Button(myMapComplete ? "Map ✓" : "Map ✗") {
                myMapComplete.toggle()
            }
            Button(postReflectionDone ? "Reflected ✓" : "Reflected ✗") {
                postReflectionDone.toggle()
            }
            Button(partnerMapComplete ? "Partner ✓" : "Partner ✗") {
                partnerMapComplete.toggle()
            }
            Button(revealDone ? "Reveal ✓" : "Reveal ✗") {
                revealDone.toggle()
            }
        }
        .font(Font.custom("Switzer-Medium", size: 11, relativeTo: .caption2))
        .foregroundStyle(AppColors.accentPrimary)
        .padding(AppSpacing.sm)
        .background(AppColors.cardBackground.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .padding(.trailing, AppSpacing.md)
        .bottomContentInset(layout)
    }
    #endif
}
