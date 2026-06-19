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
                }
                .task {
                    // Waits for session check to resolve before retrying syncs.
                    // Task.sleep is a known issue — tracked for replacement
                    // with proper async coordination. See handoff doc.
                    try? await Task.sleep(for: .seconds(1))
                    let onboardingDone = appState.isOnboardingComplete
                    guard onboardingDone, let userId = authService.userId else { return }
                    await SyncManager.shared.retryPendingSyncs(userId: userId)
                }
                .modelContainer(ModelContainer.appContainer)
        }
    }
}
