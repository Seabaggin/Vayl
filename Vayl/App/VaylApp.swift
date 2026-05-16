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
    @State private var appState = AppState()
    @State private var pulseStore = PulseStore()
    @State private var authService = AuthService()
    @State private var onboardingStore = OnboardingStore(
        modelContainer: ModelContainer.appContainer,
        appState: AppState()   // replaced with the real instance in body's .task below
    )

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(themeManager)
                .environment(appState)
                .environment(authService)
                .environment(pulseStore)
                .environment(onboardingStore)
                .task {
                    onboardingStore.appState = appState
                    await authService.checkSession()
                }
                .task {
                    // Waits for session check to resolve before retrying syncs.
                    // Task.sleep is a known issue — tracked for replacement
                    // with proper async coordination. See handoff doc.
                    try? await Task.sleep(for: .seconds(1))
                    let onboardingDone = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
                    guard onboardingDone, let userId = authService.userId else { return }
                    await SyncManager.shared.retryPendingSyncs(
                        userId: userId,
                        localProfile: nil
                    )
                }
                .modelContainer(ModelContainer.appContainer)
        }
    }
}
