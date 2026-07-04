//
//  VaylApp.swift
//  Vayl
//

import SwiftUI
import SwiftData

@main
struct VaylApp: App {

    // MARK: - App-Level State

    @State private var themeManager = ThemeManager()
    @State private var appState: AppState
    @State private var pulseStore = PulseStore()
    @State private var authService = AuthService()
    @State private var onboardingStore: OnboardingStore
    @State private var entitlementStore: EntitlementStore

    @Environment(\.scenePhase) private var scenePhase

    // MARK: - Init
    // Composition root: build AppState once and inject the SAME instance into
    // OnboardingStore — no throwaway, no post-launch reassignment. VaylApp.init is
    // main-actor (SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor), so constructing these
    // @MainActor stores here is safe.
    init() {
        let appState = AppState()
        _appState = State(initialValue: appState)
        _onboardingStore = State(initialValue: OnboardingStore(
            modelContainer: ModelContainer.appContainer,
            appState: appState
        ))
        // Central tier read-surface — one purchase unlocks both partners. Gates read this (M3+).
        _entitlementStore = State(initialValue: EntitlementStore(
            modelContainer: ModelContainer.appContainer,
            appState: appState
        ))
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .preferredColorScheme(.dark)
                .environment(themeManager)
                .environment(appState)
                .environment(authService)
                .environment(pulseStore)
                .environment(onboardingStore)
                .environment(entitlementStore)
                .task {
                    // Reconcile the onboarding gate against the durable truth (UserProfile)
                    // before anything routes — init only read the fast UserDefaults cache.
                    appState.hydrateOnboardingState(from: ModelContainer.appContainer)
                    await authService.checkSession()
                    // Resolve tier (server + local StoreKit) + load the product + start the
                    // purchase-updates listener, now the session is ready (RLS-scoped).
                    await entitlementStore.bootstrap()
                    // Pull down any Pulse history the device doesn't have locally yet
                    // (reinstall / new device) — session is ready, so RLS-scoped reads work.
                    await pulseStore.hydrateFromServer()
                    
                    // Now that session is guaranteed to be checked, retry syncs safely.
                    let onboardingDone = appState.isOnboardingComplete
                    if onboardingDone, let userId = authService.userId {
                        await SyncManager.shared.retryPendingSyncs(userId: userId)
                    }
                }
                // Reconcile Pulse on every return to foreground, not just cold launch —
                // a check-in made offline that reconnects mid-session would otherwise
                // wait for the next relaunch to reach the server (hydrateFromServer is
                // bidirectional: pull-merge, then a bounded push-back of unsynced days).
                // Safe pre-auth: fetchOwnEntries returns nil when signed out, which
                // hydrateFromServer treats as "leave local state alone."
                .onChange(of: scenePhase) { _, newPhase in
                    guard newPhase == .active else { return }
                    Task { await pulseStore.hydrateFromServer() }
                }
                .modelContainer(ModelContainer.appContainer)
        }
    }
}
