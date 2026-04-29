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
                        withAnimation(.easeInOut(duration: 0.4)) {
                            postReflectionDone = true
                        }
                    },
                    onSkipAll: {
                        withAnimation(.easeInOut(duration: 0.4)) {
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
        .animation(.easeInOut(duration: 0.4), value: homeState)
        .task {
            await loadDeck()
        }

        #if DEBUG
        .overlay(alignment: .bottomTrailing) {
            debugControls
        }
        #endif
    }

    // MARK: - Dashboard Content

    @ViewBuilder
    private var dashboardContent: some View {
        if let error = deckLoadError {
            // ── Load failure — visible error, never silent ────────────────
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 36))
                    .foregroundStyle(AppColors.magenta)

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
            .padding(32)

        } else if isLoadingDeck || deck == nil {
            // ── Loading state ─────────────────────────────────────────────
            VStack(spacing: 12) {
                ProgressView()
                    .tint(AppColors.cyan)
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
    private var debugControls: some View {
        VStack(alignment: .trailing, spacing: 6) {
            Text("HomeState: \(String(describing: homeState))")
                .font(.system(size: 10, weight: .medium))
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
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(AppColors.cyan)
        .padding(12)
        .background(AppColors.cardBg.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.trailing, 16)
        .padding(.bottom, 100)
    }
    #endif
}
