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

struct ContentView: View {

    // MARK: - Onboarding Gate

    @AppStorage("isOnboardingComplete") private var hasCompletedOnboarding = false

    #if DEBUG
    private let forceOnboarding = false
    #else
    private let forceOnboarding = false
    #endif

    // MARK: - Dependencies

    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    // MARK: - Body

    var body: some View {
        if hasCompletedOnboarding && !forceOnboarding {
            AppShell()
        } else {
            OnboardingFlowView(
                modelContainer: modelContext.container,
                appState: appState
            )
        }
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
