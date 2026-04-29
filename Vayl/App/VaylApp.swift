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

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isAuthenticated {
                    ContentView()
                        .themedRoot()
                        .environment(themeManager)
                        .environment(appState)
                } else {
                    SignInView(authService: authService)
                }
            }
            .environment(authService)
            .environment(pulseStore)
            .task {
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
