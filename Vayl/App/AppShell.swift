//
//  AppShell.swift
//  Vayl
//

import SwiftUI
import SwiftData

struct AppShell: View {

    @Environment(AppState.self) private var appState

    @State private var selectedTab: AppTab  = .home
    @State private var contentTab: AppTab  = .home
    @State private var transitionDirection: CGFloat = 1

    var body: some View {
        @Bindable var appState = appState
        Group {
            // Tabs are hosted directly. The old TabContentWrapper was retired
            // (2026-07-19): two of its three documented jobs — bottom content
            // inset and scroll-indicator inset — had already moved to the
            // `.safeAreaInset` tab bar below, and its one remaining behaviour (a
            // 110pt bottom fade mask) was applied to the WHOLE tab, so it
            // dissolved each screen's void + atmosphere and killed hit-testing in
            // the bottom strip. Backgrounds bleed, content insets — a mask over
            // the background is the inverse of that rule. If a bottom dissolve is
            // wanted again, it belongs on the ScrollView (a companion to
            // `.scrollTopEdgeFade()`), never on the tab.
            switch contentTab {
            case .home:
                HomeRouterView()
                    .transition(driftTransition)
            case .play:
                PlayView()
                    .transition(driftTransition)
            case .map:
                MapView()
                    .transition(driftTransition)
            case .learn:
                LearnView()
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
            // pad below IS the true gap to the physical edge. `.md` (16pt), set 2026-07-21.
            //
            // The line to clear is the HOME INDICATOR, not the 34pt safe area. The indicator
            // is a 5pt pill sitting 8pt off the edge, so its top edge is at 13pt; 16pt leaves
            // 3pt of air above it. The 34pt inset is dead space a full-width bar must reserve
            // — a floating pill rides inside it, which is the whole point of floating.
            //
            // Briefly set to `.lg` (24pt) on the reasoning that 60 + 24 matched the system
            // bar's 50 + 34 total footprint. That was wrong: it matched a number that includes
            // reserved emptiness, and the bar read as hovering. Band is ~14–20pt; below 13
            // overlaps the indicator, past ~22 floats.
            //
            // Verified against a to-scale indicator in docs/mockups/tab-bar-sizing.html.
            // FEEL: confirm on device.
            .padding(.bottom, AppSpacing.sm)
            .ignoresSafeArea(.all, edges: .bottom)
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
            insertion: .opacity.combined(with: .offset(x: 14 * transitionDirection)),
            removal: .opacity.combined(with: .offset(x: -8 * transitionDirection))
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
