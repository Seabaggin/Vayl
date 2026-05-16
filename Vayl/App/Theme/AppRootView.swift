import SwiftUI

// ─────────────────────────────────────────────────────────────
// AppRootView — top-level routing gate.
//
// Responsibilities:
//   1. Show SplashScreenView once per cold launch.
//      Suppressed on foreground resume from background —
//      scenePhase gate sets splashDone = true when the app
//      moves to background so the next foreground is treated
//      as a resume, not a cold launch.
//   2. After splash, route to auth or onboarding based on
//      persistent state read from UserDefaults / AuthService.
//
// Does NOT own app-level stores — those live in VaylApp and
// flow down via environment. This view only reads environment
// values it needs for routing decisions.
// ─────────────────────────────────────────────────────────────

struct AppRootView: View {

    // MARK: - Environment

    @Environment(AuthService.self) private var authService
    @Environment(\.scenePhase)     private var scenePhase

    // MARK: - State

    @State private var splashDone = false

    // MARK: - Routing

    @ViewBuilder
    private var postSplashDestination: some View {
        if authService.isAuthenticated {
            AppShell()
                .themedRoot()
        } else if UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
            SignInView(authService: authService)
                .themedRoot()
        } else {
            OnboardingCanvasView()
                .themedRoot()
        }
    }

    // MARK: - Body

    var body: some View {
        Group {
            if !splashDone {
                SplashScreenView(
                    onComplete:  { splashDone = true },
                    onTearBegan: {},
                    destination: AnyView(postSplashDestination)
                )
            } else {
                postSplashDestination
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            // App moved to background — next foreground is a resume, not a cold
            // launch. Mark splash done so it does not replay on return.
            if newPhase == .background {
                splashDone = true
            }
        }
    }
}
