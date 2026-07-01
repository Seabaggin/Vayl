//
//  AppShell.swift
//  Vayl
//

import SwiftUI
import SwiftData

struct AppShell: View {

    @State private var selectedTab:  AppTab  = .home
    @State private var bloomScale:   CGFloat = 0
    @State private var bloomOpacity: CGFloat = 0

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
                .padding(.top, AppSpacing.sm)
                // Drop the pill into the home-indicator strip and set the gap ourselves: without
                // this, `.safeAreaInset` floats the bar ABOVE the ~34pt system inset, which reads
                // as dead space. `.ignoresSafeArea(.container, .bottom)` collapses that inset so the
                // pad below IS the true gap to the physical edge. Kept at `.sm` (8pt), not tighter,
                // so the pill clears the home-indicator gesture zone. FEEL: confirm on device.
                .padding(.bottom, AppSpacing.sm)
                .ignoresSafeArea(.container, edges: .bottom)
                // Bloom lives as a background of the bar so the pill chrome renders ON TOP of it.
                // Being in the bar's safeAreaInset layer keeps it out of the main content Group's
                // overlay stack — it rises from behind the bar rather than floating over content.
                // blendMode(.screen) makes it additive on the dark void: purple light adds to
                // underlying pixels rather than covering them. offset(y:) centres the orb in the
                // bar zone; scale expands it upward through the screen at tap time.
                .background(alignment: .center) {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    AppColors.accentSecondary.opacity(0.55),
                                    AppColors.accentSecondary.opacity(0.20),
                                    .clear
                                ],
                                center:      .center,
                                startRadius: 0,
                                endRadius:   90
                            )
                        )
                        .frame(width: 200, height: 200)
                        .scaleEffect(bloomScale)
                        .opacity(bloomOpacity)
                        .blendMode(.screen)
                        .allowsHitTesting(false)
                        .offset(y: -50)
                }
        }
        .onChange(of: selectedTab) { _, _ in triggerBloom() }
    }

    private func triggerBloom() {
        bloomScale   = 0
        bloomOpacity = 0

        // Appear fast, expand over the enter curve
        withAnimation(AppAnimation.fast)  { bloomOpacity = 1.0 }
        withAnimation(AppAnimation.enter) { bloomScale   = 8   }

        // Hold at full opacity so it reads, then dissolve
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(AppAnimation.standard) { bloomOpacity = 0 }
        }

        // Reset scale after fully dissolved
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.60) {
            bloomScale = 0
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
