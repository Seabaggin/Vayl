//
//  HomeState.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/23/26.
//


// HomeRouterView.swift
// Open Lightly
//
// Root router for the Home tab.
// Reads UserProfile + Couple state and renders the correct home experience.
// All tab-locking logic lives here — single source of truth.
//
// State machine:
//   S1 — unpaired, map incomplete      → HomeGateView
//   S2 — unpaired, map complete        → PostMapReflectionView (if needed) → HomeWaitingView
//   S3 — paired, my map incomplete     → HomeGateView
//   S4 — paired, waiting on partner    → HomeWaitingView
//   S5 — both complete, no reveal yet  → HomeMatchReadyView
//   S6 — reveal done                   → HomeDashboardView

import SwiftUI

enum HomeState: Equatable {
    case gated              // S1 / S3 — map not done
    case postReflection     // R1 / R2 / R3 — post-map reflection stems
    case waiting            // S4 — waiting on partner
    case matchReady         // S5 — both done, reveal pending
    case dashboard          // S6 — full experience
}

struct HomeRouterView: View {
    @Environment(\.colorScheme) private var colorScheme

    // Injected from DataStore / AppState
    // These will be @Bindable SwiftData models in the real implementation.
    // Using simple @State here so the file compiles standalone for now.
    @State private var myMapComplete: Bool          = false
    @State private var partnerMapComplete: Bool     = false
    @State private var isPaired: Bool               = false
    @State private var revealDone: Bool             = false
    @State private var postReflectionDone: Bool     = false
    @State private var reflectionStep: Int          = 1    // 1, 2, or 3

    // Derived state — single computed property drives all routing
    private var homeState: HomeState {
        guard myMapComplete else         { return .gated }
        guard postReflectionDone else    { return .postReflection }
        guard isPaired && partnerMapComplete else { return .waiting }
        guard revealDone else            { return .matchReady }
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
                    partnerName: "your partner", // replace with real partner name
                    onInvite: { /* open share sheet */ }
                )
                .transition(.opacity)

            case .matchReady:
                HomeMatchReadyView(
                    onReveal: { /* route to reveal / paywall */ }
                )
                .transition(.opacity)

            case .dashboard:
                HomeDashboardView()
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: homeState)
    }
}

// MARK: - Tab Lock Helper
// Called from the tab bar coordinator to determine which tabs are accessible.
// Single source of truth — no logic scattered across tab items.

extension HomeRouterView {
    static func isTabLocked(_ tab: AppTab, homeState: HomeState) -> Bool {
        switch homeState {
        case .dashboard:
            return false // All tabs open
        default:
            // Only Home and More are accessible during gate/waiting/reveal states
            return tab == .meUs || tab == .explore
        }
    }
}