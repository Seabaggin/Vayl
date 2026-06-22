//
//  AppShell.swift
//  Vayl
//

import SwiftUI

struct AppShell: View {

    @State private var selectedTab: AppTab = .home

    var body: some View {
        GeometryReader { geo in
            let layout = AppLayout.from(geo)

            ZStack(alignment: .bottom) {
                Group {
                    switch selectedTab {
                    case .home:
                        TabContentWrapper { HomeRouterView() }
                    case .play:
                        TabContentWrapper { PlayView() }
                    case .map:
                        TabContentWrapper { MapView() }
                    case .learn:
                        TabContentWrapper { LearnView() }
                    }
                }
                .ignoresSafeArea(edges: .bottom)

                RacetrackTabBar(selection: $selectedTab)
                    .padding(.bottom, layout.homeIndicatorInset + AppSpacing.xs)
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .ignoresSafeArea(edges: .bottom)
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
        .preferredColorScheme(.dark)
}

#Preview("Home — Unlinked Together") {
    let state = AppState()
    state.linkState = .unlinked
    state.appMode = .together
    state.displayName = "Jordan"
    return AppShell()
        .environment(state)
        .environment(PulseStore())
        .preferredColorScheme(.dark)
}

#Preview("Home — Unlinked Solo") {
    let state = AppState()
    state.linkState = .unlinked
    state.appMode = .solo
    state.displayName = "Riley"
    return AppShell()
        .environment(state)
        .environment(PulseStore())
        .preferredColorScheme(.dark)
}
