import SwiftUI

#if DEBUG
/// Set to true to always route to OnboardingCanvasView on launch.
/// Flip to false to restore normal auth/onboarding routing.
/// (Currently false so the session work can be tested past the OB.)
private let forceOnboarding = false
#endif

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
//      AppState (onboarding gate) / AuthService. Routing is
//      reactive — AppState is @Observable, so completing
//      onboarding transitions the root without a relaunch.
//
// Does NOT own app-level stores — those live in VaylApp and
// flow down via environment. This view only reads environment
// values it needs for routing decisions.
// ─────────────────────────────────────────────────────────────

struct AppRootView: View {

    // MARK: - Environment

    @Environment(AuthService.self) private var authService
    @Environment(AppState.self)    private var appState
    @Environment(\.scenePhase)     private var scenePhase

    // MARK: - State

    @State private var splashDone = false

    // MARK: - Routing

    @ViewBuilder
    private var postSplashDestination: some View {
        #if DEBUG
        if forceOnboarding {
            OnboardingCanvasWrapper()
                .themedRoot()
        } else {
            routedDestination
        }
        #else
        routedDestination
        #endif
    }

    @ViewBuilder
    private var routedDestination: some View {
        // Onboarding gates FIRST. A user without a completed onboarding has no local
        // UserProfile (it's created by OnboardingStore.commit), and pairing's
        // persistLink requires one — so route through OnboardingCanvas regardless of
        // auth state, then sign-in, then the app. The terminal FounderLetterPhase
        // commits via director.finishOnboarding → isOnboardingComplete flips true and
        // reactive routing carries the user onward.
        if !appState.isOnboardingComplete {
            OnboardingCanvasWrapper()
                .themedRoot()
        } else if authService.isAuthenticated {
            AppShell()
                .themedRoot()
        } else {
            SignInView(authService: authService)
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
