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
    @State private var authStore = AuthStore()
    @State private var onboardingStore: OnboardingStore
    @State private var entitlementStore: EntitlementStore
    @State private var coupleContext: CoupleContext

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
        let entitlementStore = EntitlementStore(
            modelContainer: ModelContainer.appContainer,
            appState: appState
        )
        _entitlementStore = State(initialValue: entitlementStore)
        // Couple-fact single source of truth: partner identity + the reveal gate
        // (2026-07-04 audit, Blueprint A). Surfaces read this; nothing re-derives it.
        _coupleContext = State(initialValue: CoupleContext(
            appState: appState,
            entitlements: entitlementStore,
            modelContainer: ModelContainer.appContainer
        ))
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .preferredColorScheme(.dark)
                .environment(themeManager)
                .environment(appState)
                .environment(authStore)
                .environment(pulseStore)
                .environment(onboardingStore)
                .environment(entitlementStore)
                .environment(coupleContext)
                .task {
                    #if DEBUG
                    let debugSeedRan = await DebugCoupleSeedService(
                        modelContainer: ModelContainer.appContainer,
                        appState: appState,
                        authService: authStore.service
                    ).runIfRequested()
                    if debugSeedRan {
                        appState.hydrateOnboardingState(from: ModelContainer.appContainer)
                    } else {
                        // Reconcile the onboarding gate against the durable truth (UserProfile)
                        // before anything routes — init only read the fast UserDefaults cache.
                        appState.hydrateOnboardingState(from: ModelContainer.appContainer)
                        await authStore.checkSession()
                    }
                    #else
                    // Reconcile the onboarding gate against the durable truth (UserProfile)
                    // before anything routes — init only read the fast UserDefaults cache.
                    appState.hydrateOnboardingState(from: ModelContainer.appContainer)
                    await authStore.checkSession()
                    #endif
                    // Resolve tier (server + local StoreKit) + load the product + start the
                    // purchase-updates listener, now the session is ready (RLS-scoped).
                    await entitlementStore.bootstrap()
                    // Hydrate the couple facts (partner identity) once the session
                    // is ready — every partner-name surface reads CoupleContext.
                    await coupleContext.refreshIfNeeded()
                    // Pull down any Pulse history the device doesn't have locally yet
                    // (reinstall / new device) — session is ready, so RLS-scoped reads work.
                    await pulseStore.hydrateFromServer()
                    
                    // Now that session is guaranteed to be checked, retry syncs safely.
                    let onboardingDone = appState.isOnboardingComplete
                    if onboardingDone, let userId = authStore.userId {
                        await SyncManager.shared.retryPendingSyncs(userId: userId)
                    }
                }
                // Reconcile Pulse on every return to foreground, not just cold launch —
                // a check-in made offline that reconnects mid-session would otherwise
                // wait for the next relaunch to reach the server (hydrateFromServer is
                // bidirectional: pull-merge, then a bounded push-back of unsynced days).
                // Safe pre-auth: fetchOwnEntries returns .failure when signed out, which
                // hydrateFromServer treats as "leave local state alone."
                .onChange(of: scenePhase) { _, newPhase in
                    guard newPhase == .active else { return }
                    Task { await pulseStore.hydrateFromServer() }
                }
                .modelContainer(ModelContainer.appContainer)
        }
    }
}
