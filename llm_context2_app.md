# LLM Context Bundle 2 — Open Lightly · App Logic

> **Scope: Services + Data + Models + All Feature Screens**
> FILE_TRACKER revision: 2026-03-30
> Generated: 2026-03-30 16:55:54 PDT

---

## Table of Contents

  1. [`Open Lightly/App/Open_LightlyApp.swift`](#file-open-lightly-app-open-lightlyapp-swift)
  2. [`Open Lightly/App/ContentView.swift`](#file-open-lightly-app-contentview-swift)
  3. [`Open Lightly/Core/Services/AppState.swift`](#file-open-lightly-core-services-appstate-swift)
  4. [`Open Lightly/Models/Enums/AppEnums.swift`](#file-open-lightly-models-enums-appenums-swift)
  5. [`Open Lightly/Models/Enums/ExperienceType.swift`](#file-open-lightly-models-enums-experiencetype-swift)
  6. [`Open Lightly/Models/Enums/AppTab.swift`](#file-open-lightly-models-enums-apptab-swift)
  7. [`Open Lightly/Core/Services/Config.swift`](#file-open-lightly-core-services-config-swift)
  8. [`Open Lightly/Core/Services/SupabaseManager.swift`](#file-open-lightly-core-services-supabasemanager-swift)
  9. [`Open Lightly/Core/Services/AuthService.swift`](#file-open-lightly-core-services-authservice-swift)
  10. [`Open Lightly/Core/Services/ProfileService.swift`](#file-open-lightly-core-services-profileservice-swift)
  11. [`Open Lightly/Core/Services/PairingService.swift`](#file-open-lightly-core-services-pairingservice-swift)
  12. [`Open Lightly/Core/Services/ContentLoader.swift`](#file-open-lightly-core-services-contentloader-swift)
  13. [`Open Lightly/Core/Services/SyncManager.swift`](#file-open-lightly-core-services-syncmanager-swift)
  14. [`Open Lightly/Core/Services/AssessmentSyncService.swift`](#file-open-lightly-core-services-assessmentsyncservice-swift)
  15. [`Open Lightly/Core/Services/DesireSyncService.swift`](#file-open-lightly-core-services-desiresyncservice-swift)
  16. [`Open Lightly/Core/Services/SessionSyncService.swift`](#file-open-lightly-core-services-sessionsyncservice-swift)
  17. [`Open Lightly/Data/Store/DataStore.swift`](#file-open-lightly-data-store-datastore-swift)
  18. [`Open Lightly/Data/Store/ModelContainer.swift`](#file-open-lightly-data-store-modelcontainer-swift)
  19. [`Open Lightly/Models/Content/ContentAssessmentQuestion.swift`](#file-open-lightly-models-content-contentassessmentquestion-swift)
  20. [`Open Lightly/Models/Content/ContentCard.swift`](#file-open-lightly-models-content-contentcard-swift)
  21. [`Open Lightly/Models/Content/ContentCategory.swift`](#file-open-lightly-models-content-contentcategory-swift)
  22. [`Open Lightly/Models/Content/ContentDesireItem.swift`](#file-open-lightly-models-content-contentdesireitem-swift)
  23. [`Open Lightly/Models/Content/Prompt.swift`](#file-open-lightly-models-content-prompt-swift)
  24. [`Open Lightly/Models/Persistence/RatingRecord.swift`](#file-open-lightly-models-persistence-ratingrecord-swift)
  25. [`Open Lightly/Models/Persistence/SessionRecord.swift`](#file-open-lightly-models-persistence-sessionrecord-swift)
  26. [`Open Lightly/Models/Persistence/StreakRecord.swift`](#file-open-lightly-models-persistence-streakrecord-swift)
  27. [`Open Lightly/Models/Progress/AssessmentResponse.swift`](#file-open-lightly-models-progress-assessmentresponse-swift)
  28. [`Open Lightly/Models/Progress/AssessmentResult.swift`](#file-open-lightly-models-progress-assessmentresult-swift)
  29. [`Open Lightly/Models/Progress/CardProgress.swift`](#file-open-lightly-models-progress-cardprogress-swift)
  30. [`Open Lightly/Models/Progress/Couple.swift`](#file-open-lightly-models-progress-couple-swift)
  31. [`Open Lightly/Models/Progress/CoupleSessionRecord.swift`](#file-open-lightly-models-progress-couplesessionrecord-swift)
  32. [`Open Lightly/Models/Progress/DesireMatch.swift`](#file-open-lightly-models-progress-desirematch-swift)
  33. [`Open Lightly/Models/Progress/DesireRating.swift`](#file-open-lightly-models-progress-desirerating-swift)
  34. [`Open Lightly/Models/Progress/UserProfile.swift`](#file-open-lightly-models-progress-userprofile-swift)
  35. [`Open Lightly/Features/Auth/SignInView.swift`](#file-open-lightly-features-auth-signinview-swift)
  36. [`Open Lightly/Features/Compatibility/DesireMapView.swift`](#file-open-lightly-features-compatibility-desiremapview-swift)
  37. [`Open Lightly/Features/Explore/ExploreView.swift`](#file-open-lightly-features-explore-exploreview-swift)
  38. [`Open Lightly/Features/Home/HomeView.swift`](#file-open-lightly-features-home-homeview-swift)
  39. [`Open Lightly/Features/Home/HomeDashboardView.swift`](#file-open-lightly-features-home-homedashboardview-swift)
  40. [`Open Lightly/Features/Home/HomeGateView.swift`](#file-open-lightly-features-home-homegateview-swift)
  41. [`Open Lightly/Features/Home/HomeMatchReadyView.swift`](#file-open-lightly-features-home-homematchreadyview-swift)
  42. [`Open Lightly/Features/Home/HomeRouterView.swift`](#file-open-lightly-features-home-homerouterview-swift)
  43. [`Open Lightly/Features/Home/HomeWaitingView.swift`](#file-open-lightly-features-home-homewaitingview-swift)
  44. [`Open Lightly/Features/Home/HomeViewSingle.swift`](#file-open-lightly-features-home-homeviewsingle-swift)
  45. [`Open Lightly/Features/Home/HomeViewSolo.swift`](#file-open-lightly-features-home-homeviewsolo-swift)
  46. [`Open Lightly/Features/Home/HomeViewCoupleNew.swift`](#file-open-lightly-features-home-homeviewcouplenew-swift)
  47. [`Open Lightly/Features/Home/HomeViewCoupleExp.swift`](#file-open-lightly-features-home-homeviewcoupleexp-swift)
  48. [`Open Lightly/Features/Home/PostMapReflectionView.swift`](#file-open-lightly-features-home-postmapreflectionview-swift)
  49. [`Open Lightly/Features/Home/Components/DesireMapIndicator.swift`](#file-open-lightly-features-home-components-desiremapindicator-swift)
  50. [`Open Lightly/Features/Home/Components/PartnerChip.swift`](#file-open-lightly-features-home-components-partnerchip-swift)
  51. [`Open Lightly/Features/Home/Components/PickUpCard.swift`](#file-open-lightly-features-home-components-pickupcard-swift)
  52. [`Open Lightly/Features/Home/Components/ReflectionBannerView.swift`](#file-open-lightly-features-home-components-reflectionbannerview-swift)
  53. [`Open Lightly/Features/Home/Components/ReflectionCard.swift`](#file-open-lightly-features-home-components-reflectioncard-swift)
  54. [`Open Lightly/Features/Home/Components/ResearchTicker.swift`](#file-open-lightly-features-home-components-researchticker-swift)
  55. [`Open Lightly/Features/Home/Components/SessionCard.swift`](#file-open-lightly-features-home-components-sessioncard-swift)
  56. [`Open Lightly/Features/Home/Models/HomeEventEngine.swift`](#file-open-lightly-features-home-models-homeeventengine-swift)
  57. [`Open Lightly/Features/Home/Models/HomeModels.swift`](#file-open-lightly-features-home-models-homemodels-swift)
  58. [`Open Lightly/Features/MeUs/MeUsView.swift`](#file-open-lightly-features-meus-meusview-swift)
  59. [`Open Lightly/Features/More/MoreView.swift`](#file-open-lightly-features-more-moreview-swift)
  60. [`Open Lightly/Features/Onboarding/Data/OnboardingData.swift`](#file-open-lightly-features-onboarding-data-onboardingdata-swift)
  61. [`Open Lightly/Features/Onboarding/Data/CuriosityScreenConfig.swift`](#file-open-lightly-features-onboarding-data-curiosityscreenconfig-swift)
  62. [`Open Lightly/Features/Onboarding/Design/OnboardingAtmosphere.swift`](#file-open-lightly-features-onboarding-design-onboardingatmosphere-swift)
  63. [`Open Lightly/Features/Onboarding/Layout/OnboardingLayout.swift`](#file-open-lightly-features-onboarding-layout-onboardinglayout-swift)
  64. [`Open Lightly/Features/Onboarding/Views/OnboardingFlowView.swift`](#file-open-lightly-features-onboarding-views-onboardingflowview-swift)
  65. [`Open Lightly/Features/Onboarding/Views/OnboardingStatView.swift`](#file-open-lightly-features-onboarding-views-onboardingstatview-swift)
  66. [`Open Lightly/Features/Onboarding/Views/OnboardingBrandView.swift`](#file-open-lightly-features-onboarding-views-onboardingbrandview-swift)
  67. [`Open Lightly/Features/Onboarding/Views/OnboardingNameView.swift`](#file-open-lightly-features-onboarding-views-onboardingnameview-swift)
  68. [`Open Lightly/Features/Onboarding/Views/OnboardingModeSelectView.swift`](#file-open-lightly-features-onboarding-views-onboardingmodeselectview-swift)
  69. [`Open Lightly/Features/Onboarding/Views/OnboardingContextView.swift`](#file-open-lightly-features-onboarding-views-onboardingcontextview-swift)
  70. [`Open Lightly/Features/Onboarding/Views/OnboardingCuriosityPickerView.swift`](#file-open-lightly-features-onboarding-views-onboardingcuriositypickerview-swift)
  71. [`Open Lightly/Features/Onboarding/Views/OnboardingBuildingPathView.swift`](#file-open-lightly-features-onboarding-views-onboardingbuildingpathview-swift)
  72. [`Open Lightly/Features/Onboarding/Views/OnboardingCardRevealView.swift`](#file-open-lightly-features-onboarding-views-onboardingcardrevealview-swift)
  73. [`Open Lightly/Features/Onboarding/Views/OnboardingGroundRulesView.swift`](#file-open-lightly-features-onboarding-views-onboardinggroundrulesview-swift)
  74. [`Open Lightly/Features/Onboarding/Views/PairingForkView.swift`](#file-open-lightly-features-onboarding-views-pairingforkview-swift)
  75. [`Open Lightly/Features/Sessions/SessionView.swift`](#file-open-lightly-features-sessions-sessionview-swift)
  76. [`FILE_TRACKER.md`](#file-file-tracker-md)
  77. [`PROJECT_SCOPE.md`](#file-project-scope-md)

---

## File: `Open Lightly/App/Open_LightlyApp.swift` {#file-open-lightly-app-open-lightlyapp-swift}

```swift
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

    // ── App State ──
    // Owns experience-type routing (soloSingle, soloPartnered, coupleNew, etc.)
    // and the onboarding-complete flag that ContentView reads.
    // Injected via .environment(appState) so any child can read with
    // @Environment(AppState.self).
    @State private var appState = AppState()

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
                        .environment(appState)       // Provides AppState for experience routing
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

```

---

## File: `Open Lightly/App/ContentView.swift` {#file-open-lightly-app-contentview-swift}

```swift
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
    
    // ADD this just below the hasCompletedOnboarding @AppStorage line:
    #if DEBUG
    private let forceOnboarding = true   // ← set false to test main app
    #else
    private let forceOnboarding = false
    #endif

    // ── Experience routing ───────────────────────────────────────────────
    @Environment(AppState.self) private var appState

    // ── Tab selection ────────────────────────────────────────────────────
    @State private var selectedTab: AppTab = .home

    // MARK: - Body

    var body: some View {
        if hasCompletedOnboarding && !forceOnboarding {
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

```

---

## File: `Open Lightly/Core/Services/AppState.swift` {#file-open-lightly-core-services-appstate-swift}

```swift
//
//  AppState.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/20/26.
//


// Core/AppState.swift

import Foundation
import OSLog

private let logger = Logger(
    subsystem: "com.openlightly.app",
    category: "AppState"
)

/// Central app-level state. Injected as @Environment at the root.
/// Owns experience routing and onboarding gate.
/// Does not own feature-level state — that lives in feature ViewModels.
@MainActor
@Observable
final class AppState {

    // MARK: - Published State

    var experienceType: ExperienceType {
        didSet {
            persist(experienceType.rawValue, forKey: .experienceType)
            logger.info("Experience changed to: \(self.experienceType.rawValue)")
        }
    }

    var isOnboardingComplete: Bool {
        didSet {
            persist(isOnboardingComplete, forKey: .onboardingComplete)
            logger.info("Onboarding complete: \(self.isOnboardingComplete)")
        }
    }

    var loadState: AppLoadState = .idle

    // MARK: - Init

    init() {
        // Safe read — defaults to .soloSingle if key missing or unrecognised.
        // Unrecognised raw value means a future migration introduced a new case
        // before this version knew about it — .soloSingle is the safest fallback.
        let savedRaw = UserDefaults.standard.string(forKey: PersistenceKey.experienceType.rawValue)

        if let raw = savedRaw, let resolved = ExperienceType(rawValue: raw) {
            self.experienceType = resolved
        } else {
            self.experienceType = .soloSingle
            if savedRaw != nil {
                // A value existed but wasn't recognised — log for diagnostics.
                // Do NOT log the raw value itself (could contain user-entered data in future).
                logger.warning("Unrecognised experienceType in UserDefaults — defaulting to soloSingle")
            }
        }

        self.isOnboardingComplete = UserDefaults.standard.bool(
            forKey: PersistenceKey.onboardingComplete.rawValue
        )
    }

    // MARK: - Private Helpers

    private func persist(_ value: String, forKey key: PersistenceKey) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }

    private func persist(_ value: Bool, forKey key: PersistenceKey) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }

    // MARK: - Persistence Keys

    private enum PersistenceKey: String {
        case experienceType    = "experienceType"
        case onboardingComplete = "isOnboardingComplete"
    }
}

// MARK: - App Load State

enum AppLoadState {
    case idle
    case loading
    case ready
    case error(String)
}
```

---

## File: `Open Lightly/Models/Enums/AppEnums.swift` {#file-open-lightly-models-enums-appenums-swift}

```swift
//
//  AppEnums.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import Foundation
import SwiftUI

// Provide a default Identifiable.id for String-backed RawRepresentable types.
// This lives at the top so each enum can simply declare Identifiable and
// inherit a sensible id automatically (the raw string value).
extension RawRepresentable where Self: Identifiable, RawValue == String {
    var id: String { rawValue }
}

// ============================================================
// AppEnums.swift
// Shared enums used across every model and screen.
//
// WHY ENUMS?
// An enum is a type that can only be one of a fixed set of values.
// This prevents bugs like misspelling "easyy" as a difficulty
// because the compiler forces you to use .easy, .medium, or .deep.
//
// WHY CaseIterable?
// Lets you loop over all cases: Difficulty.allCases gives you
// [.easy, .medium, .deep]. Useful for building UI pickers.
//
// WHY Codable?
// Lets Swift automatically convert these to/from JSON.
// Needed when saving to device or syncing with Supabase.
//
// WHY String raw values?
// Each case stores a string like "easy" or "medium".
// This is what actually gets saved to JSON or a database.
// Without it, Swift would just store an integer index,
// which breaks if you reorder cases later.
// ============================================================


// MARK: - CategoryPhase
// The therapeutic stage a category belongs to.
// Categories are ordered to mirror clinical pacing:
// stabilize the foundation before exploring, explore
// before planning logistics.

enum CategoryPhase: String, CaseIterable, Identifiable, Codable {
    case foundation   // Categories 1-2: communication, security
    case exploration  // Categories 3-4: sexuality, compatibility
    case framework    // Category 5: boundaries and agreements
    case planning     // Category 6: logistics (unlocked last)

    var displayName: String {
        switch self {
        case .foundation:  return "Foundation"
        case .exploration: return "Exploration"
        case .framework:   return "Framework"
        case .planning:    return "Planning"
        }
    }

    var color: Color {
        switch self {
        case .foundation:  return .blue
        case .exploration: return .purple
        case .framework:   return .orange
        case .planning:    return .green
        }
    }
}


// MARK: - CategoryType
// The 6 topic buckets that cards are grouped into.
// These match the spec exactly — 6 categories in therapeutic order.
// See PROJECT_SCOPE.md Section 8.2 for clinical rationale.
//
// ORDER MATTERS: sortOrder is used by the session system to
// recommend which category to tackle next. NM Logistics is
// always last and requires 2+ categories completed to unlock.

enum CategoryType: String, CaseIterable, Identifiable, Codable {
    case relationshipHealth  // Foundation — communication, conflict, intimacy
    case insecurities        // Foundation — fears, attachment, jealousy, compersion
    case sexualSatisfaction  // Exploration — desires, fantasies, satisfaction
    case compatibility       // Exploration — ENM style, hierarchy, time, vision
    case boundaries          // Framework — hard/soft limits, veto, renegotiation
    case nmLogistics         // Planning — scheduling, safer sex, finances, social media

    // Human-readable name for headers and labels
    var displayName: String {
        switch self {
        case .relationshipHealth: return "Relationship Health"
        case .insecurities:       return "Insecurities & Jealousy"
        case .sexualSatisfaction: return "Sexual Satisfaction"
        case .compatibility:      return "Compatibility & Vision"
        case .boundaries:         return "Boundaries & Agreements"
        case .nmLogistics:        return "NM Logistics"
        }
    }

    // Card ID prefix used in JSON content files (e.g. "RH-1", "IJ-3")
    var cardPrefix: String {
        switch self {
        case .relationshipHealth: return "RH"
        case .insecurities:       return "IJ"
        case .sexualSatisfaction: return "SS"
        case .compatibility:      return "CV"
        case .boundaries:         return "BA"
        case .nmLogistics:        return "NL"
        }
    }

    // SF Symbol icon for category headers and list items
    var icon: String {
        switch self {
        case .relationshipHealth: return "heart.fill"
        case .insecurities:       return "shield.fill"
        case .sexualSatisfaction: return "flame.fill"
        case .compatibility:      return "chart.bar.fill"
        case .boundaries:         return "lock.fill"
        case .nmLogistics:        return "list.bullet.clipboard.fill"
        }
    }

    // Which therapeutic phase this category belongs to
    var phase: CategoryPhase {
        switch self {
        case .relationshipHealth: return .foundation
        case .insecurities:       return .foundation
        case .sexualSatisfaction: return .exploration
        case .compatibility:      return .exploration
        case .boundaries:         return .framework
        case .nmLogistics:        return .planning
        }
    }

    // Position in the recommended order (1-indexed, matches spec)
    var sortOrder: Int {
        switch self {
        case .relationshipHealth: return 1
        case .insecurities:       return 2
        case .sexualSatisfaction: return 3
        case .compatibility:      return 4
        case .boundaries:         return 5
        case .nmLogistics:        return 6
        }
    }

    // NM Logistics requires 2+ other categories completed before unlocking.
    // All other categories are available from the start.
    var requiresUnlock: Bool {
        self == .nmLogistics
    }
}


// MARK: - CardType
// What kind of card this is — determines how the session
// renders the card and whether it has a discussion prompt.
//
//   prompt         — partners take turns sharing, discussion required
//   education      — informational content, no prompt
//   educationPrompt — info block followed by a discussion prompt
//   coolOff        — grounding exercise auto-inserted after heavy cards

enum CardType: String, CaseIterable, Identifiable, Codable {
    case prompt
    case education
    case educationPrompt
    case coolOff

    var displayName: String {
        switch self {
        case .prompt:           return "Prompt"
        case .education:        return "Education"
        case .educationPrompt:  return "Education + Prompt"
        case .coolOff:          return "Cool-off"
        }
    }
}


// MARK: - CardStatus
// Per-card state tracked for each couple's session history.
// A card lives in exactly one state at any given time.

enum CardStatus: String, CaseIterable, Identifiable, Codable {
    case notStarted  // Never shown to this couple
    case discussed   // Partners marked "We've Discussed"
    case skipped     // Partners tapped "Not ready"
    case bookmarked  // Flagged to revisit

    var displayName: String {
        switch self {
        case .notStarted: return "Not Started"
        case .discussed:  return "Discussed"
        case .skipped:    return "Skipped"
        case .bookmarked: return "Bookmarked"
        }
    }
}


// MARK: - Difficulty
// How emotionally intense a conversation card is.
// Screens use this to show a label and sort cards by depth.
// (Not in spec — kept as a useful concrete enum for content authors.)

enum Difficulty: String, CaseIterable, Identifiable, Codable {
    case easy    // light warmup prompts
    case medium  // requires some vulnerability
    case deep    // emotionally intense, may trigger safe word

    var displayName: String {
        switch self {
        case .easy:   return "Easy"
        case .medium: return "Medium"
        case .deep:   return "Deep"
        }
    }

    var color: Color {
        switch self {
        case .easy:   return .green
        case .medium: return .orange
        case .deep:   return .red
        }
    }
}


// MARK: - Sensitivity
// How sensitive a card's content is — determines whether
// screenshot protection activates on this card.
// Separate from Difficulty: a card can be emotionally easy
// but still sensitive (e.g. a kink-related education card).

enum Sensitivity: String, CaseIterable, Identifiable, Codable {
    case low
    case medium
    case high

    var displayName: String {
        switch self {
        case .low:    return "Low"
        case .medium: return "Medium"
        case .high:   return "High"
        }
    }
}


// MARK: - DesireLevel
// How a partner feels about a kink/boundary item.
// Used on the Desire Map screen — each partner picks one per item.
//
// PRIVACY: Hard No ratings are NEVER revealed to the partner.
// The matching logic returns nil for any hard-no combination.
// See ContentDesireItem.computeAlignment for implementation.

enum DesireLevel: Int, Codable, CaseIterable {
    case notForMe = 1
    case probablyNot = 2
    case openToIt = 3
    case excitedAboutIt = 4
    
    var displayLabel: String {
        switch self {
        case .notForMe:       return "Not For Me"
        case .probablyNot:    return "Probably Not"
        case .openToIt:       return "Open To It"
        case .excitedAboutIt: return "Excited About It"
        }
    }
    
    var color: String {
        switch self {
        case .notForMe:       return "red"
        case .probablyNot:    return "orange"
        case .openToIt:       return "green"
        case .excitedAboutIt: return "darkGreen"
        }
    }
}


// MARK: - AlignmentLevel
// The result of comparing two partners' kink ratings.
// Only positive matches (mutualYes, exploreZone, worthDiscussing) are stored.
// Hard No combinations are NEVER stored or revealed.
// See PROJECT_SCOPE.md Section 10 for the matching matrix.

enum AlignmentLevel: String, Codable, CaseIterable {
    case strongAlignment
    case aligned
    case talkAboutIt
    case boundary
    case mutualPass
    
    var displayLabel: String {
        switch self {
        case .strongAlignment: return "Strong Alignment"
        case .aligned:         return "Aligned"
        case .talkAboutIt:     return "Talk About It"
        case .boundary:        return "Boundary Respected"
        case .mutualPass:      return "Mutual Pass"
        }
    }
    
    var emoji: String {
        switch self {
        case .strongAlignment: return "🔥"
        case .aligned:         return "💚"
        case .talkAboutIt:     return "💛"
        case .boundary:        return "🔒"
        case .mutualPass:      return "⬜"
        }
    }
}


// MARK: - SessionStatus
// Tracks where a session is in its lifecycle.
// paused is used by the safe word — session suspends but
// is not complete, and can be resumed.

enum SessionStatus: String, CaseIterable, Identifiable, Codable {
    case notStarted
    case inProgress
    case paused     // triggered by safe word; resumes to inProgress
    case completed

    var displayName: String {
        switch self {
        case .notStarted: return "Not Started"
        case .inProgress: return "In Progress"
        case .paused:     return "Paused"
        case .completed:  return "Completed"
        }
    }
}


// MARK: - TurnOrder
// Who speaks first on a given card.
// Alternating turns prevents one partner from dominating.
// "together" is used on lighter prompts where simultaneous
// discussion is more natural than taking turns.

enum TurnOrder: String, CaseIterable, Identifiable, Codable {
    case partnerA  // partner A shares first, B listens
    case partnerB  // partner B shares first, A listens
    // NOTE: Not yet used in card JSON content. Cards only specify "A" or "B".
    // Added for future use. Ensure ContentLoader handles missing case gracefully.
    case together  // both discuss simultaneously

    var displayName: String {
        switch self {
        case .partnerA: return "Partner A"
        case .partnerB: return "Partner B"
        case .together: return "Together"
        }
    }
}


// MARK: - PartnerLabel
// Identifies which person in a couple owns a piece of data.
// Each partner gets a label when the couple links.
// Used on AssessmentResponse, DesireRating, and any other
// per-person data that needs to be attributed.
//
// This is NOT the same as TurnOrder — TurnOrder describes
// who speaks first on a card. PartnerLabel identifies whose
// data this is in the database.

enum PartnerLabel: String, CaseIterable, Identifiable, Codable {
    case partnerA
    case partnerB

    var displayName: String {
        switch self {
        case .partnerA: return "Partner A"
        case .partnerB: return "Partner B"
        }
    }

    var opposite: PartnerLabel {
        switch self {
        case .partnerA: return .partnerB
        case .partnerB: return .partnerA
        }
    }
}


// MARK: - ReadinessLevel
// The five result bands for the couple's overall readiness score.
// Assigned after scoring the 5-domain assessment.
// See PROJECT_SCOPE.md Section 10 for score ranges.

enum ReadinessLevel: String, CaseIterable, Identifiable, Codable {
    case thriving            // 85-100
    case ready               // 70-84
    case someGaps            // 50-69
    case significantConcerns // 35-49
    case notReady            // 0-34

    var displayName: String {
        switch self {
        case .thriving:            return "Thriving Foundation"
        case .ready:               return "Ready with Awareness"
        case .someGaps:            return "Some Gaps to Address"
        case .significantConcerns: return "Significant Concerns"
        case .notReady:            return "Not Ready — Foundation Work Needed"
        }
    }

    // Score range for this level
    var scoreRange: ClosedRange<Int> {
        switch self {
        case .thriving:            return 85...100
        case .ready:               return 70...84
        case .someGaps:            return 50...69
        case .significantConcerns: return 35...49
        case .notReady:            return 0...34
        }
    }

    var color: Color {
        switch self {
        case .thriving:            return .green
        case .ready:               return .blue
        case .someGaps:            return .yellow
        case .significantConcerns: return .orange
        case .notReady:            return .red
        }
    }

    static func level(for score: Int) -> ReadinessLevel {
        let clamped = max(0, min(100, score))
        return allCases.first { $0.scoreRange.contains(clamped) } ?? .notReady
    }
}


// MARK: - AssessmentDomain
// The 5 scored domains in the individual assessment.
// Each domain has 4 questions (20 total across the assessment).
// Domain weights for overall score: Communication 25%, Trust 25%,
// Emotional Security 20%, Sexual Openness 15%, Boundary Awareness 15%.

enum AssessmentDomain: String, CaseIterable, Identifiable, Codable {
    case communication      // weight: 0.25
    case trust              // weight: 0.25
    case emotionalSecurity  // weight: 0.20
    case sexualOpenness     // weight: 0.15
    case boundaryAwareness  // weight: 0.15

    var displayName: String {
        switch self {
        case .communication:     return "Communication"
        case .trust:             return "Trust"
        case .emotionalSecurity: return "Emotional Security"
        case .sexualOpenness:    return "Sexual Openness"
        case .boundaryAwareness: return "Boundary Awareness"
        }
    }

    var weight: Double {
        switch self {
        case .communication:     return 0.25
        case .trust:             return 0.25
        case .emotionalSecurity: return 0.20
        case .sexualOpenness:    return 0.15
        case .boundaryAwareness: return 0.15
        }
    }
}


// MARK: - AssessmentQuestionType
// The input type for an assessment question.
// Scale = 5-point Likert. Multi-select = pick all that apply.
// See PROJECT_SCOPE.md Section 8.1 for question format.

enum AssessmentQuestionType: String, CaseIterable, Identifiable, Codable {
    case scale
    case multiSelect = "multi_select"

    var displayName: String {
        switch self {
        case .scale:       return "Scale (1-5)"
        case .multiSelect: return "Multi-Select"
        }
    }
}


// MARK: - PurchaseTier
// The three entitlement levels.
// Free: assessment + score + 3-5 sample cards + 5 kink items
// Core: full card library (30-40 cards, 5 categories), sessions, notes
// Complete: everything + full Desire Map (40+ items) + NM Logistics + cool-off cards

enum PurchaseTier: String, CaseIterable, Identifiable, Codable {
    case free
    case core
    case complete

    var displayName: String {
        switch self {
        case .free:     return "Free"
        case .core:     return "Core"
        case .complete: return "Complete"
        }
    }

    // Whether this tier includes access to a given category
    func includesCategory(_ category: CategoryType) -> Bool {
        switch self {
        case .free:
            // Free only gets sample content — no full category access
            return false
        case .core:
            // Core includes all categories except NM Logistics
            return category != .nmLogistics
        case .complete:
            // Complete includes everything
            return true
        }
    }
}


// MARK: - NMFlavor
// Which style of ethical non-monogamy the couple is interested in.
// Collected during onboarding or compatibility assessment.
// "unsure" is always a valid answer — the app doesn't require certainty.

enum NMFlavor: String, CaseIterable, Identifiable, Codable {
    case swinging
    case openRelationship
    case polyamory
    case relationshipAnarchy
    case monogamish
    case unsure

    var displayName: String {
        switch self {
        case .swinging:            return "Swinging"
        case .openRelationship:    return "Open Relationship"
        case .polyamory:           return "Polyamory"
        case .relationshipAnarchy: return "Relationship Anarchy"
        case .monogamish:          return "Monogamish"
        case .unsure:              return "Not Sure Yet"
        }
    }
}

```

---

## File: `Open Lightly/Models/Enums/ExperienceType.swift` {#file-open-lightly-models-enums-experiencetype-swift}

```swift
//
//  ExperienceType.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/20/26.
//


// Models/ExperienceType.swift

import Foundation

/// Represents the user's chosen experience mode.
/// Set once during onboarding, changeable via Settings → Switch Experience.
/// Persisted via UserDefaults (non-sensitive — it's a UI routing key only).
enum ExperienceType: String, CaseIterable, Codable {

    case browsing           = "browsing"
    case soloSingle         = "solo_single"
    case soloPartnered      = "solo_partnered"
    case coupleNew          = "couple_new"
    case coupleExperienced  = "couple_experienced"

    // TODO(follow-up): If ExperienceType is ever stored in SwiftData
    // (not just UserDefaults), a SchemaMigrationPlan is required for
    // any case rename or removal.

    var displayName: String {
        switch self {
        case .browsing:          return "Just Browsing"
        case .soloSingle:        return "Solo Explorer"
        case .soloPartnered:     return "Solo (with partner)"
        case .coupleNew:         return "New Couple"
        case .coupleExperienced: return "Experienced ENM"
        }
    }

    /// Tabs visible to this experience. Browsing is gate-locked to .more only.
    var availableTabs: [AppTab] {
        switch self {
        case .browsing:
            return [.more]
        case .soloSingle, .soloPartnered:
            return [.home, .meUs, .explore, .more]
        case .coupleNew, .coupleExperienced:
            return [.home, .meUs, .explore, .more]
        }
    }

    var isCoupleAccount: Bool {
        self == .coupleNew || self == .coupleExperienced
    }

    var isGuest: Bool {
        self == .browsing
    }
}
```

---

## File: `Open Lightly/Models/Enums/AppTab.swift` {#file-open-lightly-models-enums-apptab-swift}

```swift
// Models/Enums/AppTab.swift

import Foundation

/// Tab identifiers for the main tab bar.
/// Raw value matches TabView selection tag.
enum AppTab: Hashable {
    case home
    case meUs       // "Me" for solo, "Us · Me" for couple — label driven by ExperienceType
    case explore
    case more
}

```

---

## File: `Open Lightly/Core/Services/Config.swift` {#file-open-lightly-core-services-config-swift}

```swift
enum Config {
    static let supabaseURL = "https://ynhjlabjzauamntbyxdp.supabase.co"
    static let supabaseAnonKey = "sb_publishable_1jhWS0h_LrTM7jzNmxRRbQ_twrlP8Y3"
}

```

---

## File: `Open Lightly/Core/Services/SupabaseManager.swift` {#file-open-lightly-core-services-supabasemanager-swift}

```swift
//
//  SupabaseManager.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/9/26.
//


import Supabase
import Foundation

final class SupabaseManager {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    private init() {
        guard let url = URL(string: Config.supabaseURL) else {
            fatalError("Invalid Supabase URL")
        }
        client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: Config.supabaseAnonKey
        )
    }
}

```

---

## File: `Open Lightly/Core/Services/AuthService.swift` {#file-open-lightly-core-services-authservice-swift}

```swift
//
//  AuthService.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/9/26.
//

import AuthenticationServices
import Supabase
import CryptoKit
import Foundation
import Combine

@MainActor
final class AuthService: NSObject, ObservableObject {
    
    // MARK: - Published State

    @Published var isAuthenticated = true
    @Published var userId: UUID?
    @Published var isLoading = false
    @Published var error: String?
    
    // MARK: - Private
    
    private var currentNonce: String?
    
    private var supabase: SupabaseClient {
        SupabaseManager.shared.client
    }
    
    // MARK: - Check Existing Session
    
    func checkSession() async {
        #if targetEnvironment(simulator)
        isAuthenticated = true
        userId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        #else
        do {
            let session = try await supabase.auth.session
            self.userId = session.user.id
            self.isAuthenticated = true
            #if DEBUG
            print("✅ Existing session found: \(session.user.id)")
            #endif
        } catch {
            // No active session — user needs to sign in
            #if DEBUG
            print("ℹ️ No existing session")
            #endif
            // ✅ TestFlight ready — properly clears auth state on failure
            self.isAuthenticated = false
            self.userId = nil
        }
        #endif
    }
    
    // MARK: - Sign in with Apple
    
    func signInWithApple() {
        #if targetEnvironment(simulator)
        isAuthenticated = true
        userId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        #else
        isLoading = true
        error = nil

        let nonce = randomNonceString()
        currentNonce = nonce

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.email]
        request.nonce = sha256(nonce)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.performRequests()
        #endif
    }
    
    // MARK: - Sign Out
    
    func signOut() async {
        do {
            try await supabase.auth.signOut()
            self.isAuthenticated = false
            self.userId = nil
            #if DEBUG
            print("✅ Signed out")
            #endif
        } catch {
            self.error = error.localizedDescription
            #if DEBUG
            print("❌ Sign out failed")
            #endif
        }
    }
    
    // MARK: - Current User ID Helper
    
    var currentAuthId: UUID? {
        return userId
    }
    
    // MARK: - Nonce Helpers
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { byte in charset[Int(byte) % charset.count] })
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthService: ASAuthorizationControllerDelegate {
    
    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityTokenData = credential.identityToken,
              let identityToken = String(data: identityTokenData, encoding: .utf8)
        else {
            Task { @MainActor in
                self.error = "Failed to get Apple ID token"
                self.isLoading = false
            }
            return
        }
        
        Task { @MainActor in
            do {
                let session = try await supabase.auth.signInWithIdToken(
                    credentials: .init(
                        provider: .apple,
                        idToken: identityToken,
                        nonce: currentNonce
                    )
                )
                self.userId = session.user.id
                self.isAuthenticated = true
                self.isLoading = false
                #if DEBUG
                print("✅ Apple sign-in successful: \(session.user.id)")
                #endif
            } catch {
                self.error = error.localizedDescription
                self.isLoading = false
                #if DEBUG
                print("❌ Apple sign-in failed: \(error.localizedDescription)")
                #endif
            }
        }
    }
    
    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        Task { @MainActor in
            self.error = error.localizedDescription
            self.isLoading = false
            #if DEBUG
            print("❌ Apple auth error: \(error.localizedDescription)")
            #endif
        }
    }
}

```

---

## File: `Open Lightly/Core/Services/ProfileService.swift` {#file-open-lightly-core-services-profileservice-swift}

```swift
//
//  ProfileService.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/9/26.
//


//
//  ProfileService.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/9/26.
//

import Supabase
import Foundation
import Combine

@MainActor
final class ProfileService: ObservableObject {
    
    private var supabase: SupabaseClient {
        SupabaseManager.shared.client
    }
    
    // MARK: - Supabase Profile Struct
    
    struct SupabaseProfile: Codable {
        let id: UUID?
        let authId: UUID
        let name: String?
        let pronouns: String
        let sexualOrientation: String
        let rolePreference: String
        let userMode: String
        let experienceLevel: String
        let defaultDifficulty: String
        let curiositySelections: [String]
        let surpriseMeEnabled: Bool
        let mythBusterComplete: Bool
        let mythBusterSkipped: Bool
        let nmFlavor: String?
        let pairingCode: String?
        let isLinked: Bool
        let partnerLabel: String?
        let hasCompletedOnboarding: Bool
        let hasCompletedAssessment: Bool
        
        enum CodingKeys: String, CodingKey {
            case id
            case authId = "auth_id"
            case name
            case pronouns
            case sexualOrientation = "sexual_orientation"
            case rolePreference = "role_preference"
            case userMode = "user_mode"
            case experienceLevel = "experience_level"
            case defaultDifficulty = "default_difficulty"
            case curiositySelections = "curiosity_selections"
            case surpriseMeEnabled = "surprise_me_enabled"
            case mythBusterComplete = "myth_buster_complete"
            case mythBusterSkipped = "myth_buster_skipped"
            case nmFlavor = "nm_flavor"
            case pairingCode = "pairing_code"
            case isLinked = "is_linked"
            case partnerLabel = "partner_label"
            case hasCompletedOnboarding = "has_completed_onboarding"
            case hasCompletedAssessment = "has_completed_assessment"
        }
    }
    
    // MARK: - Fetch or Create Profile
    
    /// Fetches the user's profile from Supabase. If none exists, creates one.
    func fetchOrCreateProfile(authId: UUID) async throws -> SupabaseProfile {
        // Try to fetch existing profile
        let existing: [SupabaseProfile] = try await supabase
            .from("user_profiles")
            .select()
            .eq("auth_id", value: authId.uuidString)
            .execute()
            .value
        
        if let profile = existing.first {
            return profile
        }
        
        // No profile exists — create one
        let newProfile = SupabaseProfile(
            id: nil,
            authId: authId,
            name: nil,
            pronouns: "they/them",
            sexualOrientation: "prefer not to say",
            rolePreference: "not sure",
            userMode: "solo",
            experienceLevel: "new",
            defaultDifficulty: "warm",
            curiositySelections: [],
            surpriseMeEnabled: false,
            mythBusterComplete: false,
            mythBusterSkipped: false,
            nmFlavor: nil,
            pairingCode: nil,
            isLinked: false,
            partnerLabel: nil,
            hasCompletedOnboarding: false,
            hasCompletedAssessment: false
        )
        
        let created: SupabaseProfile = try await supabase
            .from("user_profiles")
            .insert(newProfile)
            .select()
            .single()
            .execute()
            .value
        
        return created
    }
    
    // MARK: - Lookup Pairing Code

    /// Scoped response for pairing code lookup.
    /// Contains ONLY the fields needed to confirm a partner in the UI.
    /// Sexual orientation, NM flavor, role preference and all other
    /// sensitive profile fields are intentionally excluded.
    struct PartnerPreview: Codable {
        let name: String?
        let pronouns: String
    }

    /// Looks up a pairing code and returns only the partner's display name
    /// and pronouns — nothing else. The full SupabaseProfile is never
    /// fetched or transmitted to the requesting client.
    func lookupPairingCode(_ code: String) async throws -> PartnerPreview? {
        struct PairingCodeRecord: Codable {
            let code: String
            let userId: UUID
            let used: Bool

            enum CodingKeys: String, CodingKey {
                case code
                case userId = "user_id"
                case used
            }
        }

        let records: [PairingCodeRecord] = try await supabase
            .from("pairing_codes")
            .select()
            .eq("code", value: code)
            .eq("used", value: false)
            .execute()
            .value

        guard let record = records.first else { return nil }

        // Fetch ONLY name and pronouns — all other columns are excluded
        // from the projection so they are never transmitted to the client.
        let previews: [PartnerPreview] = try await supabase
            .from("user_profiles")
            .select("name,pronouns")
            .eq("id", value: record.userId.uuidString)
            .execute()
            .value

        return previews.first
    }
    // MARK: - Mark Onboarding Complete (Batch 10)
        
        /// Sets `has_completed_onboarding = true` in Supabase.
        ///
        /// Called by SyncManager AFTER the local SwiftData model has already
        /// been updated. This is the remote half of that operation.
        ///
        /// - Parameter profileId: The user's profile UUID (the `id` column, not `auth_id`)
        func markOnboardingComplete(profileId: UUID) async throws {
            struct ProfileIdOnly: Codable { let id: UUID }
            let check: [ProfileIdOnly] = try await supabase
                .from("user_profiles")
                .select("id")
                .eq("id", value: profileId.uuidString)
                .execute()
                .value

            guard !check.isEmpty else {
                throw SyncManager.SyncError.profileNotFound
            }

            try await supabase
                .from("user_profiles")
                .update(["has_completed_onboarding": true])
                .eq("id", value: profileId.uuidString)
                .execute()
        }
    
    // MARK: - Ensure Profile Exists

    /// Checks if a profile exists for the given authId. If not, throws an error.
    /// Caches the profile ID in UserDefaults for future use.
    func ensureProfileExists(authId: UUID) async throws -> UUID {
        if let cached = UserDefaults.standard.string(forKey: "supabaseProfileId"),
           let cachedId = UUID(uuidString: cached) {
            return cachedId
        }
        struct ProfileIdOnly: Codable {
            let id: UUID
        }
        let results: [ProfileIdOnly] = try await supabase
            .from("user_profiles")
            .select("id")
            .eq("auth_id", value: authId.uuidString)
            .execute()
            .value
        guard let profile = results.first else {
            throw SyncManager.SyncError.profileNotFound
        }
        UserDefaults.standard.set(profile.id.uuidString, forKey: "supabaseProfileId")
        return profile.id
    }
}

```

---

## File: `Open Lightly/Core/Services/PairingService.swift` {#file-open-lightly-core-services-pairingservice-swift}

```swift
//
//  PairingService.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/9/26.
//


//
//  PairingService.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/9/26.
//

import Supabase
import Foundation
import Combine

@MainActor
final class PairingService: ObservableObject {
    
    // MARK: - Published State
    
    @Published var generatedCode: String?
    @Published var isGenerating = false
    @Published var isLookingUp = false
    @Published var isPairing = false
    @Published var error: String?
    
    @Published var partnerName: String?
    @Published var partnerPronouns: String?
    @Published var partnerId: String?
    
    @Published var pairingComplete = false
    @Published var coupleId: String?
    
    // MARK: - Private
    
    private var supabase: SupabaseClient {
        SupabaseManager.shared.client
    }
    
    private let profileService = ProfileService()
    
    // MARK: - Code Generation
    
    /// Generates a 3-character pairing code: D4G, R2N, 7KM, etc.
    func generateCode(userId: UUID) async {
        isGenerating = true
        error = nil
        let code = createPairingCode()
        do {
            _ = try await profileService.ensureProfileExists(authId: userId)
            try await supabase
                .from("pairing_codes")
                .delete()
                .eq("user_id", value: userId.uuidString)
                .eq("used", value: false)
                .execute()
            let expiresAt = ISO8601DateFormatter().string(
                from: Date().addingTimeInterval(5 * 60)
            )
            try await supabase
                .from("pairing_codes")
                .insert([
                    "code": code,
                    "user_id": userId.uuidString,
                    "expires_at": expiresAt,
                    "used": "false"
                ])
                .execute()
            try await supabase
                .from("user_profiles")
                .update(["pairing_code": code])
                .eq("auth_id", value: userId.uuidString)
                .execute()
            self.generatedCode = code
            #if DEBUG
            print("✅ Pairing code generated: \(code)")
            #endif
        } catch {
            self.error = "Cannot generate code — your profile isn't set up yet. Please complete onboarding first."
            #if DEBUG
            print("❌ Code generation failed: \(error.localizedDescription)")
            #endif
        }
        isGenerating = false
    }
    
    // MARK: - Code Lookup
    
    /// Calls the lookup-code Edge Function to validate a partner's code
    func lookupCode(_ code: String) async {
        isLookingUp = true
        error = nil
        partnerName = nil
        partnerPronouns = nil
        partnerId = nil
        
        do {
            let data: LookupResponse = try await supabase.functions.invoke(
                "lookup-code",
                options: .init(body: ["code": code.uppercased().trimmingCharacters(in: .whitespaces)])
            )
            
            if data.valid {
                self.partnerId = data.partnerId
                self.partnerName = data.partnerName
                self.partnerPronouns = data.partnerPronouns
                #if DEBUG
                print("✅ Code valid — partner: \(data.partnerName ?? "unknown")")
                #endif
            } else {
                self.error = "Invalid or expired code"
            }
        } catch {
            self.error = "Code not found. Check and try again."
            #if DEBUG
            print("❌ Lookup failed: \(error.localizedDescription)")
            #endif
        }
        
        isLookingUp = false
    }
    
    // MARK: - Create Pair
    
    /// Calls the create-pair Edge Function to link both users
    func createPair(code: String, requesterId: UUID) async {
        isPairing = true
        error = nil
        
        do {
            _ = try await profileService.ensureProfileExists(authId: requesterId)
            let data: PairResponse = try await supabase.functions.invoke(
                "create-pair",
                options: .init(body: [
                    "code": code.uppercased().trimmingCharacters(in: .whitespaces),
                    "requesterId": requesterId.uuidString
                ])
            )
            
            if data.success {
                self.coupleId = data.coupleId
                self.pairingComplete = true
                #if DEBUG
                print("✅ Pairing complete! Couple ID: \(data.coupleId ?? "unknown")")
                #endif
            } else {
                self.error = "Pairing failed. Try again."
            }
        } catch {
            self.error = "Pairing failed. Try again."
            #if DEBUG
            print("❌ Pairing failed: \(error.localizedDescription)")
            #endif
        }
        
        isPairing = false
    }
    
    // MARK: - Reset
    
    func reset() {
        generatedCode = nil
        partnerName = nil
        partnerPronouns = nil
        partnerId = nil
        pairingComplete = false
        coupleId = nil
        error = nil
    }
    
    // MARK: - 3-Character Code Generator
    
    /// Generates codes like D4G, R2N, 7KM, B9X
    /// ~27,000 unique combos — no confusing chars (0/O, 1/I, L)
    private func createPairingCode() -> String {
        let chars: [Character] = Array("ABCDEFGHJKMNPQRSTUVWXYZ2345679")
        return String((0..<3).map { _ in chars.randomElement()! })
    }
    
    // MARK: - Response Models
    struct LookupResponse: Codable {
        let valid: Bool
        let partnerId: String?
        let partnerName: String?
        let partnerPronouns: String?
    }
    
    struct PairResponse: Codable {
        let success: Bool
        let coupleId: String?
        let userA: String?
        let userB: String?
    }
}

```

---

## File: `Open Lightly/Core/Services/ContentLoader.swift` {#file-open-lightly-core-services-contentloader-swift}

```swift
//
//  ContentLoader.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import Foundation

// ============================================================
// ContentLoader.swift
// Simple static helper for reading bundled, read-only JSON
// content shipped with the app. These files are part of the
// app bundle and should always be present in production.
// Missing or malformed content is considered a developer error
// and intentionally triggers a fatalError so it is caught early
// during development.
// ============================================================

struct ContentLoader {

    /// Generic loader for an array of Decodable items from a
    /// bundled JSON file. The `filename` should NOT include the
    /// `.json` extension.
    static func load<T: Decodable>(_ type: T.Type, from filename: String) -> [T] {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            fatalError("Content file not found in bundle: \(filename).json")
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode([T].self, from: data)
        } catch {
            fatalError("Failed to load or decode bundled content '\(filename).json': \(error)")
        }
    }


    // MARK: - Convenience Accessors

    static func loadCategories() -> [ContentCategory] {
        load(ContentCategory.self, from: "categories")
    }

    static func loadCards() -> [ContentCard] {
        load(ContentCard.self, from: "cards")
    }

    static func loadAssessmentQuestions() -> [ContentAssessmentQuestion] {
        load(ContentAssessmentQuestion.self, from: "assessment_questions")
    }

    static func loadDesireItems() -> [ContentDesireItem] {
        load(ContentDesireItem.self, from: "desire_items")
    }
}

```

---

## File: `Open Lightly/Core/Services/SyncManager.swift` {#file-open-lightly-core-services-syncmanager-swift}

```swift
//
//  SyncManager.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/10/26.
//


//
//  SyncManager.swift
//  Open Lightly
//
//  Created in Batch 10 — The Bridge Between Local and Remote
//
//  PURPOSE:
//  SyncManager is the ORCHESTRATOR that coordinates writes between:
//    - SwiftData (local, on-device, instant, works offline)
//    - Supabase (remote, cloud, async, needs internet)
//
//  THE GOLDEN RULE:
//  ┌────────────────────────────────────────────────────┐
//  │  1. Save to SwiftData FIRST (instant, never fails) │
//  │  2. Push to Supabase SECOND (async, might fail)    │
//  │  3. If push fails → flag it for retry later        │
//  └────────────────────────────────────────────────────┘
//
//  WHY THIS PATTERN?
//  - The user sees instant UI updates (SwiftData drives the views)
//  - If they're offline or Supabase is down, the app still works
//  - Pending syncs are retried on next app launch
//  - SwiftData = source of truth for UI
//  - Supabase = source of truth for multiplayer/cross-device
//
//  WHO CALLS SYNCMANAGER?
//  Views and view models call SyncManager. SyncManager calls
//  ProfileService, DesireSyncService, etc. Views should NEVER
//  call ProfileService directly.
//

import Foundation
import SwiftData
import Combine

@MainActor  // Runs on main thread — safe for @Published properties that drive UI
class SyncManager: ObservableObject {

    // MARK: - Singleton

    /// Shared instance — access with `SyncManager.shared`
    static let shared = SyncManager()

    // MARK: - Published State (UI can observe these)

    /// True while any sync operation is in progress.
    /// You can use this to show a spinner or "Syncing..." indicator.
    @Published var isSyncing = false

    /// If the last sync failed, this contains the error message.
    /// Nil means everything is fine. You can show this in a toast/alert.
    @Published var lastSyncError: String?

    // MARK: - Dependencies

    /// Reference to ProfileService for all profile-related Supabase calls.
    private let profileService = ProfileService()

    // =========================================================================
    // MARK: - Profile Sync (After Onboarding)
    // =========================================================================

    /// Pushes the user's profile data to Supabase after it's been saved locally.
    ///
    /// WHEN TO CALL:
    /// At the end of onboarding, AFTER you've saved the UserProfile to SwiftData.
    ///
    /// WHAT HAPPENS:
    /// 1. Sets `isSyncing = true` (UI can show a loading state)
    /// 2. Calls ProfileService to create/fetch the remote profile
    /// 3. On success: prints confirmation, clears any previous error
    /// 4. On failure: stores error message, flags sync as pending in UserDefaults
    /// 5. Sets `isSyncing = false`
    ///
    /// FAILURE HANDLING:
    /// If the push fails (no internet, Supabase down, etc.), we set a flag in
    /// UserDefaults: "pendingProfileSync" = true. On next app launch,
    /// `retryPendingSyncs()` will pick this up and try again.
    ///
    /// - Parameter authId: Authenticated user's UUID from AuthService
    @discardableResult
    func syncProfileToSupabase(authId: UUID) async throws -> UUID {
        isSyncing = true
        lastSyncError = nil
        defer { isSyncing = false }

        do {
            let profile = try await profileService.fetchOrCreateProfile(authId: authId)
            guard let profileId = profile.id else {
                throw SyncError.profileMissingId
            }
            UserDefaults.standard.set(profileId.uuidString, forKey: "supabaseProfileId")
            #if DEBUG
            print("✅ Profile synced to Supabase")
            #endif
            return profileId
        } catch {
            lastSyncError = error.localizedDescription
            UserDefaults.standard.set(true, forKey: "pendingProfileSync")
            #if DEBUG
            print("❌ Profile sync failed: \(error.localizedDescription)")
            #endif
            throw error
        }
    }

    // MARK: - Sync Errors

    enum SyncError: LocalizedError {
        case profileMissingId
        case profileNotFound
        case onboardingNotComplete

        var errorDescription: String? {
            switch self {
            case .profileMissingId:
                return "Profile was created but returned no ID. Cannot proceed."
            case .profileNotFound:
                return "No confirmed profile found. Please complete onboarding first."
            case .onboardingNotComplete:
                return "Onboarding has not been completed. Cannot sync data."
            }
        }
    }

    // =========================================================================
    // MARK: - Complete Onboarding (Local + Remote)
    // =========================================================================

    /// Marks onboarding as complete in BOTH SwiftData and Supabase.
    ///
    /// FLOW:
    /// 1. Set `hasCompletedOnboarding = true` on the local SwiftData model (instant)
    /// 2. Save the SwiftData context (persists to disk)
    /// 3. Push the same flag to Supabase (async, might fail)
    /// 4. If Supabase push fails → flag for retry
    ///
    /// WHY LOCAL FIRST?
    /// Because the app checks `hasCompletedOnboarding` on every launch to decide
    /// whether to show onboarding or the home screen. If we waited for Supabase,
    /// the user could be stuck in onboarding if they're offline.
    ///
    /// - Parameters:
    ///   - profileId: Supabase profile UUID
    ///   - localProfile: The SwiftData UserProfile model instance
    ///   - modelContext: The SwiftData ModelContext (needed to call .save())
    func completeOnboarding(
        localProfile: UserProfile,
        modelContext: ModelContext
    ) async throws {
        guard let profileIdString = UserDefaults.standard.string(forKey: "supabaseProfileId"),
              let profileId = UUID(uuidString: profileIdString) else {
            throw SyncError.profileMissingId
        }
        localProfile.hasCompletedOnboarding = true
        try? modelContext.save()
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        do {
            try await profileService.markOnboardingComplete(profileId: profileId)
            #if DEBUG
            print("✅ Onboarding flag synced to Supabase")
            #endif
        } catch {
            #if DEBUG
            print("❌ Onboarding sync failed — will retry: \(error)")
            #endif
            UserDefaults.standard.set(true, forKey: "pendingOnboardingSync")
        }
    }

    // =========================================================================
    // MARK: - Retry Pending Syncs
    // =========================================================================

    /// Checks for any failed syncs from previous sessions and retries them.
    ///
    /// WHEN TO CALL:
    /// In your app's root view (e.g., `ContentView` or `Open_LightlyApp.swift`),
    /// inside a `.task { }` modifier that runs on app launch:
    ///
    /// ```swift
    /// .task {
    ///     if let userId = authService.userId, let profile = localProfile {
    ///         await SyncManager.shared.retryPendingSyncs(
    ///             userId: userId,
    ///             localProfile: profile
    ///         )
    ///     }
    /// }
    /// ```
    ///
    /// HOW IT WORKS:
    /// 1. Checks UserDefaults for "pendingProfileSync" flag
    /// 2. If true → re-attempts the profile sync using local SwiftData data
    /// 3. If the retry succeeds → clears the flag
    /// 4. If it fails again → flag stays set, will retry next launch
    /// 5. Same pattern for "pendingOnboardingSync"
    ///
    /// - Parameters:
    ///   - userId: Authenticated user's UUID
    ///   - localProfile: The local SwiftData UserProfile (has the data to push)
    func retryPendingSyncs(userId: UUID, localProfile: UserProfile?) async {
        if UserDefaults.standard.bool(forKey: "pendingProfileSync"),
           localProfile != nil {
            do {
                try await syncProfileToSupabase(authId: userId)
                if lastSyncError == nil {
                    UserDefaults.standard.set(false, forKey: "pendingProfileSync")
                    #if DEBUG
                    print("✅ Pending profile sync completed on retry")
                    #endif
                }
            } catch {
                #if DEBUG
                print("❌ Pending profile sync retry failed: \(error)")
                #endif
            }
        }
        if UserDefaults.standard.bool(forKey: "pendingOnboardingSync"),
           let profileIdString = UserDefaults.standard.string(forKey: "supabaseProfileId"),
           let profileId = UUID(uuidString: profileIdString) {
            do {
                try await profileService.markOnboardingComplete(profileId: profileId)
                UserDefaults.standard.set(false, forKey: "pendingOnboardingSync")
                #if DEBUG
                print("✅ Pending onboarding sync completed on retry")
                #endif
            } catch {
                #if DEBUG
                print("⚠️ Retry failed for onboarding sync — will try again next launch")
                #endif
            }
        }
    }
}

```

---

## File: `Open Lightly/Core/Services/AssessmentSyncService.swift` {#file-open-lightly-core-services-assessmentsyncservice-swift}

```swift
//
//  SupabaseAssessmentResponse.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/10/26.
//


//
//  AssessmentSyncService.swift
//  Open Lightly
//
//  Created in Batch 10 — Assessment Data Sync
//
//  PURPOSE:
//  Pushes assessment data from SwiftData to Supabase after the user
//  completes the individual assessment. Two tables get written:
//
//    1. `assessment_responses` — one row per question answered
//       (maps from local AssessmentResponse model)
//
//    2. `assessment_results` — one row per completed assessment
//       (maps from local AssessmentResult model)
//
//  HOW IT FITS:
//  The user takes the assessment → answers are saved to SwiftData as
//  AssessmentResponse objects → when they finish, an AssessmentResult
//  is computed and saved locally → THEN this service pushes both
//  the individual responses and the final result to Supabase.
//
//  SAME PATTERN AS EVERYTHING ELSE:
//  1. SwiftData saves first (instant, offline-capable)
//  2. This service pushes to Supabase (async, might fail)
//  3. If push fails → flag for retry on next app launch
//
//  WHO CALLS THIS:
//  SyncManager calls these methods. Views should NOT call this directly.
//

import Foundation
import Supabase
import Combine

// MARK: - Supabase DTOs

/// Maps one assessment answer to the `assessment_responses` table in Supabase.
/// This is a plain Codable struct — NOT a SwiftData model.
/// It mirrors the local AssessmentResponse but with snake_case column names.
struct SupabaseAssessmentResponse: Codable {

    /// Auto-generated UUID for this row (matches local AssessmentResponse.id)
    let id: UUID

    /// The user's auth UUID — links this response to a user.
    /// Column: auth_id (foreign key to user_profiles.auth_id)
    let authId: UUID

    /// Which question this answers (e.g. "Q1", "Q2").
    /// Matches ContentAssessmentQuestion.id from your content JSON.
    let questionId: String

    /// Which assessment domain this question belongs to
    /// (e.g. "communication", "trust", "emotionalSecurity").
    /// Stored as the raw string value of your AssessmentDomain enum.
    let domain: String

    /// For scale questions (1–5): the numeric value the user chose.
    /// Nil for multi-select questions.
    let scaleValue: Int?

    /// For multi-select questions: the option IDs the user picked
    /// (e.g. ["a", "c"]). Empty array for scale questions.
    let selectedOptionIds: [String]

    /// Points awarded for this answer, computed by your scoring logic.
    let score: Double

    /// When the user answered this question.
    let answeredAt: String  // ISO 8601 string for Postgres timestamptz

    /// Maps Swift camelCase → Postgres snake_case column names.
    enum CodingKeys: String, CodingKey {
        case id
        case authId = "auth_id"
        case questionId = "question_id"
        case domain
        case scaleValue = "scale_value"
        case selectedOptionIds = "selected_option_ids"
        case score
        case answeredAt = "answered_at"
    }
}

/// Maps the overall assessment outcome to the `assessment_results` table.
/// One row per user per completed assessment.
struct SupabaseAssessmentResult: Codable {

    /// Auto-generated UUID (matches local AssessmentResult.id)
    let id: UUID

    /// The user's auth UUID
    let authId: UUID

    /// Per-domain scores as a JSON object.
    /// Keys are domain raw values (e.g. "communication": 75.0).
    /// Postgres stores this as JSONB.
    let domainScores: [String: Double]

    /// The weighted overall score (0–100).
    let compositeScore: Double

    /// The readiness band derived from compositeScore
    /// (e.g. "ready", "notReady", "almostReady").
    /// Stored as the raw string value of your ReadinessLevel enum.
    let readinessLevel: String

    /// When the assessment was completed.
    let completedAt: String  // ISO 8601 string

    /// Maps Swift camelCase → Postgres snake_case column names.
    enum CodingKeys: String, CodingKey {
        case id
        case authId = "auth_id"
        case domainScores = "domain_scores"
        case compositeScore = "composite_score"
        case readinessLevel = "readiness_level"
        case completedAt = "completed_at"
    }
}

// MARK: - Service

@MainActor
class AssessmentSyncService: ObservableObject {

    /// Shared singleton — access with AssessmentSyncService.shared
    static let shared = AssessmentSyncService()

    /// Reference to the Supabase client for making API calls.
    private var supabase: SupabaseClient {
        SupabaseManager.shared.client
    }

    /// ISO 8601 formatter — converts Swift Dates to strings that
    /// Postgres understands (e.g. "2026-03-11T00:23:01Z").
    private let isoFormatter = ISO8601DateFormatter()

    private let profileService = ProfileService()

    // MARK: - Sync Responses

    /// Pushes all assessment responses for a user to Supabase.
    ///
    /// WHEN TO CALL:
    /// After the user completes the assessment and all AssessmentResponse
    /// objects have been saved to SwiftData.
    ///
    /// WHAT IT DOES:
    /// 1. Converts each local AssessmentResponse into a SupabaseAssessmentResponse
    /// 2. Sends them all to Supabase in one batch INSERT
    ///
    /// WHY BATCH INSERT?
    /// An assessment might have 20–30 questions. Sending one HTTP request
    /// per question would be slow. Supabase supports array inserts, so we
    /// send all responses in a single request.
    ///
    /// - Parameters:
    ///   - responses: Array of local SwiftData AssessmentResponse objects
    ///   - authId: The authenticated user's UUID
    func syncResponses(_ responses: [AssessmentResponse], authId: UUID) async throws {

        // Convert each local SwiftData model into a Supabase-compatible struct.
        // This is where we translate between the two worlds:
        //   - AssessmentResponse (SwiftData, uses enums, has relationships)
        //   - SupabaseAssessmentResponse (plain Codable, uses strings, flat)
        let supabaseResponses = responses.map { response in
            SupabaseAssessmentResponse(
                id: response.id,
                authId: authId,
                questionId: response.questionID,
                domain: response.domain.rawValue,         // Enum → String
                scaleValue: response.scaleValue,
                selectedOptionIds: response.selectedOptionIDs,
                score: response.score,
                answeredAt: isoFormatter.string(from: response.answeredAt)  // Date → String
            )
        }

        // Batch insert all responses in one HTTP request.
        // If some responses already exist (e.g., retry after partial failure),
        // Supabase will throw a conflict error. In production you might want
        // to use .upsert() instead of .insert() to handle this gracefully.
        try await supabase
            .from("assessment_responses")
            .insert(supabaseResponses)
            .execute()

        #if DEBUG
        print("✅ \(supabaseResponses.count) assessment responses synced to Supabase")
        #endif
    }

    // MARK: - Sync Result

    /// Pushes the final assessment result (scores + readiness level) to Supabase.
    ///
    /// WHEN TO CALL:
    /// After the assessment is scored and the AssessmentResult has been
    /// saved to SwiftData.
    ///
    /// - Parameters:
    ///   - result: The local SwiftData AssessmentResult object
    ///   - authId: The authenticated user's UUID
    func syncResult(_ result: AssessmentResult, authId: UUID) async throws {

        // Convert the local model to a Supabase-compatible struct.
        let supabaseResult = SupabaseAssessmentResult(
            id: result.id,
            authId: authId,
            domainScores: result.domainScores,                         // Already [String: Double]
            compositeScore: result.compositeScore,
            readinessLevel: result.readinessLevel.rawValue,            // Enum → String
            completedAt: isoFormatter.string(from: result.completedAt) // Date → String
        )

        // Insert the result. Using .single() because we expect exactly
        // one row to be created.
        try await supabase
            .from("assessment_results")
            .insert(supabaseResult)
            .execute()

        #if DEBUG
        print("✅ Assessment result synced to Supabase (score: \(result.compositeScore))")
        #endif
    }

    // MARK: - Sync Both (Convenience)

    /// Syncs both responses AND the result in one call.
    ///
    /// This is the method SyncManager should call. It handles both
    /// tables and provides a single success/failure point.
    ///
    /// - Parameters:
    ///   - responses: All AssessmentResponse objects from SwiftData
    ///   - result: The computed AssessmentResult from SwiftData
    ///   - authId: The authenticated user's UUID
    func syncAssessment(
        responses: [AssessmentResponse],
        result: AssessmentResult,
        authId: UUID
    ) async throws {
        _ = try await profileService.ensureProfileExists(authId: authId)
        try await syncResponses(responses, authId: authId)
        try await syncResult(result, authId: authId)

        #if DEBUG
        print("✅ Full assessment synced to Supabase")
        #endif
    }
}

```

---

## File: `Open Lightly/Core/Services/DesireSyncService.swift` {#file-open-lightly-core-services-desiresyncservice-swift}

```swift
//
//  SupabaseDesireRating.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/10/26.
//


//
//  DesireSyncService.swift
//  Open Lightly
//
//  Created in Batch 10 — Desire Ratings Sync
//
//  PURPOSE:
//  Pushes desire map ratings from SwiftData to Supabase after the user
//  completes the desire map during onboarding (or updates ratings later).
//
//  TABLE: `desire_ratings`
//  Each row = one user's private rating for one desire item.
//
//  PRIVACY NOTE:
//  Desire ratings are PRIVATE — they are never shown to the partner directly.
//  They're only used server-side to compute DesireMatch results (overlapping
//  interests between two paired users). The raw ratings stay private.
//
//  SAME PATTERN:
//  1. SwiftData saves first (instant, offline-capable)
//  2. This service pushes to Supabase (async, might fail)
//  3. If push fails → SyncManager flags for retry
//

import Foundation
import Supabase
import Combine

// MARK: - Supabase DTO

/// Maps one desire rating to the `desire_ratings` table in Supabase.
/// Plain Codable struct — NOT a SwiftData model.
struct SupabaseDesireRating: Codable {
    let id: UUID
    let userId: UUID
    let desireItemId: String
    let rating: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case desireItemId = "desire_item_id"
        case rating
        case createdAt = "created_at"
    }
}

// MARK: - SupabaseDesireMatch DTO
struct SupabaseDesireMatch: Codable {
    let id: UUID
    let coupleId: UUID
    let desireItemId: String
    let alignmentLevel: String
    let partnerAValue: String?
    let partnerBValue: String?
    let gapSize: Int?
    let bridgeCardId: String?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case coupleId = "couple_id"
        case desireItemId = "desire_item_id"
        case alignmentLevel = "alignment_level"
        case partnerAValue = "partner_a_value"
        case partnerBValue = "partner_b_value"
        case gapSize = "gap_size"
        case bridgeCardId = "bridge_card_id"
        case createdAt = "created_at"
    }
}

// MARK: - Service

@MainActor
class DesireSyncService: ObservableObject {

    /// Shared singleton — access with DesireSyncService.shared
    static let shared = DesireSyncService()

    /// Reference to the Supabase client.
    private var supabase: SupabaseClient {
        SupabaseManager.shared.client
    }

    /// ISO 8601 formatter for converting Dates to Postgres-friendly strings.
    private let isoFormatter = ISO8601DateFormatter()

    private let profileService = ProfileService()

    // MARK: - Sync All Ratings

    /// Pushes all desire ratings for a user to Supabase in one batch.
    ///
    /// WHEN TO CALL:
    /// After the user completes the desire map during onboarding
    /// and all DesireRating objects have been saved to SwiftData.
    ///
    /// WHAT IT DOES:
    /// 1. Converts each local DesireRating into a SupabaseDesireRating
    /// 2. Sends them all to Supabase in one batch INSERT
    ///
    /// WHY BATCH INSERT?
    /// The desire map might have 30–50+ items. One HTTP request per rating
    /// would be painfully slow. Batch insert sends them all at once.
    ///
    /// - Parameters:
    ///   - ratings: Array of local SwiftData DesireRating objects
    ///   - authId: The authenticated user's UUID
    func syncRatings(_ ratings: [DesireRating], authId: UUID) async throws {
        _ = try await profileService.ensureProfileExists(authId: authId)

        // Convert local SwiftData models → Supabase Codable structs
        let supabaseRatings = ratings.map { rating in
            SupabaseDesireRating(
                id: rating.id,
                userId: authId,
                desireItemId: rating.desireItemId,
                rating: String(rating.rating.rawValue),                      // Rating enum → String
                createdAt: isoFormatter.string(from: rating.ratedAt)   // Date → String
            )
        }

        // Batch insert all ratings in one request
        try await supabase
            .from("desire_ratings")
            .insert(supabaseRatings)
            .execute()

        #if DEBUG
        print("✅ \(supabaseRatings.count) desire ratings synced to Supabase")
        #endif
    }
}

```

---

## File: `Open Lightly/Core/Services/SessionSyncService.swift` {#file-open-lightly-core-services-sessionsyncservice-swift}

```swift
//
//  SupabaseCoupleSessionRecord.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/10/26.
//


//
//  SessionSyncService.swift
//  Open Lightly
//
//  Created in Batch 10 — Session Recording Sync
//
//  PURPOSE:
//  Pushes completed session records from SwiftData to Supabase
//  after each couple session ends (or is paused/resumed).
//
//  TABLE: `couple_session_records`
//  Each row = one session between a couple, tracking which cards
//  were discussed, which were skipped, timing, and metadata.
//
//  WHEN DOES A SESSION GET SYNCED?
//  - When the session status changes to .completed
//  - When the session is paused (partial sync for resume on other device)
//  - When safe word is used (session ends immediately)
//
//  NOTE ABOUT COUPLE ID:
//  Sessions are owned by a Couple, not a User. The coupleId comes
//  from the local Couple model (which was created during pairing
//  in Batch 9). If the user is in Solo mode, sessions are tracked
//  locally only and NOT synced to Supabase.
//
//  SAME PATTERN:
//  1. SwiftData saves the session locally (instant)
//  2. This service pushes to Supabase (async, might fail)
//  3. If push fails → SyncManager flags for retry
//

import Foundation
import Supabase
import Combine

// MARK: - Supabase DTO

/// Maps one session record to the `couple_session_records` table in Supabase.
/// Plain Codable struct — NOT a SwiftData model.
struct SupabaseCoupleSessionRecord: Codable {

    /// Auto-generated UUID (matches local CoupleSessionRecord.id)
    let id: UUID

    /// The couple's UUID — links this session to a specific couple.
    /// Foreign key to couples.id in Supabase.
    let coupleId: UUID

    /// Which content category this session covered (e.g. "communication").
    let categoryId: String

    /// The lifecycle state: "notStarted", "inProgress", "paused", "completed".
    /// Stored as the raw string value of your SessionStatus enum.
    let status: String

    /// Ordered list of card IDs that were discussed during this session.
    /// Stored as a Postgres text[] (array) or JSONB.
    let cardIdsDiscussed: [String]

    /// Card IDs the couple chose to skip.
    let cardIdsSkipped: [String]

    /// If paused/in-progress: which card is currently being displayed.
    /// Nil if the session is completed.
    let currentCardId: String?

    /// If paused: whose turn it is ("partnerA" or "partnerB").
    /// Nil if session is completed or not yet started.
    let currentTurn: String?

    /// Whether the safe word was invoked during this session.
    /// If true, the session ended early by design.
    let safeWordUsed: Bool

    /// Total session duration in seconds.
    let durationSeconds: Int

    /// When the session was started. Nil if status is still "notStarted".
    let startedAt: String?   // ISO 8601 string

    /// When the session was completed. Nil if not yet finished.
    let completedAt: String?  // ISO 8601 string

    /// Maps Swift camelCase → Postgres snake_case column names.
    enum CodingKeys: String, CodingKey {
        case id
        case coupleId = "couple_id"
        case categoryId = "category_id"
        case status
        case cardIdsDiscussed = "card_ids_discussed"
        case cardIdsSkipped = "card_ids_skipped"
        case currentCardId = "current_card_id"
        case currentTurn = "current_turn"
        case safeWordUsed = "safe_word_used"
        case durationSeconds = "duration_seconds"
        case startedAt = "started_at"
        case completedAt = "completed_at"
    }
}

// MARK: - Service

@MainActor
class SessionSyncService: ObservableObject {

    /// Shared singleton — access with SessionSyncService.shared
    static let shared = SessionSyncService()

    /// Reference to the Supabase client.
    private var supabase: SupabaseClient {
        SupabaseManager.shared.client
    }

    /// ISO 8601 formatter for Date → String conversion.
    private let isoFormatter = ISO8601DateFormatter()

    // MARK: - Helper: Convert Optional Date

    /// Safely converts an optional Date to an optional ISO 8601 string.
    /// Returns nil if the input date is nil (Supabase stores as NULL).
    private func isoString(from date: Date?) -> String? {
        guard let date = date else { return nil }
        return isoFormatter.string(from: date)
    }
}

```

---

## File: `Open Lightly/Data/Store/DataStore.swift` {#file-open-lightly-data-store-datastore-swift}

```swift
import Foundation
import SwiftData

// MARK: - DataStore
// Central persistence layer for Open Lightly.
// Every read/write to SwiftData goes through here.
// Instantiated with a ModelContext from the environment.
//
// Usage:
//   let store = DataStore(context: modelContext)
//   store.saveSession(...)

final class DataStore {

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Sessions

    /// Saves a completed session along with its individual prompt ratings.
    /// Also updates the streak record.
    ///
    /// - Parameters:
    ///   - category: Raw string of the session's primary category
    ///   - difficulty: Raw string of the session's difficulty level
    ///   - promptsShown: Array of prompt text strings shown during the session
    ///   - durationSeconds: Total session length in seconds
    ///   - reactions: Array of tuples — each has the prompt text, category, and reaction string
    ///   - partnerName: Optional partner display name (nil for solo)
    ///   - completedFully: false if the user safe-worded out early
    func saveSession(
        category: String,
        difficulty: String,
        promptsShown: [String],
        durationSeconds: Int,
        reactions: [(promptText: String, category: String, reaction: String)],
        partnerName: String?,
        completedFully: Bool
    ) {
        // 1. Create the parent session record
        let session = SessionRecord(
            category: category,
            difficulty: difficulty,
            promptsShown: promptsShown,
            durationSeconds: durationSeconds,
            partnerName: partnerName,
            completedFully: completedFully
        )
        context.insert(session)

        // 2. Create a RatingRecord for each reaction, linked to the session
        for reaction in reactions {
            let rating = RatingRecord(
                promptText: reaction.promptText,
                category: reaction.category,
                reaction: reaction.reaction,
                session: session
            )
            context.insert(rating)
        }

        // 3. Update the streak
        let streak = fetchOrCreateStreak()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let lastActive = calendar.startOfDay(for: streak.lastActiveDate)

        if lastActive == today {
            // Already logged today — just bump counts
        } else if calendar.isDate(lastActive, equalTo: today - 86400, toGranularity: .day) {
            // Consecutive day — extend streak
            streak.currentStreak += 1
        } else {
            // Gap — reset streak
            streak.currentStreak = 1
        }

        if streak.currentStreak > streak.longestStreak {
            streak.longestStreak = streak.currentStreak
        }

        streak.lastActiveDate = .now
        streak.totalSessions += 1
        streak.totalPromptsRated += reactions.count

        try? context.save()
    }

    /// Fetches all sessions, newest first.
    func fetchAllSessions() -> [SessionRecord] {
        let descriptor = FetchDescriptor<SessionRecord>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Fetches sessions for a specific category.
    func fetchSessions(forCategory category: String) -> [SessionRecord] {
        let descriptor = FetchDescriptor<SessionRecord>(
            predicate: #Predicate { $0.category == category },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    // MARK: - Ratings

    /// Fetches all ratings with a specific reaction (e.g. "liked", "disliked", "skipped").
    func fetchRatings(byReaction reaction: String) -> [RatingRecord] {
        let descriptor = FetchDescriptor<RatingRecord>(
            predicate: #Predicate { $0.reaction == reaction }
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Fetches all ratings for a specific category.
    func fetchRatings(forCategory category: String) -> [RatingRecord] {
        let descriptor = FetchDescriptor<RatingRecord>(
            predicate: #Predicate { $0.category == category }
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    // MARK: - Desire Map Ratings

    /// Fetches a single rating record by prompt ID (used for desire map items).
    /// Returns nil if no rating exists yet for this prompt.
    func fetchRating(forPromptId promptId: String) -> RatingRecord? {
        let descriptor = FetchDescriptor<RatingRecord>(
            predicate: #Predicate { $0.promptText == promptId }
        )
        return try? context.fetch(descriptor).first
    }

    /// Saves or updates a desire map rating.
    /// Desire ratings are stored as RatingRecords with no parent session.
    func saveDesireRating(itemId: String, category: String, level: DesireLevel) {
        if let existing = fetchRating(forPromptId: itemId) {
            existing.reaction = String(level.rawValue)
        } else {
            let record = RatingRecord(
                promptText: itemId,
                category: category,
                reaction: String(level.rawValue),
                session: nil
            )
            context.insert(record)
        }
        try? context.save()
    }

    // MARK: - Streak

    /// Fetches the single streak record, or creates one if none exists.
    /// There should only ever be one StreakRecord in the store.
    func fetchOrCreateStreak() -> StreakRecord {
        let descriptor = FetchDescriptor<StreakRecord>()
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let streak = StreakRecord()
        context.insert(streak)
        try? context.save()
        return streak
    }

    // MARK: - User Profile

    /// Fetches the current user's profile, or creates a default one.
    /// There should only ever be one UserProfile on device.
    func fetchOrCreateProfile() -> UserProfile {
        let descriptor = FetchDescriptor<UserProfile>()
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let profile = UserProfile()
        context.insert(profile)
        try? context.save()
        return profile
    }

    /// Saves any pending changes to the user profile.
    func saveProfile() {
        try? context.save()
    }

    // MARK: - Danger Zone

    /// Deletes a single session and its child ratings (cascade).
    func deleteSession(_ session: SessionRecord) {
        context.delete(session)
        try? context.save()
    }

    /// Nukes everything. Used for "Start Over" in Settings.
    /// Deletes all sessions, ratings, streak, and user profile.
    func deleteAllData() {
        // Sessions (ratings cascade automatically)
        let sessions = fetchAllSessions()
        for session in sessions {
            context.delete(session)
        }

        // Streak
        let streakDescriptor = FetchDescriptor<StreakRecord>()
        if let streaks = try? context.fetch(streakDescriptor) {
            for streak in streaks {
                context.delete(streak)
            }
        }

        // User Profile
        let profileDescriptor = FetchDescriptor<UserProfile>()
        if let profiles = try? context.fetch(profileDescriptor) {
            for profile in profiles {
                context.delete(profile)
            }
        }

        try? context.save()
    }
}

```

---

## File: `Open Lightly/Data/Store/ModelContainer.swift` {#file-open-lightly-data-store-modelcontainer-swift}

```swift
import Foundation
import SwiftData

// MARK: - ModelContainer+App
// Configures the shared SwiftData ModelContainer with all schemas.
// This is the single place where we register every @Model class.
// Called once from OpenLightlyApp.swift to inject into the SwiftUI scene.

extension ModelContainer {

    /// Creates the app-wide ModelContainer with all models registered.
    /// - Returns: A configured ModelContainer ready to inject via .modelContainer()
    ///
    /// Usage in OpenLightlyApp.swift:
    /// ```
    /// .modelContainer(ModelContainer.appContainer)
    /// ```
    ///
    /// If the container fails to create (corrupted DB, schema mismatch),
    /// this will crash with a fatalError — intentional so we catch it immediately.
    static var appContainer: ModelContainer {
        do {
            let schema = Schema([
                SessionRecord.self,
                RatingRecord.self,
                StreakRecord.self,
                UserProfile.self,
                DesireRating.self,
                Couple.self,
                DesireMatch.self,
                CardProgress.self,
                CoupleSessionRecord.self,
                AssessmentResponse.self,
                AssessmentResult.self
            ])

            let config = ModelConfiguration(
                "OpenLightly",
                schema: schema,
                isStoredInMemoryOnly: false
            )

            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("❌ Failed to create ModelContainer: \(error.localizedDescription)")
        }
    }

    /// In-memory container for SwiftUI previews and unit tests.
    /// Same schema, but nothing hits disk.
    static var previewContainer: ModelContainer {
        do {
            let schema = Schema([
                SessionRecord.self,
                RatingRecord.self,
                StreakRecord.self,
                UserProfile.self,
                DesireRating.self,
                Couple.self,
                DesireMatch.self,
                CardProgress.self,
                CoupleSessionRecord.self,
                AssessmentResponse.self,
                AssessmentResult.self
            ])

            let config = ModelConfiguration(
                "OpenLightlyPreview",
                schema: schema,
                isStoredInMemoryOnly: true
            )

            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("❌ Failed to create preview ModelContainer: \(error.localizedDescription)")
        }
    }
}

```

---

## File: `Open Lightly/Models/Content/ContentAssessmentQuestion.swift` {#file-open-lightly-models-content-contentassessmentquestion-swift}

```swift
//
//  AssessmentQuestion.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import Foundation

// ============================================================
// AssessmentQuestion.swift
// A read-only content model representing one of the 20
// individual assessment questions.
//
// The assessment has 5 domains with 4 questions each.
// Question types are either scale (5-point Likert) or
// multi-select (pick all that apply).
//
// This struct is decoded from JSON bundled in the app.
// It is never modified at runtime.
//
// The user's ANSWERS are stored in SwiftData (AssessmentResponse),
// not here. This struct only describes the question itself.
//
// See PROJECT_SCOPE.md Section 8.1 for assessment design.
// See PROJECT_SCOPE.md Section 10 for scoring logic.
// See AppEnums.swift for AssessmentDomain, AssessmentQuestionType.
// ============================================================

// MARK: - QuestionOption
// A single selectable option within a multi-select question.
// Each option has a point value used in scoring.

struct ContentQuestionOption: Identifiable, Codable {
    let id: String    // option identifier within the question (e.g. "a")
    let text: String  // the option text shown to the user
    let points: Int   // point value awarded when this option is selected

    static let example = ContentQuestionOption(id: "a", text: "Listen and try to understand", points: 5)
}


// MARK: - AssessmentQuestion

struct ContentAssessmentQuestion: Identifiable, Codable {

    // MARK: - Properties

    // Question identifier (e.g. "Q1", "Q2", ... "Q20")
    let id: String

    // Which of the 5 scored domains this belongs to
    let domain: AssessmentDomain

    // The question text shown to the user
    let text: String

    // Scale or multiSelect
    let type: AssessmentQuestionType

    // Only present for multiSelect questions, nil for scale
    let options: [ContentQuestionOption]?

    // Scoring weight for this question within its domain
    let weight: Double

    // Position in the assessment (1-20)
    let sortOrder: Int

    // Optional "Why this matters" note shown below the question
    let contextNote: String?


    // MARK: - Computed Properties

    // Whether this is a 5-point Likert scale question.
    var isScale: Bool { type == .scale }

    // Whether this is a pick-all-that-apply question.
    var isMultiSelect: Bool { type == .multiSelect }

    // Convenience accessor for display
    var domainDisplayName: String { domain.displayName }


    // MARK: - Preview Helpers

    static let scaleExample = ContentAssessmentQuestion(
        id: "Q1",
        domain: .communication,
        text: "How comfortable do you feel bringing up difficult topics with your partner?",
        type: .scale,
        options: nil,
        weight: 1.0,
        sortOrder: 1,
        contextNote: "Open communication is consistently linked to successful ENM navigation."
    )

    static let multiSelectExample = ContentAssessmentQuestion(
        id: "Q10",
        domain: .communication,
        text: "When your partner shares something that hurts, what is your typical response?",
        type: .multiSelect,
        options: [
            ContentQuestionOption(id: "a", text: "Listen and try to understand", points: 5),
            ContentQuestionOption(id: "b", text: "Need time to process", points: 3),
            ContentQuestionOption(id: "c", text: "Ask clarifying questions", points: 4),
            ContentQuestionOption(id: "d", text: "Become defensive", points: 1),
            ContentQuestionOption(id: "e", text: "Shut down or withdraw", points: 1)
        ],
        weight: 1.0,
        sortOrder: 10,
        contextNote: "Conflict response patterns predict how couples handle ENM-related stress."
    )
}

```

---

## File: `Open Lightly/Models/Content/ContentCard.swift` {#file-open-lightly-models-content-contentcard-swift}

```swift
//
//  Card.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import Foundation

// ============================================================
// Card.swift
// A read-only content model representing a single conversation
// card within a category.
//
// Cards are the core content unit of the app. Each card is
// a prompt, education block, education+prompt, or cool-off
// exercise that couples work through during a session.
//
// This struct is decoded from JSON bundled in the app.
// It is never modified at runtime.
//
// Per-card progress (discussed, skipped, bookmarked) lives
// in SwiftData models (CardProgress), not here.
//
// See PROJECT_SCOPE.md Section 8.2-8.3 for card definitions.
// See AppEnums.swift for CardType, Difficulty, Sensitivity, TurnOrder.
// ============================================================

struct ContentCard: Identifiable, Codable {

    // MARK: - Properties

    // Unique card ID using category prefix + number (e.g. "RH-1", "IJ-3")
    let id: String

    // Matches CategoryType raw value (e.g. "relationshipHealth")
    let categoryID: String

    // prompt, education, educationPrompt, or coolOff
    let type: CardType

    // Optional card title (education cards may have one)
    let title: String?

    // The main text shown on the card. Always present.
    let promptText: String

    // Additional education content shown above the prompt on educationPrompt cards.
    let educationText: String?

    // Who speaks first on this card (.partnerA or .partnerB)
    let speakingTurnFirst: TurnOrder

    // Emotional intensity level
    let difficulty: Difficulty

    // Determines screenshot protection behavior
    let sensitivity: Sensitivity

    // Position within the category
    let sortOrder: Int

    // Whether this card is available in the free tier
    let isFree: Bool

    // Optional "why this matters" note shown below the prompt
    let contextNote: String?


    // MARK: - Computed Properties

    // Bridges the JSON categoryID to the type-safe enum.
    var categoryType: CategoryType? { CategoryType(rawValue: categoryID) }

    // Whether this card has an education component.
    var isEducation: Bool { type == .education || type == .educationPrompt }

    // Whether this card requires partner discussion.
    var hasPrompt: Bool { type == .prompt || type == .educationPrompt }

    // Whether the app should activate screenshot protection for this card.
    var requiresScreenshotProtection: Bool { sensitivity != .low }


    // MARK: - Preview Helpers

    static let promptExample = ContentCard(
        id: "RH-1",
        categoryID: "relationshipHealth",
        type: .prompt,
        title: nil,
        promptText: "What does our relationship look like when we're at our best?",
        educationText: nil,
        speakingTurnFirst: .partnerA,
        difficulty: .easy,
        sensitivity: .low,
        sortOrder: 1,
        isFree: true,
        contextNote: "Starting with strengths builds a foundation for harder conversations."
    )

    static let educationPromptExample = ContentCard(
        id: "IJ-2",
        categoryID: "insecurities",
        type: .educationPrompt,
        title: "Understanding Jealousy",
        promptText: "When was the last time you felt jealous? What was underneath it?",
        educationText: "Jealousy is not a single emotion — it's a cluster of feelings including fear, anger, and sadness. Identifying the root feeling helps you communicate what you actually need.",
        speakingTurnFirst: .partnerB,
        difficulty: .medium,
        sensitivity: .medium,
        sortOrder: 2,
        isFree: false,
        contextNote: nil
    )
}

```

---

## File: `Open Lightly/Models/Content/ContentCategory.swift` {#file-open-lightly-models-content-contentcategory-swift}

```swift
//
//  Category.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import Foundation

// ============================================================
// Category.swift
// A read-only content model representing one of the 6 topic
// categories that conversation cards are grouped into.
//
// This struct is decoded from JSON bundled in the app.
// It is never modified at runtime — it describes the structure
// of the content, not the user's progress through it.
//
// Progress tracking (how many cards completed, unlock state)
// lives in SwiftData models, not here.
//
// See PROJECT_SCOPE.md Section 8.2 for category definitions.
// See AppEnums.swift for CategoryType and CategoryPhase.
// ============================================================

struct ContentCategory: Identifiable, Codable {

    // MARK: - Properties

    // Unique identifier — matches CategoryType rawValue (e.g. "relationshipHealth")
    let id: String

    // Human-readable name shown in the UI
    let name: String

    // SF Symbol name used for the category icon
    let icon: String

    // Short description shown on the category selection screen
    let description: String

    // Which therapeutic phase this category belongs to
    let phase: CategoryPhase

    // Total number of cards in this category (content only)
    let cardCount: Int

    // Position in the recommended order (1-6)
    let sortOrder: Int

    // Whether this category requires prerequisites to unlock
    let requiresUnlock: Bool

    // Human-readable unlock description (e.g. "Complete 2 categories")
    let unlockRequirement: String?


    // MARK: - Computed Properties

    // Bridges the JSON id string to the type-safe CategoryType enum.
    var categoryType: CategoryType? {
        CategoryType(rawValue: id)
    }

    // Convenience alias. Actual unlock evaluation happens in the progress layer, not here.
    var isLocked: Bool { requiresUnlock }


    // MARK: - Preview Helpers

    static let example = ContentCategory(
        id: "relationshipHealth",
        name: "Relationship Health",
        icon: "heart.fill",
        description: "Communication, conflict resolution, and emotional intimacy",
        phase: .foundation,
        cardCount: 8,
        sortOrder: 1,
        requiresUnlock: false,
        unlockRequirement: nil
    )
}

```

---

## File: `Open Lightly/Models/Content/ContentDesireItem.swift` {#file-open-lightly-models-content-contentdesireitem-swift}

```swift
//
//  DesireItem.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import Foundation

// ============================================================
// DesireItem.swift
// A read-only content model representing one item on the
// Desire Map — a private rating exercise where each partner
// independently rates desires, boundaries, and relationship dynamics.
//
// This struct is decoded from JSON bundled in the app.
// It is never modified at runtime.
//
// PRIVACY RULE (critical):
// "Not For Me" ratings (DesireLevel.notForMe) are NEVER revealed
// to the partner. The alignment engine returns .boundary for any
// combination involving a notForMe — the UI treats .boundary as
// "not shown in detail". Only a count of boundaries is displayed.
// This mirrors informed consent practice: a partner's firm
// boundary is theirs alone.
// ============================================================

struct ContentDesireItem: Identifiable, Codable {

    // MARK: - Properties

    let id: String              // unique identifier (e.g. "desire_mfm_threesome")
    let name: String            // short display name (e.g. "MFM Threesome")
    let description: String     // 1-2 sentence explanation shown during rating
    let category: String        // "nm_structures", "sexual", "dynamics"
    let subcategory: String?    // e.g. "swinging", "polyamory", "emotional"
    let layer: String           // "core", "discovery", "deep_dive"
    let sortOrder: Int          // position within the desire map
    let isFree: Bool            // whether this item is available in the free tier
    let sensitivityLevel: Int   // 1-3: how much primer framing is needed

    // MARK: - Alignment Logic

    /// Computes alignment between two partners' desire levels.
    /// .boundary items are NEVER shown to partners in detail.
    static func computeAlignment(
        partnerA: DesireLevel,
        partnerB: DesireLevel
    ) -> AlignmentLevel {

        // SACRED RULE: Either partner = notForMe → boundary
        if partnerA == .notForMe || partnerB == .notForMe {
            return .boundary
        }

        let gap = abs(partnerA.rawValue - partnerB.rawValue)
        let minimum = min(partnerA.rawValue, partnerB.rawValue)

        // Both low (probablyNot) → mutual pass
        if minimum <= 2 && gap == 0 {
            return .mutualPass
        }

        // Gap 0-1 with at least one partner openToIt or above
        if gap <= 1 && minimum >= 3 {
            if partnerA == .excitedAboutIt && partnerB == .excitedAboutIt {
                return .strongAlignment
            }
            return .aligned
        }

        // Gap 0-1 but lower ratings (2+3 or 2+2)
        if gap <= 1 {
            return .mutualPass
        }

        // Gap 2+ (max possible without notForMe: 4 vs 2 = 2)
        return .talkAboutIt
    }

    /// Returns the gap size for bridge card template selection
    static func gapSize(partnerA: DesireLevel, partnerB: DesireLevel) -> Int {
        return abs(partnerA.rawValue - partnerB.rawValue)
    }

    /// Whether this alignment needs a primer card before the bridge card
    static func needsPrimer(alignment: AlignmentLevel, sensitivityLevel: Int) -> Bool {
        switch alignment {
        case .talkAboutIt: return true
        case .aligned: return sensitivityLevel >= 3
        default: return false
        }
    }

    // MARK: - Preview Helpers

    static let example = ContentDesireItem(
        id: "desire_mfm_threesome",
        name: "MFM Threesome",
        description: "A sexual experience involving two men and one woman",
        category: "nm_structures",
        subcategory: "swinging",
        layer: "discovery",
        sortOrder: 1,
        isFree: true,
        sensitivityLevel: 2
    )
}

```

---

## File: `Open Lightly/Models/Content/Prompt.swift` {#file-open-lightly-models-content-prompt-swift}

```swift
import Foundation

// MARK: - Prompt Model
// Represents a single prompt card in Open Lightly

struct Prompt: Identifiable, Codable, Hashable {
    let id: UUID
    let text: String
    let highlightWords: [String]
    let category: PromptCategory
    let difficulty: PromptDifficulty
    let meta: String
    let isSensitive: Bool
    let canSkip: Bool
    let whoStarts: WhoStarts
    
    init(
        id: UUID = UUID(),
        text: String,
        highlightWords: [String] = [],
        category: PromptCategory = .prompt,
        difficulty: PromptDifficulty = .easy,
        meta: String = "",
        isSensitive: Bool = false,
        canSkip: Bool = true,
        whoStarts: WhoStarts = .partnerA
    ) {
        self.id = id
        self.text = text
        self.highlightWords = highlightWords
        self.category = category
        self.difficulty = difficulty
        self.meta = meta.isEmpty ? whoStarts.displayText : meta
        self.isSensitive = isSensitive
        self.canSkip = canSkip
        self.whoStarts = whoStarts
    }
    
    /// Auto-derive CardIntensity from difficulty
    var intensity: CardIntensity {
        CardIntensity.from(difficulty: difficulty.rawValue)
    }
}

// MARK: - Enums

enum PromptCategory: String, Codable, CaseIterable, Hashable {
    case prompt     = "Prompt"
    case reflect    = "Reflect"
    case deepDive   = "Deep Dive"
    case explore    = "Explore"
    case fantasy    = "Fantasy"
    case desireMap  = "Desire Map"
    case ultimate   = "Ultimate"
    
    var displayName: String { rawValue }
}

enum PromptDifficulty: String, Codable, CaseIterable, Hashable {
    case easy       = "Easy"
    case light      = "Light"
    case medium     = "Medium"
    case deep       = "Deep"
    case sensitive  = "Sensitive"
    case ultimate   = "Ultimate"
    
    var displayName: String { rawValue }
    
    /// Sort order for filtering
    var sortOrder: Int {
        switch self {
        case .easy:      return 0
        case .light:     return 1
        case .medium:    return 2
        case .deep:      return 3
        case .sensitive: return 4
        case .ultimate:  return 5
        }
    }
}

enum WhoStarts: String, Codable, CaseIterable, Hashable {
    case partnerA  = "partnerA"
    case partnerB  = "partnerB"
    case either    = "either"
    case both      = "both"
    
    var displayText: String {
        switch self {
        case .partnerA: return "Partner A starts"
        case .partnerB: return "Partner B starts"
        case .either:   return "Either partner starts"
        case .both:     return "Both share"
        }
    }
}

// MARK: - Sample Data

extension Prompt {
    static let samples: [Prompt] = [
        Prompt(
            text: "What first attracted you to the idea of opening your relationship?",
            highlightWords: ["opening your relationship"],
            category: .prompt,
            difficulty: .easy,
            whoStarts: .partnerA
        ),
        Prompt(
            text: "What does emotional safety actually feel like to you?",
            highlightWords: ["emotional safety"],
            category: .prompt,
            difficulty: .easy,
            whoStarts: .partnerA
        ),
        Prompt(
            text: "How do you handle jealousy when it shows up unexpectedly?",
            highlightWords: ["jealousy"],
            category: .reflect,
            difficulty: .medium,
            isSensitive: true,
            whoStarts: .partnerB
        ),
        Prompt(
            text: "What's one boundary you've been afraid to say out loud?",
            highlightWords: ["boundary"],
            category: .deepDive,
            difficulty: .medium,
            whoStarts: .either
        ),
        Prompt(
            text: "Have you ever been curious about role play or power exchange?",
            highlightWords: ["role play", "power exchange"],
            category: .explore,
            difficulty: .deep,
            whoStarts: .both
        ),
        Prompt(
            text: "Describe a fantasy you haven't shared — your partner shares theirs too.",
            highlightWords: ["fantasy", "theirs too"],
            category: .fantasy,
            difficulty: .deep,
            isSensitive: true,
            whoStarts: .both
        ),
        Prompt(
            text: "What would change if you both said yes to everything for one night?",
            highlightWords: ["yes", "one night"],
            category: .reflect,
            difficulty: .sensitive,
            isSensitive: true,
            whoStarts: .both
        ),
        Prompt(
            text: "If there were no fear and no judgment — what would your ideal relationship actually look like?",
            highlightWords: ["no fear", "no judgment"],
            category: .ultimate,
            difficulty: .ultimate,
            isSensitive: true,
            canSkip: false,
            whoStarts: .both
        )
    ]
}

```

---

## File: `Open Lightly/Models/Persistence/RatingRecord.swift` {#file-open-lightly-models-persistence-ratingrecord-swift}

```swift
//
//  RatingRecord.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/9/26.
//


import Foundation
import SwiftData

// MARK: - RatingRecord
// Stores the user's reaction to a single prompt within a session.
// One RatingRecord per prompt shown — so a 5-prompt session creates 5 of these.
// Owned by a SessionRecord via cascade delete (parent dies, these die too).

@Model
final class RatingRecord {

    // MARK: - Identity

    /// Unique identifier for this rating. Auto-generated on creation.
    var id: UUID

    /// Timestamp of when the user rated this prompt.
    var date: Date

    // MARK: - Prompt Info

    /// The exact prompt text the user was shown.
    /// Stored as a String so we can display it in history/progress screens.
    var promptText: String

    /// The category this prompt belongs to (e.g. "Sensation", "Power").
    /// Raw string — convert back to your enum at read time.
    var category: String

    // MARK: - User Reaction

    /// What the user did with this prompt.
    /// "liked" = thumbs up / heart
    /// "disliked" = thumbs down
    /// "skipped" = swiped past without rating
    /// Stored as String to keep SwiftData happy — no enum storage issues.
    var reaction: String

    // MARK: - Relationship (Inverse)

    /// The session this rating belongs to.
    /// SwiftData auto-wires this as the inverse of SessionRecord.ratings.
    /// nil only if the record is orphaned (shouldn't happen with cascade delete).
    var session: SessionRecord?

    // MARK: - Init

    /// Creates a new RatingRecord.
    /// - Parameters:
    ///   - id: Auto-generated UUID. Override only for testing/previews.
    ///   - date: Defaults to now.
    ///   - promptText: The prompt string the user saw.
    ///   - category: Raw string of the prompt's category.
    ///   - reaction: "liked", "disliked", or "skipped".
    ///   - session: The parent SessionRecord. Set automatically when appended to session.ratings.
    init(
        id: UUID = UUID(),
        date: Date = .now,
        promptText: String,
        category: String,
        reaction: String,
        session: SessionRecord? = nil
    ) {
        self.id = id
        self.date = date
        self.promptText = promptText
        self.category = category
        self.reaction = reaction
        self.session = session
    }
}
```

---

## File: `Open Lightly/Models/Persistence/SessionRecord.swift` {#file-open-lightly-models-persistence-sessionrecord-swift}

```swift
//
//  SessionRecord.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/9/26.
//


import Foundation
import SwiftData

// MARK: - SessionRecord
// Represents a single completed (or safe-worded) play session.
// One row is created each time the user finishes or exits SessionView.
// Stored via SwiftData — persists across app launches.

@Model
final class SessionRecord {

    // MARK: - Identity

    /// Unique identifier for this session. Auto-generated on creation.
    var id: UUID

    /// Timestamp of when the session was started/saved.
    var date: Date

    // MARK: - Session Metadata

    /// The category chosen for this session (e.g. "Sensation", "Power").
    /// Stored as a raw String so SwiftData doesn't choke on enums.
    /// Convert back to your enum at read time: Category(rawValue: category)
    var category: String

    /// The difficulty level selected (e.g. "warm", "hot", "blazing").
    /// Maps to PromptDifficulty.rawValue — same string-storage reason.
    var difficulty: String

    /// Ordered list of every prompt text the user was shown during this session.
    /// Stored as [String] — SwiftData handles array serialization automatically.
    var promptsShown: [String]

    /// How long the session lasted, in seconds.
    /// Captured from the timer in SessionView when the session ends.
    var durationSeconds: Int

    // MARK: - Partner (Optional — preps for Batch 9 pairing)

    /// Name of the partner, if this was a paired session.
    /// nil for solo sessions. Will be populated once Batch 9 pairing lands.
    var partnerName: String?

    // MARK: - Completion Status

    /// true = user reached the final prompt normally.
    /// false = user tapped the SafeWordButton to end early.
    var completedFully: Bool

    // MARK: - Relationships

    /// All per-prompt ratings tied to this session.
    /// Cascade delete rule: deleting a SessionRecord automatically
    /// deletes all of its child RatingRecords — no orphaned data.
    @Relationship(deleteRule: .cascade)
    var ratings: [RatingRecord] = []

    // MARK: - Init

    /// Creates a new SessionRecord with sensible defaults.
    /// - Parameters:
    ///   - id: Auto-generated UUID. Override only for testing/previews.
    ///   - date: Defaults to now. Override for mock data.
    ///   - category: Raw string of the session's category.
    ///   - difficulty: Raw string of PromptDifficulty case.
    ///   - promptsShown: Array of prompt texts shown this session.
    ///   - durationSeconds: Total session time in seconds.
    ///   - partnerName: Optional partner name (nil = solo).
    ///   - completedFully: Whether the session ended naturally.
    init(
        id: UUID = UUID(),
        date: Date = .now,
        category: String,
        difficulty: String,
        promptsShown: [String],
        durationSeconds: Int,
        partnerName: String? = nil,
        completedFully: Bool = true
    ) {
        self.id = id
        self.date = date
        self.category = category
        self.difficulty = difficulty
        self.promptsShown = promptsShown
        self.durationSeconds = durationSeconds
        self.partnerName = partnerName
        self.completedFully = completedFully
    }
}
```

---

## File: `Open Lightly/Models/Persistence/StreakRecord.swift` {#file-open-lightly-models-persistence-streakrecord-swift}

```swift
//
//  StreakRecord.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/9/26.
//


import Foundation
import SwiftData

// MARK: - StreakRecord
// Tracks the user's consecutive-day usage streaks.
// Only ONE StreakRecord should exist at any time — it gets updated, not duplicated.
// DataStore will handle the "fetch or create" logic to enforce this.

@Model
final class StreakRecord {

    // MARK: - Identity

    /// Unique identifier. Only one record exists, but SwiftData requires a stable ID.
    var id: UUID

    // MARK: - Current Streak

    /// How many consecutive days the user has completed at least one session.
    /// Resets to 1 if they miss a day, increments if they play on consecutive days.
    var currentStreak: Int

    /// The date the user last completed a session.
    /// Used to determine if today is consecutive (yesterday or today)
    /// or if the streak should reset.
    var lastActiveDate: Date

    // MARK: - Best Streak

    /// The longest streak the user has ever achieved.
    /// Only updates when currentStreak surpasses it — never decreases.
    var longestStreak: Int

    // MARK: - Stats

    /// Total number of sessions completed across all time.
    /// Incremented by 1 every time a session is saved, regardless of streaks.
    var totalSessions: Int

    /// Total number of prompts the user has rated across all sessions.
    /// Useful for milestone badges or progress displays.
    var totalPromptsRated: Int

    // MARK: - Init

    /// Creates a new StreakRecord with fresh-start defaults.
    /// - Parameters:
    ///   - id: Auto-generated UUID. Override only for testing/previews.
    ///   - currentStreak: Defaults to 0 (no sessions yet).
    ///   - lastActiveDate: Defaults to .distantPast so first session always counts.
    ///   - longestStreak: Defaults to 0.
    ///   - totalSessions: Defaults to 0.
    ///   - totalPromptsRated: Defaults to 0.
    init(
        id: UUID = UUID(),
        currentStreak: Int = 0,
        lastActiveDate: Date = .distantPast,
        longestStreak: Int = 0,
        totalSessions: Int = 0,
        totalPromptsRated: Int = 0
    ) {
        self.id = id
        self.currentStreak = currentStreak
        self.lastActiveDate = lastActiveDate
        self.longestStreak = longestStreak
        self.totalSessions = totalSessions
        self.totalPromptsRated = totalPromptsRated
    }
}
```

---

## File: `Open Lightly/Models/Progress/AssessmentResponse.swift` {#file-open-lightly-models-progress-assessmentresponse-swift}

```swift
//
//  AssessmentResponse.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import Foundation
import SwiftData

// ============================================================
// AssessmentResponse.swift
// A SwiftData model representing one answer to an individual
// assessment question.
//
// Each AssessmentResponse is owned by a UserProfile and stores
// either a scale value (1-5) or a set of selected option IDs
// for multi-select questions. The response also carries a
// computed score (points awarded) and a timestamp.
//
// This model is decoded/created at runtime as users complete
// the individual assessment. The aggregate scoring and
// readiness evaluation happen elsewhere.
// ============================================================

@Model
final class AssessmentResponse: Identifiable {

    // MARK: - Properties

    var id: UUID = UUID()

    // Matches ContentAssessmentQuestion.id (e.g. "Q1")
    var questionID: String

    // Domain this question belongs to
    var domain: AssessmentDomain

    // For scale questions (1-5)
    var scaleValue: Int? = nil

    // For multi-select questions: selected option ids (e.g. ["a","c"]) 
    var selectedOptionIDs: [String] = []

    // Computed points awarded for this answer (updated by scoring logic)
    var score: Double = 0.0

    // When the question was answered
    var answeredAt: Date = Date()

    // MARK: - Relationships

    // Owner is the UserProfile that created this response.
    // The inverse relationship (UserProfile.assessmentResponses)
    // is defined on the UserProfile model and uses cascade delete.
    @Relationship
    var owner: UserProfile?


    // MARK: - Initializer

    init(
        questionID: String,
        domain: AssessmentDomain,
        scaleValue: Int? = nil,
        selectedOptionIDs: [String] = [],
        score: Double = 0.0
    ) {
        self.id = UUID()
        self.questionID = questionID
        self.domain = domain
        self.scaleValue = scaleValue
        self.selectedOptionIDs = selectedOptionIDs
        self.score = score
        self.answeredAt = Date()
    }


    // MARK: - Preview Helpers

    // Note: using .emotionalSecurity (matches AssessmentDomain case names)
    static let example = AssessmentResponse(questionID: "Q1", domain: .emotionalSecurity, scaleValue: 4, score: 4.0)
}

```

---

## File: `Open Lightly/Models/Progress/AssessmentResult.swift` {#file-open-lightly-models-progress-assessmentresult-swift}

```swift
//
//  AssessmentResult.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import Foundation
import SwiftData

// ============================================================
// AssessmentResult.swift
// A SwiftData model representing the overall result of the
// individual assessment for one user.
//
// Stores per-domain scores (as raw string keys for persistence),
// the composite weighted score, and the resulting readiness band.
// This is owned by a UserProfile and stored per person.
//
// Note: domainScores uses string keys (AssessmentDomain.rawValue)
// because SwiftData cannot persist dictionaries keyed by enums.
// ============================================================

@Model
final class AssessmentResult: Identifiable {

    // MARK: - Properties

    var id: UUID = UUID()

    // Keys are AssessmentDomain.rawValue (e.g. "communication")
    var domainScores: [String: Double] = [:]

    // Weighted overall score (0-100)
    var compositeScore: Double = 0.0

    // Overall readiness band derived from compositeScore
    var readinessLevel: ReadinessLevel = ReadinessLevel.notReady

    // When the assessment was completed
    var completedAt: Date = Date()

    // MARK: - Relationships

    // Owner is the UserProfile that owns this result
    @Relationship
    var owner: UserProfile?


    // MARK: - Initializer

    init(
        domainScores: [String: Double] = [:],
        compositeScore: Double = 0.0,
        readinessLevel: ReadinessLevel = ReadinessLevel.notReady
    ) {
        self.id = UUID()
        self.domainScores = domainScores
        self.compositeScore = compositeScore
        self.readinessLevel = readinessLevel
        self.completedAt = Date()
    }


    // MARK: - Preview Helpers

    static let example = AssessmentResult(
        domainScores: [
            "communication": 75.0,
            "trust": 70.0,
            "emotionalSecurity": 68.0,
            "sexualOpenness": 72.0,
            "boundaryAwareness": 73.0
        ],
        compositeScore: 72.0,
        readinessLevel: .ready
    )
}

```

---

## File: `Open Lightly/Models/Progress/CardProgress.swift` {#file-open-lightly-models-progress-cardprogress-swift}

```swift
//
//  CardProgress.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import Foundation
import SwiftData

// ============================================================
// CardProgress.swift
// A SwiftData model representing a couple-level progress record
// for a single content card.
//
// Each CardProgress instance tracks whether the card was
// discussed, skipped, or bookmarked during a session, along
// with optional timestamps and notes. CardProgress objects are
// owned by a Couple and link back to the couple via the
// `couple` relationship.
//
// Forward references: Couple model owns CardProgress via a
// cascade relationship and is defined in Couple.swift.
// ============================================================

@Model
final class CardProgress: Identifiable {

    // MARK: - Properties

    var id: UUID = UUID()

    // Matches ContentCard.id (e.g. "COMM-01")
    var cardID: String

    // Category identifier for the card (e.g. "communication")
    var categoryID: String

    // Per-card state tracked for the couple
    var status: CardStatus = CardStatus.notStarted

    // Timestamps for actions
    var discussedAt: Date? = nil
    var skippedAt: Date? = nil
    var bookmarkedAt: Date? = nil

    // Optional couple notes about this card
    var notes: String? = nil


    // MARK: - Relationships

    // The Couple that owns this CardProgress record. The inverse
    // relationship is declared on Couple.cardProgress and handles
    // cascade deletion when a Couple is removed.
    @Relationship
    var couple: Couple?


    // MARK: - Initializer

    init(
        cardID: String,
        categoryID: String,
        status: CardStatus = CardStatus.notStarted,
        discussedAt: Date? = nil,
        skippedAt: Date? = nil,
        bookmarkedAt: Date? = nil,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.cardID = cardID
        self.categoryID = categoryID
        self.status = status
        self.discussedAt = discussedAt
        self.skippedAt = skippedAt
        self.bookmarkedAt = bookmarkedAt
        self.notes = notes
    }


    // MARK: - Preview Helpers

    static let example = CardProgress(cardID: "COMM-01", categoryID: "communication")
}

```

---

## File: `Open Lightly/Models/Progress/Couple.swift` {#file-open-lightly-models-progress-couple-swift}

```swift
//
//  Couple.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import Foundation
import SwiftData

@Model
final class Couple: Identifiable {

    // MARK: - Properties

    var id: UUID = UUID()
    var createdAt: Date = Date()

    // References to the two partners. No cascade — deleting
    // a Couple does NOT delete the UserProfiles.
    var partnerA: UserProfile?
    var partnerB: UserProfile?

    // MARK: - Shared Settings

    /// Safe word agreed upon by both partners.
    /// Default traffic light system: "red" / "yellow" / "green"
    /// Can be customized during onboarding or in Settings.
    var sharedSafeWord: String = "red"

    /// Whether kink map mutual matches have been revealed.
    /// Stays false until both partners complete their ratings
    /// and tap "Reveal Matches."
    var matchesRevealed: Bool = false

    // MARK: - Relationships

    @Relationship(deleteRule: .cascade)
    var cardProgress: [CardProgress] = []

    @Relationship(deleteRule: .cascade)
    var sessionRecords: [CoupleSessionRecord] = []

    @Relationship(deleteRule: .cascade)
    var desireMatches: [DesireMatch] = []

    // MARK: - Initializer

    init(
        partnerA: UserProfile? = nil,
        partnerB: UserProfile? = nil,
        sharedSafeWord: String = "red"
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.partnerA = partnerA
        self.partnerB = partnerB
        self.sharedSafeWord = sharedSafeWord
    }

    // MARK: - Preview Helpers

    static let example = Couple()
}

```

---

## File: `Open Lightly/Models/Progress/CoupleSessionRecord.swift` {#file-open-lightly-models-progress-couplesessionrecord-swift}

```swift
//
//  CoupleSessionRecord.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import Foundation
import SwiftData

// ============================================================
// CoupleSessionRecord.swift
// A SwiftData model representing one completed or in-progress
// couple session. It tracks which cards were discussed or
// skipped, timing, and session-level metadata.
//
// CoupleSessionRecord instances are owned by a Couple and stored
// as part of the couple's history. They are not responsible
// for storing per-card progress (that's CardProgress).
//
// Forward references: Couple model declares the inverse
// relationship and owns CoupleSessionRecord via a cascade rule.
// ============================================================

@Model
final class CoupleSessionRecord: Identifiable {

    // MARK: - Properties

    var id: UUID = UUID()

    // Which category this session covered (e.g. "communication")
    var categoryID: String

    // Lifecycle state of the session
    var status: SessionStatus = SessionStatus.notStarted

    // Ordered list of card IDs that were discussed in this session
    var cardIDsDiscussed: [String] = []

    // Cards the couple chose to skip
    var cardIDsSkipped: [String] = []

    // If paused/in-progress, which card is currently displayed
    var currentCardID: String? = nil

    // If paused, whose turn it is
    var currentTurn: TurnOrder? = nil

    // Whether the safe word was invoked during this session
    var safeWordUsed: Bool = false

    // Total duration in seconds
    var durationSeconds: Int = 0

    // Timestamps
    var startedAt: Date? = nil
    var completedAt: Date? = nil


    // MARK: - Relationships

    // The Couple that owns this session record (inverse declared on Couple)
    @Relationship
    var couple: Couple?


    // MARK: - Initializer

    init(
        categoryID: String,
        status: SessionStatus = SessionStatus.notStarted,
        cardIDsDiscussed: [String] = [],
        cardIDsSkipped: [String] = [],
        currentCardID: String? = nil,
        currentTurn: TurnOrder? = nil,
        safeWordUsed: Bool = false,
        durationSeconds: Int = 0,
        startedAt: Date? = nil,
        completedAt: Date? = nil
    ) {
        self.id = UUID()
        self.categoryID = categoryID
        self.status = status
        self.cardIDsDiscussed = cardIDsDiscussed
        self.cardIDsSkipped = cardIDsSkipped
        self.currentCardID = currentCardID
        self.currentTurn = currentTurn
        self.safeWordUsed = safeWordUsed
        self.durationSeconds = durationSeconds
        self.startedAt = startedAt
        self.completedAt = completedAt
    }


    // MARK: - Preview Helpers

    static let example = CoupleSessionRecord(categoryID: "communication")
}

```

---

## File: `Open Lightly/Models/Progress/DesireMatch.swift` {#file-open-lightly-models-progress-desirematch-swift}

```swift
//
//  DesireMatch.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import Foundation
import SwiftData

// ============================================================
// DesireMatch.swift
// A SwiftData model representing a positive alignment between two
// partners for a specific desire map item. A DesireMatch is only
// created when the alignment logic yields a positive result.
// Combinations involving a boundary never produce a DesireMatch.
//
// This model is owned by a Couple and records the alignment level
// as well as the original ratings from each partner.
// ============================================================

@Model
final class DesireMatch: Identifiable {

    // MARK: - Properties

    var id: UUID = UUID()

    // Matches ContentDesireItem.id (e.g. "desire-001")
    var desireItemId: String

    // The alignment level returned by the alignment engine
    var alignmentLevel: String

    // What partner A rated this item
    var ratingA: DesireLevel

    // What partner B rated this item
    var ratingB: DesireLevel

    // When this match was computed/stored
    var computedAt: Date = Date()

    // Optional: partner values, gap, bridge card
    var partnerAValue: String?
    var partnerBValue: String?
    var gapSize: Int?
    var bridgeCardId: String?


    // MARK: - Relationships

    // The Couple that owns this match record (inverse declared on Couple)
    @Relationship
    var couple: Couple?


    // MARK: - Initializer

    init(
        desireItemId: String,
        alignmentLevel: String,
        ratingA: DesireLevel,
        ratingB: DesireLevel,
        partnerAValue: String? = nil,
        partnerBValue: String? = nil,
        gapSize: Int? = nil,
        bridgeCardId: String? = nil
    ) {
        self.id = UUID()
        self.desireItemId = desireItemId
        self.alignmentLevel = alignmentLevel
        self.ratingA = ratingA
        self.ratingB = ratingB
        self.computedAt = Date()
        self.partnerAValue = partnerAValue
        self.partnerBValue = partnerBValue
        self.gapSize = gapSize
        self.bridgeCardId = bridgeCardId
    }


    // MARK: - Preview Helpers

    static let example = DesireMatch(desireItemId: "desire-001", alignmentLevel: AlignmentLevel.strongAlignment.rawValue, ratingA: DesireLevel.excitedAboutIt, ratingB: DesireLevel.openToIt)
}

```

---

## File: `Open Lightly/Models/Progress/DesireRating.swift` {#file-open-lightly-models-progress-desirerating-swift}

```swift
//
//  DesireRating.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import Foundation
import SwiftData

// ============================================================
// DesireRating.swift
// A SwiftData model storing one person's private rating for
// a single desire map item. Ratings are private and only used
// to compute DesireMatch results; the raw ratings are never
// exposed to the partner.
//
// This model is owned by a UserProfile and represents a single
// response on the Desire Map.
// ============================================================

@Model
final class DesireRating: Identifiable {

    // MARK: - Properties

    var id: UUID = UUID()

    // Matches ContentDesireItem.id (e.g. "desire-001")
    var desireItemId: String

    // Partner's private rating for this item
    var rating: DesireLevel

    // When the rating was recorded
    var ratedAt: Date = Date()


    // MARK: - Relationships

    // Owner is the UserProfile who created this rating. The inverse
    // relationship is defined on UserProfile.desireRatings and handles
    // cascade deletion when a UserProfile is removed.
    @Relationship
    var owner: UserProfile?


    // MARK: - Initializer

    init(
        desireItemId: String,
        rating: DesireLevel
    ) {
        self.id = UUID()
        self.desireItemId = desireItemId
        self.rating = rating
        self.ratedAt = Date()
    }


    // MARK: - Preview Helpers

    static let example = DesireRating(desireItemId: "desire-001", rating: DesireLevel.openToIt)
}

```

---

## File: `Open Lightly/Models/Progress/UserProfile.swift` {#file-open-lightly-models-progress-userprofile-swift}

```swift
//
//  UserProfile.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import Foundation
import SwiftData

@Model
final class UserProfile: Identifiable {

    // MARK: - Identity

    var id: UUID = UUID()
    var name: String
    var createdAt: Date = Date()
    var pronouns: String
    var sexualOrientation: String
    var rolePreference: String

    // MARK: - Mode & Experience

    var userMode: String
    var experienceLevel: String
    var defaultDifficulty: String
    var nmFlavor: NMFlavor?

    // MARK: - Curiosity & Content

    var curiositySelections: [String]
    var surpriseMeEnabled: Bool

    // MARK: - Onboarding State

    var hasCompletedOnboarding: Bool = false
    var hasCompletedAssessment: Bool = false
    var mythBusterComplete: Bool
    var mythBusterSkipped: Bool
    var onboardingDropoffScreen: String?

    // MARK: - Account & Auth

    var accountId: String?
    var accountCreated: Bool

    // MARK: - Pairing

    var pairingCode: String = ""
    var isLinked: Bool = false
    var partnerLabel: PartnerLabel?

    // MARK: - Relationships

    @Relationship(deleteRule: .cascade)
    var assessmentResponses: [AssessmentResponse] = []

    @Relationship(deleteRule: .cascade)
    var desireRatings: [DesireRating] = []

    // MARK: - Init

    init(
        id: UUID = UUID(),
        name: String = "",
        createdAt: Date = Date(),
        pronouns: String = "they/them",
        sexualOrientation: String = "prefer not to say",
        rolePreference: String = "not sure",
        userMode: String = "solo",
        experienceLevel: String = "new",
        defaultDifficulty: String = "warm",
        nmFlavor: NMFlavor? = nil,
        pairingCode: String? = nil,
        isLinked: Bool = false,
        partnerLabel: PartnerLabel? = nil,
        hasCompletedOnboarding: Bool = false,
        hasCompletedAssessment: Bool = false
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.pronouns = pronouns
        self.sexualOrientation = sexualOrientation
        self.rolePreference = rolePreference
        self.userMode = userMode
        self.experienceLevel = experienceLevel
        self.defaultDifficulty = defaultDifficulty
        self.nmFlavor = nmFlavor
        self.pairingCode = pairingCode ?? UserProfile.generatePairingCode()
        self.isLinked = isLinked
        self.partnerLabel = partnerLabel
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.hasCompletedAssessment = hasCompletedAssessment
        self.curiositySelections = []
        self.surpriseMeEnabled = false
        self.mythBusterComplete = false
        self.mythBusterSkipped = false
        self.accountId = nil
        self.accountCreated = false
        self.onboardingDropoffScreen = nil
    }

    // MARK: - Computed Properties

    var displayInitial: String {
        String(name.prefix(1)).uppercased()
    }

    var isSolo: Bool { !isLinked }

    // MARK: - Static Helpers

    static func generatePairingCode() -> String {
        let words = [
            "HONEY", "SPARK", "FLAME", "BLOOM", "VELVET",
            "LUNAR", "EMBER", "BLUSH", "SUGAR", "CEDAR",
            "ROUGE", "PEARL", "CORAL", "DUSK", "HAVEN"
        ]
        let word = words.randomElement() ?? "SPARK"
        let number = Int.random(in: 10...99)
        return "\(word) \(number)"
    }

    // MARK: - Preview Helpers

    static let example = UserProfile(name: "Jordan")

    static let linkedExample: UserProfile = {
        let p = UserProfile(name: "Riley")
        p.isLinked = true
        p.partnerLabel = PartnerLabel.partnerA
        p.hasCompletedOnboarding = true
        p.hasCompletedAssessment = true
        p.pairingCode = "SPARK 42"
        return p
    }()
}

```

---

## File: `Open Lightly/Features/Auth/SignInView.swift` {#file-open-lightly-features-auth-signinview-swift}

```swift
//
//  SignInView.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/9/26.
//

import SwiftUI

struct SignInView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                VStack(spacing: 12) {
                    Text("Open Lightly")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.white)
                    
                    Text("Explore intimacy at your own pace")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                }
                
                Spacer()
                
                VStack(spacing: 16) {
                    Button(action: {
                        authService.signInWithApple()
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "apple.logo")
                            Text("Sign in with Apple")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(.white)
                        .foregroundStyle(.black)
                        .cornerRadius(14)
                    }
                    .padding(.horizontal, 40)
                    .disabled(authService.isLoading)
                    
                    if authService.isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                    
                    if let error = authService.error {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal, 40)
                            .multilineTextAlignment(.center)
                    }
                }
                
                Spacer()
                    .frame(height: 60)
            }
        }
    }
}

#Preview {
    SignInView()
        .environmentObject(AuthService())
}

```

---

## File: `Open Lightly/Features/Compatibility/DesireMapView.swift` {#file-open-lightly-features-compatibility-desiremapview-swift}

```swift
import SwiftUI
import SwiftData

struct DesireMapView: View {
    // MARK: - State
    @State private var ratings: [String: DesireLevel] = [:]
    @State private var expandedCategory: String? = nil
    
    // Placeholder data until Batch 8 persistence
    private let desireCategories: [(name: String, items: [(id: String, name: String, description: String)])] = [
        ("Power Dynamics", [
            ("pd-1", "Dominant Role", "Taking the lead in intimate scenarios"),
            ("pd-2", "Submissive Role", "Following your partner's guidance"),
            ("pd-3", "Switching", "Alternating between roles fluidly")
        ]),
        ("Sensation", [
            ("sn-1", "Temperature Play", "Using warmth or coolness as stimulation"),
            ("sn-2", "Light Touch", "Feather-light, teasing contact"),
            ("sn-3", "Firm Pressure", "Deeper, grounding physical pressure")
        ]),
        ("Communication", [
            ("cm-1", "Dirty Talk", "Verbal expression during intimacy"),
            ("cm-2", "Praise", "Affirming words and compliments"),
            ("cm-3", "Instruction", "Giving or receiving specific guidance")
        ]),
        ("Exploration", [
            ("ex-1", "Role Play", "Taking on characters or scenarios"),
            ("ex-2", "New Locations", "Intimacy outside the usual setting"),
            ("ex-3", "Toys & Props", "Introducing objects into play")
        ])
    ]
    
    private var ratedCount: Int { ratings.count }
    private var totalCount: Int { desireCategories.flatMap(\.items).count }
    
    @Environment(\.modelContext) private var modelContext
    /// Live DataStore instance built from the environment context.
    private var store: DataStore { DataStore(context: modelContext) }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                header
                progressSummary
                categoryList
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .background(AppColors.background.ignoresSafeArea())
        .onAppear { loadSavedRatings() }
        .screenshotProtected()
    }
    
    // MARK: - Header
    private var header: some View {
        VStack(spacing: 6) {
            Text("Desire Map")
                .font(AppFonts.screenTitle)
                .foregroundColor(AppColors.textPrimary)
            
            Text("Rate each item privately. Matches revealed only when both partners finish.")
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textTertiary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Progress Summary
    private var progressSummary: some View {
        SettingsCard {
            HStack(spacing: 16) {
                ProgressRingView(progress: totalCount > 0 ? Double(ratedCount) / Double(totalCount) : 0, size: 48)

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(ratedCount) of \(totalCount) rated")
                        .font(AppFonts.bodyMedium)
                        .foregroundColor(AppColors.textPrimary)

                    Text("Take your time — there's no rush")
                        .font(AppFonts.meta)
                        .foregroundColor(AppColors.textMuted)
                }

                Spacer()
            }
        }
    }
    
    // MARK: - Category List
    private var categoryList: some View {
        VStack(spacing: 16) {
            ForEach(desireCategories, id: \.name) { category in
                categorySection(category)
            }
        }
    }
    
    // MARK: - Category Section
    @ViewBuilder
    private func categorySection(_ category: (name: String, items: [(id: String, name: String, description: String)])) -> some View {
        let isExpanded = expandedCategory == category.name
        let categoryRated = category.items.filter { ratings[$0.id] != nil }.count
        
        VStack(spacing: 0) {
            // Header row (tap to expand)
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    expandedCategory = isExpanded ? nil : category.name
                }
            } label: {
                HStack {
                    Text(category.name.uppercased())
                        .font(AppFonts.sectionHeader)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Spacer()
                    
                    GradBadge(text: "\(categoryRated)/\(category.items.count)")
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColors.textMuted)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            
            if isExpanded {
                SpectrumBar()
                    .padding(.horizontal, 16)
                
                VStack(spacing: 12) {
                    ForEach(category.items, id: \.id) { item in
                        desireItemRow(item)
                    }
                }
                .padding(16)
            }
        }
        .cardStyle()
    }
    
    // MARK: - Desire Item Row
    private func desireItemRow(_ item: (id: String, name: String, description: String)) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(item.name)
                .font(AppFonts.bodyMedium)
                .foregroundColor(AppColors.textPrimary)
            
            Text(item.description)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textTertiary)
            
            RatingButtonGroup(
                selected: Binding(
                    get: { ratings[item.id] },
                    set: { newValue in
                        ratings[item.id] = newValue
                        if let rating = newValue {
                            // Find which category this item belongs to
                            let categoryName = desireCategories.first { cat in
                                cat.items.contains { $0.id == item.id }
                            }?.name ?? "Unknown"
                            saveRating(itemId: item.id, category: categoryName, rating: rating)
                        }
                    }
                )
            )
        }
        .padding(12)
        .background(AppColors.surfaceBg)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    /// Loads all previously saved desire map ratings via DataStore.
    private func loadSavedRatings() {
        let allItems = desireCategories.flatMap(\.items)
        for item in allItems {
            if let saved = store.fetchRating(forPromptId: item.id),
               let level = Int(saved.reaction).flatMap({ DesireLevel(rawValue: $0) }) {
                ratings[item.id] = level
            }
        }
    }

    /// Saves or updates a single desire map rating via DataStore.
    private func saveRating(itemId: String, category: String, rating: DesireLevel) {
        store.saveDesireRating(itemId: itemId, category: category, level: rating)
    }
}

#Preview {
    DesireMapView()
        .preferredColorScheme(.dark)
        .modelContainer(ModelContainer.previewContainer)
}

```

---

## File: `Open Lightly/Features/Explore/ExploreView.swift` {#file-open-lightly-features-explore-exploreview-swift}

```swift
// Features/Explore/ExploreView.swift
// Open Lightly
//
// Content discovery hub — articles, exercises, education tracks.
// Stub — full implementation in a future batch.

import SwiftUI

struct ExploreView: View {
    var body: some View {
        ZStack {
            AppColors.pageBg.ignoresSafeArea()
            Text("ExploreView")
                .font(AppFonts.screenTitle)
                .foregroundStyle(AppColors.textPrimary)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    let state = AppState()
    state.experienceType = .soloSingle
    return ExploreView().environment(state)
}

```

---

## File: `Open Lightly/Features/Home/HomeView.swift` {#file-open-lightly-features-home-homeview-swift}

```swift
// Features/Home/HomeView.swift
// Open Lightly
//
// Thin router only — zero business logic here.
// Switches on appState.experienceType and renders the matching
// experience-specific home screen.
//
// The .browsing case should never reach this view because ContentView
// gates guests into the guest shell before the tab bar renders.
// The case is kept as a defensive fallback that renders MoreView.

import SwiftUI
import OSLog

private let logger = Logger(subsystem: "com.openlightly.app", category: "HomeView")

struct HomeView: View {

    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            switch appState.experienceType {
            case .soloSingle:
                HomeViewSingle()
            case .soloPartnered:
                HomeViewSolo()
            case .coupleNew:
                HomeViewCoupleNew()
            case .coupleExperienced:
                HomeViewCoupleExp()
            case .browsing:
                // Defensive fallback — guest users are gated in ContentView.
                // Log a warning so this path is visible in console.
                MoreView()
                    .onAppear {
                        logger.warning("HomeView reached with .browsing experienceType — guest should be gated in ContentView")
                    }
            }
        }
    }
}

// MARK: - Previews

#Preview("HomeViewSingle") {
    let state = AppState()
    state.experienceType = .soloSingle
    return HomeView().environment(state)
}

#Preview("HomeViewSolo") {
    let state = AppState()
    state.experienceType = .soloPartnered
    return HomeView().environment(state)
}

#Preview("HomeViewCoupleNew") {
    let state = AppState()
    state.experienceType = .coupleNew
    return HomeView().environment(state)
}

#Preview("HomeViewCoupleExp") {
    let state = AppState()
    state.experienceType = .coupleExperienced
    return HomeView().environment(state)
}

```

---

## File: `Open Lightly/Features/Home/HomeDashboardView.swift` {#file-open-lightly-features-home-homedashboardview-swift}

```swift
// HomeDashboardView.swift
// Open Lightly

import SwiftUI

// MARK: - HomeDashboardView

// Home tab — Full Dashboard
// Solo frame: addresses the individual user.
// Couple context surfaces through components,
// not through the primary language of the screen.
// Act 1 MVP — coupleNew persona.
// Shell is expansion-ready for Act 2 + Act 3 users.

struct HomeDashboardView: View {

    // MARK: - Injected Properties
    // All have preview-safe defaults.

    var displayName: String = "Jordan"
    var partnerChipState: PartnerChipState = .none
    var sessionCardState: SessionCardState = .dayZero
    var desireMapState: DesireMapState = .hidden
    var reflectionCardState: ReflectionCardState = .hidden
    var pickUpItems: [PickUpItem] = []

    var stageIndex: Int = 1
    var cardsCompleted: Int = 0
    var daysSinceLastSession: Int? = nil
    var recentEvents: [HomeEvent] = []
    var isSolo: Bool = false

    var showReflectionBanner: Bool = false

    // MARK: - Callbacks

    var onSessionContinue: (() -> Void)? = nil
    var onRemindPartner: (() -> Void)? = nil
    var onGoToLearn: (() -> Void)? = nil
    var onDesireMapReveal: (() -> Void)? = nil
    var onDesireMapUnlock: (() -> Void)? = nil
    var onReflectionDone: (([String], String?, Bool) -> Void)? = nil
    var onReflectionBannerDismiss: (() -> Void)? = nil
    var onMoreTap: (() -> Void)? = nil
    var onPickUpItemTap: ((PickUpItem) -> Void)? = nil
    var onInvitePartner: (() -> Void)? = nil

    // MARK: - Environment + State

    @Environment(\.colorScheme) private var colorScheme

    @State private var greetingVisible    = false
    @State private var sessionVisible     = false
    @State private var desireMapVisible   = false
    @State private var reflectionVisible  = false
    @State private var pickUpVisible      = false
    @State private var tickerVisible      = false
    @State private var hasAnimated        = false
    @State private var greeting: String   = ""

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack(alignment: .top) {
                backgroundLayer(w: w, h: h)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {

                        Spacer(minLength: max(16, h * 0.06))

                        // ── Greeting ──────────────────────────────
                        greetingBlock
                            .padding(.horizontal, 24)
                            .opacity(greetingVisible ? 1 : 0)
                            .offset(y: greetingVisible ? 0 : 12)
                            .animation(.easeOut(duration: 0.5),
                                       value: greetingVisible)

                        Spacer(minLength: max(24, h * 0.034))

                        // ── Session Card ──────────────────────────
                        SessionCard(
                            state: sessionCardState,
                            onContinue: onSessionContinue,
                            onRemindPartner: onRemindPartner,
                            onGoToLearn: onGoToLearn
                        )
                        .padding(.horizontal, 20)
                        .opacity(sessionVisible ? 1 : 0)
                        .offset(y: sessionVisible ? 0 : 16)
                        .animation(.easeOut(duration: 0.5),
                                   value: sessionVisible)

                        // ── Desire Map Indicator ──────────────────
                        if desireMapState != .hidden
                            && desireMapState != .fullyUnlocked {

                            Spacer(minLength: max(14, h * 0.02))

                            DesireMapIndicator(
                                state: desireMapState,
                                onReveal: onDesireMapReveal,
                                onUnlock: onDesireMapUnlock,
                                onRemind: onRemindPartner
                            )
                            .padding(.horizontal, 20)
                            .opacity(desireMapVisible ? 1 : 0)
                            .offset(y: desireMapVisible ? 0 : 12)
                            .animation(.easeOut(duration: 0.5),
                                       value: desireMapVisible)
                        }

                        // ── Reflection Card ───────────────────────
                        if reflectionCardState != .hidden {

                            Spacer(minLength: max(14, h * 0.02))

                            ReflectionCard(
                                state: reflectionCardState,
                                onMoreTap: onMoreTap,
                                onDone: { pills, note in
                                    onReflectionDone?(
                                        pills, note, true)
                                }
                            )
                            .padding(.horizontal, 20)
                            .opacity(reflectionVisible ? 1 : 0)
                            .offset(y: reflectionVisible ? 0 : 12)
                            .animation(.easeOut(duration: 0.5),
                                       value: reflectionVisible)
                        }

                        // ── Pick Up Where You Left Off ────────────
                        if !pickUpItems.isEmpty {

                            Spacer(minLength: max(14, h * 0.02))

                            PickUpCard(
                                items: pickUpItems,
                                onItemTap: onPickUpItemTap
                            )
                            .padding(.horizontal, 20)
                            .opacity(pickUpVisible ? 1 : 0)
                            .offset(y: pickUpVisible ? 0 : 8)
                            .animation(.easeOut(duration: 0.5),
                                       value: pickUpVisible)
                        }

                        // ── Research Ticker ───────────────────────
                        Spacer(minLength: max(20, h * 0.03))

                        ResearchTicker()
                            .opacity(tickerVisible ? 1 : 0)
                            .animation(.easeOut(duration: 0.6),
                                       value: tickerVisible)

                        // Bottom padding for floating tab bar
                        Spacer(minLength: 120)
                    }
                }

                // ── Reflection Banner Overlay ─────────────────────
                if showReflectionBanner {
                    VStack {
                        ReflectionBannerView(
                            sessionLabel: bannerSessionLabel,
                            partnerName: bannerPartnerName,
                            onDone: onReflectionDone,
                            onDismiss: onReflectionBannerDismiss
                        )
                        .padding(.horizontal, 12)
                        .padding(.top, 8)

                        Spacer()
                    }
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .top)
                                .combined(with: .opacity),
                            removal: .move(edge: .top)
                                .combined(with: .opacity)
                        )
                    )
                    .animation(.spring(response: 0.4,
                                       dampingFraction: 0.8),
                               value: showReflectionBanner)
                    .zIndex(10)
                }
            }
            .frame(width: w, height: h)
            .onAppear {
                buildGreeting()
                guard !hasAnimated else { return }
                hasAnimated = true
                runEntranceAnimations()
            }
        }
    }

    // MARK: - Greeting Block

    private var greetingBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Name row with partner chip
            HStack(alignment: .top) {
                // Greeting lines
                VStack(alignment: .leading, spacing: 2) {
                    // Salutation line
                    Text(greetingSalutation)
                        .font(AppFonts.heroTitle)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightTextPrimary
                            : AppColors.textPrimary)

                    // Name in gradient
                    if !displayName.isEmpty {
                        Text("\(displayName).")
                            .font(AppFonts.heroTitle)
                            .foregroundStyle(
                                colorScheme == .light
                                ? AnyShapeStyle(LinearGradient(
                                    colors: [AppColors.magenta,
                                             AppColors.gold],
                                    startPoint: .leading,
                                    endPoint: .trailing))
                                : AnyShapeStyle(LinearGradient(
                                    colors: [AppColors.cyan,
                                             AppColors.purple],
                                    startPoint: .leading,
                                    endPoint: .trailing))
                            )
                    }
                }

                Spacer()

                // Partner chip — top right
                PartnerChip(
                    state: partnerChipState,
                    onInviteTap: onInvitePartner
                )
                .padding(.top, 4)
            }

            // Event-aware one-liner
            Text(eventOneLiner)
                .font(AppFonts.bodyText)
                .foregroundStyle(colorScheme == .light
                    ? AppColors.lightTextSecondary
                    : AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Computed Properties

    private var greetingSalutation: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "Good morning"
        case 12..<17: return "Hey"
        case 17..<21: return "Good evening"
        default:      return "Still up"
        }
    }

    private var eventOneLiner: String {
        let partner: String? = {
            if case .active(let name, _) = partnerChipState {
                return name
            }
            return nil
        }()
        return HomeEventEngine.oneLiner(
            events: recentEvents,
            stageIndex: stageIndex,
            cardsCompleted: cardsCompleted,
            isSolo: isSolo,
            partnerName: partner
        )
    }

    private var bannerSessionLabel: String {
        if case .pendingYours(let label, _) = reflectionCardState {
            return label
        }
        return "Last session"
    }

    private var bannerPartnerName: String? {
        if case .active(let name, _) = partnerChipState {
            return name
        }
        return nil
    }

    // MARK: - Background

    private func backgroundLayer(w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            if colorScheme == .light {
                AppColors.lightPageBg
            } else {
                AppColors.pageBg
            }

            if colorScheme == .dark {
                Ellipse()
                    .fill(RadialGradient(
                        colors: [
                            AppColors.purple.opacity(0.18),
                            AppColors.deepBlue.opacity(0.08),
                            Color.clear
                        ],
                        center: .top,
                        startRadius: 30,
                        endRadius: 380
                    ))
                    .frame(width: w * 1.4, height: h * 0.45)
                    .offset(y: -h * 0.06)
                    .blur(radius: 80)
            }

            if colorScheme == .light {
                AuroraGlowField()
            } else {
                OnboardingGlowField()
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Greeting Build

    private func buildGreeting() {
        // greeting salutation is computed live in greetingSalutation
        // nothing needed here unless caching is required
    }

    // MARK: - Entrance Animations

    private func runEntranceAnimations() {
        withAnimation(.easeOut(duration: 0.5).delay(0.10)) {
            greetingVisible   = true
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.25)) {
            sessionVisible    = true
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.38)) {
            desireMapVisible  = true
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.50)) {
            reflectionVisible = true
        }
        withAnimation(.easeOut(duration: 0.4).delay(0.60)) {
            pickUpVisible     = true
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.70)) {
            tickerVisible     = true
        }
    }
}

// MARK: - DesireMapState Equatable helper

extension DesireMapState: Equatable {
    static func == (lhs: DesireMapState,
                    rhs: DesireMapState) -> Bool {
        switch (lhs, rhs) {
        case (.hidden, .hidden),
             (.bothReady, .bothReady),
             (.fullyUnlocked, .fullyUnlocked):
            return true
        case (.youDone(let a), .youDone(let b)):
            return a == b
        case (.freeRevealSeen(let a), .freeRevealSeen(let b)):
            return a == b
        case (.redoInProgress(let a, let b),
              .redoInProgress(let c, let d)):
            return a == c && b == d
        default:
            return false
        }
    }
}

// MARK: - ReflectionCardState Equatable helper

extension ReflectionCardState: Equatable {
    static func == (lhs: ReflectionCardState,
                    rhs: ReflectionCardState) -> Bool {
        switch (lhs, rhs) {
        case (.hidden, .hidden):
            return true
        default:
            return false
        }
    }
}

// MARK: - Previews

#Preview("Dark — Day Zero, Solo") {
    HomeDashboardView(
        displayName: "Jordan",
        partnerChipState: .none,
        sessionCardState: .dayZero,
        desireMapState: .hidden,
        reflectionCardState: .hidden,
        pickUpItems: [],
        stageIndex: 1,
        cardsCompleted: 0,
        recentEvents: [],
        isSolo: true
    )
    .preferredColorScheme(.dark)
}

#Preview("Dark — Day Zero, Invite Pending") {
    HomeDashboardView(
        displayName: "Jordan",
        partnerChipState: .invitePending,
        sessionCardState: .dayZero,
        desireMapState: .youDone(partnerName: "Alex"),
        reflectionCardState: .hidden,
        pickUpItems: [],
        stageIndex: 1,
        cardsCompleted: 0,
        recentEvents: []
    )
    .preferredColorScheme(.dark)
}

#Preview("Dark — Mid Deck, Both Map Ready") {
    HomeDashboardView(
        displayName: "Jordan",
        partnerChipState: .active(name: "Alex", initial: "A"),
        sessionCardState: .midDeck(
            completed: 5, total: 12,
            nextPrompt: "When did you first become curious about this?"
        ),
        desireMapState: .bothReady,
        reflectionCardState: .pendingYours(
            sessionLabel: "Stage 1 · Session 1",
            sessionDate: Date().addingTimeInterval(-172800)
        ),
        pickUpItems: [],
        stageIndex: 1,
        cardsCompleted: 5,
        recentEvents: [
            .partnerCompletedDesireMap(partnerName: "Alex")
        ]
    )
    .preferredColorScheme(.dark)
}

#Preview("Dark — Both Reflected, Summary") {
    HomeDashboardView(
        displayName: "Jordan",
        partnerChipState: .active(name: "Alex", initial: "A"),
        sessionCardState: .midDeck(
            completed: 8, total: 12,
            nextPrompt: "What would feeling safe actually look like?"
        ),
        desireMapState: .hidden,
        reflectionCardState: .summary(
            arc: "You've moved from something heavy surfacing to feeling connected twice running. That's a real shift.",
            yourName: "Jordan",
            yourDots: [true, true, true],
            partnerName: "Alex",
            partnerDots: [true, true, false],
            swipePosition: 2
        ),
        pickUpItems: [
            PickUpItem(
                contentType: .timelineScenario(
                    branchCurrent: 2, branchTotal: 4),
                title: "Alex is home. Sam has been quiet.",
                contextLine: "You're at branch point 2 of 4",
                actionLabel: "Continue →"
            )
        ],
        stageIndex: 1,
        cardsCompleted: 8,
        recentEvents: []
    )
    .preferredColorScheme(.dark)
}

#Preview("Dark — Deck Complete") {
    HomeDashboardView(
        displayName: "Jordan",
        partnerChipState: .active(name: "Alex", initial: "A"),
        sessionCardState: .deckComplete(
            stageName: "Curiosity",
            stageIndex: 1,
            nextStageName: "Fantasy Together",
            nextStageCards: 10
        ),
        desireMapState: .freeRevealSeen(partnerName: "Alex"),
        reflectionCardState: .bothReflected(
            sessionLabel: "Stage 1 · Session 4",
            yourName: "Jordan",
            yourPills: ["Connected", "Surprised"],
            yourNote: "Didn't expect to feel that settled.",
            partnerName: "Alex",
            partnerPills: ["Heavy", "Want to talk more"],
            partnerNote: nil,
            swipePosition: 0
        ),
        pickUpItems: [],
        stageIndex: 1,
        cardsCompleted: 12,
        recentEvents: [.stageCompleted(stageName: "Curiosity")]
    )
    .preferredColorScheme(.dark)
}

#Preview("Dark — Waiting on Partner") {
    HomeDashboardView(
        displayName: "Jordan",
        partnerChipState: .active(name: "Alex", initial: "A"),
        sessionCardState: .waitingOnPartner(
            partnerName: "Alex",
            completed: 5,
            total: 12
        ),
        desireMapState: .hidden,
        reflectionCardState: .hidden,
        pickUpItems: [],
        stageIndex: 1,
        cardsCompleted: 5,
        recentEvents: [.daysSinceSession(3, partnerName: "Alex")]
    )
    .preferredColorScheme(.dark)
}

#Preview("Dark — Reflection Banner") {
    HomeDashboardView(
        displayName: "Jordan",
        partnerChipState: .active(name: "Alex", initial: "A"),
        sessionCardState: .midDeck(
            completed: 3, total: 12,
            nextPrompt: "What would safety actually look like?"
        ),
        desireMapState: .hidden,
        reflectionCardState: .hidden,
        pickUpItems: [],
        stageIndex: 1,
        cardsCompleted: 3,
        recentEvents: [],
        showReflectionBanner: true
    )
    .preferredColorScheme(.dark)
}

#Preview("Light — Day Zero") {
    HomeDashboardView(
        displayName: "Jordan",
        partnerChipState: .invitePending,
        sessionCardState: .dayZero,
        desireMapState: .hidden,
        reflectionCardState: .hidden,
        pickUpItems: [],
        stageIndex: 1,
        cardsCompleted: 0,
        recentEvents: []
    )
    .preferredColorScheme(.light)
}

#Preview("Dark — No Name") {
    HomeDashboardView(
        displayName: "",
        partnerChipState: .none,
        sessionCardState: .dayZero,
        desireMapState: .hidden,
        reflectionCardState: .hidden,
        pickUpItems: [],
        stageIndex: 1,
        cardsCompleted: 0,
        recentEvents: [],
        isSolo: true
    )
    .preferredColorScheme(.dark)
}

```

---

## File: `Open Lightly/Features/Home/HomeGateView.swift` {#file-open-lightly-features-home-homegateview-swift}

```swift
//
//  HomeGateView.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/23/26.
//


// HomeGateView.swift
// Open Lightly
//
// Home tab — Gate state (S1 / S3)
// Shown when: user has not completed their Desire Map.
// Whether paired or not, the primary CTA is the same: start the map.
// Learn tab escape hatch is a secondary link, never a consolation prize.

import SwiftUI

struct HomeGateView: View {
    let isPaired: Bool
    let onStartMap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    @State private var headerVisible     = false
    @State private var cardVisible       = false
    @State private var detailVisible     = false
    @State private var ctaVisible        = false
    @State private var hasAnimated       = false

    // Subtle breathing glow behind the CTA
    @State private var breathe: Bool = false

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let w = geo.size.width

            let topPad      = max(16.0, h * 0.04)
            let sectionGap  = max(20.0, h * 0.032)
            let cardPad     = max(16.0, h * 0.022)

            ViewThatFits(in: .vertical) {

                // Attempt 1 — preferred, no scroll
                VStack(spacing: 0) {
                    contentBlock(h: h, sectionGap: sectionGap,
                                 cardPad: cardPad, topPad: topPad)
                    Spacer(minLength: 0)
                    ctaBlock
                        .padding(.horizontal, 24)
                }

                // Attempt 2 — scroll fallback (SE + large text)
                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        contentBlock(h: h, sectionGap: sectionGap,
                                     cardPad: cardPad, topPad: topPad)
                    }
                    ctaBlock
                        .padding(.horizontal, 24)
                }
            }
            .frame(width: w, height: h)
            .background { backgroundLayer(w: w, h: h) }
            .onAppear {
                guard !hasAnimated else { return }
                hasAnimated = true
                runEntranceAnimations()
            }
        }
    }

    // MARK: - Content Block

    private func contentBlock(
        h: CGFloat,
        sectionGap: CGFloat,
        cardPad: CGFloat,
        topPad: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: sectionGap) {

            // ── Overline ───────────────────────────────────────────
            Text("STEP 1 OF 2")
                .font(AppFonts.overline)
                .tracking(2)
                .foregroundStyle(colorScheme == .light
                    ? AnyShapeStyle(LinearGradient(
                        colors: [AppColors.magenta, AppColors.gold],
                        startPoint: .leading, endPoint: .trailing))
                    : AnyShapeStyle(AppColors.cyanLight))
                .opacity(headerVisible ? 1 : 0)
                .offset(y: headerVisible ? 0 : -8)

            // ── Headline ───────────────────────────────────────────
            VStack(alignment: .leading, spacing: 6) {
                Text("Before you can see")
                    .font(AppFonts.heroTitle)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextPrimary
                        : AppColors.textPrimary)

                Text("what you share —")
                    .font(AppFonts.heroTitle)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextPrimary
                        : AppColors.textPrimary)

                // Gradient keyword line
                Text("know what YOU want.")
                    .font(AppFonts.heroTitle)
                    .foregroundStyle(
                        colorScheme == .light
                            ? AnyShapeStyle(LinearGradient(
                                colors: [AppColors.magenta, AppColors.gold],
                                startPoint: .leading, endPoint: .trailing))
                            : AnyShapeStyle(LinearGradient(
                                colors: [AppColors.cyan, AppColors.purple],
                                startPoint: .leading, endPoint: .trailing))
                    )
            }
            .opacity(headerVisible ? 1 : 0)
            .offset(y: headerVisible ? 0 : 12)

            // ── Info card ──────────────────────────────────────────
            VStack(alignment: .leading, spacing: 14) {
                infoRow(
                    icon: "lock.fill",
                    text: "17 questions. Your answers stay **completely private**."
                )
                infoRow(
                    icon: "clock.fill",
                    text: "About **5 minutes**. No wrong answers."
                )
                infoRow(
                    icon: "eye.slash.fill",
                    text: isPaired
                        ? "Your partner **never sees** your individual answers — only what you both agree on."
                        : "When your partner joins, they'll **never see** your individual answers."
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, cardPad)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .light
                        ? AppColors.lightCardFill
                        : AppColors.cardBg)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        colorScheme == .light
                            ? AppColors.lightBorder
                            : AppColors.border,
                        lineWidth: 1
                    )
            }
            .opacity(cardVisible ? 1 : 0)
            .offset(y: cardVisible ? 0 : 12)

            // ── Reassurance ────────────────────────────────────────
            Text("There are no right answers. Just yours.")
                .font(AppFonts.caption)
                .foregroundStyle(colorScheme == .light
                    ? AppColors.lightTextSecondary
                    : AppColors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .opacity(detailVisible ? 1 : 0)
        }
        .padding(.horizontal, 24)
        .padding(.top, topPad)
        .padding(.bottom, 16)
    }

    // MARK: - Info Row

    private func infoRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            // Icon badge
            ZStack {
                Circle()
                    .fill(colorScheme == .light
                        ? AppColors.magenta.opacity(0.08)
                        : AppColors.cyan.opacity(0.10))
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.magenta
                        : AppColors.cyan)
            }
            .fixedSize()

            // Markdown-style bold text
            // Using AttributedString for inline bold
            Text(parseInlineBold(text))
                .font(AppFonts.bodyText)
                .foregroundStyle(colorScheme == .light
                    ? AppColors.lightTextPrimary
                    : AppColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
        }
    }

    // MARK: - CTA Block

    private var ctaBlock: some View {
        VStack(spacing: 16) {

            // Primary CTA
            HoloCTAButton(
                title: "Start Your Desire Map",
                isEnabled: true
            ) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onStartMap()
            }
            .fixedSize(horizontal: false, vertical: true)
            .opacity(ctaVisible ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.82), value: ctaVisible)

            // Education escape hatch
            Button {
                // Route to Learn tab
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "books.vertical.fill")
                        .font(.system(size: 12, weight: .medium))
                    Text("Browse the education library while you wait")
                        .font(AppFonts.caption)
                }
                .foregroundStyle(colorScheme == .light
                    ? AppColors.lightTextSecondary
                    : AppColors.textSecondary)
            }
            .buttonStyle(.plain)
            .opacity(ctaVisible ? 1 : 0)
            .animation(
                .easeOut(duration: 0.4).delay(0.1),
                value: ctaVisible
            )

            // Footer
            OnboardingFooter(text: "Your answers are encrypted and never leave your device.")
        }
    }

    // MARK: - Background

    private func backgroundLayer(w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            if colorScheme == .light {
                AppColors.lightPageBg
            } else {
                AppColors.pageBg
            }

            if colorScheme == .dark {
                // Atmospheric ellipse — purple top wash
                Ellipse()
                    .fill(RadialGradient(
                        colors: [
                            AppColors.purple.opacity(0.25),
                            AppColors.deepBlue.opacity(0.12),
                            Color.clear
                        ],
                        center: .top,
                        startRadius: 30,
                        endRadius: 360
                    ))
                    .frame(width: w * 1.4, height: h * 0.55)
                    .offset(y: -h * 0.1)
                    .blur(radius: 80)
            }

            if colorScheme == .light {
                AuroraGlowField()
            } else {
                OnboardingGlowField()
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Animations

    private func runEntranceAnimations() {
        withAnimation(.easeOut(duration: 0.5).delay(0.15)) { headerVisible = true }
        withAnimation(.easeOut(duration: 0.5).delay(0.30)) { cardVisible   = true }
        withAnimation(.easeOut(duration: 0.5).delay(0.50)) { detailVisible = true }
        withAnimation(.easeOut(duration: 0.4).delay(0.55)) { ctaVisible    = true }

        // Breathing glow loop — starts after entrance settles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                breathe = true
            }
        }
    }

    // MARK: - Inline Bold Parser

    /// Converts **text** markers to AttributedString bold spans.
    /// Keeps font consistent — only weight changes.
    private func parseInlineBold(_ raw: String) -> AttributedString {
        var result = AttributedString()
        let parts  = raw.components(separatedBy: "**")
        for (i, part) in parts.enumerated() {
            var segment = AttributedString(part)
            if i % 2 == 1 {
                segment.font = AppFonts.bodyMedium
            }
            result.append(segment)
        }
        return result
    }
}

// MARK: - Previews

#Preview("Dark — Unpaired") {
    HomeGateView(isPaired: false, onStartMap: {})
        .preferredColorScheme(.dark)
}

#Preview("Dark — Paired") {
    HomeGateView(isPaired: true, onStartMap: {})
        .preferredColorScheme(.dark)
}

#Preview("Light — Unpaired") {
    HomeGateView(isPaired: false, onStartMap: {})
        .preferredColorScheme(.light)
}

#Preview("SE — Dark") {
    HomeGateView(isPaired: true, onStartMap: {})
        .preferredColorScheme(.dark)
}
```

---

## File: `Open Lightly/Features/Home/HomeMatchReadyView.swift` {#file-open-lightly-features-home-homematchreadyview-swift}

```swift
//
//  HomeMatchReadyView.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/23/26.
//


// HomeMatchReadyView.swift
// Open Lightly
//
// Home tab — Match Ready state (S5)
// Shown when: both partners have completed the Desire Map, reveal not yet seen.
//
// This is the highest-tension screen in the entire app.
// Design intent: maximum restraint. One CTA. No clutter. No secondary actions.
// The pacing IS the experience — this screen should feel like the moment
// before opening something important.

import SwiftUI

struct HomeMatchReadyView: View {
    let onReveal: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    @State private var readyVisible   = false
    @State private var bodyVisible    = false
    @State private var ctaVisible     = false
    @State private var togetherVisible = false
    @State private var hasAnimated    = false

    // Spectrum bloom breathing — this screen's signature
    @State private var bloom: Bool = false

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let w = geo.size.width

            VStack(spacing: 0) {
                Spacer()

                // ── Core content — deliberately centered ──────────
                VStack(spacing: max(24.0, h * 0.034)) {

                    // Particle burst placeholder
                    // Replace with ParticleBurstView when built (Risk 3 in DESIGN_DOC)
                    HStack(spacing: 12) {
                        ForEach(0..<5) { i in
                            Circle()
                                .fill(
                                    [AppColors.cyan, AppColors.purple,
                                     AppColors.magenta, AppColors.cyan,
                                     AppColors.purple][i]
                                    .opacity(bloom ? 0.9 : 0.4)
                                )
                                .frame(width: 6, height: 6)
                                .scaleEffect(bloom ? 1.2 : 0.8)
                                .animation(
                                    .easeInOut(duration: 1.4)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(i) * 0.18),
                                    value: bloom
                                )
                        }
                    }
                    .opacity(readyVisible ? 1 : 0)

                    // Headline
                    VStack(spacing: 6) {
                        Text("You're both ready.")
                            .font(AppFonts.heroTitle)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: colorScheme == .light
                                        ? [AppColors.magenta, AppColors.gold]
                                        : [AppColors.cyan, AppColors.purple, AppColors.magenta],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .multilineTextAlignment(.center)
                    }
                    .opacity(readyVisible ? 1 : 0)
                    .offset(y: readyVisible ? 0 : 16)

                    // Body
                    Text("One thing you agree on\nis waiting to be seen.")
                        .font(AppFonts.bodyText)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightTextSecondary
                            : AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .opacity(bodyVisible ? 1 : 0)
                }
                .padding(.horizontal, 32)

                Spacer()

                // ── CTA — pinned to bottom ─────────────────────────
                VStack(spacing: 12) {
                    HoloCTAButton(
                        title: "See Your First Match",
                        isEnabled: true
                    ) {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        onReveal()
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(ctaVisible ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.82), value: ctaVisible)

                    // "Do this together" — only instruction on this screen
                    Text("Do this together.")
                        .font(AppFonts.caption)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightTextTertiary
                            : AppColors.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .opacity(togetherVisible ? 1 : 0)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .frame(width: w, height: h)
            .background { backgroundLayer(w: w, h: h) }
            .onAppear {
                guard !hasAnimated else { return }
                hasAnimated = true
                runEntranceAnimations()
            }
        }
    }

    // MARK: - Background
    // Maximum atmospheric treatment — this screen earns full spectrum bloom.

    private func backgroundLayer(w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            if colorScheme == .light {
                AppColors.lightPageBg
            } else {
                AppColors.pageBg
            }

            if colorScheme == .dark {
                // Tri-color bloom — all three spectrum colors present
                Ellipse()
                    .fill(RadialGradient(
                        colors: [
                            AppColors.cyan.opacity(bloom ? 0.18 : 0.10),
                            AppColors.purple.opacity(bloom ? 0.14 : 0.08),
                            Color.clear
                        ],
                        center: .top,
                        startRadius: 20,
                        endRadius: 400
                    ))
                    .frame(width: w * 1.6, height: h * 0.6)
                    .offset(y: -h * 0.05)
                    .blur(radius: 90)

                Ellipse()
                    .fill(RadialGradient(
                        colors: [
                            AppColors.magenta.opacity(bloom ? 0.12 : 0.06),
                            Color.clear
                        ],
                        center: .bottom,
                        startRadius: 10,
                        endRadius: 300
                    ))
                    .frame(width: w * 1.2, height: h * 0.4)
                    .offset(y: h * 0.15)
                    .blur(radius: 80)
            }

            if colorScheme == .light {
                AuroraGlowField()
            } else {
                OnboardingGlowField()
            }
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: bloom)
    }

    // MARK: - Animations

    private func runEntranceAnimations() {
        // Deliberate slowness — this screen gets more ceremony
        withAnimation(.easeOut(duration: 0.7).delay(0.30)) { readyVisible    = true }
        withAnimation(.easeOut(duration: 0.6).delay(0.60)) { bodyVisible     = true }
        withAnimation(.easeOut(duration: 0.4).delay(0.90)) { ctaVisible      = true }
        withAnimation(.easeOut(duration: 0.4).delay(1.05)) { togetherVisible = true }

        // Bloom breathing — starts after content settles
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                bloom = true
            }
        }
    }
}

// MARK: - Previews

#Preview("Dark") {
    HomeMatchReadyView(onReveal: {})
        .preferredColorScheme(.dark)
}

#Preview("Light") {
    HomeMatchReadyView(onReveal: {})
        .preferredColorScheme(.light)
}
```

---

## File: `Open Lightly/Features/Home/HomeRouterView.swift` {#file-open-lightly-features-home-homerouterview-swift}

```swift
//
//  HomeState.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/23/26.
//


// HomeRouterView.swift
// Open Lightly
//
// Root router for the Home tab.
// Reads UserProfile + Couple state and renders the correct home experience.
// All tab-locking logic lives here — single source of truth.
//
// State machine:
//   S1 — unpaired, map incomplete      → HomeGateView
//   S2 — unpaired, map complete        → PostMapReflectionView (if needed) → HomeWaitingView
//   S3 — paired, my map incomplete     → HomeGateView
//   S4 — paired, waiting on partner    → HomeWaitingView
//   S5 — both complete, no reveal yet  → HomeMatchReadyView
//   S6 — reveal done                   → HomeDashboardView

import SwiftUI

enum HomeState: Equatable {
    case gated              // S1 / S3 — map not done
    case postReflection     // R1 / R2 / R3 — post-map reflection stems
    case waiting            // S4 — waiting on partner
    case matchReady         // S5 — both done, reveal pending
    case dashboard          // S6 — full experience
}

struct HomeRouterView: View {
    @Environment(\.colorScheme) private var colorScheme

    // Injected from DataStore / AppState
    // These will be @Bindable SwiftData models in the real implementation.
    // Using simple @State here so the file compiles standalone for now.
    @State private var myMapComplete: Bool          = false
    @State private var partnerMapComplete: Bool     = false
    @State private var isPaired: Bool               = false
    @State private var revealDone: Bool             = false
    @State private var postReflectionDone: Bool     = false
    @State private var reflectionStep: Int          = 1    // 1, 2, or 3

    // Derived state — single computed property drives all routing
    private var homeState: HomeState {
        guard myMapComplete else         { return .gated }
        guard postReflectionDone else    { return .postReflection }
        guard isPaired && partnerMapComplete else { return .waiting }
        guard revealDone else            { return .matchReady }
        return .dashboard
    }

    var body: some View {
        ZStack {
            switch homeState {
            case .gated:
                HomeGateView(
                    isPaired: isPaired,
                    onStartMap: { /* route to DesireMapView */ }
                )
                .transition(.opacity)

            case .postReflection:
                PostMapReflectionView(
                    step: $reflectionStep,
                    onComplete: {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            postReflectionDone = true
                        }
                    },
                    onSkipAll: {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            postReflectionDone = true
                        }
                    }
                )
                .transition(.opacity)

            case .waiting:
                HomeWaitingView(
                    isPaired: isPaired,
                    partnerName: "your partner", // replace with real partner name
                    onInvite: { /* open share sheet */ }
                )
                .transition(.opacity)

            case .matchReady:
                HomeMatchReadyView(
                    onReveal: { /* route to reveal / paywall */ }
                )
                .transition(.opacity)

            case .dashboard:
                HomeDashboardView()
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: homeState)
    }
}

// MARK: - Tab Lock Helper
// Called from the tab bar coordinator to determine which tabs are accessible.
// Single source of truth — no logic scattered across tab items.

extension HomeRouterView {
    static func isTabLocked(_ tab: AppTab, homeState: HomeState) -> Bool {
        switch homeState {
        case .dashboard:
            return false // All tabs open
        default:
            // Only Home and More are accessible during gate/waiting/reveal states
            return tab == .meUs || tab == .explore
        }
    }
}
```

---

## File: `Open Lightly/Features/Home/HomeWaitingView.swift` {#file-open-lightly-features-home-homewaitingview-swift}

```swift
//
//  HomeWaitingView.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/23/26.
//


// HomeWaitingView.swift
// Open Lightly
//
// Home tab — Waiting state (S4)
// Shown when: user has completed their Desire Map, partner hasn't.
// Also shown when: user hasn't paired yet (isPaired: false).
//
// Primary goal: re-surface the invite mechanism without feeling pushy.
// Secondary: genuine value while they wait (education, preview).

import SwiftUI

struct HomeWaitingView: View {
    let isPaired: Bool
    let partnerName: String     // Empty string if unpaired
    let onInvite: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    @State private var headerVisible  = false
    @State private var statusVisible  = false
    @State private var ctaVisible     = false
    @State private var secondaryVisible = false
    @State private var hasAnimated    = false
    @State private var pulsing        = false

    private var displayPartnerName: String {
        partnerName.isEmpty ? "your partner" : partnerName
    }

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let w = geo.size.width

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    contentBlock(h: h)
                }
                ctaBlock
                    .padding(.horizontal, 24)
            }
            .frame(width: w, height: h)
            .background { backgroundLayer(w: w, h: h) }
            .onAppear {
                guard !hasAnimated else { return }
                hasAnimated = true
                runEntranceAnimations()
            }
        }
    }

    // MARK: - Content Block

    private func contentBlock(h: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: max(24.0, h * 0.036)) {

            // ── Overline ───────────────────────────────────────────
            Text("YOUR PART IS DONE")
                .font(AppFonts.overline)
                .tracking(2)
                .foregroundStyle(
                    colorScheme == .light
                        ? AnyShapeStyle(LinearGradient(
                            colors: [AppColors.magenta, AppColors.gold],
                            startPoint: .leading, endPoint: .trailing))
                        : AnyShapeStyle(AppColors.cyanLight)
                )
                .opacity(headerVisible ? 1 : 0)
                .offset(y: headerVisible ? 0 : -8)

            // ── Headline ───────────────────────────────────────────
            VStack(alignment: .leading, spacing: 4) {
                Text(isPaired
                     ? "Now we wait for"
                     : "Invite your partner")
                    .font(AppFonts.heroTitle)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextPrimary
                        : AppColors.textPrimary)

                if isPaired {
                    Text(displayPartnerName + ".")
                        .font(AppFonts.heroTitle)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppColors.cyan, AppColors.purple],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                }
            }
            .opacity(headerVisible ? 1 : 0)
            .offset(y: headerVisible ? 0 : 12)

            // ── Partner status indicator ───────────────────────────
            if isPaired {
                partnerStatusCard
                    .opacity(statusVisible ? 1 : 0)
                    .offset(y: statusVisible ? 0 : 12)
            }

            // ── Context copy ───────────────────────────────────────
            Text(isPaired
                 ? "Their answers are private too. When they're done, you'll see what you have in common."
                 : "They'll complete their own map privately. When you're both done, you'll see your first shared result.")
                .font(AppFonts.bodyText)
                .foregroundStyle(colorScheme == .light
                    ? AppColors.lightTextSecondary
                    : AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(statusVisible ? 1 : 0)
                .offset(y: statusVisible ? 0 : 8)

            // ── While you wait ─────────────────────────────────────
            VStack(alignment: .leading, spacing: 12) {
                Text("While you wait")
                    .font(AppFonts.caption)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextSecondary
                        : AppColors.textSecondary)

                whileYouWaitRow(
                    icon: "books.vertical.fill",
                    text: "Browse the education library",
                    action: { /* route to Learn tab */ }
                )
                whileYouWaitRow(
                    icon: "eye.fill",
                    text: "Preview your first conversation deck",
                    action: { /* route to deck preview */ }
                )
            }
            .opacity(secondaryVisible ? 1 : 0)
            .offset(y: secondaryVisible ? 0 : 12)
        }
        .padding(.horizontal, 24)
        .padding(.top, 40)
        .padding(.bottom, 16)
    }

    // MARK: - Partner Status Card

    private var partnerStatusCard: some View {
        HStack(spacing: 14) {
            // Pulsing pending indicator
            ZStack {
                Circle()
                    .fill(AppColors.cyan.opacity(pulsing ? 0.15 : 0.06))
                    .frame(width: 36, height: 36)
                    .scaleEffect(pulsing ? 1.15 : 1.0)

                Circle()
                    .fill(AppColors.cyan.opacity(0.3))
                    .frame(width: 10, height: 10)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(displayPartnerName)
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextPrimary
                        : AppColors.textPrimary)
                Text("Map in progress...")
                    .font(AppFonts.caption)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextTertiary
                        : AppColors.textTertiary)
            }

            Spacer()

            Text("Waiting")
                .font(AppFonts.overline)
                .tracking(1)
                .foregroundStyle(AppColors.textTertiary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background {
                    Capsule()
                        .fill(colorScheme == .light
                            ? AppColors.lightBorder
                            : Color.white.opacity(0.06))
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(colorScheme == .light
                    ? AppColors.lightCardFill
                    : AppColors.cardBg)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(colorScheme == .light
                    ? AppColors.lightBorder
                    : AppColors.border,
                    lineWidth: 1)
        }
    }

    // MARK: - While You Wait Row

    private func whileYouWaitRow(
        icon: String,
        text: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.purple
                        : AppColors.cyanLight)
                    .frame(width: 20)

                Text(text)
                    .font(AppFonts.bodyText)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextPrimary
                        : AppColors.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextTertiary
                        : AppColors.textTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .light
                        ? AppColors.lightFrostCard
                        : AppColors.cardBg)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(colorScheme == .light
                        ? AppColors.lightBorder
                        : AppColors.border,
                        lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - CTA Block

    private var ctaBlock: some View {
        VStack(spacing: 16) {
            HoloCTAButton(
                title: isPaired
                    ? "Remind \(displayPartnerName)"
                    : "Invite Your Partner",
                isEnabled: true
            ) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onInvite()
            }
            .fixedSize(horizontal: false, vertical: true)
            .opacity(ctaVisible ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.82), value: ctaVisible)

            OnboardingFooter(
                text: isPaired
                    ? "We won't tell them how you answered."
                    : "They'll set up their own account and complete the map privately."
            )
        }
    }

    // MARK: - Background

    private func backgroundLayer(w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            if colorScheme == .light {
                AppColors.lightPageBg
            } else {
                AppColors.pageBg
            }

            if colorScheme == .dark {
                Ellipse()
                    .fill(RadialGradient(
                        colors: [
                            AppColors.purple.opacity(0.20),
                            AppColors.deepBlue.opacity(0.10),
                            Color.clear
                        ],
                        center: .top,
                        startRadius: 30,
                        endRadius: 360
                    ))
                    .frame(width: w * 1.4, height: h * 0.50)
                    .offset(y: -h * 0.08)
                    .blur(radius: 80)
            }

            if colorScheme == .light {
                AuroraGlowField()
            } else {
                OnboardingGlowField()
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Animations

    private func runEntranceAnimations() {
        withAnimation(.easeOut(duration: 0.5).delay(0.15)) { headerVisible    = true }
        withAnimation(.easeOut(duration: 0.5).delay(0.30)) { statusVisible    = true }
        withAnimation(.easeOut(duration: 0.5).delay(0.50)) { secondaryVisible = true }
        withAnimation(.easeOut(duration: 0.4).delay(0.55)) { ctaVisible       = true }

        // Pulsing partner status loop
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                pulsing = true
            }
        }
    }
}

// MARK: - Previews

#Preview("Paired — Dark") {
    HomeWaitingView(isPaired: true, partnerName: "Alex", onInvite: {})
        .preferredColorScheme(.dark)
}

#Preview("Unpaired — Dark") {
    HomeWaitingView(isPaired: false, partnerName: "", onInvite: {})
        .preferredColorScheme(.dark)
}

#Preview("Paired — Light") {
    HomeWaitingView(isPaired: true, partnerName: "Alex", onInvite: {})
        .preferredColorScheme(.light)
}
```

---

## File: `Open Lightly/Features/Home/HomeViewSingle.swift` {#file-open-lightly-features-home-homeviewsingle-swift}

```swift
// Features/Home/HomeViewSingle.swift
// Open Lightly
//
// Home screen for solo users with no current partner.
// Stub — full implementation in a future batch.

import SwiftUI

struct HomeViewSingle: View {
    var body: some View {
        ZStack {
            AppColors.pageBg.ignoresSafeArea()
            Text("HomeViewSingle")
                .font(AppFonts.screenTitle)
                .foregroundStyle(AppColors.textPrimary)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    let state = AppState()
    state.experienceType = .soloSingle
    return HomeViewSingle()
        .environment(state)
}

```

---

## File: `Open Lightly/Features/Home/HomeViewSolo.swift` {#file-open-lightly-features-home-homeviewsolo-swift}

```swift
// Features/Home/HomeViewSolo.swift
// Open Lightly
//
// Home screen for solo users who have a partner (open or not yet disclosed).
// Stub — full implementation in a future batch.

import SwiftUI

struct HomeViewSolo: View {
    var body: some View {
        ZStack {
            AppColors.pageBg.ignoresSafeArea()
            Text("HomeViewSolo")
                .font(AppFonts.screenTitle)
                .foregroundStyle(AppColors.textPrimary)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    let state = AppState()
    state.experienceType = .soloPartnered
    return HomeViewSolo()
        .environment(state)
}

```

---

## File: `Open Lightly/Features/Home/HomeViewCoupleNew.swift` {#file-open-lightly-features-home-homeviewcouplenew-swift}

```swift
// Features/Home/HomeViewCoupleNew.swift
// Open Lightly
//
// Home screen for couples who are new to non-monogamy exploration.
// Stub — full implementation in a future batch.

import SwiftUI

struct HomeViewCoupleNew: View {
    var body: some View {
        ZStack {
            AppColors.pageBg.ignoresSafeArea()
            Text("HomeViewCoupleNew")
                .font(AppFonts.screenTitle)
                .foregroundStyle(AppColors.textPrimary)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    let state = AppState()
    state.experienceType = .coupleNew
    return HomeViewCoupleNew()
        .environment(state)
}

```

---

## File: `Open Lightly/Features/Home/HomeViewCoupleExp.swift` {#file-open-lightly-features-home-homeviewcoupleexp-swift}

```swift
// Features/Home/HomeViewCoupleExp.swift
// Open Lightly
//
// Home screen for couples with existing ENM experience.
// Stub — full implementation in a future batch.

import SwiftUI

struct HomeViewCoupleExp: View {
    var body: some View {
        ZStack {
            AppColors.pageBg.ignoresSafeArea()
            Text("HomeViewCoupleExp")
                .font(AppFonts.screenTitle)
                .foregroundStyle(AppColors.textPrimary)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    let state = AppState()
    state.experienceType = .coupleExperienced
    return HomeViewCoupleExp()
        .environment(state)
}

```

---

## File: `Open Lightly/Features/Home/PostMapReflectionView.swift` {#file-open-lightly-features-home-postmapreflectionview-swift}

```swift
//
//  StemConfig.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/23/26.
//


// PostMapReflectionView.swift
// Open Lightly
//
// Post-Desire-Map reflection — 3 sentence stems, one per screen.
// Private, on-device only. All skippable without guilt.
//
// Tonal progression:
//   Step 1 — cyan atmosphere   — grounded, certain
//   Step 2 — purple atmosphere — open, curious
//   Step 3 — magenta atmosphere — anticipatory, outward-facing
//
// The third stem is the most commercially important.
// It builds desire for the reveal before the partner has finished.

import SwiftUI

private struct StemConfig {
    let step: Int
    let overline: String
    let stem: String            // The "___" blank is appended in the view
    let placeholder: String
    let bloomColor: Color       // Dominant atmospheric tint
    let gradient: [Color]       // Headline gradient
    let hint: String            // Subtle copy below the field
}

private let stems: [StemConfig] = [
    StemConfig(
        step: 1,
        overline: "REFLECT · 1 OF 3",
        stem: "The item I felt most certain about was",
        placeholder: "what came to mind first...",
        bloomColor: AppColors.cyan,
        gradient: [AppColors.cyan, AppColors.purple],
        hint: "Certainty is data. It tells you something about yourself."
    ),
    StemConfig(
        step: 2,
        overline: "REFLECT · 2 OF 3",
        stem: "The one that surprised me was",
        placeholder: "I didn't expect to feel...",
        bloomColor: AppColors.purple,
        gradient: [AppColors.purple, AppColors.magenta],
        hint: "Surprise is where the interesting stuff lives."
    ),
    StemConfig(
        step: 3,
        overline: "REFLECT · 3 OF 3",
        stem: "What I'm most curious about my partner's answer to is",
        placeholder: "I wonder if they feel the same about...",
        bloomColor: AppColors.magenta,
        gradient: [AppColors.magenta, AppColors.purple],
        hint: "You'll find out soon."  // Intentional forward lean
    )
]

struct PostMapReflectionView: View {
    @Binding var step: Int      // 1, 2, 3
    let onComplete: () -> Void  // All 3 done (or skipped through)
    let onSkipAll: () -> Void   // User skips entire reflection

    @Environment(\.colorScheme) private var colorScheme

    @State private var inputText     = ""
    @State private var headerVisible = false
    @State private var stemVisible   = false
    @State private var fieldVisible  = false
    @State private var skipVisible   = false
    @State private var hasAnimated   = false
    @State private var isTransitioning = false
    @FocusState private var fieldFocused: Bool

    // Persisted responses (on-device only — never synced)
    @State private var responses: [Int: String] = [:]

    private var config: StemConfig {
        stems.first(where: { $0.step == step }) ?? stems[0]
    }

    private var isLastStep: Bool { step == 3 }
    private var canAdvance: Bool { !inputText.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let w = geo.size.width

            let topPad     = max(20.0, h * 0.05)
            let sectionGap = max(20.0, h * 0.034)

            ViewThatFits(in: .vertical) {
                VStack(spacing: 0) {
                    contentBlock(h: h, sectionGap: sectionGap, topPad: topPad)
                    Spacer(minLength: 0)
                    ctaBlock
                        .padding(.horizontal, 24)
                }

                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        contentBlock(h: h, sectionGap: sectionGap, topPad: topPad)
                    }
                    ctaBlock
                        .padding(.horizontal, 24)
                }
            }
            .frame(width: w, height: h)
            .background { backgroundLayer(w: w, h: h) }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .onAppear {
                guard !hasAnimated else { return }
                hasAnimated = true
                runEntranceAnimations()
            }
            // Tap to dismiss keyboard on scroll
            .onTapGesture { fieldFocused = false }
        }
    }

    // MARK: - Content Block

    private func contentBlock(
        h: CGFloat,
        sectionGap: CGFloat,
        topPad: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: sectionGap) {

            // ── Overline ───────────────────────────────────────────
            Text(config.overline)
                .font(AppFonts.overline)
                .tracking(2)
                .foregroundStyle(
                    colorScheme == .light
                        ? AnyShapeStyle(LinearGradient(
                            colors: [AppColors.magenta, AppColors.gold],
                            startPoint: .leading, endPoint: .trailing))
                        : AnyShapeStyle(config.bloomColor.opacity(0.9))
                )
                .opacity(headerVisible ? 1 : 0)
                .offset(y: headerVisible ? 0 : -8)

            // ── Stem ───────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 4) {
                Text(config.stem)
                    .font(AppFonts.screenTitle)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextPrimary
                        : AppColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                // The blank — visually part of the sentence
                Text("___")
                    .font(AppFonts.screenTitle)
                    .foregroundStyle(
                        LinearGradient(
                            colors: config.gradient,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            .opacity(stemVisible ? 1 : 0)
            .offset(y: stemVisible ? 0 : 12)

            // ── Input field ────────────────────────────────────────
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topLeading) {
                    // Placeholder
                    if inputText.isEmpty {
                        Text(config.placeholder)
                            .font(AppFonts.bodyText)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.lightTextTertiary
                                : AppColors.textTertiary)
                            .padding(.horizontal, 16)
                            .padding(.top, 14)
                            .allowsHitTesting(false)
                    }

                    TextEditor(text: $inputText)
                        .font(AppFonts.bodyText)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightTextPrimary
                            : AppColors.textPrimary)
                        .tint(config.bloomColor)
                        .focused($fieldFocused)
                        .frame(minHeight: 80, maxHeight: 120)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .scrollContentBackground(.hidden)
                }
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colorScheme == .light
                            ? AppColors.lightSurfaceBg
                            : Color.white.opacity(0.05))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            fieldFocused
                                ? AnyShapeStyle(LinearGradient(
                                    colors: config.gradient,
                                    startPoint: .leading,
                                    endPoint: .trailing))
                                : AnyShapeStyle(colorScheme == .light
                                    ? AppColors.lightBorder
                                    : AppColors.border),
                            lineWidth: fieldFocused ? 1.5 : 1
                        )
                }
                .animation(.easeOut(duration: 0.2), value: fieldFocused)

                // Hint text
                Text(config.hint)
                    .font(AppFonts.caption)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextTertiary
                        : AppColors.textTertiary)
                    .padding(.horizontal, 4)
            }
            .opacity(fieldVisible ? 1 : 0)
            .offset(y: fieldVisible ? 0 : 12)
        }
        .padding(.horizontal, 24)
        .padding(.top, topPad)
        .padding(.bottom, 16)
    }

    // MARK: - CTA Block

    private var ctaBlock: some View {
        VStack(spacing: 16) {

            // Primary CTA — changes on last step
            HoloCTAButton(
                title: isLastStep ? "See my waiting state" : "Next",
                isEnabled: canAdvance
            ) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                saveAndAdvance()
            }
            .fixedSize(horizontal: false, vertical: true)

            // Skip this one
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                skipAndAdvance()
            } label: {
                Text(isLastStep ? "Skip for now" : "Skip this one")
                    .font(AppFonts.caption)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextTertiary
                        : AppColors.textTertiary)
            }
            .buttonStyle(.plain)
            .opacity(skipVisible ? 1 : 0)

            OnboardingFooter(text: "Only you see this. These never leave your device.")
        }
    }

    // MARK: - Background

    private func backgroundLayer(w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            if colorScheme == .light {
                AppColors.lightPageBg
            } else {
                AppColors.pageBg
            }

            if colorScheme == .dark {
                // Bloom shifts with each step — tonal progression
                Ellipse()
                    .fill(RadialGradient(
                        colors: [
                            config.bloomColor.opacity(0.22),
                            config.bloomColor.opacity(0.08),
                            Color.clear
                        ],
                        center: .top,
                        startRadius: 20,
                        endRadius: 340
                    ))
                    .frame(width: w * 1.4, height: h * 0.50)
                    .offset(y: -h * 0.08)
                    .blur(radius: 80)
                    .animation(.easeInOut(duration: 0.8), value: step)
            }

            if colorScheme == .light {
                AuroraGlowField()
            } else {
                OnboardingGlowField()
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Navigation

    private func saveAndAdvance() {
        responses[step] = inputText.trimmingCharacters(in: .whitespaces)
        // TODO: persist to SwiftData SoloReflectionEntry or equivalent
        advance()
    }

    private func skipAndAdvance() {
        responses[step] = "" // Explicit skip — empty string not nil
        advance()
    }

    private func advance() {
        guard !isTransitioning else { return }
        isTransitioning = true
        fieldFocused = false

        if isLastStep {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                onComplete()
            }
        } else {
            // Cross-fade to next stem
            withAnimation(.easeInOut(duration: 0.35)) {
                headerVisible = false
                stemVisible   = false
                fieldVisible  = false
                skipVisible   = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.40) {
                step      += 1
                inputText  = ""
                hasAnimated = false
                isTransitioning = false
                runEntranceAnimations()
            }
        }
    }

    // MARK: - Animations

    private func runEntranceAnimations() {
        withAnimation(.easeOut(duration: 0.5).delay(0.10)) { headerVisible = true }
        withAnimation(.easeOut(duration: 0.5).delay(0.25)) { stemVisible   = true }
        withAnimation(.easeOut(duration: 0.5).delay(0.40)) { fieldVisible  = true }
        withAnimation(.easeOut(duration: 0.4).delay(0.60)) { skipVisible   = true }

        // Auto-focus field after entrance settles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            fieldFocused = true
        }
    }
}

// MARK: - Previews

#Preview("Step 1 — Dark") {
    @Previewable @State var step = 1
    PostMapReflectionView(step: $step, onComplete: {}, onSkipAll: {})
        .preferredColorScheme(.dark)
}

#Preview("Step 2 — Dark") {
    @Previewable @State var step = 2
    PostMapReflectionView(step: $step, onComplete: {}, onSkipAll: {})
        .preferredColorScheme(.dark)
}

#Preview("Step 3 — Dark") {
    @Previewable @State var step = 3
    PostMapReflectionView(step: $step, onComplete: {}, onSkipAll: {})
        .preferredColorScheme(.dark)
}

#Preview("Step 1 — Light") {
    @Previewable @State var step = 1
    PostMapReflectionView(step: $step, onComplete: {}, onSkipAll: {})
        .preferredColorScheme(.light)
}
```

---

## File: `Open Lightly/Features/Home/Components/DesireMapIndicator.swift` {#file-open-lightly-features-home-components-desiremapindicator-swift}

```swift
// Home/Components/DesireMapIndicator.swift

import SwiftUI

struct DesireMapIndicator: View {
    let state: DesireMapState
    var onReveal: (() -> Void)? = nil
    var onUnlock: (() -> Void)? = nil
    var onRemind: (() -> Void)? = nil

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        switch state {
        case .hidden, .fullyUnlocked:
            EmptyView()

        case .youDone(let partnerName):
            statusCard {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("DESIRE MAP")
                            .font(AppFonts.overline)
                            .tracking(1.2)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.lightTextTertiary
                                : AppColors.textTertiary)

                        HStack(spacing: 12) {
                            HStack(spacing: 5) {
                                Circle()
                                    .fill(colorScheme == .light
                                        ? AppColors.magenta
                                        : AppColors.cyan)
                                    .frame(width: 7, height: 7)
                                Text("You're done")
                                    .font(AppFonts.caption)
                                    .foregroundStyle(colorScheme == .light
                                        ? AppColors.lightTextSecondary
                                        : AppColors.textSecondary)
                            }
                            HStack(spacing: 5) {
                                Circle()
                                    .stroke(colorScheme == .light
                                        ? AppColors.lightTextTertiary
                                        : AppColors.textTertiary,
                                        lineWidth: 1)
                                    .frame(width: 7, height: 7)
                                Text(partnerName)
                                    .font(AppFonts.caption)
                                    .foregroundStyle(colorScheme == .light
                                        ? AppColors.lightTextTertiary
                                        : AppColors.textTertiary)
                            }
                        }
                    }
                    Spacer()
                    Button {
                        UIImpactFeedbackGenerator(style: .light)
                            .impactOccurred()
                        onRemind?()
                    } label: {
                        Text("Remind \(partnerName) →")
                            .font(AppFonts.caption)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.magenta
                                : AppColors.cyanLight)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
            }

        case .bothReady:
            // Elevated treatment — highest CTA weight on screen
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("DESIRE MAP")
                            .font(AppFonts.overline)
                            .tracking(1.2)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.lightTextTertiary
                                : AppColors.textTertiary)
                        Spacer()
                        Text("You're both ready")
                            .font(AppFonts.caption)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.magenta
                                : AppColors.cyanLight)
                    }

                    HStack(spacing: 16) {
                        HStack(spacing: 5) {
                            Circle()
                                .fill(colorScheme == .light
                                    ? AppColors.magenta
                                    : AppColors.cyan)
                                .frame(width: 7, height: 7)
                            Text("You")
                                .font(AppFonts.bodyMedium)
                                .foregroundStyle(colorScheme == .light
                                    ? AppColors.lightTextPrimary
                                    : AppColors.textPrimary)
                        }
                        HStack(spacing: 5) {
                            Circle()
                                .fill(colorScheme == .light
                                    ? AppColors.gold
                                    : AppColors.purple)
                                .frame(width: 7, height: 7)
                            Text("Partner")
                                .font(AppFonts.bodyMedium)
                                .foregroundStyle(colorScheme == .light
                                    ? AppColors.lightTextPrimary
                                    : AppColors.textPrimary)
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)

                Spacer(minLength: 14)

                Button {
                    UIImpactFeedbackGenerator(style: .medium)
                        .impactOccurred()
                    onReveal?()
                } label: {
                    Text("See Your First Match")
                        .font(AppFonts.ctaLabel)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.wineDark
                            : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(colorScheme == .light
                                    ? AnyShapeStyle(LinearGradient(
                                        colors: [AppColors.magenta.opacity(0.18),
                                                 AppColors.gold.opacity(0.14)],
                                        startPoint: .leading,
                                        endPoint: .trailing))
                                    : AnyShapeStyle(LinearGradient(
                                        colors: [AppColors.cyan,
                                                 AppColors.purple,
                                                 AppColors.magenta],
                                        startPoint: .leading,
                                        endPoint: .trailing)))
                        }
                        .shadow(color: colorScheme == .light
                            ? AppColors.lightShadowMagenta
                            : AppColors.purple.opacity(0.4),
                                radius: 12, y: 4)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.bottom, 18)
            }
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .light
                        ? AppColors.lightCardFill
                        : AppColors.cardBg)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(colorScheme == .light
                        ? AnyShapeStyle(
                            AppColors.warmAuroraBorder.opacity(0.6))
                        : AnyShapeStyle(LinearGradient(
                            colors: [AppColors.cyan.opacity(0.5),
                                     AppColors.purple.opacity(0.4),
                                     AppColors.magenta.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing)),
                        lineWidth: 1.5)
            }
            .shadow(color: colorScheme == .light
                ? AppColors.lightShadowPurple
                : AppColors.purple.opacity(0.2),
                    radius: 20, y: 6)

        case .freeRevealSeen(_):
            statusCard {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(colorScheme == .light
                                ? AppColors.magenta.opacity(0.10)
                                : AppColors.purple.opacity(0.15))
                            .frame(width: 38, height: 38)
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(colorScheme == .light
                                ? AnyShapeStyle(LinearGradient(
                                    colors: [AppColors.magenta, AppColors.gold],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing))
                                : AnyShapeStyle(LinearGradient(
                                    colors: [AppColors.purple, AppColors.magenta],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing)))
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("1 match revealed")
                            .font(AppFonts.bodyMedium)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.lightTextPrimary
                                : AppColors.textPrimary)
                        Text("+ more waiting")
                            .font(AppFonts.caption)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.lightTextTertiary
                                : AppColors.textTertiary)
                    }
                    Spacer()
                    Button {
                        UIImpactFeedbackGenerator(style: .light)
                            .impactOccurred()
                        onUnlock?()
                    } label: {
                        Text("Unlock →")
                            .font(AppFonts.caption)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.magenta
                                : AppColors.cyanLight)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
            }

        case .redoInProgress(let partnerName, let partnerStarted):
            statusCard {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("DESIRE MAP")
                                .font(AppFonts.overline)
                                .tracking(1.2)
                                .foregroundStyle(colorScheme == .light
                                    ? AppColors.lightTextTertiary
                                    : AppColors.textTertiary)
                            Text("· Check-in")
                                .font(AppFonts.overline)
                                .foregroundStyle(colorScheme == .light
                                    ? AppColors.magenta
                                    : AppColors.cyanLight)
                        }

                        HStack(spacing: 12) {
                            HStack(spacing: 5) {
                                Circle()
                                    .fill(colorScheme == .light
                                        ? AppColors.magenta
                                        : AppColors.cyan)
                                    .frame(width: 7, height: 7)
                                Text("You — redoing")
                                    .font(AppFonts.caption)
                                    .foregroundStyle(colorScheme == .light
                                        ? AppColors.lightTextSecondary
                                        : AppColors.textSecondary)
                            }
                            HStack(spacing: 5) {
                                Circle()
                                    .fill(partnerStarted
                                          ? (colorScheme == .light
                                              ? AppColors.gold
                                              : AppColors.purple)
                                          : Color.clear)
                                    .overlay {
                                        if !partnerStarted {
                                            Circle()
                                                .stroke(colorScheme == .light
                                                    ? AppColors.lightTextTertiary
                                                    : AppColors.textTertiary,
                                                    lineWidth: 1)
                                        }
                                    }
                                    .frame(width: 7, height: 7)
                                Text(partnerStarted
                                     ? "\(partnerName) in progress"
                                     : "\(partnerName) hasn't started")
                                    .font(AppFonts.caption)
                                    .foregroundStyle(
                                        partnerStarted
                                        ? (colorScheme == .light
                                            ? AppColors.lightTextSecondary
                                            : AppColors.textSecondary)
                                        : (colorScheme == .light
                                            ? AppColors.lightTextTertiary
                                            : AppColors.textTertiary)
                                    )
                            }
                        }
                    }
                    Spacer()
                    if !partnerStarted {
                        Button {
                            UIImpactFeedbackGenerator(style: .light)
                                .impactOccurred()
                            onRemind?()
                        } label: {
                            Text("Remind →")
                                .font(AppFonts.caption)
                                .foregroundStyle(colorScheme == .light
                                    ? AppColors.magenta
                                    : AppColors.cyanLight)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
            }
        }
    }

    // MARK: - Shared card shell for compact states

    @ViewBuilder
    private func statusCard<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .light
                        ? AppColors.lightFrostCard
                        : AppColors.cardBg)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(colorScheme == .light
                        ? AppColors.lightBorder
                        : AppColors.border,
                        lineWidth: 1)
            }
    }
}

```

---

## File: `Open Lightly/Features/Home/Components/PartnerChip.swift` {#file-open-lightly-features-home-components-partnerchip-swift}

```swift
// Home/Components/PartnerChip.swift

import SwiftUI

struct PartnerChip: View {
    let state: PartnerChipState
    var onInviteTap: (() -> Void)? = nil

    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }

    var body: some View {
        switch state {
        case .none:
            EmptyView()

        case .invitePending:
            Button {
                onInviteTap?()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "plus")
                        .font(.system(size: 9, weight: .bold))
                    Text("Invite partner")
                        .font(AppFonts.caption)
                }
                .foregroundStyle(isLight
                    ? AppColors.lightTextTertiary
                    : AppColors.textTertiary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background {
                    Capsule()
                        .fill(isLight
                            ? AppColors.lightFrostCard
                            : Color.white.opacity(0.04))
                }
                .overlay {
                    Capsule()
                        .stroke(isLight
                            ? AppColors.lightBorder
                            : Color.white.opacity(0.10),
                            lineWidth: 1)
                }
            }
            .buttonStyle(.plain)

        case .active(let name, let initial):
            HStack(spacing: 6) {
                // Avatar circle
                ZStack {
                    Circle()
                        .fill(isLight
                            ? Color.black.opacity(0.08)
                            : Color.white.opacity(0.12))
                        .frame(width: 18, height: 18)
                    Text(String(initial))
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(isLight
                            ? AppColors.lightTextPrimary
                            : .white)
                }
                Text(name)
                    .font(AppFonts.caption)
                    .foregroundStyle(isLight
                        ? AppColors.lightTextSecondary
                        : AppColors.textSecondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background {
                Capsule()
                    .fill(isLight
                        ? AppColors.lightFrostCard
                        : Color.white.opacity(0.04))
            }
            .overlay {
                Capsule()
                    .stroke(isLight
                        ? AppColors.lightBorder
                        : Color.white.opacity(0.08),
                        lineWidth: 1)
            }
        }
    }
}

```

---

## File: `Open Lightly/Features/Home/Components/PickUpCard.swift` {#file-open-lightly-features-home-components-pickupcard-swift}

```swift
// Home/Components/PickUpCard.swift

import SwiftUI

struct PickUpCard: View {
    let items: [PickUpItem]
    var onItemTap: ((PickUpItem) -> Void)? = nil
    var onSeeAll: (() -> Void)? = nil

    @Environment(\.colorScheme) private var colorScheme

    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        if items.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(items.prefix(2)) { item in
                    itemCard(item)
                        .onTapGesture {
                            UIImpactFeedbackGenerator(style: .light)
                                .impactOccurred()
                            onItemTap?(item)
                        }
                }

                if items.count > 2 {
                    Button {
                        onSeeAll?()
                    } label: {
                        Text("See all in-progress →")
                            .font(AppFonts.caption)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.magenta
                                : AppColors.cyanLight)
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 4)
                }
            }
        }
    }

    private func itemCard(_ item: PickUpItem) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(item.contentType.label)
                        .font(AppFonts.overline)
                        .tracking(1.0)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.magenta
                            : AppColors.cyanLight)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background {
                            Capsule()
                                .fill(colorScheme == .light
                                    ? AppColors.magenta.opacity(0.08)
                                    : AppColors.cyan.opacity(0.12))
                        }
                        .overlay {
                            Capsule()
                                .stroke(colorScheme == .light
                                    ? AppColors.magenta.opacity(0.20)
                                    : AppColors.cyan.opacity(0.25),
                                    lineWidth: 1)
                        }

                    Spacer()

                    // Pulsing amber dot
                    Circle()
                        .fill(Color(red: 1, green: 0.72, blue: 0))
                        .frame(width: 7, height: 7)
                        .scaleEffect(pulseScale)
                        .onAppear {
                            withAnimation(
                                .easeInOut(duration: 1.2)
                                .repeatForever(autoreverses: true)
                            ) {
                                pulseScale = 1.4
                            }
                        }
                }

                Text(item.contextLine)
                    .font(AppFonts.caption)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextTertiary
                        : AppColors.textTertiary)

                Text(item.title)
                    .font(AppFonts.bodyText)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextSecondary
                        : AppColors.textSecondary)
                    .lineLimit(2)

                Text(item.actionLabel)
                    .font(AppFonts.caption)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.magenta
                        : AppColors.cyanLight)
            }
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(colorScheme == .light
                    ? AppColors.lightFrostCard
                    : AppColors.cardBg)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(colorScheme == .light
                    ? AppColors.lightBorder
                    : AppColors.border,
                    lineWidth: 1)
        }
    }
}

private extension PickUpContentType {
    var label: String {
        switch self {
        case .timelineScenario: return "TIMELINE"
        case .article:          return "ARTICLE"
        case .judgmentCall:      return "JUDGMENT"
        case .autopsy:          return "AUTOPSY"
        }
    }
}

```

---

## File: `Open Lightly/Features/Home/Components/ReflectionBannerView.swift` {#file-open-lightly-features-home-components-reflectionbannerview-swift}

```swift
// Home/Components/ReflectionBannerView.swift

import SwiftUI

struct ReflectionBannerView: View {
    let sessionLabel: String
    let partnerName: String?
    var onDone: (([String], String?, Bool) -> Void)? = nil
    var onDismiss: (() -> Void)? = nil

    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedPills: Set<String> = []
    @State private var noteText: String = ""
    @State private var isWritingNote: Bool = false
    @State private var shareWithPartner: Bool = true
    @State private var showFullPillSheet: Bool = false

    @GestureState private var dragOffset: CGFloat = 0
    @State private var isVisible: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            Capsule()
                .fill(colorScheme == .light
                    ? Color.black.opacity(0.15)
                    : Color.white.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 10)
                .padding(.bottom, 14)

            VStack(alignment: .leading, spacing: 14) {
                // Header
                VStack(alignment: .leading, spacing: 2) {
                    Text(sessionLabel)
                        .font(AppFonts.overline)
                        .tracking(1.2)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightTextTertiary
                            : AppColors.textTertiary)
                    Text("How did that land for you?")
                        .font(AppFonts.bodyMedium)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightTextPrimary
                            : AppColors.textPrimary)
                }

                if isWritingNote {
                    TextEditor(text: $noteText)
                        .frame(minHeight: 70)
                        .font(AppFonts.bodyText)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightTextPrimary
                            : AppColors.textPrimary)
                        .scrollContentBackground(.hidden)
                        .padding(10)
                        .background {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(colorScheme == .light
                                    ? Color.black.opacity(0.03)
                                    : Color.white.opacity(0.04))
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(colorScheme == .light
                                    ? AppColors.lightBorder
                                    : AppColors.border,
                                    lineWidth: 1)
                        }
                } else {
                    // 5 default pills in 2 rows
                    LazyVGrid(
                        columns: Array(repeating:
                            GridItem(.flexible(), spacing: 8), count: 3),
                        spacing: 8
                    ) {
                        ForEach(ReflectionPillGroup.inlineDefault,
                                id: \.self) { pill in
                            bannerPillButton(pill)
                        }
                    }

                    Button {
                        showFullPillSheet = true
                    } label: {
                        Text("More →")
                            .font(AppFonts.caption)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.magenta
                                : AppColors.cyanLight)
                    }
                    .buttonStyle(.plain)
                }

                // Mode toggle
                Button {
                    isWritingNote.toggle()
                } label: {
                    Text(isWritingNote
                         ? "← Use pills instead"
                         : "✎ Write a note instead")
                        .font(AppFonts.caption)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightTextTertiary
                            : AppColors.textTertiary)
                }
                .buttonStyle(.plain)

                // Share toggle (only if has partner)
                if let name = partnerName {
                    HStack {
                        Text("Share with \(name)")
                            .font(AppFonts.caption)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.lightTextSecondary
                                : AppColors.textSecondary)
                        Spacer()
                        Toggle("", isOn: $shareWithPartner)
                            .labelsHidden()
                            .tint(colorScheme == .light
                                ? AppColors.magenta
                                : AppColors.cyan)
                    }
                }

                // Done + Not now
                HStack {
                    Button("Not now") {
                        dismiss()
                    }
                    .font(AppFonts.caption)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextTertiary
                        : AppColors.textTertiary)
                    .buttonStyle(.plain)

                    Spacer()

                    Button {
                        UIImpactFeedbackGenerator(style: .medium)
                            .impactOccurred()
                        onDone?(Array(selectedPills),
                                noteText.isEmpty ? nil : noteText,
                                shareWithPartner)
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(AppFonts.ctaLabel)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.wineDark
                                : .white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background {
                                Capsule()
                                    .fill(colorScheme == .light
                                        ? AnyShapeStyle(LinearGradient(
                                            colors: [AppColors.magenta.opacity(0.18),
                                                     AppColors.gold.opacity(0.14)],
                                            startPoint: .leading,
                                            endPoint: .trailing))
                                        : AnyShapeStyle(LinearGradient(
                                            colors: [AppColors.cyan,
                                                     AppColors.purple,
                                                     AppColors.magenta],
                                            startPoint: .leading,
                                            endPoint: .trailing)))
                            }
                            .overlay {
                                Capsule()
                                    .stroke(colorScheme == .light
                                        ? AnyShapeStyle(LinearGradient(
                                            colors: [AppColors.magenta,
                                                     AppColors.gold],
                                            startPoint: .leading,
                                            endPoint: .trailing))
                                        : AnyShapeStyle(Color.clear),
                                        lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedPills.isEmpty
                              && noteText.isEmpty)
                    .opacity(selectedPills.isEmpty
                             && noteText.isEmpty ? 0.4 : 1)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .fill((colorScheme == .light
                            ? AppColors.lightCardFill
                            : AppColors.cardBg).opacity(0.85))
                }
        }
        .overlay(alignment: .top) {
            RoundedRectangle(cornerRadius: 20)
                .stroke(colorScheme == .light
                    ? AnyShapeStyle(
                        AppColors.warmAuroraBorder.opacity(0.5))
                    : AnyShapeStyle(LinearGradient(
                        colors: [AppColors.cyan.opacity(0.4),
                                 AppColors.purple.opacity(0.3),
                                 AppColors.magenta.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing)),
                    lineWidth: 1.5)
        }
        .shadow(
            color: colorScheme == .light
                ? AppColors.lightShadowPurple
                : AppColors.purple.opacity(0.12),
            radius: 20, y: 6
        )
        .offset(y: dragOffset)
        .gesture(
            DragGesture()
                .updating($dragOffset) { value, state, _ in
                    if value.translation.height > 0 {
                        state = value.translation.height
                    }
                }
                .onEnded { value in
                    if value.translation.height > 80 {
                        dismiss()
                    }
                }
        )
        .sheet(isPresented: $showFullPillSheet) {
            fullPillSheet
        }
    }

    // MARK: - Pill Button

    private func bannerPillButton(_ pill: String) -> some View {
        let isSelected = selectedPills.contains(pill)
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            if isSelected { selectedPills.remove(pill) }
            else          { selectedPills.insert(pill) }
        } label: {
            Text(pill)
                .font(AppFonts.caption)
                .foregroundStyle(isSelected
                    ? (colorScheme == .light
                        ? AppColors.wineDark
                        : .white)
                    : (colorScheme == .light
                        ? AppColors.lightTextSecondary
                        : AppColors.textSecondary))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .frame(maxWidth: .infinity)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected
                            ? (colorScheme == .light
                                ? AnyShapeStyle(LinearGradient(
                                    colors: [AppColors.magenta.opacity(0.15),
                                             AppColors.gold.opacity(0.12)],
                                    startPoint: .leading,
                                    endPoint: .trailing))
                                : AnyShapeStyle(LinearGradient(
                                    colors: [AppColors.cyan.opacity(0.35),
                                             AppColors.purple.opacity(0.25)],
                                    startPoint: .leading,
                                    endPoint: .trailing)))
                            : AnyShapeStyle(Color.clear))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isSelected
                            ? (colorScheme == .light
                                ? AnyShapeStyle(LinearGradient(
                                    colors: [AppColors.magenta,
                                             AppColors.gold],
                                    startPoint: .leading,
                                    endPoint: .trailing))
                                : AnyShapeStyle(LinearGradient(
                                    colors: [AppColors.cyan,
                                             AppColors.purple],
                                    startPoint: .leading,
                                    endPoint: .trailing)))
                            : AnyShapeStyle(colorScheme == .light
                                ? AppColors.lightBorder
                                : AppColors.border),
                            lineWidth: 1
                        )
                }
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    // MARK: - Full Pill Sheet

    private var fullPillSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    pillSheetSection(
                        title: "HOW IT FELT",
                        pills: ReflectionPillGroup.howItFelt
                    )
                    pillSheetSection(
                        title: "WHAT HAPPENED",
                        pills: ReflectionPillGroup.whatHappened
                    )
                    pillSheetSection(
                        title: "WHAT YOU NEED NOW",
                        pills: ReflectionPillGroup.whatYouNeedNow
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Text("ADD A NOTE")
                            .font(AppFonts.overline)
                            .tracking(1.2)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.lightTextTertiary
                                : AppColors.textTertiary)

                        TextEditor(text: $noteText)
                            .frame(minHeight: 80)
                            .font(AppFonts.bodyText)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.lightTextPrimary
                                : AppColors.textPrimary)
                            .scrollContentBackground(.hidden)
                            .padding(10)
                            .background {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(colorScheme == .light
                                        ? Color.black.opacity(0.03)
                                        : Color.white.opacity(0.04))
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(colorScheme == .light
                                        ? AppColors.lightBorder
                                        : AppColors.border,
                                        lineWidth: 1)
                            }
                    }

                    if let name = partnerName {
                        HStack {
                            Text("Share with \(name)")
                                .font(AppFonts.bodyText)
                                .foregroundStyle(colorScheme == .light
                                    ? AppColors.lightTextSecondary
                                    : AppColors.textSecondary)
                            Spacer()
                            Toggle("", isOn: $shareWithPartner)
                                .labelsHidden()
                                .tint(colorScheme == .light
                                    ? AppColors.magenta
                                    : AppColors.cyan)
                        }
                    }

                    Button {
                        showFullPillSheet = false
                        onDone?(Array(selectedPills),
                                noteText.isEmpty ? nil : noteText,
                                shareWithPartner)
                    } label: {
                        Text("Done")
                            .font(AppFonts.ctaLabel)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.wineDark
                                : .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(colorScheme == .light
                                        ? AnyShapeStyle(LinearGradient(
                                            colors: [AppColors.magenta.opacity(0.18),
                                                     AppColors.gold.opacity(0.14)],
                                            startPoint: .leading,
                                            endPoint: .trailing))
                                        : AnyShapeStyle(LinearGradient(
                                            colors: [AppColors.cyan,
                                                     AppColors.purple,
                                                     AppColors.magenta],
                                            startPoint: .leading,
                                            endPoint: .trailing)))
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(colorScheme == .light
                                        ? AnyShapeStyle(LinearGradient(
                                            colors: [AppColors.magenta,
                                                     AppColors.gold],
                                            startPoint: .leading,
                                            endPoint: .trailing))
                                        : AnyShapeStyle(Color.clear),
                                        lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 20)
                }
                .padding(20)
            }
            .background((colorScheme == .light
                ? AppColors.lightPageBg
                : AppColors.pageBg).ignoresSafeArea())
            .navigationTitle("How did that land?")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func pillSheetSection(title: String,
                                   pills: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(AppFonts.overline)
                .tracking(1.2)
                .foregroundStyle(colorScheme == .light
                    ? AppColors.lightTextTertiary
                    : AppColors.textTertiary)

            LazyVGrid(
                columns: Array(repeating:
                    GridItem(.flexible(), spacing: 8), count: 2),
                spacing: 8
            ) {
                ForEach(pills, id: \.self) { pill in
                    bannerPillButton(pill)
                }
            }
        }
    }

    private func dismiss() {
        withAnimation(.spring(response: 0.35,
                               dampingFraction: 0.8)) {
            onDismiss?()
        }
    }
}

```

---

## File: `Open Lightly/Features/Home/Components/ReflectionCard.swift` {#file-open-lightly-features-home-components-reflectioncard-swift}

```swift
// Home/Components/ReflectionCard.swift

import SwiftUI

struct ReflectionCard: View {
    let state: ReflectionCardState
    var onMoreTap: (() -> Void)? = nil
    var onDone: (([String], String?) -> Void)? = nil

    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedPills: Set<String> = []
    @State private var noteText: String = ""
    @State private var isWritingNote: Bool = false
    @State private var showFullPillSheet: Bool = false
    @State private var shareWithPartner: Bool = true

    var body: some View {
        switch state {
        case .hidden:
            EmptyView()

        case .pendingYours(let sessionLabel, let sessionDate):
            pendingCard(sessionLabel: sessionLabel,
                        sessionDate: sessionDate)

        case .waitingOnPartner(let sessionLabel, let yourPills):
            waitingCard(sessionLabel: sessionLabel,
                        yourPills: yourPills)

        case .bothReflected(let sessionLabel,
                            let yourName, let yourPills, let yourNote,
                            let partnerName, let partnerPills,
                            let partnerNote, let swipePosition):
            bothReflectedCard(
                sessionLabel: sessionLabel,
                yourName: yourName, yourPills: yourPills,
                yourNote: yourNote,
                partnerName: partnerName,
                partnerPills: partnerPills,
                partnerNote: partnerNote,
                swipePosition: swipePosition
            )

        case .summary(let arc, let yourName, let yourDots,
                      let partnerName, let partnerDots,
                      let swipePosition):
            summaryCard(
                arc: arc,
                yourName: yourName, yourDots: yourDots,
                partnerName: partnerName, partnerDots: partnerDots,
                swipePosition: swipePosition
            )
        }
    }

    // MARK: - Pending State

    private func pendingCard(sessionLabel: String,
                              sessionDate: Date) -> some View {
        cardShell {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(sessionLabel)
                            .font(AppFonts.overline)
                            .tracking(1.2)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.lightTextTertiary
                                : AppColors.textTertiary)
                        Text(sessionDate.relativeString)
                            .font(AppFonts.caption)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.lightTextTertiary
                                : AppColors.textTertiary)
                    }
                    Spacer()
                }

                Text("How did that land?")
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextPrimary
                        : AppColors.textPrimary)

                if isWritingNote {
                    // Journal mode
                    TextEditor(text: $noteText)
                        .frame(minHeight: 80)
                        .font(AppFonts.bodyText)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightTextPrimary
                            : AppColors.textPrimary)
                        .scrollContentBackground(.hidden)
                        .padding(10)
                        .background {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(colorScheme == .light
                                    ? Color.black.opacity(0.03)
                                    : Color.white.opacity(0.04))
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(colorScheme == .light
                                    ? AppColors.lightBorder
                                    : AppColors.border,
                                    lineWidth: 1)
                        }
                } else {
                    // Pill row — 5 inline defaults
                    LazyVGrid(
                        columns: Array(repeating:
                            GridItem(.flexible(), spacing: 8), count: 3),
                        spacing: 8
                    ) {
                        ForEach(ReflectionPillGroup.inlineDefault,
                                id: \.self) { pill in
                            pillButton(pill)
                        }
                    }

                    HStack {
                        Button {
                            showFullPillSheet = true
                        } label: {
                            Text("More →")
                                .font(AppFonts.caption)
                                .foregroundStyle(colorScheme == .light
                                    ? AppColors.magenta
                                    : AppColors.cyanLight)
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                }

                // Switch mode link
                Button {
                    isWritingNote.toggle()
                } label: {
                    Text(isWritingNote
                         ? "← Use pills instead"
                         : "✎ Write a note instead")
                        .font(AppFonts.caption)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightTextTertiary
                            : AppColors.textTertiary)
                }
                .buttonStyle(.plain)

                // Share toggle
                HStack {
                    Text("Share with partner")
                        .font(AppFonts.caption)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightTextSecondary
                            : AppColors.textSecondary)
                    Spacer()
                    Toggle("", isOn: $shareWithPartner)
                        .labelsHidden()
                        .tint(colorScheme == .light
                            ? AppColors.magenta
                            : AppColors.cyan)
                }

                // Done + Not now
                HStack {
                    Button("Not now") {}
                        .font(AppFonts.caption)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightTextTertiary
                            : AppColors.textTertiary)
                        .buttonStyle(.plain)

                    Spacer()

                    Button {
                        UIImpactFeedbackGenerator(style: .medium)
                            .impactOccurred()
                        onDone?(Array(selectedPills),
                                noteText.isEmpty ? nil : noteText)
                    } label: {
                        Text("Done")
                            .font(AppFonts.ctaLabel)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.wineDark
                                : .white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background {
                                Capsule()
                                    .fill(colorScheme == .light
                                        ? AnyShapeStyle(LinearGradient(
                                            colors: [AppColors.magenta.opacity(0.18),
                                                     AppColors.gold.opacity(0.14)],
                                            startPoint: .leading,
                                            endPoint: .trailing))
                                        : AnyShapeStyle(LinearGradient(
                                            colors: [AppColors.cyan,
                                                     AppColors.purple,
                                                     AppColors.magenta],
                                            startPoint: .leading,
                                            endPoint: .trailing)))
                            }
                            .overlay {
                                Capsule()
                                    .stroke(colorScheme == .light
                                        ? AnyShapeStyle(LinearGradient(
                                            colors: [AppColors.magenta,
                                                     AppColors.gold],
                                            startPoint: .leading,
                                            endPoint: .trailing))
                                        : AnyShapeStyle(Color.clear),
                                        lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedPills.isEmpty && noteText.isEmpty)
                    .opacity(selectedPills.isEmpty
                             && noteText.isEmpty ? 0.4 : 1)
                }
            }
            .padding(18)
        }
        .sheet(isPresented: $showFullPillSheet) {
            fullPillSheet
        }
    }

    // MARK: - Waiting State

    private func waitingCard(sessionLabel: String,
                              yourPills: [String]) -> some View {
        cardShell {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(sessionLabel)
                        .font(AppFonts.overline)
                        .tracking(1.2)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightTextTertiary
                            : AppColors.textTertiary)
                    Spacer()
                    // Status dots
                    HStack(spacing: 4) {
                        Circle().fill(colorScheme == .light
                            ? AppColors.magenta
                            : AppColors.cyan)
                            .frame(width: 7, height: 7)
                        Circle().stroke(colorScheme == .light
                            ? AppColors.lightTextTertiary
                            : AppColors.textTertiary,
                            lineWidth: 1)
                            .frame(width: 7, height: 7)
                    }
                }

                Text("You reflected.")
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextPrimary
                        : AppColors.textPrimary)

                // Your pills read-only
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(yourPills, id: \.self) { pill in
                            Text(pill)
                                .font(AppFonts.caption)
                                .foregroundStyle(colorScheme == .light
                                    ? AppColors.lightTextPrimary
                                    : AppColors.textPrimary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background {
                                    Capsule()
                                        .fill(colorScheme == .light
                                            ? AnyShapeStyle(LinearGradient(
                                                colors: [AppColors.magenta.opacity(0.12),
                                                         AppColors.gold.opacity(0.10)],
                                                startPoint: .leading,
                                                endPoint: .trailing))
                                            : AnyShapeStyle(LinearGradient(
                                                colors: [AppColors.cyan.opacity(0.2),
                                                         AppColors.purple.opacity(0.15)],
                                                startPoint: .leading,
                                                endPoint: .trailing)))
                                }
                        }
                    }
                }

                Text("Waiting for your partner.")
                    .font(AppFonts.caption)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextTertiary
                        : AppColors.textTertiary)

                cardFooter
            }
            .padding(18)
        }
    }

    // MARK: - Both Reflected State

    private func bothReflectedCard(
        sessionLabel: String,
        yourName: String, yourPills: [String], yourNote: String?,
        partnerName: String, partnerPills: [String], partnerNote: String?,
        swipePosition: Int
    ) -> some View {
        cardShell {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(sessionLabel)
                        .font(AppFonts.overline)
                        .tracking(1.2)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightTextTertiary
                            : AppColors.textTertiary)
                    Spacer()
                    HStack(spacing: 4) {
                        Circle().fill(colorScheme == .light
                            ? AppColors.magenta
                            : AppColors.cyan)
                            .frame(width: 7, height: 7)
                        Circle().fill(colorScheme == .light
                            ? AppColors.gold
                            : AppColors.purple)
                            .frame(width: 7, height: 7)
                    }
                }

                // Your section
                VStack(alignment: .leading, spacing: 6) {
                    Text(yourName.uppercased())
                        .font(AppFonts.overline)
                        .tracking(1.0)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightTextTertiary
                            : AppColors.textTertiary)
                    pillsReadOnly(yourPills,
                                  color: colorScheme == .light
                                      ? AppColors.magenta
                                      : AppColors.cyan)
                    if let note = yourNote {
                        Text("\"\(note)\"")
                            .font(AppFonts.bodyText)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.lightTextSecondary
                                : AppColors.textSecondary)
                            .italic()
                            .lineLimit(2)
                    }
                }

                Rectangle()
                    .fill(colorScheme == .light
                        ? Color.black.opacity(0.06)
                        : Color.white.opacity(0.06))
                    .frame(height: 1)

                // Partner section
                VStack(alignment: .leading, spacing: 6) {
                    Text(partnerName.uppercased())
                        .font(AppFonts.overline)
                        .tracking(1.0)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightTextTertiary
                            : AppColors.textTertiary)
                    pillsReadOnly(partnerPills,
                                  color: colorScheme == .light
                                      ? AppColors.gold
                                      : AppColors.purple)
                    if let note = partnerNote {
                        Text("\"\(note)\"")
                            .font(AppFonts.bodyText)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.lightTextSecondary
                                : AppColors.textSecondary)
                            .italic()
                            .lineLimit(2)
                    }
                }

                cardFooter
            }
            .padding(18)
        }
    }

    // MARK: - Summary State

    private func summaryCard(
        arc: String,
        yourName: String, yourDots: [Bool],
        partnerName: String, partnerDots: [Bool],
        swipePosition: Int
    ) -> some View {
        cardShell {
            VStack(alignment: .leading, spacing: 12) {
                // Dot header
                HStack(spacing: 5) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(i < yourDots.count && yourDots[i]
                                  ? (colorScheme == .light
                                      ? AppColors.magenta
                                      : AppColors.cyan)
                                  : Color.clear)
                            .overlay {
                                if !(i < yourDots.count && yourDots[i]) {
                                    Circle()
                                        .stroke(colorScheme == .light
                                            ? AppColors.lightTextTertiary
                                            : AppColors.textTertiary,
                                            lineWidth: 1)
                                }
                            }
                            .frame(width: 7, height: 7)
                    }
                    Text("Last 3 sessions")
                        .font(AppFonts.caption)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightTextTertiary
                            : AppColors.textTertiary)
                        .padding(.leading, 4)
                }

                // Arc copy
                Text(arc)
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextPrimary
                        : AppColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                // Timeline rows
                VStack(alignment: .leading, spacing: 4) {
                    timelineRow(name: yourName, dots: yourDots)
                    timelineRow(name: partnerName, dots: partnerDots)
                }

                cardFooter
            }
            .padding(18)
        }
    }

    // MARK: - Full Pill Sheet

    private var fullPillSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    pillSection(
                        title: "HOW IT FELT",
                        pills: ReflectionPillGroup.howItFelt
                    )
                    pillSection(
                        title: "WHAT HAPPENED",
                        pills: ReflectionPillGroup.whatHappened
                    )
                    pillSection(
                        title: "WHAT YOU NEED NOW",
                        pills: ReflectionPillGroup.whatYouNeedNow
                    )

                    // Optional note
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ADD A NOTE")
                            .font(AppFonts.overline)
                            .tracking(1.2)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.lightTextTertiary
                                : AppColors.textTertiary)

                        TextEditor(text: $noteText)
                            .frame(minHeight: 80)
                            .font(AppFonts.bodyText)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.lightTextPrimary
                                : AppColors.textPrimary)
                            .scrollContentBackground(.hidden)
                            .padding(10)
                            .background {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(colorScheme == .light
                                        ? Color.black.opacity(0.03)
                                        : Color.white.opacity(0.04))
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(colorScheme == .light
                                        ? AppColors.lightBorder
                                        : AppColors.border,
                                        lineWidth: 1)
                            }
                    }

                    // Share toggle
                    HStack {
                        Text("Share with partner")
                            .font(AppFonts.bodyText)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.lightTextSecondary
                                : AppColors.textSecondary)
                        Spacer()
                        Toggle("", isOn: $shareWithPartner)
                            .labelsHidden()
                            .tint(colorScheme == .light
                                ? AppColors.magenta
                                : AppColors.cyan)
                    }

                    Button {
                        showFullPillSheet = false
                        onDone?(Array(selectedPills),
                                noteText.isEmpty ? nil : noteText)
                    } label: {
                        Text("Done")
                            .font(AppFonts.ctaLabel)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.wineDark
                                : .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(colorScheme == .light
                                        ? AnyShapeStyle(LinearGradient(
                                            colors: [AppColors.magenta.opacity(0.18),
                                                     AppColors.gold.opacity(0.14)],
                                            startPoint: .leading,
                                            endPoint: .trailing))
                                        : AnyShapeStyle(LinearGradient(
                                            colors: [AppColors.cyan,
                                                     AppColors.purple,
                                                     AppColors.magenta],
                                            startPoint: .leading,
                                            endPoint: .trailing)))
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(colorScheme == .light
                                        ? AnyShapeStyle(LinearGradient(
                                            colors: [AppColors.magenta,
                                                     AppColors.gold],
                                            startPoint: .leading,
                                            endPoint: .trailing))
                                        : AnyShapeStyle(Color.clear),
                                        lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 20)
                }
                .padding(20)
            }
            .background((colorScheme == .light
                ? AppColors.lightPageBg
                : AppColors.pageBg).ignoresSafeArea())
            .navigationTitle("How did that land?")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func pillSection(title: String,
                              pills: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(AppFonts.overline)
                .tracking(1.2)
                .foregroundStyle(colorScheme == .light
                    ? AppColors.lightTextTertiary
                    : AppColors.textTertiary)

            LazyVGrid(
                columns: Array(repeating:
                    GridItem(.flexible(), spacing: 8), count: 2),
                spacing: 8
            ) {
                ForEach(pills, id: \.self) { pill in
                    pillButton(pill)
                }
            }
        }
    }

    // MARK: - Shared Subviews

    private func pillButton(_ pill: String) -> some View {
        let isSelected = selectedPills.contains(pill)
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            if isSelected {
                selectedPills.remove(pill)
            } else {
                selectedPills.insert(pill)
            }
        } label: {
            Text(pill)
                .font(AppFonts.caption)
                .foregroundStyle(isSelected
                    ? (colorScheme == .light
                        ? AppColors.wineDark
                        : .white)
                    : (colorScheme == .light
                        ? AppColors.lightTextSecondary
                        : AppColors.textSecondary))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(colorScheme == .light
                                ? AnyShapeStyle(LinearGradient(
                                    colors: [AppColors.magenta.opacity(0.15),
                                             AppColors.gold.opacity(0.12)],
                                    startPoint: .leading,
                                    endPoint: .trailing))
                                : AnyShapeStyle(LinearGradient(
                                    colors: [AppColors.cyan.opacity(0.4),
                                             AppColors.purple.opacity(0.3)],
                                    startPoint: .leading,
                                    endPoint: .trailing)))
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.clear)
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isSelected
                            ? (colorScheme == .light
                                ? AnyShapeStyle(LinearGradient(
                                    colors: [AppColors.magenta, AppColors.gold],
                                    startPoint: .leading, endPoint: .trailing))
                                : AnyShapeStyle(LinearGradient(
                                    colors: [AppColors.cyan, AppColors.purple],
                                    startPoint: .leading, endPoint: .trailing)))
                            : AnyShapeStyle(colorScheme == .light
                                ? AppColors.lightBorder
                                : AppColors.border),
                            lineWidth: 1
                        )
                }
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    private func pillsReadOnly(_ pills: [String],
                                color: Color) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(pills, id: \.self) { pill in
                    Text(pill)
                        .font(AppFonts.caption)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightTextPrimary
                            : AppColors.textPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background {
                            Capsule()
                                .fill(color.opacity(0.15))
                        }
                        .overlay {
                            Capsule()
                                .stroke(color.opacity(0.3),
                                        lineWidth: 1)
                        }
                }
            }
        }
    }

    private func timelineRow(name: String,
                              dots: [Bool]) -> some View {
        HStack(spacing: 6) {
            Text(name)
                .font(AppFonts.caption)
                .foregroundStyle(colorScheme == .light
                    ? AppColors.lightTextTertiary
                    : AppColors.textTertiary)
                .frame(width: 60, alignment: .leading)

            Text("──")
                .font(.system(size: 9))
                .foregroundStyle(colorScheme == .light
                    ? AppColors.lightTextTertiary
                    : AppColors.textTertiary)

            ForEach(0..<dots.count, id: \.self) { i in
                if dots[i] {
                    Circle().fill(colorScheme == .light
                        ? AppColors.magenta
                        : AppColors.cyan)
                        .frame(width: 7, height: 7)
                } else {
                    Circle()
                        .stroke(colorScheme == .light
                            ? AppColors.lightTextTertiary
                            : AppColors.textTertiary,
                            lineWidth: 1)
                        .frame(width: 7, height: 7)
                }
                if i < dots.count - 1 {
                    Text("──")
                        .font(.system(size: 9))
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightTextTertiary
                            : AppColors.textTertiary)
                }
            }
        }
    }

    private var cardFooter: some View {
        HStack {
            Spacer()
            Button {
                onMoreTap?()
            } label: {
                Text("More ↗")
                    .font(AppFonts.caption)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.magenta
                        : AppColors.cyanLight)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func cardShell<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .light
                        ? AppColors.lightFrostCard
                        : AppColors.cardBg)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(colorScheme == .light
                        ? AppColors.lightBorder
                        : AppColors.border,
                        lineWidth: 1)
            }
    }
}

// MARK: - Date Extension

private extension Date {
    var relativeString: String {
        let days = Calendar.current.dateComponents(
            [.day], from: self, to: Date()
        ).day ?? 0
        switch days {
        case 0:  return "Today"
        case 1:  return "Yesterday"
        case 2:  return "Two days ago"
        default:
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return "Last \(formatter.string(from: self))"
        }
    }
}

```

---

## File: `Open Lightly/Features/Home/Components/ResearchTicker.swift` {#file-open-lightly-features-home-components-researchticker-swift}

```swift
// Home/Components/ResearchTicker.swift

import SwiftUI

struct ResearchTicker: View {
    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }

    private let facts: [ResearchFact] = [
        ResearchFact(category: .research,
            body: "1 in 5 Americans has engaged in CNM\nat some point in their lives.",
            attribution: "— Haupert et al., 2017"),
        ResearchFact(category: .research,
            body: "Communication quality is measurably higher\nin CNM relationships. The structure demands it.",
            attribution: "— Rubel & Bogaert, 2015"),
        ResearchFact(category: .research,
            body: "The biggest predictor of success isn't\ncompatibility — it's whether both people\ngenuinely chose this.",
            attribution: "— Rubel & Bogaert, 2015"),
        ResearchFact(category: .definition,
            body: "Compersion: feeling joy at your partner's\nhappiness with someone else.",
            attribution: nil),
        ResearchFact(category: .definition,
            body: "NRE — New Relationship Energy:\nthe heightened feeling of a new connection.\nReal, temporary, manageable.",
            attribution: nil),
        ResearchFact(category: .definition,
            body: "Metamour: your partner's partner.\nSomeone you may never meet — or become\nclose friends with.",
            attribution: nil),
        ResearchFact(category: .reframe,
            body: "Jealousy is information,\nnot evidence that something is wrong.",
            attribution: nil),
        ResearchFact(category: .reframe,
            body: "Most people who explore CNM\nweren't unhappy. They were curious.",
            attribution: nil),
        ResearchFact(category: .research,
            body: "People who live in alignment with their\nactual desires report lower anxiety —\nregardless of what those desires are.",
            attribution: "— Moors et al., 2017"),
        ResearchFact(category: .reframe,
            body: "Sexual and romantic attraction are\nindependent dimensions. Both matter.\nNeither determines the other.",
            attribution: "— Diamond, 2003"),
    ]

    @State private var currentIndex: Int = 0
    @State private var opacity: Double = 1.0

    private let displayDuration: TimeInterval = 10
    private let fadeDuration: TimeInterval = 0.4

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            // Top separator
            Rectangle()
                .fill(isLight
                    ? Color.black.opacity(0.06)
                    : Color.white.opacity(0.06))
                .frame(height: 1)

            VStack(alignment: .leading, spacing: 4) {
                // Overline
                Text(facts[currentIndex].category.overlineLabel)
                    .font(AppFonts.overline)
                    .tracking(1.2)
                    .foregroundStyle(isLight
                        ? AppColors.lightTextTertiary
                        : AppColors.textTertiary)

                // Body
                Text(facts[currentIndex].body)
                    .font(AppFonts.bodyText)
                    .foregroundStyle(isLight
                        ? AppColors.lightTextSecondary
                        : AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(3)

                // Attribution if exists
                if let attribution = facts[currentIndex].attribution {
                    Text(attribution)
                        .font(AppFonts.caption)
                        .foregroundStyle(isLight
                            ? AppColors.lightTextTertiary
                            : AppColors.textTertiary)
                }
            }
            .opacity(opacity)
            .padding(.vertical, 14)

            // Bottom separator
            Rectangle()
                .fill(isLight
                    ? Color.black.opacity(0.06)
                    : Color.white.opacity(0.06))
                .frame(height: 1)
        }
        .padding(.horizontal, 24)
        .allowsHitTesting(false)
        .onAppear {
            startCycle()
        }
    }

    private func startCycle() {
        Timer.scheduledTimer(withTimeInterval: displayDuration,
                             repeats: true) { _ in
            // Fade out
            withAnimation(.easeInOut(duration: fadeDuration)) {
                opacity = 0
            }
            // Swap fact + fade in
            DispatchQueue.main.asyncAfter(
                deadline: .now() + fadeDuration + 0.1
            ) {
                currentIndex = (currentIndex + 1) % facts.count
                withAnimation(.easeInOut(duration: fadeDuration)) {
                    opacity = 1
                }
            }
        }
    }
}

#Preview("Ticker Dark") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        ResearchTicker()
    }
    .preferredColorScheme(.dark)
}

#Preview("Ticker Light") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        ResearchTicker()
    }
    .preferredColorScheme(.light)
}

```

---

## File: `Open Lightly/Features/Home/Components/SessionCard.swift` {#file-open-lightly-features-home-components-sessioncard-swift}

```swift
// Home/Components/SessionCard.swift

import SwiftUI

struct SessionCard: View {
    let state: SessionCardState
    var onContinue: (() -> Void)? = nil
    var onRemindPartner: (() -> Void)? = nil
    var onGoToLearn: (() -> Void)? = nil

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            switch state {
            case .dayZero:
                dayZeroContent
            case .midDeck(let completed, let total, let prompt):
                midDeckContent(completed: completed,
                               total: total,
                               prompt: prompt)
            case .deckComplete(let stageName, let stageIndex,
                               let nextName, let nextCards):
                deckCompleteContent(stageName: stageName,
                                    stageIndex: stageIndex,
                                    nextStageName: nextName,
                                    nextStageCards: nextCards)
            case .waitingOnPartner(let name, let completed, let total):
                waitingContent(partnerName: name,
                               completed: completed,
                               total: total)
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(colorScheme == .light
                    ? AppColors.lightCardFill
                    : AppColors.cardBg)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    colorScheme == .light
                        ? AnyShapeStyle(
                            AppColors.warmAuroraBorder.opacity(0.5))
                        : AnyShapeStyle(LinearGradient(
                            colors: [
                                AppColors.cyan.opacity(0.4),
                                AppColors.purple.opacity(0.3),
                                AppColors.magenta.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          )),
                    lineWidth: 1.5
                )
        }
        .shadow(
            color: colorScheme == .light
                ? AppColors.lightShadowPurple
                : AppColors.purple.opacity(0.12),
            radius: 20, y: 6
        )
    }

    // MARK: - Day Zero

    private var dayZeroContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            cardHeader(overline: "STAGE 1 · CURIOSITY",
                       stageName: "Curiosity")
                .padding(.horizontal, 20)
                .padding(.top, 20)

            Spacer(minLength: 16)

            promptPreview(
                label: "FIRST PROMPT",
                text: "What's one thing about non-monogamy that excites you most? Just one."
            )

            Spacer(minLength: 16)

            ctaButton(label: "Start Your First Session",
                      action: onContinue)
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
        }
    }

    // MARK: - Mid Deck

    private func midDeckContent(completed: Int,
                                 total: Int,
                                 prompt: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                cardHeader(overline: "STAGE 1 · CURIOSITY",
                           stageName: "Foundation Conversations")

                // Progress bar
                HStack(spacing: 10) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(colorScheme == .light
                                    ? Color.black.opacity(0.08)
                                    : Color.white.opacity(0.12))
                                .frame(height: 3)

                            let ratio = total > 0
                                ? CGFloat(completed) / CGFloat(total)
                                : 0

                            Capsule()
                                .fill(colorScheme == .light
                                    ? AnyShapeStyle(LinearGradient(
                                        colors: [AppColors.magenta,
                                                 AppColors.gold],
                                        startPoint: .leading,
                                        endPoint: .trailing))
                                    : AnyShapeStyle(LinearGradient(
                                        colors: [AppColors.cyan,
                                                 AppColors.purple,
                                                 AppColors.magenta],
                                        startPoint: .leading,
                                        endPoint: .trailing)))
                                .frame(width: geo.size.width * ratio,
                                       height: 3)
                                .animation(.easeInOut(duration: 0.6),
                                           value: completed)
                        }
                    }
                    .frame(height: 3)

                    Text("\(completed) of \(total)")
                        .font(AppFonts.caption)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightTextTertiary
                            : AppColors.textTertiary)
                        .fixedSize()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            Spacer(minLength: 16)

            promptPreview(label: "NEXT PROMPT", text: prompt)

            Spacer(minLength: 16)

            ctaButton(label: "Continue Session",
                      action: onContinue)
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
        }
    }

    // MARK: - Deck Complete

    private func deckCompleteContent(stageName: String,
                                      stageIndex: Int,
                                      nextStageName: String,
                                      nextStageCards: Int) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Completion header
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(colorScheme == .light
                        ? AnyShapeStyle(LinearGradient(
                            colors: [AppColors.magenta, AppColors.gold],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing))
                        : AnyShapeStyle(LinearGradient(
                            colors: [AppColors.cyan, AppColors.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing)))

                Text("STAGE \(stageIndex) COMPLETE")
                    .font(AppFonts.overline)
                    .tracking(1.5)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextTertiary
                        : AppColors.textTertiary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            Text("You finished \(stageName).")
                .font(AppFonts.bodyMedium)
                .foregroundStyle(colorScheme == .light
                    ? AppColors.lightTextPrimary
                    : AppColors.textPrimary)
                .padding(.horizontal, 20)
                .padding(.top, 8)

            // Divider
            Rectangle()
                .fill(colorScheme == .light
                    ? Color.black.opacity(0.06)
                    : Color.white.opacity(0.06))
                .frame(height: 1)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

            // Next stage
            VStack(alignment: .leading, spacing: 6) {
                Text("STAGE \(stageIndex + 1) · \(nextStageName.uppercased())")
                    .font(AppFonts.overline)
                    .tracking(1.5)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextTertiary
                        : AppColors.textTertiary)

                Text(nextStageName)
                    .font(AppFonts.cardTitle)
                    .foregroundStyle(colorScheme == .light
                        ? AnyShapeStyle(LinearGradient(
                            colors: [AppColors.magenta, AppColors.gold],
                            startPoint: .leading,
                            endPoint: .trailing))
                        : AnyShapeStyle(LinearGradient(
                            colors: [AppColors.cyan, AppColors.purple],
                            startPoint: .leading,
                            endPoint: .trailing)))

                Text("\(nextStageCards) cards · When you're ready")
                    .font(AppFonts.caption)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextTertiary
                        : AppColors.textTertiary)
            }
            .padding(.horizontal, 20)

            Spacer(minLength: 16)

            ctaButton(label: "Start Stage \(stageIndex + 1)",
                      action: onContinue)
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
        }
    }

    // MARK: - Waiting on Partner

    private func waitingContent(partnerName: String,
                                 completed: Int,
                                 total: Int) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                cardHeader(overline: "STAGE 1 · CURIOSITY",
                           stageName: "Foundation Conversations")

                // Progress bar
                HStack(spacing: 10) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(colorScheme == .light
                                    ? Color.black.opacity(0.08)
                                    : Color.white.opacity(0.12))
                                .frame(height: 3)

                            let ratio = total > 0
                                ? CGFloat(completed) / CGFloat(total)
                                : 0

                            Capsule()
                                .fill(colorScheme == .light
                                    ? AnyShapeStyle(LinearGradient(
                                        colors: [AppColors.magenta,
                                                 AppColors.gold],
                                        startPoint: .leading,
                                        endPoint: .trailing))
                                    : AnyShapeStyle(LinearGradient(
                                        colors: [AppColors.cyan,
                                                 AppColors.purple,
                                                 AppColors.magenta],
                                        startPoint: .leading,
                                        endPoint: .trailing)))
                                .frame(width: geo.size.width * ratio,
                                       height: 3)
                        }
                    }
                    .frame(height: 3)

                    Text("\(completed) of \(total)")
                        .font(AppFonts.caption)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightTextTertiary
                            : AppColors.textTertiary)
                        .fixedSize()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            Text("\(partnerName) isn't ready yet")
                .font(AppFonts.bodyText)
                .foregroundStyle(colorScheme == .light
                    ? AppColors.lightTextSecondary
                    : AppColors.textSecondary)
                .padding(.horizontal, 20)
                .padding(.top, 12)

            Spacer(minLength: 16)

            // Two CTAs
            HStack(spacing: 10) {
                // Outlined remind button
                Button {
                    UIImpactFeedbackGenerator(style: .light)
                        .impactOccurred()
                    onRemindPartner?()
                } label: {
                    Text("Remind \(partnerName)")
                        .font(AppFonts.ctaLabel)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightTextSecondary
                            : AppColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(colorScheme == .light
                                    ? AppColors.lightBorder
                                    : AppColors.border,
                                    lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)

                // Filled learn button
                Button {
                    UIImpactFeedbackGenerator(style: .medium)
                        .impactOccurred()
                    onGoToLearn?()
                } label: {
                    Text("Go to Learn")
                        .font(AppFonts.ctaLabel)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.wineDark
                            : AppColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colorScheme == .light
                                    ? AnyShapeStyle(LinearGradient(
                                        colors: [AppColors.magenta.opacity(0.12),
                                                 AppColors.gold.opacity(0.10)],
                                        startPoint: .leading,
                                        endPoint: .trailing))
                                    : AnyShapeStyle(LinearGradient(
                                        colors: [AppColors.cyan.opacity(0.2),
                                                 AppColors.purple.opacity(0.15)],
                                        startPoint: .leading,
                                        endPoint: .trailing)))
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(colorScheme == .light
                                    ? AnyShapeStyle(LinearGradient(
                                        colors: [AppColors.magenta,
                                                 AppColors.gold],
                                        startPoint: .leading,
                                        endPoint: .trailing))
                                    : AnyShapeStyle(LinearGradient(
                                        colors: [AppColors.cyan,
                                                 AppColors.purple],
                                        startPoint: .leading,
                                        endPoint: .trailing)),
                                    lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Shared Subviews

    private func cardHeader(overline: String,
                             stageName: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(overline)
                .font(AppFonts.overline)
                .tracking(1.5)
                .foregroundStyle(colorScheme == .light
                    ? AppColors.lightTextTertiary
                    : AppColors.textTertiary)

            Text(stageName)
                .font(AppFonts.cardTitle)
                .foregroundStyle(colorScheme == .light
                    ? AnyShapeStyle(LinearGradient(
                        colors: [AppColors.magenta, AppColors.gold],
                        startPoint: .leading,
                        endPoint: .trailing))
                    : AnyShapeStyle(LinearGradient(
                        colors: [AppColors.cyan, AppColors.purple],
                        startPoint: .leading,
                        endPoint: .trailing)))
        }
    }

    private func promptPreview(label: String,
                                text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(AppFonts.overline)
                .tracking(1.5)
                .foregroundStyle(colorScheme == .light
                    ? AppColors.lightTextTertiary
                    : AppColors.textTertiary)
                .padding(.horizontal, 20)

            Text("\"\(text)\"")
                .font(AppFonts.bodyMedium)
                .foregroundStyle(colorScheme == .light
                    ? AppColors.lightTextSecondary
                    : AppColors.textSecondary)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(colorScheme == .light
                            ? Color.black.opacity(0.03)
                            : Color.white.opacity(0.04))
                }
                .padding(.horizontal, 16)
        }
    }

    private func ctaButton(label: String,
                            action: (() -> Void)?) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action?()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "play.fill")
                    .font(.system(size: 13, weight: .semibold))
                Text(label)
                    .font(AppFonts.ctaLabel)
            }
            .foregroundStyle(colorScheme == .light
                ? AppColors.wineDark
                : AppColors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(colorScheme == .light
                        ? AnyShapeStyle(AppColors.lightFrostCTA)
                        : AnyShapeStyle(LinearGradient(
                            colors: [AppColors.cyan.opacity(0.15),
                                     AppColors.purple.opacity(0.12)],
                            startPoint: .leading,
                            endPoint: .trailing)))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(colorScheme == .light
                        ? AnyShapeStyle(LinearGradient(
                            colors: [AppColors.magenta,
                                     AppColors.gold],
                            startPoint: .leading,
                            endPoint: .trailing))
                        : AnyShapeStyle(LinearGradient(
                            colors: [AppColors.cyan,
                                     AppColors.purple,
                                     AppColors.magenta],
                            startPoint: .leading,
                            endPoint: .trailing)),
                        lineWidth: 1.5)
            }
            .shadow(color: colorScheme == .light
                ? AppColors.lightShadowMagenta
                : AppColors.cyan.opacity(0.15),
                    radius: 10, y: 4)
        }
        .buttonStyle(.plain)
    }
}

```

---

## File: `Open Lightly/Features/Home/Models/HomeEventEngine.swift` {#file-open-lightly-features-home-models-homeeventengine-swift}

```swift
// Home/Models/HomeEventEngine.swift
//
// Pure logic struct. No views. Takes app state, returns one String.
// Priority: partner events → milestones → time/absence → stage defaults

import Foundation

struct HomeEventEngine {

    // MARK: - Public Interface

    /// Returns the two-line-max sub-copy for the greeting block.
    /// Priority: partner events → milestones → time/absence → stage defaults
    static func oneLiner(
        events: [HomeEvent],
        stageIndex: Int,
        cardsCompleted: Int,
        isSolo: Bool,
        partnerName: String?
    ) -> String {

        let partner = partnerName ?? "your partner"

        // PRIORITY 1 — Partner events
        for event in events {
            switch event {
            case .partnerCompletedDesireMap(let name):
                return "\(name) just finished their map.\nYou're both ready."
            case .partnerReflected(let name, let day):
                return "\(name) reflected on \(day)'s session.\nYour turn when you're ready."
            case .mutualReflectRevealReady:
                return "You both reflected.\nSee what you each said."
            default:
                continue
            }
        }

        // PRIORITY 2 — Milestone events
        for event in events {
            switch event {
            case .bothSawFreeReveal:
                return "You saw your first match together.\nThat's where it starts."
            case .fullMapUnlocked:
                return "The full picture is yours now."
            case .stageCompleted(let name):
                return "You finished \(name).\nTake that in."
            case .stageUnlocked(let index):
                return "Stage \(index) just opened up.\nWhen you're ready."
            case .firstSessionCompleted:
                return "You did your first session.\nThe first one matters most."
            case .firstMutualReflection:
                return "You both reflected on that session.\nThat's more than most."
            default:
                continue
            }
        }

        // PRIORITY 3 — Time / absence events
        for event in events {
            switch event {
            case .daysSinceSession(let days, let name):
                if days >= 3 && days <= 7 {
                    return "No rush.\nIt'll be here when you're ready."
                } else if days >= 8 && days <= 14 {
                    if isSolo {
                        return "Take it at your own pace."
                    } else {
                        return "It's been a little while.\n\(name ?? partner) is ready when you are."
                    }
                } else if days >= 15 {
                    return "It's still here.\nNothing lost."
                }
            case .threeOpensNoSession:
                return "Just looking around is fine too."
            default:
                continue
            }
        }

        // PRIORITY 4 — Stage defaults
        if stageIndex == 0 || (stageIndex == 1 && cardsCompleted == 0) {
            if events.isEmpty {
                return "Take your time looking around."
            }
            return isSolo
                ? "Start when you're ready."
                : "Start when you're both ready."
        }

        switch stageIndex {
        case 1:
            return "Your first deck is waiting."
        case 2:
            return "You've started something real."
        case 3, 4:
            return "You're building real momentum."
        case 5, 6, 7:
            return "You've come a long way."
        default:
            return "Most couples never get here."
        }
    }
}

```

---

## File: `Open Lightly/Features/Home/Models/HomeModels.swift` {#file-open-lightly-features-home-models-homemodels-swift}

```swift
// Home/Models/HomeModels.swift
//
// View-layer structs and enums for the Home screen.
// No business logic. No SwiftData. Placeholder-ready.

import SwiftUI

// MARK: - Session Card State

enum SessionCardState {
    case dayZero
    case midDeck(completed: Int, total: Int, nextPrompt: String)
    case deckComplete(stageName: String, stageIndex: Int,
                      nextStageName: String, nextStageCards: Int)
    case waitingOnPartner(partnerName: String,
                          completed: Int, total: Int)
}

// MARK: - Desire Map State

enum DesireMapState {
    case hidden
    case youDone(partnerName: String)
    case bothReady
    case freeRevealSeen(partnerName: String)
    case fullyUnlocked
    case redoInProgress(partnerName: String, partnerStarted: Bool)
}

// MARK: - Reflection Card State

enum ReflectionCardState {
    case hidden
    case pendingYours(sessionLabel: String, sessionDate: Date)
    case waitingOnPartner(sessionLabel: String,
                          yourPills: [String])
    case bothReflected(sessionLabel: String,
                       yourName: String,
                       yourPills: [String],
                       yourNote: String?,
                       partnerName: String,
                       partnerPills: [String],
                       partnerNote: String?,
                       swipePosition: Int)
    case summary(arc: String,
                 yourName: String,
                 yourDots: [Bool],
                 partnerName: String,
                 partnerDots: [Bool],
                 swipePosition: Int)
}

// MARK: - Reflection Pills

struct ReflectionPillGroup {
    static let howItFelt: [String] = [
        "Connected", "Tender", "Energized",
        "Heavy", "Relieved", "Uncertain",
        "Surprised", "Proud", "Raw"
    ]
    static let whatHappened: [String] = [
        "We went deeper than expected",
        "Something surfaced unexpectedly",
        "We disagreed on something",
        "We aligned on something big",
        "One of us needed to stop early",
        "Lighter than expected"
    ]
    static let whatYouNeedNow: [String] = [
        "Just marking this",
        "Want to sit with it",
        "Need some space",
        "Want to talk more",
        "Want something normal"
    ]
    static let inlineDefault: [String] = [
        "Connected", "Heavy", "Raw",
        "Relieved", "Surprised"
    ]
}

// MARK: - Pick Up Item

struct PickUpItem: Identifiable {
    let id = UUID()
    let contentType: PickUpContentType
    let title: String
    let contextLine: String
    let actionLabel: String
}

enum PickUpContentType {
    case timelineScenario(branchCurrent: Int, branchTotal: Int)
    case article(progressPercent: Int)
    case judgmentCall
    case autopsy(ratedMoments: Int, totalMoments: Int)
}

// MARK: - Research Ticker

struct ResearchFact: Identifiable {
    let id = UUID()
    let category: FactCategory
    let body: String
    let attribution: String?
}

enum FactCategory {
    case research
    case definition
    case reframe

    var overlineLabel: String {
        switch self {
        case .research:   return "RESEARCH"
        case .definition: return "DEFINITION"
        case .reframe:    return "OPEN LIGHTLY"
        }
    }
}

// MARK: - Partner Chip

enum PartnerChipState {
    case none
    case invitePending
    case active(name: String, initial: Character)
}

// MARK: - Home Event (for EventEngine)

enum HomeEvent {
    // Partner events
    case partnerCompletedDesireMap(partnerName: String)
    case partnerReflected(partnerName: String, sessionDay: String)
    case mutualReflectRevealReady

    // Milestone events
    case bothSawFreeReveal
    case fullMapUnlocked
    case stageCompleted(stageName: String)
    case stageUnlocked(stageIndex: Int)
    case firstSessionCompleted
    case firstMutualReflection

    // Time events
    case daysSinceSession(Int, partnerName: String?)
    case threeOpensNoSession

    var expiresAfterHours: Int {
        switch self {
        case .partnerCompletedDesireMap,
             .partnerReflected,
             .mutualReflectRevealReady,
             .bothSawFreeReveal,
             .fullMapUnlocked,
             .stageCompleted,
             .stageUnlocked,
             .firstSessionCompleted,
             .firstMutualReflection:
            return 24
        case .daysSinceSession,
             .threeOpensNoSession:
            return 0 // persistent until condition changes
        }
    }
}

```

---

## File: `Open Lightly/Features/MeUs/MeUsView.swift` {#file-open-lightly-features-meus-meusview-swift}

```swift
// Features/MeUs/MeUsView.swift
// Open Lightly
//
// Personal profile and partner connection hub.
// Label: "Me" for solo experiences, "Us · Me" for couple accounts.
// Stub — full implementation in a future batch.

import SwiftUI

struct MeUsView: View {

    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            AppColors.pageBg.ignoresSafeArea()
            Text(appState.experienceType.isCoupleAccount ? "MeUsView" : "MeView")
                .font(AppFonts.screenTitle)
                .foregroundStyle(AppColors.textPrimary)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview("Solo") {
    let state = AppState()
    state.experienceType = .soloSingle
    return MeUsView().environment(state)
}

#Preview("Couple") {
    let state = AppState()
    state.experienceType = .coupleNew
    return MeUsView().environment(state)
}

```

---

## File: `Open Lightly/Features/More/MoreView.swift` {#file-open-lightly-features-more-moreview-swift}

```swift
// Features/More/MoreView.swift
// Open Lightly
//
// Settings, account, support, and app-level actions.
// Also serves as the only visible screen for browsing/guest users.
// Stub — full implementation in a future batch.

import SwiftUI

struct MoreView: View {
    var body: some View {
        ZStack {
            AppColors.pageBg.ignoresSafeArea()
            Text("MoreView")
                .font(AppFonts.screenTitle)
                .foregroundStyle(AppColors.textPrimary)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    let state = AppState()
    return MoreView().environment(state)
}

```

---

## File: `Open Lightly/Features/Onboarding/Data/OnboardingData.swift` {#file-open-lightly-features-onboarding-data-onboardingdata-swift}

```swift
//
// OnboardingData.swift
// Open Lightly
//

import Foundation

struct OnboardingData {
    // Screen 1 — Name + Gender
    var displayName: String = ""
    var gender: String? = nil
    // Solo path only — captured in ContextView when
    // user selects a card implying a partner exists.
    // Couple path does not use this field —
    // partner sets their own gender in NameView.
    // nil = not provided or not applicable.
    var partnerPronouns: String? = nil

    // Screen 2 — Mode Select
    var explorationMode: ExplorationMode?

    // Screen 3 — Relationship Status (solo only)
    var relationshipStatus: RelationshipStatus?

    // Screen 4 — Relationship Context (branches on explorationMode)
    var relationshipContext: RelationshipContext?

    // Screen 4 — Personalize
    var nmStage: NMStage?
    var defaultDepth: Float = 0.3

    // Screen 5 — Curiosity Picker
    var communicationGoals: [String] = []    // Section 1 selections
    var learningGoals: [String] = []         // Section 2 selections
    var curiositySelections: [String] = []   // Derived: communicationGoals + learningGoals

    // Screen 6 — Pairing (couple only)
    var pairingId: String?

    // Screen 7 — Building Path (derived from nmStage)
    var defaultDifficulty: String = ""

    // Screen 7.5 — Card Reveal (pill selection for archetype routing)
    // nil when user skips — archetype routing uses fallback.
    var nmCardResponse: String? = nil

    // Screen 8 — Ground Rules + completion
    var groundRulesAcceptedAt: Date?
    var onboardingComplete: Bool = false
    var completedAt: Date?

    // Solo Reflection
    var firstReflection: String?
    var firstReflectionCompleted: Bool = false
    var firstReflectionTimestamp: Date?
}

// MARK: - Enums

enum PronounOption: String, CaseIterable, Identifiable, Hashable {
    case sheHer = "she/her"
    case heHim = "he/him"
    case theyThem = "they/them"
    
    var id: String { rawValue }
}

enum ExplorationMode: String, CaseIterable {
    case solo
    case couple
    case browsing
}

enum RelationshipStatus: String, CaseIterable {
    case single
    case partneredOpen
    case partneredHidden
}

enum NMStage: String, CaseIterable {
    case curious
    case exploring
    case experienced
}

enum RelationshipContext: String, CaseIterable, Codable {
    // Solo contexts
    case single
    case partneredOpen
    case partneredHidden

    // Couple contexts
    case notTalked
    case talking
    case someExperience
    case needsReset
}

```

---

## File: `Open Lightly/Features/Onboarding/Data/CuriosityScreenConfig.swift` {#file-open-lightly-features-onboarding-data-curiosityscreenconfig-swift}

```swift
//
//  CuriosityScreenConfig.swift
//  Open Lightly
//
//  Drives OnboardingCuriosityPickerView.
//  Config is derived from OnboardingData — never hardcode mode checks in the view.
//

import Foundation

// MARK: - CuriosityScreenConfig

struct CuriosityScreenConfig {
    let section1Label: String
    let section1Sublabel: String
    let section2Label: String
    let section2Sublabel: String
    let section1Options: [CuriosityOption]
    let section2Options: [CuriosityOption]
    let showSection2: Bool

    init(
        section1Label: String,
        section1Sublabel: String,
        section2Label: String = "",
        section2Sublabel: String = "",
        section1Options: [CuriosityOption],
        section2Options: [CuriosityOption] = [],
        showSection2: Bool
    ) {
        self.section1Label    = section1Label
        self.section1Sublabel = section1Sublabel
        self.section2Label    = section2Label
        self.section2Sublabel = section2Sublabel
        self.section1Options  = section1Options
        self.section2Options  = section2Options
        self.showSection2     = showSection2
    }
}

// MARK: - CuriosityOption

struct CuriosityOption: Identifiable {
    let id: String
    let label: String
    let isEmphasized: Bool
    let contentType: LearningContentType
}

// MARK: - LearningContentType

enum LearningContentType {
    case communicationGoal
    case educationTrack
    case quiz(QuizType)
    case desireMap
    case reflectionTrack
}

// MARK: - QuizType

enum QuizType {
    case cnmStyleDiscovery
    case cnmReadiness
    case attachmentStyle
    case jealousyAnatomy
}

// MARK: - OnboardingData Extension

extension OnboardingData {
    /// Derives the correct screen config from explorationMode + relationshipContext.
    var curiosityScreenConfig: CuriosityScreenConfig {
        switch (explorationMode, relationshipContext) {
        case (.solo, .single):           return .soloSingleConfig
        case (.solo, .partneredOpen):    return .soloPartneredOpenConfig
        case (.solo, .partneredHidden):  return .soloPartneredHiddenConfig
        case (.solo, nil):               return .soloSingleConfig
        case (.couple, .notTalked):      return .coupleNotTalkedConfig
        case (.couple, .talking):        return .coupleTalkingConfig
        case (.couple, .someExperience): return .coupleSomeExperienceConfig
        case (.couple, .needsReset):     return .coupleNeedsResetConfig
        case (.couple, nil):             return .coupleNotTalkedConfig
        default:                         return .browsingConfig
        }
    }
}

// MARK: - Static Config Instances

extension CuriosityScreenConfig {

    // MARK: Solo — Single

    static let soloSingleConfig = CuriosityScreenConfig(
        section1Label:    "What's been on your mind?",
        section1Sublabel: "Pick everything that feels true.",
        section2Label:    "What do you want to figure out?",
        section2Sublabel: "These shape what you'll explore and learn.",
        section1Options: [
            CuriosityOption(id: "desire_unknown",      label: "I don't know what I actually want",               isEmphasized: true,  contentType: .communicationGoal),
            CuriosityOption(id: "pattern_recognition", label: "I keep ending up in the same place",              isEmphasized: true,  contentType: .communicationGoal),
            CuriosityOption(id: "initiating",          label: "I wouldn't know how to ask for it",               isEmphasized: false, contentType: .communicationGoal),
            CuriosityOption(id: "self_awareness",      label: "My reactions in intimacy surprise me sometimes",  isEmphasized: false, contentType: .communicationGoal),
            CuriosityOption(id: "situationship",       label: "I'm in something I can't quite read",             isEmphasized: false, contentType: .communicationGoal),
        ],
        section2Options: [
            CuriosityOption(id: "desire_language",       label: "What I want — not what I've accepted",                                   isEmphasized: true,  contentType: .educationTrack),
            CuriosityOption(id: "attachment",            label: "Why I respond to people the way I do",                                   isEmphasized: true,  contentType: .educationTrack),
            CuriosityOption(id: "cnm_style_discovery",   label: "I'm curious whether non-monogamy could be right for me",                 isEmphasized: false, contentType: .quiz(.cnmStyleDiscovery)),
            CuriosityOption(id: "desire_map",            label: "I want to map my own desires before anything else",                      isEmphasized: false, contentType: .desireMap),
            CuriosityOption(id: "jealousy_history",      label: "I've felt jealousy in past relationships and want to understand it",     isEmphasized: false, contentType: .reflectionTrack),
            CuriosityOption(id: "consent_self_advocacy", label: "What it actually means to ask for what I want",                          isEmphasized: false, contentType: .educationTrack),
        ],
        showSection2: true
    )

    // MARK: Solo — Partnered Open (Partner Knows)

    static let soloPartneredOpenConfig = CuriosityScreenConfig(
        section1Label:    "What are you two working on?",
        section1Sublabel: "Pick everything that feels true.",
        section2Label:    "What do you want to figure out?",
        section2Sublabel: "These shape what you'll explore and learn.",
        section1Options: [
            CuriosityOption(id: "desire_mismatch", label: "We want different things sexually",          isEmphasized: true,  contentType: .communicationGoal),
            CuriosityOption(id: "initiating",      label: "I don't know how to start the conversation", isEmphasized: true,  contentType: .communicationGoal),
            CuriosityOption(id: "reconnection",    label: "We've lost some of our connection",          isEmphasized: false, contentType: .communicationGoal),
            CuriosityOption(id: "jealousy_stuck",  label: "Jealousy comes up and gets stuck",           isEmphasized: false, contentType: .communicationGoal),
            CuriosityOption(id: "self_unknown",    label: "I'm still figuring out what I want",         isEmphasized: false, contentType: .communicationGoal),
        ],
        section2Options: [
            CuriosityOption(id: "desire_language",   label: "What I want — not what I've accepted",                      isEmphasized: true,  contentType: .educationTrack),
            CuriosityOption(id: "cnm_openness",      label: "Whether opening up could work for us",                      isEmphasized: true,  contentType: .quiz(.cnmReadiness)),
            CuriosityOption(id: "desire_map",        label: "I want to map my own desires before anything else",         isEmphasized: false, contentType: .desireMap),
            CuriosityOption(id: "agreements",        label: "What our agreements should actually look like",              isEmphasized: false, contentType: .educationTrack),
            CuriosityOption(id: "jealousy_literacy", label: "What jealousy is actually telling me",                      isEmphasized: false, contentType: .educationTrack),
            CuriosityOption(id: "attachment",        label: "Why I respond to people the way I do",                      isEmphasized: false, contentType: .educationTrack),
        ],
        showSection2: true
    )

    // MARK: Solo — Partnered Hidden (It's Complicated)

    static let soloPartneredHiddenConfig = CuriosityScreenConfig(
        section1Label:    "What's actually going on for you?",
        section1Sublabel: "Pick everything that feels true.",
        section2Label:    "What would help you most right now?",
        section2Sublabel: "These shape what you'll explore and learn.",
        section1Options: [
            CuriosityOption(id: "self_unknown",               label: "I'm still figuring out what I want",      isEmphasized: true,  contentType: .communicationGoal),
            CuriosityOption(id: "initiating_hidden",          label: "I don't know how I'd even bring this up", isEmphasized: true,  contentType: .communicationGoal),
            CuriosityOption(id: "desire_mismatch_unilateral", label: "I think we want different things",        isEmphasized: false, contentType: .communicationGoal),
            CuriosityOption(id: "reconnection",               label: "We've lost some of our connection",       isEmphasized: false, contentType: .communicationGoal),
            CuriosityOption(id: "jealousy_stuck",             label: "Jealousy comes up and gets stuck",        isEmphasized: false, contentType: .communicationGoal),
        ],
        section2Options: [
            CuriosityOption(id: "desire_language",       label: "What I want — not what I've accepted",                           isEmphasized: true,  contentType: .educationTrack),
            CuriosityOption(id: "attachment",            label: "Why I respond to people the way I do",                           isEmphasized: true,  contentType: .educationTrack),
            CuriosityOption(id: "cnm_style_discovery",   label: "I'm curious whether non-monogamy could be right for me",         isEmphasized: true,  contentType: .quiz(.cnmStyleDiscovery)),
            CuriosityOption(id: "desire_map",            label: "I want to map my own desires before anything else",              isEmphasized: false, contentType: .desireMap),
            CuriosityOption(id: "jealousy_literacy",     label: "What jealousy is actually telling me",                           isEmphasized: false, contentType: .educationTrack),
            CuriosityOption(id: "consent_self_advocacy", label: "What it actually means to ask for what I want",                  isEmphasized: false, contentType: .educationTrack),
        ],
        showSection2: true
    )

    // MARK: Couple — Haven't Really Talked

    static let coupleNotTalkedConfig = CuriosityScreenConfig(
        section1Label:    "What feels hardest right now?",
        section1Sublabel: "Pick everything that feels true.",
        section2Label:    "What do you want to figure out?",
        section2Sublabel: "These shape what you'll explore and learn.",
        section1Options: [
            CuriosityOption(id: "initiating",      label: "I don't know how to start the conversation", isEmphasized: true,  contentType: .communicationGoal),
            CuriosityOption(id: "self_unknown",    label: "I'm still figuring out what I want",         isEmphasized: true,  contentType: .communicationGoal),
            CuriosityOption(id: "desire_mismatch", label: "We want different things sexually",          isEmphasized: false, contentType: .communicationGoal),
            CuriosityOption(id: "jealousy_stuck",  label: "Jealousy comes up and gets stuck",           isEmphasized: false, contentType: .communicationGoal),
        ],
        section2Options: [
            CuriosityOption(id: "cnm_openness",          label: "Whether opening up could work for us",              isEmphasized: true,  contentType: .quiz(.cnmReadiness)),
            CuriosityOption(id: "consent_ongoing",       label: "What it actually means to ask for what I want",     isEmphasized: true,  contentType: .educationTrack),
            CuriosityOption(id: "desire_map_individual", label: "Understanding what we each want — separately",      isEmphasized: true,  contentType: .desireMap),
            CuriosityOption(id: "agreements",            label: "What our agreements should actually look like",      isEmphasized: false, contentType: .educationTrack),
            CuriosityOption(id: "jealousy_literacy",     label: "What jealousy is actually telling me",              isEmphasized: false, contentType: .educationTrack),
            CuriosityOption(id: "attachment",            label: "Why I respond to people the way I do",              isEmphasized: false, contentType: .educationTrack),
        ],
        showSection2: true
    )

    // MARK: Couple — We've Been Talking

    static let coupleTalkingConfig = CuriosityScreenConfig(
        section1Label:    "Where do you want to go from here?",
        section1Sublabel: "Pick everything that feels true.",
        section2Label:    "What do you want to figure out?",
        section2Sublabel: "These shape what you'll explore and learn.",
        section1Options: [
            CuriosityOption(id: "desire_mismatch", label: "We want different things sexually",               isEmphasized: true,  contentType: .communicationGoal),
            CuriosityOption(id: "initiating",      label: "I don't know how to ask for the specific things", isEmphasized: true,  contentType: .communicationGoal),
            CuriosityOption(id: "jealousy_stuck",  label: "Jealousy comes up and gets stuck",                isEmphasized: false, contentType: .communicationGoal),
            CuriosityOption(id: "self_unknown",    label: "I'm still figuring out what I want",              isEmphasized: false, contentType: .communicationGoal),
            CuriosityOption(id: "reconnection",    label: "We've lost some of our connection",               isEmphasized: false, contentType: .communicationGoal),
        ],
        section2Options: [
            CuriosityOption(id: "agreements",            label: "What our agreements should actually look like",  isEmphasized: true,  contentType: .educationTrack),
            CuriosityOption(id: "compersion",            label: "Feeling good about what brings them joy",        isEmphasized: true,  contentType: .educationTrack),
            CuriosityOption(id: "cnm_openness",          label: "Whether opening up could work for us",           isEmphasized: true,  contentType: .quiz(.cnmReadiness)),
            CuriosityOption(id: "desire_map_individual", label: "Understanding what we each want — separately",   isEmphasized: false, contentType: .desireMap),
            CuriosityOption(id: "jealousy_literacy",     label: "What jealousy is actually telling me",           isEmphasized: false, contentType: .educationTrack),
            CuriosityOption(id: "attachment",            label: "Why I respond to people the way I do",           isEmphasized: false, contentType: .educationTrack),
            CuriosityOption(id: "consent_ongoing",       label: "What it actually means to ask for what I want",  isEmphasized: false, contentType: .educationTrack),
        ],
        showSection2: true
    )

    // MARK: Couple — We've Tried Some Things

    static let coupleSomeExperienceConfig = CuriosityScreenConfig(
        section1Label:    "What are you trying to figure out?",
        section1Sublabel: "Pick everything that feels true.",
        section2Label:    "What do you want to figure out?",
        section2Sublabel: "These shape what you'll explore and learn.",
        section1Options: [
            CuriosityOption(id: "jealousy_stuck",  label: "Jealousy comes up and gets stuck",         isEmphasized: true,  contentType: .communicationGoal),
            CuriosityOption(id: "desire_mismatch", label: "We want different things sexually",        isEmphasized: true,  contentType: .communicationGoal),
            CuriosityOption(id: "self_unknown",    label: "I'm still figuring out what I want",       isEmphasized: false, contentType: .communicationGoal),
            CuriosityOption(id: "reconnection",    label: "We've lost some of our connection",        isEmphasized: false, contentType: .communicationGoal),
            CuriosityOption(id: "initiating",      label: "I don't know how to ask for what I want", isEmphasized: false, contentType: .communicationGoal),
        ],
        section2Options: [
            CuriosityOption(id: "jealousy_literacy",   label: "What jealousy is actually telling me",                                        isEmphasized: true,  contentType: .educationTrack),
            CuriosityOption(id: "compersion",          label: "Feeling good about what brings them joy",                                      isEmphasized: true,  contentType: .educationTrack),
            CuriosityOption(id: "agreements",          label: "What our agreements should actually look like",                                isEmphasized: true,  contentType: .educationTrack),
            CuriosityOption(id: "asymmetric_interest", label: "How to handle it if one of us wants this more than the other",                 isEmphasized: false, contentType: .educationTrack),
            CuriosityOption(id: "attachment",          label: "Why I respond to people the way I do",                                        isEmphasized: false, contentType: .educationTrack),
            CuriosityOption(id: "consent_ongoing",     label: "What it actually means to ask for what I want",                               isEmphasized: false, contentType: .educationTrack),
            CuriosityOption(id: "cnm_openness",        label: "Whether opening up could work for us",                                        isEmphasized: false, contentType: .quiz(.cnmReadiness)),
        ],
        showSection2: true
    )

    // MARK: Couple — We Need A Reset

    static let coupleNeedsResetConfig = CuriosityScreenConfig(
        section1Label:    "What needs attention right now?",
        section1Sublabel: "Pick everything that feels true.",
        section2Label:    "What would help you two find footing?",
        section2Sublabel: "These shape what you'll explore and learn.",
        section1Options: [
            CuriosityOption(id: "reconnection",    label: "We've lost some of our connection",   isEmphasized: true,  contentType: .communicationGoal),
            CuriosityOption(id: "jealousy_stuck",  label: "Jealousy comes up and gets stuck",    isEmphasized: true,  contentType: .communicationGoal),
            CuriosityOption(id: "desire_mismatch", label: "We want different things sexually",   isEmphasized: false, contentType: .communicationGoal),
            CuriosityOption(id: "self_unknown",    label: "I'm still figuring out what I want",  isEmphasized: false, contentType: .communicationGoal),
        ],
        section2Options: [
            CuriosityOption(id: "attachment",            label: "Why I respond to people the way I do",           isEmphasized: true,  contentType: .educationTrack),
            CuriosityOption(id: "jealousy_literacy",     label: "What jealousy is actually telling me",           isEmphasized: true,  contentType: .educationTrack),
            CuriosityOption(id: "agreements",            label: "What our agreements should actually look like",   isEmphasized: true,  contentType: .educationTrack),
            CuriosityOption(id: "desire_language",       label: "What I want — not what I've accepted",           isEmphasized: false, contentType: .educationTrack),
            CuriosityOption(id: "consent_ongoing",       label: "What it actually means to ask for what I want",  isEmphasized: false, contentType: .educationTrack),
            CuriosityOption(id: "desire_map_individual", label: "Understanding what we each want — separately",   isEmphasized: false, contentType: .desireMap),
        ],
        showSection2: true
    )

    // MARK: Browsing (no explorationMode set)

    static let browsingConfig = CuriosityScreenConfig(
        section1Label:    "What do you want to learn about?",
        section1Sublabel: "Pick everything that interests you.",
        section2Label:    "What would you like to try?",
        section2Sublabel: "These open up quizzes and personalized paths.",
        section1Options: [
            CuriosityOption(id: "cnm_foundations",   label: "How non-monogamy actually works",               isEmphasized: false, contentType: .educationTrack),
            CuriosityOption(id: "desire_language",   label: "Understanding desire and what shapes it",        isEmphasized: false, contentType: .educationTrack),
            CuriosityOption(id: "jealousy_literacy", label: "What jealousy is actually telling you",          isEmphasized: false, contentType: .educationTrack),
            CuriosityOption(id: "attachment",        label: "Why people respond to intimacy the way they do", isEmphasized: false, contentType: .educationTrack),
            CuriosityOption(id: "consent_ongoing",   label: "Consent beyond yes and no",                      isEmphasized: false, contentType: .educationTrack),
            CuriosityOption(id: "compersion",        label: "Feeling good about what brings a partner joy",   isEmphasized: false, contentType: .educationTrack),
        ],
        section2Options: [
            CuriosityOption(id: "agreements",          label: "How couples build agreements that hold",              isEmphasized: false, contentType: .educationTrack),
            CuriosityOption(id: "desire_map",          label: "I want to map my own desires before anything else",   isEmphasized: true,  contentType: .desireMap),
            CuriosityOption(id: "cnm_style_discovery", label: "I'm curious what kind of relationships might suit me", isEmphasized: true,  contentType: .quiz(.cnmStyleDiscovery)),
            CuriosityOption(id: "attachment_style",    label: "What my attachment style means for how I connect",    isEmphasized: false, contentType: .quiz(.attachmentStyle)),
            CuriosityOption(id: "cnm_readiness",       label: "Whether non-monogamy could actually work for me",     isEmphasized: false, contentType: .quiz(.cnmReadiness)),
            CuriosityOption(id: "jealousy_anatomy",    label: "The anatomy of jealousy — and what mine is made of",  isEmphasized: false, contentType: .quiz(.jealousyAnatomy)),
        ],
        showSection2: true
    )
}

```

---

## File: `Open Lightly/Features/Onboarding/Design/OnboardingAtmosphere.swift` {#file-open-lightly-features-onboarding-design-onboardingatmosphere-swift}

```swift
// OnboardingAtmosphere.swift
// Open Lightly
//
// Unified atmospheric background for the entire onboarding flow.
// Consolidates OnboardingGlowField (dark) and AuroraGlowField (light)
// into one component with one config system covering both modes.
//
// Architecture:
//   - Lives in OnboardingFlowView's ZStack, below the screen switch.
//   - Never leaves the hierarchy — screens render on top of it.
//   - Light mode: AuroraGlowField morphs between per-screen configs via
//     its built-in .animation(.easeInOut(duration: 1.0), value: config).
//   - Dark mode: OnboardingGlowField is self-contained, no config needed.
//   - SparkField is light mode only — folded in here, not a separate call.
//
// BrandView exit contract:
//   OnboardingBrandView fires onAtmosphereExit() at t=4780ms.
//   FlowView receives this and sets atmosphereOpacity = 0 (easeIn 400ms).
//   FlowView owns atmosphereOpacity and passes it in here.
//   BrandView owns the timing. FlowView owns the state. Neither reaches
//   into the other's domain.
//
// Usage:
//   OnboardingAtmosphere(
//       config: auroraConfig,
//       sparkConfig: sparkConfig,
//       opacity: atmosphereOpacity
//   )
//   .ignoresSafeArea()
//   .allowsHitTesting(false)
//   .accessibilityHidden(true)

import SwiftUI

// MARK: - AtmosphereConfig
//
// One config per screen. Each config carries both light and dark
// intensity values so they live next to each other and can be
// tuned in one place.
//
// Light values carry over from the existing AuroraConfig presets.
// Dark values are tuned separately — dark mode amplifies color
// differently than cream does so the same multipliers would overblow.

struct AtmosphereConfig: Equatable {
    var light: AtmosphereIntensity
    var dark:  AtmosphereIntensity

    // ── Per-screen presets ────────────────────────────────────────────

    static let stat = AtmosphereConfig(
        light: AtmosphereIntensity(top: 1.00, mid: 0.40, bottom: 1.15, global: 0.85),
        dark:  AtmosphereIntensity(top: 1.00, mid: 0.50, bottom: 1.00, global: 0.70)
    )

    static let brand = AtmosphereConfig(
        light: AtmosphereIntensity(top: 1.00, mid: 0.35, bottom: 0.70, global: 0.78),
        dark:  AtmosphereIntensity(top: 1.00, mid: 0.45, bottom: 0.80, global: 0.65)
    )

    static let name = AtmosphereConfig(
        light: AtmosphereIntensity(top: 1.00, mid: 0.10, bottom: 1.15, global: 0.60),
        dark:  AtmosphereIntensity(top: 0.80, mid: 0.20, bottom: 0.90, global: 0.55)
    )

    static let modeSelect = AtmosphereConfig(
        light: AtmosphereIntensity(top: 0.10, mid: 0.30, bottom: 1.15, global: 0.70),
        dark:  AtmosphereIntensity(top: 0.15, mid: 0.35, bottom: 1.00, global: 0.60)
    )

    static let contextSelect = AtmosphereConfig(
        light: AtmosphereIntensity(top: 0.40, mid: 0.20, bottom: 0.85, global: 0.50),
        dark:  AtmosphereIntensity(top: 0.30, mid: 0.25, bottom: 0.75, global: 0.45)
    )

    static let curiosityPicker = AtmosphereConfig(
        light: AtmosphereIntensity(top: 0.30, mid: 0.10, bottom: 0.75, global: 0.40),
        dark:  AtmosphereIntensity(top: 0.20, mid: 0.15, bottom: 0.65, global: 0.35)
    )

    // buildingPath and cardReveal reuse curiosityPicker —
    // de-energised atmosphere, content is the focus.
    static let buildingPath   = AtmosphereConfig.curiosityPicker
    static let cardReveal     = AtmosphereConfig.curiosityPicker

    static let groundRules = AtmosphereConfig(
        light: AtmosphereIntensity(top: 0.15, mid: 0.20, bottom: 1.05, global: 0.50),
        dark:  AtmosphereIntensity(top: 0.10, mid: 0.20, bottom: 0.90, global: 0.45)
    )
}

// MARK: - AtmosphereIntensity

struct AtmosphereIntensity: Equatable {
    var top:    Double
    var mid:    Double
    var bottom: Double
    var global: Double
}

// MARK: - OnboardingAtmosphere

struct OnboardingAtmosphere: View {

    var config:      AtmosphereConfig      = .stat
    var sparkConfig: SparkConfiguration    = .statView
    var opacity:     Double                = 1.0

    @Environment(\.colorScheme) private var colorScheme

    // Map AtmosphereConfig → AuroraConfig so AuroraGlowField
    // continues to receive the typed value it expects.
    // This bridge is internal — callers only deal with AtmosphereConfig.
    private var auroraConfig: AuroraConfig {
        let i = colorScheme == .light ? config.light : config.dark
        return AuroraConfig(
            topOpacityMult:    i.top,
            midOpacityMult:    i.mid,
            bottomOpacityMult: i.bottom,
            globalOpacity:     i.global
        )
    }

    var body: some View {
        Group {
            if colorScheme == .light {
                ZStack {
                    AuroraGlowField(config: auroraConfig)
                    SparkField(config: sparkConfig)
                }
            } else {
                OnboardingGlowField()
            }
        }
        .opacity(opacity)
    }
}
// MARK: - Previews

#Preview("Stat — Dark") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        OnboardingAtmosphere(config: .stat, sparkConfig: .statView, opacity: 1.0)
            .ignoresSafeArea()
    }
    .preferredColorScheme(.dark)
}

#Preview("Stat — Light") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        OnboardingAtmosphere(config: .stat, sparkConfig: .statView, opacity: 1.0)
            .ignoresSafeArea()
    }
    .preferredColorScheme(.light)
}

```

---

## File: `Open Lightly/Features/Onboarding/Layout/OnboardingLayout.swift` {#file-open-lightly-features-onboarding-layout-onboardinglayout-swift}

```swift
// Features/Onboarding/Layout/OnboardingLayout.swift
//
// Shared proportional spacing constants for the onboarding flow.
// All values are expressed as fractions of the screen's live height or width
// so that the layout scales correctly across the full device matrix:
//
//   iPhone SE 2/3    375 × 667 pt   (home button, no bottom safe area)
//   iPhone 16        393 × 852 pt   (34 pt bottom safe area)
//   iPhone 16 Plus   430 × 932 pt   (34 pt bottom safe area)
//   iPhone 16 Pro    402 × 874 pt   (34 pt bottom safe area)
//   iPhone 16 Pro Max 440 × 956 pt  (34 pt bottom safe area)
//
// Reference device: iPhone 16 (852 pt height).
// Fraction × 852 == the original hardcoded pt value at reference size.
//
// Usage:
//   GeometryReader { geo in
//       let h = geo.size.height
//       let w = geo.size.width
//       VStack(spacing: 0) { ... }
//           .padding(.top, OL.navTop(h))
//   }

import SwiftUI

typealias OL = OnboardingLayout

enum OnboardingLayout {

    // MARK: - Nav Bar

    /// Top clearance for the nav bar (below status bar / Dynamic Island).
    /// SE: ~8pt   |   reference: ~12pt   |   Pro Max: ~13pt
    static func navTop(_ h: CGFloat) -> CGFloat    { max(8, h * 0.014) }

    /// Gap between nav bar and first content element.
    /// SE: ~14pt  |   reference: ~20pt   |   Pro Max: ~22pt
    static func navBottom(_ h: CGFloat) -> CGFloat { h * 0.023 }

    // MARK: - Vertical Rhythm Scale

    /// Tight gap — between tightly-coupled elements (label → sub-label).
    /// SE: ~9pt   |   reference: ~12pt   |   Pro Max: ~13pt
    static func compact(_ h: CGFloat) -> CGFloat   { h * 0.014 }

    /// Standard section gap — between distinct content blocks.
    /// SE: ~19pt  |   reference: ~24pt   |   Pro Max: ~27pt
    static func standard(_ h: CGFloat) -> CGFloat  { h * 0.028 }

    /// Loose breathing room — between major sections or before/after CTA.
    /// SE: ~31pt  |   reference: ~40pt   |   Pro Max: ~45pt
    static func loose(_ h: CGFloat) -> CGFloat     { h * 0.047 }

    // MARK: - Progress Bar Clearance

    /// Space above the progress bar (below nav / safe area).
    /// SE: ~19pt  |   reference: ~24pt   |   Pro Max: ~27pt
    static func progressTop(_ h: CGFloat) -> CGFloat    { h * 0.028 }

    /// Space below the progress bar before the first text element.
    /// SE: ~15pt  |   reference: ~20pt   |   Pro Max: ~22pt
    static func progressBottom(_ h: CGFloat) -> CGFloat { h * 0.023 }

    // MARK: - Spacer Bounds

    /// Minimum spacer height — prevents content from touching on SE.
    static func spacerMin(_ h: CGFloat) -> CGFloat  { h * 0.033 }

    /// Maximum spacer height — prevents excessive dead space on Pro Max.
    static func spacerMax(_ h: CGFloat) -> CGFloat  { h * 0.075 }

    // MARK: - Atmosphere Decoration

    /// Width for full-bleed atmosphere ellipses (maps 600 pt at 393 w reference).
    static func atmosW(_ w: CGFloat) -> CGFloat { w * 1.53 }

    /// Height for full-bleed atmosphere ellipses (maps 500 pt at 852 h reference).
    static func atmosH(_ h: CGFloat) -> CGFloat { h * 0.587 }

    // MARK: - ScrollView Content

    /// Minimum VStack height inside a ScrollView — fills screen before
    /// scroll activates, preventing compression on small devices.
    static func scrollMinH(_ h: CGFloat) -> CGFloat { h * 0.85 }
}

```

---

## File: `Open Lightly/Features/Onboarding/Views/OnboardingFlowView.swift` {#file-open-lightly-features-onboarding-views-onboardingflowview-swift}

```swift
// Features/Onboarding/OnboardingFlowView.swift

import SwiftUI
import OSLog

private let logger = Logger(subsystem: "com.openlightly.app", category: "OnboardingFlowView")

// MARK: - Screen Sequence
// 0.   stat            → trust trigger
// 0.5  brand           → identity (auto-advance)
// 1.   name            → name + pronouns
// 2.   modeSelect      → solo / couple / browsing
// 3a.  contextSelect   → relationship context (solo + couple only)
// 3b.  curiosityPicker → interest picker (all paths; browsing skips contextSelect)
// 4.   buildingPath    → processing animation (auto-advance, derives defaultDifficulty)
// 4.5  cardReveal      → prompt card reveal transition (skip to continue)
// 5.   groundRules     → privacy guarantees + ethical frame (must-acknowledge)
//
// BRAND → NAME TRANSITION
// ────────────────────────
// BrandView runs its internal exit sequence then fires onFinished().
// FlowView sets currentStep = .name directly — no cover, no delay.
// The atmosphere stays at full opacity throughout. NameView cascades
// its content in from top to bottom starting 80ms after it enters
// the hierarchy.
// All other step transitions use advance() unchanged.

enum OnboardingStep: Int, CaseIterable {
    case stat
    case brand
    case name
    case modeSelect
    case contextSelect
    case curiosityPicker
    case buildingPath
    case cardReveal
    case groundRules
}

struct OnboardingFlowView: View {

    init(startAt: OnboardingStep = .stat) {
        _currentStep = State(initialValue: startAt)
    }

    @State private var currentStep: OnboardingStep
    @State private var onboardingData = OnboardingData()

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Shared BG so transitions never flash the wrong surface color.
            (colorScheme == .light ? AppColors.lightPageBg : AppColors.pageBg)
                .ignoresSafeArea()

            // Persistent atmosphere owned by FlowView.
            OnboardingAtmosphere(
                config: atmosphereConfig,
                sparkConfig: sparkConfig
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .accessibilityHidden(true)

            switch currentStep {
            case .stat:
                OnboardingStatView(onContinue: {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        currentStep = .brand
                    }
                })
                .transition(.opacity)

            case .brand:
                OnboardingBrandView(
                    onFinished: {
                        currentStep = .name
                    }
                )

            case .name:
                // NameView renders under its own cascade; no cover entrance.
                OnboardingNameView(
                    data: $onboardingData,
                    onContinue: { advance(to: .modeSelect) },
                    onBack: { advance(to: .brand) }
                )

            case .modeSelect:
                OnboardingModeSelectView(
                    data: $onboardingData,
                    onContinue: {
                        if onboardingData.explorationMode == .browsing {
                            advance(to: .curiosityPicker)
                        } else {
                            advance(to: .contextSelect)
                        }
                    },
                    onBack: { advance(to: .name) }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95))) // ANIM-STD-38

            case .contextSelect:
                OnboardingContextView(
                    data: $onboardingData,
                    onContinue: { advance(to: .curiosityPicker) },
                    onBack:     { advance(to: .modeSelect) }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95))) // ANIM-STD-38

            case .curiosityPicker:
                OnboardingCuriosityPickerView(
                    data: $onboardingData,
                    onContinue: { advance(to: .buildingPath) },
                    onBack: {
                        if onboardingData.explorationMode == .browsing {
                            advance(to: .modeSelect)
                        } else {
                            advance(to: .contextSelect)
                        }
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95))) // ANIM-STD-38

            case .buildingPath:
                OnboardingBuildingPathView(data: $onboardingData, onFinished: {
                    advance(to: .cardReveal)
                })
                .transition(.opacity.combined(with: .scale(scale: 0.95))) // ANIM-STD-38

            case .cardReveal:
                OnboardingCardRevealView(data: $onboardingData, onContinue: {
                    advance(to: .groundRules)
                })
                .transition(.opacity.combined(with: .scale(scale: 0.95))) // ANIM-STD-38

            case .groundRules:
                OnboardingGroundRulesView(data: $onboardingData, onFinished: {
                    let experience = deriveExperienceType(from: onboardingData)
                    appState.experienceType = experience
                    logger.info("Onboarding complete — experienceType set to: \(experience.rawValue)")
                    hasCompletedOnboarding = true
                })
                .transition(.opacity.combined(with: .scale(scale: 0.95))) // ANIM-STD-38
            }
        }
    }

    // MARK: - Atmosphere config per step
    private var atmosphereConfig: AtmosphereConfig {
        switch currentStep {
        case .stat:            return .stat
        case .brand:           return .brand
        case .name:            return .name
        case .modeSelect:      return .modeSelect
        case .contextSelect:   return .contextSelect
        case .curiosityPicker: return .curiosityPicker
        case .buildingPath:    return .buildingPath
        case .cardReveal:      return .cardReveal
        case .groundRules:     return .groundRules
        }
    }

    // MARK: - Spark config per step (light mode only)
    private var sparkConfig: SparkConfiguration {
        switch currentStep {
        case .stat:            return .statView
        case .brand:           return .statView
        case .name:            return .nameView
        case .modeSelect:      return .modeSelectView
        case .contextSelect:   return .contextView
        case .curiosityPicker: return .curiosityPickerView
        case .buildingPath:    return .curiosityPickerView
        case .cardReveal:      return .curiosityPickerView
        case .groundRules:     return .groundRulesView
        }
    }

    private func advance(to step: OnboardingStep) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { // ANIM-STD-37
            currentStep = step
        }
    }

    // MARK: - Experience Type Derivation
    private func deriveExperienceType(from data: OnboardingData) -> ExperienceType {
        switch data.explorationMode {
        case .browsing:
            return .browsing
        case .solo:
            switch data.relationshipContext {
            case .partneredOpen, .partneredHidden:
                return .soloPartnered
            default:
                return .soloSingle
            }
        case .couple:
            let isExperienced = data.nmStage == .experienced
                || data.relationshipContext == .someExperience
            return isExperienced ? .coupleExperienced : .coupleNew
        case .none:
            logger.warning("deriveExperienceType: explorationMode is nil — defaulting to soloSingle")
            return .soloSingle
        }
    }
}

// MARK: - Previews
#Preview("Full Flow — Dark") {
    OnboardingFlowView()
        .environment(AppState())
        .preferredColorScheme(.dark)
}

#Preview("Full Flow — Light") {
    OnboardingFlowView()
        .environment(AppState())
        .preferredColorScheme(.light)
}

#Preview("Jump → Brand") {
    OnboardingFlowView(startAt: .brand)
        .environment(AppState())
        .preferredColorScheme(.dark)
}

#Preview("Jump → Name") {
    OnboardingFlowView(startAt: .name)
        .environment(AppState())
        .preferredColorScheme(.dark)
}

#Preview("Jump → Brand→Name transition") {
    OnboardingFlowView(startAt: .brand)
        .environment(AppState())
        .preferredColorScheme(.dark)
}

```

---

## File: `Open Lightly/Features/Onboarding/Views/OnboardingStatView.swift` {#file-open-lightly-features-onboarding-views-onboardingstatview-swift}

```swift
import SwiftUI

// MARK: - Layout constant
private let kReferenceHeight: CGFloat = 844

// MARK: - Main Onboarding View
struct OnboardingStatView: View {

    var onContinue: (() -> Void)? = nil

    @State private var holoShiftPhase: CGFloat = -0.35
    @State private var holoFlashOffset: CGFloat = 2.5
    @State private var glowPulseHigh = false
    @State private var castPulseHigh = false

    @State private var showStatLabel = false
    @State private var showCiteTap   = false
    @State private var showEthos     = false
    @State private var showCTA       = false

    @State private var citeOpen = false
    @State private var hasAnimated = false
    @State private var hasAdvanced = false

    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }

    var body: some View {
        GeometryReader { geo in
            let screenH = geo.size.height
            let scale = screenH / kReferenceHeight
            let screenW = geo.size.width
            let statFontSize: CGFloat = screenH <= 700
                ? 100
                : (screenW > 390 ? 164 : 140)

            ZStack {
                Color.clear.ignoresSafeArea()
                if !isLight {
                    Ellipse()
                        .fill(RadialGradient(stops: [
                            .init(color: Color.purple.opacity(0.12), location: 0),
                            .init(color: Color.blue.opacity(0.06), location: 0.5),
                            .init(color: .clear, location: 1)
                        ], center: .center, startRadius: 0, endRadius: 240))
                        .frame(width: 380, height: 220)
                        .blur(radius: 90)
                        .offset(y: 260 * scale)
                        .allowsHitTesting(false)
                }

                VStack(spacing: 0) {

                    Spacer(minLength: screenH * 0.08)

                    VStack(spacing: 0) {
                        StatNumberView(
                            holoShiftPhase: holoShiftPhase,
                            holoFlashOffset: holoFlashOffset,
                            glowPulseHigh: glowPulseHigh,
                            castPulseHigh: castPulseHigh,
                            fontSize: statFontSize,
                            isLight: isLight
                        )
                        .padding(.bottom, 20 * scale)

                        Text("Americans have engaged in consensual non\u{2011}monogamy at some point in their lives.")
                            .font(AppFonts.body(18))
                            .lineSpacing(10.8)
                            .foregroundStyle(isLight
                                ? AppColors.lightCardTitle
                                : AppColors.textPrimary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 300)
                            .opacity(showStatLabel ? 1 : 0)
                            .offset(y: showStatLabel ? 0 : 14)

                        CitationTapView(citeOpen: $citeOpen)
                            .opacity(showCiteTap ? 1 : 0)
                            .offset(y: showCiteTap ? 0 : 14)

                        EthosTextView()
                            .padding(.top, 28 * scale)
                            .opacity(showEthos ? 1 : 0)
                            .offset(y: showEthos ? 0 : 8)
                            .animation(.easeOut(duration: 0.5).delay(1.0), value: showEthos)
                    }
                    .padding(.horizontal, 28)

                    Spacer(minLength: 16)

                    // ✦ CHANGED — offset 14 → 10 (shorter travel = snappier)
                    HoloCTAButton(
                        title: "Explore",
                        isEnabled: true,
                        action: {
                            guard !hasAdvanced else { return }
                            hasAdvanced = true
                            #if DEBUG
                            assert(onContinue != nil,
                                   "OnboardingStatView: onContinue not injected — wire from coordinator.")
                            #endif
                            onContinue?()
                        },
                        cornerRadius: 100,
                        height: 56,
                        lightModeGradient: isLight ? LinearGradient(
                            stops: [
                                .init(color: AppColors.magenta,   location: 0.0),
                                .init(color: AppColors.orangeHot, location: 0.55),
                                .init(color: AppColors.gold,      location: 1.0),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) : nil
                    )
                    .padding(.horizontal, 28)
                    .opacity(showCTA ? 1 : 0)
                    .offset(y: showCTA ? 0 : 10)

                    Spacer()
                        .frame(height: 12)

                    HomeIndicatorBar()
                }
            }
        }
        .onAppear(perform: {
            guard !hasAnimated else { return }
            hasAnimated = true
            startAllAnimations()
        })
        .onDisappear {
            hasAnimated = false
            hasAdvanced = false
        }
    }

    // MARK: - Animation Orchestration

    private func startAllAnimations() {

        withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
            holoShiftPhase = 0.65
        }
        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
            holoFlashOffset = -0.5
        }
        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
            glowPulseHigh = true
        }
        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
            castPulseHigh = true
        }

        // ✦ CHANGED — tighter stagger (200ms), snappier durations
        // Time to interactive: 2.3s → 1.5s
        withAnimation(.easeOut(duration: 0.6).delay(0.5))  { showStatLabel = true }
        withAnimation(.easeOut(duration: 0.6).delay(0.7))  { showCiteTap   = true }
        withAnimation(.easeOut(duration: 0.5).delay(1.0))  { showEthos     = true }

        // ✦ CHANGED — CTA gets a spring for a decisive "tap me" arrival
        withAnimation(.spring(response: 0.45, dampingFraction: 0.82).delay(1.05)) {
            showCTA = true
        }
    }

    // MARK: - Stat Number (Holographic "1 in 5")
    private struct StatNumberView: View {
        let holoShiftPhase: CGFloat
        let holoFlashOffset: CGFloat
        let glowPulseHigh: Bool
        let castPulseHigh: Bool

        var fontSize: CGFloat = 140
        var isLight: Bool = false

        private let txt  = "1 in 5"

        private var fnt: Font { AppFonts.display(fontSize, weight: .bold) }
        private var trk: CGFloat { -3.2 * (fontSize / 140) }

        private var castWidth: CGFloat { 300 * (fontSize / 140) }
        private var castHeight: CGFloat { 55 * (fontSize / 140) }
        private var castOffset: CGFloat { 70 * (fontSize / 140) }

        private var holoStops: [Gradient.Stop] {
            [
                .init(color: AppColors.cyan,    location: 0.00),
                .init(color: AppColors.purple,  location: 0.25),
                .init(color: AppColors.magenta, location: 0.50),
                .init(color: AppColors.pink,    location: 0.65),
                .init(color: AppColors.purple,  location: 0.80),
                .init(color: AppColors.cyan,    location: 1.00),
            ]
        }

        private var warmStops: [Gradient.Stop] {
            [
                .init(color: AppColors.magenta,   location: 0.00),
                .init(color: AppColors.orangeHot, location: 0.55),
                .init(color: AppColors.gold,      location: 1.00),
            ]
        }

        private var holoGradient: LinearGradient {
            LinearGradient(
                stops: holoStops,
                startPoint: UnitPoint(x: -holoShiftPhase, y: -0.2),
                endPoint:   UnitPoint(x: 2.0 - holoShiftPhase, y: 1.2)
            )
        }

        private var warmGradient: LinearGradient {
            LinearGradient(
                stops: warmStops,
                startPoint: UnitPoint(x: -holoShiftPhase, y: -0.2),
                endPoint:   UnitPoint(x: 2.0 - holoShiftPhase, y: 1.2)
            )
        }

        private var activeGradient: LinearGradient {
            isLight ? warmGradient : holoGradient
        }

        private var baseText: some View {
            Text(txt).font(fnt).tracking(trk)
        }

        var body: some View {
            ZStack {
                baseText
                    .foregroundStyle(.clear)
                    .overlay { activeGradient.mask { baseText } }
                    .blur(radius: 12)
                    .opacity(glowPulseHigh ? 0.40 : 0.25)
                    .padding(-6)

                Ellipse()
                    .fill(RadialGradient(stops: [
                        .init(color: isLight
                            ? AppColors.magenta.opacity(0.18)
                            : AppColors.purple.opacity(0.18), location: 0),
                        .init(color: isLight
                            ? AppColors.gold.opacity(0.10)
                            : AppColors.cyan.opacity(0.10), location: 0.4),
                        .init(color: .clear, location: 0.7)
                    ], center: .center, startRadius: 0, endRadius: 150))
                    .frame(width: castWidth, height: castHeight)
                    .blur(radius: 20)
                    .scaleEffect(x: castPulseHigh ? 1.12 : 1.0, y: 1.0)
                    .opacity(castPulseHigh ? 1.0 : 0.7)
                    .offset(y: castOffset)

                baseText
                    .foregroundStyle(.clear)
                    .overlay { activeGradient.mask { baseText } }

                baseText
                    .foregroundStyle(.clear)
                    .overlay {
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0.00),
                                .init(color: .clear, location: 0.30),
                                .init(color: Color.white.opacity(0.30), location: 0.38),
                                .init(color: Color.white.opacity(0.00), location: 0.42),
                                .init(color: .clear, location: 0.50),
                                .init(color: Color.white.opacity(0.18), location: 0.60),
                                .init(color: .clear, location: 0.65),
                                .init(color: .clear, location: 1.00),
                            ],
                            startPoint: UnitPoint(x: -0.1, y: 1.0),
                            endPoint:   UnitPoint(x: 1.1,  y: -0.25)
                        )
                        .frame(width: 800)
                        .offset(x: holoFlashOffset * 320)
                        .mask { baseText }
                    }
                    .clipped()
            }
            .fixedSize()
        }
    }

    // MARK: - Citation Tap
    private struct CitationTapView: View {
        @Binding var citeOpen: Bool

        @Environment(\.colorScheme) private var colorScheme
        private var isLight: Bool { colorScheme == .light }

        private func citationBody() -> AttributedString {
            var result = AttributedString()
            
            var first = AttributedString("8,718 single adults")
            first.font = AppFonts.body(11.5, weight: .semibold)
            result.append(first)
            
            var second = AttributedString(" across two nationally representative studies. Roughly 1 in 5 reported engaging in CNM \u{2014} consistent across age, income, religion, race, political affiliation, and region.")
            second.font = AppFonts.body(11.5, weight: .regular)
            result.append(second)
            
            return result
        }

        var body: some View {
            VStack(spacing: 0) {
                Button {
                    withAnimation(.timingCurve(0.4, 0, 0.2, 1, duration: 0.35)) {
                        citeOpen.toggle()
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(isLight
                                ? AppColors.magenta
                                : AppColors.cyanLight)
                        Text("About this research")
                            .font(AppFonts.body(11, weight: .medium))
                            .foregroundStyle(isLight
                                    ? AppColors.lightCardTitle
                                    : AppColors.textPrimary)
                            .tracking(0.3)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 10)
                    .background {
                        Capsule()
                            .fill(isLight ? Color.white.opacity(0.08) : Color.white.opacity(0.06))
                            .overlay {
                                Capsule()
                                    .stroke(
                                        isLight
                                            ? AppColors.lightBorder
                                            : Color.white.opacity(0.12),
                                        lineWidth: 1
                                    )
                            }
                    }
                }
                .buttonStyle(.plain)
                .padding(.top, 14)

                if citeOpen {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(citationBody())
                            .foregroundColor(isLight ? AppColors.lightTextPrimary : AppColors.textPrimary)
                            .lineSpacing(11.5 * 0.7)

                        Text("Haupert et al., 2017 · Journal of Sex Research")
                            .font(AppFonts.body(10).italic())
                            .foregroundColor(isLight
                                ? AppColors.lightTextSecondary
                                : AppColors.textSecondary)
                            .padding(.top, 8)
                    }
                    .frame(maxWidth: 300, alignment: .leading)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(isLight
                                ? AppColors.lightCardFill
                                : AppColors.cardBg)
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .stroke(isLight
                                    ? AppColors.lightBorder
                                    : AppColors.borderActive,
                                    lineWidth: 1))
                    )
                    .shadow(color: isLight
                        ? AppColors.lightShadowPurple
                        : Color.black.opacity(0.5),
                            radius: isLight ? 16 : 20,
                            y: isLight ? 4 : 6)
                    .padding(.top, 14)
                    .frame(maxHeight: 140)
                    .clipped()
                    .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .top)))
                }
            }
        }
    }

    // MARK: - Ethos Text
    private struct EthosTextView: View {
        @Environment(\.colorScheme) private var colorScheme
        private var isLight: Bool { colorScheme == .light }

        var body: some View {
            if isLight {
                HStack(spacing: 0) {
                    Text("You're not alone.")
                        .font(AppFonts.body(14, weight: .semibold))
                        .foregroundStyle(LinearGradient(
                            stops: [
                                .init(color: AppColors.magenta,   location: 0.00),
                                .init(color: AppColors.orangeHot, location: 0.55),
                                .init(color: AppColors.gold,      location: 1.00),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                    Text(" And this isn't new.")
                        .font(AppFonts.body(14, weight: .medium))
                        .tracking(0.2)
                        .foregroundColor(AppColors.lightCardTitle)
                }
                .lineSpacing(14 * 0.6)
                .multilineTextAlignment(.center)
            } else {
                HStack(spacing: 0) {
                    Text("You're not alone.")
                        .font(AppFonts.body(14, weight: .semibold))
                        .foregroundStyle(LinearGradient(
                            colors: [
                                AppColors.cyan.opacity(0.90),
                                AppColors.purple.opacity(0.80),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                    Text(" And this isn't new.")
                        .font(AppFonts.body(14, weight: .medium))
                        .tracking(0.2)
                        .foregroundColor(.white)
                }
                .lineSpacing(14 * 0.6)
                .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Home Indicator Bar
    private struct HomeIndicatorBar: View {
        @Environment(\.colorScheme) private var colorScheme
        private var isLight: Bool { colorScheme == .light }

        var body: some View {
            RoundedRectangle(cornerRadius: 3)
                .fill(isLight
                    ? Color.black.opacity(0.12)
                    : Color.white.opacity(0.15))
                .frame(width: 134, height: 5)
                .frame(height: 24)
        }
    }
}

#Preview("Dark") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        OnboardingAtmosphere(config: .stat, sparkConfig: .statView, opacity: 1.0)
            .ignoresSafeArea()
        OnboardingStatView(onContinue: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("Light") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        OnboardingAtmosphere(config: .stat, sparkConfig: .statView, opacity: 1.0)
            .ignoresSafeArea()
        OnboardingStatView(onContinue: {})
    }
    .preferredColorScheme(.light)
}

```

---

## File: `Open Lightly/Features/Onboarding/Views/OnboardingBrandView.swift` {#file-open-lightly-features-onboarding-views-onboardingbrandview-swift}

```swift
import SwiftUI
import Combine

struct OnboardingBrandView: View {

    var onFinished: (() -> Void)? = nil

    // MARK: - Accessibility

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }

    // MARK: - Screen geometry

    @State private var screenW: CGFloat = 393
    @State private var screenH: CGFloat = 852

    // MARK: - Canvas bloom state

    @State private var bl1Width: CGFloat = 6
    @State private var bl1Opacity: Double = 0.8
    @State private var hotWidth: CGFloat = 3
    @State private var hotOpacity: Double = 0.6
    @State private var thickWidth: CGFloat = 0
    @State private var thickOpacity: Double = 0
    @State private var centerGlowOpacity: Double = 0
    @State private var centerGlowScale: CGFloat = 1.0
    @State private var wisp1Opacity: Double = 0
    @State private var wisp2Opacity: Double = 0
    @State private var wisp3Opacity: Double = 0
    @State private var wisp1Offset: CGSize = .zero
    @State private var wisp1Scale: CGFloat = 1.0
    @State private var wisp2Offset: CGSize = .zero
    @State private var wisp2Scale: CGFloat = 1.0
    @State private var wisp3Offset: CGSize = .zero
    @State private var wisp3Scale: CGFloat = 1.0
    @State private var floorWidth: CGFloat = 0
    @State private var floorOpacity: Double = 0
    @State private var floorScaleX: CGFloat = 1.0

    // MARK: - Holo gradient sweep state

    @State private var holoPhase: CGFloat = 0
    @State private var holoPhaseB: CGFloat = 0

    // MARK: - Wordmark per-word state

    @State private var openOpacity: Double = 0
    @State private var openScale: CGFloat = 0.90
    @State private var openOffsetY: CGFloat = 12
    @State private var lightlyOpacity: Double = 0
    @State private var lightlyScale: CGFloat = 0.92
    @State private var lightlyOffsetY: CGFloat = 10
    @State private var wordmarkBreath: CGFloat = 1.0

    // MARK: - Tagline state
    //
    // taglineOpacity is EXIT-ONLY — starts at 1.0, only animated to 0 on exit.
    // No positional animation on the container — always at final position.
    //
    // Line 1 enters t=1950ms easeOut(0.22) → done t=2170ms
    // Line 2 enters t=2150ms easeOut(0.22) → done t=2370ms
    // Stagger gap (200ms) > duration × 0.7 (154ms) — reading beat honoured.
    // Exit does not begin until t=4500ms — 2130ms+ of settled dwell.

    @State private var taglineOpacity: Double = 1.0
    @State private var taglineBreath: Double = 0.55
    @State private var line1Opacity: Double = 0
    @State private var line2Opacity: Double = 0

    // MARK: - Global state

    @State private var autoAdvanceFired = false
    @State private var filamentStarted = false
    @State private var glowFieldOpacity: Double = 0
    @State private var sceneEntryOpacity: Double = 0

    // NOTE: fadeOutOpacity REMOVED — coordinator owns the cover.

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let _ = cacheSize(geo.size)
            let w = screenW
            let h = screenH

            ZStack {
                Color.clear.ignoresSafeArea()

                wisps(w: w, h: h)
                    .allowsHitTesting(false)

                centerGlow()
                    .allowsHitTesting(false)

                floorReflection(h: h)
                    .allowsHitTesting(false)

                if filamentStarted {
                    FilamentView(size: screenW, mode: .solo, speed: 1.0, showConnections: false)
                        .frame(width: screenW, height: screenW)
                        .position(x: w / 2, y: h * 0.46)
                        .allowsHitTesting(false)
                }

                wordmark
                    .scaleEffect(wordmarkBreath)
                    .position(x: w / 2 + 8, y: h * 0.46)
                    .accessibilityHidden(true)

                taglineView
                    .position(x: w / 2, y: h * 0.571)
                    .accessibilityHidden(true)

                // NOTE: No fadeOutOpacity cover layer here.
                // The coordinator's cover sits above this entire view.

                #if DEBUG
                VStack {
                    Spacer()
                Button("↺ Replay") { replay() }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.4))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                    .padding(.bottom, 48)
                }
                #endif

                // Accessibility: invisible, VoiceOver only.
                VStack(spacing: 4) {
                    Text("Open Lightly")
                    Text("Hard Conversations, Made Easier.")
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Open Lightly. Hard Conversations, Made Easier.")
                .opacity(0)
                .allowsHitTesting(false)
            }
            .opacity(sceneEntryOpacity)
            .drawingGroup()
        }
        .ignoresSafeArea()
        .onAppear { startEverything() }
        .onDisappear {
            filamentStarted   = false
            autoAdvanceFired  = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                wisp1Opacity      = 0
                wisp2Opacity      = 0
                wisp3Opacity      = 0
                centerGlowOpacity = 0
                floorOpacity      = 0
                glowFieldOpacity  = 0
                holoPhase         = 0
                holoPhaseB        = 0
                wordmarkBreath    = 1.0
                taglineBreath     = 0.55
            }
        }
    }

    // MARK: - Size cache

    private func cacheSize(_ size: CGSize) {
        if screenW != size.width || screenH != size.height {
            DispatchQueue.main.async {
                screenW = size.width
                screenH = size.height
            }
        }
    }

    // MARK: - Background layers

    private func bleedInit(h: CGFloat) -> some View {
        Rectangle()
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: .clear,                          location: 0.02),
                        .init(color: AppColors.cyan.opacity(0.12),    location: 0.12),
                        .init(color: AppColors.purple.opacity(0.22),  location: 0.30),
                        .init(color: AppColors.magenta.opacity(0.20), location: 0.50),
                        .init(color: AppColors.purple.opacity(0.18),  location: 0.70),
                        .init(color: AppColors.pink.opacity(0.10),    location: 0.88),
                        .init(color: .clear,                          location: 0.98)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: bl1Width, height: h)
            .opacity(bl1Opacity)
    }

    private func bleedThick(h: CGFloat) -> some View {
        Rectangle()
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: .clear,                           location: 0.05),
                        .init(color: AppColors.magenta.opacity(0.14),  location: 0.20),
                        .init(color: AppColors.purple.opacity(0.20),   location: 0.40),
                        .init(color: AppColors.cyan.opacity(0.12),     location: 0.60),
                        .init(color: AppColors.pink.opacity(0.14),     location: 0.80),
                        .init(color: .clear,                           location: 0.95)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: thickWidth, height: h)
            .blur(radius: 40)
            .opacity(thickOpacity)
    }

    private func bleedHot(h: CGFloat) -> some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        .clear,
                        Color.white.opacity(0.10),
                        Color.white.opacity(0.15),
                        Color.white.opacity(0.10),
                        .clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: hotWidth, height: h * 0.8)
            .opacity(hotOpacity)
    }

    private func centerGlow() -> some View {
        Ellipse()
            .fill(
                RadialGradient(
                    stops: [
                        .init(color: AppColors.purple.opacity(0.10),  location: 0),
                        .init(color: AppColors.magenta.opacity(0.06), location: 0.40),
                        .init(color: .clear,                          location: 0.70)
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 150
                )
            )
            .frame(width: 250, height: 150)
            .scaleEffect(centerGlowScale)
            .blur(radius: 50)
            .opacity(centerGlowOpacity)
    }

    private func wisps(w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            Ellipse()
                .fill(AppColors.cyan.opacity(0.06))
                .frame(width: 120, height: 80)
                .blur(radius: 35)
                .scaleEffect(wisp1Scale)
                .offset(wisp1Offset)
                .offset(x: -w * 0.15, y: -h * 0.12)
                .opacity(wisp1Opacity)

            Ellipse()
                .fill(AppColors.magenta.opacity(0.05))
                .frame(width: 80, height: 120)
                .blur(radius: 35)
                .scaleEffect(wisp2Scale)
                .offset(wisp2Offset)
                .offset(x: w * 0.18, y: h * 0.02)
                .opacity(wisp2Opacity)

            Ellipse()
                .fill(AppColors.purple.opacity(0.06))
                .frame(width: 100, height: 90)
                .blur(radius: 35)
                .scaleEffect(wisp3Scale)
                .offset(wisp3Offset)
                .offset(x: -w * 0.05, y: h * 0.18)
                .opacity(wisp3Opacity)
        }
    }

    private func floorReflection(h: CGFloat) -> some View {
        Ellipse()
            .fill(
                RadialGradient(
                    stops: [
                        .init(color: AppColors.magenta.opacity(0.10), location: 0),
                        .init(color: AppColors.purple.opacity(0.08),  location: 0.40),
                        .init(color: .clear,                          location: 0.70)
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: floorWidth * 0.5
                )
            )
            .frame(width: floorWidth, height: 90)
            .scaleEffect(x: floorScaleX, y: 1.0)
            .blur(radius: 35)
            .opacity(floorOpacity)
            .offset(y: h * 0.36)
    }

    // MARK: - Wordmark

    private var wordmark: some View {
        VStack(spacing: screenH < 700 ? -10 : -16) {
            Text("Open")
                .font(.custom("Zodiak-Extrabold", size: 58))
                .tracking(-1.5)
                .italic()
                .foregroundStyle(
                    isLight
                        ? AnyShapeStyle(AppColors.purple)
                        : AnyShapeStyle(LinearGradient(
                            colors: [AppColors.cyan, AppColors.cyan, AppColors.purple],
                            startPoint: UnitPoint(
                                x: -0.5 + holoPhase * 0.4,
                                y:  0.0 + holoPhase * 0.2
                            ),
                            endPoint: UnitPoint(
                                x:  1.5 + holoPhase * 0.4,
                                y:  1.0 + holoPhase * 0.2
                            )
                          ))
                )
                .opacity(openOpacity)
                .scaleEffect(openScale)
                .offset(y: openOffsetY)

            Text("Lightly")
                .font(.custom("Zodiak-Bold", size: 54))
                .tracking(2)
                .foregroundStyle(
                    isLight
                        ? AnyShapeStyle(AppColors.orangeHot)
                        : AnyShapeStyle(LinearGradient(
                            colors: [AppColors.magenta, AppColors.pink, AppColors.pink],
                            startPoint: UnitPoint(
                                x: -0.5 + holoPhaseB * 0.4,
                                y:  0.0 + holoPhaseB * 0.2
                            ),
                            endPoint: UnitPoint(
                                x:  1.5 + holoPhaseB * 0.4,
                                y:  1.0 + holoPhaseB * 0.2
                            )
                          ))
                )
                .opacity(lightlyOpacity)
                .scaleEffect(lightlyScale)
                .offset(y: lightlyOffsetY)
        }
        .multilineTextAlignment(.center)
    }

    // MARK: - Tagline

    private var taglineView: some View {
        VStack(spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("Hard")
                    .font(.custom("Switzer-Regular", size: 18))
                    .foregroundColor(
                        isLight
                            ? AppColors.wineDark
                            : Color.white
                    )
                Text("Conversations")
                    .font(.custom("Switzer-Light", size: 18))
                    .foregroundStyle(
                        isLight
                            ? AnyShapeStyle(LinearGradient(
                                stops: [
                                    .init(color: AppColors.magenta,   location: 0.00),
                                    .init(color: AppColors.orangeHot, location: 0.55),
                                    .init(color: AppColors.gold,      location: 1.00),
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                              ))
                            : AnyShapeStyle(LinearGradient(
                                colors: [
                                    AppColors.cyan,
                                    AppColors.purpleLight,
                                    AppColors.magenta,
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                              ))
                    )
            }
            .opacity(line1Opacity)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("Made")
                    .font(.custom("Switzer-Regular", size: 18))
                    .foregroundColor(
                        isLight
                            ? AppColors.wineDark
                            : Color.white
                    )
                Text("Easier")
                    .font(.custom("Switzer-Light", size: 18))
                    .foregroundStyle(
                        isLight
                            ? AnyShapeStyle(LinearGradient(
                                stops: [
                                    .init(color: AppColors.magenta,   location: 0.00),
                                    .init(color: AppColors.orangeHot, location: 0.55),
                                    .init(color: AppColors.gold,      location: 1.00),
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                              ))
                            : AnyShapeStyle(LinearGradient(
                                colors: [
                                    AppColors.cyan,
                                    AppColors.purpleLight,
                                    AppColors.magenta,
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                              ))
                    )
            }
            .opacity(line2Opacity)
        }
        .font(.custom("Switzer-Light", size: 18))
        .tracking(0.3)
        .multilineTextAlignment(.center)
        .opacity(taglineOpacity)
    }

    // MARK: - Replay (DEBUG only)

    private func replay() {
        #if DEBUG
        if autoAdvanceFired {
            print("[OnboardingBrandView] ⚠️ replay() called after " +
                  "ambient loops started — competing animations possible.")
        }
        #endif

        bl1Width          = 6
        bl1Opacity        = 0.8
        hotWidth          = 3
        hotOpacity        = 0.6
        thickWidth        = 0
        thickOpacity      = 0
        centerGlowOpacity = 0
        centerGlowScale   = 1.0
        wisp1Opacity      = 0
        wisp2Opacity      = 0
        wisp3Opacity      = 0
        wisp1Offset       = .zero
        wisp2Offset       = .zero
        wisp3Offset       = .zero
        wisp1Scale        = 1.0
        wisp2Scale        = 1.0
        wisp3Scale        = 1.0
        floorWidth        = 0
        floorOpacity      = 0
        floorScaleX       = 1.0
        holoPhase         = 0
        holoPhaseB        = 0
        openOpacity       = 0
        openScale         = 0.90
        openOffsetY       = 12
        lightlyOpacity    = 0
        lightlyScale      = 0.92
        lightlyOffsetY    = 10
        wordmarkBreath    = 1.0
        taglineOpacity    = 1.0
        taglineBreath     = 0.55
        line1Opacity      = 0
        line2Opacity      = 0
        glowFieldOpacity  = 0
        sceneEntryOpacity = 0
        filamentStarted   = false
        autoAdvanceFired  = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            startEverything()
        }
    }

    // MARK: - Animation timeline
    //
    // FINAL TIMELINE (v7 — Layered Dissolve) total runtime ~5020ms to handoff:
    //
    //   t=0ms       Canvas bloom begins
    //   t=300ms     Filament starts (skipped if reduceMotion)
    //   t=600ms     "Open" lands
    //   t=900ms     "Lightly" lands
    //   t=1000ms    Glow field begins (dark: 2.5s creep / light: 0.6s)
    //   t=1800ms    Atmospheric loops begin (skipped if reduceMotion)
    //   t=2000ms    Wordmark gradient sweep begins
    //   t=2200ms    Wordmark breath begins
    //   t=1950ms    Line 1 fades in — easeOut(0.22) done t=2170ms
    //   t=2150ms    Line 2 fades in — easeOut(0.22) done t=2370ms
    //   t=2370ms–4500ms  Fully settled dwell (~2130ms)
    //   t=4500ms    Tagline exits     — easeIn(160ms)  done t=4660ms
    //   t=4700ms    Wordmark exits    — easeIn(280ms)  done t=4980ms
    //   t=4780ms    Atmosphere exits  — easeIn(400ms)  done t=5180ms
    //   t=5020ms    onFinished() fires — coordinator takes over
    //
    //   COORDINATOR then:
    //   +0ms    NextScreen renders under cover (already opaque)
    //   +50ms   Cover lifts — easeOut(320ms)
    //   +410ms  Cover gone, NextScreen fully visible
    //   +450ms  BrandView removed from hierarchy

    private func startEverything() {

        // ── Scene entry fade ──────────────────────
        withAnimation(.easeOut(duration: 0.4)) {
            sceneEntryOpacity = 1.0
        }

        // ── Phase 1: Canvas bloom (0ms) ──────────────────────────────────

        withAnimation(.easeOut(duration: 1.2)) {
            bl1Width   = 420
            bl1Opacity = 0.18
        }
        withAnimation(.easeOut(duration: 0.8)) {
            hotWidth   = 200
            hotOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
            withAnimation(.easeOut(duration: 1.4)) {
                thickWidth   = 420
                thickOpacity = 0.22
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeOut(duration: 0.8)) {
                wisp1Opacity      = 1.0
                wisp2Opacity      = 1.0
                wisp3Opacity      = 1.0
                centerGlowOpacity = 1.0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.easeOut(duration: 1.0)) {
                floorWidth   = 360
                floorOpacity = 0.4
            }
        }

        // ── Glow field ────────────────────────────────────────────────────

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 2.5)) {
                glowFieldOpacity = 1.0
            }
        }

        // ── Phase 2: "Open" lands (600ms) ────────────────────────────────

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.60) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.82)) {
                openOpacity = 1.0
                openScale   = 1.0
                openOffsetY = 0
            }
        }

        // ── Filament (300ms) ─────────────────────────────────────────────

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
            if !reduceMotion {
                filamentStarted = true
            }
        }

        // ── Phase 2b: "Lightly" lands (900ms) ────────────────────────────

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.90) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.82)) {
                lightlyOpacity = 1.0
                lightlyScale   = 1.0
                lightlyOffsetY = 0
            }
        }

        // ── Ambient loops — staggered ignition (v7) ───────────────────────
        //
        // Three separate dispatch times prevent the "loop bomb" where all
        // repeatForever transactions fire on the same RunLoop tick:
        //
        //   t=1800ms  Atmospheric layer (wisps, glow, floor)
        //   t=2000ms  Gradient sweep (holoPhase, holoPhaseB)
        //   t=2200ms  Wordmark breath (wordmarkBreath, taglineBreath)
        //
        // 200ms micro-stagger is sub-perceptual as a pause but spreads
        // GPU transaction load across frames.

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.80) {
            guard !reduceMotion else { return }
            withAnimation(
                .easeInOut(duration: 6)
                    .repeatForever(autoreverses: true)
            ) {
                wisp1Offset     = CGSize(width: 20,  height: -15)
                wisp1Scale      = 1.10
                wisp2Offset     = CGSize(width: -18, height: 18)
                wisp2Scale      = 1.12
                wisp3Offset     = CGSize(width: 12,  height: 15)
                wisp3Scale      = 1.08
                centerGlowScale = 1.2
                floorScaleX     = 1.06
                floorOpacity    = 0.6
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.00) {
            guard !reduceMotion else { return }
            withAnimation(
                .easeInOut(duration: 5.2)
                    .repeatForever(autoreverses: true)
            ) {
                holoPhase  = 1.0
                holoPhaseB = 1.0
            }
            withAnimation(
                .easeInOut(duration: 5.5)
                    .repeatForever(autoreverses: true)
            ) {
                taglineBreath = 0.72
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.20) {
            guard !reduceMotion else { return }
            withAnimation(
                .easeInOut(duration: 5.0)
                    .repeatForever(autoreverses: true)
            ) {
                wordmarkBreath = 1.02
            }
        }

        // ── Tagline entrance ──────────────────────────────────────────────
        //
        // Stagger gap (200ms) > duration × 0.7 (154ms) — Line 1 fully
        // opaque before Line 2 starts. Reading beat is honoured.

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.95) {
            withAnimation(.easeOut(duration: 0.22)) {
                line1Opacity = 1.0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.15) {
            withAnimation(.easeOut(duration: 0.22)) {
                line2Opacity = 1.0
            }
        }

        // ── Settled dwell: t=2370ms → t=4500ms (~2130ms) ─────────────────

        // ── Phase 4: Exit sequence ────────────────────────────────────────
        //
        // Beat 1 — Tagline dissolves (t=4500ms, 160ms)
        // Beat 2 — Wordmark contracts+fades (t=4700ms, 280ms)
        //          Starts 40ms after tagline done (4660ms + 40ms buffer)
        // Beat 3 — Atmosphere fades (t=4780ms, 400ms)
        //          Overlaps wordmark tail — bg layer has lower priority
        // Handoff — onFinished() at t=5020ms
        //          40ms before atmosphere fully done (5180ms)
        //          Coordinator receives and starts cover lift

        // Beat 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.50) {
            withAnimation(.easeIn(duration: 0.16)) {
                taglineOpacity = 0
            }
        }

        // Beat 2
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.70) {
            withAnimation(.easeIn(duration: 0.28)) {
                openOpacity    = 0
                openScale      = 0.96
                lightlyOpacity = 0
                lightlyScale   = 0.96
            }
        }

        // Beat 3
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.78) {
            withAnimation(.easeIn(duration: 0.40)) {
                glowFieldOpacity  = 0
                centerGlowOpacity = 0
                wisp1Opacity      = 0
                wisp2Opacity      = 0
                wisp3Opacity      = 0
                floorOpacity      = 0
            }
        }

        // ── Handoff (5020ms) ─────────────────────────────────────────────

        DispatchQueue.main.asyncAfter(deadline: .now() + 4.85) {
            withAnimation(.easeIn(duration: 0.35)) {
                sceneEntryOpacity = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 5.20) {
            guard !autoAdvanceFired else { return }
            autoAdvanceFired = true
            #if DEBUG
            assert(
                onFinished != nil,
                "OnboardingBrandView: onFinished not injected — " +
                "wire this callback from the coordinator."
            )
            #endif
            onFinished?()
        }
    }
}

// MARK: - Previews

#Preview("Dark") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config:      .brand,
            sparkConfig: .statView,
            opacity:     1.0
        )
        .ignoresSafeArea()
        .allowsHitTesting(false)
        OnboardingBrandView(onFinished: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("Light") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config:      .brand,
            sparkConfig: .statView,
            opacity:     1.0
        )
        .ignoresSafeArea()
        .allowsHitTesting(false)
        OnboardingBrandView(onFinished: {})
    }
    .preferredColorScheme(.light)
}
 

```

---

## File: `Open Lightly/Features/Onboarding/Views/OnboardingNameView.swift` {#file-open-lightly-features-onboarding-views-onboardingnameview-swift}

```swift
// OnboardingNameView.swift
// Open Lightly
//
// Screen 1: Name + Pronouns

import SwiftUI

// MARK: - Main View

struct OnboardingNameView: View {
    @Binding var data: OnboardingData
    var onContinue: (() -> Void)?
    var onBack:     (() -> Void)?

    // Form state
    @State private var displayName:       String         = ""
    @State private var selectedGender:    String? = nil
    @State private var customGenderText:  String = ""
    @State private var showCustomGenderField: Bool = false
    @FocusState private var nameFieldFocused: Bool

    // Atmosphere
    @State private var borderPhase: CGFloat   = 0
    @State private var hasAnimated: Bool      = false

    // Entrance
    @State private var headerVisible = false
    @State private var cardVisible   = false
    @State private var ctaVisible    = false

    // Greeting response
    @State private var greetingVisible = false
    @State private var greetingOwnsName: Bool = false
    @State private var nameTextOpacity: Double = 1.0
    @State private var fieldCollapsed: Bool = false
    @State private var typingDebounce: DispatchWorkItem? = nil

    // Gender section
    @State private var genderSectionVisible = false

    // Validation Bloom
    @State private var isButtonGlowing: Bool = false

    // Pulse Animation
    @State private var glowPulse: Bool = false

    // Environment
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Surface tokens

    private var kFieldBG: Color {
        colorScheme == .light
            ? AppColors.lightSurfaceBg
            : Color.white.opacity(0.07)
    }

    private var kGlassBorder: Color {
        colorScheme == .light
            ? AppColors.lightBorder
            : Color.white.opacity(0.09)
    }

    private var kFieldBorderActive: some ShapeStyle {
        if colorScheme == .light {
            return AnyShapeStyle(AppColors.warmAuroraBorder)
        } else {
            return AnyShapeStyle(AppColors.spectrumBorder)
        }
    }

    private var kFloatingLabelFocused: Color {
        colorScheme == .light
            ? AppColors.lightLabelFocused
            : AppColors.purpleLight
    }

    private var kFloatingLabelUnfocused: Color {
        colorScheme == .light
            ? AppColors.lightCardTitle.opacity(0.40)
            : AppColors.textTertiary
    }

    private var kTextPrimary: Color {
        colorScheme == .light
            ? AppColors.lightCardTitle
            : .white
    }

    private var kPronounLabel: Color {
        colorScheme == .light
            ? AppColors.lightCardTitle.opacity(0.65)
            : .white.opacity(0.75)
    }

    private var kPronounHint: Color {
        colorScheme == .light
            ? AppColors.lightHintText
            : AppColors.textTertiary
    }

    private var kCustomPillFill: Color {
        colorScheme == .light
            ? AppColors.lightFrostPillCustom
            : AppColors.surfaceBg
    }

    private var kCustomPillBorder: Color {
        colorScheme == .light
            ? AppColors.lightBorder
            : AppColors.borderHover
    }

    private var isValid: Bool {
        let trimmed = displayName.trimmingCharacters(in: .whitespaces)
        return trimmed.count >= 1 && trimmed.count <= 30 && selectedGender != nil
    }

    // MARK: - Name Field

    @ViewBuilder
    private var nameField: some View {
        ZStack(alignment: .leading) {

            // Floating label
            Text("What should we call you?")
                .font(displayName.isEmpty && !nameFieldFocused
                      ? AppFonts.display(22, weight: .semibold)
                      : AppFonts.overline)
                .foregroundStyle(
                    displayName.isEmpty && !nameFieldFocused
                        ? (colorScheme == .light
                            ? AnyShapeStyle(AppColors.lightTextSecondary)
                            : AnyShapeStyle(AppColors.textSecondary))
                        : (colorScheme == .light
                            ? AnyShapeStyle(AppColors.lightLabelFocused)
                            : AnyShapeStyle(AppColors.purpleLight))
                )
                .offset(y: displayName.isEmpty && !nameFieldFocused ? 0 : -36)
                .animation(.easeInOut(duration: 0.35), value: nameFieldFocused)
                .animation(.easeInOut(duration: 0.35), value: displayName.isEmpty)
                .opacity(fieldCollapsed ? 0 : 1)
                .animation(.easeInOut(duration: 0.25).delay(0.05), value: fieldCollapsed)
                .accessibilityHidden(true)

            TextField("", text: $displayName)
                .font(AppFonts.display(28, weight: .semibold))
                .foregroundColor(
                    (colorScheme == .light
                        ? AppColors.lightCardTitle
                        : AppColors.textPrimary)
                    .opacity(nameTextOpacity)
                )
                .tint(colorScheme == .light
                    ? AppColors.lightLabelFocused
                    : AppColors.cyan)
                .offset(y: 10)
                .focused($nameFieldFocused)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .onSubmit {
                    nameFieldFocused = false
                    triggerCollapse()
                }
                .opacity(fieldCollapsed ? 0 : 1)
                .animation(.easeInOut(duration: 0.3), value: fieldCollapsed)
                .disabled(fieldCollapsed)
                .onChange(of: displayName) { _, newValue in
                    if newValue.count > 30 {
                        displayName = String(newValue.prefix(30))
                    }

                    let hasContent = !newValue
                        .trimmingCharacters(in: .whitespaces)
                        .isEmpty

                    withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                        genderSectionVisible = hasContent
                    }

                    typingDebounce?.cancel()

                    let trimmed = newValue.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            greetingVisible = false
                            greetingOwnsName = false
                        }
                        withAnimation(.easeInOut(duration: 0.3).delay(0.15)) {
                            fieldCollapsed = false
                            nameTextOpacity = 1.0
                        }
                        return
                    }

                    let work = DispatchWorkItem {
                        triggerCollapse()
                    }
                    typingDebounce = work
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: work)
                }
                .onChange(of: nameFieldFocused) { _, isFocused in
                    if isFocused && greetingOwnsName {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            greetingVisible = false
                            greetingOwnsName = false
                        }
                        withAnimation(.easeInOut(duration: 0.3).delay(0.15)) {
                            fieldCollapsed = false
                            nameTextOpacity = 1.0
                        }
                    }
                }
                .accessibilityLabel("What should we call you?")
        }
        .frame(height: 72)
        .padding(.bottom, 4)
        .overlay(alignment: .bottom) {
            ZStack {
                // Base line — always visible
                Rectangle()
                    .fill(
                        nameFieldFocused || !displayName.isEmpty
                            ? (colorScheme == .light
                                ? AnyShapeStyle(AppColors.warmAuroraBorder)
                                : AnyShapeStyle(AppColors.spectrumBorder))
                            : (colorScheme == .light
                                ? AnyShapeStyle(AppColors.lightBorder)
                                : AnyShapeStyle(AppColors.border))
                    )
                    .frame(height: nameFieldFocused ? 3 : 2)
                    .animation(.easeInOut(duration: 0.3), value: nameFieldFocused)

                // Gradient glow line — appears when focused or has content
                if nameFieldFocused || !displayName.isEmpty {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: colorScheme == .light
                                    ? [
                                        AppColors.magenta.opacity(0.6),
                                        AppColors.pink.opacity(0.9),
                                        AppColors.purple.opacity(0.7),
                                        AppColors.magenta.opacity(0.6)
                                      ]
                                    : [
                                        AppColors.cyan.opacity(0.6),
                                        AppColors.purple.opacity(0.9),
                                        AppColors.pink.opacity(0.8),
                                        AppColors.cyan.opacity(0.6)
                                      ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 3)
                        .blur(radius: 4)
                        .opacity(nameFieldFocused ? 1.0 : 0.5)
                        .animation(.easeInOut(duration: 0.3), value: nameFieldFocused)

                    // Outer soft glow
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: colorScheme == .light
                                    ? [
                                        AppColors.magenta.opacity(0.2),
                                        AppColors.pink.opacity(0.35),
                                        AppColors.purple.opacity(0.25),
                                        AppColors.magenta.opacity(0.2)
                                      ]
                                    : [
                                        AppColors.cyan.opacity(0.2),
                                        AppColors.purple.opacity(0.35),
                                        AppColors.pink.opacity(0.3),
                                        AppColors.cyan.opacity(0.2)
                                      ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 8)
                        .blur(radius: 6)
                        .opacity(nameFieldFocused ? 0.9 : 0.4)
                        .animation(.easeInOut(duration: 0.3), value: nameFieldFocused)
                }
            }
            .opacity(fieldCollapsed ? 0 : 1)
            .animation(.easeInOut(duration: 0.3), value: fieldCollapsed)
        }
    }

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height

            ZStack {
                // ── Background ───────────────────────────────────────────
                Color.clear.ignoresSafeArea()

                // ── Atmosphere ellipse ────────────────────────────────────
                if colorScheme == .dark {
                    Ellipse()
                        .fill(RadialGradient(stops: [
                            .init(color: Color.purple.opacity(0.22), location: 0),
                            .init(color: Color.blue.opacity(0.12),   location: 0.5),
                            .init(color: .clear,                     location: 1)
                        ], center: .center, startRadius: 0, endRadius: 240))
                        .frame(width: geo.size.width, height: h * 0.31)
                        .blur(radius: 80)
                        .offset(y: h * 0.30)
                        .allowsHitTesting(false)
                }

                // ── Content ───────────────────────────────────────────────
                VStack(alignment: .leading, spacing: 0) {

                    OnboardingNavBar(currentStep: 1, totalSteps: 6, onBack: onBack)
                        .padding(.top, geo.safeAreaInsets.top > 50 ? 8 : 20)
                        .padding(.bottom, 28)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Let's get")
                            .font(AppFonts.display(28, weight: .semibold))
                            .foregroundColor(kTextPrimary)
                        LivingText(text: "acquainted.")
                    }
                    .opacity(headerVisible ? 1 : 0)
                    .scaleEffect(headerVisible ? 1.0 : 0.95)
                    .padding(.bottom, 28)

                    // ── Name field ────────────────────────────────────────
                    nameField
                        .padding(.bottom, 20)
                        .opacity(cardVisible ? 1 : 0)
                        .scaleEffect(cardVisible ? 1.0 : 0.95)

                    // ── Greeting ──────────────────────────────────────────
                    // FIX: corrected brace structure
                    HStack(alignment: .firstTextBaseline, spacing: 7.5) {
                        Spacer()

                        Text("Hi ")
                            .font(AppFonts.display(32, weight: .bold))
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.lightHeadlineDarkRose
                                : AppColors.textPrimary.opacity(0.94))

                        Text(displayName.trimmingCharacters(in: .whitespaces))
                            .font(AppFonts.display(32, weight: .bold))
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.lightHeadlineDarkRose
                                : AppColors.textPrimary)
                            .overlay(alignment: .bottom) {
                                ZStack {
                                    Rectangle()
                                        .fill(colorScheme == .light
                                            ? AnyShapeStyle(AppColors.warmAuroraBorder)
                                            : AnyShapeStyle(AppColors.spectrumBorder))
                                        .frame(height: 2)

                                    Rectangle()
                                        .fill(LinearGradient(
                                            colors: colorScheme == .light
                                                ? [AppColors.magenta.opacity(0.6),
                                                   AppColors.pink.opacity(0.9),
                                                   AppColors.purple.opacity(0.7),
                                                   AppColors.magenta.opacity(0.6)]
                                        : [AppColors.cyan.opacity(0.9),
                                           AppColors.purple.opacity(1.0),
                                           AppColors.pink.opacity(1.0),
                                           AppColors.cyan.opacity(0.9)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ))
                                    .frame(height: 2)
                                        .blur(radius: 6)

                                    Rectangle()
                                        .fill(LinearGradient(
                                            colors: colorScheme == .light
                                                ? [AppColors.magenta.opacity(0.2),
                                                   AppColors.pink.opacity(0.35),
                                                   AppColors.purple.opacity(0.25),
                                                   AppColors.magenta.opacity(0.2)]
                                                : [AppColors.cyan.opacity(0.2),
                                                   AppColors.purple.opacity(0.35),
                                                   AppColors.pink.opacity(0.3),
                                                   AppColors.cyan.opacity(0.2)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ))
                                        .frame(height: 10)
                                        .blur(radius: 10)
                                }
                                .padding(.leading, 2)
                                .offset(y: 4)
                            }

                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .opacity(greetingVisible ? 1 : 0)
                    .offset(y: greetingVisible ? -65 : 16)
                    .animation(
                        .spring(response: 1.1, dampingFraction: 0.88),
                        value: greetingVisible
                    )
                    .padding(.top, 8)
                    .padding(.bottom, 28)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            greetingVisible = false
                            greetingOwnsName = false
                        }
                        withAnimation(.easeInOut(duration: 0.3).delay(0.15)) {
                            fieldCollapsed = false
                            nameTextOpacity = 1.0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            nameFieldFocused = true
                        }
                    }
                    .accessibilityLabel("Edit name")
                    .accessibilityHint("Tap to change what we call you")
                    .accessibilityAddTraits(.isButton)

                    Rectangle()
                        .fill(colorScheme == .light
                              ? AppColors.lightBorder
                              : Color.white.opacity(0.05))
                        .frame(height: 1)
                        .padding(.bottom, 18)
                        .opacity(cardVisible && !fieldCollapsed ? 1 : 0)
                        .scaleEffect(cardVisible ? 1.0 : 0.95)
                        .animation(.easeInOut(duration: 0.3), value: fieldCollapsed)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.85).delay(0.23),
                            value: cardVisible
                        )

                    genderSection
                        .opacity(cardVisible && genderSectionVisible ? 1 : 0)
                        .scaleEffect(cardVisible && genderSectionVisible ? 1.0 : 0.95)

                    Spacer(minLength: OL.spacerMin(h))

                    // ── CTA ───────────────────────────────────────────────
                    ZStack {
                        RoundedRectangle(cornerRadius: 100)
                            .fill(LinearGradient(
                                colors: [
                                    AppColors.pink.opacity(0.30),
                                    AppColors.purple.opacity(0.25),
                                    AppColors.magenta.opacity(0.20)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(maxWidth: .infinity)
                            .frame(height: 80)
                            .blur(radius: 36)
                            .opacity(isButtonGlowing ? 1.0 : 0.0)
                            .animation(
                                reduceMotion ? .none : .easeInOut(duration: 0.6),
                                value: isButtonGlowing
                            )
                            .allowsHitTesting(false)

                        HoloCTAButton(
                            title: "Next",
                            isEnabled: isValid
                        ) {
                            triggerHaptic(.medium)
#if DEBUG
                            assert(onContinue != nil,
                                   "OnboardingNameView: onContinue not injected — " +
                                   "wire this callback from the coordinator.")
#endif
                            commitData()
                            onContinue?()
                        }
                        .fixedSize(horizontal: false, vertical: true)
                        .shadow(
                            color: isButtonGlowing
                                ? AppColors.pink.opacity(
                                    reduceMotion ? 0.30 : (glowPulse ? 0.40 : 0.20)
                                )
                                : .clear,
                            radius: isButtonGlowing
                                ? (reduceMotion ? 12 : (glowPulse ? 18 : 8))
                                : 0,
                            x: 0, y: 0
                        )
                    }
                    .opacity(ctaVisible ? 1 : 0)
                    .scaleEffect(ctaVisible ? 1.0 : 0.95)

                    OnboardingFooter()
                        .opacity(ctaVisible ? 1 : 0)
                        .scaleEffect(ctaVisible ? 1.0 : 0.95)
                }
                .padding(.horizontal, 28)
            }
            .frame(width: geo.size.width, alignment: .topLeading)
            .onAppear {
                restoreStateIfNeeded()

                if isValid {
                    isButtonGlowing = true
                    if !reduceMotion {
                        withAnimation(
                            .easeInOut(duration: 2.5)
                            .repeatForever(autoreverses: true)
                            .delay(0.6)
                        ) { glowPulse = true }
                    }
                }

                guard !hasAnimated else { return }
                hasAnimated = true

                if colorScheme == .dark {
                    withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                        borderPhase = 1.0
                    }
                }

                let entranceSpring = Animation.spring(response: 0.5, dampingFraction: 0.85)

                if reduceMotion {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        headerVisible = true
                        cardVisible   = true
                        ctaVisible    = true
                    }
                } else {
                    withAnimation(entranceSpring.delay(0.08)) { headerVisible = true }
                    withAnimation(entranceSpring.delay(0.23)) { cardVisible = true }
                    withAnimation(entranceSpring.delay(0.38)) { ctaVisible = true }
                }

                if !reduceMotion {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            nameFieldFocused = true
                        }
                    }
                }
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .onDisappear {
                hasAnimated      = false
                headerVisible    = false
                cardVisible      = false
                ctaVisible       = false
                isButtonGlowing  = false
                glowPulse        = false
                greetingOwnsName = false
                nameTextOpacity  = 1.0
                fieldCollapsed   = false
            }
            .onChange(of: isValid) { _, newValue in
                if newValue {
                    triggerHaptic(.medium)
                    if reduceMotion {
                        isButtonGlowing = true
                    } else {
                        withAnimation(.easeInOut(duration: 0.6)) {
                            isButtonGlowing = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            withAnimation(
                                .easeInOut(duration: 2.5)
                                .repeatForever(autoreverses: true)
                            ) { glowPulse = true }
                        }
                    }
                } else {
                    withAnimation(.easeInOut(duration: 0.45)) {
                        isButtonGlowing = false
                    }
                    glowPulse = false
                }
            }
        }
    }

    // MARK: - Gender Section

    private var genderSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Gender identity")
                    .font(AppFonts.body(13, weight: .medium))
                    .foregroundColor(kPronounLabel)
                Spacer()
                Text("helps us personalize")
                    .font(AppFonts.body(13, weight: .regular))
                    .foregroundColor(kPronounHint)
            }
            .padding(.bottom, 12)

            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    SelectablePill(
                        label: "Man",
                        isSelected: selectedGender == "Man",
                        showFlame: false
                    ) {
                        nameFieldFocused = false
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedGender = selectedGender == "Man" ? nil : "Man"
                            showCustomGenderField = false
                            customGenderText = ""
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                    SelectablePill(
                        label: "Woman",
                        isSelected: selectedGender == "Woman",
                        showFlame: false
                    ) {
                        nameFieldFocused = false
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedGender = selectedGender == "Woman" ? nil : "Woman"
                            showCustomGenderField = false
                            customGenderText = ""
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
                HStack(spacing: 10) {
                    SelectablePill(
                        label: "Non-binary",
                        isSelected: selectedGender == "Non-binary",
                        showFlame: false
                    ) {
                        nameFieldFocused = false
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedGender = selectedGender == "Non-binary" ? nil : "Non-binary"
                            showCustomGenderField = false
                            customGenderText = ""
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                    SelectablePill(
                        label: "Something else",
                        isSelected: selectedGender == "Something else",
                        showFlame: false
                    ) {
                        nameFieldFocused = false
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedGender = selectedGender == "Something else"
                                ? nil : "Something else"
                            showCustomGenderField = selectedGender == "Something else"
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }

                SelectablePill(
                    label: "Prefer not to say",
                    isSelected: selectedGender == "Prefer not to say",
                    showFlame: false
                ) {
                    nameFieldFocused = false
                    withAnimation(.easeInOut(duration: 0.25)) {
                        selectedGender = selectedGender == "Prefer not to say"
                            ? nil : "Prefer not to say"
                        showCustomGenderField = false
                        customGenderText = ""
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Gender identity — optional")
    }

    // MARK: - Haptic

    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    // MARK: - Helpers

    private func triggerCollapse() {
        let trimmed = displayName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        typingDebounce?.cancel()
        withAnimation(.easeInOut(duration: 0.35)) {
            nameTextOpacity = 0
            fieldCollapsed = true
        }
        withAnimation(
            .spring(response: 0.6, dampingFraction: 0.85)
            .delay(0.28)
        ) {
            greetingVisible = true
            greetingOwnsName = true
        }
    }

    private func dismissCustomIfNeeded() {
        if showCustomGenderField {
            withAnimation(.easeInOut(duration: 0.3)) {
                showCustomGenderField = false
                customGenderText = ""
            }
        }
    }

    // MARK: - State Restoration

    private func restoreStateIfNeeded() {
        if !data.displayName.isEmpty {
            displayName = data.displayName
        }
        if let savedGender = data.gender {
            selectedGender = savedGender
        }
    }

    // MARK: - Commit

    private func commitData() {
        data.displayName = displayName.trimmingCharacters(in: .whitespaces)
        let custom = customGenderText.trimmingCharacters(in: .whitespaces)
        if !custom.isEmpty {
            data.gender = custom
        } else if let selected = selectedGender {
            data.gender = selected
        }
    }
}

// MARK: - Previews

#Preview("Dark") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.displayName = "Jordan"
        return d
    }()
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config: .name,
            sparkConfig: .nameView,
            opacity: 1.0
        )
        .ignoresSafeArea()
        OnboardingNameView(data: $data, onContinue: {}, onBack: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("Light") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.displayName = "Jordan"
        return d
    }()
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config: .name,
            sparkConfig: .nameView,
            opacity: 1.0
        )
        .ignoresSafeArea()
        OnboardingNameView(data: $data, onContinue: {}, onBack: {})
    }
    .preferredColorScheme(.light)
}

#Preview("Dark — empty state") {
    @Previewable @State var data = OnboardingData()
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config: .name,
            sparkConfig: .nameView,
            opacity: 1.0
        )
        .ignoresSafeArea()
        OnboardingNameView(data: $data, onContinue: {}, onBack: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("Light — empty state") {
    @Previewable @State var data = OnboardingData()
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config: .name,
            sparkConfig: .nameView,
            opacity: 1.0
        )
        .ignoresSafeArea()
        OnboardingNameView(data: $data, onContinue: {}, onBack: {})
    }
    .preferredColorScheme(.light)
}

```

---

## File: `Open Lightly/Features/Onboarding/Views/OnboardingModeSelectView.swift` {#file-open-lightly-features-onboarding-views-onboardingmodeselectview-swift}

```swift
import SwiftUI

// MARK: - Main View

struct OnboardingModeSelectView: View {
    @Binding var data: OnboardingData
    var onContinue: () -> Void
    var onBack: (() -> Void)?

    @State private var titleVisible  = false
    @State private var navVisible    = false
    @State private var cardsVisible  = false
    @State private var hasAnimated   = false

    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }

    private var selectionMade: Bool {
        data.explorationMode != nil && data.nmStage != nil
    }

    private var experienceDescriptor: String? {
        switch data.nmStage {
        case .curious:    return "New to this — maybe I've read about it or know people who do it."
        case .exploring:  return "I've dipped my toes in. A few real experiences."
        case .experienced:return "This has been part of my life for a while."
        case .none:       return nil
        }
    }

    private var atmosphereColors: (primary: Color, secondary: Color) {
        switch data.explorationMode {
        case .solo:     return (AppColors.cyan,    AppColors.deepBlue)
        case .couple:   return (AppColors.magenta, AppColors.purple)
        case .browsing: return (AppColors.gold,    AppColors.orangeHot)
        case .none:     return (AppColors.purple,  AppColors.deepBlue)
        }
    }

    private func handleSelection(_ mode: ExplorationMode) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            if data.explorationMode == mode {
                data.explorationMode = nil
            } else {
                data.explorationMode = mode
            }
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    @ViewBuilder
    private func selectedBorder(
        isSelected:   Bool,
        cornerRadius: CGFloat
    ) -> some View {
        if isSelected {
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        isLight ? AppColors.warmAuroraBorder : AppColors.spectrumGradient,
                        lineWidth: 2
                    )
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        isLight ? AppColors.warmAuroraBorder : AppColors.spectrumGradient,
                        lineWidth: 3
                    )
                    .blur(radius: 4)
                    .opacity(0.25)
            }
        } else {
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(
                    isLight ? AppColors.lightBorder : AppColors.border,
                    lineWidth: 1.5
                )
        }
    }

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let w = geo.size.width

            let sectionSpacing: CGFloat = h < 700
                ? max(8.0, h * 0.012)
                : max(12.0, h * 0.018)

            ZStack {
                Color.clear.ignoresSafeArea()

                if !isLight {
                    Ellipse()
                        .fill(RadialGradient(
                            colors: [
                                atmosphereColors.primary.opacity(0.30),
                                atmosphereColors.secondary.opacity(0.15),
                                Color.clear,
                            ],
                            center: .top,
                            startRadius: 30,
                            endRadius: 360
                        ))
                        .frame(width: OL.atmosW(w), height: OL.atmosH(h))
                        .offset(y: -h * 0.09)
                        .blur(radius: 80)
                        .animation(
                            .easeInOut(duration: 0.9),
                            value: data.explorationMode?.rawValue ?? "none"
                        )
                        .allowsHitTesting(false)
                        .ignoresSafeArea()
                }

                VStack(spacing: 0) {
                    OnboardingNavBar(
                        currentStep: 2,
                        totalSteps:  6,
                        onBack:      onBack
                    )
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .padding(.bottom, max(8.0, h * 0.014))
                    .opacity(navVisible ? 1.0 : 0.18)

                    ViewThatFits(in: .vertical) {
                        VStack(spacing: 0) {
                            contentBlock(sectionSpacing: sectionSpacing, geo: geo)
                            Spacer(minLength: 0)
                            ctaBlock.padding(.horizontal, 24)
                        }
                        VStack(spacing: 0) {
                            ScrollView(showsIndicators: false) {
                                contentBlock(sectionSpacing: sectionSpacing, geo: geo)
                            }
                            ctaBlock.padding(.horizontal, 24)
                        }
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .onAppear {
                guard !hasAnimated else {
                    titleVisible = true
                    cardsVisible = true
                    navVisible   = true
                    return
                }
                hasAnimated = true
                withAnimation(.easeOut(duration: 0.4).delay(0.15)) { titleVisible = true }
                withAnimation(.easeOut(duration: 0.4).delay(0.35)) { cardsVisible = true }
                withAnimation(.easeOut(duration: 0.3).delay(1.50)) { navVisible   = true }
            }
        }
    }

    // MARK: - Content Block

    private func contentBlock(
        sectionSpacing: CGFloat,
        geo:            GeometryProxy
    ) -> some View {
        let h = geo.size.height
        let tileH: CGFloat = max(130, h * 0.195)

        return VStack(alignment: .leading, spacing: sectionSpacing) {

            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("How are you")
                        .font(AppFonts.heroTitle)
                        .foregroundStyle(isLight
                            ? AppColors.lightTextPrimary
                            : AppColors.textPrimary)
                    LivingText(text: "exploring?", font: AppFonts.heroTitle)
                }
                Text("There's no wrong way to start.")
                    .font(AppFonts.caption)
                    .foregroundStyle(isLight
                        ? AppColors.lightTextSecondary
                        : AppColors.textSecondary)
            }
            .opacity(titleVisible ? 1 : 0)
            .offset(y: titleVisible ? 0 : 12)

            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    bentoCentered(mode: .solo,   tileH: tileH)
                    bentoCentered(mode: .couple, tileH: tileH)
                }
                bentoBar(mode: .browsing)
            }
            .opacity(cardsVisible ? 1 : 0)
            .offset(y: cardsVisible ? 0 : 16)

            // Teaser — fixed height container so experience section never shifts.
            // LivingText crossfades between mode selections via .id().
            // Empty when no selection.
            ZStack {
                Color.clear.frame(height: 36)

                if let mode = data.explorationMode {
                    let teaserText: String = {
                        switch mode {
                        case .solo:     return "Starts with what you actually want."
                        case .couple:   return "Starts with the conversation you've been circling."
                        case .browsing: return "No commitment. Just curiosity."
                        }
                    }()

                    LivingText(
                        text: teaserText,
                        font: AppFonts.body(17, weight: .semibold)
                    )
                    .id(mode)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.35), value: data.explorationMode)
                }
            }
            .frame(maxWidth: .infinity)
            .animation(.easeInOut(duration: 0.35), value: data.explorationMode?.rawValue ?? "none")

            let expVisible = data.explorationMode != nil

            ZStack(alignment: .top) {
                Color.clear.frame(height: 148)

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Your experience")
                            .font(AppFonts.caption)
                            .foregroundStyle(isLight
                                ? AppColors.lightTextSecondary
                                : AppColors.textSecondary)
                        Spacer()
                        Text("No judgment")
                            .font(AppFonts.overline)
                            .foregroundStyle(isLight
                                ? AppColors.lightTextTertiary
                                : AppColors.textTertiary)
                    }

                    HStack(spacing: 10) {
                        SelectablePill(
                            label:      "Curious",
                            isSelected: data.nmStage == .curious,
                            intensity:  .dim,
                            height:     44,
                            fontSize:   15
                        ) {
                            data.nmStage = .curious
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                        SelectablePill(
                            label:      "Exploring",
                            isSelected: data.nmStage == .exploring,
                            intensity:  .warm,
                            height:     44,
                            fontSize:   15
                        ) {
                            data.nmStage = .exploring
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                        SelectablePill(
                            label:      "Experienced",
                            isSelected: data.nmStage == .experienced,
                            intensity:  .alive,
                            height:     44,
                            fontSize:   15
                        ) {
                            data.nmStage = .experienced
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
                    .frame(maxWidth: .infinity)

                    Group {
                        if let descriptor = experienceDescriptor {
                            Text(descriptor)
                                .font(AppFonts.caption)
                                .foregroundStyle(isLight
                                    ? AppColors.lightTextSecondary
                                    : AppColors.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .multilineTextAlignment(.center)
                                .id(data.nmStage)
                                .accessibilityAddTraits(.updatesFrequently)
                        } else {
                            Color.clear.frame(height: 18)
                        }
                    }
                    .animation(.easeOut(duration: 0.25), value: data.nmStage?.rawValue ?? "")

                    Text("You can always change these later.")
                        .font(AppFonts.caption)
                        .foregroundStyle(isLight
                            ? AppColors.lightTextTertiary
                            : AppColors.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .opacity(expVisible ? 1 : 0)
                .allowsHitTesting(expVisible)
                .animation(
                    .spring(response: 0.35, dampingFraction: 0.82),
                    value: expVisible
                )
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, sectionSpacing)
    }

    // MARK: - CTA Block

    private var ctaBlock: some View {
        VStack(spacing: 0) {
            HoloCTAButton(title: "Next", isEnabled: selectionMade) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onContinue()
            }
            OnboardingFooter(text: "Your data is encrypted and always stays yours.")
        }
    }

    // MARK: - Bento Centered Tile

    @ViewBuilder
    private func bentoCentered(
        mode:  ExplorationMode,
        tileH: CGFloat
    ) -> some View {
        let isSelected    = data.explorationMode == mode
        let somethingElse = data.explorationMode != nil && !isSelected
        let filamentSize: CGFloat = min(tileH * 0.52, 88)

        let headline: String = {
            switch mode {
            case .solo:   return "Solo Discovery"
            case .couple: return "Shared Journey"
            default:      return ""
            }
        }()

        let subtitle: String = {
            switch mode {
            case .solo:   return "I want clarity\nfor myself first."
            case .couple: return "Starting the conversation\ntogether."
            default:      return ""
            }
        }()

        Button {
            handleSelection(mode)
        } label: {
            VStack(spacing: 6) {
                Spacer(minLength: 0)

                TileOrbitView(
                    orbitCount: mode == .solo ? 1 : 2,
                    isActive:   isSelected,
                    speed:      1.0,
                    size:       filamentSize
                )
                .frame(width: filamentSize, height: filamentSize)
                .opacity(isSelected ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.4), value: isSelected)

                Text(headline)
                    .font(AppFonts.display(17, weight: .semibold))
                    .foregroundStyle(isLight
                        ? AppColors.lightTextPrimary
                        : AppColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(AppFonts.caption)
                    .foregroundStyle(isLight
                        ? AppColors.lightTextSecondary
                        : AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .frame(height: tileH)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isLight
                        ? (isSelected ? AppColors.lightFrostCard : AppColors.lightFrostPill)
                        : AppColors.cardBg)
            )
            .overlay(selectedBorder(isSelected: isSelected, cornerRadius: 20))
            .shadow(
                color: isSelected
                    ? (isLight
                        ? AppColors.lightShadowMagenta
                        : AppColors.purple.opacity(0.28))
                    : .clear,
                radius: 8
            )
            .shadow(
                color: isSelected
                    ? (isLight
                        ? AppColors.lightShadowPurple
                        : AppColors.cyan.opacity(0.18))
                    : .clear,
                radius: 16
            )
            .shadow(
                color: isSelected
                    ? AppColors.magenta.opacity(isLight ? 0.06 : 0.10)
                    : .clear,
                radius: 28
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : (somethingElse ? 0.965 : 1.0))
        .opacity(somethingElse ? 0.55 : 1.0)
        .animation(
            .spring(response: 0.35, dampingFraction: 0.7),
            value: data.explorationMode?.rawValue ?? "none"
        )
        .accessibilityLabel(headline)
        .accessibilityHint(isSelected ? "Selected" : "Double-tap to select \(headline)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Bento Bar

    @ViewBuilder
    private func bentoBar(mode: ExplorationMode) -> some View {
        let isSelected    = data.explorationMode == mode
        let somethingElse = data.explorationMode != nil && !isSelected
        let filamentSize: CGFloat = 56

        Button {
            handleSelection(mode)
        } label: {
            HStack(spacing: 14) {
                TileOrbitView(
                    orbitCount: 3,
                    isActive:   isSelected,
                    speed:      1.0,
                    size:       filamentSize
                )
                .frame(width: filamentSize, height: filamentSize)
                .animation(.easeInOut(duration: 0.4), value: isSelected)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Safe Learning")
                        .font(AppFonts.display(17, weight: .semibold))
                        .foregroundStyle(isLight
                            ? AppColors.lightTextPrimary
                            : AppColors.textPrimary)
                    Text("Just looking around for now.")
                        .font(AppFonts.caption)
                        .foregroundStyle(isLight
                            ? AppColors.lightTextSecondary
                            : AppColors.textSecondary)
                }

                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, minHeight: 72)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isLight
                        ? (isSelected ? AppColors.lightFrostCard : AppColors.lightFrostPill)
                        : AppColors.cardBg)
            )
            .overlay(selectedBorder(isSelected: isSelected, cornerRadius: 20))
            .shadow(
                color: isSelected
                    ? AppColors.gold.opacity(isLight ? 0.20 : 0.28)
                    : .clear,
                radius: 8
            )
            .shadow(
                color: isSelected
                    ? AppColors.gold.opacity(isLight ? 0.12 : 0.18)
                    : .clear,
                radius: 16
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : (somethingElse ? 0.97 : 1.0))
        .opacity(somethingElse ? 0.55 : 1.0)
        .animation(
            .spring(response: 0.35, dampingFraction: 0.7),
            value: data.explorationMode?.rawValue ?? "none"
        )
        .accessibilityLabel("Safe Learning")
        .accessibilityHint(isSelected ? "Selected" : "Double-tap to select Safe Learning")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Previews

#Preview("Dark — no selection") {
    @Previewable @State var data = OnboardingData()
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config:      .modeSelect,
            sparkConfig: .modeSelectView,
            opacity:     1.0
        )
        .ignoresSafeArea()
        OnboardingModeSelectView(data: $data, onContinue: {}, onBack: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("Dark — Solo selected") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.explorationMode = .solo
        d.nmStage         = .curious
        return d
    }()
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config:      .modeSelect,
            sparkConfig: .modeSelectView,
            opacity:     1.0
        )
        .ignoresSafeArea()
        OnboardingModeSelectView(data: $data, onContinue: {}, onBack: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("Dark — Couple selected") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.explorationMode = .couple
        d.nmStage         = .exploring
        return d
    }()
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config:      .modeSelect,
            sparkConfig: .modeSelectView,
            opacity:     1.0
        )
        .ignoresSafeArea()
        OnboardingModeSelectView(data: $data, onContinue: {}, onBack: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("Dark — Browsing selected") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.explorationMode = .browsing
        d.nmStage         = .curious
        return d
    }()
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config:      .modeSelect,
            sparkConfig: .modeSelectView,
            opacity:     1.0
        )
        .ignoresSafeArea()
        OnboardingModeSelectView(data: $data, onContinue: {}, onBack: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("Light — no selection") {
    @Previewable @State var data = OnboardingData()
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config:      .modeSelect,
            sparkConfig: .modeSelectView,
            opacity:     1.0
        )
        .ignoresSafeArea()
        OnboardingModeSelectView(data: $data, onContinue: {}, onBack: {})
    }
    .preferredColorScheme(.light)
}

#Preview("Light — Couple selected") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.explorationMode = .couple
        d.nmStage         = .exploring
        return d
    }()
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config:      .modeSelect,
            sparkConfig: .modeSelectView,
            opacity:     1.0
        )
        .ignoresSafeArea()
        OnboardingModeSelectView(data: $data, onContinue: {}, onBack: {})
    }
    
}

```

---

## File: `Open Lightly/Features/Onboarding/Views/OnboardingContextView.swift` {#file-open-lightly-features-onboarding-views-onboardingcontextview-swift}

```swift
// Features/Onboarding/Views/OnboardingContextView.swift
//
// Screen 4: Relationship Context — branches on explorationMode
// Solo: 3 cards  |  Couple: 4 cards

import SwiftUI

struct OnboardingContextView: View {
    @Binding var data: OnboardingData
    var onContinue: (() -> Void)?
    var onBack: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    @State private var headerVisible      = false
    @State private var cardsVisible       = false
    @State private var reassuranceVisible = false
    @State private var hasAnimated        = false

    @State private var selection: ContextOption? = nil
    @State private var autoAdvanceFired          = false

    // FIXED: Extracted from body to avoid preview type-checker timeout.
    // `let isLight` inside body was captured across 6+ nested result-builder
    // closure scopes (foregroundStyle ternaries + background Group if/else).
    private var isLight: Bool { colorScheme == .light } // FIXED: was `let isLight` in body

    // MARK: - Option Data

    private let soloOptions: [ContextOption] = [
        ContextOption(
            id: "single", context: .single, intensity: .ember,
            title: "I'm single",
            subtitle: "No partner in the picture",
            detail: "Your journey is yours alone — we'll tailor everything to individual exploration."
        ),
        ContextOption(
            id: "partnered_open", context: .partneredOpen, intensity: .spark,
            title: "I have a partner",
            subtitle: "They know I'm exploring",
            detail: "We'll include prompts that help you navigate with transparency."
        ),
        ContextOption(
            id: "partnered_hidden", context: .partneredHidden, intensity: .blaze,
            title: "I haven't brought it up yet",
            subtitle: "Curious, but the conversation hasn't happened",
            detail: "That's exactly what this is for. We'll help you find the words."
        ),
    ]

    private let coupleOptions: [ContextOption] = [
        ContextOption(
            id: "not_talked", context: .notTalked, intensity: .ember,
            title: "Haven't really talked about it",
            subtitle: "One or both of us is curious",
            detail: "We'll start with the basics — language, comfort levels, and small openings."
        ),
        ContextOption(
            id: "talking", context: .talking, intensity: .flame,
            title: "We've been talking",
            subtitle: "No experience yet, but we're on the same page",
            detail: "Great foundation. We'll build on your shared curiosity with structured prompts."
        ),
        ContextOption(
            id: "some_experience", context: .someExperience, intensity: .inferno,
            title: "We've tried some things",
            subtitle: "Real experiences — good, bad, or somewhere in between",
            detail: "We'll help you process what happened and decide what comes next."
        ),
        ContextOption(
            id: "needs_reset", context: .needsReset, intensity: .nova,
            title: "We need a reset",
            subtitle: "Something's off and we want to find our footing again",
            detail: "We'll focus on repair, reconnection, and rebuilding trust first."
        ),
    ]

    private var options: [ContextOption] {
        data.explorationMode == .couple ? coupleOptions : soloOptions
    }

    private var headlineText: String {
        let name = data.displayName.trimmingCharacters(in: .whitespaces)
        let hasName = !name.isEmpty
        if data.explorationMode == .couple {
            return hasName
                ? "\(name), you're exploring this together."
                : "You're exploring this together."
        } else {
            return hasName
                ? "\(name), you're exploring on your own."
                : "You're exploring on your own."
        }
    }

    private var subheadText: String {
        // NOTE: The solo subhead intentionally ends with an em dash.
        // The card stack below completes the implied sentence — each
        // card title is the answer to "one thing that helps us
        // personalize." This is a deliberate stylistic choice.
        // Change only after user testing confirms it reads as an error
        // rather than an intentional grammatical pause.
        data.explorationMode == .couple
            ? "Where are you two at?"
            : "One thing that helps us personalize —"
    }

    private var reassuranceText: String {
        data.explorationMode == .couple
            ? "Every starting point is valid."
            : "No judgment on any answer."
    }

    // FIXED: Extracted from body — inline AnyShapeStyle ternary with LinearGradient
    // inside .foregroundStyle() exceeded the preview type-checker's inference budget.
    private var reassuranceGradientStyle: AnyShapeStyle { // FIXED: extracted from body
        if isLight {
            // RULE B — magenta→gold for all display gradient text in light
            return AnyShapeStyle(LinearGradient(
                stops: [
                    .init(color: AppColors.magenta,   location: 0.00),
                    .init(color: AppColors.orangeHot, location: 0.55),
                    .init(color: AppColors.gold,      location: 1.00),
                ],
                startPoint: .leading,
                endPoint: .trailing
            ))
        } else {
            // Dark path — byte-for-byte unchanged
            return AnyShapeStyle(LinearGradient(
                colors: [AppColors.cyan, AppColors.purple],
                startPoint: .leading,
                endPoint: .trailing
            ))
        }
    }

    private var headlineStyle: AnyShapeStyle { // FIXED: extracted from body
        isLight
            ? AnyShapeStyle(AppColors.lightCardTitle)
            : AnyShapeStyle(AppColors.textPrimary)
    }

    private var subheadStyle: AnyShapeStyle { // FIXED: extracted from body
        isLight
            ? AnyShapeStyle(AppColors.lightCardTitle.opacity(0.65))
            : AnyShapeStyle(AppColors.textSecondary)
    }

    private var pronounLabelStyle: AnyShapeStyle { // FIXED: extracted from body
        isLight
            ? AnyShapeStyle(AppColors.lightTextTertiary)
            : AnyShapeStyle(AppColors.textTertiary)
    }

    // MARK: - Accessibility

    // Provides a spoken summary of the current front card
    // for VoiceOver users who cannot see the visual stack.
    private var accessibilityStackLabel: String {
        guard let current = selection ?? options.first else {
            return "Relationship context selection. \(options.count) options available."
        }
        return "\(current.title). \(current.subtitle). \(current.detail)"
    }

    // Allows VoiceOver swipe-up / swipe-down to navigate the
    // card stack without requiring drag gestures.
    // Note: direction parameter type is inferred — AccessibilityAdjustableAction
    // is not available as a standalone named type in SwiftUI.

    // MARK: - Extracted Decoration Layers
    //
    // FIXED: Extracted from body modifier chain to reduce result-builder
    // expression depth, same pattern as OnboardingGroundRulesView.

    // LAYOUT-FIX: converted from var to func(size:) so the atmosphere ellipse
    // can receive proportional dimensions from the GeometryReader in body.
    private func backgroundLayer(size: CGSize) -> some View {
        ZStack {
            Color.clear.ignoresSafeArea()

            // Dark mode screen-specific accent — kept, not atmosphere
            if !isLight {
                Ellipse()
                    .fill(RadialGradient(
                        colors: [
                            AppColors.purple.opacity(0.3),
                            AppColors.deepBlue.opacity(0.15),
                            Color.clear
                        ],
                        center: .top,
                        startRadius: 30,
                        endRadius: 360
                    ))
                    .frame(width: OL.atmosW(size.width), height: OL.atmosH(size.height)) // LAYOUT-FIX: was 600×500
                    .offset(y: -size.height * 0.09)                                       // LAYOUT-FIX: was -80
                    .blur(radius: 80)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in // LAYOUT-FIX: single GeometryReader for proportional spacing
        let h = geo.size.height
        VStack(spacing: 0) {

            OnboardingNavBar(currentStep: 3, totalSteps: 6, onBack: onBack)
                .padding(.top, OL.navTop(h))        // LAYOUT-FIX: was 12 hardcoded
                .padding(.bottom, OL.navBottom(h))  // LAYOUT-FIX: was 20 hardcoded
                .padding(.horizontal, 24)
                .opacity(headerVisible ? 1 : 0)
                .offset(y: headerVisible ? 0 : -8)

            VStack(alignment: .leading, spacing: OL.compact(h)) { // LAYOUT-FIX: was 8 hardcoded
                Text(headlineText)
                    .font(AppFonts.heroTitle)
                    .foregroundStyle(headlineStyle)
                    .fixedSize(horizontal: false, vertical: true)

                Text(subheadText)
                    .font(AppFonts.caption)
                    .foregroundStyle(subheadStyle)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .opacity(headerVisible ? 1 : 0)
            .offset(y: headerVisible ? 0 : 12)

            Spacer(minLength: OL.spacerMin(h)) // LAYOUT-FIX: unbounded above, min prevents crowding on SE

            ContextCardStack(
                selection: $selection,
                options: options,
                onAdvance: handleAdvance
            )
            .opacity(cardsVisible ? 1 : 0)
            .offset(y: cardsVisible ? 0 : 16)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityStackLabel)
            .accessibilityHint("Swipe left or right to browse options. Double-tap to select the current card.")
            .accessibilityValue(selection?.title ?? "No selection")
            .accessibilityAdjustableAction { direction in
                let currentIndex = options.firstIndex(where: {
                    $0.id == (selection ?? options.first)?.id
                }) ?? 0
                let newIndex: Int
                switch direction {
                case .increment:
                    newIndex = min(currentIndex + 1, options.count - 1)
                case .decrement:
                    newIndex = max(currentIndex - 1, 0)
                @unknown default:
                    return
                }
                withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                    selection = options[newIndex]
                }
            }
            .accessibilityAction(named: "Select") {
                handleAdvance()
            }

            Spacer(minLength: OL.spacerMin(h)) // LAYOUT-FIX: unbounded above, min prevents crowding on SE

            Text(reassuranceText)
                .font(AppFonts.caption)
                .foregroundStyle(reassuranceGradientStyle) // FIXED: uses pre-resolved property
                .frame(maxWidth: .infinity, alignment: .center)
                .opacity(reassuranceVisible ? 1 : 0)
                .offset(y: reassuranceVisible ? 0 : 8)
                .accessibilityAddTraits(.isStaticText)
                .accessibilityLabel(reassuranceText)

            OnboardingFooter(text: "Your data is encrypted and always stays yours.")
                .padding(.horizontal, 24)
                .accessibilityHidden(true)
        }
        .background { backgroundLayer(size: geo.size) } // LAYOUT-FIX: passes live size for proportional atmosphere
        // RULE D — .preferredColorScheme(.dark) removed;
        // screen now responds to system appearance.
        // BrandView and BuildingPathView remain permanently dark.
        .onAppear {
            #if DEBUG
            assert(
                data.explorationMode == .solo || data.explorationMode == .couple,
                "OnboardingContextView: received explorationMode " +
                "\(String(describing: data.explorationMode)) — " +
                "this screen should only be presented for .solo or .couple. " +
                "Browsing users must be routed to CuriosityPickerView."
            )
            #endif
            restoreSelectionIfNeeded()
            guard !hasAnimated else { return }
            hasAnimated = true
            runEntranceAnimations()
        }
        } // LAYOUT-FIX: end GeometryReader
    }

    // MARK: - Actions

    private func handleAdvance() {
        guard !autoAdvanceFired else { return }
        guard let confirmedContext = selection?.context else {
            // selection is nil — ContextCardStack fired onAdvance
            // before a card was confirmed. Do not advance.
            // This should never happen in production.
            assertionFailure(
                "OnboardingContextView: handleAdvance() called " +
                "with nil selection — ContextCardStack contract violated."
            )
            return
        }
        autoAdvanceFired = true
        data.relationshipContext = confirmedContext
        #if DEBUG
        assert(onContinue != nil,
            "OnboardingContextView: onContinue not injected — " +
            "wire this callback from the coordinator.")
        #endif
        onContinue?()
    }

    // MARK: - State Restoration

    private func restoreSelectionIfNeeded() {
        // Restore confirmed selection from the binding on back navigation.
        // Only restores if data has a committed value — safe on first appear
        // (data.relationshipContext will be nil, no-op).
        guard let context = data.relationshipContext else { return }
        if selection?.context != context {
            selection = options.first(where: { $0.context == context })
        }
    }

    // MARK: - Animations

    private func runEntranceAnimations() {
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            headerVisible      = true
            cardsVisible       = true
            reassuranceVisible = true
            return
        }
        #endif
        withAnimation(.easeOut(duration: 0.5).delay(0.15)) { headerVisible      = true }
        withAnimation(.easeOut(duration: 0.5).delay(0.30)) { cardsVisible       = true }
        withAnimation(.easeOut(duration: 0.5).delay(0.55)) { reassuranceVisible = true }
    }
}

// MARK: - Previews

#Preview("Dark") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.displayName     = "Jordan"
        d.explorationMode = .couple
        return d
    }()
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config: .contextSelect,
            sparkConfig: .contextView,
            opacity: 1.0
        )
        .ignoresSafeArea()
        OnboardingContextView(data: $data, onContinue: {}, onBack: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("Light") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.displayName     = "Jordan"
        d.explorationMode = .solo
        return d
    }()
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config: .contextSelect,
            sparkConfig: .contextView,
            opacity: 1.0
        )
        .ignoresSafeArea()
        OnboardingContextView(data: $data, onContinue: {}, onBack: {})
    }
    .preferredColorScheme(.light)
}

// MARK: - Changes applied
// ISSUE 1:  ContextCardStack — added .accessibilityElement,
//           .accessibilityLabel (accessibilityStackLabel computed
//           property), .accessibilityHint, .accessibilityValue,
//           .accessibilityAdjustableAction (accessibilityNavigate),
//           and .accessibilityAction("Select"); VoiceOver users
//           can now navigate and confirm cards without gestures
// ISSUE 2:  Added @State hasAnimated guard; added
//           restoreSelectionIfNeeded() call before guard in
//           onAppear; prevents re-animation on back navigation
// ISSUE 3:  Added restoreSelectionIfNeeded() — restores selection
//           from data.relationshipContext on every appear;
//           card stack shows confirmed state on back navigation
// ISSUE 4:  handleAdvance() — added guard let confirmedContext
//           defensive nil check with assertionFailure for
//           ContextCardStack contract violation
// ISSUE 5:  Added #if DEBUG assert in onAppear verifying
//           explorationMode is .solo or .couple; guards against
//           browsing users being routed here incorrectly
// ISSUE 6:  headlineText — updated to prepend data.displayName
//           when non-empty; falls back to original copy when
//           displayName is empty; first use of name in the flow
// ISSUE 7:  handleAdvance() — added #if DEBUG assert for missing
//           onContinue callback, mirroring Screens 1–3 pattern
// ISSUE 8:  Reassurance Text — added .accessibilityAddTraits +
//           .accessibilityLabel; OnboardingFooter marked
//           .accessibilityHidden(true) to reduce VoiceOver noise
// ISSUE 9:  Added explanatory comment on subheadText documenting
//           the intentional em dash; copy unchanged
// ISSUE 10: Added two new #Preview variants: "Solo — with name"
//           and "Couple — with name" to verify ISSUE 6 behavior
// ISSUE 11: Light mode pass — removed .preferredColorScheme(.dark);
//           added @Environment(\.colorScheme); branched background
//           to lightPageBg + AuroraGlowField + SparkField(.contextView)
//           in light; headlineText → lightTextPrimary in light;
//           subheadText → lightTextSecondary in light; reassurance
//           gradient → magenta→gold in light (dark path unchanged);
//           added 4 light preview variants alongside existing 4 dark
// ISSUE 12: Preview fix — extracted `let isLight` from body to
//           `private var isLight: Bool`; extracted background ZStack
//           to `backgroundLayer` property; extracted reassurance
//           gradient to `reassuranceGradientStyle` property.
//           Root cause: 6+ closure captures of `let isLight` inside
//           @ViewBuilder body exceeded preview type-checker budget.
// ISSUE 13: Revert NavArrow integration in OnboardingContextView:
//           restore top bar onBack, remove NavArrow block from bottom
// ISSUE 14: Added headlineStyle, subheadStyle, and pronounLabelStyle
//           as extracted computed properties below reassuranceGradientStyle

```

---

## File: `Open Lightly/Features/Onboarding/Views/OnboardingCuriosityPickerView.swift` {#file-open-lightly-features-onboarding-views-onboardingcuriositypickerview-swift}

```swift
//
//  OnboardingCuriosityPickerView.swift
//  Open Lightly
//
//  Screen 5 — Two-panel interest & intent picker.
//  Config is fully derived from OnboardingData — no mode checks in the view.
//
//  PANEL ARCHITECTURE:
//  CuriosityPanelStrip owns the horizontal swipe gesture and translation.
//  Panel 1 (communicationGoals) and Panel 2 (learningGoals) slide as one
//  strip through a fixed window. Nav, status strip, CTA, and footer are
//  fixed — they never move. The atmosphere lives in OnboardingFlowView's
//  ZStack and is unaffected by this view's gesture entirely.
//

import SwiftUI

// MARK: - Section Identity

private enum PickerSection {
    case one, two
}

// MARK: - Main View

struct OnboardingCuriosityPickerView: View {
    @Binding var data: OnboardingData
    var onContinue: (() -> Void)?
    var onBack: (() -> Void)?

    // MARK: - State

    @State private var selectedCommunicationGoals: Set<String> = []
    @State private var selectedLearningGoals:      Set<String> = []
    @State private var headerVisible      = false
    @State private var section1Visible    = false
    @State private var reassuranceVisible = false
    @State private var currentPanel:      Int  = 0

    // ── Card deal entrance state ───────────────────────────────────────
    @State private var c1Visible:    Bool = false
    @State private var c2Visible:    Bool = false
    @State private var c1SlideDone:  Bool = false
    @State private var c2SlideDone:  Bool = false
    @State private var swept:        Bool = false
    @State private var c1Flipped:    Bool = false
    @State private var dealComplete: Bool = false
    @State private var zooming:      Bool = false
    @State private var zoomComplete: Bool = false
    @State private var cardsSettled: Bool = false
    @State private var dragOffset:      CGFloat = 0
    @State private var isDragging:      Bool    = false
    @State private var isTransitioning: Bool    = false

    @Environment(\.colorScheme)     private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    // MARK: - Computed

    private var isLight: Bool { colorScheme == .light }

    private var config: CuriosityScreenConfig {
        data.curiosityScreenConfig
    }

    private var hasSelection: Bool {
        !selectedCommunicationGoals.isEmpty && !selectedLearningGoals.isEmpty
    }

    private var totalSelected: Int {
        selectedCommunicationGoals.count + selectedLearningGoals.count
    }

    private var pillColumns: [GridItem] {
        [GridItem(.flexible(), alignment: .top)]
    }

    private var reassuranceGradientStyle: AnyShapeStyle {
        if isLight {
            return AnyShapeStyle(LinearGradient(
                stops: [
                    .init(color: AppColors.magenta,   location: 0.00),
                    .init(color: AppColors.orangeHot, location: 0.55),
                    .init(color: AppColors.gold,      location: 1.00),
                ],
                startPoint: .leading,
                endPoint: .trailing
            ))
        } else {
            return AnyShapeStyle(LinearGradient(
                colors: [AppColors.cyan, AppColors.purple, AppColors.magenta],
                startPoint: .leading,
                endPoint: .trailing
            ))
        }
    }

    private func backgroundLayer(size: CGSize) -> some View {
        ZStack {
            Color.clear.ignoresSafeArea()
            if !isLight {
                // Top atmosphere — stronger purple crown
                Ellipse()
                    .fill(RadialGradient(
                        colors: [
                            AppColors.purple.opacity(0.45),
                            AppColors.deepBlue.opacity(0.20),
                            Color.clear,
                        ],
                        center: .top,
                        startRadius: 30,
                        endRadius: 400
                    ))
                    .frame(width: OL.atmosW(size.width), height: OL.atmosH(size.height))
                    .offset(y: -size.height * 0.06)
                    .blur(radius: 80)

                // Mid atmosphere — fills the dead zone between card and CTA
                Ellipse()
                    .fill(RadialGradient(
                        colors: [
                            AppColors.cyan.opacity(0.08),
                            AppColors.purple.opacity(0.06),
                            Color.clear,
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 280
                    ))
                    .frame(width: size.width * 1.2, height: size.height * 0.40)
                    .offset(y: size.height * 0.18)
                    .blur(radius: 60)

                // Bottom atmosphere — anchored at lower third
                Ellipse()
                    .fill(RadialGradient(
                        colors: [
                            AppColors.magenta.opacity(0.18),
                            AppColors.purple.opacity(0.12),
                            Color.clear,
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 320
                    ))
                    .frame(width: OL.atmosW(size.width), height: OL.atmosH(size.height))
                    .offset(y: size.height * 0.75)
                    .blur(radius: 70)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let w = geo.size.width

            // Height available for the sliding panel strip.
            // Subtract the fixed shell elements: nav + status strip +
            // nudge + reassurance + CTA + footer.
            let fixedH: CGFloat = OL.navTop(h) + OL.navBottom(h) + 56
                                + 44 + 26 + 22 + 10 + 56 + 60
            let availableH = h - fixedH
            let minH = h * 0.42
            let maxH = h * 0.62
            let stripH: CGFloat = min(max(minH, availableH), maxH)

            VStack(spacing: 0) {

                // ── FIXED: Nav bar ────────────────────────────────────
                OnboardingNavBar(
                    currentStep: 4,
                    totalSteps: 6,
                    onBack: onBack
                )
                .padding(.top, OL.navTop(h))
                .padding(.bottom, OL.navBottom(h))
                .padding(.horizontal, 24)
                .opacity(headerVisible ? 1 : 0)
                .offset(y: headerVisible ? 0 : -8)

                // ── SLIDING: Two-panel content strip ──────────────────
                ZStack {
                    if c2Visible {
                        CuriosityFlipCard(isFlipped: cardsSettled ? true : (currentPanel == 1 && dealComplete)) {
                            cardFrontContent(
                                panel:        .two,
                                options:      config.section2Options,
                                selectedKeys: $selectedLearningGoals,
                                isVisible:    true,
                                h:            h
                            )
                        }
                        .frame(width: w - 32, height: stripH)
                        .scaleEffect({
                            if cardsSettled { return currentPanel == 1 ? 1.0 : 0.92 }
                            if zoomComplete { return 0.92 }
                            if zooming      { return 0.88 }
                            if c2SlideDone  { return 0.62 }
                            return 0.55
                        }())
                        .offset(
                            x: {
                                if cardsSettled { return currentPanel == 1 ? 0 : 5 }
                                if zoomComplete { return swept ? 5 : w / 2 + 8 }
                                if zooming      { return w * 0.18 }
                                if c2SlideDone  { return w * 0.30 }
                                return w * 1.6
                            }(),
                            y: {
                                if cardsSettled { return currentPanel == 1 ? 0 : 9 }
                                if zoomComplete { return swept ? 9 : 0 }
                                if zooming      { return -8 }
                                return 0
                            }()
                        )
                        .opacity(c2Visible ? (cardsSettled && currentPanel == 1 ? 1.0 : 0.90) : 0)
                        .animation(.spring(response: 0.38, dampingFraction: 0.78), value: zooming)
                        .animation(.spring(response: 0.28, dampingFraction: 0.85), value: zoomComplete)
                        .animation(.spring(response: 0.28, dampingFraction: 0.80), value: c2SlideDone)
                        .animation(.spring(response: 0.40, dampingFraction: 0.80), value: swept)
                        .animation(.spring(response: 0.40, dampingFraction: 0.80), value: currentPanel)
                        .allowsHitTesting(cardsSettled && currentPanel == 1)
                        .zIndex(cardsSettled && currentPanel == 1 ? 3 : 1)
                    }

                    if c1Visible {
                        CuriosityFlipCard(isFlipped: cardsSettled ? true : (currentPanel == 0 ? c1Flipped : dealComplete)) {
                            cardFrontContent(
                                panel:        .one,
                                options:      config.section1Options,
                                selectedKeys: $selectedCommunicationGoals,
                                isVisible:    section1Visible,
                                h:            h
                            )
                        }
                        .frame(width: w - 32, height: stripH)
                        .scaleEffect({
                            if cardsSettled { return currentPanel == 0 ? 1.0 : 0.92 }
                            if zoomComplete { return 1.0 }
                            if zooming      { return 0.92 }
                            if c1SlideDone  { return 0.62 }
                            return 0.55
                        }())
                        .offset(
                            x: {
                                if cardsSettled { return currentPanel == 0 ? 0 : 5 }
                                if zoomComplete { return swept ? 0 : -(w / 2 + 8) }
                                if zooming      { return -w * 0.18 }
                                if c1SlideDone  { return -w * 0.30 }
                                return -w * 1.6
                            }(),
                            y: {
                                if cardsSettled { return currentPanel == 0 ? 0 : 9 }
                                if zoomComplete { return 0 }
                                if zooming      { return -8 }
                                return 0
                            }()
                        )
                        .opacity(c1Visible ? (cardsSettled && currentPanel == 0 ? 1.0 : 0.90) : 0)
                        .animation(.spring(response: 0.55, dampingFraction: 0.72), value: zooming)
                        .animation(.spring(response: 0.40, dampingFraction: 0.80), value: zoomComplete)
                        .animation(.spring(response: 0.28, dampingFraction: 0.80), value: c1SlideDone)
                        .animation(.spring(response: 0.40, dampingFraction: 0.80), value: swept)
                        .animation(.spring(response: 0.40, dampingFraction: 0.80), value: currentPanel)
                        .allowsHitTesting(cardsSettled && currentPanel == 0)
                        .zIndex(cardsSettled && currentPanel == 0 ? 3 : 2)
                    }
                }
                .frame(width: w, height: stripH)
                .padding(.bottom, 4)
                .highPriorityGesture(
                    DragGesture(minimumDistance: 20)
                        .onChanged { value in
                            guard dealComplete, !isTransitioning else { return }
                            isDragging = true
                            let raw = value.translation.width
                            if currentPanel == 0 && raw > 0 {
                                dragOffset = raw * 0.18
                            } else if currentPanel == 1 && raw < 0 {
                                dragOffset = raw * 0.18
                            } else {
                                dragOffset = raw
                            }
                        }
                        .onEnded { value in
                            isDragging = false
                            handleSwipe(
                                offset:    value.translation.width,
                                predicted: value.predictedEndTranslation.width
                            )
                        }
                )

                // ── FIXED: Status strip ───────────────────────────────
                CuriosityStatusStrip(
                    currentPanel:  currentPanel,
                    totalSelected: totalSelected,
                    isLight:       isLight
                )
                .padding(.horizontal, 24)

                // ── FIXED: Reassurance ────────────────────────────────
                Text("No wrong answers. You can always explore more later.")
                    .font(AppFonts.caption)
                    .foregroundStyle(reassuranceGradientStyle)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 24)
                    .opacity(totalSelected > 0 ? 0.75 : 0)
                    .animation(.easeOut(duration: 0.4), value: totalSelected > 0)
                    .padding(.bottom, 10)

                // ── FIXED: CTA ────────────────────────────────────────
                HoloCTAButton(
                    title: "Show me my path",
                    isEnabled: hasSelection
                ) {
                    handleContinue()
                }
                .padding(.horizontal, 24)

                // ── FIXED: Footer ─────────────────────────────────────
                OnboardingFooter()
                    .opacity(0.5)
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .background { backgroundLayer(size: geo.size) }
            .onAppear {
                restoreSelectionsIfNeeded()
                runEntranceAnimations()
                runDealAnimation()
                print("=== CuriosityPicker Debug ===")
                print("mode: \(String(describing: data.explorationMode))")
                print("context: \(String(describing: data.relationshipContext))")
                print("nmStage: \(String(describing: data.nmStage))")
                print("s1Label: \(config.section1Label)")
                print("s2Label: \(config.section2Label)")
                print("s1Count: \(config.section1Options.count)")
                print("s2Count: \(config.section2Options.count)")
                print("=============================")
            }
        }
    }

    // MARK: - Section Header

    private func sectionHeader(label: String, sublabel: String, h: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: max(6, h * 0.009)) {
            Text(label)
                .font(h < 700
                    ? AppFonts.display(20, weight: .semibold)
                    : h < 900
                        ? AppFonts.screenTitle
                        : AppFonts.display(26, weight: .semibold))
                .foregroundStyle(
                    isLight
                        ? AnyShapeStyle(AppColors.lightCardTitle)
                        : AnyShapeStyle(AppColors.textPrimary)
                )
                .fixedSize(horizontal: false, vertical: true)

            Text(sublabel)
                .font(AppFonts.caption)
                .foregroundStyle(
                    isLight
                        ? AnyShapeStyle(AppColors.lightCardTitle.opacity(0.65))
                        : AnyShapeStyle(AppColors.textSecondary)
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Pill Grid

    private func pillGrid(
        options: [CuriosityOption],
        selectedKeys: Binding<Set<String>>,
        isVisible: Bool,
        section: PickerSection,
        h: CGFloat = 852
    ) -> some View {
        let isOdd = options.count % 2 != 0

        return VStack(alignment: .trailing, spacing: 6) {
            LazyVGrid(columns: pillColumns, spacing: max(4, h * 0.007)) {
                ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                    let isLast = index == options.count - 1
                    CuriosityPill(
                        option:     option,
                        isSelected: selectedKeys.wrappedValue.contains(option.id),
                        pillHeight: max(40, min(52, h * 0.056)),
                        onTap:      { toggleSelection(option.id, in: selectedKeys, section: section) }
                    )
                    .gridCellColumns(isOdd && isLast ? 2 : 1)
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : 12)
                    .animation(
                        .easeOut(duration: 0.4).delay(Double(index) * 0.04),
                        value: isVisible
                    )
                }
            }

            if !selectedKeys.wrappedValue.isEmpty {
                Text("Tap to deselect")
                    .font(AppFonts.caption)
                    .foregroundStyle(
                        isLight
                            ? AnyShapeStyle(AppColors.lightCardTitle.opacity(0.40))
                            : AnyShapeStyle(AppColors.textSecondary.opacity(0.45))
                    )
                    .transition(.opacity)
                    .accessibilityHidden(true)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: selectedKeys.wrappedValue.isEmpty)
    }

    // MARK: - Card Front Content

    private func cardFrontContent(
        panel:        PickerSection,
        options:      [CuriosityOption],
        selectedKeys: Binding<Set<String>>,
        isVisible:    Bool,
        h:            CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(
                label:    panel == .one ? config.section1Label    : config.section2Label,
                sublabel: panel == .one ? config.section1Sublabel : config.section2Sublabel,
                h:        h
            )

            Spacer(minLength: max(12, h * 0.018))

            pillGrid(
                options:      options,
                selectedKeys: selectedKeys,
                isVisible:    isVisible,
                section:      panel
            )

            Spacer(minLength: OL.spacerMin(h))
        }
        .padding(.horizontal, max(16, h * 0.022))
        .padding(.top, max(18, h * 0.026))
        .padding(.bottom, max(14, h * 0.018))
        .frame(maxHeight: .infinity, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.051, green: 0.043, blue: 0.122),
                            Color(red: 0.031, green: 0.024, blue: 0.094),
                        ],
                        startPoint: .topLeading,
                        endPoint:   .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            LinearGradient(
                                colors: [AppColors.cyan, AppColors.purple, AppColors.magenta],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2.5
                        )
                        .opacity(0.55)
                )
        )
        .shadow(color: AppColors.cyan.opacity(0.14), radius: 28)
        .shadow(color: AppColors.purple.opacity(0.10), radius: 40)
        .shadow(color: Color.black.opacity(0.20), radius: 12, y: 6)
    }

    // MARK: - Preview Text Lookup

    private func previewTextFor(optionId: String, in section: PickerSection) -> String {
        let s1Map: [String: String] = [
            "desire_unknown":      "We'll center your path on desire clarity — the cards most people circle for years.",
            "pattern_recognition": "We'll surface what's repeating. Pattern recognition is built into your first deck.",
            "initiating":          "Your early cards focus on finding language before you need to use it.",
            "self_awareness":      "We'll build reflection prompts around what surprises you about yourself.",
            "situationship":       "We'll help you name what you're in before we ask you to navigate it.",
            "desire_mismatch":     "Your path opens with cards that surface mismatches without blame.",
            "reconnection":        "Reconnection cards land early — we'll start with what brought you here.",
            "jealousy_stuck":      "We'll build a jealousy reflection track into your first sessions.",
            "self_unknown":        "Self-clarity cards come first. You'll know more about what you want.",
            "initiating_hidden":   "Your early cards help you find the words before you need them.",
            "desire_mismatch_unilateral": "We'll help you understand what you want before any conversation happens.",
        ]
        let s2Map: [String: String] = [
            "desire_language":       "We'll start with the cards most people need years to find.",
            "attachment":            "Your first deck goes straight to what shapes everything else.",
            "cnm_style_discovery":   "A short quiz unlocks before your first session.",
            "cnm_openness":          "A readiness quiz opens before your first session.",
            "desire_map":            "Your path opens with a private desire inventory.",
            "desire_map_individual": "Both of you map your desires privately — then compare.",
            "jealousy_history":      "We'll build a reflection track around that specifically.",
            "jealousy_literacy":     "Jealousy literacy cards surface early in your sequence.",
            "consent_self_advocacy": "Communication cards land early in your sequence.",
            "consent_ongoing":       "Consent communication cards land early in your sequence.",
            "agreements":            "Agreement-building prompts shape your first three sessions.",
            "compersion":            "Compersion cards arrive once the foundation cards are done.",
            "asymmetric_interest":   "We'll address asymmetry directly — early, not late.",
            "cnm_readiness":         "A readiness reflection opens before your first session.",
            "attachment_style":      "Your attachment quiz unlocks before your first session.",
            "cnm_foundations":       "Foundations cards come first — language before experience.",
            "cnm_style":             "A style discovery quiz opens before your first session.",
        ]
        switch section {
        case .one: return s1Map[optionId] ?? ""
        case .two: return s2Map[optionId] ?? ""
        }
    }

    // MARK: - Helpers

    private func toggleSelection(
        _ key: String,
        in set: Binding<Set<String>>,
        section: PickerSection
    ) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if set.wrappedValue.contains(key) {
                set.wrappedValue.remove(key)
            } else {
                set.wrappedValue.insert(key)
            }
        }
    }

    private func handleContinue() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        if config.showSection2 {
            data.communicationGoals = Array(selectedCommunicationGoals).sorted()
            data.learningGoals      = Array(selectedLearningGoals).sorted()
        } else {
            data.communicationGoals = []
            data.learningGoals      = Array(selectedCommunicationGoals).sorted()
        }
        data.curiositySelections = data.communicationGoals + data.learningGoals
        onContinue?()
    }

    // MARK: - State Restoration

    private func restoreSelectionsIfNeeded() {
        let hasComms    = !data.communicationGoals.isEmpty
        let hasLearning = !data.learningGoals.isEmpty

        if !config.showSection2 {
            if hasLearning {
                selectedCommunicationGoals = Set(data.learningGoals)
            }
        } else {
            if hasComms    { selectedCommunicationGoals = Set(data.communicationGoals) }
            if hasLearning { selectedLearningGoals      = Set(data.learningGoals) }
        }

        if selectedCommunicationGoals.isEmpty && !selectedLearningGoals.isEmpty {
            currentPanel = 0
        } else {
            currentPanel = 0
        }
    }

    // MARK: - Entrance Animations

    private func runEntranceAnimations() {
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            headerVisible   = true
            section1Visible = true
            return
        }
        #endif
        guard !headerVisible else { return }
        withAnimation(.easeOut(duration: 0.5).delay(0.10)) { headerVisible   = true }
        withAnimation(.easeOut(duration: 0.5).delay(0.25)) { section1Visible = true }
    }

    // MARK: - Deal Animation

   private func runDealAnimation() {
        
        // Phase 1 — both cards deal in small, side by side (0.10s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
            c1Visible = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.80)) {
                c1SlideDone = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
            c2Visible = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.48) {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.80)) {
                c2SlideDone = true
            }
        }

        // Phase 2 — 400ms dwell so user registers both cards exist
        // Then zoom + collect: both cards rush toward the viewer
        // while C2 tucks behind C1 (the "square up")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.70) {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                zooming = true
            }
        }

        // Phase 3 — zoom settles, mark complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.88) {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                swept        = true
                zoomComplete = true
            }
        }

        // Phase 4 — flip C1 face-up 300ms after stack settles
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.50) {
            c1Flipped = true
        }

        // Phase 5 — interaction unlocked
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.10) {
            withAnimation(.easeOut(duration: 0.35)) {
                dealComplete = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.40) {
                cardsSettled = true
            }
        }
    }

    private func handleSwipe(offset: CGFloat, predicted: CGFloat) {
        let threshold: CGFloat = 65
        guard dealComplete, !isTransitioning else { return }

        if predicted < -150 || offset < -threshold {
            guard currentPanel == 0 else { return }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            dragOffset = 0
            currentPanel = 1
            isTransitioning = false
        } else if predicted > 150 || offset > threshold {
            guard currentPanel == 1 else { return }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            dragOffset = 0
            currentPanel = 0
            isTransitioning = false
        } else {
            dragOffset = 0
        }
    }
}



// MARK: - CuriosityPreviewLine

private struct CuriosityPreviewLine: View {
    let text:    String
    let isLight: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(text)
                .font(AppFonts.caption)
                .italic()
                .foregroundStyle(
                    isLight
                        ? AppColors.lightCardTitle.opacity(0.70)
                        : AppColors.textSecondary
                )
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    isLight
                        ? AppColors.magenta.opacity(0.05)
                        : AppColors.cyan.opacity(0.05)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(
                            isLight
                                ? AppColors.magenta.opacity(0.12)
                                : AppColors.cyan.opacity(0.12),
                            lineWidth: 1
                        )
                )
        )
        .padding(.top, 8)
        .transition(.opacity.combined(with: .offset(y: 6)))
    }
}

// MARK: - CuriosityPill

private struct CuriosityPill: View {
    let option:     CuriosityOption
    let isSelected: Bool
    let pillHeight: CGFloat
    let onTap:      () -> Void

    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }

    private var accentColor: Color {
        switch option.contentType {
        case .quiz, .desireMap: return AppColors.magenta
        default:                return AppColors.cyan
        }
    }

    private var darkSelectedBorder: LinearGradient {
        switch option.contentType {
        case .quiz, .desireMap:
            return LinearGradient(
                colors: [AppColors.magenta, AppColors.purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                colors: [AppColors.cyan, AppColors.purple, AppColors.magenta],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                ZStack {
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(
                                isLight ? AppColors.magenta : accentColor
                            )
                            .transition(.scale.combined(with: .opacity))
                    } else if option.isEmphasized {
                        Text("✦")
                            .font(.system(size: 8))
                            .foregroundStyle(
                                isLight
                                    ? AppColors.purple.opacity(0.5)
                                    : AppColors.cyan.opacity(0.5)
                            )
                    }
                }
                .frame(width: 16, height: 16)
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
                .accessibilityHidden(true)

                Text(option.label)
                    .font(AppFonts.buttonLabel)
                    .foregroundStyle(
                        isSelected
                            ? (isLight
                                ? AnyShapeStyle(AppColors.lightCardTitle)
                                : AnyShapeStyle(AppColors.textPrimary))
                            : (isLight
                                ? AnyShapeStyle(AppColors.wineDark)
                                : AnyShapeStyle(Color.white))
                    )
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: false)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .frame(height: pillHeight + 8)
            .background(pillBackground)
            .overlay(pillBorder)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(
                color: isSelected
                    ? (isLight
                        ? AppColors.lightShadowMagenta
                        : accentColor.opacity(0.20))
                    : (option.isEmphasized
                        ? (isLight
                            ? Color.clear
                            : AppColors.cyan.opacity(0.06))
                        : .clear),
                radius: isSelected ? 10 : 6
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }

    @ViewBuilder
    private var pillBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(
                isSelected
                    ? (isLight
                        ? LinearGradient(
                            colors: [AppColors.lightFrostPillSel, AppColors.lightFrostPillSel],
                            startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(
                            colors: [accentColor.opacity(0.08), AppColors.purple.opacity(0.06)],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                    : (isLight
                        ? LinearGradient(
                            colors: [AppColors.lightFrostPill, AppColors.lightFrostPill],
                            startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(
                            colors: [AppColors.cardBg, AppColors.cardBg],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
            )
    }

    @ViewBuilder
    private var pillBorder: some View {
        if isSelected {
            if isLight {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            LinearGradient(
                                stops: [
                                    .init(color: AppColors.magenta,   location: 0.00),
                                    .init(color: AppColors.orangeHot, location: 0.50),
                                    .init(color: AppColors.gold,      location: 1.00),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2.5
                        )
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            LinearGradient(
                                stops: [
                                    .init(color: AppColors.magenta,   location: 0.00),
                                    .init(color: AppColors.orangeHot, location: 0.50),
                                    .init(color: AppColors.gold,      location: 1.00),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3.5
                        )
                        .blur(radius: 6)
                        .opacity(0.25)
                }
                .shadow(color: AppColors.lightShadowMagenta, radius: 8,  x: 0, y: 3)
                .shadow(color: AppColors.lightShadowPurple,  radius: 16, x: 0, y: 5)
                .shadow(color: AppColors.lightShadowGold,    radius: 6,  x: 0, y: 2)
            } else {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(darkSelectedBorder, lineWidth: 2)
            }
        } else if option.isEmphasized {
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    isLight
                        ? AppColors.lightBorder
                        : AppColors.cyan.opacity(0.15),
                    lineWidth: 1.5
                )
        } else {
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    isLight ? AppColors.lightBorder : AppColors.border,
                    lineWidth: 1.5
                )
        }
    }
}

// MARK: - CuriosityStatusStrip

private struct CuriosityStatusStrip: View {
    let currentPanel:  Int
    let totalSelected: Int
    let isLight:       Bool

    var body: some View {
        HStack(spacing: 10) {

            Spacer()

            // ── Page dots — shift left when count appears ─────────────
            HStack(spacing: 8) {
                ForEach(0..<2, id: \.self) { i in
                    let isActive = i == currentPanel
                    let dotW: CGFloat = isActive ? 28 : 8
                    let dotH: CGFloat = 8

                    ZStack {
                        RoundedRectangle(cornerRadius: 100)
                            .fill(
                                isActive
                                    ? Color.clear
                                    : (isLight
                                        ? Color.black.opacity(0.12)
                                        : Color.white.opacity(0.15))
                            )
                            .frame(width: dotW, height: dotH)

                        if isActive {
                            RoundedRectangle(cornerRadius: 100)
                                .fill(Color.clear)
                                .frame(width: dotW, height: dotH)
                                .overlay(
                                    Group {
                                        if isLight {
                                            LightModeShimmer(duration: 4, usePillColors: true)
                                        } else {
                                            HolographicShimmer(duration: 4)
                                        }
                                    }
                                    .clipShape(RoundedRectangle(cornerRadius: 100))
                                )
                                .shadow(
                                    color: isLight
                                        ? AppColors.magenta.opacity(0.35)
                                        : AppColors.cyan.opacity(0.55),
                                    radius: 6
                                )
                        }
                    }
                    .frame(width: dotW, height: dotH)
                    .animation(
                        .spring(response: 0.38, dampingFraction: 0.80),
                        value: currentPanel
                    )
                }
            }

            // ── Count — slides in to the right of the dots ────────────
            if totalSelected > 0 {
                HStack(spacing: 5) {
                    Rectangle()
                        .fill(isLight
                            ? Color.black.opacity(0.10)
                            : Color.white.opacity(0.12))
                        .frame(width: 1, height: 10)

                    Text("\(totalSelected) selected")
                        .font(AppFonts.overline)
                        .tracking(1.2)
                        .foregroundStyle(
                            isLight
                                ? AppColors.lightCardTitle.opacity(0.40)
                                : AppColors.textTertiary
                        )
                }
                .transition(
                    .asymmetric(
                        insertion: .offset(x: 8).combined(with: .opacity),
                        removal:   .offset(x: 8).combined(with: .opacity)
                    )
                )
            }

            Spacer()
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.80), value: totalSelected > 0)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }
}

// MARK: - CuriosityPanelNudge

private struct CuriosityPanelNudge: View {
    let s1Empty: Bool
    let s2Empty: Bool
    let isLight: Bool
    
    private var text: String? {
        if s1Empty && s2Empty  { return "Select from both panels to continue" }
        if !s1Empty && s2Empty { return "Swipe right — pick one more thing →" }
        if s1Empty && !s2Empty { return "← Swipe back — pick one thing there too" }
        return nil
    }
    
    var body: some View {
        ZStack {
            if let nudge = text {
                Text(nudge)
                    .font(AppFonts.caption)
                    .foregroundStyle(isLight ? AppColors.lightCardTitle.opacity(0.35) : AppColors.textTertiary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .transition(.opacity.combined(with: .offset(y: 4)))
                    .id(nudge)
            }
        }
        .frame(height: 22)
        .animation(.easeOut(duration: 0.3), value: text)
        .padding(.bottom, 4)
    }
}
    private struct CuriosityCardBack: View {
        @Environment(\.colorScheme) private var colorScheme

        var body: some View {
            ZStack {
                // Base fill
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.051, green: 0.043, blue: 0.122),
                                Color(red: 0.031, green: 0.024, blue: 0.094),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Ambient center glow
                RadialGradient(
                    colors: [
                        AppColors.purple.opacity(0.18),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 120
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))

                // Inner orbit
                GeometryReader { geo in
                    let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                    let size: CGFloat = 70
                    OrbitSparkBorderView(
                        size:         CGSize(width: size, height: size),
                        cornerRadius: size / 2,
                        borderWidth:  1.5,
                        colorScheme:  colorScheme
                    )
                    .position(center)
                }

                // Outer orbit
                GeometryReader { geo in
                    let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                    let size: CGFloat = 120
                    OrbitSparkBorderView(
                        size:         CGSize(width: size, height: size),
                        cornerRadius: size / 2,
                        borderWidth:  1.5,
                        colorScheme:  colorScheme
                    )
                    .opacity(0.55)
                    .position(center)
                }

                // Corner marks
                VStack {
                    HStack {
                        Text("✦")
                            .font(AppFonts.overline)
                            .foregroundStyle(AppColors.purple.opacity(0.40))
                        Spacer()
                        Text("✦")
                            .font(AppFonts.overline)
                            .foregroundStyle(AppColors.purple.opacity(0.40))
                    }
                    Spacer()
                    HStack {
                        Text("✦")
                            .font(AppFonts.overline)
                            .foregroundStyle(AppColors.purple.opacity(0.40))
                        Spacer()
                        Text("✦")
                            .font(AppFonts.overline)
                            .foregroundStyle(AppColors.purple.opacity(0.40))
                    }
                }
                .padding(14)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(
                        LinearGradient(
                            colors: [AppColors.purple, AppColors.cyan, AppColors.magenta],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2.5
                    )
                    .opacity(0.65)
            )
            .shadow(color: AppColors.purple.opacity(0.20), radius: 20)
            .shadow(color: Color.black.opacity(0.20), radius: 12, y: 6)
        }
    }
    // MARK: - CuriosityFlipCard

    private struct CuriosityFlipCard<Content: View>: View {
        let isFlipped:   Bool
        let content:     () -> Content

        var body: some View {
            ZStack {
                // Back face — shows when not flipped
                CuriosityCardBack()
                    .rotation3DEffect(
                        .degrees(isFlipped ? 180 : 0),
                        axis: (x: 0, y: 1, z: 0),
                        perspective: 0.6
                    )
                    .opacity(isFlipped ? 0 : 1)

                // Front face — shows when flipped
                content()
                    .rotation3DEffect(
                        .degrees(isFlipped ? 0 : -180),
                        axis: (x: 0, y: 1, z: 0),
                        perspective: 0.6
                    )
                    .opacity(isFlipped ? 1 : 0)
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.82), value: isFlipped)
        }
    }


// MARK: - Previews

#Preview("Dark — Solo") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.displayName     = "Jordan"
        d.explorationMode = .solo
        return d
    }()
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config: .curiosityPicker,
            sparkConfig: .curiosityPickerView,
            opacity: 1.0
        )
        .ignoresSafeArea()
        OnboardingCuriosityPickerView(data: $data)
    }
    .preferredColorScheme(.dark)
}

#Preview("Light — Solo") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.displayName     = "Jordan"
        d.explorationMode = .solo
        return d
    }()
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config: .curiosityPicker,
            sparkConfig: .curiosityPickerView,
            opacity: 1.0
        )
        .ignoresSafeArea()
        OnboardingCuriosityPickerView(data: $data)
    }
    .preferredColorScheme(.light)
}

#Preview("Dark — Couple") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.displayName     = "Jordan"
        d.explorationMode = .couple
        return d
    }()
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config: .curiosityPicker,
            sparkConfig: .curiosityPickerView,
            opacity: 1.0
        )
        .ignoresSafeArea()
        OnboardingCuriosityPickerView(data: $data)
    }
    .preferredColorScheme(.dark)
}
 

```

---

## File: `Open Lightly/Features/Onboarding/Views/OnboardingBuildingPathView.swift` {#file-open-lightly-features-onboarding-views-onboardingbuildingpathview-swift}

```swift
// Features/Onboarding/Views/OnboardingBuildingPathView.swift
//
// REVISION 3 — fixes persistent rightward layout offset.
//
// ROOT CAUSE (correct diagnosis):
//
// Revisions 1 and 2 correctly identified that .ignoresSafeArea() children
// were involved, but applied the wrong fix (.frame on the ZStack). The
// actual mechanism: when multiple children inside a ZStack use
// .ignoresSafeArea(), the ZStack computes its internal alignment origin
// from the UNION of all children's frames — including safe-area-extended
// frames. This shifts the alignment center rightward (and/or downward),
// dragging all content with it. .frame(width:height:) on the ZStack only
// constrains its external reported size; it does NOT override the internal
// alignment computation.
//
// FIX:
//
// All .ignoresSafeArea() layers (pageBg, atmosphere, OnboardingGlowField,
// fade overlay) are moved OUT of the ZStack into .background() and
// .overlay() modifiers. These modifiers render content behind/above the
// ZStack respectively but do NOT participate in the ZStack's alignment
// computation. The ZStack now contains ONLY non-ignoresSafeArea children
// (fragmentLayer, mainContent, skipAffordance, accessibility overlay),
// so its alignment origin is the true center of its frame.
//
// fragmentLayer()'s .ignoresSafeArea() is also removed — it was
// unnecessary since the parent ZStack already covers the full screen
// via the outer GeometryReader's .ignoresSafeArea().
//
// All BUG-1 through BUG-7 and R-BUG-1 through R-BUG-3 fixes from
// prior revisions are preserved where still applicable.

import SwiftUI

// MARK: - Supporting Types

private enum BPIndicatorState: Equatable {
case pending
case processing
case complete
}

private struct BPBuildItem {
let category: String
let resolved: String
}

private struct BPFragmentState {
var visible: Bool = false
var fading:  Bool = false
}

// MARK: - Main View

struct OnboardingBuildingPathView: View {
@Binding var data: OnboardingData
var onFinished: (() -> Void)? = nil



@Environment(\.colorScheme) private var colorScheme

@State private var screenW: CGFloat = 393
@State private var screenH: CGFloat = 852

@State private var hasAnimated = false
@State private var atmosphericVisible = false
@State private var glowPeak           = false
@State private var overlabelVisible   = false
@State private var nameVisible        = false
@State private var taglineVisible     = false

@State private var indicatorStates: [BPIndicatorState] = [
    .pending, .pending, .pending, .pending
]
@State private var fragmentStates: [BPFragmentState] = [
    BPFragmentState(), BPFragmentState(), BPFragmentState()
]

@State private var itemsFadingOut   = false
@State private var fadeOutVisible   = false
@State private var autoAdvanceFired = false
@State private var skipAvailable    = false
@State private var skipVisible      = false

private var reduceMotion: Bool {
    UIAccessibility.isReduceMotionEnabled
}

/// Physical top safe-area inset (Dynamic Island / notch / status bar)
/// read directly from the UIKit key window.
///
/// geo.safeAreaInsets.top returns 0 in this view because the outer
/// GeometryReader uses .ignoresSafeArea() — which zeroes the proxy's
/// inset values. The UIKit window always reports the true physical
/// insets regardless of SwiftUI's modifier chain.
private var deviceTopInset: CGFloat {
    guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive })
                as? UIWindowScene,
          let window = scene.windows.first(where: { $0.isKeyWindow })
    else { return 0 }
    return window.safeAreaInsets.top
}

// MARK: - Computed: Build Items

private var resolvedBuildItems: [BPBuildItem] {
    [        BPBuildItem(category: "Starting point",     resolved: stageLabel),        BPBuildItem(category: "Your situation",     resolved: contextLabel),        BPBuildItem(category: "First to explore",   resolved: goalsLabel),        BPBuildItem(category: "How you'll explore", resolved: modeLabel),    ]
}

private var stageLabel: String {
    switch data.nmStage {
    case .curious:     return "Beginning from curiosity"
    case .exploring:   return "Building on what you've tried"
    case .experienced: return "Starting from experience"
    default:           return "Your starting point"
    }
}

private var contextLabel: String {
    switch data.relationshipContext {
    case .partneredOpen:   return "Navigating openness together"
    case .partneredHidden: return "Finding words for the unspoken"
    case .notTalked:       return "Opening the conversation"
    case .talking:         return "Growing shared curiosity"
    case .single:          return "Your journey, your pace"
    case .someExperience:  return "Processing what's happened"
    case .needsReset:      return "Rebuilding from here"
    default:               return "Your situation"
    }
}

private var goalsLabel: String {
    let source = data.communicationGoals.first(where: { !$0.isEmpty })
        ?? data.learningGoals.first(where: { !$0.isEmpty })
    guard let s = source else { return "What you want to explore" }
    return s.count > 32 ? String(s.prefix(32)) + "…" : s
}

private var modeLabel: String {
    switch data.explorationMode {
    case .solo:   return "At your own pace"
    case .couple: return "Together, step by step"
    default:      return "Your conversation style"
    }
}

// MARK: - Computed: Fragments

private var stageFragment: String {
    switch data.nmStage {
    case .curious:     return "Starting fresh"
    case .exploring:   return "Building on what you know"
    case .experienced: return "Going deeper"
    default:           return "Starting fresh"
    }
}

private var contextFragment: String? {
    switch data.relationshipContext {
    case .single:          return "Your journey"
    case .partneredOpen:   return "With transparency"
    case .partneredHidden: return "Finding the words"
    case .notTalked:       return "Starting together"
    case .talking:         return "Shared curiosity"
    case .someExperience:  return "Processing this"
    case .needsReset:      return "Rebuilding"
    default:               return nil
    }
}

// R-BUG-3 FIX: Fragment strings are kept short (≤20 chars) so they
// never exceed their capped frame width and bleed off-screen.

private var selectionFragment: String? {
    let source = data.communicationGoals.first(where: { !$0.isEmpty })
        ?? data.learningGoals.first(where: { !$0.isEmpty })
    guard let s = source else { return nil }
    // Cap at 20 chars for fragment display — full string is in the list row
    return s.count > 20 ? String(s.prefix(20)) + "…" : s
}

// MARK: - Computed: Personalization

private var trimmedName: String {
    data.displayName.trimmingCharacters(in: .whitespaces)
}

private var hasPersonalName: Bool { !trimmedName.isEmpty }

private var exitLine: String {
    hasPersonalName
        ? "\(trimmedName), here's your first step."
        : "Here's where you begin."
}

// MARK: - Accessibility

private var accessibilitySummary: String {
    let items = resolvedBuildItems
    let owner = hasPersonalName ? "\(trimmedName)'s" : "your"
    return "Building \(owner) path. " +
           "Assembling \(items[0].resolved), " +
           "\(items[1].resolved), " +
           "\(items[2].resolved), " +
           "and \(items[3].resolved). " +
           exitLine
}

// MARK: - Helpers

private func cacheSize(_ size: CGSize) {
    guard screenW != size.width || screenH != size.height else { return }
    DispatchQueue.main.async {
        screenW = size.width
        screenH = size.height
    }
}

private func schedule(_ seconds: Double, _ action: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: action)
}

private func deriveDefaultDifficulty() {
    switch data.nmStage {
    case .curious:     data.defaultDifficulty = "warm"
    case .exploring:   data.defaultDifficulty = "medium"
    case .experienced: data.defaultDifficulty = "hot"
    default:           data.defaultDifficulty = "warm"
    }
}

private func completeAndAdvance() {
    guard !autoAdvanceFired else { return }
    autoAdvanceFired = true
    deriveDefaultDifficulty()
    #if DEBUG
    assert(
        onFinished != nil,
        "OnboardingBuildingPathView: onFinished not injected."
    )
    #endif
    onFinished?()
}

// MARK: - Body

var body: some View {
    GeometryReader { geo in
        let _ = cacheSize(geo.size)
        // geo.safeAreaInsets.top is ZERO here because
        // .ignoresSafeArea() on the GeometryReader zeroes the
        // proxy's inset values. Read the real physical inset
        // from the UIKit key window instead.
        let topInset = deviceTopInset

        ZStack {
            // ── Floating fragments ───────────────────────────
            fragmentLayer(topInset: topInset)

            // ── Main content ─────────────────────────────────
            mainContent(topInset: topInset)

            // ── Skip affordance ──────────────────────────────
            skipAffordance()

            // ── VoiceOver overlay ────────────────────────────
            Text(accessibilitySummary)
                .opacity(0)
                .frame(width: 0, height: 0)
                .accessibilityLabel(accessibilitySummary)
                .accessibilityAddTraits(.updatesFrequently)
        }
        .frame(width: geo.size.width, height: geo.size.height)
        // LAYOUT FIX: Atmospheric layers (.ignoresSafeArea()) are
        // moved to .background() so they cannot distort the ZStack's
        // internal alignment origin. When .ignoresSafeArea() children
        // sit inside a ZStack, the ZStack computes its alignment
        // center from the union of all children's frames — including
        // safe-area-extended frames — which shifts the origin
        // rightward and drags all content with it.
        .background(
            ZStack {
                // Dark: near-black | Light: warm cream
                (colorScheme == .dark ? AppColors.pageBg : AppColors.lightPageBg)
                atmosphere()
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                OnboardingGlowField()
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            .ignoresSafeArea()
        )
        // LAYOUT FIX: Fade overlay also isolated via .overlay()
        // for the same reason — its .ignoresSafeArea() must not
        // participate in ZStack alignment.
        .overlay(
            (colorScheme == .dark ? AppColors.pageBg : AppColors.lightPageBg)
                .opacity(fadeOutVisible ? 1 : 0)
                .animation(.easeIn(duration: 0.4), value: fadeOutVisible)
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        )
        .clipped()
        .contentShape(Rectangle())
        .onTapGesture { handleSkip() }
    }
    .ignoresSafeArea()
    .preferredColorScheme(.dark)
    .onAppear {
        guard !hasAnimated else { return }
        hasAnimated = true
        startAnimation()
    }
}

// MARK: - Skip

private func handleSkip() {
    guard skipAvailable, !autoAdvanceFired else { return }
    autoAdvanceFired = true
    deriveDefaultDifficulty()
    withAnimation(.easeIn(duration: 0.25)) { fadeOutVisible = true }
    schedule(0.30) { onFinished?() }
}

@ViewBuilder
private func skipAffordance() -> some View {
    VStack {
        Spacer()
        HStack {
            Spacer()
            if skipVisible {
                Text("Continue →")
                    .font(AppFonts.caption)
                    .foregroundStyle(colorScheme == .dark
                        ? AppColors.textTertiary
                        : AppColors.lightTextTertiary)
                    .opacity(0.55)
                    .padding(.trailing, 28)
                    .padding(.bottom, 40)
                    .transition(.opacity)
                    .accessibilityLabel("Skip loading and continue")
                    .accessibilityAddTraits(.isButton)
            }
        }
    }
    .animation(.easeIn(duration: 0.4), value: skipVisible)
    .allowsHitTesting(skipAvailable)
}

// MARK: - Fragment Layer
//
// topInset: the physical top safe-area inset from UIKit's key window.
//
// The inner GeometryReader does NOT use .ignoresSafeArea() (removed
// in Rev 3 to fix the layout origin). Its geo.size.height is the
// safe-area-inset region — shorter than the physical screen by topInset.
//
// fullH = geo.size.height + topInset reconstructs the physical screen
// height from live geometry on every frame (unlike the @State screenH
// which may hold its initial value of 852 on the first render frame).
// midY is computed in inset-region coordinates, then each position
// adds topInset back for the correct physical screen position.

@ViewBuilder
private func fragmentLayer(topInset: CGFloat) -> some View {
    GeometryReader { geo in
        // fullH reconstructs the physical screen height from live geometry.
        // geo.size.height excludes topInset (no .ignoresSafeArea here).
        // screenH is cached and may hold its initial value of 852 on the
        // first render frame — using it caused fragments to jump position.
        // geo.size.height + topInset is always accurate on every frame.
        let fullH        = geo.size.height + topInset
        let midX         = geo.size.width / 2
        // midY in inset-region coordinates:
        //   physical center = fullH / 2
        //   inset-region y  = physical y − topInset
        let midY         = (fullH / 2) - topInset
        let fragmentMaxW = geo.size.width / 2 - 24

        ZStack {
            // Fragment 0 — stage — upper left of center
            BPFloatingFragment(
                text:          stageFragment,
                targetOpacity: 0.60,
                isVisible:     fragmentStates[0].visible,
                isFading:      fragmentStates[0].fading
            )
            .frame(maxWidth: fragmentMaxW)
            .position(
                x: midX - screenW * 0.22,
                y: midY - fullH * 0.28 + topInset
            )

            // Fragment 1 — context — upper right of center
            if let f1 = contextFragment {
                BPFloatingFragment(
                    text:          f1,
                    targetOpacity: 0.55,
                    isVisible:     fragmentStates[1].visible,
                    isFading:      fragmentStates[1].fading
                )
                .frame(maxWidth: fragmentMaxW)
                .position(
                    x: midX + screenW * 0.22,
                    y: midY - fullH * 0.32 + topInset
                )
            }

            // Fragment 2 — selection — centered above name
            if let f2 = selectionFragment {
                BPFloatingFragment(
                    text:          f2,
                    targetOpacity: 0.50,
                    isVisible:     fragmentStates[2].visible,
                    isFading:      fragmentStates[2].fading
                )
                .frame(maxWidth: fragmentMaxW)
                .position(
                    x: midX,
                    y: midY - fullH * 0.38 + topInset
                )
            }
        }
        .frame(width: geo.size.width, height: geo.size.height)
    }
    .allowsHitTesting(false)
    .accessibilityHidden(true)
}

// MARK: - Main Content
//
// topInset: the physical top safe-area inset (Dynamic Island / notch /
// status bar height) read from UIKit's key window.
//
// WHY geo.safeAreaInsets.top DOES NOT WORK HERE:
//
// The outer GeometryReader uses .ignoresSafeArea(). When a view opts
// out of safe areas, SwiftUI zeroes the GeometryProxy's safeAreaInsets
// — the proxy reports 0 for all edges because the view has declared it
// doesn't care about safe areas. Every prior attempt that captured
// geo.safeAreaInsets.top was capturing 0, producing padding equal to
// just OL.progressTop (~24pt) — well within the ~59pt Dynamic Island.
//
// The fix: deviceTopInset reads UIApplication → UIWindowScene →
// UIWindow.safeAreaInsets.top, which always reports the real physical
// inset regardless of SwiftUI's modifier chain. This value is passed
// as topInset to mainContent and fragmentLayer.

@ViewBuilder
private func mainContent(topInset: CGFloat) -> some View {
    let completeCount = indicatorStates.filter { $0 == .complete }.count

    VStack(alignment: .center, spacing: 0) {

        // Progress bar
        //
        // .padding(.top) = topInset (Dynamic Island / notch clearance,
        //                   from UIKit key window — NOT geo.safeAreaInsets)
        //                 + OL.progressTop (design spacing below island).
        OnboardingProgressBar(
            currentStep:          completeCount,
            totalSteps:           5
        )
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, topInset + OL.progressTop(screenH))
        .padding(.bottom, OL.progressBottom(screenH))
        .accessibilityHidden(true)

        Spacer()

        // Overline — BUG-3 FIX retained
        Text("BUILDING YOUR PATH")
            .font(AppFonts.overline)
            .foregroundStyle(colorScheme == .dark
                ? LinearGradient(
                    colors: [AppColors.purple, AppColors.magenta],
                    startPoint: .leading, endPoint: .trailing)
                : LinearGradient(stops: [
                    .init(color: AppColors.magenta, location: 0.00),
                    .init(color: AppColors.pink,    location: 0.45),
                    .init(color: AppColors.gold,    location: 1.00),
                  ],
                  startPoint: .leading, endPoint: .trailing))
            .tracking(2.5)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .frame(maxWidth: .infinity, alignment: .center)
            .opacity(overlabelVisible ? 1 : 0)
            .offset(y: overlabelVisible ? 0 : 8)
            .animation(.easeOut(duration: 1.0), value: overlabelVisible)
            .padding(.bottom, 10)
            .accessibilityHidden(true)

        // Name headline — BUG-1 downstream fix retained
        nameHeadline
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, alignment: .center)
            .opacity(nameVisible ? 1 : 0)
            .offset(y: nameVisible ? 0 : 14)
            .animation(.easeOut(duration: 1.2), value: nameVisible)
            .padding(.bottom, OL.loose(screenH))
            .accessibilityHidden(true)

        // Build item list — BUG-1 FIX retained: no .fixedSize(horizontal:)
        VStack(alignment: .leading, spacing: 20) {
            ForEach(Array(resolvedBuildItems.enumerated()), id: \.offset) { i, item in
                BPBuildItemRow(
                    item:           item,
                    indicatorState: indicatorStates[i],
                    isVisible:      indicatorStates[i] != .pending && !itemsFadingOut,
                    isComplete:     indicatorStates[i] == .complete && !itemsFadingOut
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .accessibilityHidden(true)

        // Exit tagline — BUG-5 FIX retained
        Text(exitLine)
            .font(AppFonts.body(18, weight: .medium))
            .foregroundStyle(colorScheme == .dark
                ? AppColors.textPrimary
                : AppColors.lightCardTitle)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .center)
            .opacity(taglineVisible ? 1 : 0)
            .offset(y: taglineVisible ? 0 : 10)
            .animation(.easeOut(duration: 1.2), value: taglineVisible)
            .padding(.top, OL.loose(screenH))
            .accessibilityHidden(true)

        // BUG-7 FIX retained
        Spacer(minLength: 40)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    // BUG-6 FIX retained: single source of horizontal inset.
    .padding(.horizontal, 36)
    // BUG-7 FIX retained: home indicator clearance
    .padding(.bottom, 34)
}

// MARK: - Name Headline

@ViewBuilder
private var nameHeadline: some View {
    if hasPersonalName {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(trimmedName)
                .foregroundStyle(colorScheme == .dark
                    ? AppColors.textPrimary
                    : AppColors.lightCardTitle)
            Text(".")
                .foregroundStyle(colorScheme == .dark
                    ? AppColors.spectrumBorder
                    : AppColors.warmAuroraBorder)
        }
        .font(AppFonts.heroTitle)
        .lineLimit(1)
        .minimumScaleFactor(0.75)
    } else {
        Text("Your path.")
            .font(AppFonts.heroTitle)
            .foregroundStyle(colorScheme == .dark
                ? AppColors.textPrimary
                : AppColors.lightCardTitle)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
    }
}

// MARK: - Atmospheric Layer
// Unchanged — atmosphere() renders correctly once the ZStack frame
// is pinned (R-BUG-1 fix). Orb offsets are screen-relative and correct.

// Dark:  cool spectrum — purple / cyan / magenta orbs
// Light: warm aurora  — purple / gold / magenta orbs (no cyan)
private var atmosAccent: Color {
    colorScheme == .dark ? AppColors.cyan : AppColors.gold
}

private func atmosphere() -> some View {
    ZStack {
        Ellipse()
            .fill(RadialGradient(
                colors: [AppColors.purple.opacity(0.40),
                         atmosAccent.opacity(0.20),
                         Color.clear],
                center: .top, startRadius: 30, endRadius: 380))
            .frame(width: OL.atmosW(screenW), height: OL.atmosH(screenH))
            .offset(y: -screenH * 0.42)
            .blur(radius: 90)
            .opacity(atmosphericVisible ? 1 : 0)
            .animation(.easeInOut(duration: 2.0), value: atmosphericVisible)

        Ellipse()
            .fill(atmosAccent.opacity(0.12))
            .frame(width: 180, height: 180)
            .blur(radius: 55)
            .offset(x: -screenW * 0.32, y: -screenH * 0.22)
            .opacity(glowPeak ? 0.90 : 0.40)
            .animation(.easeInOut(duration: 2.0), value: glowPeak)

        Ellipse()
            .fill(AppColors.magenta.opacity(0.10))
            .frame(width: 140, height: 140)
            .blur(radius: 50)
            .offset(x: screenW * 0.32, y: -screenH * 0.26)
            .opacity(glowPeak ? 0.85 : 0.28)
            .animation(.easeInOut(duration: 2.0), value: glowPeak)

        Ellipse()
            .fill(AppColors.purple.opacity(0.14))
            .frame(width: 240, height: 240)
            .blur(radius: 80)
            .opacity(glowPeak ? 1.00 : 0.45)
            .animation(.easeInOut(duration: 2.0), value: glowPeak)

        Ellipse()
            .fill(atmosAccent.opacity(0.08))
            .frame(width: 110, height: 110)
            .blur(radius: 42)
            .offset(x: -screenW * 0.38, y: screenH * 0.22)
            .opacity(glowPeak ? 0.75 : 0.18)
            .animation(.easeInOut(duration: 2.0), value: glowPeak)

        Ellipse()
            .fill(AppColors.magenta.opacity(0.08))
            .frame(width: 150, height: 150)
            .blur(radius: 60)
            .offset(x: screenW * 0.38, y: screenH * 0.18)
            .opacity(glowPeak ? 0.85 : 0.22)
            .animation(.easeInOut(duration: 2.0), value: glowPeak)

        Ellipse()
            .fill(RadialGradient(
                colors: [AppColors.purple.opacity(0.18),
                         atmosAccent.opacity(0.10),
                         Color.clear],
                center: .center, startRadius: 0, endRadius: 200))
            .frame(width: 400, height: 400)
            .blur(radius: 70)
            .scaleEffect(glowPeak ? 1.0 : 0.36)
            .opacity(glowPeak ? 1.0 : 0)
            .animation(.easeInOut(duration: 2.0), value: glowPeak)

        Rectangle()
            .fill(LinearGradient(
                colors: [AppColors.purple.opacity(0.10), Color.clear],
                startPoint: .bottom, endPoint: .top))
            .frame(maxWidth: .infinity)
            .frame(height: 160)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .opacity(glowPeak ? 1.0 : 0)
            .animation(.easeInOut(duration: 2.0), value: glowPeak)
    }
    .drawingGroup()
}

    // MARK: - Animation (startFullAnimation replacement)
    //
    // BUG-1 FIX: the #if DEBUG / XCODE_RUNNING_FOR_PREVIEWS block
    // previously hard-jumped to indicatorStates = [.complete × 4] and
    // returned early. This meant BPOrbitCanvas was NEVER mounted in any
    // preview — the .processing state was skipped entirely, so the comet
    // orbit was invisible.
    //
    // BUG-2 FIX (downstream): BPBuildItemRow.isVisible is computed as
    // indicatorStates[i] != .pending. When the DEBUG block set states to
    // .complete before the animation sequence ran, the rows started
    // invisible (opacity 0) and stayed there because no animation ever
    // fired to transition them in.
    //
    // FIX: the preview path now runs a real but fast (0.4× speed) animation
    // sequence using the same schedule() calls as the device path. This
    // ensures every state — pending → processing → complete — is visited,
    // all rows animate in, and the comet orbit is visible.
    //
    // The instanceID UUID toggle in the preview re-creates the view from
    // scratch on each Reset tap, which resets hasAnimated = false and
    // replays the sequence.
    
    private func startAnimation() {
        if reduceMotion { startReducedMotionAnimation(); return }
        schedule(0.15) { startFullAnimation() }
    }
    
    private func startReducedMotionAnimation() {
        overlabelVisible = true
        nameVisible      = true
        indicatorStates  = [.complete, .complete, .complete, .complete]
        taglineVisible   = true
        schedule(2.00) { completeAndAdvance() }
    }

    private func startFullAnimation() {
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            // Preview-fast path: same sequence as below but at 0.4× wall-clock
            // time so the full pending → processing → complete flow is visible
            // without waiting 4+ seconds per canvas reload.
            //
            // Multiplier 0.4 maps the real-device schedule (0s–4.6s) into
            // approximately 0s–1.85s in the preview canvas.
            let k = 0.4
            schedule(0.00 * k) {
                withAnimation(.easeInOut(duration: 1.6 * k)) { atmosphericVisible = true }
            }
            schedule(0.00 * k) {
                withAnimation(.easeOut(duration: 0.8 * k)) { overlabelVisible = true }
            }
            schedule(0.10 * k) {
                withAnimation(.easeInOut(duration: 0.9 * k)) { fragmentStates[0].visible = true }
            }
            schedule(0.40 * k) {
                withAnimation(.easeOut(duration: 0.9 * k)) { nameVisible = true }
            }
            schedule(0.40 * k) {
                withAnimation(.easeOut(duration: 0.4 * k)) { indicatorStates[0] = .processing }
            }
            schedule(0.70 * k) {
                withAnimation(.easeOut(duration: 0.4 * k)) { indicatorStates[1] = .processing }
            }
            schedule(1.00 * k) {
                withAnimation(.easeOut(duration: 0.4 * k)) { indicatorStates[2] = .processing }
            }
            schedule(1.10 * k) {
                withAnimation(.easeInOut(duration: 0.9 * k)) { fragmentStates[1].visible = true }
            }
            schedule(1.30 * k) {
                withAnimation(.easeOut(duration: 0.4 * k)) { indicatorStates[3] = .processing }
            }
            schedule(1.50 * k) { skipAvailable = true }
            schedule(1.80 * k) {
                withAnimation(.easeIn(duration: 0.4 * k)) { skipVisible = true }
            }
            schedule(1.80 * k) {
                withAnimation(.easeIn(duration: 0.8 * k)) { fragmentStates[0].fading = true }
            }
            schedule(1.90 * k) {
                withAnimation(.easeOut(duration: 0.7 * k)) { indicatorStates[0] = .complete }
            }
            schedule(2.00 * k) {
                withAnimation(.easeInOut(duration: 0.9 * k)) { fragmentStates[2].visible = true }
            }
            schedule(2.20 * k) {
                withAnimation(.easeOut(duration: 0.7 * k)) { indicatorStates[1] = .complete }
                withAnimation(.easeIn(duration: 0.8 * k)) { fragmentStates[1].fading = true }
            }
            schedule(2.50 * k) {
                withAnimation(.easeOut(duration: 0.7 * k)) { indicatorStates[2] = .complete }
            }
            schedule(2.80 * k) {
                withAnimation(.easeOut(duration: 0.7 * k)) { indicatorStates[3] = .complete }
                withAnimation(.easeInOut(duration: 1.4 * k)) { glowPeak = true }
            }
            schedule(2.90 * k) {
                withAnimation(.easeIn(duration: 0.8 * k)) { fragmentStates[2].fading = true }
            }
            schedule(3.20 * k) {
                withAnimation(.easeOut(duration: 0.9 * k)) { taglineVisible = true }
            }
            // Do NOT auto-advance in preview — leave the final state on screen.
            return
        }
        #endif

        // ── Real-device timing (unchanged) ───────────────────────────────
        schedule(0.00) {
            withAnimation(.easeInOut(duration: 1.6)) { atmosphericVisible = true }
        }
        schedule(0.00) {
            withAnimation(.easeOut(duration: 0.8)) { overlabelVisible = true }
        }
        schedule(0.10) {
            withAnimation(.easeInOut(duration: 0.9)) { fragmentStates[0].visible = true }
        }
        schedule(0.40) {
            withAnimation(.easeOut(duration: 0.9)) { nameVisible = true }
        }
        schedule(0.40) {
            withAnimation(.easeOut(duration: 0.4)) { indicatorStates[0] = .processing }
        }
        schedule(0.70) {
            withAnimation(.easeOut(duration: 0.4)) { indicatorStates[1] = .processing }
        }
        schedule(1.00) {
            withAnimation(.easeOut(duration: 0.4)) { indicatorStates[2] = .processing }
        }
        schedule(1.10) {
            withAnimation(.easeInOut(duration: 0.9)) { fragmentStates[1].visible = true }
        }
        schedule(1.30) {
            withAnimation(.easeOut(duration: 0.4)) { indicatorStates[3] = .processing }
        }
        schedule(1.50) { skipAvailable = true }
        schedule(1.80) {
            withAnimation(.easeIn(duration: 0.4)) { skipVisible = true }
        }
        schedule(1.80) {
            withAnimation(.easeIn(duration: 0.8)) { fragmentStates[0].fading = true }
        }
        schedule(1.90) {
            withAnimation(.easeOut(duration: 0.7)) { indicatorStates[0] = .complete }
        }
        schedule(2.00) {
            withAnimation(.easeInOut(duration: 0.9)) { fragmentStates[2].visible = true }
        }
        schedule(2.20) {
            withAnimation(.easeOut(duration: 0.7)) { indicatorStates[1] = .complete }
            withAnimation(.easeIn(duration: 0.8)) { fragmentStates[1].fading = true }
        }
        schedule(2.50) {
            withAnimation(.easeOut(duration: 0.7)) { indicatorStates[2] = .complete }
        }
        schedule(2.80) {
            withAnimation(.easeOut(duration: 0.7)) { indicatorStates[3] = .complete }
            withAnimation(.easeInOut(duration: 1.4)) { glowPeak = true }
        }
        schedule(2.90) {
            withAnimation(.easeIn(duration: 0.8)) { fragmentStates[2].fading = true }
        }
        schedule(3.20) {
            withAnimation(.easeOut(duration: 0.9)) { taglineVisible = true }
        }
        schedule(3.80) {
            withAnimation(.easeIn(duration: 0.4)) {
                overlabelVisible = false
                nameVisible      = false
                itemsFadingOut   = true
            }
        }
        schedule(3.90) {
            withAnimation(.easeIn(duration: 0.4)) { taglineVisible = false }
        }
        schedule(4.20) {
            withAnimation(.easeIn(duration: 0.3)) { fadeOutVisible = true }
        }
    schedule(4.60) { completeAndAdvance() }
}
}

// MARK: - BPBuildItemRow
// BUG-4 + BUG-6 fixes retained: .frame(maxWidth: .infinity) on both
// the label VStack and the outer HStack. lineLimit + truncationMode on
// both Text nodes. fixedSize(horizontal: false, vertical: true) on
// the resolved text for graceful two-line wrap.

private struct BPBuildItemRow: View {
let item:           BPBuildItem
let indicatorState: BPIndicatorState
let isVisible:      Bool
let isComplete:     Bool



@Environment(\.colorScheme) private var colorScheme

var body: some View {
    HStack(spacing: 14) {
        // Fixed-size indicator — never grows
        BPOrbitIndicator(state: indicatorState)
            .fixedSize()

        VStack(alignment: .leading, spacing: 2) {
            Text(item.category.uppercased())
                .font(AppFonts.overline)
                .foregroundStyle(colorScheme == .dark
                    ? AppColors.textTertiary
                    : AppColors.lightCardTitle.opacity(0.40))
                .tracking(1.5)
                .lineLimit(1)
                .truncationMode(.tail)

            Text(item.resolved)
                .font(AppFonts.bodyMedium)
                .foregroundStyle(isComplete
                    ? (colorScheme == .dark ? AppColors.textPrimary : AppColors.lightCardTitle)
                    : (colorScheme == .dark ? AppColors.textSecondary : AppColors.lightCardTitle.opacity(0.55)))
                .animation(.easeOut(duration: 0.7), value: isComplete)
                .lineLimit(2)
                .truncationMode(.tail)
                .fixedSize(horizontal: false, vertical: true)
        }
        // Fill remaining width after the indicator + spacing
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    // Fill the padded column width
    .frame(maxWidth: .infinity, alignment: .leading)
    .opacity(isVisible ? 1 : 0)
    .offset(y: isVisible ? 0 : 10)
    .animation(.easeOut(duration: 0.8), value: isVisible)
}
}

// MARK: - BPOrbitIndicator (unchanged)

private struct BPOrbitIndicator: View {
let state: BPIndicatorState
private let size: CGFloat = 22



@Environment(\.colorScheme) private var colorScheme

var body: some View {
    ZStack {
        Circle()
            .strokeBorder(
                colorScheme == .dark ? AppColors.border : AppColors.lightBorder,
                lineWidth: 1.5)
            .opacity(state == .pending ? 1 : 0)
            .animation(.easeOut(duration: 0.3), value: state == .pending)

        if state == .processing {
            BPOrbitCanvas(size: size, colorScheme: colorScheme)
                .transition(.opacity)
        }

        Circle()
            .fill(LinearGradient(
                colors: colorScheme == .dark
                    ? [AppColors.cyan, AppColors.purple, AppColors.magenta]
                    : [AppColors.purple, AppColors.magenta, AppColors.gold],
                startPoint: .topLeading, endPoint: .bottomTrailing))
            .opacity(state == .complete ? 1 : 0)
            .animation(.easeOut(duration: 0.7), value: state == .complete)
            .shadow(
                color: colorScheme == .dark
                    ? AppColors.glowCyan : AppColors.lightShadowPurple,
                radius: colorScheme == .dark ? 12 : 7)
            .shadow(
                color: colorScheme == .dark
                    ? AppColors.glowMagenta : AppColors.lightShadowMagenta,
                radius: colorScheme == .dark ? 24 : 14)
    }
    .frame(width: size, height: size)
}
}

// MARK: - BPOrbitCanvas (unchanged)

private struct BPOrbitCanvas: View {
let size: CGFloat
let colorScheme: ColorScheme
private let revolutionDuration: TimeInterval = 1.4



// RGB triples resolved from AppColors tokens per colorScheme.
// Dark:  cyan → purple → magenta
// Light: purple → magenta → gold
private var primaryRGB:   (r: Double, g: Double, b: Double) {
    components(of: colorScheme == .dark ? AppColors.cyan : AppColors.purple)
}
private var secondaryRGB: (r: Double, g: Double, b: Double) {
    components(of: colorScheme == .dark ? AppColors.purple : AppColors.magenta)
}
private var tertiaryRGB:  (r: Double, g: Double, b: Double) {
    components(of: colorScheme == .dark ? AppColors.magenta : AppColors.gold)
}

var body: some View {
    let pRGB = primaryRGB
    let sRGB = secondaryRGB
    let tRGB = tertiaryRGB
    let borderColor: Color = colorScheme == .dark
        ? AppColors.borderHover
        : AppColors.lightBorderHover
    let sparkOuter = AppColors.magenta
    let sparkInner: Color = colorScheme == .dark ? AppColors.cyan : AppColors.purple

    TimelineView(.animation) { timeline in
        Canvas { context, canvasSize in
            let elapsed = timeline.date.timeIntervalSinceReferenceDate
                .truncatingRemainder(dividingBy: revolutionDuration)
            let progress = elapsed / revolutionDuration
            drawOrbit(
                context: context, size: canvasSize, progress: progress,
                pRGB: pRGB, sRGB: sRGB, tRGB: tRGB,
                sparkOuter: sparkOuter, sparkInner: sparkInner,
                borderColor: borderColor
            )
        }
        .frame(width: size, height: size)
    }
}

private func drawOrbit(
    context:     GraphicsContext,
    size:        CGSize,
    progress:    Double,
    pRGB:        (r: Double, g: Double, b: Double),
    sRGB:        (r: Double, g: Double, b: Double),
    tRGB:        (r: Double, g: Double, b: Double),
    sparkOuter:  Color,
    sparkInner:  Color,
    borderColor: Color
) {
    let cx     = size.width  / 2
    let cy     = size.height / 2
    let radius = size.width  / 2 - 2.0
    let steps  = 28

    let headAngle = progress * .pi * 2 - .pi / 2
    let tailArc   = Double.pi * 0.88

    var borderPath = Path()
    borderPath.addEllipse(in: CGRect(
        x: cx - radius, y: cy - radius,
        width: radius * 2, height: radius * 2))
    context.stroke(
        borderPath,
        with: .color(borderColor),
        lineWidth: 1.5)

    for i in 0..<steps {
        let t         = Double(i) / Double(steps - 1)
        let dotAngle  = headAngle - tailArc * (1.0 - t)
        let x         = cx + cos(dotAngle) * radius
        let y         = cy + sin(dotAngle) * radius
        let alpha     = t * 0.58
        let dotRadius = 0.9 + t * 0.65

        let color: Color
        if t < 0.4 {
            let blend = t / 0.4
            color = Color(
                red:   lerp(pRGB.r, sRGB.r, blend),
                green: lerp(pRGB.g, sRGB.g, blend),
                blue:  lerp(pRGB.b, sRGB.b, blend))
        } else {
            let blend = (t - 0.4) / 0.6
            color = Color(
                red:   lerp(sRGB.r, tRGB.r, blend),
                green: lerp(sRGB.g, tRGB.g, blend),
                blue:  lerp(sRGB.b, tRGB.b, blend))
        }

        var dotPath = Path()
        dotPath.addEllipse(in: CGRect(
            x: x - dotRadius, y: y - dotRadius,
            width: dotRadius * 2, height: dotRadius * 2))
        context.fill(dotPath, with: .color(color.opacity(alpha)))
    }

    let hx = cx + cos(headAngle) * radius
    let hy = cy + sin(headAngle) * radius

    var outerPath = Path()
    outerPath.addEllipse(in: CGRect(
        x: hx - 5.5, y: hy - 5.5, width: 11, height: 11))
    context.fill(outerPath, with: .color(sparkOuter.opacity(0.45)))

    var innerPath = Path()
    innerPath.addEllipse(in: CGRect(
        x: hx - 3, y: hy - 3, width: 6, height: 6))
    context.fill(innerPath, with: .color(sparkInner.opacity(0.55)))

    var corePath = Path()
    corePath.addEllipse(in: CGRect(
        x: hx - 1.8, y: hy - 1.8, width: 3.6, height: 3.6))
    context.fill(corePath, with: .color(.white.opacity(0.96)))
}

private func components(of color: Color) -> (r: Double, g: Double, b: Double) {
    let uiColor = UIColor(color)
    var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
    uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
    return (Double(r), Double(g), Double(b))
}

private func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double {
    a + (b - a) * t
}
}

// MARK: - BPFloatingFragment
// R-BUG-3 FIX: .fixedSize() removed from inside the component.
// Width is now controlled by the .frame(maxWidth: fragmentMaxW) applied
// by the caller in fragmentLayer(). Removing .fixedSize() here means the
// Text respects the width cap and wraps rather than overflowing right.
// .lineLimit(1) ensures it stays single-line and truncates cleanly.

private struct BPFloatingFragment: View {
let text:          String
let targetOpacity: Double
let isVisible:     Bool
let isFading:      Bool



@Environment(\.colorScheme) private var colorScheme

var body: some View {
    Text(text.uppercased())
        .font(AppFonts.overline)
        .foregroundStyle(colorScheme == .dark
            ? AppColors.textSecondary
            : AppColors.lightTextSecondary)
        .tracking(2.5)
        .multilineTextAlignment(.center)
        // R-BUG-3 FIX: .fixedSize() removed. Width is capped by caller.
        // .lineLimit(1) ensures single-line with clean truncation.
        .lineLimit(1)
        .truncationMode(.tail)
        .opacity(isVisible && !isFading ? targetOpacity : 0)
        .offset(y: isVisible && !isFading ? -4 : 0)
        .animation(.easeInOut(duration: 1.0), value: isVisible)
        .animation(.easeIn(duration: 0.8), value: isFading)
        .allowsHitTesting(false)
}
}

// MARK: - Previews
//
// Each preview uses a @Previewable UUID that is toggled by a Reset button.
// Changing the id re-creates the view from scratch — hasAnimated resets to
// false — so the full entrance animation replays on every canvas reset.

#Preview("Dark Mode") {
@Previewable @State var data: OnboardingData = {
var d = OnboardingData()
d.displayName         = "Jordan"
d.explorationMode     = .couple
d.nmStage             = .curious
d.relationshipContext = .notTalked
d.communicationGoals  = ["Talking about fantasies"]
return d
}()
// Changing this id destroys and recreates the view, restarting animation.
@Previewable @State var instanceID = UUID()
ZStack(alignment: .bottomTrailing) {
OnboardingBuildingPathView(data: $data, onFinished: {})
.id(instanceID)
Button("↺ Reset") { instanceID = UUID() }
.font(.system(size: 13, weight: .semibold))
.foregroundStyle(.white)
.padding(.horizontal, 14)
.padding(.vertical, 8)
.background(.ultraThinMaterial)
.clipShape(Capsule())
.padding(20)
}
.preferredColorScheme(.dark)
}

#Preview("Light Mode") {
@Previewable @State var data: OnboardingData = {
var d = OnboardingData()
d.displayName         = "Alex"
d.explorationMode     = .solo
d.nmStage             = .experienced
d.relationshipContext = .needsReset
d.communicationGoals  = ["Rebuilding intimacy"]
return d
}()
@Previewable @State var instanceID = UUID()
ZStack(alignment: .bottomTrailing) {
OnboardingBuildingPathView(data: $data, onFinished: {})
.id(instanceID)
Button("↺ Reset") { instanceID = UUID() }
.font(.system(size: 13, weight: .semibold))
.foregroundStyle(.primary)
.padding(.horizontal, 14)
.padding(.vertical, 8)
.background(.ultraThinMaterial)
.clipShape(Capsule())
.padding(20)
}
.preferredColorScheme(.light)
}

```

---

## File: `Open Lightly/Features/Onboarding/Views/OnboardingCardRevealView.swift` {#file-open-lightly-features-onboarding-views-onboardingcardrevealview-swift}

```swift
//Features/Onboarding/Views/OnboardingCardRevealView.swift
//
// Screen 7.5 — Card Reveal
//
// INTERACTION ARC
// ───────────────
//  t=0            Scene fades in. Card floats up spring(0.42, 0.78).
//                 AtmosphericGhostDeck drifts passively behind.
//  t=0.8s         Card breath begins — scale 1.000 ↔ 1.006, 3.0s sine.
//  t=tap          Flip fires. Ghost deck fades.
//                 3D flip: spring(0.58, 0.84), perspective 0.6.
//                 Front/back cross-fade over 12° window at 90°.
//  t=flip+~320ms  Back face visible. Heading enters, pills stagger up.
//  t=select       Three-beat post-selection sequence:
//                   Beat 1 (0ms):    Pill breathes — scale → 1.06.
//                   Beat 2 (+500ms): Border blooms — lineWidth → 3.0.
//                   Beat 3 (+900ms): Unselected pills sink and fade.
//  t=select+1.3s  Card exits upward, opacity 0, over 450ms.
//  t=select+1.65s Encouragement fades in from below.
//  t=select+1.83s Typewriter begins at 38 cps.
//                 Plain text in body color. Accent in static color.
//                 LivingText crossfades in once accent fully typed.
//                 Cursor blinks ×3 after last char, then fades.
//  t=typing+0.9s  Scene fades to pageBg over 500ms → onContinue().
//
// TRANSITION TO GROUNDRULES
// ──────────────────────────
//  This view owns its exit — sceneOpacity fades to 0, then onContinue()
//  fires. FlowView's spring transition cross-dissolves to GroundRulesView.
//  OnboardingAtmosphere persists in FlowView's ZStack, morphing from
//  .cardReveal to .groundRules config — no background flash.
//
// SKIP
// ────
//  "Continue when ready →" appears at 25s idle.
//  Stores data.nmCardResponse = nil and fades out.

import SwiftUI

// MARK: - Phase

private enum CardRevealPhase: Equatable {
   case idle
   case flipping
   case flipped
   case selected
   case encouragement
   case exiting
}

// MARK: - Main View

struct OnboardingCardRevealView: View {

   @Binding var data: OnboardingData
   var onContinue: (() -> Void)?

   @Environment(\.colorScheme) private var colorScheme
   @Environment(\.accessibilityReduceMotion) private var reduceMotion
   private var isLight: Bool { colorScheme == .light }

   // ── Phase ─────────────────────────────────────────────────────────
   @State private var phase: CardRevealPhase = .idle
   @State private var selectedPill: CardRevealPill? = nil
   @State private var hasAdvanced = false

   // ── Entrance ───────────────────────────────────────────────────────
   @State private var hasAnimated       = false
   @State private var sceneOpacity:     Double  = 0
   @State private var cardOffsetY:      CGFloat = 24
   @State private var cardEntryOpacity: Double  = 0

   // ── Breath ────────────────────────────────────────────────────────
   @State private var breathActive = false
   @State private var breathScale: CGFloat = 1.0

   // ── Ghost deck ────────────────────────────────────────────────────
   @State private var ghostOpacity: Double = 0

   // ── Flip ──────────────────────────────────────────────────────────
   @State private var flipDegrees:  Double = 0
   @State private var backRevealed: Bool   = false

   // ── Post-selection beat ────────────────────────────────────────────
   @State private var selectedPillScale:      CGFloat = 1.0
   @State private var selectedBorderWidth:    CGFloat = 2.0
   @State private var unselectedPillsVisible: Bool    = true

   // ── Card exit ─────────────────────────────────────────────────────
   @State private var cardExiting: Bool = false

   // ── Encouragement ─────────────────────────────────────────────────
   @State private var encouragementVisible: Bool = false
   @State private var typingComplete:       Bool = false

   // ── Arrow ─────────────────────────────────────────────────────────
   @State private var arrowTriggered: Bool = false
   @State private var sitWithThisVisible: Bool = false

   // ── Skip ──────────────────────────────────────────────────────────
   // Skip affordance removed

   @State private var fuseVisible:   Bool = false
   @State private var fuseCompleted: Bool = false
   @State private var flipHintActive:  Bool   = false
   @State private var flipHintDegrees: Double = 0
   @State private var fuseBurnProgress: Double = 0
   @State private var fuseBurnStartDate: Date? = nil

   // ── Scene exit ────────────────────────────────────────────────────
   @State private var exitingToNext: Bool = false

   // MARK: - Constants

   private let cardSize = CGSize(width: 280, height: 380)
   private let cardCornerRadius: CGFloat = 22
   private let fuseDuration:  TimeInterval = 18.0
   private let fuseDelay:     TimeInterval = 3.0
   private let fuseLineWidth: CGFloat      = 2.5

   // MARK: - Body

   var body: some View {
       ZStack {
           Color.clear.ignoresSafeArea()

           // Card stage and encouragement share the same region.
           // Card exits upward; encouragement rises from below.
           VStack {
               Spacer()   // greedy — pushes card DOWN
               ZStack {
                   cardStage

                   if encouragementVisible || typingComplete {
                       EncouragementView(
                           isLight:      isLight,
                           active:       encouragementVisible,
                           reduceMotion: reduceMotion,
                           onComplete:   handleTypingComplete
                       )
                       .transition(
                           .opacity.combined(with: .offset(y: 16))
                       )
                   }
               }
               .frame(width: cardSize.width, height: cardSize.height)

               Text("sit with this")
                   .font(AppFonts.body(16, weight: .regular))
                   .italic()
                   .foregroundStyle(Color.white)
                   .opacity(sitWithThisVisible ? 0.75 : 0)
                   .blur(radius: sitWithThisVisible ? 0 : 4)
                   .offset(y: sitWithThisVisible ? 0 : 6)
                   .padding(.top, 12)

               Color.clear.frame(height: 160)   // fixed — stops card going too low
           }
           .frame(maxWidth: .infinity)

       }
       .opacity(sceneOpacity)
       .animation(
           exitingToNext
               ? .easeIn(duration: 0.5)
               : .easeOut(duration: 0.45),
           value: exitingToNext
       )
       .accessibilityElement(children: .ignore)
       .accessibilityLabel(
           backRevealed
               ? "Something came up. What's it closest to? Choose from: \(CardRevealPill.allCases.map(\.rawValue).joined(separator: ", "))"
               : "What would you desire if nobody, not even you, would judge the answer? Tap to reflect."
       )
       .accessibilityAction(named: "Flip card") {
           if phase == .idle { handleCardTap() }
       }
       .accessibilityAction(named: "Skip") { handleSkip() }
       .onAppear {
           guard !hasAnimated else { return }
           hasAnimated = true
           startEntrance()
       }
       .onDisappear {
           // Skip affordance removed
       }
   }

   // MARK: - Card Stage

   private var cardStage: some View {
       TimelineView(.animation(paused: !fuseVisible || fuseCompleted)) { timeline in
           ZStack {
               // AtmosphericGhostDeck handles its own drift animation internally.
               // We only control its opacity (fades out on flip).
               AtmosphericGhostDeck(
                   cardSize:     cardSize,
                   cornerRadius: cardCornerRadius
               )
               .opacity(ghostOpacity)
               .animation(.easeOut(duration: 0.45), value: ghostOpacity)

               // Main card — entrance offset + breath + exit transform
               ZStack {
                   flipContainer
               }
               .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius))
               .scaleEffect(breathActive && phase == .idle ? breathScale : 1.0)
               .offset(y: cardExiting ? -36 : cardOffsetY)
               .opacity(cardExiting ? 0 : cardEntryOpacity)
               .animation(
                   cardExiting
                       ? .timingCurve(0.4, 0, 0.6, 1, duration: 0.45)
                       : .spring(response: 0.42, dampingFraction: 0.78),
                   value: cardExiting
               )
               .animation(.easeOut(duration: 0.45), value: cardEntryOpacity)
           }
           .frame(width: cardSize.width, height: cardSize.height)
           .onChange(of: timeline.date) { _, date in
               updateFuseProgress(at: date)
           }
       }
   }

   // MARK: - Flip Container

   private var flipContainer: some View {
       ZStack {
           // Front — fades out over 78°→90° cross-fade window
           CardFrontView(
               cardSize:           cardSize,
               cornerRadius:       cardCornerRadius,
               isLight:            isLight,
               arrowTriggered:     arrowTriggered,
               sitWithThisVisible: sitWithThisVisible,
               onTap:              handleCardTap,
               fuseProgress:       phase == .idle ? fuseBurnProgress : 0
           )
           .opacity(frontFaceOpacity)
           .allowsHitTesting(phase == .idle)

           // Back — fades in over 78°→90°, pre-rotated 180°
           CardBackView(
               cardSize:            cardSize,
               cornerRadius:        cardCornerRadius,
               selectedPill:        selectedPill,
               selectedScale:       selectedPillScale,
               selectedBorderWidth: selectedBorderWidth,
               unselectedVisible:   unselectedPillsVisible,
               revealed:            backRevealed,
               isLight:             isLight,
               onSelect:            handlePillSelected
           )
           .opacity(backFaceOpacity)
           .rotation3DEffect(
               Angle.degrees(180),
               axis: (x: 0, y: 1, z: 0)
           )
           .allowsHitTesting(backRevealed && phase == .flipped)
       }
       .rotation3DEffect(
           Angle.degrees(flipDegrees + flipHintDegrees),
           axis: (x: 0, y: 1, z: 0),
           perspective: 0.6
       )
   }

   // MARK: - Cross-fade opacity
   // Replaces binary < 90° threshold with a 12° overlap window.
   // Both faces are partially visible at 78°–90° where the card
   // is edge-on — the overlap is imperceptible at that angle.

   private var frontFaceOpacity: Double {
       Double(max(0, min(1, (90.0 - flipDegrees) / 12.0)))
   }

   private var backFaceOpacity: Double {
       Double(max(0, min(1, (flipDegrees - 78.0) / 12.0)))
   }

   // MARK: - Entrance

   private func startEntrance() {
       if reduceMotion {
           sceneOpacity     = 1
           cardOffsetY      = 0
           cardEntryOpacity = 1
           ghostOpacity     = 1
           arrowTriggered   = true
           return
       }

       withAnimation(.easeOut(duration: 0.45).delay(0.08)) {
           sceneOpacity = 1
       }
       withAnimation(.spring(response: 0.42, dampingFraction: 0.78).delay(0.15)) {
           cardOffsetY = 0
       }
       withAnimation(.easeOut(duration: 0.45).delay(0.15)) {
           cardEntryOpacity = 1
       }
       withAnimation(.easeOut(duration: 0.6).delay(0.25)) {
           ghostOpacity = 1
       }

       DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { startBreath() }
       DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { arrowTriggered = true }
       // Fuse auto-starts 1.2 seconds after the card entrance spring settles.
       // Setting fuseVisible = true causes SwiftUI to render FuseTimerView,
       // which starts its internal clock immediately on appear.
       DispatchQueue.main.asyncAfter(deadline: .now() + fuseDelay) {
           guard self.phase == .idle else { return }
           self.fuseBurnStartDate = Date()
           withAnimation(.easeIn(duration: 0.4)) { self.fuseVisible = true }
       }
       // Subtext appears after draw-on completes (2.5s trigger + 4.5s draw)
       DispatchQueue.main.asyncAfter(deadline: .now() + 6.5) {
           withAnimation(.easeOut(duration: 0.9)) {
               sitWithThisVisible = true
           }
       }
   }

   // MARK: - Breath

   private func startBreath() {
       guard !reduceMotion else { return }
       breathActive = true
       tickBreath()
   }

   private func tickBreath() {
       guard breathActive, phase == .idle else {
           withAnimation(.easeOut(duration: 0.2)) { breathScale = 1.0 }
           return
       }
       withAnimation(.easeInOut(duration: 3.0)) {
           breathScale = breathScale < 1.003 ? 1.006 : 1.0
       }
       DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { tickBreath() }
   }

   private func stopBreath() {
       breathActive = false
       withAnimation(.easeOut(duration: 0.2)) { breathScale = 1.0 }
   }

   // MARK: - Flip

   private func handleCardTap() {
       fuseBurnProgress  = 0
       fuseBurnStartDate = nil
       fuseVisible   = false
       fuseCompleted = true
       flipHintActive  = false
       flipHintDegrees = 0
       guard phase == .idle else { return }
       phase = .flipping
       stopBreath()
       UIImpactFeedbackGenerator(style: .medium).impactOccurred()

       // Ghost deck fades as card turns
       withAnimation(.easeOut(duration: 0.4)) {
           ghostOpacity = 0
       }

       if reduceMotion {
           flipDegrees  = 180
           backRevealed = true
           phase        = .flipped
       } else {
           withAnimation(.spring(response: 0.58, dampingFraction: 0.84)) {
               flipDegrees = 180
           }
           // backRevealed at ~90° — spring(0.58, 0.84) reaches 90° at ~320ms
           DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
               backRevealed = true
               phase        = .flipped
           }
       }
   }

   // MARK: - Pill Selection

   private func handlePillSelected(_ pill: CardRevealPill) {
       guard phase == .flipped, selectedPill == nil else { return }
       selectedPill = pill
       phase        = .selected
       UIImpactFeedbackGenerator(style: .light).impactOccurred()

       // Beat 1 — immediate: selected pill breathes
       withAnimation(.spring(response: 0.6, dampingFraction: 0.9)) {
           selectedPillScale = 1.06
       }

       // Beat 2 — t+500ms: border blooms
       DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
           withAnimation(.easeInOut(duration: 0.3)) {
               selectedBorderWidth = 3.0
           }
           UIImpactFeedbackGenerator(style: .light).impactOccurred()
       }

       // Beat 3 — t+900ms: unselected pills sink
       DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
           withAnimation(.easeIn(duration: 0.35)) {
               unselectedPillsVisible = false
           }
       }

       // t+1.3s — card exits upward
       DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
           withAnimation(.timingCurve(0.4, 0, 0.6, 1, duration: 0.45)) {
               cardExiting = true
           }
       }

       // t+1.65s — encouragement rises into vacated space
       DispatchQueue.main.asyncAfter(deadline: .now() + 1.65) {
           phase = .encouragement
           withAnimation(.easeOut(duration: 0.4)) {
               encouragementVisible = true
           }
       }
   }

   // MARK: - Typing complete → advance

   private func handleTypingComplete() {
       guard !hasAdvanced else { return }
       typingComplete = true
       DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
           commitAndAdvance()
       }
   }

   private func commitAndAdvance() {
       guard !hasAdvanced else { return }
       hasAdvanced         = true
       data.nmCardResponse = selectedPill?.rawValue
       phase               = .exiting

       withAnimation(.easeIn(duration: 0.5)) {
           exitingToNext = true
           sceneOpacity  = 0
       }
       DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
           onContinue?()
       }
   }

   // MARK: - Skip

   private func handleSkip() {
       fuseBurnProgress  = 0
       fuseBurnStartDate = nil
       fuseVisible   = false
       fuseCompleted = true
       flipHintActive  = false
       flipHintDegrees = 0
       guard phase == .idle, !hasAdvanced else { return }
       hasAdvanced         = true
       data.nmCardResponse = nil

       withAnimation(.easeIn(duration: 0.5)) {
           exitingToNext = true
           sceneOpacity  = 0
       }
       DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
           onContinue?()
       }
   }

   private func handleFuseComplete() {
       guard phase == .idle, !fuseCompleted else { return }
       fuseCompleted    = true
       withAnimation(.easeInOut(duration: 1.2)) {
       }
       DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
           self.startFlipHint()
       }
       // ...existing code...
   }

   private func startFlipHint() {
       guard phase == .idle else { return }
       flipHintActive = true
       pulseFlipHint()
   }

   private func pulseFlipHint() {
       guard flipHintActive, phase == .idle else {
           flipHintDegrees = 0
           return
       }
       withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
           flipHintDegrees = 12
       }
       DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
           withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
               self.flipHintDegrees = 0
           }
       }
       DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
           self.pulseFlipHint()
       }
   }

   private func updateFuseProgress(at date: Date) {
       guard fuseVisible, !fuseCompleted,
             let start = fuseBurnStartDate else { return }
       let elapsed      = date.timeIntervalSince(start)
       fuseBurnProgress = min(elapsed / fuseDuration, 1.0)
       if fuseBurnProgress >= 1.0 { handleFuseComplete() }
   }
}

// MARK: - Card Front

private struct CardFrontView: View {
   let cardSize:           CGSize
   let cornerRadius:       CGFloat
   let isLight:            Bool
   let arrowTriggered:     Bool
   let sitWithThisVisible: Bool
   let onTap:              () -> Void
   let fuseProgress:       Double

   var body: some View {
       ZStack {
           // Base fill
           RoundedRectangle(cornerRadius: cornerRadius)
               .fill(cardFill)

           // Ambient wash — top-left corner
           RoundedRectangle(cornerRadius: cornerRadius)
               .fill(
                   RadialGradient(
                       colors: isLight
                           ? [AppColors.magenta.opacity(0.06), Color.clear]
                           : [AppColors.purple.opacity(0.15),  Color.clear],
                       center:      UnitPoint(x: 0.3, y: 0.2),
                       startRadius: 0,
                       endRadius:   180
                   )
               )

           // Border
           if isLight {
               RoundedRectangle(cornerRadius: cornerRadius)
                   .strokeBorder(AppColors.warmAuroraBorder, lineWidth: 2.5)
           } else {
               RoundedRectangle(cornerRadius: cornerRadius)
                   .strokeBorder(AppColors.spectrumBorder, lineWidth: 2.5)
           }

           // Burn cover — occludes the gradient border with card background
           Canvas { ctx, canvasSize in
               guard fuseProgress > 0 else { return }
               let rect = CGRect(
                   x: 1.25,
                   y: 1.25,
                   width:  canvasSize.width  - 2.5,
                   height: canvasSize.height - 2.5
               )
               let fullPath = RoundedRectangle(cornerRadius: cornerRadius - 1.25)
                   .path(in: rect)
               let path = fullPath

               // Consumed segment — paints over the gradient border with the
               // card's own background color, creating the burn illusion.
               // lineWidth is wider than the border (4.0 vs 2.5) so it
               // fully occludes the gradient with no fringing.
               let startOffset: Double = 0.75  // mid-right edge, burns clockwise to top-right almost immediately
               let end = startOffset + fuseProgress

               if end <= 1.0 {
                   // No wrap needed
                   let consumed = path.trimmedPath(from: startOffset, to: end)
                   ctx.stroke(consumed,
                       with: .color(isLight
                           ? Color(red: 1.00, green: 0.99, blue: 1.00)
                           : Color(red: 0.051, green: 0.043, blue: 0.122)),
                       style: StrokeStyle(lineWidth: 4.0, lineCap: .round))
               } else {
                   // Wrap — draw two segments
                   let seg1 = path.trimmedPath(from: startOffset, to: 1.0)
                   let seg2 = path.trimmedPath(from: 0, to: end - 1.0)
                   ctx.stroke(seg1,
                       with: .color(isLight
                           ? Color(red: 1.00, green: 0.99, blue: 1.00)
                           : Color(red: 0.051, green: 0.043, blue: 0.122)),
                       style: StrokeStyle(lineWidth: 4.0, lineCap: .round))
                   ctx.stroke(seg2,
                       with: .color(isLight
                           ? Color(red: 1.00, green: 0.99, blue: 1.00)
                           : Color(red: 0.051, green: 0.043, blue: 0.122)),
                       style: StrokeStyle(lineWidth: 4.0, lineCap: .round))
               }
           }
           .frame(width: cardSize.width, height: cardSize.height)
           .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
           .allowsHitTesting(false)

           // Spark head — glowing spark at the burn position
           Canvas { ctx, canvasSize in
               guard fuseProgress > 0, fuseProgress < 1.0 else { return }
               let rect = CGRect(
                   x: 1.25,
                   y: 1.25,
                   width:  canvasSize.width  - 2.5,
                   height: canvasSize.height - 2.5
               )
               let fullPath = RoundedRectangle(cornerRadius: cornerRadius - 1.25)
                   .path(in: rect)
               let path = fullPath

               // Get the point at the current burn position
               let startOffset: Double = 0.75
               let sparkPos = (startOffset + fuseProgress)
                   .truncatingRemainder(dividingBy: 1.0)
               let head = path.trimmedPath(
                   from: max(0, sparkPos - 0.001),
                   to:   sparkPos)
               guard let pt = head.currentPoint else { return }

               let r = CGFloat(3.5)
               let sparkRect = CGRect(x: pt.x - r, y: pt.y - r, width: r * 2, height: r * 2)

               // Map spark's actual XY position to diagonal gradient progress.
               // Gradient runs topLeading → bottomTrailing so we average
               // normalized X and Y to get a 0→1 diagonal progress value.
               let gradientT = (pt.x / canvasSize.width * 0.5)
                             + (pt.y / canvasSize.height * 0.5)

               let sparkColor: Color = {
                   let t = max(0, min(1, gradientT))
                   if isLight {
                       // purple(0.0) → magenta(0.5) → gold(1.0)
                       if t < 0.5 {
                           return interpolate(
                               from: AppColors.purple,
                               to:   AppColors.magenta,
                               t:    t / 0.5
                           )
                       } else {
                           return interpolate(
                               from: AppColors.magenta,
                               to:   AppColors.gold,
                               t:    (t - 0.5) / 0.5
                           )
                       }
                   } else {
                       // cyan(0.0) → purple(0.5) → magenta(1.0)
                       if t < 0.5 {
                           return interpolate(
                               from: AppColors.cyan,
                               to:   AppColors.purple,
                               t:    t / 0.5
                           )
                       } else {
                           return interpolate(
                               from: AppColors.purple,
                               to:   AppColors.magenta,
                               t:    (t - 0.5) / 0.5
                           )
                       }
                   }
               }()

               // Outer atmospheric glow
               var outerCtx = ctx
               outerCtx.addFilter(.blur(radius: 6))
               outerCtx.fill(
                   Circle().path(in: sparkRect.insetBy(dx: -4, dy: -4)),
                   with: .color(sparkColor.opacity(0.5))
               )

               // Mid glow
               var midCtx = ctx
               midCtx.addFilter(.blur(radius: 3))
               midCtx.fill(
                   Circle().path(in: sparkRect.insetBy(dx: -1, dy: -1)),
                   with: .color(sparkColor.opacity(0.7))
               )

               // Core
               ctx.fill(
                   Circle().path(in: sparkRect),
                   with: .color(sparkColor)
               )

               // Hot white center
               ctx.fill(
                   Circle().path(in: sparkRect.insetBy(dx: r * 0.45, dy: r * 0.45)),
                   with: .color(.white.opacity(0.95))
               )
           }
           .frame(width: cardSize.width, height: cardSize.height)
           .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
           .allowsHitTesting(false)

           VStack(spacing: 16) {
               Text("YOUR FIRST CARD")
                   .font(AppFonts.overline)
                   .tracking(2.0)
                   .foregroundStyle(
                       isLight ? AppColors.lightTextTertiary : AppColors.textTertiary
                   )
                   .padding(.top, 20)

               Spacer(minLength: 0)

               VStack(spacing: 8) {
                   Text("What would you desire if nobody")
                       .font(AppFonts.body(19, weight: .semibold))
                       .foregroundStyle(
                           isLight ? AppColors.lightCardTitle : AppColors.textPrimary
                       )
                       .multilineTextAlignment(.center)

                   LivingText(
                       text: "not even you,",
                       font: AppFonts.body(20, weight: .semibold)
                   )

                   Text("would judge the answer?")
                       .font(AppFonts.body(19, weight: .semibold))
                       .foregroundStyle(
                           isLight ? AppColors.lightCardTitle : AppColors.textPrimary
                       )
                       .multilineTextAlignment(.center)
               }
               .padding(.horizontal, 28)

               Spacer(minLength: 0)

               Spacer(minLength: 28)
           }
           // ↓ THIS IS THE FIX — VStack must claim the card's full frame
           // so Spacers have room to distribute. Without this, the ZStack
           // collapses the VStack to its content height and Spacers = 0.
           .frame(width: cardSize.width, height: cardSize.height)
       }
       .cardShadows(isLight: isLight)
       .contentShape(Rectangle())
       .onTapGesture { onTap() }
   }

   private var cardFill: some ShapeStyle {
       isLight
           ? AnyShapeStyle(LinearGradient(
               colors: [
                   Color(red: 1.00, green: 0.99, blue: 1.00),
                   Color(red: 0.98, green: 0.97, blue: 0.99),
               ],
               startPoint: .topLeading,
               endPoint:   .bottomTrailing))
           : AnyShapeStyle(LinearGradient(
               colors: [
                   Color(red: 0.051, green: 0.043, blue: 0.122),
                   Color(red: 0.031, green: 0.024, blue: 0.094),
               ],
               startPoint: .topLeading,
               endPoint:   .bottomTrailing))
   }

   private func interpolate(from: Color, to: Color, t: Double) -> Color {
       let t = max(0, min(1, t))
       let fromUI = UIColor(from)
       let toUI   = UIColor(to)
       var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
       var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
       fromUI.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
       toUI.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
       return Color(
           red:   Double(r1 + (r2 - r1) * t),
           green: Double(g1 + (g2 - g1) * t),
           blue:  Double(b1 + (b2 - b1) * t),
           opacity: Double(a1 + (a2 - a1) * t)
       )
   }
}

// MARK: - Card Back

private struct CardBackView: View {
   let cardSize:            CGSize
   let cornerRadius:        CGFloat
   let selectedPill:        CardRevealPill?
   let selectedScale:       CGFloat
   let selectedBorderWidth: CGFloat
   let unselectedVisible:   Bool
   let revealed:            Bool
   let isLight:             Bool
   let onSelect:            (CardRevealPill) -> Void

   var body: some View {
       ZStack {
           // Base fill — mirrors front
           RoundedRectangle(cornerRadius: cornerRadius)
               .fill(cardFill)

           // Ambient wash — opposite corner from front
           RoundedRectangle(cornerRadius: cornerRadius)
               .fill(
                   RadialGradient(
                       colors: isLight
                           ? [AppColors.magenta.opacity(0.06), Color.clear]
                           : [AppColors.purple.opacity(0.15),  Color.clear],
                       center:      UnitPoint(x: 0.7, y: 0.8),
                       startRadius: 0,
                       endRadius:   180
                   )
               )

           // Border — lineWidth animated by selectedBorderWidth (bloom on selection)
           if isLight {
               RoundedRectangle(cornerRadius: cornerRadius)
                   .strokeBorder(AppColors.warmAuroraBorder, lineWidth: selectedBorderWidth)
           } else {
               RoundedRectangle(cornerRadius: cornerRadius)
                   .strokeBorder(AppColors.spectrumBorder, lineWidth: selectedBorderWidth)
           }

           VStack(spacing: 0) {
               // Heading enters slightly before pills
               VStack(spacing: 6) {
                   Text("Something came up.")
                       .font(AppFonts.body(20, weight: .semibold))
                       .foregroundStyle(
                           isLight ? AppColors.lightCardTitle : AppColors.textPrimary
                       )
                       .multilineTextAlignment(.center)

                   Text("What's it closest to?")
                       .font(AppFonts.caption)
                       .foregroundStyle(
                           isLight
                               ? AppColors.lightCardTitle.opacity(0.50)
                               : AppColors.textSecondary
                       )
               }
               .padding(.top, 36)
               .opacity(revealed ? 1 : 0)
               .offset(y: revealed ? 0 : 6)
               .animation(.easeOut(duration: 0.3), value: revealed)

               Spacer()

               // Pills — staggered entrance via CardRevealPillButton
               VStack(spacing: 10) {
                   ForEach(
                       Array(CardRevealPill.allCases.enumerated()),
                       id: \.element
                   ) { index, pill in
                       CardRevealPillButton(
                           pill:            pill,
                           index:           index,
                           selectedPill:    selectedPill,
                           selectedScale:   selectedScale,
                           borderWidth:     selectedBorderWidth,
                           globalVisible:   unselectedVisible,
                           revealed:        revealed,
                           isLight:         isLight,
                           onTap:           { onSelect(pill) }
                       )
                   }
               }
               .padding(.horizontal, 20)

               Spacer()

               Text("✦")
                   .font(AppFonts.overline)
                   .foregroundStyle(
                       isLight
                           ? AppColors.lightTextTertiary.opacity(0.5)
                           : AppColors.textTertiary.opacity(0.5)
                   )
                   .opacity(revealed ? 0.6 : 0)
                   .animation(.easeOut(duration: 0.4).delay(0.5), value: revealed)
                   .padding(.bottom, 24)
           }
       }
       .frame(width: cardSize.width, height: cardSize.height)
       .cardShadows(isLight: isLight)
   }

   private var cardFill: some ShapeStyle {
       isLight
           ? AnyShapeStyle(LinearGradient(
               colors: [
                   Color(red: 1.00, green: 0.99, blue: 1.00),
                   Color(red: 0.98, green: 0.97, blue: 0.99),
               ],
               startPoint: .topLeading,
               endPoint:   .bottomTrailing))
           : AnyShapeStyle(LinearGradient(
               colors: [
                   Color(red: 0.051, green: 0.043, blue: 0.122),
                   Color(red: 0.031, green: 0.024, blue: 0.094),
               ],
               startPoint: .topLeading,
               endPoint:   .bottomTrailing))
   }
}

// MARK: - Pill Button

private struct CardRevealPillButton: View {
   let pill:          CardRevealPill
   let index:         Int
   let selectedPill:  CardRevealPill?
   let selectedScale: CGFloat
   let borderWidth:   CGFloat
   let globalVisible: Bool
   let revealed:      Bool
   let isLight:       Bool
   let onTap:         () -> Void

   @State private var entranceVisible = false

   private var isSelected: Bool { selectedPill == pill }
   private var isOther:    Bool { selectedPill != nil && !isSelected }

   // Heading has a 120ms head-start; pills stagger at 70ms each
   private var entranceDelay: Double { Double(index) * 0.07 + 0.12 }

   var body: some View {
       Button {
           guard selectedPill == nil else { return }
           UIImpactFeedbackGenerator(style: .light).impactOccurred()
           onTap()
       } label: {
           Text(pill.rawValue)
               .font(AppFonts.bodyMedium)
               .foregroundStyle(
                   isSelected
                       ? (isLight ? AppColors.lightCardTitle : AppColors.textPrimary)
                       : (isLight ? AppColors.wineDark : Color.white.opacity(0.75))
               )
               .frame(maxWidth: .infinity)
               .frame(height: 44)
               .background(pillBackground)
               .overlay(pillBorder)
               .clipShape(Capsule())
       }
       .buttonStyle(.plain)
       // Scale — driven by parent selectedPillScale during beat 1
       .scaleEffect(isSelected ? selectedScale : 1.0)
       .animation(
           .spring(response: 0.35, dampingFraction: 0.7),
           value: selectedScale
       )
       // Entrance stagger — rise from y+10
       .opacity(entranceVisible ? (isOther && !globalVisible ? 0 : 1) : 0)
       .offset(y: entranceVisible ? (isOther && !globalVisible ? 4 : 0) : 10)
       .animation(
           .easeOut(duration: 0.35).delay(entranceDelay),
           value: entranceVisible
       )
       // Beat 3 sink — independent from entrance
       .animation(.easeIn(duration: 0.35), value: globalVisible)
       .disabled(isOther)
       .accessibilityLabel(pill.rawValue)
       .accessibilityAddTraits(isSelected ? .isSelected : [])
       .onChange(of: revealed) { _, newVal in
           if newVal { entranceVisible = true }
       }
       .onAppear {
           if revealed { entranceVisible = true }
       }
   }

   @ViewBuilder
   private var pillBackground: some View {
       Capsule()
           .fill(
               isSelected
                   ? (isLight
                       ? AnyShapeStyle(AppColors.lightFrostPillSel)
                       : AnyShapeStyle(Color.white.opacity(0.10)))
                   : (isLight
                       ? AnyShapeStyle(AppColors.lightFrostPill)
                       : AnyShapeStyle(AppColors.cardBg))
           )
   }

   @ViewBuilder
   private var pillBorder: some View {
       if isSelected {
           if isLight {
               Capsule()
                   .strokeBorder(AppColors.warmAuroraBorder, lineWidth: borderWidth)
           } else {
               Capsule()
                   .strokeBorder(AppColors.spectrumBorder, lineWidth: borderWidth)
           }
       } else {
           Capsule()
               .strokeBorder(
                   isLight ? AppColors.lightBorder : AppColors.border,
                   lineWidth: 1.5
               )
       }
   }
}

// MARK: - Encouragement View
//
// Typewriter reveal at 38 cps using AttributedString — no Text + Text.
//
// Sequence:
//   1. Plain text types in body color
//   2. Accent types in a static single color (cyan dark / magenta light)
//      matching LivingText's leading gradient stop
//   3. Once accent is fully typed, LivingText crossfades in over the
//      static accent — the glow "wakes up" invisibly since both start
//      at the same leading color
//   4. Cursor ("|") blinks × 3 then fades
//   5. onComplete() fires → parent waits 900ms → commitAndAdvance()

private struct EncouragementView: View {

   let isLight:      Bool
   let active:       Bool
   let reduceMotion: Bool
   let onComplete:   () -> Void

   private let plainText  = "This journey asks a lot of the people it's meant for. "
   private let accentText = "You're in good company."
   private var fullText: String { plainText }

   private let charsPerSecond: Double = 18

   @State private var visibleCharCount:  Int    = 0
   @State private var cursorOn:          Bool   = true
   @State private var cursorDone:        Bool   = false
   @State private var accentFullyTyped:  Bool   = false
   @State private var livingTextOpacity: Double = 0
   @State private var livingTextOffsetY: CGFloat = 8
   @State private var typingTask: DispatchWorkItem? = nil

   var body: some View {
       VStack(spacing: 0) {
           Spacer()
           composedText
               .multilineTextAlignment(.center)
               .padding(.horizontal, 40)
           Spacer()
       }
       .frame(width: 300, height: 400)
       .onAppear   { if active { beginTyping() } }
       .onChange(of: active) { _, isActive in
           if isActive { beginTyping() }
       }
   }

   @ViewBuilder
   private var composedText: some View {
       VStack(spacing: 0) {
           // Plain sentence — typewriter until fully typed,
           // then static (cursor gone, accent has arrived)
           Text(buildAttributedString(
               plain:      String(plainText.prefix(visibleCharCount)),
               accent:     "",
               showCursor: !cursorDone && cursorOn
           ))
           .fixedSize(horizontal: false, vertical: true)
           .multilineTextAlignment(.center)

           // Accent — fades in all at once once plain is done.
           // opacity 0 until livingTextOpacity animates to 1.
           LivingText(
               text: accentText,
               font: AppFonts.body(20, weight: .bold)
           )
           .opacity(livingTextOpacity)
           .offset(y: livingTextOffsetY)
       }
   }

   private func buildAttributedString(
       plain:      String,
       accent:     String,
       showCursor: Bool
   ) -> AttributedString {
       // Plain portion
       var result = AttributedString(plain)
       result.font            = AppFonts.body(20, weight: .medium)
       result.foregroundColor = isLight ? AppColors.lightCardTitle : AppColors.textPrimary

       // Accent portion — single color matching LivingText's leading stop
       if !accent.isEmpty {
           var accentAttr = AttributedString(accent)
           accentAttr.font            = AppFonts.body(20, weight: .bold)
           accentAttr.foregroundColor = isLight ? AppColors.magenta : AppColors.cyan
           result.append(accentAttr)
       }

       // Cursor
       if showCursor {
           var cursor = AttributedString("|")
           cursor.font            = AppFonts.body(20, weight: .thin)
           cursor.foregroundColor = isLight ? AppColors.magenta : AppColors.cyan
           result.append(cursor)
       }

       return result
   }

   // MARK: Typing sequence

   private func beginTyping() {
       guard visibleCharCount == 0 else { return }

       if reduceMotion {
           visibleCharCount  = fullText.count
           accentFullyTyped  = true
           cursorDone        = true
           livingTextOpacity = 1
           livingTextOffsetY = 0
           onComplete()
           return
       }

       typeNextChar()
   }

   private func typeNextChar() {
       guard visibleCharCount < fullText.count else {
           blinkCursor(count: 0)
           return
       }

       let item = DispatchWorkItem {
           visibleCharCount += 1

           // Detect when plain text becomes fully visible
           if !accentFullyTyped && visibleCharCount == fullText.count {
               accentFullyTyped = true
               // Cursor fades out first (150ms), then LivingText arrives
               DispatchQueue.main.asyncAfter(deadline: .now() + 0.50) {
                   cursorDone = true
                   // Opacity and rise arrive together — easeOut so it
                   // decelerates into its final position, not springs
                   withAnimation(.easeOut(duration: 1.0)) {
                       livingTextOpacity  = 1
                       livingTextOffsetY  = 0
                   }
               }
           }

           typeNextChar()
       }
       typingTask = item
       DispatchQueue.main.asyncAfter(
           deadline: .now() + 1.0 / charsPerSecond,
           execute: item
       )
   }

   private func blinkCursor(count: Int) {
       guard count < 6 else {
           cursorOn   = false
           cursorDone = true
           withAnimation(.easeOut(duration: 1.0)) {
               livingTextOpacity = 1
           }
           DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
               onComplete()
           }
           return
       }
       DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
           cursorOn = !cursorOn
           blinkCursor(count: count + 1)
       }
   }
}

// MARK: - Card Shadow Modifier

private extension View {
   func cardShadows(isLight: Bool) -> some View {
       self
           .shadow(
               color: isLight
                   ? AppColors.purple.opacity(0.10)
                   : AppColors.cyan.opacity(0.14),
               radius: 20
           )
           .shadow(
               color: Color.black.opacity(isLight ? 0.06 : 0.85),
               radius: 25,
               y: 25
           )
   }
}

// MARK: - Previews

#Preview("Dark") {
   @Previewable @State var data = OnboardingData()
   ZStack {
       AppColors.pageBg.ignoresSafeArea()
       OnboardingAtmosphere(
           config:      .cardReveal,
           sparkConfig: .curiosityPickerView,
           opacity:     1.0
       )
       .ignoresSafeArea()
       OnboardingCardRevealView(data: $data, onContinue: {})
   }
   .preferredColorScheme(.dark)
}

#Preview("Light") {
   @Previewable @State var data = OnboardingData()
   ZStack {
       AppColors.lightPageBg.ignoresSafeArea()
       OnboardingAtmosphere(
           config:      .cardReveal,
           sparkConfig: .curiosityPickerView,
           opacity:     1.0
       )
       .ignoresSafeArea()
       OnboardingCardRevealView(data: $data, onContinue: {})
   }
   .preferredColorScheme(.light)
}

```

---

## File: `Open Lightly/Features/Onboarding/Views/OnboardingGroundRulesView.swift` {#file-open-lightly-features-onboarding-views-onboardinggroundrulesview-swift}

```swift
// Features/Onboarding/Views/OnboardingGroundRulesView.swift
//
// Screen 8: Before you dive in — honest framing of what this journey is and isn't.
// Must-acknowledge. No back button. No skipping.
// Writes data.groundRulesAcceptedAt, data.onboardingComplete, and data.completedAt
// on acknowledgment then calls onFinished.
//
// Layout strategy:
// - All devices use FlipPromiseCards — title front, detail back on tap
// - Card height scales: SE 72pt → mid 80pt → large 88pt
// - ScrollView with minHeight: fits without scroll on tall devices, scrolls on short ones

import SwiftUI

// MARK: - Main View

struct OnboardingGroundRulesView: View {
    @Binding var data: OnboardingData
    var onFinished: (() -> Void)? = nil

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion // ANIM-STD-31

    @State private var hasAnimated        = false
    @State private var atmosphereVisible  = false
    @State private var progressVisible    = false
    @State private var overlineVisible    = false
    @State private var subtextVisible     = false
    @State private var rulesVisible: Set<Int> = []
    @State private var frameVisible       = false
    @State private var ctaVisible         = false
    @State private var isPeeking          = false

    // MARK: - Pill Data

    private struct PillContent: Identifiable {
        let id: Int
        let icon: String
        let iconBg: AnyShapeStyle
        let title: String
        let detail: String
    }

    private var pills: [PillContent] {
        let pill2: PillContent = data.explorationMode == .couple
            ? PillContent(
                id: 1,
                icon: "heart.fill",
                iconBg: AnyShapeStyle(LinearGradient(
                    colors: [AppColors.orangeHot, AppColors.gold],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )),
                title: "This works best when you're both curious.",
                detail: "If one of you is pushing and the other is being dragged, this will surface that faster than it resolves it. Come in open — both of you."
              )
            : PillContent(
                id: 1,
                icon: "figure.walk",
                iconBg: AnyShapeStyle(LinearGradient(
                    colors: [AppColors.orangeHot, AppColors.gold],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )),
                title: "This won't resolve things you're running from.",
                detail: "The best it can do is help you understand what you're running toward."
              )
        return [
            PillContent(
                id: 0,
                icon: "lightbulb.fill",
                iconBg: AnyShapeStyle(LinearGradient(
                    colors: [AppColors.magenta, AppColors.orangeHot],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )),
                title: "They say money shows you more of who you are.",
                detail: "This journey will do more of the same, if you see it through."
            ),
            pill2,
            PillContent(
                id: 2,
                icon: "hand.raised.fill",
                iconBg: AnyShapeStyle(LinearGradient(
                    colors: [AppColors.magenta, AppColors.gold],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )),
                title: "This is not therapy, and it's not trying to be.",
                detail: "Not every journey into this territory requires clinical support — but if yours does, the resources are here whenever you need them."
            ),
        ]
    }

    // MARK: - Computed helpers

    private var isLight: Bool { colorScheme == .light }

    private var subheadSuffix: String {
        ", the most important questions about who you are and what you want rarely come with a roadmap — this was built to help you find your way."
    }

    private var subheadFallback: String {
        "The most important questions about who you are and what you want rarely come with a roadmap — this was built to help you find your way."
    }

    private var subheadTextColor: Color {
        isLight ? AppColors.lightCardTitle : AppColors.textPrimary
    }

    private var italicLineStyle: AnyShapeStyle {
        if isLight {
            return AnyShapeStyle(LinearGradient(
                stops: [
                    .init(color: AppColors.magenta,   location: 0.00),
                    .init(color: AppColors.orangeHot, location: 0.55),
                    .init(color: AppColors.gold,      location: 1.00),
                ],
                startPoint: .leading,
                endPoint: .trailing
            ))
        } else {
            return AnyShapeStyle(LinearGradient(
                colors: [AppColors.cyan, AppColors.purple, AppColors.magenta],
                startPoint: .leading,
                endPoint: .trailing
            ))
        }
    }

    // MARK: - Subhead View

    @ViewBuilder
    private func subheadView(h: CGFloat) -> some View {
        let font: Font = h < 700
            ? AppFonts.display(18)
            : h < 760
                ? AppFonts.display(20)
                : h < 820
                    ? AppFonts.display(21)
                    : AppFonts.screenTitle

        if data.displayName.isEmpty {
            Text(subheadFallback)
                .font(font)
                .foregroundStyle(subheadTextColor)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Text("\(data.displayName)\(subheadSuffix)")
                .font(font)
                .foregroundStyle(subheadTextColor)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let w = geo.size.width
            let isCompact = h < 720
            let isMid     = h >= 720 && h < 760
            let cardPad: CGFloat = isCompact ? 12 : isMid ? 10 : 14
            let cardGap: CGFloat = isCompact
                ? OL.compact(h)
                : isMid
                    ? OL.compact(h) * 0.7
                    : OL.compact(h)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    contentBlock(
                        h: h, w: w,
                        isCompact: isCompact,
                        isMid: isMid,
                        cardPad: cardPad,
                        cardGap: cardGap
                    )
                    Spacer(minLength: 0)
                    ctaBlock(geo: geo)
                        .padding(.horizontal, 24)
                }
                .frame(minHeight: geo.size.height)
            }
            .background {
                ZStack {
                    Color.clear.ignoresSafeArea()
                    atmosphereLayer
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
                .ignoresSafeArea()
            }
            .accessibilityLabel("Before you dive in. Screen 8 of 8.")
            .accessibilityAction(named: "I'm ready") { handleAcknowledge() }
            .onAppear {
                guard !hasAnimated else { return }
                hasAnimated = true
                #if DEBUG
                if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
                    atmosphereVisible = true
                    progressVisible   = true
                    overlineVisible   = true
                    subtextVisible    = true
                    rulesVisible      = [0, 1, 2]
                    frameVisible      = true
                    ctaVisible        = true
                    return
                }
                #endif
                startAnimation()
            }
        }
    }

    // MARK: - Content Block

    @ViewBuilder
    private func contentBlock(
        h: CGFloat,
        w: CGFloat,
        isCompact: Bool,
        isMid: Bool,
        cardPad: CGFloat,
        cardGap: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {

            // Progress bar
            OnboardingProgressBar(
                currentStep:          6,
                totalSteps:           6,
                progressDescription:  "Onboarding",
                showCompletionEffect: true
            )
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, isCompact
                ? OL.navTop(h) + OL.compact(h)
                : OL.navTop(h) + OL.standard(h))
            .padding(.bottom, isCompact
                ? OL.compact(h)
                : OL.standard(h))
            .opacity(progressVisible ? 1 : 0)
            .animation(.easeOut(duration: 0.6), value: progressVisible)
            .accessibilityHidden(true)

            // Overline
            Group {
                if isLight {
                    Text("BEFORE YOU DIVE IN")
                        .font(AppFonts.overline)
                        .tracking(2)
                        .overlay(
                            LinearGradient(
                                stops: [
                                    .init(color: AppColors.magenta,   location: 0.00),
                                    .init(color: AppColors.orangeHot, location: 0.55),
                                    .init(color: AppColors.gold,      location: 1.00),
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .mask(
                                Text("BEFORE YOU DIVE IN")
                                    .font(AppFonts.overline)
                                    .tracking(2)
                            )
                        )
                } else {
                    Text("BEFORE YOU DIVE IN")
                        .font(AppFonts.overline)
                        .foregroundStyle(AppColors.cyanLight)
                        .tracking(2)
                }
            }
            .opacity(overlineVisible ? 1 : 0) // ANIM-STD-32
            .scaleEffect(overlineVisible ? 1.0 : 0.95) // ANIM-STD-32
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: overlineVisible)
            .padding(.horizontal, 24)
            .padding(.bottom, OL.compact(h))
            .accessibilityHidden(true)

            // Headline
            subheadView(h: h)
                .opacity(subtextVisible ? 1 : 0) // ANIM-STD-32
                .scaleEffect(subtextVisible ? 1.0 : 0.95) // ANIM-STD-32
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: subtextVisible)
                .padding(.horizontal, 24)
                .padding(.bottom, isCompact
                    ? OL.compact(h)
                    : isMid
                        ? OL.compact(h)
                        : OL.standard(h))

            // Promise Cards — all devices use FlipPromiseCard
            VStack(spacing: cardGap) {
                ForEach(pills) { pill in
                    let isVisible = rulesVisible.contains(pill.id)
                    FlipPromiseCard(
                        icon:         pill.icon,
                        iconGradient: pill.iconBg,
                        title:        pill.title,
                        detail:       pill.detail,
                        verticalPad:  cardPad,
                        cardHeight:   isCompact ? 72 : isMid ? 80 : 88
                    )
                    .opacity(isVisible ? 1 : 0) // ANIM-STD-33
                    .scaleEffect(isVisible ? 1.0 : 0.95) // ANIM-STD-33
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isVisible)
                    .rotation3DEffect(
                        .degrees(pill.id == 0 && isPeeking ? 15 : 0),
                        axis: (x: 1, y: 0, z: 0),
                        perspective: 0.5
                    )
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.bottom, isCompact
                ? OL.compact(h)
                : isMid
                    ? OL.compact(h)
                    : OL.standard(h))
        }
        // NO Spacer, NO maxHeight frame, NO backgrounds
    }

    // MARK: - CTA Block

    private func ctaBlock(geo: GeometryProxy) -> some View {
        let h = geo.size.height
        let isCompact = h < 720
        let isMid = h >= 720 && h < 760
        let lifeguardFont: Font = isCompact
            ? AppFonts.body(16, weight: .medium)
            : isMid
                ? AppFonts.body(17, weight: .medium)
                : AppFonts.body(18, weight: .medium)
        return VStack(spacing: 0) {
            Text("Think of us as the lifeguard at the edge of the pool — not to keep you from the deep end, but to throw you a lifesaver if you need one.")
                .font(lifeguardFont)
                .italic()
                .foregroundStyle(italicLineStyle)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .opacity(frameVisible ? 1 : 0) // ANIM-STD-34
                .scaleEffect(frameVisible ? 1.0 : 0.95) // ANIM-STD-34
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: frameVisible)
                .padding(.horizontal, 24)
                .padding(.bottom, OL.compact(h))
            HoloCTAButton(title: "I'm ready", isEnabled: true) {
                handleAcknowledge()
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.bottom, geo.safeAreaInsets.bottom > 0
                ? geo.safeAreaInsets.bottom + 8
                : 24)
            .opacity(ctaVisible ? 1 : 0)
            .animation(
                .spring(response: 0.5, dampingFraction: 0.82),
                value: ctaVisible
            )
        }
    }

    // MARK: - Atmospheric Layer

    private var atmosphereLayer: some View {
        GeometryReader { geo in
            ZStack {
                if isLight {
                    Ellipse()
                        .fill(RadialGradient(
                            colors: [
                                AppColors.magenta.opacity(0.12),
                                AppColors.gold.opacity(0.06),
                                Color.clear,
                            ],
                            center: .top,
                            startRadius: 20,
                            endRadius: 360
                        ))
                        .frame(
                            width:  OL.atmosW(geo.size.width),
                            height: OL.atmosH(geo.size.height)
                        )
                        .position(x: geo.size.width / 2, y: -20)
                        .blur(radius: 80)
                        .opacity(atmosphereVisible ? 1 : 0)
                        .animation(.easeInOut(duration: 2.0), value: atmosphereVisible)

                    Rectangle()
                        .fill(LinearGradient(
                            colors: [AppColors.purple.opacity(0.08), Color.clear],
                            startPoint: .bottom,
                            endPoint: .top
                        ))
                        .frame(width: geo.size.width, height: 200)
                        .position(x: geo.size.width / 2, y: geo.size.height - 100)
                        .opacity(atmosphereVisible ? 1 : 0)
                        .animation(.easeInOut(duration: 2.0), value: atmosphereVisible)

                } else {
                    Ellipse()
                        .fill(RadialGradient(
                            colors: [
                                AppColors.purple.opacity(0.30),
                                AppColors.cyan.opacity(0.12),
                                Color.clear,
                            ],
                            center: .top,
                            startRadius: 20,
                            endRadius: 360
                        ))
                        .frame(
                            width:  OL.atmosW(geo.size.width),
                            height: OL.atmosH(geo.size.height)
                        )
                        .position(x: geo.size.width / 2, y: -20)
                        .blur(radius: 80)
                        .opacity(atmosphereVisible ? 1 : 0)
                        .animation(.easeInOut(duration: 2.0), value: atmosphereVisible)

                    Rectangle()
                        .fill(LinearGradient(
                            colors: [AppColors.magenta.opacity(0.08), Color.clear],
                            startPoint: .bottom,
                            endPoint: .top
                        ))
                        .frame(width: geo.size.width, height: 200)
                        .position(x: geo.size.width / 2, y: geo.size.height - 100)
                        .opacity(atmosphereVisible ? 1 : 0)
                        .animation(.easeInOut(duration: 2.0), value: atmosphereVisible)
                }
            }
        }
    }

    // MARK: - Animation Timeline

    private func startAnimation() {
        // ANIM-STD-35: Reduce Motion fallback
        if reduceMotion {
            withAnimation(.easeInOut(duration: 0.2)) {
                atmosphereVisible = true
                progressVisible   = true
                overlineVisible   = true
                subtextVisible    = true
                rulesVisible      = [0, 1, 2]
                frameVisible      = true
                ctaVisible        = true
            }
            return
        }

        // ANIM-STD-36: Standardized three-slot spring cascade
        // Slot A (header — progress + overline + subtext): 0ms
        // Slot B (body  — cards, staggered within slot):  100ms
        // Slot C (CTA   — lifeguard line + button):       200ms
        let spring = Animation.spring(response: 0.35, dampingFraction: 0.8)

        withAnimation(.easeInOut(duration: 2.0)) { atmosphereVisible = true }

        // Slot A
        withAnimation(spring) { progressVisible = true }
        withAnimation(spring) { overlineVisible = true }
        withAnimation(spring) { subtextVisible  = true }

        // Slot B — cards staggered within the 100ms slot window
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
            withAnimation(spring) { _ = rulesVisible.insert(0) }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.17) {
            withAnimation(spring) { _ = rulesVisible.insert(1) }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
            withAnimation(spring) { _ = rulesVisible.insert(2) }
        }

        // Slot C
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
            withAnimation(spring) { frameVisible = true }
            withAnimation(spring) { ctaVisible   = true }
        }

        // Peek effect — ambient, runs after entrance settles
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { isPeeking = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { isPeeking = false }
        }
    }

    // MARK: - Acknowledge

    private func handleAcknowledge() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        data.groundRulesAcceptedAt = Date()
        data.onboardingComplete    = true
        data.completedAt           = Date()
        #if DEBUG
        assert(onFinished != nil,
            "OnboardingGroundRulesView: onFinished not injected — wire from coordinator.")
        #endif
        onFinished?()
    }
}

// MARK: - PromiseCard

private struct PromiseCard: View {
    let icon:         String
    let iconGradient: AnyShapeStyle
    let title:        String
    let detail:       String
    var verticalPad:  CGFloat = 14

    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            iconBadge
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(isLight ? AppColors.lightCardTitle : AppColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .layoutPriority(1)
                Text(detail)
                    .font(AppFonts.bodyText)
                    .foregroundStyle(isLight ? AppColors.lightCardDetail : AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .layoutPriority(1)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, verticalPad)
        .cardSurface(isLight: isLight)
    }

    private var iconBadge: some View {
        ZStack {
            Circle()
                .fill(
                    isLight
                        ? iconGradient
                        : AnyShapeStyle(LinearGradient(
                            colors: [AppColors.cyan.opacity(0.20), AppColors.purple.opacity(0.16)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                          ))
                )
                .opacity(isLight ? 0.18 : 1.0)
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(
                    isLight
                        ? AnyShapeStyle(LinearGradient(
                            stops: [
                                .init(color: AppColors.magenta,   location: 0.00),
                                .init(color: AppColors.orangeHot, location: 0.55),
                                .init(color: AppColors.gold,      location: 1.00),
                            ],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                          ))
                        : AnyShapeStyle(LinearGradient(
                            colors: [AppColors.cyan, AppColors.purple],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                          ))
                )
        }
        .frame(width: 40, height: 40)
        .fixedSize()
        .accessibilityHidden(true)
    }
}

// MARK: - FlipPromiseCard

private struct FlipPromiseCard: View {
    let icon:         String
    let iconGradient: AnyShapeStyle
    let title:        String
    let detail:       String
    var verticalPad:  CGFloat = 8
    var cardHeight:   CGFloat = 72

    @State private var isFlipped = false
    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }

    var body: some View {
        ZStack {
            HStack(spacing: 16) {
                iconBadge
                Text(title)
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(isLight ? AppColors.lightCardTitle : AppColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                Image(systemName: "arrow.turn.up.left")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(isLight
                        ? AppColors.lightTextTertiary
                        : AppColors.textTertiary)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, verticalPad)
            .opacity(isFlipped ? 0 : 1)
            .rotation3DEffect(
                .degrees(isFlipped ? 180 : 0),
                axis: (x: 0, y: 1, z: 0)
            )

            Text(detail)
                .font(AppFonts.caption)
                .foregroundStyle(isLight ? AppColors.lightCardDetail : AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, verticalPad)
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(
                    .degrees(isFlipped ? 0 : -180),
                    axis: (x: 0, y: 1, z: 0)
                )
        }
        .frame(height: cardHeight)
        .frame(maxWidth: .infinity)
        .cardSurface(isLight: isLight)
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isFlipped.toggle()
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isFlipped ? detail : title)
        .accessibilityHint(isFlipped ? "Tap to show title" : "Tap to read more")
        .accessibilityAddTraits(.isButton)
    }

    private var iconBadge: some View {
        ZStack {
            Circle()
                .fill(
                    isLight
                        ? iconGradient
                        : AnyShapeStyle(LinearGradient(
                            colors: [AppColors.cyan.opacity(0.20), AppColors.purple.opacity(0.16)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                          ))
                )
                .opacity(isLight ? 0.18 : 1.0)
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(
                    isLight
                        ? AnyShapeStyle(LinearGradient(
                            stops: [
                                .init(color: AppColors.magenta,   location: 0.00),
                                .init(color: AppColors.orangeHot, location: 0.55),
                                .init(color: AppColors.gold,      location: 1.00),
                            ],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                          ))
                        : AnyShapeStyle(LinearGradient(
                            colors: [AppColors.cyan, AppColors.purple],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                          ))
                )
        }
        .frame(width: 32, height: 32)
        .fixedSize()
        .accessibilityHidden(true)
    }
}

// MARK: - Card Surface

private struct CardSurface: ViewModifier {
    let isLight: Bool
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isLight ? AppColors.lightCardFill : Color.white.opacity(0.05))
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(
                color: AppColors.magenta.opacity(isLight ? 0.07 : 0),
                radius: 8, x: 0, y: 2
            )
            .modifier(PromiseCardBorder(isLight: isLight))
    }
}

private extension View {
    func cardSurface(isLight: Bool) -> some View {
        modifier(CardSurface(isLight: isLight))
    }
}

// MARK: - PromiseCardBorder

private struct PromiseCardBorder: ViewModifier {
    let isLight: Bool
    func body(content: Content) -> some View {
        if isLight {
            content
                .magentaGoldBorder(cornerRadius: 20, lineWidth: 1.5, glowRadius: 3, opacity: 0.55)
        } else {
            content
                .pillBorder(cornerRadius: 20, lineWidth: 1, glowRadius: 3, opacity: 0.45)
        }
    }
}

// MARK: - Previews

#Preview("Dark") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.displayName     = "Jordan"
        d.explorationMode = .solo
        return d
    }()
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config: .groundRules,
            sparkConfig: .groundRulesView,
            opacity: 1.0
        )
        .ignoresSafeArea()
        OnboardingGroundRulesView(data: $data, onFinished: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("Light") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.displayName     = "Jordan"
        d.explorationMode = .solo
        return d
    }()
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config: .groundRules,
            sparkConfig: .groundRulesView,
            opacity: 1.0
        )
        .ignoresSafeArea()
        OnboardingGroundRulesView(data: $data, onFinished: {})
    }
    .preferredColorScheme(.light)
}

```

---

## File: `Open Lightly/Features/Onboarding/Views/PairingForkView.swift` {#file-open-lightly-features-onboarding-views-pairingforkview-swift}

```swift
//
//  PairingForkView.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/10/26.
//


//
//  PairingForkView.swift
//  Open Lightly
//
//  Created in Batch 10 — Onboarding Pairing Decision
//
//  PURPOSE:
//  Shown ONLY to users who selected "Couple" mode in ModeSelectionView.
//  Gives them two choices:
//    1. "Pair Now" → Opens PairingForkView (built in Batch 9) inline in onboarding
//    2. "Pair Later" → Skips pairing, continues onboarding, can pair from Settings
//
//  DESIGN RATIONALE:
//  We don't force pairing during onboarding because:
//    - The partner might not have the app yet
//    - The user might be setting up on a plane/subway (no internet)
//    - Reducing friction in onboarding improves completion rates
//    - Pairing is always available in Settings (wired in Batch 9)
//
//  This view doesn't do any data saving — it just captures the user's choice
//  via the two closures and lets the parent navigate accordingly.
//

import SwiftUI

struct PairingForkView: View {

    /// Called when the user taps "Pair Now".
    /// The parent view should navigate to PairingForkView.
    let onPairNow: () -> Void

    /// Called when the user taps "I'll do this later".
    /// The parent view should skip ahead to Experience Level or Desire Map.
    let onPairLater: () -> Void

    var body: some View {
        VStack(spacing: 32) {

            Spacer()

            // ── Icon ──
            // Visual indicator — a link symbol with a plus badge
            // to communicate "connect with someone."
            Image(systemName: "link.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)

            // ── Title ──
            Text("Connect with\nyour partner")
                .font(.title.bold())
                .multilineTextAlignment(.center)

            // ── Description ──
            // Explains WHY they should pair — unlocks shared features.
            Text("Share a code to link your accounts.\nYou'll unlock shared features like\ncompatibility matching.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            // ── Action Buttons ──
            VStack(spacing: 12) {

                // Primary action: Pair Now
                // Uses accent color to draw attention — this is the preferred path.
                Button(action: onPairNow) {
                    Text("Pair Now")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }

                // Secondary action: Pair Later
                // Subtle styling (no fill, just text) so it doesn't compete
                // with the primary button, but is still easy to find.
                Button(action: onPairLater) {
                    Text("I'll do this later")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                }
            }
        }
        .padding(24)
    }
}

```

---

## File: `Open Lightly/Features/Sessions/SessionView.swift` {#file-open-lightly-features-sessions-sessionview-swift}

```swift
import SwiftUI
import SwiftData

struct SessionView: View {
    // MARK: - State
    @State private var currentIndex: Int = 0
    @State private var showSafeWordConfirm: Bool = false
    @State private var sessionEnded: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    @Environment(\.modelContext) private var modelContext
    @State private var cardStatuses: [(promptText: String, status: CardStatus)] = []
    @State private var sessionStartDate: Date = .now
    @State private var completedFully: Bool = true
    
    private let prompts: [Prompt] = Prompt.samples.isEmpty
        ? SessionView.fallbackPrompts
        : Array(Prompt.samples.prefix(5))
    
    private var currentPrompt: Prompt { prompts[currentIndex] }
    private var isLast: Bool { currentIndex >= prompts.count - 1 }
    
    var body: some View {
        ZStack {
            // Background
            AppColors.background.ignoresSafeArea()
            
            if sessionEnded {
                sessionCompleteView
            } else {
                sessionContent
            }
        }
        .screenshotProtected()
    }
    
    // MARK: - Main Session Content
    private var sessionContent: some View {
        VStack(spacing: 0) {
            topBar
            Spacer(minLength: 12)
            cardArea
            Spacer(minLength: 12)
            progressPips
            Spacer(minLength: 16)
            bottomControls
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text("\(currentIndex + 1) of \(prompts.count)")
                    .font(AppFonts.overline)
                    .foregroundColor(AppColors.textTertiary)
                
                Text(currentPrompt.category.displayName)
                    .font(AppFonts.sectionHeader)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            // Balanced spacer for centering
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.clear)
        }
    }
    
    // MARK: - Prompt Card
    private var cardArea: some View {
        ConversationCard(prompt: currentPrompt)
            .id(currentPrompt.id) // force re-render on change
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            .animation(.easeInOut(duration: 0.35), value: currentIndex)
    }
    
    // MARK: - Progress Pips
    private var progressPips: some View {
        HStack(spacing: 8) {
            ForEach(0..<prompts.count, id: \.self) { i in
                Capsule()
                    .fill(i == currentIndex ? AppColors.cyan : AppColors.border)
                    .frame(width: i == currentIndex ? 24 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.25), value: currentIndex)
            }
        }
    }
    
    // MARK: - Bottom Controls
    private var bottomControls: some View {
        VStack(spacing: 16) {
            // Reaction buttons — like or dislike the current prompt
            HStack(spacing: 12) {
                // Skip — not ready for this card
                Button {
                    recordStatus(.skipped)
                    advanceCard()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 14))
                        Text("Not Ready")
                            .font(AppFonts.bodyMedium)
                    }
                    .foregroundColor(AppColors.textMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .cardStyle(cornerRadius: 12)
                }

                // Bookmark — save for later
                Button {
                    recordStatus(.bookmarked)
                    advanceCard()
                } label: {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.cyan)
                        .frame(width: 52, height: 48)
                        .cardStyle(cornerRadius: 12)
                }
            }

            // Discussed — primary action, full width below
            Button {
                recordStatus(.discussed)
                advanceCard()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                    Text("We Discussed This")
                        .font(AppFonts.bodyMedium)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [AppColors.magenta, AppColors.purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }
    
    // MARK: - Session Complete
    private var sessionCompleteView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.spectrumText)
            
            // Summary of discussed, skipped, and bookmarked counts
            let discussedCount = cardStatuses.filter { $0.status == .discussed }.count
            let skippedCount = cardStatuses.filter { $0.status == .skipped }.count
            let bookmarkedCount = cardStatuses.filter { $0.status == .bookmarked }.count
            VStack(spacing: 8) {
                Text("Session Complete")
                    .font(AppFonts.screenTitle)
                    .foregroundColor(AppColors.textPrimary)
                Text("You discussed \(discussedCount) of \(prompts.count) prompts")
                    .font(AppFonts.bodyMedium)
                    .foregroundColor(AppColors.textSecondary)
                if bookmarkedCount > 0 {
                    Text("\(bookmarkedCount) bookmarked for later")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.cyan)
                }
                if skippedCount > 0 {
                    Text("\(skippedCount) skipped — no pressure")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textMuted)
                }
            }
            .multilineTextAlignment(.center)

            GradientButton(title: "Done") {
                // Reset session to fresh state — dismiss() doesn't work in a tab
                withAnimation {
                    currentIndex = 0
                    sessionEnded = false
                    cardStatuses = []
                    sessionStartDate = .now
                    completedFully = true
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding(20)
    }
    
    // MARK: - Helpers
    private func advance() {
        guard !isLast else { return }
        withAnimation(.easeInOut(duration: 0.35)) {
            currentIndex += 1
        }
    }
    
    /// Records the user's action on the current card.
    private func recordStatus(_ status: CardStatus) {
        let promptText = prompts[currentIndex].text
        cardStatuses.append((promptText: promptText, status: status))
    }

    /// Moves to the next card or ends the session.
    private func advanceCard() {
        if currentIndex < prompts.count - 1 {
            withAnimation {
                currentIndex += 1
            }
        } else {
            // Session complete
            saveSession()
            withAnimation {
                sessionEnded = true
            }
        }
    }

    /// Saves the session + all ratings to SwiftData, then shows the complete screen.
    private func saveSession() {
        let store = DataStore(context: modelContext)
        let duration = Int(Date().timeIntervalSince(sessionStartDate))
        store.saveSession(
            category: prompts.first?.category.rawValue ?? "Prompt",
            difficulty: "easy",
            promptsShown: prompts.map(\.text),
            durationSeconds: duration,
            reactions: cardStatuses.map { (
                promptText: $0.promptText,
                category: prompts.first?.category.rawValue ?? "Prompt",
                reaction: $0.status.rawValue
            ) },
            partnerName: nil,
            completedFully: completedFully
        )
    }
    
    // Fallback if Prompt.samples is empty
    static let fallbackPrompts: [Prompt] = [
        Prompt(text: "What makes you feel most safe in our relationship?",
               highlightWords: ["safe"], category: .prompt, difficulty: .easy,
               meta: "Warm-up", whoStarts: .partnerA),
        Prompt(text: "Describe a moment you felt deeply connected to your partner.",
               highlightWords: ["deeply connected"], category: .reflect, difficulty: .light,
               meta: "Reflection", whoStarts: .partnerB),
        Prompt(text: "What boundary would you like to explore expanding?",
               highlightWords: ["boundary", "explore"], category: .explore, difficulty: .medium,
               meta: "Exploration", whoStarts: .either),
        Prompt(text: "Share a fantasy you haven't voiced yet.",
               highlightWords: ["fantasy"], category: .fantasy, difficulty: .deep,
               meta: "Deep dive", isSensitive: true, whoStarts: .partnerA),
        Prompt(text: "What does ultimate vulnerability look like for you?",
               highlightWords: ["ultimate", "vulnerability"], category: .deepDive, difficulty: .sensitive,
               meta: "Intimate", isSensitive: true, canSkip: true, whoStarts: .both)
    ]
}

#Preview {
    SessionView()
        .preferredColorScheme(.dark)
        .modelContainer(ModelContainer.previewContainer)
}

```

---

## File: `FILE_TRACKER.md` {#file-file-tracker-md}

```markdown
# Open Lightly — File Tracker

> Last updated: 2026-03-30
> ~140 Swift files across 35 directories

---

## Reach Tags

Files that touch many other files or provide cross-cutting infrastructure get a reach tag:

| Tag | Meaning |
|---|---|
| **`FOUNDATION`** | Imported or referenced by 10+ files across the codebase |
| **`BACKBONE`** | Core architectural piece — removing it breaks the app |
| **`BRIDGE`** | Connects two major subsystems (e.g. local data ↔ remote) |
| **`HUB`** | Central routing or orchestration point |

---

## `App/`

| File | What It Does | Reach |
|---|---|---|
| **`ContentView.swift`** | Root router. Gates onboarding vs. main tab bar vs. guest shell based on `@AppStorage("hasCompletedOnboarding")` and `AppState.experienceType`. | **`HUB`** |
| **`Open_LightlyApp.swift`** | `@main` entry point. Creates `AppState`, `ThemeManager`, and the SwiftData `ModelContainer`. Injects all environment objects. Gates auth (`SignInView` vs `ContentView`). Retries pending Supabase syncs on launch. | **`BACKBONE`** |

### `App/Theme/`

| File | What It Does | Reach |
|---|---|---|
| **`AppColors.swift`** | Full color palette as static `Color` constants plus a `Color(hex:)` initializer. Single source of truth for every color token in the app. **⚠️ Contains 10 unused tokens** (`purpleBright`, `electricViolet`, `cyanDark`, `deepPurple`, `surfaceRaised`, `textQuaternary`, `btnGhostBorder`, `btnGhostText`, `badgeBg`, `destructive`) — candidates for removal. | **`FOUNDATION`** |
| **`AppFonts.swift`** | Centralized font factory. Static methods for Clash Display (display/headline) and Switzer (body) at named semantic sizes (`screenTitle`, `overline`, `body`, etc.). | **`FOUNDATION`** |
| **`AppTheme.swift`** | Defines `ThemeMode` enum (system / light / amoled) and `AppPalette` — the resolved set of semantic colors for the active theme. | |
| **`ThemeManager.swift`** | `@Observable` class. Persists the user's selected theme mode to `UserDefaults` and resolves the active `AppPalette` from mode + system `colorScheme`. | |
| **`ThemeModifiers.swift`** | `ThemedRootModifier` ViewModifier. Injects the resolved `AppPalette` into the environment and sets `preferredColorScheme`. Applied once at the root via `.themedRoot()`. | |

---

## `Core/Services/`

| File | What It Does | Reach |
|---|---|---|
| **`AppState.swift`** | `@MainActor @Observable` class. Owns `experienceType` (persisted to `UserDefaults`) which drives all home-screen routing. Injected as `@Environment` at the root. | **`BACKBONE`** |
| **`Config.swift`** | Static constants for Supabase project URL and anon key. The only file with hardcoded credentials. | |
| **`SupabaseManager.swift`** | Singleton. Initializes and exposes the single `SupabaseClient` instance. All services read from `SupabaseManager.shared.client`. | **`BRIDGE`** |
| **`AuthService.swift`** | Sign in with Apple via Supabase auth. Publishes `isAuthenticated`, `userId`, `isLoading`, `error`. Uses `ObservableObject` (legacy — pre-`@Observable` migration). | |
| **`ProfileService.swift`** | Reads/writes user profile data to Supabase `profiles` table. **⚠️ Contains nested `SupabaseProfile` Codable struct** — should be extracted to `Models/` for cross-service visibility (also used by `SyncManager`). Uses `ObservableObject` (legacy). | |
| **`PairingService.swift`** | Couple pairing: generate codes, look up codes, complete pairing in Supabase. Publishes `generatedCode`, `isPairing`, `error`. Uses `ObservableObject` (legacy). | |
| **`ContentLoader.swift`** | Static generic helper that decodes bundled JSON files from the app bundle. `fatalError` on missing/malformed files (dev-time catch). | |
| **`SyncManager.swift`** | Orchestrator for local-first data writes. Pattern: save to SwiftData first, push to Supabase; if push fails, flag for retry via `UserDefaults`. Coordinates all domain sync services. | **`BRIDGE`** |
| **`AssessmentSyncService.swift`** | Pushes completed assessment data (responses + results) from SwiftData to Supabase `assessment_responses` / `assessment_results`. | |
| **`DesireSyncService.swift`** | Pushes desire map ratings from SwiftData to Supabase `desire_ratings`. Ratings are private — only used server-side for DesireMatch computation. | |
| **`SessionSyncService.swift`** | Pushes completed couple session records from SwiftData to Supabase `couple_session_records`. Syncs on completion, pause, and safe-word. | |

---

## `Data/Store/`

| File | What It Does | Reach |
|---|---|---|
| **`DataStore.swift`** | Central persistence layer. All SwiftData reads/writes go through here (`saveSession`, `fetchAllSessions`, `fetchOrCreateStreak`, etc.). Initialized with a `ModelContext`. | **`BRIDGE`** |
| **`ModelContainer.swift`** | `extension ModelContainer` that registers all `@Model` classes into the shared container. Called once from the app entry point. | |

---

## `Design/Components/`

### `Banners/`

| File | What It Does |
|---|---|
| **`GuestBannerView.swift`** | Persistent top banner for guest/browsing users. "Create an account" button resets onboarding flag to re-enter the flow. References `AppState`. |

### `Buttons/`

| File | What It Does |
|---|---|
| **`CriticalButton.swift`** | Destructive/neutral action button. `.neutral` and `.danger` styles. Themed via `\.theme` (`AppPalette`). |
| **`GradientButton.swift`** | Full-width gradient CTA button. Uses `t.buttonGradient`. Glow shadow adapts between amoled and light. **⚠️ Contains `GradBadge` component** (lines 45–59) — only used in `DesireMapView` and `ThemeTestView`; consider deprecation. |
| **`HoloCTAButton.swift`** | Primary onboarding CTA. Dark: holographic shimmer + pill border + bloom. Light: warm aurora shimmer + shadow spread. References `HolographicShimmer`, `LightModeShimmer`, `PillBorder`. **⚠️ Contains unused `CTABorderModifier`** (lines 165–176) — defined but never instantiated; consider refactoring to use it or removing. |
| **`SafeWordButton.swift`** | Always-visible safety button during sessions. Shows confirmation alert before triggering the safe-word callback. |
| **`SelectablePill.swift`** | Toggle pill for multi-select lists (onboarding pickers). Three intensity levels. Dark: holo shimmer + flame aura. Light: aurora shimmer + shadow. |

### `Cards/`

| File | What It Does |
|---|---|
| **`AtmosphericGhostDeck.swift`** | Ghost deck visual for CardRevealView. Layered cards with atmospheric blur + glow. |
| **`CategoryTileView.swift`** | Home-screen grid tile. Emoji, name, card count, and a `ProgressBar` for one category. |
| **`CircularArrowView.swift`** | Animated circular arrow indicator. Used in gesture-driven UI. |
| **`ContextCard.swift`** | Single card in the context-select stack. Gradient background + internal glow + breathing animation keyed to `ContextIntensity`. |
| **`ContextCardStack.swift`** | Gesture-driven infinite-scroll card stack. Swipe to browse, tap to confirm. Auto-advances 0.8s after selection. |
| **`ContextIntensity.swift`** | Six intensity levels (ember → nova) mapping to visual properties: gradient tint, glow size, border opacity, shadow. |
| **`ContextOption.swift`** | Plain data model for one context card. Holds `RelationshipContext`, `ContextIntensity`, title, subtitle, detail. |
| **`ConversationCard.swift`** | Rendered prompt card in sessions. Displays text with highlighted keywords, difficulty badge, category. |
| **`ConversationCardTypes.swift`** | Types and enums for conversation cards. Card styling by difficulty/type. |
| **`FuseTimerView.swift`** | Session timer display. Countdown or elapsed time with optional urgency indicators. |
| **`PromptCard.swift`** | Renders a single conversation prompt card with difficulty-keyed styling (background tint, border opacity, glow color). |
| **`SettingsCard.swift`** | Generic `<Content: View>` container. Wraps content in a padded `.cardStyle()` shell for Settings and list screens. |

### `Effects/`

| File | What It Does |
|---|---|
| **`AuroraGlowField.swift`** | Light mode atmospheric blob background. 6 blobs in magenta/purple/gold/pink at 6–9% opacity. Light mode counterpart to `OnboardingGlowField`. |
| **`FlameAura.swift`** | Flame-wisp particle effect for selected `SelectablePill`s in dark mode. Intensity-driven sizing. |
| **`GlowOrb.swift`** | Single blurred radial-gradient circle. Opacity from `t.glowOpacity`. Decorative accent. |
| **`HolographicShimmer.swift`** | Animated 3x-wide cyan→purple→magenta→pink gradient that sweeps L→R. Dark mode overlay, clipped to any shape. |
| **`LightAuraBloom.swift`** | Light mode bloom/glow effect. Aurora palette with breathing animation for atmospheric depth. |
| **`LightModeShimmer.swift`** | Light mode counterpart to `HolographicShimmer`. `AppColors.lightShimmerColors` at 7–11% opacity, 11s sweep cycle. |
| **`OnboardingGlowField.swift`** | Dark mode animated glow blob field for all onboarding screens. Self-managing animation state (7 blobs). |
| **`SparkField.swift`** | Canvas-based campfire ember particle system for light mode. Multiple screen-specific configs (`.statView`, `.nameView`, `.modeSelectView`, etc.). |

### `Input/`

| File | What It Does |
|---|---|
| **`InteractiveField.swift`** | Styled text field with emoji/icon prefix. Themed background and text color. |
| **`RatingButtonGroup.swift`** | 2x2 grid of rating buttons for the Desire Map. Bound to `DesireLevel?`. Haptic feedback. |
| **`ToggleRow.swift`** | Icon + label + Toggle row for Settings sections. |

### `Navigation/`

| File | What It Does |
|---|---|
| **`OnboardingFooter.swift`** | Small footer below the CTA ("Your data is encrypted..."). Adapts color to light/dark. |
| **`OnboardingNavBar.swift`** | Back chevron + centered `OnboardingProgressBar`. Back button gets a frosted circle in light mode. |

### `Progress/`

| File | What It Does |
|---|---|
| **`OnboardingProgressBar.swift`** | Highly refined animated progress bar for onboarding. Dual-mode (light/dark). Bloom glow, holographic shimmer fill, atmospheric gradient, breathing pulse. |
| **`OrbitIndicator.swift`** | Orbital animation progress indicator. Used in BuildingPath screen for processing animation. |
| **`ProgressBar.swift`** | Simple themed horizontal bar. `t.buttonGradient` fill on a muted track. |
| **`ProgressRingView.swift`** | Circular progress ring. Configurable line width and size. Track adapts to amoled/light. |
| **`ScoreRing.swift`** | Circular ring displaying a 0–100 score. Animates fill on appear via `t.ringGradient`. |
| **`SpectrumBar.swift`** | Thin capsule filled with `t.spectrumGradient`. Decorative separator/accent. |

### `Text/`

| File | What It Does |
|---|---|
| **`KeywordHighlightText.swift`** | Renders text with specific keywords highlighted in cyan/magenta/gold via `NSAttributedString`. Used on prompt cards. |
| **`LivingText.swift`** | Animated gradient text with breathing glow. `TimelineView` at 30fps, RTL-aware, dual-mode. The animated text identity for the app. |

### Misc Components

| File | What It Does |
|---|---|
| **`CardStyle.swift`** | `ViewModifier`. Reusable card shell: background + rounded clip + border stroke. Replaces the repetitive 3-line pattern across views. |
| **`FilamentMode.swift`** | Mode enum and utilities for filament-style animations and effects. **❌ DEAD CODE** — `FilamentMode` and `FilamentPattern` enums are never referenced anywhere. Candidate for deletion. |
| **`NavArrow.swift`** | Reusable chevron navigation arrow component. |
| **`OrbitSparkBorderView.swift`** | Decorative border with orbital spark animation. |
| **`PillBorder.swift`** | `ViewModifier`. Holographic pill border: cyan→purple→magenta gradient stroke + glow overlay. Single source of truth for dark mode selected/active borders. |
| **`ScreenshotProtectionModifier.swift`** | Listens for screenshot/screen-recording notifications and overlays a blur + "Content Protected" message. Uses UIKit notification hooks. |
| **`SectionHeader.swift`** | All-caps muted label for section dividers. `AppFonts.sectionHeader` + `AppColors.textMuted`. |

---

## `Features/`

### `Auth/`

| File | What It Does |
|---|---|
| **`SignInView.swift`** | Sign in with Apple screen. Dark background, app name + tagline, Apple sign-in button. Uses `AuthService` via `@EnvironmentObject`. |

### `Compatibility/`

| File | What It Does |
|---|---|
| **`DesireMapView.swift`** | Desire map UI. Expandable category list where users privately rate intimacy items with `DesireLevel`. **⚠️ Placeholder data** — full persistence and partner reveal flow pending implementation. |

### `Explore/`

| File | What It Does |
|---|---|
| **`ExploreView.swift`** | Content discovery hub. **❌ STUB** — renders a label only. Not yet implemented. |

### `Home/`

| File | What It Does |
|---|---|
| **`HomeView.swift`** | Thin router. Switches on `appState.experienceType` → renders matching home view variant. Zero business logic. |
| **`HomeDashboardView.swift`** | Main home dashboard. Shows categories, progress, session history, and quick-start buttons. |
| **`HomeGateView.swift`** | Gate view for home. Handles loading state and permission checks. |
| **`HomeMatchReadyView.swift`** | Couple home variant. Shows partner readiness status and synchronized session invitations. |
| **`HomeRouterView.swift`** | Advanced router for complex home navigation flows. Handles deep linking and state restoration. |
| **`HomeWaitingView.swift`** | Waiting state view for pending partner acceptance or sync. |
| **`HomeViewSingle.swift`** | Home screen for solo users with no partner. |
| **`HomeViewSolo.swift`** | Home screen for solo users who have a partner. |
| **`HomeViewCoupleNew.swift`** | Home screen for couples new to ENM. |
| **`HomeViewCoupleExp.swift`** | Home screen for couples with existing ENM experience. |
| **`PostMapReflectionView.swift`** | Post-desire-map reflection screen. Synthesis of alignment data and relationship insights. |

#### `Home/Components/`

| File | What It Does |
|---|---|
| **`DesireMapIndicator.swift`** | Visual indicator showing desire map completion status. |
| **`PartnerChip.swift`** | Compact partner profile chip for couple views. Name, status, photo. |
| **`PickUpCard.swift`** | Quick-action card to resume or start a session. |
| **`ReflectionBannerView.swift`** | Banner prompting reflection after key moments. |
| **`ReflectionCard.swift`** | Card for structured reflection prompts. |
| **`ResearchTicker.swift`** | Scrolling research insights ticker. |
| **`SessionCard.swift`** | Card summarizing a past session. Category, duration, cards discussed. |

#### `Home/Models/`

| File | What It Does |
|---|---|
| **`HomeEventEngine.swift`** | Event orchestration for home screen state transitions and notifications. |
| **`HomeModels.swift`** | Data models for home screen views. Session summaries, category tiles, partner data. |

### `MeUs/`

| File | What It Does |
|---|---|
| **`MeUsView.swift`** | Personal profile + partner connection hub. Tab label adapts ("Me" for solo, "Us · Me" for couple). **❌ STUB** — not yet implemented. |

### `More/`

| File | What It Does |
|---|---|
| **`MoreView.swift`** | Settings / account / support hub. Also the sole visible screen for guest/browsing users. **❌ STUB** — placeholder only. |

### `Onboarding/Data/`

| File | What It Does |
|---|---|
| **`OnboardingData.swift`** | The single mutable data bag threaded through the entire onboarding flow. Holds name, pronouns, mode, relationship context, curiosity selections, experience level, ground rules timestamp, and completion flag. Now includes `nmCardResponse` for CardReveal pill selection. |
| **`CuriosityScreenConfig.swift`** | Config model driving `OnboardingCuriosityPickerView`. Two sections of labels, sublabels, option arrays, visibility flags. Derived from `OnboardingData`. |

### `Onboarding/Design/`

| File | What It Does |
|---|---|
| **`OnboardingAtmosphere.swift`** | Centralized atmosphere layer for all onboarding screens. Owns glow fields, spark fields, and transitions between atmosphere configs per screen. **New in this version.** |

### `Onboarding/Layout/`

| File | What It Does |
|---|---|
| **`OnboardingLayout.swift`** | Layout constants and utilities for onboarding screens. Screen-relative measurements, spacing, animation timings. **New in this version.** |

### `Onboarding/Views/`

| File | Screen | What It Does |
|---|---|---|
| **`OnboardingFlowView.swift`** | *Coordinator* | Flow coordinator. Defines the 8-step sequence, manages transitions via `advance()` with spring animations, derives `ExperienceType` on completion, writes to `AppState`, sets `hasCompletedOnboarding`. Passes `data: $onboardingData` to CardRevealView. |
| **`OnboardingStatView.swift`** | Screen 0 | Trust trigger. Large emotional statistic with animated holographic glow + tap-to-expand citation + ethos statement before CTA. |
| **`OnboardingBrandView.swift`** | Screen 0.5 | Animated brand reveal (auto-advance). Beam widths, opacities, wisp particles, center glow. Calls `onFinished` when complete. |
| **`OnboardingNameView.swift`** | Screen 1 | Name + pronouns entry. Glass-style text field, pronoun pill selector, custom pronoun field. Three-slot entrance cascade (ANIM-STD). |
| **`OnboardingModeSelectView.swift`** | Screen 2 | Solo vs. Couple mode + NM experience level (curious / exploring / experienced). Drives remainder of flow branching. (ANIM-STD-06–12) |
| **`OnboardingContextView.swift`** | Screen 3 | Relationship context picker. Solo: 3 cards. Couple: 4 cards. Uses `ContextCardStack`. Auto-advances after selection. (ANIM-STD-13–18) |
| **`OnboardingCuriosityPickerView.swift`** | Screen 4 | Two-section interest + intent picker. Config from `OnboardingData`. Uses `SelectablePill`. (ANIM-STD-19–26) |
| **`OnboardingBuildingPathView.swift`** | Screen 6 | Non-interactive "Building your path" processing animation. Derives `defaultDifficulty` from `nmStage`. Auto-advances. (ANIM-STD-27–30) |
| **`OnboardingCardRevealView.swift`** | Screen 6.5 | Card reveal with tap-to-flip mechanic. User flips card to reveal bridge prompt + 4 selectable pills. Idle animations (pulse, wiggle, skip text). Stores pill selection to `data.nmCardResponse`. Accepts `@Binding var data: OnboardingData`. |
| **`OnboardingGroundRulesView.swift`** | Screen 7 | Must-acknowledge ethical framing. 3 promise cards with flip animations + reassurance text. No back, no skip. Writes acceptance timestamp + completion flags, then calls `onFinished`. (ANIM-STD-31–36) |
| **`PairingForkView.swift`** | *(Couple fork)* | Couple-only decision: "Pair Now" (inline pairing) or "Pair Later" (skip to Settings). No data saving — closures only. |

---

## `Models/`

### `Models/Enums/`

| File | What It Does | Reach |
|---|---|---|
| **`AppEnums.swift`** | Master enum file. All shared domain enums: `CardType`, `Difficulty`, `Sensitivity`, `TurnOrder`, `CategoryType`, `CategoryPhase`, `AssessmentDomain`, `DesireLevel`, `DesireAlignment`, `RelationshipContext`, `ExplorationMode`, `NMStage`, `PronounOption`, `RelationshipStatus`, `NMFlavor`, `CardStatus`, `PromptCategory`, `PromptDifficulty`, `WhoStarts`. | **`FOUNDATION`** |
| **`AppTab.swift`** | Four tab cases: `home`, `meUs`, `explore`, `more`. `Hashable` for `TabView` selection. | |
| **`ExperienceType.swift`** | Five experience modes: `browsing`, `soloSingle`, `soloPartnered`, `coupleNew`, `coupleExperienced`. Drives all home-screen routing. `CaseIterable`, `Codable`. | **`BACKBONE`** |

### `Models/Content/` *(read-only, decoded from bundled JSON)*

| File | What It Does |
|---|---|
| **`ContentAssessmentQuestion.swift`** | One of 20 assessment questions (5 domains x 4). Types: scale (1–5 Likert) or multi-select. Answers live in `AssessmentResponse`, not here. |
| **`ContentCard.swift`** | Read-only content model for a conversation card within a category. Per-card progress tracked separately in `CardProgress`. |
| **`ContentCategory.swift`** | One of the 6 topic categories. Progress tracking lives in SwiftData, not here. |
| **`ContentDesireItem.swift`** | One item on the Desire Map. "Not For Me" ratings are never revealed to partners — alignment engine returns `.boundary`. |
| **`Prompt.swift`** | Prompt card model for `SessionView`. Text, highlight words, category, difficulty, sensitivity flags, `canSkip`, `whoStarts`. Includes static sample data. |

### `Models/Persistence/` *(SwiftData `@Model` classes — local-first)*

| File | What It Does |
|---|---|
| **`RatingRecord.swift`** | One record per prompt shown in a session. Owned by `SessionRecord` via cascade. Stores prompt text, reaction, timestamp. |
| **`SessionRecord.swift`** | One row per completed or safe-worded session. Category, difficulty, duration, prompts shown, completion flag, date. |
| **`StreakRecord.swift`** | Singleton record. Tracks `currentStreak`, `longestStreak`, `totalSessions`, `lastSessionDate`. Updated by `DataStore`. |

### `Models/Progress/` *(SwiftData `@Model` classes — synced to Supabase)*

| File | What It Does |
|---|---|
| **`AssessmentResponse.swift`** | One user's answer to one assessment question. Scale value or selected option IDs, computed score, timestamp. Owned by `UserProfile`. |
| **`AssessmentResult.swift`** | Overall assessment result. Per-domain scores (string-keyed dict), composite weighted score, readiness band. Owned by `UserProfile`. |
| **`CardProgress.swift`** | Couple-level per-card progress: discussed/skipped/bookmarked, timestamps, notes. Owned by `Couple` via cascade. |
| **`Couple.swift`** | Links two `UserProfile`s as partners. Owns `CardProgress` + `CoupleSessionRecord` via cascade. Deleting a `Couple` does NOT delete the profiles. |
| **`CoupleSessionRecord.swift`** | One couple session record. Cards discussed/skipped, timing, metadata. Owned by `Couple`. |
| **`DesireMatch.swift`** | Positive desire alignment between two partners on a specific item. Only created when alignment is positive. Owned by `Couple`. |
| **`DesireRating.swift`** | One person's private rating of one desire map item. Never exposed to partner — used only to compute `DesireMatch`. Owned by `UserProfile`. |
| **`UserProfile.swift`** | Full user profile. Name, pronouns, orientation, mode, experience level, `NMFlavor`, curiosity selections. Owns `AssessmentResponse`, `AssessmentResult`, `DesireRating` collections. |

---

## File Count by Directory

| Directory | Files |
|---|---|
| `App/` | 2 |
| `App/Theme/` | 5 |
| `Core/Services/` | 11 |
| `Data/Store/` | 2 |
| `Design/Components/` | ~47 |
| `Design/Components/Banners/` | 1 |
| `Design/Components/Buttons/` | 5 |
| `Design/Components/Cards/` | 13 |
| `Design/Components/Effects/` | 9 |
| `Design/Components/Input/` | 3 |
| `Design/Components/Navigation/` | 2 |
| `Design/Components/Progress/` | 6 |
| `Design/Components/Text/` | 2 |
| `Design/Components/Misc/` | 7 |
| `Features/Auth/` | 1 |
| `Features/Compatibility/` | 1 |
| `Features/Explore/` | 1 |
| `Features/Home/` | 10 |
| `Features/Home/Components/` | 7 |
| `Features/Home/Models/` | 2 |
| `Features/MeUs/` | 1 |
| `Features/More/` | 1 |
| `Features/Onboarding/` | ~20 |
| `Features/Onboarding/Data/` | 2 |
| `Features/Onboarding/Design/` | 1 |
| `Features/Onboarding/Layout/` | 1 |
| `Features/Onboarding/Views/` | 11 |
| `Features/Progress/` | 1 |
| `Features/Sessions/` | 1 |
| `Features/Settings/` | 3 |
| `Models/Content/` | 5 |
| `Models/Enums/` | 3 |
| `Models/Persistence/` | 3 |
| `Models/Progress/` | 8 |
| `Resources/` | 1 (Documentation) |
| **Total** | **~140** |

*Note: Count reflects consolidation from old `Card/` to `Cards/` (plural) directory in this redesign cycle. Some components may be nested across multiple files.*

---

## Recent Changes (This Session)

- **OnboardingFlowView.swift**: Restored to clean ANIM-STD state; pass `data: $onboardingData` to CardRevealView (cardReveal case line 135)
- **OnboardingCardRevealView.swift**: Accepts `@Binding var data: OnboardingData`; EncouragementView body simplified to single Text
- **OnboardingBuildingPathView.swift**: Fixed BPFloatingFragment scope (moved from nested in BPOrbitCanvas to top-level private struct)
- **OnboardingGroundRulesView.swift**: Removed baseBackground/glowOverlay/sparkOverlay; background now uses Color.clear + atmosphereLayer; previews wrapped in ZStack with AppColors background + OnboardingAtmosphere
- **File reorganization**: Moved Cards from `Design/Components/Card/` to `Design/Components/Cards/` (note plural); deleted old `Card/` directory

---

## Dead Code & Maintenance Inventory

### 🚨 Critical Issues

| Item | File | Details | Impact |
|---|---|---|---|
| **Exposed API Keys** | `Config.swift:2-3` | Supabase URL + anon key hardcoded in source code (committed to git). Should be in xcconfig or environment. | **SECURITY**: Credentials visible in version control. |
| **SessionView God Object** | `Features/Sessions/SessionView.swift:4-50` | Manages session state, UI presentation, timing, card advancement, progress tracking, and persistence all in one view. 50+ lines of logic. | **MAINTAINABILITY**: Hard to test, difficult to extend, state changes scattered. |
| **UserDefaults Key Inconsistency** | `SyncManager.swift` vs `AppState.swift` | SyncManager uses hardcoded strings (`"supabaseProfileId"`, `"pendingProfileSync"`); AppState uses `PersistenceKey` enum. No shared key management. | **MAINTAINABILITY**: Inconsistent patterns, key duplication, hard to refactor. |
| **ContentLoader.swift Fatal Error** | `Core/Services/ContentLoader.swift` | Uses `fatalError` on JSON parse failure. A typo in bundled JSON crashes the app in production. | **RELIABILITY**: No graceful fallback; bundle errors are unrecoverable. |

### 🗑️ Dead Code to Remove

| Item | File | Lines | Action |
|---|---|---|---|
| **FilamentMode** | `FilamentMode.swift` | Entire file | No references. Delete. |
| **10 Unused Colors** | `AppColors.swift` | 10 tokens | `purpleBright`, `electricViolet`, `cyanDark`, `deepPurple`, `surfaceRaised`, `textQuaternary`, `btnGhostBorder`, `btnGhostText`, `badgeBg`, `destructive` — remove. |

### ⚠️ Code Quality Issues

| Item | File | Action |
|---|---|---|
| **Nested SupabaseProfile** | `ProfileService.swift` | Extract to `Models/ProfileService/SupabaseProfile.swift` for cross-service visibility. |
| **Unused CTABorderModifier** | `HoloCTAButton.swift:165-176` | Either refactor to use it or remove. |
| **Limited GradBadge Usage** | `GradientButton.swift:45-59` | Used only in 2 files (`DesireMapView`, `ThemeTestView`). Deprecate or move to test utilities. |
| **Duplicate Header Comments** | `SyncManager.swift`, `ProfileService.swift` | Both files have header comment blocks appearing twice. Remove the duplicates. |

### 🔧 Magic Numbers & Missing Constants

| Item | Files Affected | Fix |
|---|---|---|
| **Animation Durations** | ContextCard, ConversationCard, ContextCardStack, SessionView (7+ instances) | Extract to `Animation.cardTransition` and similar constants. |
| **Corner Radius `20`** | ContextCard, ConversationCard, SessionView, CardStyle (4+ instances) | Define `DesignTokens.cardCornerRadius = 20`. |
| **Padding `28`** | ContextCard, ConversationCard (3+ instances) | Define `DesignTokens.cardPadding = 28`. |
| **Light Mode Shadow Spread** | ContextCard:157-159, SelectablePill:334-339 | Extract to `.lightGlowShadows()` modifier. |
| **Dark/Light Border Logic** | SelectablePill, ContextCard, HoloCTAButton | Create `ThemedBorderModifier`. |
| **Blob Timing Arrays** | `AuroraGlowField.swift:270-273` | Extract to named `BlobTimingConfig` struct. |

### 📊 Naming Issues

| Item | File | Fix |
|---|---|---|
| **Boolean Naming** | `UserProfile.swift:39-40` | `mythBusterComplete` → `hasMythBusterCompleted`; `mythBusterSkipped` → `isMythBusterSkipped`. |
| **Vague Parameters** | `ContextCard.swift:7-8` | `index: Int` → `cardIndex: Int`; `total: Int` → `totalCards: Int`. |
| **Single-Letter Theme Var** | `ProgressRingView`, `ContextCard` | `@Environment(\.theme) private var t` → use `palette`. |
| **Abbreviated NM** | `AppEnums.swift` | Document or standardize `nmLogistics` / `NM` usage. |

---

## Key Architectural Notes

- **Onboarding Atmosphere**: Centralized in `OnboardingAtmosphere.swift` (Design/) for all screens; config-driven per-screen transitions
- **Home Expansion**: Home directory grew significantly with `HomeDashboardView`, component library, and event engine for complex state management
- **Card System Consolidation**: New unified card rendering system in `Design/Components/Cards/` for both conversation and context cards
- **ANIM-STD Protocol**: All onboarding screens now use standardized entrance animations (three-slot cascade: slot A @ 0ms, slot B @ 100ms, slot C @ 200ms) with reduce-motion fallback
- **Desire Map Architecture**: Still using private-first model; `DesireRating` never exposed to partners; alignment computed server-side via `DesireMatch`

---

## Design System Gaps (Missing Constants)

The codebase lacks centralized constants for spacing, sizing, and animations. These are currently scattered as magic numbers:

| Category | Current State | Recommended Constant |
|---|---|---|
| **Card Corner Radius** | `20` hardcoded in 4+ files | `DesignTokens.cardCornerRadius = 20` |
| **Card Padding** | `28` hardcoded in 3+ files | `DesignTokens.cardPadding = 28` |
| **Button Height** | Explicit in `HoloCTAButton` (56), implicit/padding-based in others | `DesignTokens.buttonHeight = 56` |
| **Line Width (borders)** | 1.5–3.0 depending on context | `DesignTokens.borderStandard = 1.5`, `.strong = 2.5`, `.cta = 3.0` |
| **Card Transition Duration** | 0.25–0.4s scattered across files | `Animation.cardTransition` constant |
| **Spring Animation** | `spring(response: 0.4, dampingFraction: 0.75/0.7)` used 7+ times | `Animation.cardSpring`, `Animation.pillSpring` |
| **Light Mode Shadows** | Triple-shadow block (magenta/purple/gold) copied in 2 files | `.lightGlowShadows()` ViewModifier |
| **Dark/Light Border Logic** | Conditional repeated in 3+ files | `ThemedBorderModifier` struct |

**Action**: Create a `DesignTokens` enum (or split into `Spacing`, `Sizing`, `Animation`) to centralize these values.

```

---

## File: `PROJECT_SCOPE.md` {#file-project-scope-md}

```markdown
# Open Lightly — Project Scope
**Last Updated:** March 28, 2026 (file structure audit, onboarding standardization, CardRevealView implementation)
**Developer:** Bryan Jorden
**Platform:** iOS 26 (SwiftUI, SwiftData, Supabase)

---

## 1. What Is Open Lightly

Open Lightly is a privacy-first iOS app built for couples navigating the gap between "we're curious about non-monogamy" and "we've had the conversations and know where we stand." At launch, it is a focused tool for one thing done extremely well: helping new NM couples have the conversations they've been putting off.

**Launch identity — Act 1:**
> *"The tool couples have been looking for since the first conversation they couldn't finish."*

The core product: guided conversation card decks and a mutual Desire Map reveal. Both partners complete the Desire Map independently; one matched item surfaces free; the full compatibility picture is behind the paywall. That moment — *your first glimpse of what you actually have in common* — is the conversion event.

**Core premise:** Conversations that would be awkward to start become natural when framed as a game.

**What this app is NOT:** See Section 4 — Moral Red Line.

### The Three-Act Reveal

This is not a pivot sequence. It is a reveal sequence. The product expands in a way that feels inevitable to users rather than scattered.

| Act | When | Who | Tagline |
|-----|------|-----|---------|
| **Act 1** | Launch | New NM couples | *"The tool couples have been looking for since the first conversation they couldn't finish."* |
| **Act 2** | V1.1 | Experienced ENM practitioners | *"For people doing non-monogamy intentionally."* |
| **Act 3** | V1.2+ | Solo explorers | *"For people who take relationships seriously. All kinds of relationships."* |

The Act 3 tagline is the destination. Every architecture decision now should allow the product to arrive there without a rewrite. The architecture supports all three user types from day one — what changes at each act is the marketing focus, not the codebase.

### How It Works

```
PAIR    → QR scan (in person), verbal code (same room), or share link (remote)
ASSESS  → Each partner privately answers 20 questions
REVEAL  → Sit together, see combined Readiness Score
EXPLORE → Work through guided conversation cards by category
MAP     → Privately rate 40+ intimacy items — one match revealed free, full reveal behind paywall
DECIDE  → Informed decision based on mutual understanding
```

Over time, logged check-ins, reflections, and emotional data compound into a personal relationship intelligence layer — the app gets more valuable the longer someone uses it.

---

## 2. Target Users — Three Acts, One Architecture

Open Lightly serves all four relationship populations from day one. The architecture supports everyone; the marketing reveal is sequential. Each act has a primary user, a pain point, and a clear build priority.

### Act 1 — Primary User at Launch: The New NM Couple

**Who:** Two people in a committed relationship, curious about ENM, haven't fully navigated the conversation yet. Usually one partner initiated. Ages 25–40.

**Primary pain:** "We tried to talk about it and it went sideways. We don't know how to start without it feeling like an accusation."

**What they need:** Structure that makes hard conversations feel like a game, not a fight. A mutual reveal that gives both partners a safe way to say what they want without having to say it directly first.

**Build priority:** Build for them first. Market to them exclusively at launch. Every Act 1 decision is a front-door decision.

### Act 2 — Secondary User (Present at Launch, Not Marketed): The Experienced ENM Practitioner

**Who:** Couples actively practicing ENM — swinging, polyamory, relationship anarchy, any flavor. They know the landscape. They're downloading because a friend recommended it or they saw a review.

**Primary pain:** "We've been doing this for years with no operational infrastructure. We've built our own systems from scratch, most of which are informal and inconsistent."

**What they discover:** Daily pulse, jealousy mapping, agreements vault, connection cards. The "aha" is: *this isn't just for people figuring it out — it's for people living it.*

**Build priority:** Tools present in architecture and discoverable. Not marketed until V1.1 Act 2 expansion.

### Act 3 — Secondary User (Routing Exists, Not Marketed): The Solo Explorer

**Who:** Singles, solo poly people, people navigating ENM without a primary partner. They belong here — they've always belonged here. The product now explicitly invites them.

**Primary pain:** "Every ENM resource assumes I have a partner to do this work with. I'm doing it alone."

**What they discover:** The app was never about having a partner. It was always about doing the work of non-monogamy intentionally. Solo users were always going to belong here.

**Build priority:** Solo path fully routed in architecture. Not marketed at launch. Front-door marketing shift happens at V1.2.

### Persona Tags (internal, never shown to user)

Each person must feel like the app was built for them specifically. The persona filter (set at onboarding via `nmStage`) routes them to a personalized roadmap, tailored prompt voice, and curated education — all from one shared content library.

### Persona Tags (internal, never shown to user)

| Selection | Tag | App Experience |
|-----------|-----|---------------|
| Solo + Curious | `solo-curious` | Self-discovery → preparation → "How to find & start an NM relationship" |
| Solo + Experienced | `solo-experienced` | Self-maintenance → advanced tools → community navigation |
| Coupled + Curious | `coupled-curious` | Graduated exposure roadmap → first experiences |
| Coupled + Experienced | `coupled-experienced` | Communication tune-ups → advanced scenarios → repair tools |

### Tone Shift Between Populations

| Element | Curious Tone | Experienced Tone |
|---------|-------------|-----------------|
| Vocabulary | Plain language, define everything | Community language, no hand-holding |
| Pacing | Slow, gentle, "it's okay" | Direct, efficient, respects their time |
| Assumed knowledge | Zero | Full |
| Emotional register | Warm, reassuring, validating | Honest, challenging, growth-oriented |
| Prompt complexity | One question at a time | Multi-layered, asks for nuance |
| Example | "What's one thing about NM that excites you? Just one." | "What pattern keeps showing up that you haven't fully addressed?" |

If a curious user sees experienced content → overwhelmed, unready. If an experienced user sees curious content → patronized, deletes the app. **The persona filter is the difference between "this app gets me" and "this app isn't for me."**

### Solo ↔ Coupled Transition

When a solo user finds a partner:
- Solo journal entries are NEVER shared (privacy is sacred)
- Shared journey starts fresh
- Solo stages completed inform where the coupled roadmap begins (skip already-done self-work)

---

## 3. The Problem We Solve


The #1 problem isn't jealousy. It's that people don't know how to START. The gap between curiosity and first conversation is where most NM journeys die.

### The 9 Pain Points (in customer journey order)

| # | Problem | Who | Urgency | What They'd Pay |
|---|---------|-----|---------|-----------------|
| 1 | "I can't even start the conversation" | Solo curious | Critical | $30–60 |
| 2 | "We tried to talk about it and it went badly" | Coupled curious | Critical | $40–60 |
| 3 | "I don't know what I actually want" | All curious | High | $25–40 |
| 4 | "We can't set boundaries that work" | Coupled (all stages) | Critical | $40–60 |
| 5 | "Jealousy is eating me alive" | All practitioners | Critical | $25–50 |
| 6 | "Something went wrong — crisis" | Coupled, active | Critical | $50+ |
| 7 | "I can't find a therapist who gets this" | Everyone | High | $40–60 |
| 8 | "I don't know anyone else who does this" | Everyone, esp. new | Moderate | $20–30 |
| 9 | "We've been doing this for years and we're stuck" | Experienced | Moderate | $40–60 |

### Why Existing Solutions Fail

- **Books/podcasts** — Information overload, consumed solo, no partner involvement
- **Reddit** — Contradictory crowd-sourced advice, no structure
- **Therapy** — $150–300/session, 2–6 week waitlists, most therapists aren't NM-informed and some actively pathologize it
- **"Just be honest"** — Radical honesty without structure = emotional flooding
- **Winging it** — How boundary violations happen. Not because people are bad, but because they never agreed on where the lines were.

### What the Market Actually Wants

1. **Structure over information** — They're drowning in content. They need a PROCESS for turning it into conversations.
2. **Partner involvement** — Every resource is single-player. NM is a two-person journey. Mutual reveal mechanics are the product-market fit.
3. **Normalization over pathologization** — They don't want clinical language. They want to feel like this is a legitimate, navigable life choice.
4. **Accessibility over expertise** — 70% of what a good NM therapist provides, available tonight, for the price of a book.
5. **Privacy over community** — Most NM-curious people want a PRIVATE space to figure this out first.

---

## 3.5. V1.0 Feature Set

Features are organized by act ownership. Act 1 features are front-door — marketed, prioritized, and polished first. Act 2 features ship at V1.0 but are discovered, not marketed. Act 3 features ship in architecture and routing only at V1.0; marketing focus shifts at V1.2.

### The Desire Map: Primary Conversion Architecture

The Desire Map mutual reveal is not a feature gate. It is the revenue mechanic.

1. **Both partners complete the Desire Map independently** — 17 items, ~4.5 minutes, fully private. Neither sees the other's ratings.
2. **One matched item is revealed free** — the instant personalized result. The first glimpse of what they actually agree on creates the demand the paywall fulfills.
3. **Full mutual reveal unlocked at paywall** — the complete compatibility picture is the product. The free match is the proof it works.

This is "instant personalized result → paywall on that result." The mechanic works because the result is real, immediate, and deeply personal. It cannot be replicated by any other app because it requires both partners to have already completed the assessment.

### Feature Matrix

| Feature | Act | V1.0 Ships | Notes |
|---------|-----|-----------|-------|
| Onboarding flow — all three paths | 1/2/3 | ✅ | All routes present; Act 1 path marketed at launch |
| Conversation card decks (Coupled Curious) | 1 | ✅ | Core product, front-door |
| Desire Map — 17 items, mutual private rating | 1 | ✅ | Primary conversion moment |
| Desire Map — 1 free match reveal | 1 | ✅ | Free tier hook |
| Desire Map — full reveal | 1 | ✅ | Behind paywall |
| Readiness Assessment | 1 | ✅ | Front-door |
| Partner pairing (QR, code, link) | 1 | ✅ | Front-door |
| CardReveal screen (replaces solo reflection gate) | 1/2/3 | ✅ | Universal — every user sees this. Pill selection feeds archetype routing. Scraps the separate post-onboarding reflection gate entirely. |
| Graduated exposure roadmap (Coupled Curious) | 1 | ✅ | Front-door |
| Home dashboard + Today view | 1 | ✅ | Front-door |
| Safe word (always accessible) | 1 | ✅ | Front-door |
| Screenshot protection | 1 | ✅ | Front-door |
| Drop Box — AI message translation (100 msgs) | 1 | ✅ | Communication Pack |
| Coupled Experienced roadmap | 2 | ✅ | Present, not marketed at launch |
| Advanced scenario cards | 2 | ✅ | Present, not marketed at launch |
| Agreement foundation prompts | 2 | ✅ | Present, not marketed at launch |
| Solo Curious roadmap | 3 | ✅ | Architecture present, not marketed |
| Solo Experienced roadmap | 3 | ✅ | Architecture present, not marketed |
| Bridge cards (solo user with partner) | 3 | ✅ | Architecture present, not marketed |
| Connection Cards / Partner Roster | 2 | V1.1 | Infrastructure for pulse, vault, check-ins |
| Daily Relationship Pulse | 2 | V1.1 | 30-second daily habit; data compounds retention |
| Insight Engine — pattern surfacing | 2 | V1.1 | Needs logged data to work |
| Emotional Texture Calendar | 2 | V1.1 | Needs pulse data |
| Jealousy Mapping | 2 | V1.2 | Dedicated in-the-moment tool |
| Agreements Vault | 2 | V1.2 | Requires connection roster first |
| Anonymous Community Feed | 2/3 | V1.5 | Moderation cost too high pre-scale |
| Your Year, Lightly | 2/3 | V2.0 | Needs 6+ months of active logged data |

---

## 4. Moral Red Line

**This app is not therapy. This is non-negotiable.**

Open Lightly is a communication tool and an educational resource. It facilitates structured conversations between partners. It provides research-backed frameworks for exploring difficult topics. It does NOT diagnose, treat, or replace professional mental health care.

As a future therapist building this product: no dollar is worth an ethical violation. The moment this app crosses from "guided conversation tool" into "therapy substitute," it causes harm — to users who deserve real clinical care, and to the credibility of the therapeutic profession.

### What This Means in Practice

**The app WILL:**
- Frame itself as a conversation tool, not a clinician
- Surface crisis resources (988, Crisis Text Line, National DV Hotline) when language suggests distress
- Include "Find a Therapist" resources with NM-informed directories
- State on Ground Rules screen: "We're not a therapist. If things get heavy, we'll point you to people who can help."
- Position AI features as communication SKILLS education, never clinical interpretation

**The app will NEVER:**
- Diagnose relationship patterns ("this is stonewalling," "this is anxious attachment")
- Use clinical terminology in user-facing output (no Gottman labels, no attachment framework language)
- Label emotions ("you sounded angry")
- Attribute blame ("you interrupted 7 times")
- Compare partners ("Partner A communicates better than Partner B")
- Provide unsolicited feedback on communication quality
- Frame NM as something that needs to be "fixed" or "managed"
- Replace the recommendation to seek professional help when situations exceed the app's scope

> **New features boundary:** Jealousy Mapping logs feelings, not diagnoses. Compersion Tracker celebrates moments, not prescribes them. The Insight Engine surfaces observations ("You tend to feel X after Y"), never evaluations ("Your jealousy is getting worse"). Pattern data is a mirror. The user draws their own conclusions.

### The Line Between Education and Therapy

| Education (we do this) | Therapy (we never do this) |
|------------------------|---------------------------|
| "Here's another way to express that" | "You're using criticism, a predictor of divorce" |
| "Many couples find it helpful to..." | "Based on your pattern, you should..." |
| "Research suggests that direct requests..." | "Your communication style indicates..." |
| Offer alternative phrasings, user chooses | Prescribe interventions |
| Cite communication principles | Apply clinical frameworks to user behavior |

### The Three Rules

**Rule 1: Facilitate, Never Diagnose**
- Wrong: "Based on your responses, you have an anxious attachment style."
- Right: "You mentioned feeling worried when your partner is distant. What does that worry need?"
- The first is a clinical judgment. The second is a mirror. The user draws their own conclusion.

**Rule 2: Open Doors, Never Push Through Them**
- Wrong: "It's important that you confront your jealousy. Let's work through it."
- Right: "Jealousy showed up. Want to explore what it's telling you? [Yes] [Not tonight]"
- A therapist can push — they have informed consent, a treatment plan, malpractice insurance. We have none of those. The app offers the door. The user decides.

**Rule 3: Credit the User, Not the Tool**
- Wrong: "Our evidence-based approach helped you identify your core needs."
- Right: "You just named something important."
- The app showed up with the right question at the right time. The user did the work.

### Language Guide

| Therapeutic language (avoid) | Companion language (use) |
|------------------------------|--------------------------|
| "Your assessment indicates..." | "You mentioned..." |
| "Let's work on..." | "Want to explore..." |
| "This exercise will help you..." | "Some people find it useful to..." |
| "You should discuss this with your partner" | "If this feels worth sharing, you'll know when" |
| "Processing your trauma" | "Sitting with what came up" |
| "Treatment plan" | "Your path" |
| "Session goals" | "Tonight's intention" |

### The Bar Conversation Test

Every card should pass this: Could a really wise, well-read friend say this to you over a drink without it feeling clinical?
- ✅ "What's one thing you want that you haven't said out loud yet?"
- ❌ "Identify an unmet relational need and articulate it to your partner."
- ✅ "When jealousy shows up, where do you feel it in your body?"
- ❌ "Describe the somatic manifestation of your jealousy response."

Same insight. Same evidence base. Completely different relationship with the user.

### Using Clinical Frameworks Without Crossing the Line

The app draws on Gottman, attachment theory, CBT, NVC, EFT, and motivational interviewing. The difference is framing:

| Framework | What a therapist does | What this app does |
|-----------|----------------------|-------------------|
| Gottman's Four Horsemen | Diagnoses communication dysfunction, assigns treatment plan | Card: "Notice when you're criticizing vs. complaining. What's the difference feel like?" |
| Attachment theory | Assesses attachment style, restructures interaction patterns | Reflection: "When your partner pulls away, what's the first thing you feel?" |
| CBT restructuring | Identifies and challenges distorted thought patterns | Card: "The story I'm telling myself about this is ___. What's another version?" |
| EFT | Guides couples through de-escalation cycles | Prompt sequence: surface reaction → underlying emotion → need → request |
| Motivational interviewing | Strategic questioning to move through stages of change | Card phrasing mirrors MI — open questions, affirmations, reflective framing |
| Expressive writing (Pennebaker) | Prescribed journaling for trauma processing | Free-text reflection with "Only you see this" |

Same intellectual DNA. Completely different claim.

### Where the Line Gets Tested

| Scenario | What therapy does | What this app does |
|----------|------------------|-------------------|
| Suicidal ideation in a reflection | Clinician assesses risk, activates safety protocol | Surface crisis resources immediately. Don't try to help. Route to professionals. |
| Partner describes abuse | Clinician reports, creates safety plan | Surface DV hotline. Don't counsel. Don't notify the partner. |
| User in distress after a session | Clinician de-escalates, extends session | "That was heavy. You don't have to carry this alone." + therapist finder + grounding exercise |
| Couple in active conflict during session | Therapist mediates | Card design avoids inflammatory prompts at low depth levels. The depth slider is the safety valve. |

**The rule: when it gets clinical, get out of the way and point to clinicians.** The app handles the 95% of moments where two curious people want a better conversation. The 5% where real crisis shows up is not our jurisdiction.

### Crisis Detection

Keyword-based detection (not ML). If solo reflection or session text contains crisis language:
- Surface resources immediately (988, Crisis Text Line, National DV Hotline)
- Non-blocking — resources shown, user continues at their discretion
- Always accessible in Settings → Get Support
- False positives are acceptable. Missing someone who needs help is not.

### The Philosophical Frame

This app is closer to a **really good book of questions** than it is to therapy. Think Esther Perel's card games, The School of Life conversation cards, the 36 Questions to Fall in Love. All draw on deep psychological research. None are therapy.

- A **book of questions** assumes two capable adults who want to grow.
- **Therapy** assumes something is broken and someone trained needs to help fix it.

This app assumes the first. It says: "You're not broken. You're exploring. Here are better questions than the ones you've been asking yourselves."

### Positioning

> "We're not therapy. We're what you use when you can't find a therapist who gets it — or between sessions with one who does."

### Legal Disclaimer (accessible but not obnoxious)

> "[App name] is a conversation companion, not a therapist. It's informed by relationship science and designed to help you explore — but it's not a substitute for professional support. If you're in crisis or experiencing abuse, please reach out to [resources]."

Present in: App Store listing, Settings → About, Onboarding Ground Rules. One line. Not a wall of legal text.

---

## 5. AI Ethics & Communication Coaching

### Guiding Principle

> "We don't tell you what you said wrong. We show you other ways you could say what you meant."

### AI Can / Cannot

✅ **AI CAN:**
- Identify linguistic patterns (you-statements, absolutes, questions vs. statements)
- Offer alternative phrasings (not interpretations)
- Show speaking time balance
- Highlight questions asked (encourages curiosity)
- Note moments of agreement/alignment
- Translate messages in the Drop Box (anonymous, non-judgmental rephrasing)

❌ **AI CANNOT:**
- Label emotions ("you sounded angry")
- Attribute blame ("you interrupted 7 times")
- Diagnose patterns ("this is stonewalling")
- Apply clinical frameworks in output
- Provide unsolicited feedback
- Show one partner's analysis without the other present
- Train on users' private conversations

### AI Implementation Levels

| Level | What It Actually Is | Difficulty | Cost | When |
|-------|-------------------|-----------|------|------|
| **1. System Prompt** | GPT-4o/Claude with a detailed role prompt + user context injection (assessment data, desire map, session history). Not retrained — role-playing well. | Easy | ~$20/mo API | Launch (Drop Box) |
| **2. RAG** | Source material (NM books, NVC, Gottman research, your content) chunked into embeddings, stored in vector DB. User question → semantic search → relevant chunks injected as context → grounded response. | Medium | ~$50–100/mo | Month 4–6 (AI Coach) |
| **3. Fine-Tuning** | Retrain a model on hundreds of example conversations in your voice/tone. Learns your specific framing. | Medium-Hard | $500–2K training | Month 12+ (if enough data) |
| **4. From Scratch** | Don't. OpenAI and Anthropic spent the billions. Stand on their shoulders. | — | — | Never |

**RAG tech stack:**

| Component | Tool | Cost |
|-----------|------|------|
| LLM | OpenAI GPT-4o or Claude | ~$0.01–0.05/turn |
| Vector DB | Supabase pgvector (already in stack) | Free tier |
| Embedding | OpenAI text-embedding-3-small | Pennies |
| Orchestration | LangChain or LlamaIndex | Free (open source) |

**AI Coach feature map:**

| Feature | What It Does |
|---------|-------------|
| Ask the Coach | Freeform chat for questions that don't fit prompts. Context-aware via assessment + desire map data. |
| Jealousy First Aid | Real-time CBT reframing: identify thought → examine evidence → find distortion → reframe → action plan. Personalized to their archetype, attachment signals, and agreements. |
| Post-Conversation Processing | "We just had a hard conversation. Help us make sense of it." |
| Scenario Expansion | After a hypothetical, "What if [variation]?" — AI generates new angles dynamically. |
| Assessment Interpreter | "What does our score actually mean for [specific situation]?" |
| Drop Box Translation | Anonymous AI rephrasing: say what you mean without the loaded language. |

**AI implementation phases:**

| Phase | When | What | Method |
|-------|------|------|--------|
| Launch | Day 1 | Drop Box (100 AI translations) | Level 1 — system prompt |
| Month 4–6 | AI Coach v1 | Ask the Coach + Jealousy First Aid | Level 1 with context injection |
| Month 7–9 | AI Coach v2 | RAG upgrade — responses grounded in curated NM content | Level 2 |
| Month 12+ | Voice refinement | Fine-tune on anonymized Drop Box patterns | Level 3 (if data exists) |

### Communication Coaching Models (Late Feature — Batch 24+)

| Model | What It Is | When |
|-------|-----------|------|
| **Pattern Library** | Browsable library of common communication patterns with research-backed alternatives. No recording, no surveillance. Users self-identify. | Batch 24–26 |
| **Post-Conversation Replay** | Couple opts in to record a session. Together, they tap any line to see alternative phrasings. No judgment on which is "better." | Batch 29+ |
| **Hybrid Analysis** | Linguistic structure analysis (not emotional/clinical). Alternatives sourced from NVC, Gottman soft startup research, active listening frameworks. | Batch 30+ |

### Consent Architecture (for recording features)

- Opt-in PER SESSION (not global)
- BOTH partners must consent (double opt-in)
- Either partner can delete at any time
- On-device processing or E2E encrypted
- Clear disclosure before recording begins

### Transparency

Public documentation of:
1. What we analyze (linguistic structure, speaking balance, conversational flow)
2. What we don't analyze (emotional tone, who's "right," clinical categories)
3. Where alternatives come from (NVC, Gottman published research, active listening frameworks)
4. Every suggestion has a "This doesn't fit" button
5. Model never trains on private conversations

---

## 6. Psychology & Emotional Design

### Shame Reduction Architecture

Every design decision passes through: "Does this reduce shame or increase it?"

- **Onboarding stat screen** ("1 in 5 Americans") — normalizes before asking anything personal
- **"No judgment on any answer"** — explicit on relationship status screen (the partnered_hidden option carries shame)
- **Skip is always real** — no guilt copy, no "Are you sure?", no re-prompting
- **Jealousy is data, not failure** — reframed as information about unmet needs, not proof something is wrong
- **Every outcome is valid** — including "We explored this and decided it's not for us"

### Desire Map Assessment — Core 17 Items

The Desire Map is a mutual-reveal compatibility tool. Both partners rate 17 items independently; results are compared only when both complete. The 17 items cover all 7 of Moors' (2024) clinical assessment dimensions for CNM couples.

| # | Item | Category | Sensitivity | Source |
|---|------|----------|-------------|--------|
| 1 | Opening Our Relationship | Structure | 1 | Conley 2017 |
| 2 | Swinging or Playing Together | Structure | 1 | Rubel & Bogaert 2015 |
| 3 | Dating Separately | Structure | 2 | Moors 2017 |
| 4 | Polyamory — Loving More Than One | Structure | 2 | Fern 2020, Haupert 2017 |
| 5 | Our Relationship Comes First | Structure | 2 | Fern 2020 (hierarchy) |
| 6 | Emotional Connections With Others | Emotional | 2 | Mogilski 2017 |
| 7 | New Relationship Energy (NRE) | Emotional | 2 | Easton & Hardy 2017 |
| 8 | Your Partner Falling in Love | Emotional | 3 | Conley 2017 |
| 9 | Group Sexual Experiences | Sexual | 2 | Lehmiller 2018 |
| 10 | Safer Sex Boundaries | Health | 1 | Moors 2024, Fern 2020 |
| 11 | Overnight Stays With Others | Logistics | 2 | Sheff 2014 |
| 12 | Time and Attention | Logistics | 2 | Moors 2024, Mogilski 2017 |
| 13 | Veto Power | Logistics | 2 | Easton & Hardy 2017 |
| 14 | Full Disclosure — Knowing Everything | Communication | 2 | Mogilski 2017, Deri 2015 |
| 15 | Meeting Your Partner's Other Connections | Communication | 1 | Sheff 2014 |
| 16 | Who Knows About Us | Social | 1 | Sheff 2014, PMC 2025 |
| 17 | Handling Jealousy Together | Emotional | 2 | Veh et al. 2025 |

**Why 17, not 15:** The 3 clinically-mandated additions (safer sex, hierarchy, social disclosure) can't replace existing items without creating a gap. 17 items × 15 seconds = ~4.5 minutes. Under the 5-minute threshold.

**Clinical coverage:**

| Moors (2024) Dimension | Items |
|------------------------|-------|
| Structural agreement | 1–4 |
| Emotional boundaries | 5–8 |
| Sexual health agreements | 10 |
| Disclosure preferences | 14 |
| Time management | 11–12 |
| Social identity management | 16 |
| Conflict resolution style | 17 |

**Key clinical insights informing the design:**
- **Gottman:** ~70% of couple problems are perpetual. The Desire Map doesn't solve disagreements — it identifies which are perpetual (need ongoing dialogue) vs. solvable. That reframe shapes item descriptions.
- **Fern (2020):** Hierarchy is the most common unspoken assumption. Partners who disagree on #5 build their CNM structure on a fault line.
- **Sheff (2014):** Closeting stress is the #1 predictor of long-term CNM burnout. Partners often disagree sharply on outness (#16).
- **Veh et al. (2025):** Jealousy management is the strongest predictor of CNM satisfaction. Item #17 is the only item measuring a PROCESS (how you deal with feelings) vs. a PREFERENCE (what you want).

### Archetype System (Post-Reflection Classification)

Solo reflection text is embedded and compared against 8 archetype centroids:

| Archetype | Signals | Content Path |
|-----------|---------|-------------|
| The Curious | "wondering," "thinking about it" | Foundational, exploratory |
| The Anxious | "scared," "worried about losing" | Reassurance-first, attachment-focused |
| The Wanting | "desire," "something missing" | Desire exploration, permission-giving |
| The Going-Along | "partner wants," "they asked me" | Autonomy-focused |
| The Processing | "jealousy," "struggling" | Emotional processing tools |
| The Stuck | "been doing this but," "not working" | Advanced mechanics, renegotiation |
| The Communicator | "don't know how to talk about" | Communication frameworks |
| The Builder | "rules," "structure," "boundaries" | Practical tools, agreements |

Classification is **invisible infrastructure**. The system tags a user as `anxious` internally for content routing. The user never sees that label. They see cards that happen to address their experience. The user experience is just: "Wow, this app gets me." Use the science to build the engine. Let the user experience feel like wisdom, not treatment.

### Emotional Pacing

- Onboarding screens 1–7: logistics (setup energy)
- Screen 8 (Ground Rules): ethical frame (trust energy)
- Screen 9 (Priming): emotional threshold — everything after is personal
- Solo Reflection: first vulnerable moment — earns the right to personalize

### Ground Rules Resurfacing

| Moment | What Appears |
|--------|-------------|
| First couples session | "No scorecards. This is exploration, not evaluation." |
| Cards touching conflict | Footer: "This isn't about right or wrong." |
| Post-session checkout | "How did that feel? (Just for you — your partner sees their own.)" |
| Settings → About | Full ground rules + crisis resources |
| 14+ days inactive | No guilt. At most: "Still here when you're ready." |

---

## 7. Marketing & Positioning

### Core Positioning

Don't sell "an NM app." Sell the solution to specific pain points. The app is ONE product. The marketing speaks to NINE different moments of pain.

### Pain-Point Marketing Hooks

| Hook | Problem It Targets |
|------|-------------------|
| "How to bring up non-monogamy without your partner thinking you want to cheat" | #1 — Can't start |
| "Your first NM conversation went badly. Here's what to do next." | #2 — Went badly |
| "Swinging? Polyamory? Open? How to figure out what YOU actually want" | #3 — Don't know what I want |
| "The boundary-setting conversation most NM couples skip (and regret)" | #4 — Boundaries |
| "What to do when jealousy hits and 'just sit with it' isn't working" | #5 — Jealousy |
| "It's 11pm and your partner's date ran late. Here's how to handle tonight." | #6 — Crisis |
| "When your therapist doesn't get non-monogamy" | #7 — Therapist gap |
| "You're not the only couple figuring this out" | #8 — Isolation |
| "Been doing NM for years? When's the last time you audited your agreements?" | #9 — Experienced but stuck |

### Price Psychology

- **$14.99 Core** = less than a physical card deck ($25–45), less than one therapy session, less than dinner out
- **$34.99 Complete** = the "I'm all in" option — feels like buying a book, not renting access
- **$6.99/mo AI Coach** = less than one coffee/week, justified by real per-message API costs
- Expansion packs feel earned — couples hit them naturally as they progress

### Buyer Journey

```
$0 (Free) → "Let me just see what this is"
  ↓ Assessment blows their mind
$14.99 (Core) → "This is actually good, $15 is nothing"
  ↓ Complete Phase 1, feel momentum
+$9.99 (Communication) → "I NEED the Drop Box — I can't say this out loud"
  ↓ Hit message limit, want more
$6.99/mo (AI Coach) → "Unlimited Drop Box + a coach? For $7/mo? Yes."
  ↓ Using insights, reports, coaching regularly
Total: ~$35 one-time + $7/mo for active AI features
```

### Revenue Projections (Conservative)

| Timeframe | Downloads | Free→Core (15%) | Core→Bundle (30%) | AI Coach (10% of paid) | Monthly Revenue |
|-----------|-----------|-----------------|-------------------|----------------------|----------------|
| Month 3 | 3,000 | 450 | 135 | — | ~$9,900 (one-time) |
| Month 6 | 8,000 | 1,200 | 360 | 120 | ~$26,400 + $839/mo |
| Month 12 | 20,000 | 3,000 | 900 | 300 | ~$72,000 + $2,100/mo |

---

## 8. Design System

### Colors — `AppColors`

| Token | Hex | Usage |
|-------|-----|-------|
| `cyan` | #00C2FF | Primary accent, cool spectrum |
| `purple` | #6C3AE0 | Mid-spectrum, transitions |
| `magenta` | #FF006A | Emotion accent, hot spectrum |
| `pink` | #FF2D8A | Shimmer gradients |
| `deepBlue` | #0078FF | Atmospheric floor washes |
| `gold` | #C8960A | Safety ONLY (safe word, warnings) |
| `pageBg` | #030305 | Page backgrounds |
| `cardBg` / `card` | #050507 | Card interiors |
| `surfaceBg` | #08080C | Elevated surfaces |
| `textPrimary` | #E8E8F0 | Headings, prompt text |
| `textSecondary` | #AAAABC | Labels, descriptions |
| `textTertiary` | #666680 | Timestamps, meta |
| `border` | white @ 6% | Subtle card borders |
| `spectrumGradient` | cyan→purple→magenta | Hot border, prompt cards |

### Typography — `AppFonts`

All tokens use two factory functions: `display(size, weight:)` (Clash Display) and `body(size, weight:)` (Switzer).

| Token | Font | Size |
|-------|------|------|
| `heroTitle` | Clash Display Bold | 42 |
| `cardTitle` | Clash Display Semibold | 22 |
| `screenTitle` | Clash Display Semibold | 24 |
| `bodyText` | Switzer Regular | 16 |
| `bodyMedium` | Switzer Medium | 15 |
| `caption` | Switzer Regular | 13 |
| `ctaLabel` | Switzer Semibold | 16 |
| `buttonLabel` | Switzer Semibold | 14 |

### Shared Modifiers

| Modifier | What it does |
|----------|-------------|
| `.cardStyle()` | `background + clipShape(RoundedRectangle) + border stroke` |
| `.pillBorder()` | Neon gradient stroke (cyan→purple→magenta) with blur + shadow layers |
| `.screenshotProtected()` | Prevents screenshots on sensitive content |

### Design Rules

1. **Color is earned** — Gradient only on interactive/prompt cards. Static UI uses muted surfaces.
2. **Gold = safety only** — Never decorative. Safe word, warnings, exit actions.
3. **Hot border = prompt cards only** — Spectrum gradient stroke reserved for PromptCard.
4. **Zero hardcoded values** — All colors via `AppColors`, all fonts via `AppFonts`.

---

## 9. Architecture

### Tab Architecture

The Roadmap is the spine. Tab layout adapts based on persona:

```
Coupled:  Home  |  Roadmap  |  Us ∞    |  You
Solo:     Home  |  Roadmap  |  Journal ✦  |  You
```

| Tab | Coupled Users | Solo Users |
|-----|--------------|------------|
| **Home** | Tonight's check-in, roadmap position, quick play | Same |
| **Roadmap** | Visual journey map. Current stage expanded with Deck + Learn + Pre/Post. All stages browsable (not locked). | Same structure, different roadmap |
| **Us / Journal** | Mutual reveals, session history, partner roadmap progress, saved cards | Private reflections, personal growth timeline, bookmarked prompts, "Questions to ask a future partner" |
| **You** | Profile, settings, safe word config, pairing | Same (minus pairing) |

Learn/Education lives inside each Roadmap stage AND as a browsable section under a "More" area.

### Tech Stack

| Layer | Technology | Notes |
|-------|-----------|-------|
| UI | SwiftUI (iOS 26) | |
| Persistence | SwiftData | Local-first — all session data stays on device |
| Architecture | MVVM | `@Observable`, `@AppStorage`, `@Environment` |
| Backend | Supabase (Free tier) | Postgres, Realtime, Edge Functions, RLS, Auth |
| Auth | Sign in with Apple → Supabase Auth | |
| Purchases | StoreKit 2 | |
| Security | CryptoKit (encryption), Keychain (tokens/keys), LocalAuthentication (biometrics) | |
| Fonts | Clash Display (headings), Switzer (body), Zodiak + GeneralSans (brand) | |
| External deps | Supabase Swift SDK (only external dependency) | |

**Supabase tier: Free ($0/mo)**
- 50,000 monthly active users included
- 500 MB database
- Unlimited API requests
- Upgrade to Pro ($25/mo) only when exceeding 50K MAU

### Project Structure (130 files, 32 directories)

```
App/
  Open_LightlyApp.swift        — Entry point, auth gate, SwiftData container
  ContentView.swift             — Root router: onboarding vs. tabbed app
  Theme/
    AppColors.swift             — Single source of truth for all colors
    AppFonts.swift              — Font factory functions + semantic tokens
    AppTheme.swift              — ThemeMode enum, AppPalette (light/dark/AMOLED)
    ThemeManager.swift          — Observable theme state
    ThemeModifiers.swift        — .themedRoot() modifier

Features/
  Auth/
    SignInView.swift
  Home/
    HomeView.swift              — Router: routes per experienceType
    HomeDashboardView.swift     — Main home dashboard with categories & progress
    HomeGateView.swift          — Loading & permission gate
    HomeMatchReadyView.swift    — Couple-specific home variant
    HomeRouterView.swift        — Advanced routing for complex flows
    HomeWaitingView.swift       — Pending partner acceptance state
    HomeViewSingle.swift        — Solo user (no partner)
    HomeViewSolo.swift          — Solo user (with partner)
    HomeViewCoupleNew.swift     — Couple (new to ENM)
    HomeViewCoupleExp.swift     — Couple (experienced)
    PostMapReflectionView.swift — Post-desire-map reflection
    Components/                 — PartnerChip, PickUpCard, ReflectionBannerView, SessionCard, etc.
    Models/                     — HomeEventEngine, HomeModels
  Sessions/
    SessionView.swift
  Compatibility/
    DesireMapView.swift
  Progress/
    ProgressDashboardView.swift
  Settings/
    SettingsView.swift
    ThemePickerView.swift
    ThemeTestView.swift
  MeUs/
    MeUsView.swift
  More/
    MoreView.swift
  Explore/
    ExploreView.swift
  Onboarding/
    OnboardingFlowView.swift    — Coordinator / screen sequencer (ANIM-STD, spring animations)
    Design/
      OnboardingAtmosphere.swift — Centralized atmosphere layer for all screens
    Layout/
      OnboardingLayout.swift     — Layout constants & screen-relative measurements
    Data/
      OnboardingData.swift       — Central data model (includes nmCardResponse for CardReveal)
      CuriosityScreenConfig.swift — Config for CuriosityPickerView
    Views/
      OnboardingStatView.swift, OnboardingBrandView.swift, OnboardingNameView.swift,
      OnboardingModeSelectView.swift, OnboardingContextView.swift, OnboardingCuriosityPickerView.swift,
      OnboardingBuildingPathView.swift, OnboardingCardRevealView.swift, OnboardingGroundRulesView.swift,
      PairingForkView.swift

Design/Components/
  Buttons/                    — GradientButton, HoloCTAButton, CriticalButton, SafeWordButton, SelectablePill
  Cards/                      — PromptCard, SettingsCard, CategoryTileView, ContextCard, ConversationCard,
                              — AtmosphericGhostDeck, CircularArrowView, ContextCardStack, FuseTimerView
  Effects/                    — HolographicShimmer, OnboardingGlowField, SparkField, GlowOrb,
                              — AuroraGlowField, LightAuraBloom, LightModeShimmer, FlameAura
  Input/                      — InteractiveField, RatingButtonGroup, ToggleRow
  Navigation/                 — OnboardingNavBar, OnboardingFooter
  Progress/                   — OnboardingProgressBar, ProgressBar, ProgressRingView, ScoreRing,
                              — SpectrumBar, OrbitIndicator
  Text/                       — LivingText, KeywordHighlightText
  Misc Components/            — CardStyle.swift, PillBorder.swift, ScreenshotProtectionModifier.swift,
                              — SectionHeader.swift, NavArrow.swift, OrbitSparkBorderView.swift, FilamentMode.swift

Core/Services/
  AppState.swift              — Experienceype routing state (@Observable)
  AuthService.swift           — Sign in with Apple + Supabase session
  SupabaseManager.swift       — Shared Supabase client
  SyncManager.swift           — Retry pending syncs on launch
  ContentLoader.swift         — JSON prompt loading
  Config.swift                — API keys, environment config
  ProfileService.swift        — User profile CRUD
  PairingService.swift        — Couple pairing codes + Realtime
  SessionSyncService.swift    — Session data sync
  AssessmentSyncService.swift — Assessment results sync
  DesireSyncService.swift     — Desire map ratings sync

Data/Store/
  DataStore.swift             — Central persistence layer
  ModelContainer.swift        — SwiftData container config

Models/
  Content/                    — ContentCard, ContentCategory, ContentAssessmentQuestion,
                              — ContentDesireItem, Prompt
  Enums/
    AppEnums.swift            — All shared domain enums (CardType, Difficulty, RelationshipContext, etc.)
    AppTab.swift              — Tab routing enum
    ExperienceType.swift      — Experience routing (browsing, soloSingle, soloPartnered, coupleNew, coupleExperienced)
  Persistence/                — SessionRecord, RatingRecord, StreakRecord (local-first)
  Progress/                   — UserProfile, AssessmentResult, Couple, DesireMatch, CoupleSessionRecord,
                              — CardProgress, DesireRating, AssessmentResponse (synced to Supabase)
```

---

## 10. Onboarding Flow (v2.0)

**Goal:** App Store download → first meaningful moment in 60–90 seconds (Solo/Couple) or 45–60 seconds (Browsing).

**Design principles:**
- Trust before ask: normalization (Stats) before data collection
- Progressive disclosure: simple asks first, deeper questions after investment
- Breathing room: auto-advance screens provide mental breaks
- Self-honesty before partner performance: Solo Reflection happens first, even for couples
- Clear value exchange: user understands why each question matters
- No dead ends: every path leads to value

### Screen Sequence (9 screens)

| # | Screen | File | Type | Data Collected | Purpose |
|---|--------|------|------|---------------|---------|
| 1 | StatView | `OnboardingStatView.swift` | Interactive | None | "1 in 5" stat — normalize, reduce shame |
| 2 | BrandView | `OnboardingBrandView.swift` | Auto (3.5s) | None | Brand identity — mental break before first ask |
| 3 | NameView | `OnboardingNameView.swift` | Form | `displayName`, `gender` | Personalization seed, lowest-stakes first ask |
| 4 | ModeSelectView | `OnboardingModeSelectView.swift` | Two-stage | `explorationMode`, `nmStage` | Primary branch: Solo / Couple / Just Browsing |
| 5 | ContextView | `OnboardingContextView.swift` | Card stack | `relationshipContext` | Relationship situation — **skipped for Browsing** |
| 6 | CuriosityPickerView | `OnboardingCuriosityPickerView.swift` | Multi-select | `curiositySelections`, `communicationGoals`, `learningGoals` | Interest + intent picker — drives content personalization |
| 7 | CardRevealView | `OnboardingCardRevealView.swift` | Tap-to-flip card | `nmCardResponse` | **The reflective moment.** Replaces the old standalone solo reflection gate. Universal — every path. Front: open question the user sits with. Back: four pills (A desire / A fear / A boundary / A truth). Pill selection feeds archetype routing invisibly. Skip stores nil. |
| 8 | BuildingPathView | `OnboardingBuildingPathView.swift` | Auto (~7.5s) | Derives `defaultDifficulty` from `nmStage` | **Arrival ceremony — not processing animation.** Responds directly to CardReveal data. Four orbit rows including `nmCardResponse`. Exit line: "Jordan, you're in." Copy: "YOUR PATH IS READY." |
| 9 | GroundRulesView | `OnboardingGroundRulesView.swift` | Must-acknowledge, ScrollView | `groundRulesAcceptedAt`, `onboardingComplete`, `completedAt` | Ethical frame — what this is and isn't. Home renders blurred and non-interactive behind this screen. User sees destination before final acknowledgment. Blur animates to zero BEFORE `hasCompletedOnboarding` fires. No back button. |

**Then:**
```
→ HOME DASHBOARD (direct)
```

**NOTE: The Solo Reflection gate has been scrapped. Its function is
fully absorbed by the CardReveal screen (step 7), which poses the
reflective open question universally within the onboarding flow itself.
Post-onboarding, all paths land directly on the home dashboard with
no intermediate gate.**

### Path Variations

| Path | Screens | Notes |
|------|---------|-------|
| **Solo** | All 9 | ContextView shows 3 relationship-context cards. CardReveal is universal. |
| **Couple** | All 9 | ContextView shows 4 relationship-context cards. CardReveal is universal. Pairing deferred to Settings. |
| **Just Browsing** | 8 (skips ContextView) | CardReveal universal. Education tab unlocked; sessions locked until upgrade. |

**Note on screen count:** The count increases by 1 from the previous spec
because CardReveal has moved from step 7.5 (a half-step) to step 7 (a full
step), with BuildingPath at step 8 and GroundRules at step 9. The total
user experience duration is unchanged — BuildingPath and CardReveal existed
before, they have simply been reordered and reframed.

### Act-Ownership Routing Logic

The onboarding routing is intentional and permanent — not a placeholder to be replaced, but the architecture that enables the three-act reveal sequence. No onboarding screens change between acts; only the marketing focus shifts.

| Onboarding Selection | Act | Marketing Status at Launch |
|---------------------|-----|---------------------------|
| Coupled + Curious (`nmStage`: curious / exploring) | **Act 1** | Marketed — primary front-door path |
| Coupled + Experienced (`nmStage`: experienced) | **Act 2** | Present, not marketed — experienced tools surface first; these users discover the operational infrastructure organically |
| Solo (any `nmStage`) | **Act 3** | In architecture, not marketed — full routing present; excluded from launch marketing; front-door shift at V1.2 |

When Act 2 marketing begins at V1.1, experienced users have always had a complete path. When Act 3 marketing begins at V1.2, solo users have always had a complete path. The routing is the strategy encoded in code.

**CardReveal routing note:** nmCardResponse is available to BuildingPath
because CardReveal now precedes it in the flow. BuildingPath reads this
value to populate its fourth orbit row. The archetype classification that
previously happened post-solo-reflection now happens at the same point —
during BuildingPath's animation window, which provides sufficient processing
time before the user reaches GroundRules.

### User Modes

```swift
enum UserMode: String, Codable {
    case solo      // Self-discovery, partner optional
    case couple    // Joint exploration, paired via code
    case browsing  // Learn first, no sessions yet
}
```

### Experience Levels (collected in ModeSelectView, stage 2)

Defined in `AppEnums.swift` as part of `NMStage`:

```swift
enum NMStage: String, Codable, CaseIterable {
    case curious     // Brand new → defaultDifficulty: "warm"
    case exploring   // Some context → defaultDifficulty: "medium"
    case experienced // Knows what they want → defaultDifficulty: "hot"
}
```

This was consolidated from the old standalone `ExperienceLevel.swift` into `AppEnums.swift` for unified enum management.

### Relationship Context Options (ContextView)

**Solo (3 cards):**
| ID | Title | Intensity |
|----|-------|-----------|
| `single` | "I'm single" | ember |
| `partneredOpen` | "I have a partner (they know)" | spark |
| `partneredHidden` | "It's complicated" | blaze |

**Couple (4 cards):**
| ID | Title | Intensity |
|----|-------|-----------|
| `notTalked` | "Haven't really talked about it" | ember |
| `talking` | "We've been talking" | flame |
| `someExperience` | "We've tried some things" | inferno |
| `needsReset` | "We need a reset" | nova |

### Curiosity Categories (CuriosityPickerView, multi-select)

- Communication & Dirty Talk
- Sensation & Touch
- Power Dynamics
- Fantasy & Role Play
- Trust & Vulnerability
- Romance & Connection
- Adventure & Novelty
- Bondage & Restraint
- Not sure yet — surprise me *(mutually exclusive with all others)*

### Navigation Logic

```swift
// Implemented in OnboardingFlowView.swift as advance(to:)
// All transitions: .spring(response: 0.35, dampingFraction: 0.8), .opacity.combined(with: .scale(0.95))
// (ANIM-STD-37: advance() spring, ANIM-STD-38: screen transitions)

enum OnboardingStep: Int, CaseIterable {
    case stat, brand, name, modeSelect, contextSelect, curiosityPicker, cardReveal, buildingPath, groundRules
}
// NOTE: cardReveal precedes buildingPath intentionally.
// CardReveal is the reflective moment — nmCardResponse feeds directly
// into BuildingPath's fourth orbit row and exit copy.
// BuildingPath is the arrival ceremony, not a processing screen.

func advance(to step: OnboardingStep) {
    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
        currentStep = step
    }
}

// Main navigation flow:
switch currentStep {
    case .stat:             advance(to: .brand)
    case .brand:            advance(to: .name)           // auto-advance at 3.5s
    case .name:             advance(to: .modeSelect)
    case .modeSelect:
        // Browsing skips context — goes directly to curiosity picker
        advance(to: explorationMode == .browsing ? .curiosityPicker : .contextSelect)
    case .contextSelect:    advance(to: .curiosityPicker)
    case .curiosityPicker:  advance(to: .cardReveal)
    case .cardReveal:
        // User taps to flip & select pill (or skip)
        // Stores data.nmCardResponse (String? — nil if skip)
        // Encouragement typewriter completes → advance
        advance(to: .buildingPath)
    case .buildingPath:     advance(to: .groundRules)    // auto-advance at ~7.5s
    case .groundRules:
        // Must-acknowledge; no back button
        // Writes: groundRulesAcceptedAt, onboardingComplete, completedAt
        // Then calls onFinished → coordinator marks onboarding done → HOME
        onFinished?()
}

func goBack() {
    // .stat, .brand — no back (brand already played)
    switch currentStep {
    case .name:            advance(to: .modeSelect)   // back goes forward to avoid re-playing brand
    case .modeSelect:      advance(to: .name)
    case .contextSelect:   advance(to: .modeSelect)
    case .curiosityPicker:
        // Browsing went modeSelect → curiosity, so back goes to modeSelect
        advance(to: explorationMode == .browsing ? .modeSelect : .contextSelect)
    // NOTE: cardReveal, buildingPath, groundRules — no back button
    // cardReveal: first vulnerable moment, no return
    // buildingPath: auto-advance terminal, no back
    // groundRules: terminal screen, no back
    default: break
    }
}
```

### Data Model

```swift
struct OnboardingData {
    // Screen 3 — NameView
    var displayName: String = ""
    var pronouns: [PronounOption] = []

    // Screen 4 — ModeSelectView
    var explorationMode: ExplorationMode?  // solo / couple / browsing (from AppEnums)
    var nmStage: NMStage?                  // curious / exploring / experienced (from AppEnums)

    // Screen 5 — ContextView (Solo/Couple only)
    var relationshipContext: RelationshipContext?  // from AppEnums

    // Screen 6 — CuriosityPickerView
    var curiositySelections: [String] = []
    var communicationGoals: [String] = []
    var learningGoals: [String] = []

    // Screen 7 — CardRevealView
    // Pill selection for archetype routing; nil when user skips.
    // This IS the solo reflection moment — no separate gate exists.
    var nmCardResponse: String? = nil

    // Screen 8 — BuildingPathView (auto-advance)
    // Derived from nmStage. BuildingPath reads nmCardResponse to
    // populate its fourth orbit row and personalise exit copy.
    var defaultDifficulty: String {
        switch nmStage {
        case .curious:     return "warm"
        case .exploring:   return "medium"
        case .experienced: return "hot"
        default:           return "warm"
        }
    }

    // Completion (Screen 9 — GroundRulesView)
    var groundRulesAcceptedAt: Date?
    var onboardingComplete: Bool = false
    var completedAt: Date?
}
```

**Notes:**
- `nmCardResponse` is stored but used primarily for internal archetype classification
- `nil` when user skips CardReveal (skip button or close); archetype routing uses fallback
- Data defined in `Features/Onboarding/Data/OnboardingData.swift`
- Threaded as `@Binding var data: OnboardingData` through all onboarding screens

### Partner Pairing (Couple Mode — deferred to Settings)

Pairing is no longer a mandatory onboarding screen. Couple users complete their own onboarding individually, then pair via Settings. This removes the blocking dependency on a partner being present at signup time.

Three pairing methods remain available in Settings:
| Method | When | How |
|--------|------|-----|
| **QR Code** | Same room | Partner A shows QR → Partner B scans |
| **Verbal Code** | Same room, different device | Format: `WORD + 2-digit number` (e.g. "SPARK 42") |
| **Share Link** | Remote | iMessage/text deep link |

---

### Solo Reflection — Absorbed Into CardReveal

The standalone post-onboarding solo reflection gate has been scrapped.
Its function is fully absorbed by the CardReveal screen (step 7 in the
onboarding flow).

**What changed:**
- `SoloReflectionEntry` model is no longer needed — remove if present
- No post-onboarding gate on first HOME visit
- All paths land directly on home dashboard after GroundRules acknowledges
- The reflective question ("What would you desire if nobody, not even you,
  would judge the answer?") is posed universally during onboarding
- `nmCardResponse` stores the pill selection and drives archetype routing
- Skip behavior identical: nil stored, archetype routing uses fallback,
  seed is still planted (user read the question even if they didn't answer)

**Why this is better:**
The old gate created a friction point at the home threshold — users who
just completed 8 onboarding screens hit another reflective prompt before
seeing the app. CardReveal poses the same quality of question at the
correct moment in the emotional arc (immediately before BuildingPath
confirms what was built from it) rather than as a post-hoc gate.

---

## 11. Content Structure & Roadmaps

### The Roadmap is the Spine

The Roadmap is the primary navigation — a visual journey map (not a checklist, not a progress bar). Each persona gets a different roadmap. Each stage has three layers:

| Layer | What It Is |
|-------|-----------|
| **Conversation Deck** | 8–12 prompts specific to this stage |
| **Education Module** | Curated resources (books, podcasts, Reddit threads, videos) contextual to this stage |
| **Pre/Post Processing** | Before: "What are we hoping to feel? What are we afraid of?" / After: "What actually happened? What surprised us?" |

### Coupled Curious Roadmap — Graduated Exposure

This is **systematic desensitization** (Wolpe, 1958) applied to NM exploration. Each step increases only ONE variable (observation → participation → emotional → physical → autonomy). Each step has a natural pause-and-process point. Regression is expected and normalized.

| Stage | Anxiety | What It Tests | Clinical Parallel |
|-------|:---:|---------------|-------------------|
| 1. Curiosity | 1/10 | Can we even have this conversation? | Psychoeducation / imaginal exposure |
| 2. Fantasy Together | 2/10 | Can we be sexual while acknowledging others exist? | Imaginal exposure |
| 3. Observation | 3/10 | Can we be in a sexually charged environment together? | In-vivo exposure (observation) |
| 4. Mild Participation | 4/10 | Can I see my partner receiving attention from someone else? | In-vivo exposure (mild) |
| 5. Controlled Experience | 5/10 | Can we involve a third party in a boundaried way? | In-vivo exposure (controlled) |
| 6. Emotional Connection | 5/10 | Can we handle emotional attention from others? | In-vivo (emotional domain) |
| 7. Low-Stakes Dating | 6/10 | Can we handle our partner on a date? | In-vivo (social/romantic) |
| 8. Raising Stakes | 7/10 | Can we handle escalation? | Graded exposure |
| 9. Full Experience | 8–9/10 | The real thing, together or separately | Full exposure (with safety) |
| 10. Autonomy | 10/10 | Maximum trust | Full autonomy |

**Framing: descriptive, not prescriptive.** "Many couples find that starting with low-stakes observation helps them gauge comfort" — NOT "You should start with strip clubs." No required order. A guide, not a gate. You can stop anywhere. Every stage is an arrival, not a waypoint.

**Evidence basis:** No peer-reviewed research on this exact sequence for swinging. But the underlying framework is massively validated: graduated exposure (Wolpe 1958), processing with partner improves outcomes (Gottman, Johnson), psychoeducation before novel experiences reduces negative outcomes (health psych), autonomy at each step predicts satisfaction (Deci & Ryan + Moors et al.), emotional regulation improves with practice (Gross 2015).

### Solo Curious Roadmap

| Stage | Focus |
|-------|-------|
| 1. Understand Yourself | What do I want? What am I afraid of? What does commitment mean to me? |
| 2. Learn the Landscape | NM styles, structures, terminology. What resonates? |
| 3. Process Your Feelings | Internalized monogamy, shame, fear. What stories am I telling myself? |
| 4. Prepare to Date | Profiles, disclosure timing, vetting NM partners |
| 5. Build Your World | Community, support, who do I tell? How? |
| 6. Start Dating | First conversations, first dates, processing what comes up |
| 7. Navigate Your First NM Relationship | Communication, boundaries, NRE — "It's real now" |

### Coupled Experienced Roadmap

| Stage | Focus |
|-------|-------|
| 1. State of the Union | How are WE doing? Honest check-in. What's working? What's friction? |
| 2. Agreement Audit | Review every rule and boundary. "Does this still serve us or just protect us?" |
| 3. Unfinished Conversations | Things you've been avoiding. Resentments, unspoken desires, fears. |
| 4. Advanced Scenarios | NRE management, unequal situations, evolving structures |
| 5. Repair Shop | When trust was damaged. Specific incident processing framework. |
| 6. What's Next | Deeper exploration, new structures. "Where do we want to be in a year?" |

### Solo Experienced Roadmap

| Stage | Focus |
|-------|-------|
| 1. Check In With Yourself | Where am I? What patterns keep showing up? |
| 2. Sharpen Your Tools | Communication upgrade, boundary audit |
| 3. Go Deeper | Attachment patterns in NM, jealousy triggers, compersion cultivation |
| 4. Navigate Complexity | Multiple relationships, time, energy, hinge skills, metamour dynamics |
| 5. Handle Hard Stuff | Breakups, transitions, restructuring, repair |
| 6. Sustain & Thrive | Long-term NM wellness, preventing burnout, maintaining joy |

### Content Ratio: Shared vs. Unique

Not four apps — one content library with four paths:

| Content Type | Shared | Unique per path |
|-------------|--------|-----------------|
| Education library (books, podcasts, links) | 80% | 20% path-specific curation |
| Glossary (~50 terms) | 100% | Highlights terms relevant to current stage |
| Conversation prompts | 30% (reframed per persona) | 70% unique |
| Roadmap stages | 0% | 100% unique journeys |
| Pre/Post processing | 40% shared framework | 60% unique prompts |
| Emotional tools (jealousy, NRE) | 50% shared concepts | 50% unique prompts |

**Same topic, four framings (example — jealousy card):**

| Persona | How the card reads |
|---------|-------------------|
| Solo Curious | "When you imagine a future partner being with someone else, what comes up? Sit with that feeling." |
| Solo Experienced | "Think about the last time jealousy showed up. What was the trigger underneath the trigger?" |
| Coupled Curious | "Read this to each other: 'When I imagine you being with someone else, I feel ____.' Just listen." |
| Coupled Experienced | "When was the last time jealousy surprised you — a situation where you thought you'd be fine but weren't?" |

### Content Volume Estimate

| Path | Unique prompts | Shared (reframed) | Total |
|------|---------------|-------------------|-------|
| Solo Curious | ~80 | ~40 | ~120 |
| Solo Experienced | ~70 | ~40 | ~110 |
| Coupled Curious | ~90 | ~40 | ~130 |
| Coupled Experienced | ~75 | ~40 | ~115 |
| **Total** | **~315 unique** | **~40 × 4 = 160** | **~475 prompt variations** |

### Launch Content Priority

**Phase 1 (Launch):** Solo Curious + Coupled Curious = ~295 prompts + glossary + curated education

**Phase 2 (Month 2–3):** Add Experienced paths = ~145 additional prompts

**Phase 3 (Month 4+):** Style-specific roadmaps (polyamory, relationship anarchy, kink+NM intersection)

### Prompt Phases (purchase tiers)

| Phase | Content | Tier |
|-------|---------|------|
| 0 | Relationship Strengthening | Core |
| 1 | Foundation Conversations (40+ prompts) | Free (3) + Core |
| 2 | NM Education Modules | Education Pack |
| 3 | Hypothetical Scenarios | Scenarios Pack |
| 4 | After First Experience | Scenarios Pack |

### Prompt Model

| Property | Type | Description |
|----------|------|-------------|
| `text` | String | The prompt question |
| `highlightWords` | [String] | Keywords highlighted via GradientText |
| `category` | PromptCategory | .prompt, .reflect, .ultimate, etc. |
| `difficulty` | PromptDifficulty | .easy → .ultimate (6 levels) |
| `isSensitive` | Bool | Triggers screenshot protection |
| `canSkip` | Bool | Whether user can skip |
| `whoStarts` | WhoStarts | .partnerA, .partnerB, .both |

### Education Library

Attached to each roadmap stage (contextual, not standalone). Also browsable as a top-level section.

```
LEARN
├── ⭐ Recommended for You (3–4 based on persona + current stage)
├── 📚 Books (curated per persona — same library, different "Start Here")
├── 🎙️ Podcasts (We Gotta Thing, Normalizing NM, Room 77, Front Porch Swingers)
├── 📺 Videos (curated playlist)
├── 💬 Communities (Reddit, lifestyle sites, local finding guide)
├── 📋 Glossary (universal — highlights terms relevant to current stage)
└── 🧭 Where Do I Start? (different entry point per persona)
```

Resources are curated, not created. The app doesn't write textbooks — it organizes the best existing resources and surfaces them at the moment they're needed.

---

## 12. Revenue Model

### Primary Conversion Architecture — The Desire Map Paywall

> **This is not a feature gate. This is the business model.**

The Desire Map mutual reveal is the primary revenue mechanic at launch. The structure:

1. **Both partners complete the Desire Map free** — 17 items, ~4.5 minutes, fully private.
2. **One matched item is revealed free** — both partners see one thing they agree on. This is the "instant personalized result" that creates the demand.
3. **Full mutual reveal unlocked at paywall** — the complete compatibility picture is the product being purchased.

The free match reveal is the hook. It proves the product works before asking for money. It is personally relevant, immediately gratifying, and impossible to replicate without completing the assessment — which means any user who sees the free match has already invested in the product. The paywall lands at peak intent.

**Where it sits in the pricing tier:** The full Desire Map reveal unlocks with Core Edition ($14.99) or the Complete Bundle ($34.99). It is the primary reason couples upgrade from free.

---

### Pricing Tiers

| Tier | Price | Contents |
|------|-------|----------|
| Free | $0 | Onboarding, assessment preview, 3 prompts, desire map teaser |
| Core Edition | $14.99 | Full scores, Phase 0+1, full desire map, boundary workshop |
| Communication Pack | +$9.99 | Drop Box (100 AI-translated messages), communication profiles |
| Education Pack | +$9.99 | Phase 2 modules, quizzes, STI resources |
| Scenarios Pack | +$14.99 | Phase 3+4, advanced boundary tools |
| Complete Bundle | $34.99 | Everything. All future content updates. |
| AI Coach (subscription) | $6.99/mo | Unlimited Drop Box, AI coach, jealousy first aid, insights, reports |

### Why One-Time + Subscription

Static content is yours forever — buying a book, not renting access. The ONLY subscription is for AI features that cost real money per use (every chat message, every transcription, every analysis). Users understand that.

### Future Freemium Consideration

The Flo Health model suggests a compelling alternative: free tier creates the habit and the data, premium unlocks the value of the data already collected. For Open Lightly this could mean:

| Free Tier | Premium |
|---|---|
| Basic check-ins (last 10 entries) | Full check-in history + pattern insights |
| Up to 3 connection cards | Unlimited connections |
| Basic jealousy log | Full jealousy history + pattern dashboard |
| 5 daily pulse entries | Full pulse history + emotional calendar |
| Community prompts (read) | Full prompt library + custom |

**Decision deferred to post-V1.0 data review.** The current one-time + subscription model ships first. Conversion to freemium considered only if D30 retention data suggests the data-compounding model would produce stronger LTV.

### Subscription Features Breakdown

| Feature | Why Subscription | Cost Driver |
|---------|-----------------|-------------|
| Unlimited Drop Box | $0.02–0.08 per AI translation, heavy users send 50+/month | Per-message API cost |
| Conversation Insights | Recording → transcription → analysis per session | Whisper + GPT per session |
| Monthly Reports | AI-generated relationship health reports | Accumulated data analysis |
| Evolving Compatibility | Quarterly re-assessment with trend analysis | Embedding + comparison |

---

## 13. Build Progress

Act 1 batches ship before Act 2 batches are polished before Act 3 batches are completed.

| Batch | Act | Scope | Status |
|-------|-----|-------|--------|
| 1–3 | 1/2/3 | Project setup, data models, enums | Done |
| 4 | 1/2/3 | Theme — AppColors, AppFonts, AppTheme, ThemeManager | Done |
| 5 | 1/2/3 | Navigation — ContentView, 5-tab structure | Done |
| 6 | 1 | Components — PromptCard, GradientText, SafeWordButton, ProgressRingView | Done |
| 7 | 1 | Feature screens — Home, Session, DesireMap, Progress, Settings | Done |
| 8 | 1/2/3 | SwiftData persistence — sessions, ratings, streaks | Done |
| 9 | 1/2/3 | Auth (Sign in with Apple + Supabase), partner pairing, sync services | Done |
| 10 | 1/2/3 | Theming (light/AMOLED), sync retry on launch | Done |
| — | 1/2/3 | Codebase audit & refactor (design tokens, shared components, dead code) | Done |
| 11 | 1/2/3 | Onboarding flow (all three-act paths, CardReveal as reflection moment, blurred-home GR implementation) | **In Progress** |
| 12 | 1 | Content authoring — Act 1 prompts, card decks, education modules | Planned |
| 13 | 1 | Assessment / archetype classification (post-first-session) | Planned |
| 14 | 1 | Communication Pack — Drop Box + AI translation | Planned |
| 15 | 1 | AI Coach Membership | Planned |
| 16 | 3 | Bridge Cards (solo user with partner path) | Planned |
| 17 | 3 | Journal / notes system (solo path) | Planned |
| 18 | 2 | Jealousy Mapping — structured logging/decoding tool | Planned |
| 19 | 2 | Compersion Tracker — emotional logging | Planned |
| 20 | 2 | Connection Cards / Partner Roster — visual relationship network | Planned |
| 21 | 2 | Solo/Couple Check-In Rituals — structured pre/post-date check-ins | Planned |
| 22 | 2 | Daily Relationship Pulse — 30-second micro-check-in | Planned |
| 23 | 2 | Contextual Resource Library — trigger-based education | Planned |
| 24–26 | 2 | Communication Pattern Library (browsable, no recording) | Planned |
| 27–28 | 2 | Opt-in recording, transcription, alternative phrasing engine | Planned |
| 29+ | 2 | Post-conversation replay, transparency documentation | Planned |
| 30+ | 2 | Hybrid linguistic analysis (with full consent architecture) | Planned |

---

## 14. Guiding Principles

1. **This is not therapy.** It is a conversation tool. A communication skills resource. An educational framework. The line is non-negotiable. See Section 3.
2. **Privacy is the product.** Local-first. Solo reflections never shared. Screenshot protection on sensitive content. No social graph. No accounts linked to social media.
3. **The couple is the user.** Every feature asks: does this bring them closer or create friction?
4. **Buy content, subscribe to AI.** Static content is yours forever. Subscription only for features that cost real money per use.
5. **Color is earned.** The UI rewards engagement with visual richness.
6. **Safety is sacred.** Gold means stop. The safe word is always accessible, never hidden.
7. **Skip is real.** No guilt, no nagging, no re-prompting. Every "skip" is a valid choice.
8. **Normalize, don't pathologize.** The voice is a thoughtful friend, not a clinician. Every outcome — including "this isn't for us" — is valid.
9. **Structure over information.** They have enough information. They need a process for turning it into conversations.
10. **No dollar is worth an ethical violation.** If a feature could cause harm, it doesn't ship. Period.

> **The Compounding Data Principle:** Every check-in, every journal entry, every jealousy log should feel like it's building something — a picture of yourself and your relationships that gets more accurate and more valuable the longer you stay. The moment a user thinks "this app knows me better than I know myself" — that's when retention becomes organic.

---

## 15. Session System

### Card Actions

Replaces the original thumbs up/down design:

| Action | Button | What It Means | Signal |
|--------|--------|---------------|--------|
| **We Discussed This** | ✅ Primary gradient CTA | Partners talked about this card | Completion |
| **Not Ready** | ⏩ Secondary | Not ready for this topic yet | Honest signal, no shame |
| **Bookmark** | 🔖 Icon button | Save to revisit later | High intent |

**Rationale for removing thumbs up/down:**
- `CardStatus` enum (`.discussed` / `.skipped` / `.bookmarked`) tracks the meaningful signals
- "Did you talk about it?" matters more than "Did you like the card?"
- The conversation IS the engagement, not the rating tap
- Skip/bookmark data is more actionable for content improvement than 👍👎

### Card Layout (per card in session)

```
┌──────────────────────────────────────┐
│          1 of 5 • Category           │
│                                      │
│  ┌────────────────────────────────┐  │
│  │ "Prompt text here..."          │  │
│  │                                │  │
│  │ Take turns sharing.            │  │
│  │ Listen without judgment.       │  │
│  └────────────────────────────────┘  │
│                                      │
│  ┌──────────────┐  ┌──────┐         │
│  │ ⏩ Not Ready  │  │ 🔖  │         │
│  └──────────────┘  └──────┘         │
│                                      │
│  ┌────────────────────────────────┐  │
│  │  ✅ We Discussed This          │  │
│  └────────────────────────────────┘  │
│                                      │
│           🛑 Safe Word               │
└──────────────────────────────────────┘
```

### Session Summary

- Cards discussed count
- Cards skipped count ("no pressure")
- Cards bookmarked count ("saved for later")
- Feeling emoji check-in
- Encouragement text

---

## 16. Data Models

### Architecture

```
UserProfile A          UserProfile B
│                      │
└──────┐  ┌────────────┘
       │  │
       ▼  ▼
      Couple
      ├── cardProgress[]
      ├── sessionRecords[]
      └── kinkMatches[]
```

Individual data (assessment answers, kink ratings) lives on `UserProfile`.
Shared data (sessions, card progress, kink matches) lives on `Couple`.
Deleting a `Couple` does NOT delete the `UserProfile`s.

### Couple Model

```
Couple
├── id: UUID
├── createdAt: Date
├── partnerA: UserProfile?
├── partnerB: UserProfile?
├── sharedSafeWord: String          (default: "red")
├── matchesRevealed: Bool           (default: false)
├── cardProgress: [CardProgress]
├── sessionRecords: [CoupleSessionRecord]
└── kinkMatches: [KinkMatch]
```

### UserProfile Model

```
UserProfile
├── id: UUID
├── name: String
├── createdAt: Date
├── pronouns: String
├── sexualOrientation: String
├── rolePreference: String
├── userMode: String                ("solo", "couple", "curious")
├── experienceLevel: String         ("new", "some", "experienced")
├── defaultDifficulty: String       ("warm", "medium", "hot", "blazing")
├── nmFlavor: NMFlavor?
├── curiositySelections: [String]
├── surpriseMeEnabled: Bool
├── hasCompletedOnboarding: Bool
├── hasCompletedAssessment: Bool
├── mythBusterComplete: Bool
├── mythBusterSkipped: Bool
├── onboardingDropoffScreen: String?    (analytics)
├── accountId: String?                  (Sign in with Apple)
├── accountCreated: Bool
├── pairingCode: String
├── isLinked: Bool
├── partnerLabel: PartnerLabel?
├── assessmentResponses: [AssessmentResponse]
└── kinkRatings: [KinkRating]
```

---

## 17. Scoring & Matching

### Two Separate Rating Systems

| Model | Purpose | Data Type | Owner | Privacy |
|-------|---------|-----------|-------|---------|
| **RatingRecord** | Prompt card reactions during sessions | String (`"discussed"` / `"skipped"` / `"bookmarked"`) | `SessionRecord` | Shared — written together |
| **KinkRating** | Individual kink/BDSM map answers | Typed `Rating` enum (`.love` / `.curious` / `.neutral` / `.hardNo`) | `UserProfile` | Private — Hard No NEVER revealed |

`KinkRating` feeds into `KinkMatch`. `RatingRecord` feeds into session history and progress stats. They are completely separate systems.

### Hard No Protection (Defense in Depth)

Hard No ratings must **NEVER** be visible to a partner. Enforced at three levels:

| Level | Protection |
|-------|-----------|
| **Database (RLS)** | `kink_ratings` table: only owner can query. Partner cannot access this table at all. |
| **Server (Edge Function)** | `compute_kink_matches()` filters out any row where either rating = `hardNo` BEFORE writing to `kink_matches` table. |
| **Client (Swift)** | `KinkRating` model is local-only for `hardNo` items. Only `.love` / `.curious` / `.neutral` are ever sent to server for matching. `hardNo` items never leave the device. |

---

## 18. Privacy Rules

| Rule | Detail | Enforcement Level |
|------|--------|-------------------|
| Individual assessment answers | Encrypted locally. Never synced raw. Partner never sees them. | Device + Database (never uploaded) |
| Kink Hard No's | Never revealed. Never stored on server. Never queryable by partner. | Device + Server (Edge Function filter) + Database (RLS) |
| Safe word usage | Not logged. Not surfaced in stats. Not stored anywhere. | App code (no tracking call) |
| Session notes | Local only. Never synced to Supabase. | Device only |
| Push notifications | No sensitive content in notification text. | Server (Edge Function templates) |
| Backend data | Only: pairing data, completion status, domain-level scores (not raw answers), positive kink matches. | Database (RLS on every table) |
| Cross-user access | No user can query another user's data except through couple relationship. | Database (RLS policies) |
| Unauthenticated access | Zero. All queries require valid Sign in with Apple JWT. | Database (RLS) + Supabase Auth |
| Service role key | Server-side only. Never in client code. Never in git. | Code review + audit checklist |
| Encryption at rest | Kink ratings and assessment answers encrypted via CryptoKit before any storage. | Device (CryptoKit + Keychain) |

### Data Classification

| Data | Sensitivity | Storage | Encrypted | Synced to Supabase |
|------|-------------|---------|-----------|-------------------|
| Display name | Low | SwiftData + Supabase | No | Yes |
| Pronouns | Low | SwiftData + Supabase | No | Yes |
| NM Flavor | Medium | SwiftData + Supabase | No | Yes |
| Pairing code | Low (ephemeral) | Supabase only | No | Yes (expires 24h) |
| Assessment answers (raw) | High | SwiftData ONLY | Yes (CryptoKit) | NO — never leaves device |
| Assessment domain scores | Medium | SwiftData + Supabase | No | Yes (aggregated, not raw) |
| Kink ratings (individual) | Critical | SwiftData (encrypted) | Yes (CryptoKit) | Only non-hardNo, encrypted, for matching |
| Kink Hard No items | Critical | SwiftData ONLY | Yes (CryptoKit) | NO — never leaves device |
| Kink matches (positive) | Medium | SwiftData + Supabase | No | Yes (only mutual positives) |
| Session notes | High | SwiftData ONLY | No | NO — never leaves device |
| Session card statuses | Low | SwiftData + Supabase | No | Yes (discussed/skipped/bookmarked) |
| Safe word usage | Critical | NOT LOGGED | N/A | NO — never recorded anywhere |

---

## 19. Database Security Plan

### Why This Matters More for This App

This app stores the most sensitive data possible — sexual preferences, kink ratings, intimate conversation history, partner pairing status, psychological assessment answers. A breach for a to-do app is embarrassing. A breach for this app ruins lives.

### The 7 Mistakes We Will Not Make

| # | Mistake | What Happens | Our Mitigation |
|---|---------|-------------|----------------|
| 1 | No Row Level Security (RLS) | Anyone with Supabase URL reads/writes ALL data | RLS enabled on EVERY table at creation, BEFORE any data is inserted |
| 2 | API keys in frontend code | Anyone can extract keys from app bundle | Only anon key in app (safe with RLS). Service role key NEVER in client code. |
| 3 | No auth required for queries | Unauthenticated users read entire database | Sign in with Apple required before any DB access. No anonymous queries. |
| 4 | Service role key in the app | "God mode" key shipped to users | Service role key exists ONLY in Supabase Edge Functions (server-side) |
| 5 | No policies on sensitive tables | Kink ratings, messages readable by anyone | Every table has explicit USING/WITH CHECK policies per row |
| 6 | Client-side validation only | User modifies request, bypasses checks | All security enforced at database level via RLS. Client validation is UX only. |
| 7 | No encryption for sensitive fields | Breach exposes plaintext data | Kink ratings encrypted with CryptoKit before upload. Even a breach yields encrypted blobs. |

### Row Level Security Policies

**Every table gets RLS enabled and policies written BEFORE any data is inserted.**

```sql
-- ============================================
-- USER PROFILES: Only own profile accessible
-- ============================================
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users read own profile"
  ON user_profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users update own profile"
  ON user_profiles FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Users insert own profile"
  ON user_profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- ============================================
-- KINK RATINGS: Private — ONLY the owner
-- ============================================
ALTER TABLE kink_ratings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Private kink ratings"
  ON kink_ratings FOR ALL
  USING (auth.uid() = owner_id);

-- Partner can NEVER query this table for the other user.
-- Matching is done via Edge Function (server-side) that
-- filters out Hard No before returning results.

-- ============================================
-- COUPLES: Only the two linked partners
-- ============================================
ALTER TABLE couples ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Couple members only"
  ON couples FOR SELECT
  USING (
    auth.uid() = partner_a_id
    OR auth.uid() = partner_b_id
  );

CREATE POLICY "Couple members update"
  ON couples FOR UPDATE
  USING (
    auth.uid() = partner_a_id
    OR auth.uid() = partner_b_id
  );

-- ============================================
-- KINK MATCHES: Only the couple, positive only
-- ============================================
ALTER TABLE kink_matches ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Couple views matches"
  ON kink_matches FOR SELECT
  USING (
    couple_id IN (
      SELECT id FROM couples
      WHERE partner_a_id = auth.uid()
         OR partner_b_id = auth.uid()
    )
  );

-- ============================================
-- ASSESSMENT STATUS: Own data + partner completion flag
-- ============================================
ALTER TABLE assessment_status ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Own assessment data"
  ON assessment_status FOR ALL
  USING (auth.uid() = user_id);

CREATE POLICY "Partner completion check"
  ON assessment_status FOR SELECT
  USING (
    couple_id IN (
      SELECT id FROM couples
      WHERE partner_a_id = auth.uid()
         OR partner_b_id = auth.uid()
    )
  );
-- NOTE: Partner can see is_complete flag, NOT individual scores or answers.

-- ============================================
-- ENTITLEMENTS: Both partners read
-- ============================================
ALTER TABLE entitlements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Couple views entitlements"
  ON entitlements FOR SELECT
  USING (
    couple_id IN (
      SELECT id FROM couples
      WHERE partner_a_id = auth.uid()
         OR partner_b_id = auth.uid()
    )
  );
```

### Key Management

| Key | Where It Lives | Who Can Access |
|-----|---------------|----------------|
| Supabase URL | App config (public) | Anyone (by design — safe with RLS) |
| Supabase anon key | App config (public) | Anyone (by design — safe with RLS) |
| Supabase service role key | Supabase Edge Functions ONLY | Server-side only. NEVER in client code. NEVER in git. |
| User encryption key | iOS Keychain (per device) | Only the device owner via biometric auth |
| JWT tokens | iOS Keychain | Only the authenticated user |

### Pre-Launch Security Audit Checklist

```
□ RLS enabled on every Supabase table (check dashboard badges)
□ Every table has explicit SELECT/INSERT/UPDATE/DELETE policies
□ Test: unauthenticated request to any table returns 0 rows
□ Test: User A authenticated, query User B's kink_ratings → 0 rows
□ Test: User A authenticated, query User B's assessment → 0 rows
□ Test: User A in Couple 1, query Couple 2 data → 0 rows
□ Test: Query kink_matches for a couple → no Hard No items present
□ Search entire Xcode project for service role key → 0 results
□ Search entire git history for service role key → 0 results
□ Supabase anon key is the ONLY key in client code
□ Sign in with Apple is required before any database operation
□ Kink ratings encrypted before any network transmission
□ Hard No items never included in any Supabase write operation
□ Push notification text contains no sensitive content
□ Screenshot protection active on: assessment, kink map, results, notes
□ App lock (Face ID / Touch ID) enabled by default
□ Privacy policy accurately describes data handling
□ Run Supabase security advisor (dashboard tool)
```

### Incident Response Plan

If a security issue is discovered:
1. Immediately revoke all active sessions (Supabase dashboard)
2. Immediately rotate the anon key and service role key
3. Assess what data was exposed and for how long
4. Notify affected users within 72 hours (GDPR/CCPA requirement)
5. Document the root cause and fix
6. Post-mortem — update security policies to prevent recurrence

---

## 20. Supabase Cost Projections

### Cost by User Scale

| Monthly Active Users | Plan | Base | MAU Overage | Est. Total/mo | Revenue Needed to Cover |
|---------------------|------|------|-------------|--------------|------------------------|
| 0 – 50,000 | Free | $0 | $0 | $0 | Nothing |
| 50,001 – 100,000 | Pro | $25 | $0 (100K included) | ~$25–35 | 2–3 paid users |
| 100,001 – 250,000 | Pro | $25 | 150K × $0.00325 = $488 | ~$525 | 53 paid users |
| 250,001 – 500,000 | Pro | $25 | 400K × $0.00325 = $1,300 | ~$1,400 | 140 paid users |
| 500,001 – 1,000,000 | Pro/Team | $25–599 | 900K × $0.00325 = $2,925 | ~$3,000–3,500 | 350 paid users |

### Hidden Cost Triggers

| Resource | Free Limit | Pro Limit | Overage Cost | When It Bites |
|----------|-----------|-----------|-------------|--------------|
| Database size | 500 MB | 8 GB | $0.125/GB | ~100K users with kink ratings + sessions |
| Bandwidth (egress) | 5 GB | 250 GB | $0.09/GB | Real-time sync for couples is chatty |
| File storage | 1 GB | 100 GB | $0.021/GB | Only if profile photos added later |
| Compute | Shared CPU | $10 credit | Varies | If real-time pairing feels slow |

### Break-Even Context

At Y1 target of 2,000–5,000 paying couples:
- Supabase cost: **$0** (well under 50K MAU)
- App revenue: $50,000–$80,000
- Backend costs are irrelevant until app is already profitable

> **Note:** Free tier projects pause after 1 week of inactivity — upgrade to Pro ($25/mo) before any real users to prevent this.

---

## 21. Expansion Roadmap — Acts 2 & 3

Each expansion is a marketing shift as much as a feature release. The tools are largely present in architecture at V1.0; what changes at each act milestone is the front-door story and who we tell it to.

### Act 2 Expansion — V1.1 (30–60 days post-launch)

**Marketing shift:** *"For people doing non-monogamy intentionally."* Experienced ENM practitioners who downloaded the app out of curiosity discover it has operational infrastructure they've never had. This expansion surfaces what was already present.

| Feature | User Type | Rationale |
|---|---|---|
| Connection Cards / Partner Roster | Both | Infrastructure — other features (vault, check-ins, logs) link to connections |
| Solo Date Check-In / Self Check-In | Both | Structured post-date ritual. Natural evolution of solo reflection. |
| Compersion Tracker | Both | Low-friction emotional logging. Counterweight to jealousy work. |
| Daily Relationship Pulse | Both | 30-second daily habit. Data compounds → retention compounds. |
| Smart Contextual Notifications | Both | Personalized nudges based on logged data. Max 1/day, all user-adjustable. |
| Contextual Resource Library | Both | Education surfaced at the right moment — triggered by logging activity. |
| Insight Engine — Pattern Surfacing | Both | Weekly/monthly insights from logged data. Core retention mechanic. Needs data from V1.0 usage to work. |
| Emotional Texture Calendar | Both | Calendar layer showing emotional color per day. Needs pulse data. |

### Act 2 Continued — V1.2 (60–120 days post-launch)

| Feature | User Type | Rationale |
|---|---|---|
| Jealousy Mapping | Both | Dedicated in-the-moment tool. Treats jealousy as information, not failure. |
| Agreements Vault | Partnered | Structured, per-partner agreement storage. Requires connection roster first. |
| Discovery Journal | Solo | Prompted private journal for self-discovery. Extends reflection system. |
| Non-Negotiables Document | Solo | Personal values/boundaries document. Living reference, not one-time fill. |

### Act 3 Expansion — V1.2+ (Marketing shift accompanies feature polish)

**Marketing shift:** *"For people who take relationships seriously. All kinds of relationships."* Solo users are explicitly invited. The product reveals it was never about having a partner — it was always about doing the work intentionally. The solo path has existed since V1.0; this is when we tell that story publicly.

Solo-specific polish, bridge cards, and expanded solo roadmap content ship as part of the Act 3 marketing push. No architectural changes required — the routing has always been there.

### V1.5 (4–8 months post-launch)

| Feature | User Type | Rationale |
|---|---|---|
| Anonymous Community Feed | Both | Context-mapped social layer. Requires Pulse + logging features at critical mass first. Moderation cost too high pre-scale. |
| Relationship Report (Exportable) | Both | PDF summary for therapist/coach use. Only meaningful with significant logged history. |

### V2.0+ (Far Future Considerations)

| Feature | Notes |
|---|---|
| Your Year, Lightly | Annual cinematic retrospective. Spotify Wrapped for your relational year. Hidden from users with < 6 months active logging — surfaces when earned, not unlocked. Not named in scope yet. |
| Multi-Partner Calendar | Scheduling + emotional texture overlay. High complexity. |
| NRE Navigator | Second-order feature for active new connections. |
| Polycule Network Visualizer | Requires populated roster. |

---

## 22. Anonymous Community Feed — V1.5 Design Principles

> The feed is not a forum bolted onto a tracking app. It is where people who already know themselves — because the app taught them — come to locate their experience within a larger map of human ENM life.

### The Core Differentiator From r/nonmonogamy

Reddit's problem: posts are the atomic unit. Every new person with a jealousy spiral creates a new post, gets 12 replies saying "communicate with your partner," and the collective knowledge never compounds. Open Lightly's feed inverts this.

**The post is a last resort. The default action is finding yourself in what already exists.**

### Pre-Post Mapping Flow

When a user opens "Share something," they don't get a text field. They get a short framing funnel:

1. *What kind of thing is this?* — Processing something difficult / Sharing a win / Asking for perspective / Something I've never seen discussed
2. *What's at the center of it?* — Tags drawn from the app's vocabulary (jealousy, compersion, NRE, bandwidth, agreements, endings, metamour dynamics, etc.)

The app then surfaces: **"Here's what others have shared from a similar place"** — a visual cluster of existing posts mapped by emotional similarity, not keyword match. If a user finds themselves in an existing post, they react and they're done. They found their people without adding noise.

Only if nothing matches does the compose screen open — with nearby posts visible, relevant tags pre-suggested, and a prompt: *"What's the angle nobody's captured yet?"*

### Post Context Layer

Posts optionally carry relational context the app already knows:
- *"Writing from: 8 months into ENM, coupled primary structure, recently added a new connection"*
- No name, no photo — but structural context that makes advice actually calibrated

This is the thing Reddit can never replicate: people arriving with language and self-knowledge the app built for them.

### Feed Structure

- **Resonance clustering** — not chronological, not upvote-ranked. Posts bookmarked by users at similar stages cluster to the surface.
- **"Still true" signal** — users can mark a post weeks or months later when it still reflects something real. Posts with sustained "still true" signals become the durable knowledge base.
- **Sections:** Processing / Wins / Never discussed this before / Questions
- **Reactions:** Heart / Resonate only — no downvotes, no public reply counts on individual posts

### Access Model

- Read-only on free tier
- Posting unlocked on Premium or V1.5+ active user tier
- Moderation architecture designed before launch, not after

---

## 23. Your Year, Lightly — V2.0 Design Principles

> Spotify Wrapped works because it makes you the protagonist of a story you were already living. Open Lightly's version carries real emotional weight: you processed jealousy 14 times, logged compersion 9 times, your bandwidth was lowest in October, you added three connections and closed one with grace.

### Eligibility Gate

The feature does not exist for ineligible users — no locked state, no teaser. It surfaces when earned:
- ≥ 6 months of active logging (not installs)
- ≥ 20 check-ins or session completions
- ≥ 1 connection card with meaningful history

### The Experience Arc

A cinematic scroll — one reveal at a time, each screen its own moment. Opens not with stats but with a tone read:

> *"2025 was a year of expansion for you. You moved toward things that scared you — and most of them were worth it."*

Derived from actual log data: net emotional trajectory, connections opened vs. closed, jealousy trend, bandwidth patterns. The app already knows this. It just hasn't said it out loud yet.

### Postcard System

Each significant moment gets its own designed postcard — shareable, beautiful, optionally private. Not a screenshot of a log. A *designed artifact* that transforms data into memory.

**Milestone cards** — first-of-kind events the user tagged or the app inferred:
- First new connection added to an existing relational structure
- First agreement renegotiation the user initiated
- First time logging compersion after previously only logging jealousy
- Sexual and experiential milestones the user tagged (first club night, first moresome, etc.) — app never labels or assumes; only celebrates what the user explicitly logged

**Emotional arc cards:**
- Jealousy patterns: frequency, most common triggers, and whether the pattern shifted over the year
- Compersion log highlights: the moments that made the list
- Bandwidth rhythm: highest and lowest capacity months

**Connection cards** — one per active relationship:
- Time together logged, sessions run, most-used card category
- A pulled quote from a reflection they wrote (their words, their meaning)

**The numbers card:**
- Check-ins completed / Reflection entries written / Agreements created or revised
- Connections active at start vs. end of year
- Emotional arc summary in one line

### Sharing Design

- **Private first** by default — the full experience is personal
- **Shareable postcards** designed to carry meaning without requiring context. *"I logged compersion 23 times in 2025"* means everything to ENM people and reads as emotional growth to everyone else
- **Partner share** option — send your Year card to a partner so they can see your year from the inside. No comparison, no leaderboard. Just: *"here's what this year looked like for me"* — a conversation starter no other app can create

### Name

**Your Year, Lightly** — the app handing something back to you, not performing for you.

---

## 22. Professional-Grade Engineering — Guardrails for Vibe Coders

> **Context:** This section exists because vibe coding + AI assistants can produce apps that look finished but have silent, catastrophic failure modes. This app stores the most sensitive data users will ever hand an app. The bar is higher than a to-do list. These rules are the difference between a hobby project and a shippable product.

---

### The Core Problem With Vibe Coding

AI writes code that works for the happy path. It doesn't write code that handles the 37 things that can go wrong. You have to know what questions to ask — and this section gives you those questions.

**The pattern to break:**
```
❌ Vibe: Write code → it works in simulator → ship it
✅ Professional: Write code → ask "what happens when this fails?" → handle failure → test edge cases → then ship
```

---

### 1. Error Handling — The #1 Vibe Coder Blind Spot

AI-generated code almost always has this pattern:
```swift
// What AI writes (dangerous)
let data = try await supabase.from("profiles").select().execute()

// What it should be
do {
    let data = try await supabase.from("profiles").select().execute()
} catch {
    // Log it. Show user something meaningful. Don't crash silently.
    logger.error("Profile fetch failed: \(error.localizedDescription)")
    await MainActor.run { self.errorState = .networkFailure }
}
```

**Every network call needs:**
- A success path
- A failure path
- A loading state
- A retry mechanism (or at least a retry button)

**The three states every async view needs:**
```
.loading   → show skeleton / spinner
.loaded    → show content
.error     → show "Something went wrong" + retry button (NOT a blank screen)
```

A blank white screen when the network fails isn't UX — it's a bug that looks like a feature.

---

### 2. SwiftData Safety — Silent Data Destruction

SwiftData schema changes are the most dangerous thing you can do to existing users. A model change that worked fine in your simulator will wipe a real user's data if migrated wrong.

**The rule: Every SwiftData model change that isn't purely additive requires a migration plan.**

| Change Type | Safe? | What to Do |
|-------------|-------|-----------|
| Add a new optional property | ✅ Safe | Just add it |
| Add a new required property | ⚠️ Dangerous | Must provide default value or migration |
| Rename a property | ❌ Destructive | Write a `MigrationPlan` with `MigrationStage` |
| Change a property type | ❌ Destructive | Write a migration |
| Delete a property | ⚠️ Careful | Data is gone — intentional? |
| Rename a model | ❌ Destructive | Write a migration |

**What a migration looks like:**
```swift
enum AppMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] = [
        SchemaV1.self,
        SchemaV2.self,
    ]

    static var stages: [MigrationStage] = [
        migrateV1toV2
    ]

    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self,
        willMigrate: nil,
        didMigrate: { context in
            // transform data here
        }
    )
}
```

**Before shipping any model change:** Delete the app from your simulator, reinstall fresh, verify the new schema works from scratch. Then verify migration from the old schema works.

---

### 3. Main Thread Violations — The Crash You Won't See in Testing

SwiftUI requires UI updates on the main thread. Supabase callbacks and async operations often return on background threads. Violating this crashes the app — sometimes immediately, sometimes randomly in production.

```swift
// ❌ Crashes in production (fine in simulator sometimes)
func fetchProfile() async {
    let profile = try await profileService.fetch()
    self.userProfile = profile  // ← UI update on background thread
}

// ✅ Correct
func fetchProfile() async {
    let profile = try await profileService.fetch()
    await MainActor.run {
        self.userProfile = profile
    }
}
```

**The rule:** Any property marked `@Published` or that drives SwiftUI views must only be mutated on `@MainActor`. Mark your ViewModels `@MainActor` at the class level to prevent the entire class of bugs:

```swift
@MainActor
class SessionViewModel: ObservableObject {
    @Published var cards: [PromptCard] = []
    // All mutations here are automatically main-thread safe
}
```

---

### 4. The Empty State Problem

Every list, every collection, every result set can be empty. Vibe coders handle the case where data exists. Professional apps handle all three cases:

| State | What to Show |
|-------|-------------|
| Loading | Skeleton / spinner |
| Empty (no data yet) | Helpful message + CTA ("No sessions yet — start your first one") |
| Empty (no results for filter) | Explanation ("Nothing matches") |
| Error | "Something went wrong" + retry |
| Has data | The actual content |

A `ForEach` over an empty array shows nothing. Users think the app is broken.

```swift
// Always wrap lists with state awareness
if cards.isEmpty && !isLoading {
    EmptyStateView(message: "No cards yet. Start a session to explore.")
} else {
    ForEach(cards) { card in CardView(card: card) }
}
```

---

### 5. Sensitive Data Must Never Hit the Console

Xcode's console and `print()` statements are your friend during development. They are a data breach in production.

**Never log:**
- Kink ratings or any assessment answers
- User names paired with relationship data
- Authentication tokens or session IDs
- Pairing codes
- Any property from `UserProfile` beyond `id`

**Use a proper logger:**
```swift
import OSLog

private let logger = Logger(subsystem: "com.openlightly.app", category: "Sessions")

// Safe — category only, no user data
logger.info("Session started")

// NEVER do this
print("User \(user.name) rated kink item \(kinkItem.title) as \(rating)")
```

**Before shipping:** Search the entire codebase for `print(` and audit every single one. Remove or replace with `logger`. Build for release and check the console — if sensitive data appears there, it's a bug.

---

### 6. Git Hygiene — One Mistake That Can't Be Undone

Secrets pushed to git are compromised, full stop. Rotate them immediately. Deleting the commit doesn't help — git history is forever, and bots scrape GitHub for secrets within minutes of a push.

**Your `.gitignore` must include:**
```
# Secrets
Config.xcconfig
*.xcconfig
.env
Secrets.plist

# Xcode noise
*.xcuserstate
xcuserdata/
DerivedData/

# OS junk
.DS_Store
```

**The `Config.xcconfig` pattern for secrets:**
```
// Config.xcconfig (git-ignored)
SUPABASE_URL = https://your-project.supabase.co
SUPABASE_ANON_KEY = eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

```swift
// Config.swift — reads from build settings, never hardcodes
struct Config {
    static let supabaseURL = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as! String
    static let supabaseAnonKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as! String
}
```

**Branching strategy (simple, actually follow it):**
```
main          → only tested, working code. Never commit directly.
dev           → integration branch. Test here before merging to main.
feature/xxx   → one branch per feature. Merge via PR to dev.
```

---

### 7. Two Environments: Dev and Production

The #1 way vibe coders corrupt real user data: running development builds against the production database.

**You need two Supabase projects:**
- `openlightly-dev` — your sandbox. Blow it up, reset it, experiment freely.
- `openlightly-prod` — real users. Touch only for intentional releases.

**How to switch:**
```
// Dev scheme → points to openlightly-dev Supabase
// Prod scheme → points to openlightly-prod Supabase

// In Xcode: Product → Scheme → Manage Schemes
// Create "Open Lightly Dev" and "Open Lightly Prod"
// Each scheme uses a different Config.xcconfig
```

**The rule:** Run the Dev scheme 99% of the time. Switch to Prod only for TestFlight builds and releases. If you're ever unsure which environment you're pointed at, check before touching the database.

---

### 8. StoreKit Testing — Don't Find Out at Submission

StoreKit is the most "works in simulator, breaks in production" layer in iOS development.

**Testing checklist before submission:**
```
□ Test purchase flow with StoreKit sandbox (not simulator mock)
□ Test restore purchases on a fresh device (users WILL do this when they get a new phone)
□ Test what happens when a purchase is interrupted (network drops mid-transaction)
□ Test subscription expiry — does the app correctly downgrade access?
□ Test family sharing (does one family member's purchase unlock for others? Is that intended?)
□ Verify receipt validation happens server-side, not just client-side
□ Test with a StoreKit sandbox account, not your Apple ID
```

**Receipt validation:** If you validate purchases client-side only, users can spoof receipts and get paid content for free. For this app's scale, client-side validation is acceptable at launch — but document it as a known limitation to address before scaling.

---

### 9. App Store Submission — Common Rejection Reasons

Apple rejects apps for predictable reasons. Know them before you submit.

| Rejection Reason | How to Avoid |
|-----------------|-------------|
| **Guideline 1.1.6** — Dating/social apps must have content moderation | This is NOT a dating app — make sure the App Store listing, screenshots, and app description are clear about that. |
| **Guideline 5.1.1** — Privacy policy required | Write one before submission. It must accurately describe all data collected and how it's used. |
| **Guideline 3.1.1** — All digital goods sold via IAP | You cannot use Stripe, PayPal, etc. for in-app purchases. StoreKit only. |
| **Guideline 2.1** — App crashes or has major bugs | Test on a real device (not just simulator). Test every purchase flow. |
| **Guideline 5.1.2** — Sensitive data handling | Must have a privacy policy link in the App Store listing AND in the app. |
| **Guideline 2.3.3** — App description misleading | Screenshots must show actual app UI, not mockups. |
| **Guideline 4.2** — Minimum functionality | Free tier must have enough functionality to demonstrate value. |
| **Metadata rejection** — screenshots too similar | Every screenshot must show clearly different content. |

**Before submitting, run your App Store listing through this lens:**
> "Does this sound like a hook-up app, a therapy app, or a sex app?"

It must sound like none of those. It's a conversation tool for couples. Review every word of the listing with that framing.

---

### 10. Memory Management — Retain Cycles

SwiftUI and `@Observable` handle most memory management automatically. But `async`/`await` and closures can still create retain cycles that silently grow your app's memory footprint.

**The pattern to watch:**
```swift
// ❌ Potential retain cycle — self holds task, task holds self
func loadCards() {
    Task {
        self.cards = await fetchCards()  // strong capture of self
    }
}

// ✅ Weak capture when appropriate
func loadCards() {
    Task { [weak self] in
        guard let self else { return }
        self.cards = await fetchCards()
    }
}
```

**How to detect:**
- In Xcode: Debug → Memory Graph Debugger during a session
- Look for objects that should have been deallocated still showing up
- Use Instruments → Leaks for a full leak report before submission

---

### 11. Accessibility — Not Optional

Apple reviews for accessibility. Users with disabilities use your app. And VoiceOver users in the NM community exist.

**Minimum requirements:**
```swift
// Every interactive element needs a label
Button(action: skipCard) {
    Image(systemName: "forward.fill")
}
.accessibilityLabel("Skip this card")

// Images that convey meaning need descriptions
Image("desire-map-result")
    .accessibilityLabel("Desire map showing high compatibility in emotional connection")

// Images that are decorative should be hidden
Image("background-gradient")
    .accessibilityHidden(true)
```

**Test with VoiceOver (Settings → Accessibility → VoiceOver):** Navigate the entire onboarding flow without looking at the screen. If you can't complete it, real users can't either.

**Dynamic Type:** Go to Settings → Accessibility → Display & Text Size → Larger Text → max out the slider. Run your app. If text clips, overlaps, or disappears, you have layout bugs.

---

### 12. Offline Behavior — Design for No Connection

Users will open this app in a cabin, on a plane, in bed with their phone on airplane mode. The app must not be useless offline.

**Local-first architecture (already your model) means:**
- App loads from SwiftData without network → show local data immediately
- Network sync happens in background
- If sync fails → local data is still visible → show a subtle "Sync pending" indicator
- Never show a loading spinner indefinitely — set a timeout (10-15 seconds) and show an error state

**The offline checklist:**
```
□ Turn on airplane mode
□ Open the app
□ Does it load? (It should — from SwiftData)
□ Can you start a session? (Yes — cards are local)
□ What happens when you complete a card? (Queues for sync)
□ Turn wifi back on
□ Does queued data sync? (SyncManager handles this)
□ Is nothing lost? (The answer must be yes)
```

---

### 13. Testing — The Minimum You Actually Need

You don't need 100% test coverage. You need tests for the things that will ruin your users' experience if they break.

**Write tests for:**

| What | Why |
|------|-----|
| Hard No never included in kink match payload | The #1 privacy guarantee. If this breaks silently, you've violated user trust catastrophically. |
| Pairing code format validation | Bad codes cause failed pairings. Users blame the app. |
| Assessment score calculation | Wrong scores feed wrong content routing. The whole personalization engine breaks. |
| SwiftData model persistence | Basic smoke test: save a UserProfile, restart the container, verify it's still there. |
| StoreKit entitlement checks | Verify paid content gates work. Verify free users can't access paid content. |

```swift
// Example: The most important test in the app
func testHardNoNeverIncludedInMatchPayload() {
    let ratings = [
        KinkRating(itemId: "item1", rating: .love),
        KinkRating(itemId: "item2", rating: .hardNo),  // Must never appear in payload
        KinkRating(itemId: "item3", rating: .curious),
    ]
    let payload = KinkMatchService.buildPayload(from: ratings)
    XCTAssertFalse(payload.contains(where: { $0.itemId == "item2" }),
                   "Hard No item must never be included in sync payload")
}
```

**How to run:** Cmd+U in Xcode. Run before every TestFlight build.

---

### 14. Crash Reporting — Know When Your App Breaks in the Wild

You won't be there when real users hit bugs. You need to be notified.

**At minimum: Enable Xcode Organizer crash reports**
- Xcode → Window → Organizer → Crashes
- Apple sends you symbolicated crash reports automatically for App Store builds
- Check this weekly after launch

**Better: Add a free crash reporter**
- [Crashlytics (Firebase)](https://firebase.google.com/products/crashlytics) — free, industry standard
- Zero data privacy concerns (just crash stack traces, no user data)
- Setup is ~30 minutes: add SDK, one line in `AppDelegate`/`App.swift`, done
- You get an email every time a new crash type is discovered

**The rule:** Never go more than a week post-launch without checking crash reports.

---

### 15. Performance — Profile Before It's Too Late

Slow apps get deleted. The simulator lies — it runs on a Mac CPU. Real iPhones, especially older models (iPhone 12, iPhone 13), will expose performance issues the simulator hides.

**Test on a real device — specifically:**
- The oldest iPhone you want to support
- iPhone with low storage (< 5GB free) — storage pressure slows SwiftData
- While other apps are running in background

**Instruments (Xcode → Open Developer Tool → Instruments):**

| Instrument | What It Catches |
|------------|----------------|
| Time Profiler | Functions taking too long (scroll lag, slow loads) |
| Core Data / SwiftData | Slow fetches, N+1 query problems |
| Leaks | Objects that should be freed but aren't |
| Network | Unnecessary requests, slow API calls |

**The one SwiftData performance mistake to avoid:**
```swift
// ❌ N+1 problem — fetches each card separately in a loop
for session in sessions {
    let cards = session.cards  // Each access triggers a fetch
}

// ✅ Fetch everything you need upfront with a predicate
@Query(sort: \.createdAt, order: .reverse) var sessions: [SessionRecord]
// SwiftData pre-fetches relationships when declared this way
```

---

### 16. The Vibe Coder Anti-Pattern Checklist

Run through this before every significant PR or TestFlight build:

```
SECURITY
□ No hardcoded API keys, passwords, or secrets anywhere in the code
□ `Config.xcconfig` is in .gitignore and not in the git history
□ `print()` statements don't log any user data
□ Service role key is not in any client-side file

DATA SAFETY
□ No SwiftData model changes without a migration plan
□ Tested fresh install (delete app, reinstall, verify onboarding works)
□ Tested upgrade from previous version (don't delete, just update)
□ Hard No kink ratings never included in any server payload

ERROR HANDLING
□ Every async function has a do/catch or .catch handler
□ Every view has a loading state, empty state, and error state
□ No force-unwrap `!` on values that could realistically be nil
□ Network failures show a user-facing message, not a blank screen

UI/UX
□ Tested with airplane mode on
□ Tested with Dynamic Type at maximum size
□ Tested with VoiceOver on (at least onboarding)
□ Tested on a real device (not just simulator)
□ All lists handle empty state gracefully

PERFORMANCE
□ No blocking operations on the main thread (no `Thread.sleep`, no heavy sync work)
□ Heavy work (JSON parsing, encryption, sync) runs on background Task
□ Scrollable lists use lazy loading (LazyVStack, LazyVGrid, not VStack)

STORE
□ Tested purchase flow with StoreKit sandbox
□ Tested restore purchases on a fresh install
□ All paid content correctly gated behind entitlement check

BEFORE TESTFLIGHT
□ Build in Release configuration (not Debug)
□ Run on a real device in Release mode
□ Check Xcode Organizer for any existing crash reports
□ Run Cmd+U — all tests pass
```

---

### 17. The Questions to Ask Claude/AI When Vibe Coding

AI assistants write code that works. Your job is to ask the questions that surface what breaks. Add these to any prompt where you're implementing something real:

```
After every code generation, ask:
1. "What happens if this network call fails?"
2. "What happens if the user has no internet connection?"
3. "What happens if this data is nil or empty?"
4. "Is there any user data being logged or printed here?"
5. "Does this run on the main thread? Should it?"
6. "What happens if the user leaves this screen mid-operation?"
7. "Is there any way this could expose one user's data to another user?"
8. "What's the migration path if I need to change this SwiftData model later?"
```

These 8 questions, asked consistently, are worth more than a CS degree for shipping a safe, reliable app.

---

### 18. The Honest Scale of What You're Building

This isn't meant to intimidate — it's meant to calibrate:

| App Category | Consequences of a Bug |
|-------------|----------------------|
| To-do app | User re-enters a task |
| Social app | User sees wrong posts |
| **This app** | User's kink preferences exposed to their partner, therapist, family, employer |

The stakes are genuinely high. The data is genuinely sensitive. That's not a reason not to build it — it's a reason to build it right.

The professional bar isn't about having a CS degree. It's about knowing which questions to ask and building the habits (error handling, environment separation, testing the unhappy path) that prevent silent failures.

You have something most CS graduates don't: you understand your users deeply, you've thought carefully about ethics, and you have domain knowledge that can't be taught in a classroom. The technical guardrails above can be learned. The judgment you bring to the product is harder to acquire.

**Build carefully. Ship confidently.**

```

---

