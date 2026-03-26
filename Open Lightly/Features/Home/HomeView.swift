// Features/Home/HomeView.swift
// Open Lightly
//
// Thin router only — zero business logic here.
// Switches on appState.experienceType and renders the matching
// experience-specific home screen.
//
// The .browsing case should never reach this view because ContentView
// gates guests into the guest shell before the tab bar renders.
// The case is kept as a defensive fallback that renders MoreView.

import SwiftUI
import OSLog

private let logger = Logger(subsystem: "com.openlightly.app", category: "HomeView")

struct HomeView: View {

    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            switch appState.experienceType {
            case .soloSingle:
                HomeViewSingle()
            case .soloPartnered:
                HomeViewSolo()
            case .coupleNew:
                HomeViewCoupleNew()
            case .coupleExperienced:
                HomeViewCoupleExp()
            case .browsing:
                // Defensive fallback — guest users are gated in ContentView.
                // Log a warning so this path is visible in console.
                MoreView()
                    .onAppear {
                        logger.warning("HomeView reached with .browsing experienceType — guest should be gated in ContentView")
                    }
            }
        }
    }
}

// MARK: - Previews

#Preview("HomeViewSingle") {
    let state = AppState()
    state.experienceType = .soloSingle
    return HomeView().environment(state)
}

#Preview("HomeViewSolo") {
    let state = AppState()
    state.experienceType = .soloPartnered
    return HomeView().environment(state)
}

#Preview("HomeViewCoupleNew") {
    let state = AppState()
    state.experienceType = .coupleNew
    return HomeView().environment(state)
}

#Preview("HomeViewCoupleExp") {
    let state = AppState()
    state.experienceType = .coupleExperienced
    return HomeView().environment(state)
}
