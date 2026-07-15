//
//  VaylApp.swift
//  Vayl
//

import SwiftUI
import Sentry

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
        Self.startSentryIfNeeded()
        PostHogService.shared.setupIfNeeded()

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

    // MARK: - Sentry (production-focused)
    //
    // Vayl uses Sentry for real production crash / hang / performance signal.
    // Local dev builds stay OUT of Sentry by default: debugging (breakpoints,
    // slow simulator launches) reads as an "app hang" to Sentry's monitor and
    // would pollute the production project with false positives (that is what
    // generated the "App Hang" email). To exercise Sentry from a dev build, set
    // the `VAYL_SENTRY_TEST=1` environment variable in the Run scheme — it then
    // reports under the separate `debug` environment, never `production`.

    private static func startSentryIfNeeded() {
        #if DEBUG
        guard ProcessInfo.processInfo.environment["VAYL_SENTRY_TEST"] == "1" else { return }
        let environmentName = "debug"
        let sampleRate = 1.0            // full capture while explicitly testing
        #else
        let environmentName = "production"
        let sampleRate = 0.2            // sane production sampling (quota + runtime overhead)
        #endif

        SentrySDK.start { options in
            options.dsn = "https://74388eccb3916eb3fac30d46744b3c0f@o4511702079897600.ingest.us.sentry.io/4511702082781184"
            options.environment = environmentName
            // Privacy: Vayl is privacy-first — never attach user IPs / PII by default.
            options.sendDefaultPii = false
            options.tracesSampleRate = NSNumber(value: sampleRate)
            options.configureProfiling = {
                $0.sessionSampleRate = Float(sampleRate)
                $0.lifecycle = .trace
            }
            options.enableLogs = true
        }
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
                    // Keep auth state live for the app's lifetime: when connectivity
                    // returns while foregrounded, the SDK's auto-refresh clears any
                    // offline flag without waiting for a scene-phase change.
                    authStore.startObservingAuthState()
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
                    if let userId = authStore.userId {
                        PostHogService.shared.identify(authId: userId)
                    }
                    // Routing is now decided (onboarding reconciled + session checked,
                    // success or failure) — release the splash to reveal. Everything
                    // below is post-reveal warmup and must NOT gate the splash.
                    appState.isRoutingSettled = true
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
                    // If we entered the app authenticated-but-offline, a return to
                    // foreground is a natural moment to re-attempt the session refresh.
                    Task { await authStore.retrySessionIfOffline() }
                }
                .modelContainer(ModelContainer.appContainer)
        }
    }
}
