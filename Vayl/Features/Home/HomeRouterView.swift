// HomeRouterView.swift
// Open Lightly

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

    // ── Real state — placeholder bools until SwiftData models exist ──────
    // These will become @Bindable SwiftData model reads in a future batch.
    // Kept as @State for now so the router compiles and all states are
    // reachable for testing via the debug controls below.
    // AFTER
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

    // ── Derived from AppState ────────────────────────────────────────────
    private var isPaired: Bool {
        appState.experienceType == .coupleNew
        || appState.experienceType == .coupleExperienced
    }

    private var isSolo: Bool {
        appState.experienceType == .soloSingle
        || appState.experienceType == .soloPartnered
    }

    // ── Single computed property drives all routing ──────────────────────
    private var homeState: HomeState {
        guard myMapComplete else                        { return .gated }
        guard postReflectionDone else                   { return .postReflection }
        // Temporarily bypass isPaired check for testing
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
                HomeDashboardView(
                    displayName:         appState.displayName,
                    partnerChipState:    isPaired ? .invitePending : .none,
                    cards:               Prompt.samples,
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
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: homeState)

        #if DEBUG
        // ── Debug overlay — lets you walk through all home states
        // in the preview canvas without touching real data
        .overlay(alignment: .bottomTrailing) {
            debugControls
        }
        #endif
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
