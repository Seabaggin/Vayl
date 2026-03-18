//
//  Open_LightlyApp.swift
//  Open Lightly
//
//  Originally created in earlier batches.
//  Modified in Batch 9 — Auth gate added (SignInView vs ContentView).
//  Modified in Batch 10 — Added pending sync retry on app launch.
//
//  PURPOSE:
//  This is the app's entry point — the very first thing that runs.
//  It handles three critical responsibilities:
//
//  1. THEME: Creates and injects ThemeManager so every view can
//     access the user's chosen theme (colors, fonts, etc.)
//
//  2. AUTH GATE: Checks if the user is logged in.
//     - Logged in → show ContentView (the main tabbed app)
//     - Not logged in → show SignInView (Sign in with Apple)
//
//  3. DATA: Sets up the SwiftData ModelContainer so all views
//     can read/write local persistent data (UserProfile, etc.)
//
//  BATCH 10 ADDITION:
//  Added a second .task modifier that retries any Supabase syncs
//  that failed in a previous session (e.g., user was offline during
//  onboarding). This runs every app launch but is safe to call
//  repeatedly — it checks UserDefaults flags first and does nothing
//  if there's nothing pending.
//

import SwiftUI
import SwiftData
import Combine

@main
struct Open_LightlyApp: App {

    // ── Theme Manager ──
    // Controls the app's visual theme (colors, fonts, dark/light mode).
    // Injected into the environment so any child view can read it
    // with @Environment(ThemeManager.self).
    @State private var themeManager = ThemeManager()

    // ── Auth Service ──
    // Manages user authentication state (Sign in with Apple + Supabase).
    // @StateObject so it persists for the lifetime of the app.
    // Provides:
    //   - authService.isAuthenticated (Bool) — drives the auth gate below
    //   - authService.userId (UUID?) — the logged-in user's Supabase ID
    @StateObject private var authService = AuthService()

    var body: some Scene {
        WindowGroup {
            Group {
                // ── Auth Gate ──
                // This is the top-level fork in the entire app:
                //   - Authenticated? → Show the main app (ContentView with tabs)
                //   - Not authenticated? → Show the sign-in screen
                if authService.isAuthenticated {
                    ContentView()
                        .themedRoot()               // Applies theme modifiers (must be INSIDE)
                        .environment(themeManager)   // Provides ThemeManager to child views (must be OUTSIDE)
                } else {
                    SignInView()
                }
            }
            // ── Shared Environment Objects ──
            // AuthService is available to EVERY view in the app via
            // @EnvironmentObject var authService: AuthService
            .environmentObject(authService)

            // ── Session Check (Batch 9) ──
            // Runs on every app launch. Checks if the user has an existing
            // Supabase auth session (stored in keychain). If yes, sets
            // isAuthenticated = true so the auth gate shows ContentView.
            // If no session (or it expired), shows SignInView.
            .task {
                await authService.checkSession()
            }

            // ── BATCH 10 ADDITION: Retry Pending Supabase Syncs ──
            // This runs on every app launch AFTER the session check above.
            // It looks for UserDefaults flags that indicate a previous
            // Supabase sync failed (e.g., profile creation during onboarding
            // while the user was offline). If flags are found, it retries
            // those syncs using the locally saved SwiftData data.
            //
            // Safe to call every launch — does nothing if no flags are set.
            //
            // FLAGS IT CHECKS:
            //   - "pendingProfileSync"    → re-pushes user profile to Supabase
            //   - "pendingOnboardingSync" → re-sets has_completed_onboarding = true
            .task {
                // Wait briefly to let the auth session check finish first.
                // Without this, authService.userId might still be nil.
                try? await Task.sleep(for: .seconds(1))
                // SAFETY GATE: Only retry syncs if onboarding has actually been completed locally.
                let onboardingDone = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
                guard onboardingDone, let userId = authService.userId else { return }
                await SyncManager.shared.retryPendingSyncs(
                    userId: userId,
                    localProfile: nil
                )
            }

            // ── SwiftData Container ──
            // Sets up the on-device database using your custom container
            // (defined in ModelContainer.appContainer). This makes SwiftData's
            // ModelContext available to all child views via @Environment(\.modelContext).
            .modelContainer(ModelContainer.appContainer)
        }
    }
}
