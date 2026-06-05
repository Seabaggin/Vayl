//
//  ContentView.swift
//  Vayl
//
//  Root router. Two responsibilities only:
//    1. Gate: onboarding not complete → OnboardingFlowView
//    2. Gate: onboarding complete → AppShell
//

import SwiftUI
import SwiftData
import OSLog

private let logger = Logger(
    subsystem: "com.vayl.app",
    category: "ContentView"
)

#if DEBUG
/// Set to true to always route to OnboardingCanvasView on launch.
/// Flip to false to restore normal auth/onboarding routing.
private let forceOnboarding = true
#endif

struct ContentView: View {

    // MARK: - Onboarding Gate

    @AppStorage("isOnboardingComplete") private var hasCompletedOnboarding = false

    // MARK: - Dependencies

    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    // MARK: - Body

    var body: some View {
        #if DEBUG
        if forceOnboarding {
            OnboardingCanvasView()
        } else {
            if hasCompletedOnboarding {
                AppShell()
            } else {
                OnboardingCanvasView()
            }
        }
        #else
        if hasCompletedOnboarding {
            AppShell()
        } else {
            OnboardingCanvasView()
        }
        #endif
    }
}

// MARK: - Previews

#Preview("Onboarding") {
    ContentView()
        .environment(AppState())
        .environment(PulseStore())
        .preferredColorScheme(.dark)
}

#Preview("Main App — Linked") {
    let state = AppState()
    state.linkState = .linked
    state.displayName = "Jordan"
    return ContentView()
        .environment(state)
        .environment(PulseStore())
        .preferredColorScheme(.dark)
}

#Preview("Main App — Unlinked Together") {
    let state = AppState()
    state.linkState = .unlinked
    state.appMode = .together
    state.displayName = "Jordan"
    return ContentView()
        .environment(state)
        .environment(PulseStore())
        .preferredColorScheme(.dark)
}

#Preview("Main App — Unlinked Solo") {
    let state = AppState()
    state.linkState = .unlinked
    state.appMode = .solo
    state.displayName = "Riley"
    return ContentView()
        .environment(state)
        .environment(PulseStore())
        .preferredColorScheme(.dark)
}
