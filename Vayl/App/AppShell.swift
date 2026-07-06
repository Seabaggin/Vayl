//
//  AppShell.swift
//  Vayl
//

import SwiftUI
import SwiftData

struct AppShell: View {

    @Environment(AppState.self) private var appState

    @State private var selectedTab:        AppTab  = .home
    @State private var transitionDirection: CGFloat = 1

    var body: some View {
        Group {
            switch selectedTab {
            case .home:
                // fade off: Home's Lexicon is anchored at the bottom and must not dissolve.
                TabContentWrapper(fade: false) { HomeRouterView() }
                    .transition(driftTransition)
            case .play:
                TabContentWrapper { PlayView() }
                    .transition(driftTransition)
            case .map:
                TabContentWrapper { MapView() }
                    .transition(driftTransition)
            case .learn:
                TabContentWrapper { LearnView() }
                    .transition(driftTransition)
            case .settings:
                TabContentWrapper { SettingsView(isTab: true) }
                    .transition(driftTransition)
            }
        }
        // The tab bar is attached as a bottom SAFE-AREA INSET, not a ZStack overlay.
        // SwiftUI then (1) positions the pill above the home indicator on every device and
        // (2) reserves its EXACT rendered height as a content inset for every tab — a single
        // source of truth, so the bar can't sit wrong and screens stop hand-rolling their
        // own bottom clearance. Per-tab atmospheres still bleed behind it via their own
        // .ignoresSafeArea(), so the pill floats over the void.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            // Intercept the selection write to capture direction BEFORE selectedTab changes.
            // Both mutations happen in the same event cycle so driftTransition reads the
            // correct direction when SwiftUI builds the incoming view's transition.
            RacetrackTabBar(selection: Binding(
                get: { selectedTab },
                set: { newTab in
                    let fromIdx = AppTab.allCases.firstIndex(of: selectedTab) ?? 0
                    let toIdx   = AppTab.allCases.firstIndex(of: newTab) ?? 0
                    transitionDirection = CGFloat(toIdx > fromIdx ? 1 : -1)
                    withAnimation(AppAnimation.tabSwitch) {
                        selectedTab = newTab
                    }
                }
            ))
            .padding(.top, AppSpacing.sm)
            // Drop the pill into the home-indicator strip and set the gap ourselves: without
            // this, `.safeAreaInset` floats the bar ABOVE the ~34pt system inset, which reads
            // as dead space. `.ignoresSafeArea(.container, .bottom)` collapses that inset so the
            // pad below IS the true gap to the physical edge. Kept at `.sm` (8pt), not tighter,
            // so the pill clears the home-indicator gesture zone. FEEL: confirm on device.
            .padding(.bottom, AppSpacing.sm)
            .ignoresSafeArea(.container, edges: .bottom)
        }
        // Programmatic routing: HomeRouterView's appState.selectedTab writes (dead
        // before this) and the joiner banner's route-to-Play both land here. The
        // local @State stays the tab bar's animation source; these keep it in
        // lockstep both directions.
        .onAppear { selectedTab = appState.selectedTab }
        .onChange(of: appState.selectedTab) { _, newTab in
            guard selectedTab != newTab else { return }
            let fromIdx = AppTab.allCases.firstIndex(of: selectedTab) ?? 0
            let toIdx   = AppTab.allCases.firstIndex(of: newTab) ?? 0
            transitionDirection = CGFloat(toIdx > fromIdx ? 1 : -1)
            withAnimation(AppAnimation.tabSwitch) { selectedTab = newTab }
        }
        .onChange(of: selectedTab) { _, newTab in
            if appState.selectedTab != newTab { appState.selectedTab = newTab }
        }
    }

    // Gravity/drift transition — two-sided parallax:
    //   incoming  14pt in from navigation direction (the "gravity pull" sensation)
    //   outgoing   8pt counter-drift away (creates depth against the incoming view)
    // The outgoing view captures transitionDirection from its last render, which is one
    // render behind the new direction on backward taps. The 8pt amount is imperceptible
    // at 0.25s so the error never reads as wrong; the parallax is what matters.
    private var driftTransition: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .offset(x:  14 * transitionDirection)),
            removal:   .opacity.combined(with: .offset(x:  -8 * transitionDirection))
        )
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
