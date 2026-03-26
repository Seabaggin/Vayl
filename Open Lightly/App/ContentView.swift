// App/ContentView.swift
// Open Lightly
//
// Root router. Two responsibilities only:
//   1. Gate: onboarding vs. main app (via @AppStorage)
//   2. Guest fork: browsing experience skips tab bar entirely
//
// Tab bar structure:
//   Home   → HomeView (thin router → experience-specific home)
//   Me/Us  → MeUsView (label = "Me" solo, "Us · Me" couple)
//   Explore → ExploreView
//   More   → MoreView
//
// Do NOT add business logic here. All routing beyond experience-type
// selection lives in HomeView and feature ViewModels.

import SwiftUI
import OSLog

private let logger = Logger(subsystem: "com.openlightly.app", category: "ContentView")

struct ContentView: View {

    // ── Onboarding gate ──────────────────────────────────────────────────
    // Source of truth for whether onboarding has been completed.
    // Written by OnboardingFlowView on completion.
    // IMPORTANT: Do not move this gate to AppState — @AppStorage provides
    // immediate reactivity without any init ordering issues.
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    // ── Experience routing ───────────────────────────────────────────────
    @Environment(AppState.self) private var appState

    // ── Tab selection ────────────────────────────────────────────────────
    @State private var selectedTab: AppTab = .home

    // MARK: - Body

    var body: some View {
        if hasCompletedOnboarding {
            mainApp
        } else {
            OnboardingFlowView()
        }
    }

    // MARK: - Main App

    @ViewBuilder
    private var mainApp: some View {
        if appState.experienceType.isGuest {
            // Browsing / guest mode: no tab bar, just More + banner
            guestShell
        } else {
            tabBar
        }
    }

    // MARK: - Guest Shell

    private var guestShell: some View {
        VStack(spacing: 0) {
            GuestBannerView()
            MoreView()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.pageBg.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        TabView(selection: $selectedTab) {

            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(AppTab.home)

            MeUsView()
                .tabItem {
                    Label(
                        appState.experienceType.isCoupleAccount ? "Us · Me" : "Me",
                        systemImage: appState.experienceType.isCoupleAccount
                            ? "person.2.fill"
                            : "person.fill"
                    )
                }
                .tag(AppTab.meUs)

            ExploreView()
                .tabItem { Label("Explore", systemImage: "safari.fill") }
                .tag(AppTab.explore)

            MoreView()
                .tabItem { Label("More", systemImage: "ellipsis.circle.fill") }
                .tag(AppTab.more)
        }
        .tint(AppColors.cyan)
        .preferredColorScheme(.dark)
        .onAppear {
            logger.info("Tab bar appeared — experience: \(appState.experienceType.rawValue)")
        }
    }
}

// MARK: - Preview

#Preview("Onboarding") {
    ContentView()
        .environment(AppState())
        .preferredColorScheme(.dark)
}

#Preview("Main App — Solo") {
    let state = AppState()
    state.experienceType = .soloSingle
    return ContentView()
        .environment(state)
        .preferredColorScheme(.dark)
}

#Preview("Guest") {
    let state = AppState()
    state.experienceType = .browsing
    return ContentView()
        .environment(state)
        .preferredColorScheme(.dark)
}
