//
//  AppShell.swift
//  Vayl
//

import SwiftUI
import SwiftData

struct AppShell: View {

    @Environment(AppState.self) private var appState

    @State private var selectedTab:        AppTab  = .home
    @State private var contentTab:         AppTab  = .home
    @State private var transitionDirection: CGFloat = 1

    var body: some View {
        @Bindable var appState = appState
        Group {
            switch contentTab {
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
            }
        }
        // Settings lives OVER the shell, not in it: the masthead gear on any tab
        // opens it full screen (discrete-task exit via its own close button, so
        // no confirm-on-exit).
        .vaylCover(isPresented: $appState.settingsPresented, confirmOnExit: false) {
            SettingsView()
        }
        // The tab bar is attached as a bottom SAFE-AREA INSET, not a ZStack overlay.
        // SwiftUI then (1) positions the pill above the home indicator on every device and
        // (2) reserves its EXACT rendered height as a content inset for every tab — a single
        // source of truth, so the bar can't sit wrong and screens stop hand-rolling their
        // own bottom clearance. Per-tab atmospheres still bleed behind it via their own
        // .ignoresSafeArea(), so the pill floats over the void.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            RacetrackTabBar(selection: Binding(
                get: { selectedTab },
                set: { newTab in
                    let fromIdx = AppTab.allCases.firstIndex(of: selectedTab) ?? 0
                    let toIdx   = AppTab.allCases.firstIndex(of: newTab) ?? 0
                    transitionDirection = CGFloat(toIdx > fromIdx ? 1 : -1)
                    selectedTab = newTab
                }
            ))
            // Recede with Home when the deck/chest is engaged, so only the chest stays lit.
            // Matches the greeting/getting-started fade in HomeDashboardView; taps are
            // blocked while engaged so a stray tab tap can't yank you out mid-selection.
            .opacity(appState.deckEngaged ? 0.25 : 1)
            .blur(radius: appState.deckEngaged ? 6 : 0)
            .allowsHitTesting(!appState.deckEngaged)
            .animation(AppAnimation.enter, value: appState.deckEngaged)
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
        .onAppear {
            selectedTab = appState.selectedTab
            contentTab  = appState.selectedTab
        }
        // Programmatic routing (e.g. joiner banner → Play). No racetrack animation involved.
        .onChange(of: appState.selectedTab) { _, newTab in
            guard selectedTab != newTab else { return }
            selectedTab = newTab
        }
        // selectedTab is the single source of truth for the tab bar.
        // Content and appState stay in lockstep here rather than in the binding set,
        // so this onChange fires in a render cycle after the Button action — keeping
        // withAnimation(tabSwitch) temporally separated from runSequence's own
        // withAnimation calls and preventing animation-transaction conflicts.
        .onChange(of: selectedTab) { _, newTab in
            if appState.selectedTab != newTab { appState.selectedTab = newTab }
            if newTab != .home { appState.deckEngaged = false }
            withAnimation(AppAnimation.tabSwitch) { contentTab = newTab }
        }
    }

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
    let entitlements = EntitlementStore(modelContainer: .previewContainerWithProfile, appState: state)
    return AppShell()
        .environment(state)
        .environment(PulseStore())
        .environment(entitlements)
        .environment(CoupleContext(appState: state, entitlements: entitlements, modelContainer: .previewContainerWithProfile))
        .environment(AuthStore())
        .preferredColorScheme(.dark)
        .modelContainer(.previewContainerWithProfile)
}

#Preview("Home — Unlinked Together") {
    let state = AppState()
    state.linkState = .unlinked
    state.appMode = .together
    state.displayName = "Jordan"
    let entitlements = EntitlementStore(modelContainer: .previewContainerWithProfile, appState: state)
    return AppShell()
        .environment(state)
        .environment(PulseStore())
        .environment(entitlements)
        .environment(CoupleContext(appState: state, entitlements: entitlements, modelContainer: .previewContainerWithProfile))
        .environment(AuthStore())
        .preferredColorScheme(.dark)
        .modelContainer(.previewContainerWithProfile)
}

#Preview("Home — Unlinked Solo") {
    let state = AppState()
    state.linkState = .unlinked
    state.appMode = .solo
    state.displayName = "Riley"
    let entitlements = EntitlementStore(modelContainer: .previewContainerWithProfile, appState: state)
    return AppShell()
        .environment(state)
        .environment(PulseStore())
        .environment(entitlements)
        .environment(CoupleContext(appState: state, entitlements: entitlements, modelContainer: .previewContainerWithProfile))
        .environment(AuthStore())
        .preferredColorScheme(.dark)
        .modelContainer(.previewContainerWithProfile)
}
