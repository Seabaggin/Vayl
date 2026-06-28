//
//  AppShell.swift
//  Vayl
//

import SwiftUI
import SwiftData

struct AppShell: View {

    @State private var selectedTab: AppTab = .home

    var body: some View {
        Group {
            switch selectedTab {
            case .home:
                // fade off: Home's Lexicon is anchored at the bottom and must not dissolve.
                TabContentWrapper(fade: false) { HomeRouterView() }
            case .play:
                TabContentWrapper { PlayView() }
            case .map:
                TabContentWrapper { MapView() }
            case .learn:
                TabContentWrapper { LearnView() }
            case .settings:
                TabContentWrapper { SettingsView(isTab: true) }
            }
        }
        // The tab bar is attached as a bottom SAFE-AREA INSET, not a ZStack overlay.
        // SwiftUI then (1) positions the pill above the home indicator on every device and
        // (2) reserves its EXACT rendered height as a content inset for every tab — a single
        // source of truth, so the bar can't sit wrong and screens stop hand-rolling their
        // own bottom clearance. Per-tab atmospheres still bleed behind it via their own
        // .ignoresSafeArea(), so the pill floats over the void.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            RacetrackTabBar(selection: $selectedTab)
                .padding(.top, AppSpacing.sm)      // breathing between content and the pill
                .padding(.bottom, AppSpacing.md)   // float above the home indicator (tunable)
        }
    }
}

// MARK: - Previews

#Preview("Home — Linked") {
    let state = AppState()
    state.linkState = .linked
    state.displayName = "Jordan"
    return AppShell()
        .environment(state)
        .environment(PulseStore())
        .environment(EntitlementStore(modelContainer: .previewContainerWithProfile, appState: state))
        .environment(AuthService())
        .preferredColorScheme(.dark)
        .modelContainer(.previewContainerWithProfile)
}

#Preview("Home — Unlinked Together") {
    let state = AppState()
    state.linkState = .unlinked
    state.appMode = .together
    state.displayName = "Jordan"
    return AppShell()
        .environment(state)
        .environment(PulseStore())
        .environment(EntitlementStore(modelContainer: .previewContainerWithProfile, appState: state))
        .environment(AuthService())
        .preferredColorScheme(.dark)
        .modelContainer(.previewContainerWithProfile)
}

#Preview("Home — Unlinked Solo") {
    let state = AppState()
    state.linkState = .unlinked
    state.appMode = .solo
    state.displayName = "Riley"
    return AppShell()
        .environment(state)
        .environment(PulseStore())
        .environment(EntitlementStore(modelContainer: .previewContainerWithProfile, appState: state))
        .environment(AuthService())
        .preferredColorScheme(.dark)
        .modelContainer(.previewContainerWithProfile)
}
