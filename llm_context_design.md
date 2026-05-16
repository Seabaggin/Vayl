# LLM Context — Open Lightly · Design System

> **Scope: Full design system — theme foundation + every Design/Components file.**
>
> Load this bundle when:
> - Building or modifying any UI component
> - Adding visual effects or animations
> - Resolving theming/styling inconsistencies
> - Working on the design token / magic number cleanup (DesignTokens enum)
> - Asking 'what component should I use for X?'
>
> Does NOT include feature screens, services, or persistence.
>
> Known issues in this bundle:
> - FilamentMode.swift → dead code, entire file
> - GradBadge in GradientButton.swift:45-59 → low usage, consider removing
> - CTABorderModifier in HoloCTAButton.swift:165-176 → defined but unused
> - 10 unused color tokens in AppColors.swift → purpleBright, electricViolet, etc.
>
> FILE_TRACKER revision: 2026-03-30
> Generated: 2026-03-30 15:41:33 PDT

---

## Table of Contents

  1. [`Open Lightly/App/Open_LightlyApp.swift`](#file-open-lightly-app-open-lightlyapp-swift)
  2. [`Open Lightly/App/ContentView.swift`](#file-open-lightly-app-contentview-swift)
  3. [`Open Lightly/Core/Services/AppState.swift`](#file-open-lightly-core-services-appstate-swift)
  4. [`Open Lightly/Models/Enums/AppEnums.swift`](#file-open-lightly-models-enums-appenums-swift)
  5. [`Open Lightly/Models/Enums/ExperienceType.swift`](#file-open-lightly-models-enums-experiencetype-swift)
  6. [`Open Lightly/Models/Enums/AppTab.swift`](#file-open-lightly-models-enums-apptab-swift)
  7. [`Open Lightly/App/Theme/AppColors.swift`](#file-open-lightly-app-theme-appcolors-swift)
  8. [`Open Lightly/App/Theme/AppFonts.swift`](#file-open-lightly-app-theme-appfonts-swift)
  9. [`Open Lightly/App/Theme/AppTheme.swift`](#file-open-lightly-app-theme-apptheme-swift)
  10. [`Open Lightly/App/Theme/ThemeManager.swift`](#file-open-lightly-app-theme-thememanager-swift)
  11. [`Open Lightly/App/Theme/ThemeModifiers.swift`](#file-open-lightly-app-theme-thememodifiers-swift)
  12. [`Open Lightly/Design/Components/Banners/GuestBannerView.swift`](#file-open-lightly-design-components-banners-guestbannerview-swift)
  13. [`Open Lightly/Design/Components/Buttons/CriticalButton.swift`](#file-open-lightly-design-components-buttons-criticalbutton-swift)
  14. [`Open Lightly/Design/Components/Buttons/GradientButton.swift`](#file-open-lightly-design-components-buttons-gradientbutton-swift)
  15. [`Open Lightly/Design/Components/Buttons/HoloCTAButton.swift`](#file-open-lightly-design-components-buttons-holoctabutton-swift)
  16. [`Open Lightly/Design/Components/Buttons/SafeWordButton.swift`](#file-open-lightly-design-components-buttons-safewordbutton-swift)
  17. [`Open Lightly/Design/Components/Buttons/SelectablePill.swift`](#file-open-lightly-design-components-buttons-selectablepill-swift)
  18. [`Open Lightly/Design/Components/Cards/AtmosphericGhostDeck.swift`](#file-open-lightly-design-components-cards-atmosphericghostdeck-swift)
  19. [`Open Lightly/Design/Components/Cards/CategoryTileView.swift`](#file-open-lightly-design-components-cards-categorytileview-swift)
  20. [`Open Lightly/Design/Components/Cards/CircularArrowView.swift`](#file-open-lightly-design-components-cards-circulararrowview-swift)
  21. [`Open Lightly/Design/Components/Cards/ContextCard.swift`](#file-open-lightly-design-components-cards-contextcard-swift)
  22. [`Open Lightly/Design/Components/Cards/ContextCardStack.swift`](#file-open-lightly-design-components-cards-contextcardstack-swift)
  23. [`Open Lightly/Design/Components/Cards/ContextIntensity.swift`](#file-open-lightly-design-components-cards-contextintensity-swift)
  24. [`Open Lightly/Design/Components/Cards/ContextOption.swift`](#file-open-lightly-design-components-cards-contextoption-swift)
  25. [`Open Lightly/Design/Components/Cards/ConversationCard.swift`](#file-open-lightly-design-components-cards-conversationcard-swift)
  26. [`Open Lightly/Design/Components/Cards/ConversationCardTypes.swift`](#file-open-lightly-design-components-cards-conversationcardtypes-swift)
  27. [`Open Lightly/Design/Components/Cards/FuseTimerView.swift`](#file-open-lightly-design-components-cards-fusetimerview-swift)
  28. [`Open Lightly/Design/Components/Cards/PromptCard.swift`](#file-open-lightly-design-components-cards-promptcard-swift)
  29. [`Open Lightly/Design/Components/Cards/SettingsCard.swift`](#file-open-lightly-design-components-cards-settingscard-swift)
  30. [`Open Lightly/Design/Components/Effects/AuroraGlowField.swift`](#file-open-lightly-design-components-effects-auroraglowfield-swift)
  31. [`Open Lightly/Design/Components/Effects/FlameAura.swift`](#file-open-lightly-design-components-effects-flameaura-swift)
  32. [`Open Lightly/Design/Components/Effects/GlowOrb.swift`](#file-open-lightly-design-components-effects-gloworb-swift)
  33. [`Open Lightly/Design/Components/Effects/HolographicShimmer.swift`](#file-open-lightly-design-components-effects-holographicshimmer-swift)
  34. [`Open Lightly/Design/Components/Effects/LightAuraBloom.swift`](#file-open-lightly-design-components-effects-lightaurabloom-swift)
  35. [`Open Lightly/Design/Components/Effects/LightModeShimmer.swift`](#file-open-lightly-design-components-effects-lightmodeshimmer-swift)
  36. [`Open Lightly/Design/Components/Effects/OnboardingGlowField.swift`](#file-open-lightly-design-components-effects-onboardingglowfield-swift)
  37. [`Open Lightly/Design/Components/Effects/SparkField.swift`](#file-open-lightly-design-components-effects-sparkfield-swift)
  38. [`Open Lightly/Design/Components/Input/InteractiveField.swift`](#file-open-lightly-design-components-input-interactivefield-swift)
  39. [`Open Lightly/Design/Components/Input/RatingButtonGroup.swift`](#file-open-lightly-design-components-input-ratingbuttongroup-swift)
  40. [`Open Lightly/Design/Components/Input/ToggleRow.swift`](#file-open-lightly-design-components-input-togglerow-swift)
  41. [`Open Lightly/Design/Components/Navigation/OnboardingFooter.swift`](#file-open-lightly-design-components-navigation-onboardingfooter-swift)
  42. [`Open Lightly/Design/Components/Navigation/OnboardingNavBar.swift`](#file-open-lightly-design-components-navigation-onboardingnavbar-swift)
  43. [`Open Lightly/Design/Components/Progress/OnboardingProgressBar.swift`](#file-open-lightly-design-components-progress-onboardingprogressbar-swift)
  44. [`Open Lightly/Design/Components/Progress/OrbitIndicator.swift`](#file-open-lightly-design-components-progress-orbitindicator-swift)
  45. [`Open Lightly/Design/Components/Progress/ProgressBar.swift`](#file-open-lightly-design-components-progress-progressbar-swift)
  46. [`Open Lightly/Design/Components/Progress/ProgressRingView.swift`](#file-open-lightly-design-components-progress-progressringview-swift)
  47. [`Open Lightly/Design/Components/Progress/ScoreRing.swift`](#file-open-lightly-design-components-progress-scorering-swift)
  48. [`Open Lightly/Design/Components/Progress/SpectrumBar.swift`](#file-open-lightly-design-components-progress-spectrumbar-swift)
  49. [`Open Lightly/Design/Components/Text/GradientText.swift`](#file-open-lightly-design-components-text-gradienttext-swift)
  50. [`Open Lightly/Design/Components/Text/KeywordHighlightText.swift`](#file-open-lightly-design-components-text-keywordhighlighttext-swift)
  51. [`Open Lightly/Design/Components/Text/LivingText.swift`](#file-open-lightly-design-components-text-livingtext-swift)
  52. [`Open Lightly/Design/Components/CardStyle.swift`](#file-open-lightly-design-components-cardstyle-swift)
  53. [`Open Lightly/Design/Components/FilamentMode.swift`](#file-open-lightly-design-components-filamentmode-swift)
  54. [`Open Lightly/Design/Components/NavArrow.swift`](#file-open-lightly-design-components-navarrow-swift)
  55. [`Open Lightly/Design/Components/OrbitSparkBorderView.swift`](#file-open-lightly-design-components-orbitsparkborderview-swift)
  56. [`Open Lightly/Design/Components/PillBorder.swift`](#file-open-lightly-design-components-pillborder-swift)
  57. [`Open Lightly/Design/Components/ScreenshotProtectionModifier.swift`](#file-open-lightly-design-components-screenshotprotectionmodifier-swift)
  58. [`Open Lightly/Design/Components/SectionHeader.swift`](#file-open-lightly-design-components-sectionheader-swift)
  59. [`Open Lightly/Design/Components/OrbitSpark.metal`](#file-open-lightly-design-components-orbitspark-metal)

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

## File: `Open Lightly/App/Theme/AppColors.swift` {#file-open-lightly-app-theme-appcolors-swift}

```swift
//
//  AppColors.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        guard Scanner(string: hex).scanHexInt64(&int) else {
            self = .black
            return
        }
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            self = .black
            return
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - ──────────────────────────────────────────────
// AppColors.swift
// Open Lightly
//
// Design System: Hot Border × Clash Display × Gradient Keywords
// Card intensity scales 1–8 with prompt difficulty
// ──────────────────────────────────────────────────────

// MARK: - App Colors

struct AppColors {

    // ─────────────────────────────────────────────
    // MARK: Core Spectrum
    // The 3 anchor colors — used for borders,
    // gradient text highlights, glows
    // Gradient direction: 135° (top-left -> bottom-right)
    // ─────────────────────────────────────────────

    static let cyan       = Color(hex: "00C2FF")
    static let purple     = Color(hex: "6C3AE0")
    static let magenta    = Color(hex: "FF006A")

    /// Soft magenta variant — used in shimmer gradients and atmospheric fills
    static let pink       = Color(hex: "FF2D8A")

    /// Deep atmospheric blue — used in glow field floor washes
    static let deepBlue   = Color(hex: "0078FF")

    /// Violet — between purple and blue, used in warm-tier pill gradients
    static let violet = Color(hex: "7C3AED")
    static let electricViolet = Color(hex: "8B5CF6")
    static let deepPurple    = Color(hex: "3D1F8F")
    
    /// Electric purple — vivid gradient midpoint, LivingText only
    static let purpleVivid = Color(hex: "9333EA")
    
    static let purpleBright = Color(hex: "C084FC")

    // Lighter variants — gradient text on keywords, badges
    static let cyanLight    = Color(hex: "4DD8FF")
    static let purpleLight  = Color(hex: "A78BFA")
    static let magentaLight = Color(hex: "FF4D94")

    // Darker variants — tinted backgrounds, deep accents
    static let cyanDark    = Color(hex: "0891B2")
    static let purpleDark  = Color(hex: "1A1A5E")
    static let magentaDark = Color(hex: "BE185D")

    // ─────────────────────────────────────────────
    // MARK: Backgrounds
    // Page -> Card -> Surface (lightest)
    // ─────────────────────────────────────────────

    /// Main app background
    static let pageBg = Color(hex: "030305")

    /// Default card interior (levels 1–4)
    // DARK-FILL-FIX: was #050507 — only 2/255 delta from pageBg.
    // At disabled opacity 0.45 the button was invisible.
    // #12111A holds shape identity at 0.45 while staying dark.
    static let cardBg = Color(hex: "12111A")

    /// Elevated surfaces, sheets, modals
    // DARK-FILL-FIX: was #08080C — 5/255 delta from pageBg.
    // Invisible at 0.45 opacity. #1A1825 holds pill shape.
    static let surfaceBg = Color(hex: "1A1825")

    /// Slightly raised elements (input fields, etc)
    static let surfaceRaised = Color(hex: "0C0C10")

    // Tinted card backgrounds (for intensity levels 5–8)
    static let tintCyan    = Color(hex: "061018")
    static let tintPurple  = Color(hex: "080614")
    static let tintMagenta = Color(hex: "120610")
    static let tintNavy    = Color(hex: "0A1018")
    static let tintIndigo  = Color(hex: "0A0820")
    static let tintPlum    = Color(hex: "180818")

    // Supernova (ultimate) gradient layers — deepest possible darks
    static let tintSupernovaA = Color(hex: "081420")
    static let tintSupernovaB = Color(hex: "0C0624")
    static let tintSupernovaC = Color(hex: "1A0620")
    static let tintSupernovaD = Color(hex: "1C0818")

    // ─────────────────────────────────────────────
    // MARK: Text
    // ─────────────────────────────────────────────

    /// Primary text — prompt content, headings
    static let textPrimary   = Color(hex: "E8E8F0")

    /// Secondary text — descriptions, labels
    static let textSecondary = Color(hex: "AAAABC")

    /// Tertiary text — timestamps, meta
    static let textTertiary  = Color(hex: "666680")

    /// Quaternary text — pronoun hint, subtle placeholders
    static let textQuaternary = Color(red: 0.42, green: 0.42, blue: 0.50)

    /// Muted text — disabled states, subtle hints
    static let textMuted     = Color.white.opacity(0.20)

    /// Badge/tag text
    static let textBadge     = Color(hex: "5BB8CC")

    // ─────────────────────────────────────────────
    // MARK: Borders
    // ─────────────────────────────────────────────

    /// Default subtle border
    static let border        = Color.white.opacity(0.06)

    /// Hover/active border
    static let borderHover   = Color.white.opacity(0.10)

    /// Prominent border
    static let borderActive  = Color.white.opacity(0.15)

    // ─────────────────────────────────────────────
    // MARK: UI Elements
    // ─────────────────────────────────────────────

    /// Badge background
    static let badgeBg       = cyan.opacity(0.08)

    /// Ghost button border
    static let btnGhostBorder = Color.white.opacity(0.06)

    /// Ghost button text
    static let btnGhostText   = Color(hex: "444444")

    /// Toggle / switch active
    static let toggleActive   = cyan

    /// Destructive / warning
    static let destructive    = Color(hex: "FF4444")

    /// Success / confirmed
    static let success        = Color(hex: "00CC88")

    /// Off-spectrum utility — safety only (safe word, hard no, cool off)
    static let gold       = Color(hex: "C8960A")
    static let goldLight  = Color(hex: "E2B93B")
    static let goldDark   = Color(hex: "8B6914")
    static let glowGold   = gold
    // ── Warm Amber — Light Mode Progress Bar ──────────────────────────
    // Used in OnboardingProgressBar fill and bloom layers in light mode only.
    // Source: HTML section 9A stat gradient — #E07020 "amber" stop.
    // Do NOT use these in aurora blobs — those use gold (#C8960A).
    /// Hot orange-amber — bright fill leading stop and bloom core
    static let orangeHot  = Color(hex: "E07020")
    /// Deep orange-amber — fill trailing anchor and bloom atmosphere
    static let orangeDeep = Color(hex: "C8710A")
    // ────

    /// Glow aliases — reference the canonical spectrum tokens
    static let glowCyan    = cyan
    static let glowMagenta = magenta
    static let glowPurple  = purple

    /// Shadow colors
    static let shadowDeep  = Color.black.opacity(0.50)
    static let shadowLight = Color.black.opacity(0.25)

    // ─────────────────────────────────────────────
    // MARK: Gradients
    // ─────────────────────────────────────────────

    /// Card border gradient — the "Hot Border"
    /// Used on every prompt card at full opacity
    static let spectrumBorder = LinearGradient(
        colors: [cyan, purple, magenta],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Keyword highlight gradient — applied to select words
    /// Use with .foregroundStyle() on Text views
    static let spectrumText = LinearGradient(
        colors: [cyan, purpleLight, magenta],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Primary button fill — subtle gradient
    static let btnPrimaryFill = LinearGradient(
        colors: [
            cyan.opacity(0.12),
            magenta.opacity(0.10)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Max-intensity CTA — used sparingly (level 8, special)
    static let btnMaxFill = LinearGradient(
        colors: [cyan, purple, magenta],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Top-edge ambient wash (cards level 2+)
    static let topCyanWash = LinearGradient(
        colors: [
            cyan.opacity(0.04),
            Color.clear
        ],
        startPoint: .top,
        endPoint: .center
    )

    // MARK: - Canonical Aliases (Batch 6 spec)
    static var card: Color { cardBg }
    static var background: Color { pageBg }
    static var cardElevated: Color { surfaceRaised }

    // MARK: - Spectrum Gradient (Batch 6 spec)
    static var spectrumGradient: LinearGradient {
        LinearGradient(
            colors: [cyan, purple, magenta],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // ─────────────────────────────────────────────
    // MARK: Light Mode — Warm Aurora
    //
    // Background: #F8F6EE (warm cream — never change)
    // Aurora palette: Magenta / Purple / Gold — no cyan
    // All tokens prefixed with light* or aurora* to
    // prevent any collision with dark mode tokens.
    // ─────────────────────────────────────────────

    // Backgrounds
    /// Warm cream — the one true light mode page background
    static let lightPageBg    = Color(hex: "F8F6EE")

    /// Pure white — card interiors lift off the cream naturally
    static let lightCardBg    = Color(hex: "FFFFFF")

    /// Inset fields — slightly deeper than page, clearly recessed
    static let lightSurfaceBg = Color(hex: "F2EFE6")

    // Text
    /// Near-black — primary headings and body on cream
    static let lightTextPrimary   = Color(hex: "1A1A1E")

    /// 50% near-black — labels, descriptions
    static let lightTextSecondary = Color(hex: "1A1A1E").opacity(0.50)

    /// 30% near-black — timestamps, meta, hints
    static let lightTextTertiary  = Color(hex: "1A1A1E").opacity(0.30)

    // Borders
    /// Default subtle border on cream surfaces
    static let lightBorder      = Color.black.opacity(0.06)

    /// Hover / focus border on cream surfaces
    static let lightBorderHover = Color.black.opacity(0.10)

    // Frosted glass fills
    // Used with .background + backdrop blur in SwiftUI.
    // These are NOT opaque — the aurora bleeds through intentionally.
    /// Glass card fill — 58% white over aurora
    // OPACITY-FIX: was Color.white.opacity(0.58)
    static let lightFrostCard    = Color(red: 0.989, green: 0.985, blue: 0.972)

    /// Pill fill — unselected state on cream
    // OPACITY-FIX: was Color.white.opacity(0.55) — semi-transparent
    // whites multiply with container opacity causing pills to vanish
    // at disabled 0.45. Opaque equivalent preserves identical appearance
    // at full opacity and holds at any container opacity.
    // TINT-FIX: was (0.988, 0.984, 0.970) near-white — shimmer had nothing
    // to push against. Now a soft lavender-blush sits visibly on
    // lightPageBg (#F8F6EE). Parallel role to surfaceBg (#1A1825) in dark.
    // PILL-FILL-FIX: was (0.945, 0.925, 0.960) — near-white, indistinguishable
    // from lightPageBg (#F8F6EE). Shimmer had nothing to push against.
    // Now a visible lavender — parallel role to surfaceBg (#1A1825) in dark mode.
    // The shimmer sweeps over this tinted base the same way HolographicShimmer
    // sweeps over the deep purple surfaceBg.
    static let lightFrostPill    = Color(red: 0.910, green: 0.875, blue: 0.945)

    /// Selected pill fill — slightly more opaque for legibility
    // PILL-FILL-FIX: was (0.950, 0.922, 0.968) — barely distinguishable from
    // lightFrostPill. Selected state had no visual lift over unselected.
    // Now a visible rose-blush — selected reads richer and warmer than unselected.
    // Contrast between selected/unselected mirrors dark mode's surfaceBg delta.
    static let lightFrostPillSel = Color(red: 0.958, green: 0.875, blue: 0.925)

    /// CTA button fill — frosted, never fully opaque
    // OPACITY-FIX: was Color.white.opacity(0.70)
    static let lightFrostCTA     = Color(red: 0.992, green: 0.990, blue: 0.980)

    /// CTA button base fill — opaque rose so button reads
    /// correctly at both full and 0.45 disabled opacity.
    /// Harmonises with LightModeShimmer's purple/magenta/gold tints.
    static let lightCTAFill      = Color(red: 0.98, green: 0.91, blue: 0.93)

    // Floating label colors
    /// Focused floating label — magentaDark reads well on cream, still spectrum
    static let lightLabelFocused  = magentaDark  // #BE185D

    /// Hint text — "so we get it right", helper copy
    static let lightHintText      = magentaDark.opacity(0.50)

    // Aurora atmosphere blobs
    // Four colors that pool in corners behind frosted cards.
    // Opacity intentionally low — these are felt, not seen.
    static let auroraBlob1 = magenta.opacity(0.09)    // magenta — top right
    static let auroraBlob2 = purple.opacity(0.08)     // purple  — bottom left
    static let auroraBlob3 = gold.opacity(0.07)       // gold    — bottom right
    static let auroraBlob4 = pink.opacity(0.06)       // pink    — mid left

    // Aurora shadow spread
    // On light surfaces, shadow IS the glow.
    // These replace the cyan/magenta bloom shadows from dark mode.
    static let lightShadowMagenta = magenta.opacity(0.18)
    static let lightShadowPurple  = purple.opacity(0.12)
    static let lightShadowGold    = gold.opacity(0.07)

    // MARK: - Light Mode Card Text
    // Warm wine-toned text tokens for OnboardingGroundRulesView cards.
    // Used for card title and detail body on rose-blush fill in light mode only.

    /// Dark rose — deep wine for headlines on rose fill (#3D1A26)
    static let lightHeadlineDarkRose = Color(red: 0.24, green: 0.10, blue: 0.15)

    /// Wine dark — card title on rose fill (#5C1F35)
    static let lightCardTitle  = Color(red: 0.36, green: 0.12, blue: 0.21)

    /// Mid wine — card detail body on rose fill (#7A2D45)
    static let lightCardDetail = Color(red: 0.478, green: 0.176, blue: 0.271)

    /// Icon badge background — magenta tint (18% opacity)
    static let lightIconBgMagenta = Color(red: 1.00, green: 0.00, blue: 0.42).opacity(0.18)

    /// Icon badge background — orangeHot tint (14% opacity)
    static let lightIconBgOrange  = Color(red: 1.00, green: 0.30, blue: 0.00).opacity(0.14)

    /// Icon badge background — gold tint (14% opacity)
    static let lightIconBgGold    = Color(red: 0.78, green: 0.59, blue: 0.04).opacity(0.14)

    /// Card fill — barely blush (#FFF4F6)
    static let lightCardFill = Color(red: 1.0, green: 0.957, blue: 0.965)

    static let lightFrostPillCustom = Color(red: 0.868, green: 0.848, blue: 0.908)
    /// Card shadow — warm amber mid
    static let lightCardShadowMagenta = Color(red: 0.78, green: 0.39, blue: 0.20)

    /// Card shadow — warm orange
    static let lightCardShadowOrange  = Color(red: 1.00, green: 0.39, blue: 0.20)

    /// Wine dark — unselected pill / CTA label on light surfaces (#703040)
    static let wineDark = Color(red: 0.44, green: 0.07, blue: 0.18)

    // ─────────────────────────────────────────────
    // MARK: Universal Gradient Border
    //
    // One gradient border used on ALL screens in both
    // dark and light mode. Replaces per-mode branching
    // on borders — the gradient works on both surfaces.
    //
    // Dark:  full spectrum (cyan → purple → magenta)
    // Light: warm aurora  (purple → magenta → gold)
    //        No cyan — cyan reads too clinical on cream.
    //
    // Usage: .pillBorder() calls this via PillBorder.swift
    //        .warmAuroraBorder() calls the light variant
    //        Both live in PillBorder.swift
    // ─────────────────────────────────────────────

    /// Light mode border gradient — warm aurora
    /// purple → magentaLight → gold, topLeading → bottomTrailing
    /// Matches the aurora atmosphere palette exactly
    static let warmAuroraBorder = LinearGradient(
        colors: [purple, magenta, gold],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Light mode gradient text — for "acquainted." and keyword highlights
    /// purple → purpleLight → magentaLight
    /// Stays within the purple-original blend, warm but not jarring on cream
    static let warmAuroraText = LinearGradient(
        colors: [purple, purpleLight, magentaLight],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Light mode shimmer sweep colors — used in LightModeShimmer.swift
    /// Same warm palette at low opacity — not the full spectrum blast
    static let lightShimmerColors: [Color] = [
        purple.opacity(0.22),
        magenta.opacity(0.20),
        gold.opacity(0.18),
        magenta.opacity(0.18),
        purple.opacity(0.22),
    ]

    // lightPillShimmerColors — higher opacity than
    // lightShimmerColors. Used on interactive surfaces
    // (selected pills, active input borders) where the
    // shimmer needs to be as visible as HolographicShimmer
    // is in dark mode. lightShimmerColors remains unchanged
    // for background wash usage.
    static let lightPillShimmerColors: [Color] = [
        AppColors.magenta.opacity(0.50),
        AppColors.gold.opacity(0.55),
        AppColors.magenta.opacity(0.45),
        AppColors.goldLight.opacity(0.50),
        AppColors.magenta.opacity(0.50),
    ]

    // ─────────────────────────────────────────────
    // MARK: Light-mode surface tokens
    // ─────────────────────────────────────────────

    /// Slightly off-white field background for light mode.
    /// Sits above cardSurfaceLight without blending in.
    /// Parallel to dark-mode kFieldBG = white.opacity(0.07).
    static let fieldBgLight     = Color.white.opacity(0.82)

    /// Structural 1pt border for cards and fields in light mode.
    /// opacity(0.14) mirrors LivingText static shadow opacity(0.18) —
    /// visual weight matches LT-G-03: structural, not atmospheric.
    static let borderLight      = purple.opacity(0.14)

    /// Frosted white lift for the glass card surface in light mode.
    /// 0.72 lets the light atmosphere ellipse breathe through without
    /// muddying field fills inside the card.
    static let cardSurfaceLight = Color.white.opacity(0.72)

    /// Semantic blue — used in dark-mode atmosphere ellipse gradient.
    static let blue             = Color.blue
}

// MARK: - ──────────────────────────────────────────────
// Card Intensity System
// Maps prompt difficulty -> visual intensity
// ──────────────────────────────────────────────────────

enum CardIntensity: Int, CaseIterable, Identifiable {
    case void        = 1
    case deepOcean   = 2
    case emberFloor  = 3
    case split       = 4
    case nebula      = 5
    case auroraBand  = 6
    case deepSpace   = 7
    case supernova   = 8

    var id: Int { rawValue }

    // ─────────────────────────────────────────────
    // MARK: Mapping from prompt data
    // ─────────────────────────────────────────────

    static func from(difficulty: String) -> CardIntensity {
        switch difficulty.lowercased() {
        case "easy":        return .void
        case "light":       return .deepOcean
        case "medium":      return .split
        case "deep":        return .nebula
        case "sensitive":   return .deepSpace
        case "ultimate":    return .supernova
        default:            return .deepOcean
        }
    }

    static func from(score: Int) -> CardIntensity {
        switch score {
        case 1...2:  return .void
        case 3:      return .deepOcean
        case 4:      return .emberFloor
        case 5:      return .split
        case 6:      return .nebula
        case 7:      return .auroraBand
        case 8:      return .deepSpace
        case 9...10: return .supernova
        default:     return .deepOcean
        }
    }

    // ─────────────────────────────────────────────
    // MARK: Background
    // ─────────────────────────────────────────────

    var backgroundColor: Color {
        switch self {
        case .void, .deepOcean, .emberFloor, .split, .auroraBand:
            return AppColors.cardBg
        case .nebula:
            return AppColors.tintCyan
        case .deepSpace:
            return AppColors.tintNavy
        case .supernova:
            return AppColors.tintIndigo
        }
    }

    var backgroundGradient: LinearGradient? {
        switch self {
        case .void, .deepOcean, .emberFloor, .split, .auroraBand:
            return nil
        case .nebula:
            return LinearGradient(
                colors: [AppColors.tintCyan, AppColors.tintPurple, AppColors.tintMagenta],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .deepSpace:
            return LinearGradient(
                colors: [AppColors.tintNavy, AppColors.tintIndigo, AppColors.tintPlum],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .supernova:
            return LinearGradient(
                colors: [
                    AppColors.tintSupernovaA,
                    AppColors.tintSupernovaB,
                    AppColors.tintSupernovaC,
                    AppColors.tintSupernovaD
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    var usesGradientBackground: Bool {
        rawValue >= 5
    }

    // ─────────────────────────────────────────────
    // MARK: Radial Wash Overlays
    // ─────────────────────────────────────────────

    var cyanWash: (x: CGFloat, y: CGFloat, opacity: Double)? {
        switch self {
        case .void:         return nil
        case .deepOcean:    return (x: 0.0, y: 1.0, opacity: 0.08)
        case .emberFloor:   return nil
        case .split:        return (x: 0.1, y: 0.0, opacity: 0.07)
        case .nebula:       return (x: 0.15, y: 0.2, opacity: 0.06)
        case .auroraBand:   return nil
        case .deepSpace:    return (x: 0.2, y: 0.1, opacity: 0.08)
        case .supernova:    return (x: 0.1, y: 0.0, opacity: 0.10)
        }
    }

    var magentaWash: (x: CGFloat, y: CGFloat, opacity: Double)? {
        switch self {
        case .void, .deepOcean: return nil
        case .emberFloor:       return (x: 0.5, y: 1.1, opacity: 0.09)
        case .split:            return (x: 0.9, y: 1.0, opacity: 0.06)
        case .nebula:           return (x: 0.85, y: 0.8, opacity: 0.05)
        case .auroraBand:       return nil
        case .deepSpace:        return (x: 0.8, y: 0.9, opacity: 0.07)
        case .supernova:        return (x: 0.9, y: 1.0, opacity: 0.09)
        }
    }

    // ─────────────────────────────────────────────
    // MARK: Glow / Shadow
    // ─────────────────────────────────────────────

    var glowRadius: CGFloat {
        switch self {
        case .void, .deepOcean, .emberFloor:  return 30
        case .split, .nebula, .auroraBand:    return 40
        case .deepSpace:                       return 45
        case .supernova:                       return 60
        }
    }

    var glowMultiplier: Double {
        switch self {
        case .void:        return 0.6
        case .deepOcean:   return 0.8
        case .emberFloor:  return 0.8
        case .split:       return 0.9
        case .nebula:      return 1.0
        case .auroraBand:  return 0.9
        case .deepSpace:   return 1.1
        case .supernova:   return 1.3
        }
    }

    var cyanGlowOpacity: Double    { 0.08 * glowMultiplier }
    var magentaGlowOpacity: Double { 0.06 * glowMultiplier }

    // ─────────────────────────────────────────────
    // MARK: Display Helpers
    // ─────────────────────────────────────────────

    var displayName: String {
        switch self {
        case .void:        return "Void"
        case .deepOcean:   return "Deep Ocean"
        case .emberFloor:  return "Ember Floor"
        case .split:       return "Split"
        case .nebula:      return "Nebula"
        case .auroraBand:  return "Aurora Band"
        case .deepSpace:   return "Deep Space"
        case .supernova:   return "Supernova"
        }
    }

    var difficultyLabel: String {
        switch self {
        case .void, .deepOcean:         return "Easy"
        case .emberFloor, .split:       return "Medium"
        case .nebula, .auroraBand:      return "Deep"
        case .deepSpace:                return "Sensitive"
        case .supernova:                return "Ultimate"
        }
    }
}

```

---

## File: `Open Lightly/App/Theme/AppFonts.swift` {#file-open-lightly-app-theme-appfonts-swift}

```swift
//  AppFonts.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import SwiftUI

struct AppFonts {
    // MARK: - Display Font (Clash Display)
    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        switch weight {
        case .bold:
            return Font.custom("ClashDisplay-Bold", size: size)
        case .semibold:
            return Font.custom("ClashDisplay-Semibold", size: size)
        case .medium:
            return Font.custom("ClashDisplay-Medium", size: size)
        default:
            return Font.system(size: size, weight: .bold, design: .default)
        }
    }

    // MARK: - Body Font (Switzer)
    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .regular:
            return Font.custom("Switzer-Regular", size: size)
        case .medium:
            return Font.custom("Switzer-Medium", size: size)
        case .semibold:
            return Font.custom("Switzer-Semibold", size: size)
        case .bold:
            return Font.custom("Switzer-Bold", size: size)
        default:
            return Font.system(size: size, weight: .regular, design: .default)
        }
    }

    // MARK: - Semantic Tokens
    static var heroTitle: Font { display(42, weight: .bold) }
    static var cardTitle: Font { display(22, weight: .semibold) }
    static var sectionHeading: Font { display(20, weight: .medium) }
    static var bodyText: Font { body(16, weight: .regular) }
    static var bodyMedium: Font { body(15, weight: .medium) }
    static var caption: Font { body(13, weight: .regular) }
    static var overline: Font { body(11, weight: .semibold) }
    static var buttonLabel: Font { body(14, weight: .semibold) }

    // MARK: - Debug Font List
    static func debugFontList() {
        for family in UIFont.familyNames.sorted() {
            print("\n\(family)")
            for name in UIFont.fontNames(forFamilyName: family) {
                print("  \(name)")
            }
        }
    }

    static var prompt: Font          { display(17, weight: .medium) }
    static var promptHighlight: Font { display(17, weight: .semibold) }
    static var badge: Font           { body(10, weight: .medium) }
    static var button: Font          { body(11, weight: .medium) }
    static var meta: Font            { body(10, weight: .regular) }
    static var sectionHeader: Font   { display(13, weight: .medium) }
    static var screenTitle: Font     { display(24, weight: .semibold) }
    static var label: Font           { body(10, weight: .semibold) }
    static var tabLabel: Font        { body(10, weight: .medium) }
    static var scoreDisplay: Font    { display(32, weight: .bold) }
    static var ctaLabel: Font        { body(16, weight: .semibold) }
}

```

---

## File: `Open Lightly/App/Theme/AppTheme.swift` {#file-open-lightly-app-theme-apptheme-swift}

```swift
//
//  AppTheme.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import SwiftUI

// MARK: - Theme Mode

enum ThemeMode: String, CaseIterable, Identifiable {
    case system
    case light
    case amoled

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "System"
        case .light:  return "Light"
        case .amoled: return "Dark"
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light:  return "sun.max.fill"
        case .amoled: return "moon.fill"
        }
    }
}

// MARK: - Color Palette

struct AppPalette {
    let bg: Color
    let bgElevated: Color
    let surface1: Color
    let surface2: Color
    let surface3: Color

    let border: Color
    let borderSubtle: Color

    let text: Color
    let textSecondary: Color
    let textMuted: Color

    let success: Color
    let successDim: Color
    let error: Color
    let errorDim: Color

    /// UI accent — links, active states, highlights
    let cyan: Color
    /// UI accent — CTAs, emphasis, warnings
    let magenta: Color
    /// Decorative only — spectrum bar, score ring, flag swatch
    let navy: Color
    let gold: Color

    let glowOpacity: Double
    let glowCyan: Color
    let glowMagenta: Color
    let glowGold: Color

    let isAmoled: Bool
}

// MARK: - Computed Gradients

extension AppPalette {
    /// Spectrum bar: cyan -> magenta -> navy (decorative)
    var spectrumGradient: LinearGradient {
        LinearGradient(
            colors: [cyan, magenta, navy],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    /// Primary CTA: cyan -> magenta (no navy)
    var buttonGradient: LinearGradient {
        LinearGradient(
            colors: [cyan, magenta],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Score ring: full 3-color polyam sweep (decorative)
    var ringGradient: AngularGradient {
        AngularGradient(
            colors: [cyan, magenta, navy, cyan],
            center: .center
        )
    }

    /// Card border — hairline white on AMOLED, warm gray on light
    var cardBorder: Color {
        isAmoled ? .white.opacity(0.08) : border
    }
}

// MARK: - Light Palette

extension AppPalette {
    static let light = AppPalette(
        bg:            Color(hex: "F8F7F4"),
        bgElevated:    .white,
        surface1:      .white,
        surface2:      Color(hex: "F3F1ED"),
        surface3:      Color(hex: "E8E5DF"),
        border:        Color(hex: "E0DDD6"),
        borderSubtle:  Color(hex: "EAE7E1"),
        text:          Color(hex: "1A1918"),
        textSecondary: Color(hex: "5C5955"),
        textMuted:     Color(hex: "9E9A92"),
        success:       Color(hex: "14B866"),
        successDim:    Color(hex: "14B866").opacity(0.1),
        error:         Color(hex: "DC4444"),
        errorDim:      Color(hex: "DC4444").opacity(0.1),
        cyan:          Color(hex: "0891B2"),
        magenta:       Color(hex: "BE185D"),
        navy:          Color(hex: "1A3A8F"),
        gold:          Color(hex: "B8860B"),
        glowOpacity:   0.06,
        glowCyan:      Color(hex: "0891B2").opacity(0.10),
        glowMagenta:   Color(hex: "BE185D").opacity(0.08),
        glowGold:      Color(hex: "B8860B").opacity(0.08),
        isAmoled:      false
    )
}

// MARK: - AMOLED Palette

extension AppPalette {
    static let amoled = AppPalette(
        bg:            .black,
        bgElevated:    .black,
        surface1:      Color(hex: "0A0A10"),
        surface2:      Color(hex: "101018"),
        surface3:      Color(hex: "18181F"),
        border:        .white.opacity(0.08),
        borderSubtle:  .white.opacity(0.05),
        text:          Color(hex: "F4F3F9"),
        textSecondary: Color(hex: "8A88A0"),
        textMuted:     Color(hex: "4A485C"),
        success:       Color(hex: "5CE0A0"),
        successDim:    Color(hex: "5CE0A0").opacity(0.10),
        error:         Color(hex: "EF6B6B"),
        errorDim:      Color(hex: "EF6B6B").opacity(0.20),
        cyan:          Color(hex: "5ED0EE"),
        magenta:       Color(hex: "F472AD"),
        navy:          Color(hex: "9494D0"),
        gold:          Color(hex: "FFD700"),
        glowOpacity:   0.18,
        glowCyan:      Color(hex: "5ED0EE").opacity(0.20),
        glowMagenta:   Color(hex: "F472AD").opacity(0.20),
        glowGold:      Color(hex: "FFD700").opacity(0.20),
        isAmoled:      true
    )
}

```

---

## File: `Open Lightly/App/Theme/ThemeManager.swift` {#file-open-lightly-app-theme-thememanager-swift}

```swift
//
//  ThemeManager.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import SwiftUI

@Observable
class ThemeManager {

    var mode: ThemeMode {
        didSet {
            UserDefaults.standard.set(mode.rawValue, forKey: "appThemeMode")
        }
    }

    init() {
        let saved = UserDefaults.standard.string(forKey: "appThemeMode") ?? "system"
        self.mode = ThemeMode(rawValue: saved) ?? .system
    }

    func palette(for systemScheme: ColorScheme) -> AppPalette {
        switch mode {
        case .light:  return .light
        case .amoled: return .amoled
        case .system: return systemScheme == .dark ? .amoled : .light
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch mode {
        case .system: return nil
        case .light:  return .light
        case .amoled: return .dark
        }
    }
}

// MARK: - Environment Key

private struct PaletteKey: EnvironmentKey {
    static let defaultValue: AppPalette = .light
}

extension EnvironmentValues {
    var theme: AppPalette {
        get { self[PaletteKey.self] }
        set { self[PaletteKey.self] = newValue }
    }
}

```

---

## File: `Open Lightly/App/Theme/ThemeModifiers.swift` {#file-open-lightly-app-theme-thememodifiers-swift}

```swift
//
//  ThemeModifiers.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import SwiftUI

// MARK: - Root Modifier

struct ThemedRootModifier: ViewModifier {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.colorScheme) private var systemScheme

    func body(content: Content) -> some View {
        let palette = themeManager.palette(for: systemScheme)
        content
            .environment(\.theme, palette)
            .preferredColorScheme(themeManager.preferredColorScheme)
    }
}

extension View {
    func themedRoot() -> some View {
        modifier(ThemedRootModifier())
    }
}

// MARK: - Card Modifier

struct ThemedCardModifier: ViewModifier {
    @Environment(\.theme) private var t
    var selected: Bool = false

    func body(content: Content) -> some View {
        content
            .background(t.surface1)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        selected ? t.cyan : t.cardBorder,
                        lineWidth: selected ? 2 : 1.5
                    )
            )
            .shadow(
                color: selected && t.isAmoled
                    ? t.glowCyan
                    : .clear,
                radius: selected ? 8 : 0
            )
    }
}

extension View {
    func themedCard(selected: Bool = false) -> some View {
        modifier(ThemedCardModifier(selected: selected))
    }
}

// MARK: - Conditional Modifier Helper
// Applies a modifier only when `condition` is true.
// Usage: .if(someFlag) { $0.screenshotProtected() }

extension View {
    @ViewBuilder
    func `if`<T: View>(_ condition: Bool, transform: (Self) -> T) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

```

---

## File: `Open Lightly/Design/Components/Banners/GuestBannerView.swift` {#file-open-lightly-design-components-banners-guestbannerview-swift}

```swift
// Design/Components/Banners/GuestBannerView.swift
// Open Lightly
//
// Persistent banner shown at the top of the guest (browsing) shell.
// Tapping "create an account" resets the onboarding gate, returning
// the user to the onboarding flow where they can sign up properly.

import SwiftUI
import OSLog

private let logger = Logger(subsystem: "com.openlightly.app", category: "GuestBannerView")

struct GuestBannerView: View {

    @Environment(AppState.self) private var appState
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        HStack(spacing: 6) {
            Text("You're browsing —")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)

            Button {
                logger.info("Guest tapped create account — resetting onboarding gate")
                appState.experienceType = .soloSingle   // reset to safe default
                hasCompletedOnboarding = false          // returns to onboarding
            } label: {
                HStack(spacing: 3) {
                    Text("create an account to unlock everything")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.cyan)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppColors.cyan)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Create an account to unlock everything")
            .accessibilityHint("Starts the account creation flow")

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(AppColors.surfaceBg)
        .overlay(
            Rectangle()
                .fill(AppColors.border)
                .frame(height: 1),
            alignment: .bottom
        )
    }
}

// MARK: - Preview

#Preview {
    let state = AppState()
    state.experienceType = .browsing
    return VStack(spacing: 0) {
        GuestBannerView()
        Spacer()
    }
    .background(AppColors.pageBg.ignoresSafeArea())
    .environment(state)
    .preferredColorScheme(.dark)
}

```

---

## File: `Open Lightly/Design/Components/Buttons/CriticalButton.swift` {#file-open-lightly-design-components-buttons-criticalbutton-swift}

```swift
//
//  CriticalButton.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//


import SwiftUI

struct CriticalButton: View {
    @Environment(\.theme) private var t
    let title: String
    let icon: String
    var style: CriticalStyle = .neutral
    var action: () -> Void = {}

    enum CriticalStyle {
        case neutral
        case danger
    }

    private var fillColor: Color {
        switch style {
        case .neutral: return t.textSecondary
        case .danger:  return t.error
        }
    }

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(fillColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    fillColor.opacity(t.isAmoled ? 0.18 : 0.08)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(
                    color: t.isAmoled && style == .danger
                        ? t.error.opacity(0.2)
                        : .clear,
                    radius: 8
                )
        }
        .buttonStyle(.plain)
    }
}
```

---

## File: `Open Lightly/Design/Components/Buttons/GradientButton.swift` {#file-open-lightly-design-components-buttons-gradientbutton-swift}

```swift
//
//  GradientButton.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//
//  ✅ Design system audit — verified March 9, 2026
//

import SwiftUI

struct GradientButton: View {
    @Environment(\.theme) private var t
    let title: String
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(t.buttonGradient)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(
                    color: t.isAmoled
                        ? t.glowCyan.opacity(0.5)
                        : t.magenta.opacity(0.2),
                    radius: t.isAmoled ? 16 : 12,
                    y: t.isAmoled ? 0 : 4
                )
                .shadow(
                    color: t.isAmoled
                        ? t.glowMagenta.opacity(0.3)
                        : .clear,
                    radius: 24,
                    y: 0
                )
        }
        .buttonStyle(.plain)
    }
}

struct GradBadge: View {
    @Environment(\.theme) private var t
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 9, weight: .bold))
            .tracking(0.8)
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .background(t.buttonGradient)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

```

---

## File: `Open Lightly/Design/Components/Buttons/HoloCTAButton.swift` {#file-open-lightly-design-components-buttons-holoctabutton-swift}

```swift
// HoloCTAButton.swift
// Open Lightly
//
// Single shared CTA button used across all onboarding screens.
// Supports dark mode (spectrum glow) and light mode (warm aurora).
//
// Dark:  cardBg fill + HolographicShimmer + pillBorder + bloom glow
// Light: lightFrostCTA fill + LightModeShimmer + warmAuroraBorder
//        + shadow spread (shadow IS the glow on cream)
//        + no behind-bloom (invisible on light surfaces)

import SwiftUI

struct HoloCTAButton: View {
    let title: String
    let isEnabled: Bool
    let action: () -> Void
    
    var cornerRadius: CGFloat = 100
    var height: CGFloat = 56
    var lightModeGradient: LinearGradient? = nil

    @Environment(\.colorScheme) private var colorScheme

    // Dark mode color locals — unchanged
    private let cyan    = AppColors.cyan
    private let purple  = AppColors.purple
    private let magenta = AppColors.magenta
    private let pink    = AppColors.pink
    private let ctaBG   = AppColors.cardBg

    @State private var glowPulse:  Bool   = false

    // Convenience
    private var isLight: Bool { colorScheme == .light }

    var body: some View {
        Button(action: {
            guard isEnabled else { return }
            action()
        }, label: {
            ZStack {

                // ── Behind-glow bloom — DARK ONLY ──────────────────
                // Invisible on cream — skipped entirely in light mode.
                if !isLight {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(LinearGradient(
                            colors: [cyan.opacity(0.22), purple.opacity(0.18), magenta.opacity(0.14)],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(height: 34)
                        .blur(radius: 36)
                        .offset(y: 10)
                        .opacity(glowPulse ? 1.0 : 0.65)
                        .allowsHitTesting(false)
                }

                // ── Pill face ───────────────────────────────────────
                ZStack {
                    // Base fill
                    // FILL-FIX: lightFrostCTA was near-white — at 0.45 disabled
                    // opacity the shimmer's pink washed out entirely.
                    // lightCTAFill is opaque rose so the button reads correctly
                    // at both 1.0 (enabled) and 0.45 (disabled) opacity.
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(isLight ? AppColors.lightCTAFill : ctaBG)

                    // Shimmer — warm aurora on light, spectrum on dark
                    if isLight {
                        LightModeShimmer(duration: 8)
                    } else {
                        HolographicShimmer(duration: 6)
                            .opacity(0.50)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: height)
                // Single clipShape clips base + shimmer cleanly
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))

                // ── Border ─────────────────────────────────────────
                // Dark:  .pillBorder()         — cyan → purple → magenta + glow blur
                // Light: .warmAuroraBorder()   — purple → magenta → gold + shadow spread
                // Both called AFTER clipShape so border sits on the edge, not inside
                .if(isLight) { view in
                    view.warmAuroraBorder(cornerRadius: cornerRadius, lineWidth: 3.0, opacity: 0.90)
                }
                .if(!isLight) { view in
                    view.pillBorder(cornerRadius: cornerRadius)
                }
                // Structural visuals always render at full intensity.
                // Disabled dimming handled by outermost container opacity.

                // ── Ambient glow shadows ───────────────────────────
                // Dark:  cyan/purple/magenta glow ring, pulses with glowPulse
                // Light: shadow spread is already handled inside warmAuroraBorder.
                //        These additional shadows deepen the lift on cream.
                if isLight {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.clear)
                        .frame(height: height)
                        .shadow(color: AppColors.magenta.opacity(glowPulse ? 0.22 : 0.14), radius: 10, x: 0, y: 4)
                        .shadow(color: AppColors.purple.opacity(glowPulse ? 0.16 : 0.10),  radius: 20, x: 0, y: 6)
                        .shadow(color: AppColors.gold.opacity(glowPulse ? 0.10 : 0.05),    radius: 8,  x: 0, y: 2)
                } else {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.clear)
                        .frame(height: height)
                        .shadow(color: cyan.opacity(glowPulse ? 0.28 : 0.18),    radius: 10, x: 0, y: 0)
                        .shadow(color: purple.opacity(glowPulse ? 0.22 : 0.14),  radius: 18, x: 0, y: 0)
                        .shadow(color: magenta.opacity(glowPulse ? 0.16 : 0.10), radius: 28, x: 0, y: 0)
                }

                // ── Label ──────────────────────────────────────────
                // Dark:  white
                // Light: lightTextPrimary (#1A1A1E) — white on cream is invisible
                //        Or custom gradient if lightModeGradient is provided
                Text(title)
                    .font(AppFonts.ctaLabel)
                    .foregroundStyle(
                        isLight && lightModeGradient != nil
                            ? AnyShapeStyle(lightModeGradient!)
                            : AnyShapeStyle(colorScheme == .light
                                ? AppColors.wineDark
                                : Color.white)
                    )
            }
            .frame(height: height)
            .overlay {
                GeometryReader { geo in
                    OrbitSparkBorderView(
                        size:         geo.size,
                        cornerRadius: 28,
                        borderWidth:  3,
                        colorScheme:  colorScheme
                    )
                    .allowsHitTesting(false)
                    .opacity(isEnabled ? 1 : 0)
                    .animation(.easeIn(duration: 0.4), value: isEnabled)
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            }
        })
        .buttonStyle(.plain)
        // CONTRAST-FIX: scale + spring makes enabled state snap.
        // 0.98 shrink on disabled reads as "not ready" instantly.
        // Spring on enable feels like the button inflates to life.
        .opacity(isEnabled ? 1.0 : 0.42)
        .scaleEffect(isEnabled ? 1.0 : 0.98)
        .animation(
            .spring(response: 0.35, dampingFraction: 0.75),
            value: isEnabled
        )
        .allowsHitTesting(isEnabled)
        .onAppear {
            // Glow pulse — shadow breathing for both modes
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
    }
}

private struct CTABorderModifier: ViewModifier {
    let isLight: Bool
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        if isLight {
            content.warmAuroraBorder(cornerRadius: cornerRadius, lineWidth: 3.0, opacity: 0.90)
        } else {
            content.pillBorder(cornerRadius: cornerRadius)
        }
    }
}

// MARK: - Previews

#Preview("HoloCTA Dark — enabled") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        HoloCTAButton(title: "Next", isEnabled: true, action: { })
            .padding(.horizontal, 24)
    }
    .preferredColorScheme(.dark)
}

#Preview("HoloCTA Dark — disabled") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        HoloCTAButton(title: "Next", isEnabled: false, action: { })
            .padding(.horizontal, 24)
    }
    .preferredColorScheme(.dark)
}

#Preview("HoloCTA Light — enabled") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        HoloCTAButton(title: "Next", isEnabled: true, action: { })
            .padding(.horizontal, 24)
    }
    .preferredColorScheme(.light)
}

#Preview("HoloCTA Light — disabled") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        HoloCTAButton(title: "Next", isEnabled: false, action: { })
            .padding(.horizontal, 24)
    }
    .preferredColorScheme(.light)
}

```

---

## File: `Open Lightly/Design/Components/Buttons/SafeWordButton.swift` {#file-open-lightly-design-components-buttons-safewordbutton-swift}

```swift
// ✅ Design system audit — verified March 9, 2026
import SwiftUI

// MARK: - SafeWordButton
// Safety feature — always visible, functional, and unmissable
struct SafeWordButton: View {
    let onActivate: () -> Void
    @State private var showConfirmation: Bool = false
    @Environment(\.theme) private var t

    var body: some View {
        Button {
            showConfirmation = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 18, weight: .semibold))
                Text("Safe Word")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(t.gold)
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(t.isAmoled ? t.gold.opacity(0.08) : t.gold.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(t.gold.opacity(0.25), lineWidth: 1.5)
            )
        }
        .alert(
            "Use Safe Word?",
            isPresented: $showConfirmation,
            actions: {
                Button("Pause Session", role: .destructive) {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    showConfirmation = false
                    onActivate()
                }
                Button("Cancel", role: .cancel) {
                    showConfirmation = false
                }
            },
            message: {
                Text("This will pause the session. You can return anytime.")
            }
        )
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        SafeWordButton { print("Safe word activated") }
    }
}

```

---

## File: `Open Lightly/Design/Components/Buttons/SelectablePill.swift` {#file-open-lightly-design-components-buttons-selectablepill-swift}

```swift
// Design/Components/Buttons/SelectablePill.swift
// Open Lightly
//
// Supports dark mode (spectrum glow + flame aura) and
// light mode (warm aurora border + shadow spread).
//
// Dark:  surfaceBg fill + HolographicShimmer + flame aura + spectrum shadows
// Light: lightFrostPill fill + LightModeShimmer + warmAuroraBorder + shadow spread
//        Flame aura skipped — glow is invisible on cream, shadow spread replaces it

import SwiftUI

struct SelectablePill: View {

    enum Intensity: CGFloat {
        case dim   = 0.15
        case warm  = 0.5
        case alive = 1.0
    }

    let label: String
    let isSelected: Bool
    var intensity: Intensity = .warm
    var height: CGFloat = 46
    var fontSize: CGFloat = 15
    var showFlame: Bool = true
    var action: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }

    // ─────────────────────────────────────────────
    // MARK: Dark mode computed properties — unchanged
    // ─────────────────────────────────────────────

    private var shimmerOpacity: CGFloat {
        if isSelected {
            switch intensity {
            case .dim:   return 0.55
            case .warm:  return 0.72
            case .alive: return 0.85
            }
        } else {
            switch intensity {
            case .dim:   return 0.22
            case .warm:  return 0.38
            case .alive: return 0.46
            }
        }
    }

    private var shimmerSpeed: Double {
        switch intensity {
        case .dim:   return 6
        case .warm:  return 4
        case .alive: return 3.5
        }
    }
    
    private var lightShimmerSpeed: Double {
        switch intensity {
        case .dim:   return 6.0
        case .warm:  return 4.0
        case .alive: return 3.5
        }
    }

    private var borderWidth: CGFloat {
        guard isSelected else { return 1.5 }
        switch intensity {
        case .dim:   return 1.5
        case .warm:  return 2.0
        case .alive: return 2.5
        }
    }

    private var borderColor: Color {
        guard isSelected else { return AppColors.borderHover }
        switch intensity {
        case .dim:   return Color.white.opacity(0.12)
        case .warm:  return Color.white.opacity(0.22)
        case .alive: return Color.white.opacity(0.25)
        }
    }

    private var flameFrameHeight: CGFloat {
        switch intensity {
        case .dim:   return 0
        case .warm:  return 90
        case .alive: return 120
        }
    }

    private var lightBloomFrameHeight: CGFloat {
        switch intensity {
        case .dim:   return 0
        case .warm:  return 70
        case .alive: return 100
        }
    }

    // ─────────────────────────────────────────────
    // MARK: Light mode computed properties
    // ─────────────────────────────────────────────
    private var lightShimmerOpacity: CGFloat {
        if isSelected {
            switch intensity {
            case .dim:   return 0.55
            case .warm:  return 0.72
            case .alive: return 0.85
            }
        } else {
            switch intensity {
            case .dim:   return 0.10
            case .warm:  return 0.16
            case .alive: return 0.22
            }
        }
    }

    /// Light mode border opacity — higher than dark because no glow
    /// canvas to boost the visual weight of the border.
    private var lightBorderOpacity: Double {
        if isSelected {
            switch intensity {
            case .dim:   return 0.55
            case .warm:  return 0.78
            case .alive: return 0.90
            }
        } else {
            return 0.40
        }
    }

    /// Light mode border line width — matches warmAuroraBorder defaults.
    private var lightBorderWidth: CGFloat {
        if isSelected {
            switch intensity {
            case .dim:   return 1.5
            case .warm:  return 2.5
            case .alive: return 3.0
            }
        } else {
            return 1.5
        }
    }

    // ─────────────────────────────────────────────
    // MARK: Body
    // ─────────────────────────────────────────────

    var body: some View {
        Button {
            action()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            pillContent
                .modifier(PillShadowModifier(
                    isLight: isLight,
                    isSelected: isSelected,
                    intensity: intensity
                ))
                .background(alignment: .bottom) {
                    flameLayer
                }
                .offset(y: isLight && isSelected ? -1 : 0)
                .animation(.easeOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(.plain)
    }

    private var pillContent: some View {
        Text(label)
            .font(.system(size: fontSize, weight: .medium))
            .foregroundStyle(isLight ? AppColors.wineDark : Color.white)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(isLight
                ? (isSelected
                    ? AppColors.lightFrostPillSel
                    : AppColors.lightFrostPill)   // FIX: was lightSurfaceBg (#F2EFE6)
                                                   // which is near-identical to lightPageBg.
                                                   // lightFrostPill is visibly lavender-tinted
                                                   // so the shimmer has a tinted base to sweep
                                                   // over — same role surfaceBg plays in dark.
                : AppColors.surfaceBg)
            .overlay {
                if isLight {
                    LightModeShimmer(duration: lightShimmerSpeed, usePillColors: true)
                        .opacity(lightShimmerOpacity)
                        .allowsHitTesting(false)
                } else {
                    HolographicShimmer(duration: shimmerSpeed)
                        .opacity(shimmerOpacity)
                        .allowsHitTesting(false)
                }
            }
            .clipShape(Capsule())
            .modifier(PillBorderModifier(
                isLight: isLight,
                isSelected: isSelected,
                darkBorderColor: borderColor,
                darkBorderWidth: borderWidth,
                lightBorderOpacity: lightBorderOpacity,
                lightBorderWidth: lightBorderWidth
            ))
    }

    @ViewBuilder
    private var flameLayer: some View {
        if isSelected && intensity != .dim && showFlame {
            GeometryReader { geo in
                if isLight {
                    LightAuraBloom(intensity: intensity)
                        .frame(
                            width:  geo.size.width * 1.15,
                            height: lightBloomFrameHeight
                        )
                        .position(
                            x: geo.size.width  / 2,
                            y: geo.size.height - lightBloomFrameHeight / 2
                        )
                } else {
                    FlameAura(intensity: intensity)
                        .frame(
                            width:  geo.size.width * 1.2,
                            height: flameFrameHeight
                        )
                        .position(
                            x: geo.size.width  / 2,
                            y: geo.size.height - flameFrameHeight / 2
                        )
                }
            }
            .frame(height: isLight ? lightBloomFrameHeight : flameFrameHeight)
            .allowsHitTesting(false)
            .transition(.opacity.animation(.easeIn(duration: 0.4)))
        }
    }

    // ─────────────────────────────────────────────
    // MARK: Helpers — unchanged from original
    // ─────────────────────────────────────────────

    private var labelColor: Color {
        if isLight {
            return AppColors.wineDark   // selected and unselected both deep wine on cream
        } else {
            return .white
        }
    }

    private func glowColor(_ base: Color, _ dimAlpha: CGFloat, _ warmAlpha: CGFloat, _ aliveAlpha: CGFloat) -> Color {
        switch intensity {
        case .dim:   return base.opacity(dimAlpha)
        case .warm:  return base.opacity(warmAlpha)
        case .alive: return base.opacity(aliveAlpha)
        }
    }

    private func pick(_ dim: CGFloat, _ warm: CGFloat, _ alive: CGFloat) -> CGFloat {
        switch intensity {
        case .dim:   return dim
        case .warm:  return warm
        case .alive: return alive
        }
    }
}

// ─────────────────────────────────────────────
// MARK: PillBorderModifier
// Handles the dark/light border split cleanly
// without .if() helper to avoid redeclaration.
// ─────────────────────────────────────────────

private struct PillBorderModifier: ViewModifier {
    let isLight: Bool
    let isSelected: Bool
    let darkBorderColor: Color
    let darkBorderWidth: CGFloat
    let lightBorderOpacity: Double
    let lightBorderWidth: CGFloat

    func body(content: Content) -> some View {
        if isLight {
            if isSelected {
                // Selected light — magenta-gold gradient border
                content
                    .magentaGoldBorder(
                        cornerRadius: 100,
                        lineWidth: lightBorderWidth,
                        glowRadius: 6,
                        opacity: lightBorderOpacity
                    )
            } else {
                content.overlay(
                    Capsule().strokeBorder(
                        AppColors.lightBorderHover,
                        lineWidth: 1.5
                    )
                )
            }
        } else {
            // Dark — spectrum pillBorder when selected; subtle plain stroke when not
            if isSelected {
                content.pillBorder(cornerRadius: 100, lineWidth: darkBorderWidth, glowRadius: 5, opacity: 0.85)
            } else {
                content.overlay(
                    Capsule().strokeBorder(darkBorderColor, lineWidth: darkBorderWidth)
                )
            }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: PillShadowModifier
// Dark: spectrum glow ring
// Light: warm aurora shadow spread
// ─────────────────────────────────────────────

private struct PillShadowModifier: ViewModifier {
    let isLight: Bool
    let isSelected: Bool
    let intensity: SelectablePill.Intensity

    func body(content: Content) -> some View {
        if isLight {
            // Shadow spread — opacity scales with intensity
            let base: Double = isSelected ? 1.0 : 0.0
            content
                .shadow(color: AppColors.lightShadowMagenta.opacity(base * magentaScale),
                        radius: 8,  x: 0, y: 3)
                .shadow(color: AppColors.lightShadowPurple.opacity(base * purpleScale),
                        radius: 16, x: 0, y: 5)
                .shadow(color: AppColors.lightShadowGold.opacity(base * goldScale),
                        radius: 6,  x: 0, y: 2)
        } else {
            // Dark — original spectrum glow ring, unchanged
            content
                .shadow(color: isSelected ? glowColor(AppColors.purple,  0.20, 0.25, 0.34) : .clear,
                        radius: pick(6,  12, 14))
                .shadow(color: isSelected ? glowColor(AppColors.cyan,    0.0,  0.15, 0.30) : .clear,
                        radius: pick(0,  16, 28))
                .shadow(color: isSelected ? glowColor(AppColors.magenta, 0.0,  0.08, 0.25) : .clear,
                        radius: pick(0,  8,  45))
                .shadow(color: isSelected ? glowColor(AppColors.pink,    0.0,  0.0,  0.12) : .clear,
                        radius: pick(0,  0,  70))
        }
    }

    // Light shadow intensity scales with pill intensity
    private var magentaScale: Double {
        switch intensity { case .dim: return 0.5; case .warm: return 0.9; case .alive: return 1.0 }
    }
    private var purpleScale: Double {
        switch intensity { case .dim: return 0.4; case .warm: return 0.8; case .alive: return 1.0 }
    }
    private var goldScale: Double {
        switch intensity { case .dim: return 0.3; case .warm: return 0.7; case .alive: return 1.0 }
    }

    // Helpers mirror the original SelectablePill private functions
    private func glowColor(_ base: Color, _ d: CGFloat, _ w: CGFloat, _ a: CGFloat) -> Color {
        switch intensity {
        case .dim:   return base.opacity(d)
        case .warm:  return base.opacity(w)
        case .alive: return base.opacity(a)
        }
    }
    private func pick(_ d: CGFloat, _ w: CGFloat, _ a: CGFloat) -> CGFloat {
        switch intensity { case .dim: return d; case .warm: return w; case .alive: return a }
    }
}

// ─────────────────────────────────────────────
// MARK: Previews
// ─────────────────────────────────────────────

#Preview("Dark") {
    VStack(spacing: 12) {
        SelectablePill(label: "She/Her",    isSelected: true,  intensity: .alive) { }
        SelectablePill(label: "He/Him",     isSelected: false, intensity: .warm)  { }
        SelectablePill(label: "They/Them",  isSelected: true,  intensity: .warm)  { }
        SelectablePill(label: "Curious",    isSelected: true,  intensity: .dim)   { }
    }
    .padding(24)
    .background(AppColors.pageBg)
    .preferredColorScheme(.dark)
}

#Preview("Light") {
    VStack(spacing: 12) {
        SelectablePill(label: "She/Her",    isSelected: true,  intensity: .alive) { }
        SelectablePill(label: "He/Him",     isSelected: false, intensity: .warm)  { }
        SelectablePill(label: "They/Them",  isSelected: true,  intensity: .warm)  { }
        SelectablePill(label: "Curious",    isSelected: true,  intensity: .dim)   { }
    }
    .padding(24)
    .background(AppColors.lightPageBg)
    .preferredColorScheme(.light)
}

```

---

## File: `Open Lightly/Design/Components/Cards/AtmosphericGhostDeck.swift` {#file-open-lightly-design-components-cards-atmosphericghostdeck-swift}

```swift
//
//  AtmosphericGhostDeck.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/28/26.
//


import SwiftUI

struct AtmosphericGhostDeck: View {

    // Static offsets — the two ghost cards behind the main card
    private let ghosts: [(offset: CGSize, rotation: Double, opacity: Double)] = [
        (CGSize(width: 8,  height: -10), -3.5, 0.75),
        (CGSize(width: 16, height: -20), -7.0, 0.55),
    ]

    @Environment(\.colorScheme) private var colorScheme
    @State private var drifting = false

    let cardSize: CGSize
    let cornerRadius: CGFloat

    var body: some View {
        ZStack {
            // Ghost 1 — furthest back, slower drift
            ghostCard
                .offset(ghosts[0].offset)
                .offset(
                    x: drifting ? 5 : 0,
                    y: drifting ? -6 : 0
                )
                .rotationEffect(.degrees(ghosts[0].rotation + (drifting ? 1.5 : 0)))
                .opacity(colorScheme == .light ? 0.90 : ghosts[0].opacity)
                .animation(
                    .easeInOut(duration: 8.0).repeatForever(autoreverses: true),
                    value: drifting
                )

            // Ghost 2 — closer, slightly faster drift
            ghostCard
                .offset(ghosts[1].offset)
                .offset(
                    x: drifting ? -4 : 0,
                    y: drifting ? -4 : 0
                )
                .rotationEffect(.degrees(ghosts[1].rotation + (drifting ? -1.5 : 0)))
                .opacity(colorScheme == .light ? 0.75 : ghosts[1].opacity)
                .animation(
                    .easeInOut(duration: 9.5).repeatForever(autoreverses: true),
                    value: drifting
                )
        }
        .onAppear {
            drifting = true
        }
    }

    private var ghostCard: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                LinearGradient(
                    colors: colorScheme == .light
                        ? [
                            Color(hex: "E8DFD0"),  // warm off-white, clear tan presence
                            Color(hex: "DEDAD0"),  // deeper, closer to the cream background
                          ]
                        : [
                            Color(red: 0.10, green: 0.09, blue: 0.23),  // deep indigo
                            Color(red: 0.07, green: 0.06, blue: 0.18),  // darker indigo
                          ],
                    startPoint: .topLeading,
                    endPoint:   .bottomTrailing
                )
            )
            .frame(width: cardSize.width, height: cardSize.height)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        colorScheme == .light
                            ? AppColors.purple.opacity(0.12)  // barely-there border, same family as card border
                            : AppColors.purple.opacity(0.38), // strong on dark
                        lineWidth: 2.5
                    )
            )
    }
}

```

---

## File: `Open Lightly/Design/Components/Cards/CategoryTileView.swift` {#file-open-lightly-design-components-cards-categorytileview-swift}

```swift
// ✅ Design system audit — verified March 9, 2026
import SwiftUI

// MARK: - CategoryTileView
// Home screen category grid tile
struct CategoryTileView: View {
    let emoji: String
    let title: String
    let completedCards: Int
    let totalCards: Int
    
    @Environment(\.theme) private var t
    
    var progress: Double {
        Double(completedCards) / Double(max(totalCards, 1))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Emoji icon
            Text(emoji)
                .font(.system(size: 28))
                .padding(.bottom, 8)
            Spacer()
            // Category name
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(t.text)
                .padding(.bottom, 2)
            // Card count
            Text("\(completedCards) / \(totalCards) cards")
                .font(.system(size: 11))
                .foregroundStyle(t.textMuted)
                .padding(.bottom, 8)
            // Progress bar
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(t.surface3)
                    .frame(height: 3)
                Capsule()
                    .fill(t.buttonGradient)
                    .frame(width: max(1, progress * 64), height: 3)
            }
            .frame(height: 3)
        }
        .padding(14)
        .frame(width: 80, height: 96)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(t.surface1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(t.isAmoled ? Color.white.opacity(0.04) : Color.clear, lineWidth: 1.5)
        )
        .shadow(color: t.isAmoled ? .clear : Color.black.opacity(0.06), radius: 12, y: 4)
        .aspectRatio(1/1.2, contentMode: .fit)
    }
}

// MARK: - Preview
struct CategoryTileView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleTiles = [
            ("💬", "Communication", 4, 12),
            ("🛡️", "Boundaries", 8, 12),
            ("❤️", "Intimacy", 2, 12),
            ("🗓️", "Planning", 12, 12)
        ]
        ZStack {
            Color.black.ignoresSafeArea()
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(sampleTiles, id: \ .1) { tile in
                    CategoryTileView(
                        emoji: tile.0,
                        title: tile.1,
                        completedCards: tile.2,
                        totalCards: tile.3
                    )
                }
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }
}

```

---

## File: `Open Lightly/Design/Components/Cards/CircularArrowView.swift` {#file-open-lightly-design-components-cards-circulararrowview-swift}

```swift
//
//  CircularArrowView.swift
//  Open Lightly
//
//  Rewritten — single stroked Path (arc + arrowhead chevron), no Canvas,
//  no glow blob, no system images. The arrowhead is geometrically correct
//  via the tangent-at-endpoint formula.
//
//  All colors derive from LivingTextPalette — consistent with LivingText,
//  OnboardingProgressBar, and OrbitIndicator.
//
//  Animation:
//    - Arc draws on over drawDuration (default 1.2s), easeInOut
//    - Arrowhead appears as part of the same stroke (one path)
//    - After fully drawn: slow opacity breathe on the whole view
//    - Reduce Motion: instant appear, no breathe
//
//  Arrowhead sits at ~315° (top-left) — reads as "lift and turn over"
//  Arc is clockwise, tangent = endAngle - 90° (perpendicular to radius)
//
//  Usage:
//    CircularArrowView(triggered: triggered, onTap: { })
//    CircularArrowView(triggered: triggered, onTap: { })
//    Auto-adapts colors based on colorScheme (light or dark mode)

import SwiftUI

// MARK: - ArcWithArrow Shape

private struct ArcWithArrow: Shape {

    // Arc geometry
    var startAngle: Angle
    var endAngle: Angle
    var clockwise: Bool = true
    var arrowSize: CGFloat = 16

    // Trim drives the draw-on animation
    var trimStart: CGFloat = 0
    var trimEnd:   CGFloat = 0

    // SwiftUI animates these automatically
    var animatableData: CGFloat {
        get { trimEnd }
        set { trimEnd = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let cx     = rect.midX
        let cy     = rect.midY
        let radius = min(rect.width, rect.height) / 2

        var path = Path()

        // ── Arc body ──────────────────────────────────────────────────
        path.addArc(
            center:     CGPoint(x: cx, y: cy),
            radius:     radius,
            startAngle: startAngle,
            endAngle:   endAngle,
            clockwise:  !clockwise   // SwiftUI's clockwise is flipped vs math convention
        )

        // ── Arrowhead chevron ─────────────────────────────────────────
        // Endpoint of arc
        let endRad = CGFloat(endAngle.radians)
        // Fixed tip — pushed outward by half the lineWidth so
        // the chevron sits on top of the stroke, not inside it
        let tipOffset: CGFloat = -0.2   // tune this — try 2–4
        let endX = cx + (radius + tipOffset) * cos(endRad)
        let endY = cy + (radius + tipOffset) * sin(endRad)
        let endPt  = CGPoint(x: endX, y: endY)

        // Tangent at endpoint — clockwise arc: endAngle - 90°
        let tangent = endRad + (clockwise ? .pi / 2 : .pi / 2)

        // Replace the current symmetric spread with asymmetric values
        let innerSpread: CGFloat = .pi / 5.2   // tighter — the curve makes this read longer
        let outerSpread: CGFloat = .pi / 3.5   // wider — the curve makes this read shorter

        let p1 = CGPoint(
            x: endPt.x - (arrowSize) * cos(tangent - outerSpread),
            y: endPt.y - (arrowSize) * sin(tangent - outerSpread)
        )
        let p2 = CGPoint(
            x: endPt.x - (arrowSize)  * cos(tangent + innerSpread),
            y: endPt.y - (arrowSize) * sin(tangent + innerSpread)
        )




        path.move(to: p1)
        path.addLine(to: endPt)
        path.addLine(to: p2)
       
        return path
    }
}

// MARK: - CircularArrowView

struct CircularArrowView: View {
    let triggered: Bool
    let onTap: () -> Void
    var size: CGFloat = 60

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var isLight: Bool { colorScheme == .light }

    // Draw progress — 0 = nothing drawn, 1 = fully drawn
    @State private var trimEnd:      CGFloat = 0
    @State private var viewOpacity:  Double  = 0
    @State private var breathePhase: Bool    = false
    @State private var fullyDrawn:   Bool    = false
    @State private var glowBreathing: Bool   = false

    // MARK: - Geometry
    // Arc starts at 15° and sweeps clockwise to 315°
    // Gap (where arrowhead lives) sits at top-left — reads as "flip/turn over"
    private let arcStart = Angle.degrees(15)
    private let arcEnd   = Angle.degrees(315)
    private let drawDuration: Double = 4.5

    // MARK: - Colors (colorScheme-driven)

    private var stops: [Gradient.Stop] {
        if isLight {
            return [
                .init(color: AppColors.magenta,   location: 0.00),
                .init(color: AppColors.orangeHot, location: 0.55),
                .init(color: AppColors.gold,      location: 1.00),
            ]
        } else {
            return [
                .init(color: AppColors.cyan,      location: 0.00),
                .init(color: AppColors.purple,    location: 0.50),
                .init(color: AppColors.magenta,   location: 1.00),
            ]
        }
    }

    // Angular gradient follows the arc direction
    private var arcGradient: AngularGradient {
        AngularGradient(
            stops:      stops,
            center:     .center,
            startAngle: arcStart,
            endAngle:   arcEnd
        )
    }

    private var strokeStyle: StrokeStyle {
        StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Layer 1 — outer halo (slightly wider, soft)
            ArcWithArrow(
                startAngle: arcStart,
                endAngle:   arcEnd,
                clockwise:  true,
                arrowSize:  16,
                trimEnd:    trimEnd
            )
            .stroke(arcGradient, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
            .blur(radius: 3)
            .opacity(glowBreathing ? 0.65 : 0.20)

            // Layer 2 — inner halo (tight, bright, hugs the stroke)
            ArcWithArrow(
                startAngle: arcStart,
                endAngle:   arcEnd,
                clockwise:  true,
                arrowSize:  16,
                trimEnd:    trimEnd
            )
            .stroke(arcGradient, style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
            .blur(radius: 1.5)
            .opacity(glowBreathing ? 0.45 : 0.12)

            // Layer 2 — crisp stroke
            ArcWithArrow(
                startAngle: arcStart,
                endAngle:   arcEnd,
                clockwise:  true,
                arrowSize:  16,
                trimEnd:    trimEnd
            )
            .stroke(arcGradient, style: strokeStyle)  // lineWidth: 3
            .shadow(color: stops.first?.color.opacity(0.35) ?? .clear, radius: 4)
            .shadow(color: stops.last?.color.opacity(0.20) ?? .clear, radius: 8)
            .opacity(glowBreathing ? 1.0 : 0.70)
        }
        .frame(width: size, height: size)
        .opacity(viewOpacity)
        .contentShape(Circle())
        .onTapGesture { onTap() }
        .onChange(of: triggered) { _, newValue in
            guard newValue else { return }
            runAnimation()
        }
        .onAppear {
            if triggered { runAnimation() }
        }
    }

    // MARK: - Animation

    private func runAnimation() {
        if reduceMotion {
            viewOpacity = 1.0
            trimEnd     = 1.0
            return
        }

        // Fade container in
        withAnimation(.easeOut(duration: 0.3)) {
            viewOpacity = 1.0
        }

        // Draw the arc + arrowhead as one stroke
        withAnimation(.easeInOut(duration: drawDuration)) {
            trimEnd = 1.0
        }

        // After draw completes, start breathing
        DispatchQueue.main.asyncAfter(deadline: .now() + drawDuration + 0.1) {
            fullyDrawn   = true
            breathePhase = true
            withAnimation(
                .easeInOut(duration: 3.5)
                .repeatForever(autoreverses: true)
            ) {
                glowBreathing = true
            }
        }
    }
}

// MARK: - Previews

#Preview("Dark — triggered") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        VStack(spacing: 48) {
            CircularArrowView(triggered: true, onTap: {})
            CircularArrowView(triggered: true, onTap: {})
            CircularArrowView(triggered: true, onTap: {})
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Light — triggered") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        VStack(spacing: 48) {
            CircularArrowView(triggered: true, onTap: {})
            CircularArrowView(triggered: true, onTap: {})
            CircularArrowView(triggered: true, onTap: {})
        }
    }
    .preferredColorScheme(.light)
}

#Preview("Trigger on tap — dark") {
    @Previewable @State var triggered = false
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        VStack(spacing: 24) {
            CircularArrowView(triggered: triggered, onTap: {})
            Button("Trigger") { triggered = true }
                .foregroundStyle(.white)
                .padding(.top, 16)
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Trigger on tap — light") {
    @Previewable @State var triggered = false
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        VStack(spacing: 24) {
            CircularArrowView(triggered: triggered, onTap: {})
            Button("Trigger") { triggered = true }
                .foregroundStyle(AppColors.lightCardTitle)
                .padding(.top, 16)
        }
    }
    .preferredColorScheme(.light)
}

```

---

## File: `Open Lightly/Design/Components/Cards/ContextCard.swift` {#file-open-lightly-design-components-cards-contextcard-swift}

```swift
import SwiftUI

struct ContextCard: View {
    let option: ContextOption
    let isFront: Bool
    let isConfirmed: Bool
    var index: Int = 0
    var total: Int = 3

    @State private var detailVisible = false
    @State private var isBreathing   = false

    @Environment(\.colorScheme) private var colorScheme

    private var intensity: ContextIntensity { option.intensity }
    private var isLight:   Bool             { colorScheme == .light }

    var body: some View {
        ZStack {
            // ── Background ───────────────────────────────────────────────
            // Dark: cardBg flat or intensity gradient — unchanged.
            // Light: lightFrostCard (white 58%) + ultraThinMaterial so the
            //        aurora blobs bleed through the card intentionally.
            if isLight {
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppColors.lightFrostCard)
                    .background(
                        .ultraThinMaterial,
                        in: RoundedRectangle(cornerRadius: 20)
                    )
            } else {
                if intensity.bgTintStart < 1.0 {
                    LinearGradient(
                        stops: [
                            .init(color: AppColors.cardBg,           location: intensity.bgTintStart),
                            .init(color: intensity.bgTintColor,      location: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint:   .bottomTrailing
                    )
                } else {
                    AppColors.cardBg
                }
            }

            // ── Internal glow ─────────────────────────────────────────────
            // Light: opacity halved — the aurora behind the card already
            //        provides atmosphere; the internal glow would fight it.
            // Dark:  unchanged.
            if intensity.internalGlowSize > 0 {
                VStack {
                    HStack {
                        Spacer()
                        Ellipse()
                            .fill(intensity.internalGlowColor)
                            .frame(
                                width:  intensity.internalGlowSize,
                                height: intensity.internalGlowSize
                            )
                            .blur(radius: intensity.internalGlowBlur)
                            .opacity(isLight
                                ? (isBreathing ? 0.65 : 0.50)  // halved from dark values
                                : (isBreathing ? 1.30 : 1.00)) // dark — unchanged
                            .offset(x: 20, y: -20)
                    }
                    Spacer()
                }
            }

            // ── Watermark ─────────────────────────────────────────────────
            // Replaced with TileOrbitView + position number in top-right.
            VStack {
                HStack {
                    Spacer()
                    VStack(spacing: 2) {
                        TileOrbitView(
                            orbitCount: min(index + 1, 3),
                            isActive:   isFront,
                            speed:      1.0,
                            size:       36
                        )
                        .frame(width: 36, height: 36)
                        Text(String(format: "%02d", index + 1))
                            .font(AppFonts.overline)
                            .foregroundColor(isLight
                                ? .black.opacity(isFront ? 0.85 : 0.45)
                                : .white.opacity(isFront ? 0.85 : 0.45))
                            .animation(.easeInOut(duration: 0.3), value: isFront)
                    }
                    .padding(16)
                }
                Spacer()
            }

            // ── Content ───────────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                Text(option.title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(isLight
                        ? AppColors.lightTextPrimary
                        : intensity.rawValue >= 4
                            ? Color.white
                            : AppColors.textPrimary)
                    Text(option.subtitle)
                        .font(AppFonts.caption)
                        .foregroundStyle(isLight
                            ? AppColors.lightTextSecondary
                            : intensity.rawValue >= 4
                                ? Color.white.opacity(0.75)
                                : AppColors.textSecondary)
                }

                Spacer()

                Text(option.detail)
                    .font(.system(size: 13))
                    .foregroundStyle(isLight
                        ? AppColors.lightTextSecondary
                        : intensity.rawValue >= 4
                            ? Color.white.opacity(0.65)
                            : AppColors.textSecondary)
                    .lineSpacing(13 * 0.55)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(detailVisible ? 1 : 0)
            }
            .padding(28)
            .frame(width: 300, height: 340, alignment: .topLeading)
        }
        .frame(width: 300, height: 340)
        .scaleEffect(isBreathing ? 1.02 : 1.0)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        // ── Border overlay ────────────────────────────────────────────────
        // Dark:  spectrum gradient (cyan→purple→magenta).
        //        At rest: intensity.borderOpacity. Confirmed: full opacity.
        // Light: warmAuroraBorder (purple→magenta→gold).
        //        At rest: intensity.borderOpacity. Confirmed: full opacity.
        //        No blur overlay — blur is invisible on cream.
        .overlay(
            Group {
                if isLight {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(
                                AppColors.warmAuroraBorder,
                                lineWidth: isConfirmed ? 2.5 : 2.0
                            )
                            .opacity(isConfirmed ? 1.0 : max(intensity.borderOpacity, 0.65))
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(
                                AppColors.warmAuroraBorder,
                                lineWidth: isConfirmed ? 3.5 : 3.0
                            )
                            .blur(radius: 6)
                            .opacity(isConfirmed ? 0.35 : 0.25)
                    }
                    .shadow(color: AppColors.lightShadowMagenta, radius: 8,  x: 0, y: 3)
                    .shadow(color: AppColors.lightShadowPurple,  radius: 16, x: 0, y: 5)
                    .shadow(color: AppColors.lightShadowGold,    radius: 6,  x: 0, y: 2)
                } else {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [AppColors.cyan, AppColors.purple, AppColors.magenta],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: isConfirmed ? 2 : 1.5
                        )
                        .opacity(isConfirmed ? 1.0 : intensity.borderOpacity)
                }
            }
        )
        // ── Shadows ───────────────────────────────────────────────────────
        // Dark:  intensity.shadowColor + cyan/magenta confirmed glow.
        // Light: lightShadowMagenta/Purple spread. intensity.shadowColor
        //        is a dark token so it's skipped on cream — the warm aurora
        //        shadow spread provides equivalent depth.
        .shadow(
            color: isLight
                ? AppColors.lightShadowMagenta.opacity(0.12)
                : intensity.shadowColor,
            radius: isLight ? 12 : intensity.shadowRadius
        )
        .shadow(
            color: isConfirmed
                ? (isLight
                    ? AppColors.lightShadowMagenta
                    : AppColors.cyan.opacity(isBreathing ? 0.36 : 0.30))
                : .clear,
            radius: 8
        )
        .shadow(
            color: isConfirmed
                ? (isLight
                    ? AppColors.lightShadowPurple
                    : AppColors.magenta.opacity(isBreathing ? 0.24 : 0.20))
                : .clear,
            radius: 12
        )
        .onChange(of: isFront) { _, newFront in
            if newFront {
                withAnimation(.easeIn(duration: 0.3).delay(0.2)) { detailVisible = true }
            } else {
                withAnimation(.easeOut(duration: 0.15)) { detailVisible = false }
            }
        }
        .onChange(of: isConfirmed) { _, confirmed in
            if confirmed { startBreathing() } else { stopBreathing() }
        }
        .onAppear {
            if isFront {
                withAnimation(.easeIn(duration: 0.3).delay(0.5)) { detailVisible = true }
            }
            if isConfirmed { startBreathing() }
        }
    }

    // MARK: - Breathing Animation

    private func startBreathing() {
        isBreathing = false
        withAnimation(.easeInOut(duration: 0.2))                          { isBreathing = true  }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeInOut(duration: 0.2))                      { isBreathing = false }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeInOut(duration: 0.2))                      { isBreathing = true  }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeInOut(duration: 0.2))                      { isBreathing = false }
        }
    }

    private func stopBreathing() {
        withAnimation(.easeOut(duration: 0.2)) { isBreathing = false }
    }
}

// MARK: - Previews

private let previewOptions: [ContextOption] = [
    ContextOption(id: "single",           context: .single,          intensity: .ember,   title: "I'm single",              subtitle: "No partner in the picture",       detail: "Your journey is yours alone."),
    ContextOption(id: "partnered_open",   context: .partneredOpen,   intensity: .spark,   title: "I have a partner",        subtitle: "They know I'm exploring",         detail: "We'll include prompts for transparency."),
    ContextOption(id: "partnered_hidden", context: .partneredHidden, intensity: .blaze,   title: "It's complicated",        subtitle: "I'm not sure how to bring it up", detail: "No pressure. We'll start with self-understanding."),
    ContextOption(id: "not_talked",       context: .notTalked,       intensity: .flame,   title: "Haven't talked about it", subtitle: "One or both of us is curious",    detail: "We'll start with the basics."),
    ContextOption(id: "some_experience",  context: .someExperience,  intensity: .inferno, title: "We've tried some things", subtitle: "Good, bad, or in between",        detail: "We'll help you process what happened."),
    ContextOption(id: "needs_reset",      context: .needsReset,      intensity: .nova,    title: "We need a reset",         subtitle: "Something's off",                 detail: "Let's rebuild with structure and care."),
]

#Preview("All Intensities — dark") {
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 20) {
            ForEach(Array(previewOptions.enumerated()), id: \.element.id) { i, option in
                ContextCard(
                    option:      option,
                    isFront:     true,
                    isConfirmed: false,
                    index:       i,
                    total:       previewOptions.count
                )
            }
        }
        .padding(40)
    }
    .background(AppColors.pageBg)
    .preferredColorScheme(.dark)
}

#Preview("All Intensities — light") {
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 20) {
            ForEach(Array(previewOptions.enumerated()), id: \.element.id) { i, option in
                ContextCard(
                    option:      option,
                    isFront:     true,
                    isConfirmed: false,
                    index:       i,
                    total:       previewOptions.count
                )
            }
        }
        .padding(40)
    }
    .background(AppColors.lightPageBg)
    .preferredColorScheme(.light)
}

#Preview("Confirmed — dark") {
    let option = previewOptions.last!
    HStack(spacing: 20) {
        ContextCard(option: option, isFront: true, isConfirmed: false, index: 0, total: 3)
        ContextCard(option: option, isFront: true, isConfirmed: true, index: 0, total: 3)
    }
    .padding(40)
    .background(AppColors.pageBg)
    .preferredColorScheme(.dark)
}

#Preview("Confirmed — light") {
    let option = previewOptions.last!
    HStack(spacing: 20) {
        ContextCard(option: option, isFront: true, isConfirmed: false, index: 0, total: 3)
        ContextCard(option: option, isFront: true, isConfirmed: true, index: 0, total: 3)
    }
    .padding(40)
    .background(AppColors.lightPageBg)
    .preferredColorScheme(.light)
}

```

---

## File: `Open Lightly/Design/Components/Cards/ContextCardStack.swift` {#file-open-lightly-design-components-cards-contextcardstack-swift}

```swift
import SwiftUI

/// Infinite-scroll gesture-driven card stack.
/// Swipe to browse, tap front card to confirm/unconfirm, auto-advances 0.8s after confirm.
struct ContextCardStack: View {
    @Binding var selection: ContextOption?
    let options: [ContextOption]
    let onAdvance: () -> Void

    @State private var currentIndex: Int   = 0
    @State private var dragOffset: CGFloat = 0
    @State private var autoAdvanceTask: Task<Void, Never>?

    private var renderPositions: [Int] {
        (currentIndex - 2 ... currentIndex + 2).map { $0 }
    }

    private func option(at position: Int) -> ContextOption {
        let count = options.count
        let idx   = ((position % count) + count) % count
        return options[idx]
    }

    var body: some View {
        ZStack {
            ForEach(renderPositions, id: \.self) { pos in
                let opt           = option(at: pos)
                let diff          = CGFloat(pos - currentIndex)
                let normalDrag    = dragOffset / 300
                let effectiveDiff = diff + normalDrag
                let absDiff       = abs(effectiveDiff)
                let sign: CGFloat = effectiveDiff >= 0 ? 1 : -1

                let xOffset  = absDiff < 0.001 ? CGFloat(0) : sign * (30 + absDiff * 18)
                let scale    = max(1 - absDiff * 0.07, 0.8)
                let yOffset  = absDiff * 6
                let rotation = (pos == currentIndex && dragOffset != 0)
                                 ? Double(dragOffset * 0.03) : 0.0
                let opacity  = max(1 - absDiff * 0.35, 0)
                let zIdx     = Double(20 - Int(absDiff * 5))

                ContextCard(
                    option: opt,
                    isFront: pos == currentIndex,
                    isConfirmed: opt.id == selection?.id,
                    index: pos,
                    total: options.count
                )
                .offset(x: xOffset, y: yOffset)
                .scaleEffect(scale)
                .rotationEffect(.degrees(rotation))
                .opacity(opacity)
                .zIndex(zIdx)
            }
        }
        .frame(width: 300, height: 340)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    // Block drag while confirmed — only taps allowed
                    guard selection == nil else { return }
                    dragOffset = value.translation.width
                }
                .onEnded { value in
                    let totalMove = abs(value.translation.width) + abs(value.translation.height)

                    if totalMove < 10 {
                        // Tap: toggle confirm on front card
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { dragOffset = 0 }
                        let front = option(at: currentIndex)
                        if front.id == selection?.id {
                            // Unconfirm — cancel pending advance
                            autoAdvanceTask?.cancel()
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { selection = nil }
                        } else {
                            // Confirm — schedule auto-advance
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { selection = front }
                            autoAdvanceTask?.cancel()
                            autoAdvanceTask = Task {
                                try? await Task.sleep(for: .seconds(0.45))
                                if !Task.isCancelled {
                                    await MainActor.run { onAdvance() }
                                }
                            }
                        }
                        return
                    }

                    // Swipe — blocked if confirmed
                    guard selection == nil else {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { dragOffset = 0 }
                        return
                    }

                    let predicted = value.predictedEndTranslation.width
                    let actual    = value.translation.width
                    var newIndex  = currentIndex

                    if predicted > 150 || actual > 50 {
                        newIndex = currentIndex - 1
                    } else if predicted < -150 || actual < -50 {
                        newIndex = currentIndex + 1
                    }

                    withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                        currentIndex = newIndex
                        dragOffset   = 0
                    }
                }
        )
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.easeInOut(duration: 0.25)) {
                    dragOffset = 18
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        dragOffset = 0
                    }
                }
            }
        }
    }
}

```

---

## File: `Open Lightly/Design/Components/Cards/ContextIntensity.swift` {#file-open-lightly-design-components-cards-contextintensity-swift}

```swift
import SwiftUI

/// Visual intensity levels mirroring the HTML design spec (ember → nova).
/// Controls background gradient, internal glow, border opacity, and external shadow.
enum ContextIntensity: Int {
    case ember   = 1
    case spark   = 2
    case flame   = 3
    case blaze   = 4
    case inferno = 5
    case nova    = 6

    // MARK: Background gradient tint (applied from bottom-trailing)
    var bgTintColor: Color {
        switch self {
        case .ember:   return .clear
        case .spark:   return AppColors.cyan.opacity(0.04)
        case .flame:   return AppColors.cyan.opacity(0.06)
        case .blaze:   return AppColors.purple.opacity(0.08)
        case .inferno: return AppColors.magenta.opacity(0.06)
        case .nova:    return AppColors.magenta.opacity(0.10)
        }
    }

    /// Where the solid cardBg stops and the tint begins (gradient stop location)
    var bgTintStart: CGFloat {
        switch self {
        case .ember:   return 1.0   // no gradient
        case .spark:   return 0.70
        case .flame:   return 0.50
        case .blaze:   return 0.40
        case .inferno: return 0.30
        case .nova:    return 0.20
        }
    }

    // MARK: Spectrum border opacity
    var borderOpacity: Double {
        switch self {
        case .ember:   return 0.40
        case .spark:   return 0.50
        case .flame:   return 0.60
        case .blaze:   return 0.70
        case .inferno: return 0.80
        case .nova:    return 0.90
        }
    }

    // MARK: Internal top-right glow
    var internalGlowColor: Color {
        switch self {
        case .ember:   return .clear
        case .spark:   return AppColors.cyan.opacity(0.10)
        case .flame:   return AppColors.purple.opacity(0.15)
        case .blaze:   return AppColors.purple.opacity(0.20)
        case .inferno: return AppColors.magenta.opacity(0.20)
        case .nova:    return AppColors.magenta.opacity(0.30)
        }
    }

    var internalGlowSize: CGFloat {
        switch self {
        case .ember:   return 0
        case .spark:   return 100
        case .flame:   return 130
        case .blaze:   return 150
        case .inferno: return 170
        case .nova:    return 200
        }
    }

    var internalGlowBlur: CGFloat {
        switch self {
        case .ember:   return 0
        case .spark:   return 30
        case .flame:   return 40
        case .blaze:   return 50
        case .inferno: return 60
        case .nova:    return 70
        }
    }

    // MARK: External ambient shadow
    var shadowColor: Color {
        switch self {
        case .ember:   return AppColors.cyan.opacity(0.04)
        case .spark:   return AppColors.cyan.opacity(0.06)
        case .flame:   return AppColors.purple.opacity(0.08)
        case .blaze:   return AppColors.purple.opacity(0.12)
        case .inferno: return AppColors.magenta.opacity(0.10)
        case .nova:    return AppColors.magenta.opacity(0.16)
        }
    }

    var shadowRadius: CGFloat {
        switch self {
        case .ember:   return 10
        case .spark:   return 15
        case .flame:   return 20
        case .blaze:   return 25
        case .inferno: return 30
        case .nova:    return 35
        }
    }
}

```

---

## File: `Open Lightly/Design/Components/Cards/ContextOption.swift` {#file-open-lightly-design-components-cards-contextoption-swift}

```swift
import Foundation

struct ContextOption: Identifiable {
    let id: String
    let context: RelationshipContext
    let intensity: ContextIntensity
    let title: String
    let subtitle: String
    let detail: String
}

```

---

## File: `Open Lightly/Design/Components/Cards/ConversationCard.swift` {#file-open-lightly-design-components-cards-conversationcard-swift}

```swift
//  ConversationCard.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/28/26.
//


import SwiftUI

struct ConversationCard: View {

    // MARK: - Inputs

    let content: ConversationCardContent
    let fuseConfig: FuseConfig
    let ghostDeckMode: GhostDeckMode

    // MARK: - State

    @State private var isFlipped = false
    @State private var arrowVisible = false
    @State private var pulsing = false
    @State private var selectedPill: CardRevealPill? = nil
    @State private var showEncouragement = false

    // MARK: - Callbacks

    var onPillSelected: ((CardRevealPill) -> Void)? = nil
    var onContinue: (() -> Void)? = nil

    // MARK: - Layout

    private let cardHeight: CGFloat = 420
    private let cornerRadius: CGFloat = 20
    private let lineWidth: CGFloat = 1.5

    private var cardWidth: CGFloat {
        (UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.screen.bounds.width ?? 390) - 48
    }

    var cardSize: CGSize {
        CGSize(width: cardWidth, height: cardHeight)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Ghost deck behind everything
            if case .atmospheric = ghostDeckMode {
                AtmosphericGhostDeck(
                    cardSize: cardSize,
                    cornerRadius: cornerRadius
                )
            }

            // Card itself
            ZStack {
                frontFace
                    .opacity(isFlipped ? 0 : 1)
                    .rotation3DEffect(
                        .degrees(isFlipped ? 180 : 0),
                        axis: (x: 0, y: 1, z: 0),
                        perspective: 0.4
                    )

                backFace
                    .opacity(isFlipped ? 1 : 0)
                    .rotation3DEffect(
                        .degrees(isFlipped ? 0 : -180),
                        axis: (x: 0, y: 1, z: 0),
                        perspective: 0.4
                    )
            }
            .frame(width: cardWidth, height: cardHeight)
            .scaleEffect(pulsing ? 1.02 : 1.0)
            .animation(
                pulsing
                    ? .easeInOut(duration: 2.0).repeatForever(autoreverses: true)
                    : .default,
                value: pulsing
            )
            .onTapGesture {
                if !isFlipped {
                    flipCard()
                }
            }
        }
    }

    // MARK: - Front Face

    private var frontFace: some View {
        ZStack {
            // Card background
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(AppColors.cardBg)

            // Ambient wash — subtle glow at bottom
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            AppColors.purple.opacity(0.06),
                            AppColors.cyan.opacity(0.04),
                            .clear
                        ],
                        startPoint: .bottomLeading,
                        endPoint: .topTrailing
                    )
                )

            // Content
            VStack(alignment: .leading, spacing: 24) {
                // Overline
                if let overline = frontOverline {
                    Text(overline)
                        .font(AppFonts.overline)
                        .tracking(2)
                        .foregroundStyle(AppColors.textTertiary)
                }

                Spacer()

                // Question
                frontQuestionText

                Spacer()

                // Arrow — fades in after fuse completes
                if arrowVisible {
                    HStack {
                        Spacer()
                        CircularArrowView(triggered: arrowVisible, onTap: flipCard)
                            .transition(.opacity)
                    }
                }
            }
            .padding(28)

            // Fuse timer — rendered over card, under content
            fuseOverlay

            // Border
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        }
    }

    // MARK: - Back Face

    private var backFace: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(AppColors.cardBg)

            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            AppColors.magenta.opacity(0.05),
                            AppColors.purple.opacity(0.04),
                            .clear
                        ],
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    )
                )

            VStack(alignment: .leading, spacing: 20) {
                Text("Something came up. What's it closest to?")
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(AppColors.textSecondary)

                Spacer()

                if case .onboarding(let card) = content,
                   case .pills(let pills) = card.backFace {
                    pillGrid(pills: pills)
                }

                Spacer()

                if showEncouragement {
                    encouragementText
                        .transition(.opacity)
                }
            }
            .padding(28)

            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        }
    }

    // MARK: - Pill Grid

    private func pillGrid(pills: [CardRevealPill]) -> some View {
        VStack(spacing: 12) {
            ForEach(pills) { pill in
                pillButton(pill: pill)
            }
        }
    }

    private func pillButton(pill: CardRevealPill) -> some View {
        let isSelected = selectedPill == pill

        return Button {
            guard selectedPill == nil else { return }
            handlePillSelection(pill)
        } label: {
            Text(pill.rawValue)
                .font(AppFonts.buttonLabel)
                .foregroundStyle(isSelected ? AppColors.textPrimary : AppColors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 100)
                        .fill(isSelected
                              ? AppColors.purple.opacity(0.15)
                              : Color.white.opacity(0.04))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 100)
                        .stroke(
                            isSelected
                                ? AnyShapeStyle(AppColors.spectrumBorder)
                                : AnyShapeStyle(Color.white.opacity(0.08)),
                            lineWidth: isSelected ? 1.5 : 1
                        )
                )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }

    // MARK: - Encouragement

    private var encouragementText: some View {
        Text("This journey asks a lot of the people it's meant for. You're in good company.")
            .font(AppFonts.bodyMedium)
            .foregroundStyle(AppColors.textSecondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }

    // MARK: - Fuse Overlay

    @ViewBuilder
    private var fuseOverlay: some View {
        if case .countdown(let duration, let onComplete) = fuseConfig {
            FuseTimerView(
                size: cardSize,
                cornerRadius: cornerRadius,
                lineWidth: lineWidth,
                duration: duration,
                delay: 1.5,
                onComplete: {
                    withAnimation(.easeIn(duration: 0.4)) {
                        arrowVisible = true
                    }
                    pulsing = true
                    onComplete()
                }
            )
        }
    }

    // MARK: - Helpers

    private var frontOverline: String? {
        switch content {
        case .onboarding(let card): return card.overline
        case .prompt: return nil
        }
    }

    private var frontQuestionText: some View {
        switch content {
        case .onboarding(let card):
            return AnyView(highlightedQuestion(card: card))
        case .prompt(let prompt):
            return AnyView(
                Text(prompt.text)
                    .font(AppFonts.cardTitle)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineSpacing(6)
            )
        }
    }

    private func highlightedQuestion(card: OBCard) -> some View {
        // Split question around highlighted phrase, apply gradient to phrase
        let parts = card.question.components(separatedBy: card.highlightedPhrase)

        return Group {
            if parts.count == 2 {
                VStack(spacing: 0) {
                    Text(parts[0] + card.highlightedPhrase + parts[1])
                        .font(AppFonts.cardTitle)
                        .foregroundStyle(AppColors.textPrimary)
                        .lineSpacing(6)
                }
                .overlay(alignment: .topLeading) {
                    let prefix = AttributedString(parts[0])
                    let highlighted = try! AttributedString(markdown: "**\(card.highlightedPhrase)**")
                    var combined = prefix
                    combined += highlighted
                    
                    return Text(combined)
                        .font(AppFonts.cardTitle)
                        .foregroundStyle(AppColors.textPrimary)
                        .lineSpacing(6)
                }
            } else {
                Text(card.question)
                    .foregroundStyle(AppColors.textPrimary)
            }
        }
        .font(AppFonts.cardTitle)
        .lineSpacing(6)
    }

    // MARK: - Actions

    private func flipCard() {
        withAnimation(
            .spring(response: 0.65, dampingFraction: 0.78)
        ) {
            isFlipped = true
        }
    }

    private func handlePillSelection(_ pill: CardRevealPill) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedPill = pill
        }
        onPillSelected?(pill)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeInOut(duration: 0.4)) {
                showEncouragement = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            onContinue?()
        }
    }
}

// MARK: - Convenience Initializer for Prompt Migration

extension ConversationCard {
    /// Convenience initializer for Prompt cards
    /// Provides a streamlined API for prompt-only usage
    init(
        prompt: Prompt,
        onDismiss: (() -> Void)? = nil
    ) {
        self.init(
            content: .prompt(prompt),
            fuseConfig: .none,
            ghostDeckMode: .none,
            onPillSelected: nil,
            onContinue: onDismiss
        )
    }
}

// MARK: - Previews

#Preview("Onboarding Card — Full Flow") {
    let obCard = OBCard(
        overline: "YOUR FIRST CARD",
        question: "What would you desire if nobody (not even you) would judge the answer?",
        highlightedPhrase: "(not even you)",
        backFace: .pills(CardRevealPill.allCases)
    )
    
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        
        VStack {
            Spacer()
            ConversationCard(
                content: .onboarding(obCard),
                fuseConfig: .countdown(duration: 12.0, onComplete: { }),
                ghostDeckMode: .atmospheric,
                onPillSelected: { _ in },
                onContinue: { }
            )
            Spacer()
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}

#Preview("Prompt Card — Convenience Init") {
    let prompt = Prompt(
        id: UUID(),
        text: "What's one thing you've never told anyone?",
        category: .prompt
    )
    
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        
        VStack {
            Spacer()
            ConversationCard(prompt: prompt, onDismiss: { })
            Spacer()
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}

```

---

## File: `Open Lightly/Design/Components/Cards/ConversationCardTypes.swift` {#file-open-lightly-design-components-cards-conversationcardtypes-swift}

```swift
//
//  OBCard.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/28/26.
//


import SwiftUI

// MARK: - OB Card

struct OBCard {
    let overline: String
    let question: String
    let highlightedPhrase: String   // receives gradient treatment
    let backFace: OBCardBackFace
}

enum OBCardBackFace {
    case pills([CardRevealPill])
    case text(String)
}

enum CardRevealPill: String, CaseIterable, Identifiable {
    case ready      = "Something I'm ready for"
    case figuring   = "Something I'm still figuring out"
    case scared     = "Something that scares me"
    case almostSaid = "Something I almost said"
    case noApology  = "Something I stopped apologizing for"

    var id: String { rawValue }
}

// MARK: - Content Type

enum ConversationCardContent {
    case prompt(Prompt)
    case onboarding(OBCard)
}

// MARK: - Fuse Config

enum FuseConfig {
    case none
    case countdown(duration: TimeInterval, onComplete: () -> Void)
}

// MARK: - Ghost Deck Mode

enum GhostDeckMode {
    case none
    case atmospheric
    case navigable(cards: [ConversationCardContent], onAdvance: () -> Void)
}
```

---

## File: `Open Lightly/Design/Components/Cards/FuseTimerView.swift` {#file-open-lightly-design-components-cards-fusetimerview-swift}

```swift
//
//  FuseTimerView.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/28/26.
//


import SwiftUI

struct FuseTimerView: View {

    let size:         CGSize
    let cornerRadius: CGFloat
    let lineWidth:    CGFloat
    let duration:     TimeInterval
    let delay:        TimeInterval
    let sparkColor:   Color        // NEW — defaults to AppColors.cyan
    let onComplete:   () -> Void

    init(
        size:         CGSize,
        cornerRadius: CGFloat,
        lineWidth:    CGFloat,
        duration:     TimeInterval,
        delay:        TimeInterval,
        sparkColor:   Color = AppColors.cyan,
        onComplete:   @escaping () -> Void
    ) {
        self.size         = size
        self.cornerRadius = cornerRadius
        self.lineWidth    = lineWidth
        self.duration     = duration
        self.delay        = delay
        self.sparkColor   = sparkColor
        self.onComplete   = onComplete
    }

    @State private var startDate:  Date? = nil
    @State private var progress:   Double = 0
    @State private var completed:  Bool = false

    var body: some View {
        TimelineView(.animation(paused: completed)) { timeline in
            Canvas { ctx, canvasSize in
                let rect = CGRect(
                    x: lineWidth / 2,
                    y: lineWidth / 2,
                    width:  canvasSize.width  - lineWidth,
                    height: canvasSize.height - lineWidth
                )
                let path = RoundedRectangle(cornerRadius: cornerRadius - lineWidth / 2)
                    .path(in: rect)

                drawUnburned(ctx: ctx, path: path, canvasSize: canvasSize)
                drawEmber(ctx: ctx, path: path)
                drawSparkHead(ctx: ctx, path: path)
            }
            .onChange(of: timeline.date) { _, date in
                tick(date: date)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                startDate = Date()
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Tick

    private func tick(date: Date) {
        guard let start = startDate, !completed else { return }
        progress = min(date.timeIntervalSince(start) / duration, 1.0)
        if progress >= 1.0 {
            completed = true
            onComplete()
        }
    }

    // MARK: - Drawing

    // Full border ahead of the spark — this is the unburned segment
    private func drawUnburned(ctx: GraphicsContext, path: Path, canvasSize: CGSize) {
        guard progress < 1.0 else { return }
        let unburned = path.trimmedPath(from: progress, to: 1.0)
        ctx.stroke(
            unburned,
            with: .linearGradient(
                Gradient(colors: [
                    sparkColor.opacity(0.6),
                    sparkColor,
                    sparkColor.opacity(0.6),
                ]),
                startPoint: .zero,
                endPoint:   CGPoint(x: canvasSize.width, y: canvasSize.height)
            ),
            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
        )
    }

    // Short glowing segment just at the burn edge
    private func drawEmber(ctx: GraphicsContext, path: Path) {
        guard progress < 1.0 else { return }
        let emberEnd = min(progress + 0.04, 1.0)
        let ember    = path.trimmedPath(from: progress, to: emberEnd)
        var emberCtx = ctx
        emberCtx.addFilter(.blur(radius: 3))
        emberCtx.stroke(
            ember,
            with: .color(sparkColor.opacity(0.7)),
            style: StrokeStyle(lineWidth: lineWidth * 1.4, lineCap: .round)
        )
    }

    // Spark head at the current burn position
    private func drawSparkHead(ctx: GraphicsContext, path: Path) {
        let head = path.trimmedPath(from: max(0, progress - 0.001), to: progress)
        guard let pt = head.currentPoint else { return }

        let r    = lineWidth * 1.2
        let rect = CGRect(x: pt.x - r, y: pt.y - r, width: r * 2, height: r * 2)

        // Outer glow
        var glowCtx = ctx
        glowCtx.addFilter(.blur(radius: 5))
        glowCtx.fill(
            Circle().path(in: rect.insetBy(dx: -3, dy: -3)),
            with: .color(sparkColor.opacity(0.6))
        )

        // Core
        ctx.fill(Circle().path(in: rect),
            with: .color(sparkColor))

        // Hot white center
        ctx.fill(Circle().path(in: rect.insetBy(dx: r * 0.45, dy: r * 0.45)),
            with: .color(.white.opacity(0.95)))
    }
}

```

---

## File: `Open Lightly/Design/Components/Cards/PromptCard.swift` {#file-open-lightly-design-components-cards-promptcard-swift}

```swift
import SwiftUI

// MARK: - PromptDifficulty Visual Extensions
extension PromptDifficulty {
    var backgroundTint: Color {
        switch self {
        case .easy:      return AppColors.cyan.opacity(0.03)
        case .light:     return AppColors.cyan.opacity(0.05)
        case .medium:    return AppColors.purple.opacity(0.06)
        case .deep:      return AppColors.purple.opacity(0.08)
        case .sensitive: return AppColors.magenta.opacity(0.10)
        case .ultimate:  return AppColors.magenta.opacity(0.14)
        }
    }
    var borderOpacity: Double {
        switch self {
        case .easy:      return 0.4
        case .light:     return 0.5
        case .medium:    return 0.6
        case .deep:      return 0.7
        case .sensitive: return 0.85
        case .ultimate:  return 1.0
        }
    }
    var glowColor: Color {
        switch self {
        case .easy, .light:         return AppColors.cyan
        case .medium, .deep:        return AppColors.purple
        case .sensitive, .ultimate: return AppColors.magenta
        }
    }
    var glowRadius: CGFloat {
        switch self {
        case .easy:      return 20
        case .light:     return 25
        case .medium:    return 30
        case .deep:      return 40
        case .sensitive: return 50
        case .ultimate:  return 65
        }
    }
}

struct PromptCard: View {
    let prompt: Prompt
    @Environment(\.colorScheme) private var colorScheme

    var intensity: PromptDifficulty {
        prompt.difficulty
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Outer container
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppColors.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(intensity.backgroundTint)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(AppColors.spectrumGradient.opacity(intensity.borderOpacity), lineWidth: 2)
                )
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(
                    color: colorScheme == .dark ? intensity.glowColor : Color.black.opacity(0.10),
                    radius: colorScheme == .dark ? intensity.glowRadius * 0.5 : 12,
                    x: 0, y: 4
                )

            // Radial glow
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [intensity.glowColor, .clear]),
                        center: .center,
                        startRadius: 0,
                        endRadius: intensity.glowRadius * 1.5
                    )
                )
                .frame(width: intensity.glowRadius * 3, height: intensity.glowRadius * 3)
                .offset(x: 60, y: -40)
                .blur(radius: intensity.glowRadius)
                .allowsHitTesting(false)

            // Content stack
            VStack(alignment: .leading, spacing: 16) {
                // Category label
                Text(prompt.category.rawValue.uppercased())
                    .font(AppFonts.overline)
                    .tracking(2)
                    .textCase(.uppercase)
                    .foregroundColor(AppColors.textTertiary)

                // Prompt text
                KeywordHighlightText(fullText: prompt.text, keywords: prompt.highlightWords.map { (text: $0, type: "cyan") })
                    .font(AppFonts.cardTitle)
                    .lineSpacing(4)
                    .foregroundColor(AppColors.textPrimary)

                // Footer row
                HStack {
                    // Intensity label
                    Text(intensity.displayName.capitalized)
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textTertiary)

                    Spacer()

                    // Difficulty dots
                    HStack(spacing: 4) {
                        let difficultyOrder = [PromptDifficulty.easy, .light, .medium, .deep, .sensitive, .ultimate]
                        ForEach(0..<6, id: \ .self) { i in
                            Circle()
                                .frame(width: 6, height: 6)
                                .foregroundStyle(
                                    i <= difficultyOrder.firstIndex(of: prompt.difficulty) ?? 0 ? AppColors.cyan : Color.white.opacity(0.15)
                                )
                        }
                    }
                }
            }
            .padding(.top, 32)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 24) {
        PromptCard(prompt: Prompt(
            text: "What first attracted you to the idea of opening your relationship?",
            highlightWords: ["opening your relationship"],
            category: .prompt,
            difficulty: .easy,
            meta: "",
            isSensitive: false,
            canSkip: true,
            whoStarts: .partnerA
        ))
        PromptCard(prompt: Prompt(
            text: "How do you handle jealousy when it shows up unexpectedly?",
            highlightWords: ["jealousy"],
            category: .reflect,
            difficulty: .medium,
            meta: "",
            isSensitive: true,
            canSkip: true,
            whoStarts: .partnerB
        ))
        PromptCard(prompt: Prompt(
            text: "If there were no fear and no judgment — what would your ideal relationship actually look like?",
            highlightWords: ["no fear", "no judgment"],
            category: .ultimate,
            difficulty: .ultimate,
            meta: "",
            isSensitive: true,
            canSkip: false,
            whoStarts: .both
        ))
    }
    .padding()
    .background(AppColors.background)
}

```

---

## File: `Open Lightly/Design/Components/Cards/SettingsCard.swift` {#file-open-lightly-design-components-cards-settingscard-swift}

```swift
import SwiftUI

/// Rounded card container used throughout Settings and any other list-style screen.
/// Usage: wrap any content in `SettingsCard { ... }`
struct SettingsCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(16)
        .cardStyle()
    }
}

```

---

## File: `Open Lightly/Design/Components/Effects/AuroraGlowField.swift` {#file-open-lightly-design-components-effects-auroraglowfield-swift}

```swift
//
//  AuroraGlowField.swift
//  Open Lightly
//
//  Warm Aurora atmospheric blob field for light mode screens.
//  Near-verbatim copy of OnboardingGlowField with warm palette
//  swapped in and opacities raised ~1.8–2.2× to compensate
//  for cream (#F8F6EE) absorbing color vs dark (#030305) amplifying it.
//

import SwiftUI

// ─────────────────────────────────────────────
// MARK: Private palette
// File-scoped only. DO NOT add to AppColors.swift.
// ─────────────────────────────────────────────

private extension Color {
    static let auroraOrange  = Color(hex: "E04A10")
    static let auroraWine    = Color(hex: "6B1030")
    static let auroraPink    = Color(hex: "D42060")
    static let auroraWineLo  = Color(hex: "8A1430")
    // CHANGE (v2): Added purple — required for brandView gradient harmony.
    // Purple bridges the gap between wine/pink and gold in the brand palette.
    static let auroraPurple  = Color(hex: "6B28AA")
    // CHANGE (v2): Added gold — brandView uses magenta→orange→gold arc.
    static let auroraGold    = Color(hex: "E8A020")
}

// ─────────────────────────────────────────────
// MARK: Aurora Configuration
// ─────────────────────────────────────────────

struct AuroraConfig: Equatable {
    var topOpacityMult:    Double
    var midOpacityMult:    Double
    var bottomOpacityMult: Double
    var globalOpacity:     Double

    // CHANGE (v2): Added brandView config.
    // Heavy top-right (gold/orange) + strong left (purple/pink) +
    // fading bottom. Mirrors the asymmetric distribution in the mockup.
    // globalOpacity 0.78 — slightly under statView (0.85) because the
    // brand screen has a filament orbit that already contributes color
    // energy. Aurora should be atmospheric, not competing.
    static let brandView = AuroraConfig(
        topOpacityMult:    1.0,
        midOpacityMult:    0.35,
        bottomOpacityMult: 0.70,
        globalOpacity: 0.88
    )

    static let statView = AuroraConfig(
        topOpacityMult: 1.0, midOpacityMult: 0.4,
        bottomOpacityMult: 1.15, globalOpacity: 1.0)

    static let nameView = AuroraConfig(
        topOpacityMult: 1.0, midOpacityMult: 0.1,
        bottomOpacityMult: 1.15, globalOpacity: 0.85)

    static let modeSelectView = AuroraConfig(
        topOpacityMult: 0.1, midOpacityMult: 0.3,
        bottomOpacityMult: 1.15, globalOpacity: 0.90)

    static let contextView = AuroraConfig(
        topOpacityMult: 0.4, midOpacityMult: 0.2,
        bottomOpacityMult: 0.85, globalOpacity: 0.75)

    static let curiosityPickerView = AuroraConfig(
        topOpacityMult: 0.3, midOpacityMult: 0.1,
        bottomOpacityMult: 0.75, globalOpacity: 0.65)

    static let groundRulesView = AuroraConfig(
        topOpacityMult: 0.15, midOpacityMult: 0.2,
        bottomOpacityMult: 1.05, globalOpacity: 0.75)
}

// ─────────────────────────────────────────────
// MARK: Aurora Glow Field
// ─────────────────────────────────────────────

struct AuroraGlowField: View {
    var config: AuroraConfig = .statView

    @State private var blobVisible: [Bool]    = Array(repeating: false, count: 9)
    @State private var blobPhase:   [CGFloat] = Array(repeating: 0,     count: 9)
    @State private var hasStarted = false

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let global = config.globalOpacity

            ZStack {

                // ── Tier 1: Top zone — heavy, asymmetric ──────────────────
                //
                // CHANGE (v2): Was single upper-left orange blob.
                // Now two blobs: dominant gold top-right + strong pink top-left.
                // This matches the mockup's asymmetric top-heavy distribution
                // and introduces gold into the upper field for brandView harmony.

                // Gold — dominant top-right
                blob(.auroraGold, 0.82 * config.topOpacityMult * global, 340, 280, 80, 0)
                    .offset(
                        x: sin(blobPhase[0] * .pi * 2) * 14,
                        y: sin(blobPhase[0] * .pi * 2 + .pi / 3) * 10
                    )
                    .position(x: w * 0.78, y: h * 0.14)

                // Pink — strong top-left
                blob(.auroraPink, 0.76 * config.topOpacityMult * global, 280, 240, 72, 1)
                    .offset(
                        x: sin(blobPhase[1] * .pi * 2) * -10,
                        y: sin(blobPhase[1] * .pi * 2 + .pi / 4) * 12
                    )
                    .position(x: w * 0.18, y: h * 0.17)

                // ── Tier 2: Mid zone — supporting, moderate opacity ────────
                //
                // CHANGE (v2): Added purple blob center-right — bridges the
                // wine/pink and gold colors. Was absent in v1 entirely.
                // Wine blob repositioned from center to center-left so the
                // mid zone has left/right color separation rather than one
                // central mass.

                // Purple — center-right (new)
                blob(.auroraPurple, 0.70 * config.midOpacityMult * global, 300, 260, 78, 2)
                    .scaleEffect(
                        blobVisible[2]
                            ? 1 + 0.05 * sin(blobPhase[2] * .pi * 2)
                            : 0.7
                    )
                    .offset(x: sin(blobPhase[2] * .pi * 2) * 8)
                    .position(x: w * 0.80, y: h * 0.36)

                // Wine — center-left (was: center w * 0.50)
                blob(.auroraWine, 0.67 * config.midOpacityMult * global, 320, 280, 78, 3)
                    .scaleEffect(
                        blobVisible[3]
                            ? 1 + 0.06 * sin(blobPhase[3] * .pi * 2)
                            : 0.7
                    )
                    .offset(x: sin(blobPhase[3] * .pi * 2) * 5)
                    .position(x: w * 0.28, y: h * 0.40)

                // Orange — warm mid accent (unchanged position, opacity tuned)
                blob(.auroraOrange, 0.42 * config.midOpacityMult * global, 200, 180, 80, 4)
                    .offset(
                        x: sin(blobPhase[4] * .pi) * 8,
                        y: sin(blobPhase[4] * .pi) * -6
                    )
                    .position(x: w * 0.55, y: h * 0.50)

                // ── Tier 3: Lower zone — faint, wide ──────────────────────
                //
                // CHANGE (v2): WineLo blob repositioned from w*0.18 h*0.60
                // to w*0.22 h*0.64 — slightly more centered so the lower
                // field doesn't feel left-only.
                // Floor wash y moved from h*0.80 → h*0.86 for brandView
                // so it doesn't bleed into the tagline zone at h*0.595.
                // Bottom orange accent opacity reduced — less competition
                // with the tagline text at the bottom of the brand screen.

                // WineLo — lower left
                blob(.auroraWineLo, 0.67 * config.midOpacityMult * global, 280, 200, 85, 5)
                    .scaleEffect(
                        blobVisible[5]
                            ? 1 + 0.05 * sin(blobPhase[5] * .pi * 2)
                            : 0.7
                    )
                    .offset(
                        x: sin(blobPhase[5] * .pi) * 8,
                        y: sin(blobPhase[5] * .pi) * -5
                    )
                    .position(x: w * 0.22, y: h * 0.64)

                // Floor wash — wide radial sweep across bottom
                Ellipse()
                    .fill(RadialGradient(
                        stops: [
                            .init(
                                color: Color.auroraWine.opacity(
                                    0.48 * config.bottomOpacityMult * global
                                ),
                                location: 0
                            ),
                            .init(
                                color: Color.auroraPink.opacity(
                                    0.28 * config.bottomOpacityMult * global
                                ),
                                location: 0.4
                            ),
                            .init(color: .clear, location: 0.7)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    ))
                    .frame(width: 420, height: 180)
                    .blur(radius: 90)
                    .scaleEffect(
                        blobVisible[6]
                            ? 1 + 0.06 * sin(blobPhase[6] * .pi * 2)
                            : 0.7
                    )
                    .opacity(blobVisible[6] ? 1 : 0)
                    .offset(x: sin(blobPhase[6] * .pi * 2) * 4)
                    .position(x: w * 0.5, y: h * 0.86)

                // Orange — bottom accent (opacity reduced v1→v2: 0.324→0.22)
                blob(.auroraOrange, 0.35 * config.bottomOpacityMult * global, 220, 140, 88, 7)
                    .offset(x: sin(blobPhase[7] * .pi * 2) * -8)
                    .position(x: w * 0.46, y: h * 0.91)

                // Gold — bottom-right faint accent (new in v2)
                // Anchors the gold presence in the lower field so the
                // warm arc (gold top-right → gold bottom-right) reads as
                // intentional, not a single isolated blob.
                blob(.auroraGold, 0.26 * config.bottomOpacityMult * global, 200, 140, 85, 8)
                    .offset(x: sin(blobPhase[8] * .pi * 2) * 6)
                    .position(x: w * 0.80, y: h * 0.88)
            }
        }
        .allowsHitTesting(false)
        .animation(.easeInOut(duration: 1.0), value: config)
        .onAppear {
            guard !hasStarted else { return }
            hasStarted = true
            startAtmosphere()
        }
    }

    // MARK: - Blob builder

    @ViewBuilder
    private func blob(
        _ color: Color,
        _ opacity: Double,
        _ w: CGFloat,
        _ h: CGFloat,
        _ blur: CGFloat,
        _ i: Int
    ) -> some View {
        Ellipse()
            .fill(RadialGradient(
                stops: [
                    .init(color: color.opacity(opacity),        location: 0.20),
                    .init(color: color.opacity(opacity * 0.55), location: 0.55),
                    .init(color: .clear,                        location: 1.0)
                ],
                center: .center,
                startRadius: 0,
                endRadius: max(w, h) / 2
            ))
            .frame(width: w, height: h)
            .blur(radius: blur)
            .scaleEffect(blobVisible[i] ? 1.0 : 0.7)
            .opacity(blobVisible[i] ? 1 : 0)
    }

    // MARK: - Animation orchestration
    //
    // CHANGE (v2): Extended from 7 blobs → 9 blobs.
    // Two new entries appended to all arrays (indices 7, 8).
    // Phase-drifted durations prevent synchronization across blobs.

    private func startAtmosphere() {
        let fadeDelays:    [Double] = [0.10, 0.20, 0.30, 0.35, 0.40, 0.50, 0.60, 0.65, 0.70]
        let fadeDurations: [Double] = [0.90, 1.00, 0.90, 1.00, 1.00, 1.20, 1.00, 1.00, 1.10]
        let loopDurations: [Double] = [8,    10,   9,    11,   12,   14,   10,   13,   11  ]
        let loopDelays:    [Double] = [0.80, 1.00, 1.20, 1.30, 1.50, 1.60, 1.80, 1.90, 2.00]

        for i in 0..<9 {
            withAnimation(
                .easeInOut(duration: fadeDurations[i])
                .delay(fadeDelays[i])
            ) {
                blobVisible[i] = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + loopDelays[i]) {
                withAnimation(
                    .linear(duration: loopDurations[i])
                    .repeatForever(autoreverses: false)
                ) {
                    blobPhase[i] = 1.0
                }
            }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: Previews
// ─────────────────────────────────────────────

#Preview("Brand View — Light") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        AuroraGlowField(config: .brandView)
    }
    .preferredColorScheme(.light)
}

#Preview("Stat View — Light") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        AuroraGlowField(config: .statView)
    }
    .preferredColorScheme(.light)
}

#Preview("Stat View — Dark") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        AuroraGlowField(config: .statView)
    }
    .preferredColorScheme(.dark)
}

```

---

## File: `Open Lightly/Design/Components/Effects/FlameAura.swift` {#file-open-lightly-design-components-effects-flameaura-swift}

```swift
// Design/Components/Effects/FlameAura.swift
// Open Lightly
//
// Wisp-based flame renderer.
// Each wisp is an independent tapered path that:
//   • rises at its own speed
//   • wobbles horizontally via stacked sine offsets (fake turbulence)
//   • shifts colour from hot-pink/magenta at the base → deep purple at tip
//   • fades in opacity as it rises
//
// Rendered entirely in Canvas so there are zero UIKit/CALayer allocations.

import SwiftUI
import Combine

// ─────────────────────────────────────────────
// MARK: Public view
// ─────────────────────────────────────────────

struct FlameAura: View {

    let intensity: SelectablePill.Intensity

    // Appearance entrance
    @State private var appeared = false
    // Master time driver
    @State private var t: Double = 0

    // Timer publisher — 60 fps
    private let ticker = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()

    private var wispCount: Int {
        switch intensity {
        case .dim:   return 0
        case .warm:  return 9
        case .alive: return 14
        }
    }

    private var maxWispHeight: CGFloat {
        switch intensity {
        case .dim:   return 0
        case .warm:  return 0.72   // fraction of frame height
        case .alive: return 0.92
        }
    }

    private var masterOpacity: Double {
        switch intensity {
        case .dim:   return 0
        case .warm:  return 0.82
        case .alive: return 1.0
        }
    }

    var body: some View {
        Canvas { ctx, size in
            guard wispCount > 0 else { return }
            for i in 0..<wispCount {
                drawWisp(ctx: &ctx, size: size, index: i, t: t)
            }
        }
        .opacity(appeared ? masterOpacity : 0)
        .onAppear {
            withAnimation(.easeIn(duration: 0.45)) { appeared = true }
        }
        .onDisappear { appeared = false }
        .onReceive(ticker) { _ in t += 0.018 }
        .allowsHitTesting(false)
    }

    // ─────────────────────────────────────────────
    // MARK: Wisp renderer
    // ─────────────────────────────────────────────

    private func drawWisp(
        ctx: inout GraphicsContext,
        size: CGSize,
        index: Int,
        t: Double
    ) {
        // Each wisp gets a stable seed so its personality is consistent
        let seed     = Double(index) * 1.618_033          // golden ratio spread
        let baseX    = size.width * lerp(0.08, 0.92, fract(seed * 0.37))

        // Rise phase — wraps 0→1 continuously, offset per wisp
        let risePhase = fract(t * lerp(0.18, 0.32, fract(seed * 0.71)) + fract(seed * 0.53))
        // Ease the rise so wisps accelerate as they climb
        let easedRise = easeInQuad(risePhase)

        let bottomY  = size.height * 0.95
        let topY     = size.height * (1.0 - maxWispHeight * easedRise)
        let wispH    = bottomY - topY
        guard wispH > 2 else { return }

        // Base width tapers to zero at tip
        let baseWidth = size.width * lerp(0.06, 0.14, fract(seed * 0.29))

        // Horizontal turbulence — two stacked sine waves per wisp
        // creates convincing flicker without Perlin noise
        let wobble1  = sin(t * lerp(1.8, 3.2, fract(seed * 0.43)) + seed) * size.width * 0.045
        let wobble2  = sin(t * lerp(3.0, 5.5, fract(seed * 0.67)) + seed * 2.1) * size.width * 0.022

        // Fade in at birth (risePhase 0→0.15), fade out near tip (0.75→1.0)
        let birthFade = smoothStep(0, 0.15, risePhase)
        let deathFade = 1.0 - smoothStep(0.72, 1.0, risePhase)
        let alpha     = birthFade * deathFade

        guard alpha > 0.01 else { return }

        // Build tapered wisp path — 4-point bezier ribbon
        let cx      = baseX + wobble1 + wobble2
        let path    = taperedWispPath(
            cx: cx,
            bottomY: bottomY,
            topY: topY,
            baseWidth: baseWidth,
            wispH: wispH
        )

        // Colour: base = magenta-pink, tip = deep purple
        // We draw the wisp twice:
        //   pass 1 — wide blur  (outer glow / heat haze)
        //   pass 2 — tight blur (bright core)

        let baseColor = lerpColor(
            Color(red: 1.0,  green: 0.15, blue: 0.55),   // hot pink
            Color(red: 0.72, green: 0.10, blue: 0.90),   // magenta-violet
            fract(seed * 0.19)
        )
        let tipColor = Color(red: 0.25, green: 0.02, blue: 0.55) // deep purple

        let gradient = Gradient(stops: [
            .init(color: baseColor.opacity(alpha * 0.90), location: 0.0),
            .init(color: baseColor.opacity(alpha * 0.55), location: 0.35),
            .init(color: tipColor.opacity(alpha  * 0.20), location: 0.78),
            .init(color: tipColor.opacity(0),             location: 1.0),
        ])

        // Pass 1 — diffuse outer glow
        ctx.drawLayer { g in
            g.addFilter(.blur(radius: lerp(8, 18, fract(seed * 0.41))))
            g.fill(
                path,
                with: .linearGradient(
                    gradient,
                    startPoint: CGPoint(x: cx, y: bottomY),
                    endPoint:   CGPoint(x: cx, y: topY)
                )
            )
        }

        // Pass 2 — bright tight core (thinner path, less blur)
        let corePath = taperedWispPath(
            cx: cx,
            bottomY: bottomY,
            topY: topY + wispH * 0.12,
            baseWidth: baseWidth * 0.38,
            wispH: wispH * 0.88
        )
        ctx.drawLayer { g in
            g.addFilter(.blur(radius: lerp(2, 5, fract(seed * 0.53))))
            g.fill(
                corePath,
                with: .linearGradient(
                    Gradient(stops: [
                        .init(color: Color.white.opacity(alpha * 0.55), location: 0.0),
                        .init(color: baseColor.opacity(alpha * 0.40),   location: 0.40),
                        .init(color: tipColor.opacity(0),               location: 1.0),
                    ]),
                    startPoint: CGPoint(x: cx, y: bottomY),
                    endPoint:   CGPoint(x: cx, y: topY)
                )
            )
        }
    }

    // ─────────────────────────────────────────────
    // MARK: Path builder
    // ─────────────────────────────────────────────

    /// Tapered ribbon: full width at bottom, zero at top.
    /// Two cubic bezier sides give it a slight organic curve.
    private func taperedWispPath(
        cx: Double,
        bottomY: Double,
        topY: Double,
        baseWidth: Double,
        wispH: Double
    ) -> Path {
        var p = Path()
        let halfW  = baseWidth / 2
        // Control point pulls the sides inward 1/3 of the way up
        let ctrl1Y = bottomY - wispH * 0.33
        let ctrl2Y = bottomY - wispH * 0.66

        // left side — bottom-left → top (tapers to point)
        p.move(to: CGPoint(x: cx - halfW, y: bottomY))
        p.addCurve(
            to:      CGPoint(x: cx,        y: topY),
            control1: CGPoint(x: cx - halfW * 0.7, y: ctrl1Y),
            control2: CGPoint(x: cx - halfW * 0.2, y: ctrl2Y)
        )
        // right side — top → bottom-right
        p.addCurve(
            to:      CGPoint(x: cx + halfW, y: bottomY),
            control1: CGPoint(x: cx + halfW * 0.2, y: ctrl2Y),
            control2: CGPoint(x: cx + halfW * 0.7, y: ctrl1Y)
        )
        p.closeSubpath()
        return p
    }

    // ─────────────────────────────────────────────
    // MARK: Math helpers
    // ─────────────────────────────────────────────

    private func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double { a + (b - a) * t }
    private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: Double) -> CGFloat {
        CGFloat(lerp(Double(a), Double(b), t))
    }
    private func fract(_ x: Double) -> Double { x - floor(x) }
    private func easeInQuad(_ t: Double) -> Double { t * t }
    private func smoothStep(_ edge0: Double, _ edge1: Double, _ x: Double) -> Double {
        let t = max(0, min(1, (x - edge0) / (edge1 - edge0)))
        return t * t * (3 - 2 * t)
    }

    private func lerpColor(_ a: Color, _ b: Color, _ t: Double) -> Color {
        let t = max(0, min(1, t))
        // Resolve to UIColor for component access
        let ua = UIColor(a), ub = UIColor(b)
        var (r1,g1,b1,a1): (CGFloat,CGFloat,CGFloat,CGFloat) = (0,0,0,0)
        var (r2,g2,b2,a2): (CGFloat,CGFloat,CGFloat,CGFloat) = (0,0,0,0)
        ua.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        ub.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return Color(
            red:   Double(r1 + (r2-r1) * t),
            green: Double(g1 + (g2-g1) * t),
            blue:  Double(b1 + (b2-b1) * t),
            opacity: Double(a1 + (a2-a1) * t)
        )
    }
}

```

---

## File: `Open Lightly/Design/Components/Effects/GlowOrb.swift` {#file-open-lightly-design-components-effects-gloworb-swift}

```swift
//
//  GlowOrb.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

// ✅ Design system audit — verified March 9, 2026

import SwiftUI

struct GlowOrb: View {
    @Environment(\.theme) private var t
    let color: Color
    var size: CGFloat = 200

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [color, .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: size / 2
                )
            )
            .frame(width: size, height: size)
            .blur(radius: 40)
            .opacity(t.glowOpacity)
            .allowsHitTesting(false)
    }
}

```

---

## File: `Open Lightly/Design/Components/Effects/HolographicShimmer.swift` {#file-open-lightly-design-components-effects-holographicshimmer-swift}

```swift
import SwiftUI

/// Self-contained animated holographic shimmer fill.
/// Renders a 3× wide neon gradient that sweeps left→right continuously.
///
/// Use as a background layer clipped to any shape:
/// ```swift
/// Capsule()
///     .fill(AppColors.surfaceBg)
///     .overlay { HolographicShimmer().clipShape(Capsule()) }
/// ```
struct HolographicShimmer: View {
    /// Animation duration in seconds. Defaults to 6 (gentle sweep).
    var duration: Double = 6

    @State private var phase: CGFloat = 0

    private let colors: [Color] = [
        AppColors.cyan.opacity(0.50),
        AppColors.purple.opacity(0.45),
        AppColors.magenta.opacity(0.45),
        AppColors.pink.opacity(0.40),
        AppColors.cyan.opacity(0.40),
    ]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
                .frame(width: w * 3, height: geo.size.height)
                .offset(x: phase * -w * 2)
        }
        .clipped()
        .onAppear {
            withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                phase = 1
            }
        }
    }
}

```

---

## File: `Open Lightly/Design/Components/Effects/LightAuraBloom.swift` {#file-open-lightly-design-components-effects-lightaurabloom-swift}

```swift
//
//  LightAuraBloom.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/26/26.
//


// Design/Components/Effects/LightAuraBloom.swift
// Open Lightly
//
// Light-mode analogue of FlameAura.
// Renders layered, animated warm blobs that rise above
// a selected pill on a cream/white background.
// Uses rose / peach / gold / lavender — all visible on light surfaces.

import SwiftUI
import Combine

struct LightAuraBloom: View {

    let intensity: SelectablePill.Intensity

    // ── tuneable per-intensity values ──────────────────────────────
    private var blobOpacity: Double {
        switch intensity {
        case .dim:   return 0.30
        case .warm:  return 0.48
        case .alive: return 0.62
        }
    }

    private var bloomHeight: CGFloat {
        switch intensity {
        case .dim:   return 0          // .dim never shows flame/bloom
        case .warm:  return 70
        case .alive: return 100
        }
    }

    // ── animation state ───────────────────────────────────────────
    @State private var phase: Double = 0

    var body: some View {
        guard bloomHeight > 0 else { return AnyView(EmptyView()) }
        return AnyView(
            TimelineView(.animation) { timeline in
                Canvas { ctx, size in
                    let t = phase
                    drawBloom(ctx: &ctx, size: size, t: t)
                }
                .onAppear { phase = 0 }
                .onReceive(
                    Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()
                ) { _ in
                    phase += 0.012
                }
            }
            .allowsHitTesting(false)
        )
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: Drawing
    // ─────────────────────────────────────────────────────────────

    private func drawBloom(ctx: inout GraphicsContext, size: CGSize, t: Double) {
        let blobs: [(offsetX: Double, color: Color, scale: Double, phaseShift: Double)] = [
            // rose centre
            (offsetX:  0.00, color: Color(red: 1.00, green: 0.40, blue: 0.60),
             scale: 1.00, phaseShift: 0.00),
            // peach left
            (offsetX: -0.18, color: Color(red: 1.00, green: 0.65, blue: 0.45),
             scale: 0.78, phaseShift: 0.90),
            // gold right
            (offsetX:  0.20, color: Color(red: 1.00, green: 0.80, blue: 0.30),
             scale: 0.70, phaseShift: 1.60),
            // lavender far-left
            (offsetX: -0.30, color: Color(red: 0.78, green: 0.60, blue: 1.00),
             scale: 0.60, phaseShift: 2.40),
            // blush far-right
            (offsetX:  0.32, color: Color(red: 1.00, green: 0.55, blue: 0.75),
             scale: 0.55, phaseShift: 3.10),
        ]

        for blob in blobs {
            let waver   = sin(t * 1.8 + blob.phaseShift) * 0.06    // gentle horizontal sway
            let rise    = cos(t * 1.2 + blob.phaseShift) * 0.08    // breathing rise/fall
            let pulse   = 0.88 + sin(t * 2.0 + blob.phaseShift) * 0.12 // opacity pulse

            let cx = size.width  * (0.50 + blob.offsetX + waver)
            // blobs sit just above bottom edge and drift upward
            let cy = size.height * (0.75 + rise)

            let blobW = size.width  * blob.scale * 0.55
            let blobH = size.height * blob.scale * 0.60

            let rect = CGRect(
                x: cx - blobW / 2,
                y: cy - blobH / 2,
                width: blobW,
                height: blobH
            )

            // soft radial gradient per blob
            let gradient = Gradient(stops: [
                .init(color: blob.color.opacity(blobOpacity * pulse), location: 0.0),
                .init(color: blob.color.opacity(0),                   location: 1.0),
            ])

            ctx.drawLayer { inner in
                inner.addFilter(.blur(radius: 18 * blob.scale))
                inner.fill(
                    Path(ellipseIn: rect),
                    with: .radialGradient(
                        gradient,
                        center: CGPoint(x: cx, y: cy),
                        startRadius: 0,
                        endRadius: max(blobW, blobH) / 2
                    )
                )
            }
        }
    }
}

```

---

## File: `Open Lightly/Design/Components/Effects/LightModeShimmer.swift` {#file-open-lightly-design-components-effects-lightmodeshimmer-swift}

```swift
// LightModeShimmer.swift
// Open Lightly
//
// Rewritten to match HolographicShimmer's energy on cream surfaces.
//
// Key fixes vs original:
//   - Removed .multiply blend mode — was darkening colours into mud
//   - Added second diagonal pass at different speed — depth/foil feel
//   - Matched HolographicShimmer's normal compositing
//   - Kept warm palette (purple/magenta/gold) — no cyan on cream

import SwiftUI

struct LightModeShimmer: View {
    var duration: Double = 6
    var usePillColors: Bool = false

    @State private var phase1: CGFloat = 0   // primary horizontal sweep
    @State private var phase2: CGFloat = 0   // secondary diagonal sweep

    // Primary sweep — matches HolographicShimmer's colour slot count
    // and opacity range exactly. Only the hues differ (warm vs neon).
    private var primaryColors: [Color] {
        [
            AppColors.purple.opacity(0.55),
            AppColors.magenta.opacity(0.60),
            AppColors.gold.opacity(0.55),
            AppColors.magentaLight.opacity(0.58),
            AppColors.purple.opacity(0.55),
        ]
    }

    // Secondary pass — softer, offset palette
    // Sits on top of primary at lower opacity to create depth.
    // Diagonal start/end point fakes a 2D foil angle.
    private var secondaryColors: [Color] {
        [
            AppColors.gold.opacity(0.30),
            AppColors.purple.opacity(0.25),
            AppColors.magenta.opacity(0.28),
            AppColors.gold.opacity(0.22),
            AppColors.magentaLight.opacity(0.25),
        ]
    }

    // Background wash variant — same structure, lower opacity
    private var washColors: [Color] {
        AppColors.lightShimmerColors
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // ── Pass 1: primary horizontal sweep ─────────────────
                // Identical mechanics to HolographicShimmer.
                // No blend mode — normal compositing, colours at face value.
                LinearGradient(
                    colors: usePillColors ? primaryColors : washColors,
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: w * 3, height: h)
                .offset(x: phase1 * -w * 2)

                // ── Pass 2: secondary diagonal sweep (pills only) ─────
                // Offset diagonal gradient at 60% speed of primary.
                // Creates the illusion of depth — light catching a
                // different facet of the foil at a different angle.
                // Skipped for background wash — too busy on large surfaces.
                if usePillColors {
                    LinearGradient(
                        colors: secondaryColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: w * 3, height: h)
                    .offset(x: phase2 * -w * 2)
                    .blendMode(.screen)   // screen on cream = gentle brightening,
                                          // not the darkening that multiply caused
                }
            }
        }
        .clipped()
        .onAppear {
            // Primary sweep — same timing as HolographicShimmer
            withAnimation(
                .easeInOut(duration: usePillColors ? min(duration, 5.5) : duration)
                .repeatForever(autoreverses: true)
            ) {
                phase1 = 1
            }

            // Secondary sweep — 60% speed, starts offset so
            // the two passes are never in sync (avoids strobing)
            withAnimation(
                .easeInOut(duration: usePillColors ? min(duration, 5.5) * 1.65 : duration * 1.4)
                .repeatForever(autoreverses: true)
                .delay(0.8)
            ) {
                phase2 = 1
            }
        }
    }
}

```

---

## File: `Open Lightly/Design/Components/Effects/OnboardingGlowField.swift` {#file-open-lightly-design-components-effects-onboardingglowfield-swift}

```swift
// OnboardingGlowField.swift
// Open Lightly
//
// Atmospheric glow blob field shared across all onboarding screens.
// Extracted from OnboardingNameView's inline glowField implementation.
// Usage: OnboardingGlowField() — manages its own animation state.
import SwiftUI

struct OnboardingGlowField: View {
    @State private var blobVisible: [Bool]    = Array(repeating: false, count: 7)
    @State private var blobPhase:   [CGFloat] = Array(repeating: 0,     count: 7)
    @State private var hasStarted = false

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                // Cyan — upper-left
                blob(AppColors.cyan,  0.32, 300, 280, 75, 0)
                    .offset(x: sin(blobPhase[0] * .pi * 2) * 12,
                            y: sin(blobPhase[0] * .pi * 2 + .pi / 3) * 14)
                    .position(x: w * 0.22, y: h * 0.20)

                // Purple — center
                blob(AppColors.purple, 0.28, 380, 360, 75, 1)
                    .scaleEffect(blobVisible[1] ? 1 + 0.06 * sin(blobPhase[1] * .pi * 2) : 0.7)
                    .offset(x: sin(blobPhase[1] * .pi * 2) * 4)
                    .position(x: w * 0.50, y: h * 0.40)

                // Magenta — right edge
                blob(AppColors.magenta, 0.24, 280, 300, 75, 2)
                    .offset(x: sin(blobPhase[2] * .pi * 2) * -10,
                            y: cos(blobPhase[2] * .pi * 2) * 12)
                    .position(x: w * 0.88, y: h * 0.33)

                // Gold — warm accent
                blob(AppColors.goldLight, 0.12, 200, 180, 80, 3)
                    .offset(x: sin(blobPhase[3] * .pi) * 8,
                            y: sin(blobPhase[3] * .pi) * -6)
                    .position(x: w * 0.20, y: h * 0.48)

                // Magenta — mid-left
                blob(AppColors.magenta, 0.15, 300, 220, 85, 4)
                    .scaleEffect(blobVisible[4] ? 1 + 0.05 * sin(blobPhase[4] * .pi * 2) : 0.7)
                    .offset(x: sin(blobPhase[4] * .pi) * 8,
                            y: sin(blobPhase[4] * .pi) * -6)
                    .position(x: w * 0.18, y: h * 0.60)

                // Floor wash
                Ellipse()
                    .fill(RadialGradient(stops: [
                        .init(color: AppColors.deepBlue.opacity(0.12), location: 0),
                        .init(color: AppColors.purple.opacity(0.08),   location: 0.4),
                        .init(color: .clear,                           location: 0.7)
                    ], center: .center, startRadius: 0, endRadius: 200))
                    .frame(width: 420, height: 180)
                    .blur(radius: 90)
                    .scaleEffect(blobVisible[5] ? 1 + 0.06 * sin(blobPhase[5] * .pi * 2) : 0.7)
                    .opacity(blobVisible[5] ? 1 : 0)
                    .offset(x: sin(blobPhase[5] * .pi * 2) * 4)
                    .position(x: w * 0.5, y: h * 0.80)

                // Cyan accent — bottom
                blob(AppColors.cyan, 0.08, 240, 150, 90, 6)
                    .offset(x: sin(blobPhase[6] * .pi * 2) * -8)
                    .position(x: w * 0.45, y: h * 0.88)
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            guard !hasStarted else { return }
            hasStarted = true
            startAtmosphere()
        }
    }

    // MARK: - Blob builder

    @ViewBuilder
    private func blob(_ color: Color, _ opacity: Double, _ w: CGFloat, _ h: CGFloat, _ blur: CGFloat, _ i: Int) -> some View {
        Ellipse()
            .fill(color.opacity(opacity))
            .frame(width: w, height: h)
            .blur(radius: blur)
            .scaleEffect(blobVisible[i] ? 1.0 : 0.7)
            .opacity(blobVisible[i] ? 1 : 0)
    }

    // MARK: - Animation orchestration

    private func startAtmosphere() {
        let fadeDelays:    [Double] = [0.1, 0.2, 0.3, 0.35, 0.4,  0.5,  0.6]
        let fadeDurations: [Double] = [0.9, 1.0, 0.9, 1.0,  1.0,  1.2,  1.0]
        let loopDurations: [Double] = [8,   10,  9,   11,   12,   14,   10]
        let loopDelays:    [Double] = [0.8, 1.0, 1.2, 1.3,  1.5,  1.6,  1.8]

        for i in 0..<7 {
            withAnimation(.easeInOut(duration: fadeDurations[i]).delay(fadeDelays[i])) {
                blobVisible[i] = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + loopDelays[i]) {
                withAnimation(.linear(duration: loopDurations[i]).repeatForever(autoreverses: false)) {
                    blobPhase[i] = 1.0
                }
            }
        }
    }
}

#Preview {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        OnboardingGlowField()
    }
}

```

---

## File: `Open Lightly/Design/Components/Effects/SparkField.swift` {#file-open-lightly-design-components-effects-sparkfield-swift}

```swift
// SparkField.swift
// Open Lightly
//
// Campfire ember particle system for light mode screens.
// Standalone Canvas-based component — place alongside AuroraGlowField
// in the screen background stack.
//
// Palette: warm ember colors — deep magenta, hot pink, gold, amber,
//          rose, warm gold, deep rose, orange-amber.
//          Matches the StatView HTML mockup exactly.
//
// Usage:
//   ZStack {
//       AppColors.lightPageBg.ignoresSafeArea()
//       AuroraGlowField().ignoresSafeArea()
//       SparkField(config: .statView).ignoresSafeArea()
//       // content
//   }
//
// Screen configs:
//   .statView            — Screen 1, free travel, no fade
//   .nameView            — Screen 3, fades before glass card
//   .modeSelectView      — Screen 4, stays in lower third
//   .contextView         — Screen 5, very subtle, early fade
//   .curiosityPickerView — Screen 6, minimal, bottom only
//   .groundRulesView     — Screen 8, confined to bottom quarter
//
// BrandView (Screen 2) and BuildingPathView (Screen 7)
// are permanently dark — never use SparkField on those screens.
//
// Always: .allowsHitTesting(false)
// Always: placed in background, never over content
// Light mode only — never use on dark screens
//
// Architecture notes:
//   - SparkSystem is @StateObject — each SparkField instance owns its
//     own isolated particle state. No singleton. Safe for overlapping
//     views, navigation transitions, and sheet presentations.
//   - plusLighter blend is applied INSIDE the Canvas GraphicsContext only.
//     Sparks glow additively against each other within the offscreen texture.
//     The texture itself composites normally (.normal) against the scene,
//     preserving ember colors against the cream background.
//   - .compositingGroup() on the view seals the layer so sparks physically
//     sit below all ZStack siblings placed after SparkField.

import Combine
import SwiftUI

// ─────────────────────────────────────────────
// MARK: SparkConfiguration
// One config per screen. Defined once, used everywhere.
// Tune numbers here — never inside Particle or SparkSystem.
// ─────────────────────────────────────────────

struct SparkConfiguration {

    // Number of simultaneous sparks
    var count: Int

    // Rise speed — base + variance
    // vy = -(baseSpeed + random * speedVariance)
    var baseSpeed: Double
    var speedVariance: Double

    // Dot size
    var radiusMin: Double
    var radiusMax: Double

    // Glow halo multiplier applied to radius
    var glowMultiplierMin: Double
    var glowMultiplierMax: Double

    // Opacity ceiling — how bright sparks get at peak
    // Tuned per screen: brighter on open screens, dimmer under content
    var opacityCeilMin: Double
    var opacityCeilMax: Double

    // Spawn X range (normalised 0–1)
    var spawnXMin: Double
    var spawnXMax: Double

    // Spawn Y on respawn (normalised 0–1, 1 = bottom)
    // Particles born here when they respawn after lifespan ends
    var respawnYMin: Double

    // Spatial fade zone (normalised 0–1, y decreases as particle rises)
    // nil = no fade — particle travels until lifecycle ends naturally
    // fadeStartY: fade begins (full opacity below this)
    // fadeEndY:   fully transparent (above this y, particle invisible)
    // fadeStartY must be > fadeEndY (y decreases as particle rises)
    var fadeStartY: Double?
    var fadeEndY: Double?

    // Palette override — nil uses the default warm ember palette
    // Provide a custom palette to shift color character per screen
    var palette: [(r: Double, g: Double, b: Double)]?
}

// ─────────────────────────────────────────────
// MARK: Per-screen configurations
// ─────────────────────────────────────────────

extension SparkConfiguration {

    // Default warm ember palette — shared across all screens.
    // Matches the StatView HTML mockup warmPalette exactly.
    static let defaultPalette: [(r: Double, g: Double, b: Double)] = [
        (r: 220/255, g:  30/255, b:  90/255),  // deep magenta   — boosted red channel
        (r: 255/255, g:   0/255, b: 106/255),  // hot pink       — unchanged #FF006A
        (r: 215/255, g: 110/255, b:   0/255),  // amber-gold     — green reduced, warmer
        (r: 240/255, g:  70/255, b:  10/255),  // hot amber      — red pushed, green dropped
        (r: 210/255, g:  10/255, b:  80/255),  // rose           — more saturated
        (r: 255/255, g: 130/255, b:   0/255),  // pure warm gold — green floor raised
        (r: 200/255, g:  20/255, b:  70/255),  // deep rose      — direction unchanged
        (r: 250/255, g:  90/255, b:  20/255),  // hot orange     — red channel maximised
    ]

    // ── Screen 1: StatView ────────────────────
    // No cards. Full vertical travel. No spatial fade.
    // Most expressive — stat number is the hero, sparks
    // surround it freely across the full screen height.
    // Matches HTML StatView mockup: count 28, speed 0.27–0.45.
    static let statView = SparkConfiguration(
        count:             28,
        baseSpeed:         0.27,
        speedVariance:     0.18,
        radiusMin:         0.65,
        radiusMax:         2.00,
        glowMultiplierMin: 4.0,
        glowMultiplierMax: 6.2,
        opacityCeilMin:    0.48,
        opacityCeilMax:    0.75,
        spawnXMin:         0.10,
        spawnXMax:         0.90,
        respawnYMin:       0.55,
        fadeStartY:        nil,   // full travel — no fade
        fadeEndY:          nil,
        palette:           nil    // default warm ember
    )

    // ── Screen 3: NameView ────────────────────
    // Glass card: y ~0.28–0.72.
    // Sparks spawn below, dissolve before card edge.
    // Form screen — quieter than StatView.
    static let nameView = SparkConfiguration(
        count:             22,
        baseSpeed:         0.27,
        speedVariance:     0.18,
        radiusMin:         0.65,
        radiusMax:         2.00,
        glowMultiplierMin: 4.0,
        glowMultiplierMax: 6.2,
        opacityCeilMin:    0.42,
        opacityCeilMax:    0.65,
        spawnXMin:         0.12,
        spawnXMax:         0.88,
        respawnYMin:       0.55,
        fadeStartY:        0.58, // dissolve begins here
        fadeEndY:          0.44, // fully gone — well below card edge
        palette:           nil
    )

    // ── Screen 4: ModeSelectView ──────────────
    // Three mode cards start ~y 0.35, experience pills below.
    // Sparks confined to lower half. Quieter density.
    // ScrollView content means particles should not rise
    // high enough to be visible behind text.
    static let modeSelectView = SparkConfiguration(
        count:             18,
        baseSpeed:         0.22,
        speedVariance:     0.14,
        radiusMin:         0.55,
        radiusMax:         1.70,
        glowMultiplierMin: 3.5,
        glowMultiplierMax: 5.5,
        opacityCeilMin:    0.33,
        opacityCeilMax:    0.54,
        spawnXMin:         0.12,
        spawnXMax:         0.88,
        respawnYMin:       0.62,  // born lower than other screens
        fadeStartY:        0.55,
        fadeEndY:          0.40,
        palette:           nil
    )

    // ── Screen 5: ContextView ─────────────────
    // Gesture-driven card stack takes most of the screen.
    // Sparks must not compete with the drag interaction.
    // Very subtle — almost subliminal presence only.
    static let contextView = SparkConfiguration(
        count:             14,
        baseSpeed:         0.20,
        speedVariance:     0.12,
        radiusMin:         0.50,
        radiusMax:         1.50,
        glowMultiplierMin: 3.0,
        glowMultiplierMax: 5.0,
        opacityCeilMin:    0.27,
        opacityCeilMax:    0.45,
        spawnXMin:         0.10,
        spawnXMax:         0.90,
        respawnYMin:       0.65,
        fadeStartY:        0.60,  // early fade — cards occupy mid-screen
        fadeEndY:          0.48,
        palette:           nil
    )

    // ── Screen 6: CuriosityPickerView ─────────
    // Dense ScrollView fills most of the screen from top.
    // Sparks barely there — content is the entire focus.
    // Lowest density and opacity in the flow.
    static let curiosityPickerView = SparkConfiguration(
        count:             12,
        baseSpeed:         0.18,
        speedVariance:     0.10,
        radiusMin:         0.45,
        radiusMax:         1.30,
        glowMultiplierMin: 3.0,
        glowMultiplierMax: 4.5,
        opacityCeilMin:    0.22,
        opacityCeilMax:    0.36,
        spawnXMin:         0.10,
        spawnXMax:         0.90,
        respawnYMin:       0.70,  // born in bottom 30% only
        fadeStartY:        0.65,  // dissolve almost immediately after spawning
        fadeEndY:          0.52,
        palette:           nil
    )

    // ── Screen 8: GroundRulesView ─────────────
    // ScrollView with promise cards + italic line + pinned CTA.
    // Sparks confined to bottom quarter. Very dim.
    // Must not distract from the must-read content.
    static let groundRulesView = SparkConfiguration(
        count:             14,
        baseSpeed:         0.18,
        speedVariance:     0.10,
        radiusMin:         0.45,
        radiusMax:         1.30,
        glowMultiplierMin: 3.0,
        glowMultiplierMax: 4.5,
        opacityCeilMin:    0.24,
        opacityCeilMax:    0.40,
        spawnXMin:         0.10,
        spawnXMax:         0.90,
        respawnYMin:       0.72,  // bottom quarter only
        fadeStartY:        0.68,
        fadeEndY:          0.56,
        palette:           nil
    )
}

// ─────────────────────────────────────────────
// MARK: SparkField View
// ─────────────────────────────────────────────

struct SparkField: View {

    var config: SparkConfiguration = .statView

    // Each SparkField instance owns its own isolated particle system.
    // @StateObject persists across parent re-renders (e.g. keyboard
    // appearing, @State changes on the parent view) so particles are
    // never accidentally reset mid-animation.
    @StateObject private var system = SparkSystem()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1/30, paused: false)) { timeline in
            Canvas { context, size in
                // Reference timeline.date — required so SwiftUI
                // invalidates the Canvas on every tick.
                _ = timeline.date
                system.update(size: size)
                system.drawAll(context: context, size: size)
            }
        }
        // .compositingGroup() flattens this entire Canvas into one
        // offscreen Metal texture before it is composited into the
        // parent ZStack. This means every ZStack sibling placed AFTER
        // SparkField sits in a completely separate layer — sparks are
        // physically underneath buttons, cards, and text.
        //
        // NO .blendMode() here — normal alpha compositing against the
        // scene preserves ember colors on the cream background.
        // plusLighter lives only INSIDE the Canvas (see SparkSystem.drawAll)
        // where it blends sparks against each other, not against the bg.
        .compositingGroup()
        .allowsHitTesting(false)
        .onAppear {
            system.configure(config)
        }
    }
}

// ─────────────────────────────────────────────
// MARK: SparkSystem
// Owns all particle state. ObservableObject so @StateObject
// in SparkField holds a stable reference across re-renders.
// No singleton — each SparkField gets its own instance.
// Safe for overlapping views, navigation transitions, sheets.
// ─────────────────────────────────────────────

final class SparkSystem: ObservableObject {

    // Explicit publisher satisfies ObservableObject without @Published.
    // SparkSystem never needs to push UI updates through Combine —
    // the Canvas refreshes via TimelineView, not objectWillChange.
    // Declared explicitly because the compiler cannot synthesise
    // conformance when no @Published properties are present.
    let objectWillChange = ObservableObjectPublisher()

    private var particles: [Particle] = []
    private var activeConfig: SparkConfiguration = .statView

    func configure(_ config: SparkConfiguration) {
        // Always fully reconfigure — no one-time flag.
        // .onAppear is naturally scoped to the view lifetime,
        // so this is only called when the view actually appears.
        activeConfig = config
        let palette = config.palette ?? SparkConfiguration.defaultPalette
        particles = (0..<config.count).map { _ in
            Particle(config: config, palette: palette, initial: true)
        }
    }

    func update(size: CGSize) {
        let palette = activeConfig.palette ?? SparkConfiguration.defaultPalette
        for i in particles.indices {
            particles[i].update(bounds: size, config: activeConfig, palette: palette)
        }
    }

    func drawAll(context: GraphicsContext, size: CGSize) {
        // plusLighter INSIDE the Canvas only.
        // Sparks that overlap each other add light together — correct
        // ember glow behaviour. The offscreen texture produced by
        // .compositingGroup() then composites normally against the scene,
        // so the cream background is never additively blown out to white.
        var blendedContext = context
        blendedContext.blendMode = .plusLighter

        for particle in particles {
            let px = particle.x * size.width
            let py = particle.y * size.height
            particle.drawAt(context: blendedContext, px: px, py: py)
        }
    }
}

// ─────────────────────────────────────────────
// MARK: Particle
// Value type — one ember spark.
// x and y are stored normalised (0–1).
// Converted to pixels in SparkSystem.drawAll().
// All physics values read from SparkConfiguration —
// nothing hardcoded here.
// ─────────────────────────────────────────────

private struct Particle {

    var x: Double
    var y: Double
    var vy: Double
    var vx: Double
    var driftAmp:    Double
    var driftFreq:   Double
    var driftPhase:  Double
    var radius:      Double
    var glowRadius:  Double
    var frame:       Double
    var totalFrames: Double
    var opacityCeil: Double
    var fadeStartY:  Double?
    var fadeEndY:    Double?
    var r: Double
    var g: Double
    var b: Double

    // ── Init ──────────────────────────────────────

    init(
        config: SparkConfiguration,
        palette: [(r: Double, g: Double, b: Double)],
        initial: Bool
    ) {
        let c = palette[Int.random(in: 0..<palette.count)]
        r = c.r; g = c.g; b = c.b

        x = config.spawnXMin + Double.random(in: 0..<(config.spawnXMax - config.spawnXMin))

        // Initial spread: y 0.15–1.0 so all vertical zones populated on first appear
        // Respawn: born near bottom per config.respawnYMin
        y = initial
            ? (0.15 + Double.random(in: 0..<0.85))
            : (config.respawnYMin + Double.random(in: 0..<(1.0 - config.respawnYMin)))

        radius = config.radiusMin + Double.random(in: 0..<(config.radiusMax - config.radiusMin))

        let spd = config.baseSpeed
        let variance = config.speedVariance
        vy = -(spd + Double.random(in: 0..<variance))
        vx = (Double.random(in: 0..<1.0) - 0.5) * 0.20

        driftAmp   = 0.5 + Double.random(in: 0..<0.9)
        driftFreq  = 0.007 + Double.random(in: 0..<0.011)
        driftPhase = Double.random(in: 0..<(.pi * 2))

        totalFrames = 180 + Double.random(in: 0..<240)
        frame       = initial ? Double.random(in: 0..<totalFrames) : 0

        let glowMult = config.glowMultiplierMin
            + Double.random(in: 0..<(config.glowMultiplierMax - config.glowMultiplierMin))
        glowRadius = radius * glowMult

        opacityCeil = config.opacityCeilMin
            + Double.random(in: 0..<(config.opacityCeilMax - config.opacityCeilMin))

        // Store fade zone per particle so update() can read it without config reference
        fadeStartY = config.fadeStartY
        fadeEndY   = config.fadeEndY
    }

    // ── Opacity curve ─────────────────────────────
    // Lifecycle: ease in (0→0.15), hold (0.15→0.66), ease out (0.66→1.0)
    // Spatial:   dissolve as particle rises into content zone.
    //            nil fadeStartY = no spatial fade.

    var opacity: Double {
        let t = frame / totalFrames

        // Lifecycle curve
        let lifeCurve: Double
        if t < 0.14      { lifeCurve = (t / 0.14) * opacityCeil }
        else if t < 0.66 { lifeCurve = opacityCeil }
        else             { lifeCurve = ((1.0 - t) / 0.34) * opacityCeil }

        // Spatial fade — only applied when config provides fade zone
        guard let startY = fadeStartY, let endY = fadeEndY else {
            return lifeCurve   // no fade — full travel
        }
        let spatialFade: Double
        if y > startY {
            spatialFade = 1.0
        } else if y < endY {
            spatialFade = 0.0
        } else {
            spatialFade = (y - endY) / (startY - endY)
        }
        return lifeCurve * spatialFade
    }

    // ── Update ────────────────────────────────────

    mutating func update(
        bounds: CGSize,
        config: SparkConfiguration,
        palette: [(r: Double, g: Double, b: Double)]
    ) {
        frame += 1

        let pixelY = y * bounds.height
        if frame >= totalFrames || pixelY < -20 {
            self = Particle(config: config, palette: palette, initial: false)
            return
        }

        let sine = sin(frame * driftFreq + driftPhase)
        x += (vx + sine * driftAmp * 0.032) / bounds.width
        y += vy / bounds.height
        vy *= 1.0012
    }

    // ── Draw ──────────────────────────────────────
    // Three layers: smooth radial gradient halo → crisp dot → hot white core.

    func drawAt(context: GraphicsContext, px: Double, py: Double) {
        let op = opacity
        guard op > 0.01 else { return }

        let baseColor = Color(red: r, green: g, blue: b)

        // Layer 1: Smooth Radial Gradient Halo
        let haloGradient = Gradient(stops: [
            .init(color: baseColor.opacity(op * 0.72), location: 0.0),
            .init(color: baseColor.opacity(op * 0.32), location: 0.40),
            .init(color: baseColor.opacity(op * 0.08), location: 0.75),
            .init(color: baseColor.opacity(0.0),       location: 1.0)
        ])

        let haloRect = CGRect(
            x: px - glowRadius, y: py - glowRadius,
            width: glowRadius * 2, height: glowRadius * 2
        )
        context.fill(
            Path(ellipseIn: haloRect),
            with: .radialGradient(
                haloGradient,
                center: CGPoint(x: px, y: py),
                startRadius: 0,
                endRadius: glowRadius
            )
        )

        // Layer 2: Crisp dot
        let dotRect = CGRect(
            x: px - radius, y: py - radius,
            width: radius * 2, height: radius * 2
        )
        context.fill(Path(ellipseIn: dotRect), with: .color(baseColor.opacity(op * 1.0)))

        // Layer 3: Hot white core for larger sparks
        if radius > 0.7 {
            let coreR = radius * 0.40
            let coreRect = CGRect(
                x: px - coreR, y: py - coreR,
                width: coreR * 2, height: coreR * 2
            )
            context.fill(
                Path(ellipseIn: coreRect),
                with: .color(Color.white.opacity(op * 0.65))
            )
        }
    }
}

// ─────────────────────────────────────────────
// MARK: Previews
// ─────────────────────────────────────────────

#Preview("StatView — full travel") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        AuroraGlowField().ignoresSafeArea()
        SparkField(config: .statView).ignoresSafeArea()
        VStack {
            Spacer()
            Text("1 in 5")
                .font(.system(size: 120, weight: .bold))
                .foregroundStyle(Color.orange)
            Spacer()
        }
    }
    .preferredColorScheme(.light)
}

#Preview("NameView — fades before card") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        AuroraGlowField().ignoresSafeArea()
        SparkField(config: .nameView).ignoresSafeArea()
        VStack {
            Spacer().frame(height: 200)
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .frame(height: 340)
                .padding(.horizontal, 28)
            Spacer()
        }
    }
    .preferredColorScheme(.light)
}

#Preview("ModeSelectView — lower third") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        AuroraGlowField().ignoresSafeArea()
        SparkField(config: .modeSelectView).ignoresSafeArea()
    }
    .preferredColorScheme(.light)
}

#Preview("ContextView — very subtle") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        AuroraGlowField().ignoresSafeArea()
        SparkField(config: .contextView).ignoresSafeArea()
    }
    .preferredColorScheme(.light)
}

#Preview("CuriosityPickerView — minimal") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        AuroraGlowField().ignoresSafeArea()
        SparkField(config: .curiosityPickerView).ignoresSafeArea()
    }
    .preferredColorScheme(.light)
}

#Preview("GroundRulesView — bottom quarter") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        AuroraGlowField().ignoresSafeArea()
        SparkField(config: .groundRulesView).ignoresSafeArea()
        VStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .frame(height: 500)
                .padding(.horizontal, 24)
                .padding(.top, 80)
            Spacer()
        }
    }
    .preferredColorScheme(.light)
}

```

---

## File: `Open Lightly/Design/Components/Input/InteractiveField.swift` {#file-open-lightly-design-components-input-interactivefield-swift}

```swift
//
//  InteractiveField.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//


import SwiftUI

struct InteractiveField: View {
    @Environment(\.theme) private var t
    let placeholder: String
    let icon: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 8) {
            Text(icon)
                .font(.system(size: 13))
            TextField(placeholder, text: $text)
                .font(.system(size: 12))
                .foregroundStyle(t.text)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            t.isAmoled ? .white.opacity(0.03) : t.surface1
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(t.cardBorder, lineWidth: 1.5)
        )
        .shadow(
            color: t.isAmoled ? t.glowCyan : .clear,
            radius: 6
        )
    }
}
```

---

## File: `Open Lightly/Design/Components/Input/RatingButtonGroup.swift` {#file-open-lightly-design-components-input-ratingbuttongroup-swift}

```swift
// ✅ Design system audit — verified March 9, 2026

import SwiftUI

// MARK: - RatingButtonGroup
// 2x2 grid of rating buttons for Desire Map
// (Arrows replaced: use <- and -> in comments, not unicode)
struct RatingButtonGroup: View {
    @Binding var selected: DesireLevel?

    private let ratings: [DesireLevel] = [.excitedAboutIt, .openToIt, .probablyNot, .notForMe]
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(ratings, id: \.self) { rating in
                let isSelected = selected == rating
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        if isSelected {
                            selected = nil
                        } else {
                            selected = rating
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                } label: {
                    VStack(spacing: 4) {
                        Text(rating.displayLabel)
                            .font(AppFonts.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.textPrimary)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected
                                ? accentColor(for: rating).opacity(0.06)
                                : AppColors.card)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected
                                ? accentColor(for: rating)
                                : AppColors.border, lineWidth: 1.5)
                    )
                    .scaleEffect(isSelected ? 0.97 : 1.0)
                    .animation(.spring(response: 0.3), value: isSelected)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 2)
    }

    private func accentColor(for rating: DesireLevel) -> Color {
        switch rating {
        case .excitedAboutIt: return AppColors.magenta
        case .openToIt:       return AppColors.cyan
        case .probablyNot:    return Color.white.opacity(0.5)
        case .notForMe:       return AppColors.gold
        }
    }
}

// MARK: - Preview
struct RatingButtonGroup_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            RatingButtonGroup(selected: .constant(nil))
                .padding()
        }
        .preferredColorScheme(.dark)
    }
}

```

---

## File: `Open Lightly/Design/Components/Input/ToggleRow.swift` {#file-open-lightly-design-components-input-togglerow-swift}

```swift
import SwiftUI

/// Icon + label + Toggle row used in Settings sections.
/// Usage: `ToggleRow(icon: "waveform", iconColor: AppColors.magenta, label: "Haptic Feedback", isOn: $hapticFeedback)`
struct ToggleRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(iconColor)

            Text(label)
                .font(AppFonts.bodyMedium)
                .foregroundColor(AppColors.textPrimary)

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(AppColors.toggleActive)
        }
    }
}

```

---

## File: `Open Lightly/Design/Components/Navigation/OnboardingFooter.swift` {#file-open-lightly-design-components-navigation-onboardingfooter-swift}

```swift
// OnboardingFooter.swift
// Open Lightly
//
// Footer shown below the CTA on onboarding screens.

import SwiftUI

struct OnboardingFooter: View {
    var text: String = "Your data is encrypted and always stays yours."

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Text(text)
            .font(.system(size: 12))
            .foregroundColor(colorScheme == .light
                ? AppColors.lightTextTertiary
                : Color(red: 0.42, green: 0.42, blue: 0.50))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, 12)
            .padding(.bottom, 24)
    }
}

#Preview {
    VStack(spacing: 0) {
        // Dark
        ZStack {
            AppColors.pageBg.ignoresSafeArea()
            VStack {
                OnboardingFooter()
                OnboardingFooter(text: "Custom footer copy for another screen.")
            }
        }
        .preferredColorScheme(.dark)
        .frame(maxWidth: .infinity)

        // Light
        ZStack {
            AppColors.lightPageBg.ignoresSafeArea()
            VStack {
                OnboardingFooter()
                OnboardingFooter(text: "Custom footer copy for another screen.")
            }
        }
        .preferredColorScheme(.light)
        .frame(maxWidth: .infinity)
    }
}

```

---

## File: `Open Lightly/Design/Components/Navigation/OnboardingNavBar.swift` {#file-open-lightly-design-components-navigation-onboardingnavbar-swift}

```swift
// OnboardingNavBar.swift
// Open Lightly
//
// Reusable nav row: back chevron + centered progress bar.
// Used at the top of every onboarding screen that shows navigation.
import SwiftUI

// MARK: - Private Modifiers

private struct BackButtonModifier: ViewModifier {
    let colorScheme: ColorScheme

    func body(content: Content) -> some View {
        if colorScheme == .light {
            content
                .padding(13)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.55))
                        .overlay(
                            Circle()
                                .strokeBorder(AppColors.warmAuroraBorder, lineWidth: 2.0)
                        )
                        
                )
                .shadow(color: AppColors.magenta.opacity(0.12), radius: 8, y: 2)
                .shadow(color: AppColors.purple.opacity(0.08), radius: 16, y: 2)
        } else {
            content
                .padding(13)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [AppColors.cyan, AppColors.purple, AppColors.magenta],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2.0
                                )
                        )
                       
                )
                .shadow(color: AppColors.purple.opacity(0.22), radius: 8)
                .shadow(color: AppColors.cyan.opacity(0.12), radius: 20)
                .shadow(color: AppColors.purple.opacity(0.08), radius: 28)
        }
    }
}

// MARK: - View

struct OnboardingNavBar: View {
    let currentStep: Int
    let totalSteps: Int
    var onBack: (() -> Void)?  // nil = no back button (ground rules, priming, arrival)
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            if let onBack {
                Button(action: onBack) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(colorScheme == .light
                                         ? AppColors.wineDark
                                         : Color.white.opacity(0.80))
                        .modifier(BackButtonModifier(colorScheme: colorScheme))
                }
                .accessibilityLabel("Go back")
            } else {
                // Match the 38pt rendered size of the back button
                Color.clear.frame(width: 38, height: 38)
                    .padding(.trailing, 0) 
            }
            
            Spacer()
            OnboardingProgressBar(currentStep: currentStep, totalSteps: totalSteps)
            Spacer()
            
            // FIXED: was 18pt — must match back button total size (18 icon + 10 pad each side = 38)
            Color.clear.frame(width: 38, height: 38)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        // Dark
        ZStack {
            AppColors.pageBg.ignoresSafeArea()
            VStack(spacing: 40) {
                OnboardingNavBar(currentStep: 1, totalSteps: 6, onBack: { })
                OnboardingNavBar(currentStep: 3, totalSteps: 6, onBack: nil)
            }
            .padding(24)
        }
        .preferredColorScheme(.dark)
        .frame(maxWidth: .infinity)

        // Light
        ZStack {
            AppColors.lightPageBg.ignoresSafeArea()
            VStack(spacing: 40) {
                OnboardingNavBar(currentStep: 1, totalSteps: 6, onBack: { })
                OnboardingNavBar(currentStep: 3, totalSteps: 6, onBack: nil)
            }
            .padding(24)
        }
        .preferredColorScheme(.light)
        .frame(maxWidth: .infinity)
    }
}

```

---

## File: `Open Lightly/Design/Components/Progress/OnboardingProgressBar.swift` {#file-open-lightly-design-components-progress-onboardingprogressbar-swift}

```swift
// OnboardingProgressBar.swift
// Open Lightly
//
// FULLY AUDITED & REFINED — v2.3  (visual quality pass)
//
// Changes in v2.3
// ───────────────────────────────────────────────────────
// VQ-01  shimmerCycleDuration default raised 2.4 → 3.0s.
//        At 2.4s the shimmer pulses at 25/min — reads as nervous.
//        3.0s aligns with reward animation research (cf. App Store
//        confetti timing) and simultaneously slows the bloom breathe
//        to ~20/min, closer to the 12–16/min respiratory target.
//
// VQ-02  Bloom atmo vertical spread scalars reduced:
//        Dark  base 3.5 → 2.8,  pulse 2.0 → 1.4
//        Light base 2.2 → 1.8,  pulse 1.1 → 0.8
//        Previous values produced 14–22pt spread on a 4pt bar.
//        New values produce 11–16pt dark / 9–13pt light — still
//        atmospheric but proportionate.
//
// VQ-03  Bloom atmo gradient gains a cyan stop at position 0 (dark)
//        and a deeper orangeDeep stop at 0 (light) to anchor the left
//        end of the bar's color identity into the atmospheric layer.
//        Previously atmo opened with purple, losing cyan entirely.
//
// VQ-04  Bloom atmo magenta opacity cap:
//        Dark:  0.80 → 0.70  (atmo center stop — was competing with fill)
//        Light: 0.80 → 0.50  (cream background — was creating pink cast)
//
// VQ-05  Bloom mid center stop opacity:
//        Light orangeHot 0.90 → 0.65  (too saturated on cream)
//        Dark  purple    0.90 → unchanged (correct)
//
// VQ-06  Bloom core base opacity:
//        Dark  0.50 → 0.38  (was competing with fill surface)
//        Light 0.22 → unchanged (well-calibrated)
//
// VQ-07  Bloom atmo blur base:
//        Light 4.5 → 3.5  (was spreading magenta too far on cream)
//        Dark  6.0 → unchanged
//
// VQ-08  Light mode fill gradient: magenta final stop opacity 0.75 → 0.55,
//        orangeHot mid stop location 0.5 → 0.65 — extends warm amber
//        longer before the pink arrival, reducing harsh colour jump.
//
// VQ-09  Light mode track opacity 0.06 → 0.09 — the rail was barely
//        legible at minimum contrast; 0.09 is structural without heavy.
//
// VQ-10  Shimmer outer blur radius 2 → 3pt — softens the rectangular
//        edge artifact visible at small blur on a 4pt bar.
//
// VQ-11  Shimmer inner opacity range light mode branch added:
//        Light: 0.32 + intensity×0.36  (dark: 0.28 + intensity×0.32)
//        White shimmer is less visible against orange fill; compensated.
//
// VQ-12  Particle rise height: base 10 → 14pt, variation ±3 → ±5pt
//        (range 9–19pt). Previous 7–13pt barely cleared the bloom halo.
//
// VQ-13  Particle ease exponent: base 2.0 → 2.2, variation ±0.5 → ±0.9
//        (range 1.3–3.1). Wider spread creates visible arc-vs-drift variety.
//
// VQ-14  Particle drift frequency: sin multiplier 2.1 → 1.8 per particle
//        index. Previous frequency clustered two particles at similar
//        rightward drift (+4.55, +3.27). New distribution is better spread.
//
// VQ-15  Particle wobble amplitude: easeOut×2 → easeOut×3.5.
//        Previous 2pt max lateral movement was sub-perceptual.
//
// VQ-16  Particle fade-in window: 0–20% → 0–15% of cycle.
//        0.48s fade-in at 2.4s cycle exceeded 300ms attention-capture
//        threshold. Now 0.45s at 3.0s cycle (0–15% × 3.0s).
//
// VQ-17  Particle Y origin: shifted to bar top surface.
//        Previously particles began at barMidY (bar centre).
//        Now: barMidY - barHeight/2 — they appear to launch from
//        the lit surface rather than from inside the fill.
//
// VQ-18  Particle light mode opacity scale: 0.52 → 0.65.
//        At 0.52 the dot (0.47) was too dim against orange fill on cream.
//        0.65 brings dot to 0.59, halo to 0.34 — readable without smear.
//
// All dark bloom color values unchanged except where explicitly noted.
// All accessibility, localisation, architecture, and performance work
// from v2.1/v2.2 preserved exactly.

import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - ClosedRange clamp helper
// ─────────────────────────────────────────────────────────────────────────────

extension ClosedRange where Bound: Comparable {
    /// Clamps `value` to lie within this range.
    func clamp(_ value: Bound) -> Bound {
        Swift.min(upperBound, Swift.max(lowerBound, value))
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Pure Animation Math  (zero UI dependencies — unit-testable)
// ─────────────────────────────────────────────────────────────────────────────

enum AnimationMath {

    /// Wraps elapsed seconds into a normalised [0, 1) phase for one cycle.
    static func shimmerPhase(
        elapsed:       CGFloat,
        cycleDuration: CGFloat
    ) -> CGFloat {
        guard cycleDuration > 0 else { return 0 }
        return elapsed
            .truncatingRemainder(dividingBy: cycleDuration) / cycleDuration
    }

    /// Peak at mid-cycle. Returns value in [0, 1].
    static func bloomIntensity(phase: CGFloat) -> CGFloat {
        sin(phase * .pi)
    }

    /// Intentionally identical to bloomIntensity so the two effects
    /// pulse in perfect unison (fixes the phase-drift bug from v1).
    static func breatheIntensity(phase: CGFloat) -> CGFloat {
        bloomIntensity(phase: phase)
    }

    /// Shimmer hotspot X offset in points.
    /// Travels from −overshoot to fillWidth+overshoot across one cycle.
    static func shimmerXOffset(
        phase:     CGFloat,
        fillWidth: CGFloat,
        overshoot: CGFloat = 30
    ) -> CGFloat {
        let sweepRange = fillWidth + overshoot * 2
        return phase * sweepRange - overshoot
    }

    /// Progress ratio clamped to [0, 1]; NaN / infinite safe.
    static func safeRatio(current: Int, total: Int) -> CGFloat {
        guard total > 0 else { return 0 }
        let raw = CGFloat(current) / CGFloat(total)
        guard raw.isFinite else { return 0 }
        return (0.0...1.0).clamp(raw)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Animation Clock  (extracted from View — testable, identity-safe)
// ─────────────────────────────────────────────────────────────────────────────

@Observable
final class ProgressAnimationClock {

    private(set) var startTime: Date? = nil

    func activate() { startTime = Date() }
    func reset()    { startTime = nil  }

    func elapsed(at date: Date) -> CGFloat {
        guard let start = startTime else { return 0 }
        return CGFloat(date.timeIntervalSince(start))
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Design Constants
// ─────────────────────────────────────────────────────────────────────────────

private enum ProgressBarConstants {
    static let defaultTotalWidth:    CGFloat = 120
    static let defaultBarHeight:     CGFloat = 5
    /// Extra canvas on each side so bloom can bleed past bar ends.
    static let bloomBleed:           CGFloat = 12
    // VQ-01: raised from 2.4 → 3.0s. See change log.
    static let defaultShimmerCycle:  Double  = 3.0
    static let defaultFillDuration:  Double  = 0.35
    /// Frame-rate cap for the bloom TimelineView.
    static let bloomFPS:             Double  = 30
    /// Max vertical bloom spread as a multiple of barHeight (HIG cap).
    static let maxBloomSpreadFactor: CGFloat = 7.0
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Pre-computed Gradients  (static lets — dark mode source of truth)
//
// These are the dark mode gradients, allocated once.
// Light mode variants are computed properties on the View (they must be
// computed because they reference colorScheme, which requires View context).
// ─────────────────────────────────────────────────────────────────────────────

private enum ProgressBarGradients {

    // ── Fill ──────────────────────────────────────────────────────────────
    static let staticFill = LinearGradient(
        stops: [
            .init(color: AppColors.cyan,   location: 0.0),
            .init(color: AppColors.purple, location: 1.0)
        ],
        startPoint: .leading,
        endPoint:   .trailing
    )
    static let finalFill = LinearGradient(
        stops: [
            .init(color: AppColors.cyan,    location: 0.0),
            .init(color: AppColors.purple,  location: 0.5),
            .init(color: AppColors.magenta, location: 1.0)
        ],
        startPoint: .leading,
        endPoint:   .trailing
    )

    // RTL mirrors — colour order preserved, direction flipped
    static let staticFillRTL = LinearGradient(
        stops: [
            .init(color: AppColors.cyan,   location: 0.0),
            .init(color: AppColors.purple, location: 1.0)
        ],
        startPoint: .trailing,
        endPoint:   .leading
    )
    static let finalFillRTL = LinearGradient(
        stops: [
            .init(color: AppColors.cyan,    location: 0.0),
            .init(color: AppColors.purple,  location: 0.5),
            .init(color: AppColors.magenta, location: 1.0)
        ],
        startPoint: .trailing,
        endPoint:   .leading
    )

    // ── Light mode fill variants ───────────────────────────────────────────
    // VQ-08: magenta final stop opacity 0.75 → 0.55; orangeHot mid stop
    //        location 0.5 → 0.65 to extend warm amber before the pink arrives.

    static let staticFillLight = LinearGradient(
        stops: [
            .init(color: AppColors.orangeDeep, location: 0.0),
            .init(color: AppColors.orangeHot,  location: 1.0)
        ],
        startPoint: .leading,
        endPoint:   .trailing
    )
    static let finalFillLight = LinearGradient(
        stops: [
            .init(color: AppColors.orangeDeep,            location: 0.00),
            .init(color: AppColors.orangeHot,             location: 0.65),  // VQ-08: was 0.50
            .init(color: AppColors.magenta.opacity(0.55), location: 1.00)   // VQ-08: was 0.75
        ],
        startPoint: .leading,
        endPoint:   .trailing
    )
    static let staticFillLightRTL = LinearGradient(
        stops: [
            .init(color: AppColors.orangeDeep, location: 0.0),
            .init(color: AppColors.orangeHot,  location: 1.0)
        ],
        startPoint: .trailing,
        endPoint:   .leading
    )
    static let finalFillLightRTL = LinearGradient(
        stops: [
            .init(color: AppColors.orangeDeep,            location: 0.00),
            .init(color: AppColors.orangeHot,             location: 0.65),  // VQ-08: was 0.50
            .init(color: AppColors.magenta.opacity(0.55), location: 1.00)   // VQ-08: was 0.75
        ],
        startPoint: .trailing,
        endPoint:   .leading
    )
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Localised String Helpers
// ─────────────────────────────────────────────────────────────────────────────

private enum ProgressBarStrings {

    static func stepLabel(
        description: String,
        current:     Int,
        total:       Int
    ) -> String {
        String(
            format: NSLocalizedString(
                "progress.step.label",
                value: "%@, step %lld of %lld",
                comment: "Accessibility label. Arg1: flow name, Arg2: current step, Arg3: total."
            ),
            description,
            current,
            total
        )
    }

    /// Locale-correct percentage, e.g. "75%" or "75 %" depending on locale.
    static func percentValue(ratio: CGFloat) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle           = .percent
        formatter.locale                = .current
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: Double(ratio)))
            ?? "\(Int(ratio * 100))%"
    }

    static func milestoneAnnouncement(current: Int, total: Int) -> String {
        String(
            format: NSLocalizedString(
                "progress.step.announcement",
                value: "Step %lld of %lld",
                comment: "VoiceOver announcement when the user advances a step."
            ),
            current,
            total
        )
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - iOS-version-safe onChange modifier  (wraps #available internally)
// ─────────────────────────────────────────────────────────────────────────────

private struct StepChangeModifier: ViewModifier {
    let currentStep: Int
    let action: () -> Void

    func body(content: Content) -> some View {
        if #available(iOS 17, *) {
            content.onChange(of: currentStep) { _, _ in action() }
        } else {
            content.onChange(of: currentStep) { _ in action() }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - OnboardingProgressBar
// ─────────────────────────────────────────────────────────────────────────────

struct OnboardingProgressBar: View {

    // ── Public props ───────────────────────────────────────────────────────

    let currentStep:          Int
    let totalSteps:           Int
    var progressDescription:  String  = NSLocalizedString(
        "progress.description.default",
        value: "Onboarding",
        comment: "Default VoiceOver description."
    )
    var showCompletionEffect: Bool    = false
    var totalWidth:           CGFloat = ProgressBarConstants.defaultTotalWidth
    var barHeight:            CGFloat = ProgressBarConstants.defaultBarHeight
    var animationDuration:    Double  = ProgressBarConstants.defaultFillDuration
    var shimmerCycleDuration: Double  = ProgressBarConstants.defaultShimmerCycle

    // ── Backward-compatible convenience init ──────────────────────────────
    init(
        currentStep:          Int,
        totalSteps:           Int,
        progressDescription:  String  = NSLocalizedString(
            "progress.description.default",
            value: "Onboarding",
            comment: "Default VoiceOver description."
        ),
        showCompletionEffect: Bool    = false,
        totalWidth:           CGFloat = ProgressBarConstants.defaultTotalWidth,
        barHeight:            CGFloat = ProgressBarConstants.defaultBarHeight,
        animationDuration:    Double  = ProgressBarConstants.defaultFillDuration,
        shimmerCycleDuration: Double  = ProgressBarConstants.defaultShimmerCycle
    ) {
        self.currentStep          = currentStep
        self.totalSteps           = totalSteps
        self.progressDescription  = progressDescription
        self.showCompletionEffect = showCompletionEffect
        self.totalWidth           = totalWidth
        self.barHeight            = barHeight
        self.animationDuration    = animationDuration
        self.shimmerCycleDuration = shimmerCycleDuration
    }

    // ── Private state ──────────────────────────────────────────────────────

    @State private var clock = ProgressAnimationClock()

    // ── Environment ────────────────────────────────────────────────────────

    private var reduceMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    private var increaseContrast: Bool {
        UIAccessibility.isDarkerSystemColorsEnabled
    }

    @Environment(\.colorScheme)      private var colorScheme
    @Environment(\.layoutDirection)  private var layoutDirection

    // ── Derived values ─────────────────────────────────────────────────────

    var fillRatio: CGFloat {
        AnimationMath.safeRatio(current: currentStep, total: totalSteps)
    }

    private var fillWidth: CGFloat { totalWidth * fillRatio }

    // LIGHT-01 / VQ-09: Light track opacity raised 0.06 → 0.09.
    //   At 0.06 the rail was at minimum legibility on cream.
    //   0.09 is structural without being heavy.
    private var trackColor: Color {
        colorScheme == .light
        ? Color.black.opacity(0.09)   // VQ-09: was 0.06
        : Color.white.opacity(trackOpacity)
    }

    private var trackOpacity: CGFloat {
        increaseContrast ? 0.50 : 0.18
    }

    private var isRTL: Bool { layoutDirection == .rightToLeft }

    // LIGHT-02: Gradient selectors branch dark ↔ light before RTL mirror.
    private var staticFillGradient: LinearGradient {
        if colorScheme == .light {
            return isRTL
            ? ProgressBarGradients.staticFillLightRTL
            : ProgressBarGradients.staticFillLight
        }
        return isRTL
        ? ProgressBarGradients.staticFillRTL
        : ProgressBarGradients.staticFill
    }

    private var finalFillGradient: LinearGradient {
        if colorScheme == .light {
            return isRTL
            ? ProgressBarGradients.finalFillLightRTL
            : ProgressBarGradients.finalFillLight
        }
        return isRTL
        ? ProgressBarGradients.finalFillRTL
        : ProgressBarGradients.finalFill
    }

    // ── Bloom geometry ─────────────────────────────────────────────────────

    private var bloomBleed:     CGFloat { ProgressBarConstants.bloomBleed }
    private var canvasWidth:    CGFloat { totalWidth + bloomBleed * 2 }
    private var maxBloomHeight: CGFloat {
        barHeight * ProgressBarConstants.maxBloomSpreadFactor
    }

    // ── Bloom light/dark scalars ────────────────────────────────────────────
    //
    // VQ-02: Atmo spread reduced. Previous dark base 3.5 → 2.8 (−20%),
    //        pulse 2.0 → 1.4 (−30%). Light base 2.2 → 1.8, pulse 1.1 → 0.8.
    //        On a 4pt bar the old values produced 14–22pt spread —
    //        disproportionate. New range: 11–16pt dark, 9–13pt light.
    //
    // VQ-04: Atmo magenta opacity reduced (see bloomCanvas gradient stops).
    // VQ-06: Core base opacity dark 0.50 → 0.38 — was competing with fill.
    // VQ-07: Atmo blur base light 4.5 → 3.5 — was spreading pink too far.

    private var bloomAtmoOpacityBase:  CGFloat { colorScheme == .dark ? 0.18 : 0.10 }
    private var bloomAtmoOpacityPulse: CGFloat { colorScheme == .dark ? 0.18 : 0.10 }
    private var bloomMidOpacityBase:   CGFloat { colorScheme == .dark ? 0.28 : 0.13 }
    private var bloomMidOpacityPulse:  CGFloat { colorScheme == .dark ? 0.22 : 0.11 }
    private var bloomCoreOpacityBase:  CGFloat { colorScheme == .dark ? 0.38 : 0.22 }  // VQ-06: dark was 0.50
    private var bloomCoreOpacityPulse: CGFloat { colorScheme == .dark ? 0.25 : 0.13 }

    // VQ-02: Spread multipliers tightened.
    private var bloomAtmoSpreadBase:   CGFloat { colorScheme == .dark ? 2.8 : 1.8 }    // VQ-02: dark 3.5→2.8, light 2.2→1.8
    private var bloomAtmoSpreadPulse:  CGFloat { colorScheme == .dark ? 1.4 : 0.8 }    // VQ-02: dark 2.0→1.4, light 1.1→0.8
    private var bloomMidSpreadBase:    CGFloat { colorScheme == .dark ? 2.0 : 1.3 }
    private var bloomMidSpreadPulse:   CGFloat { colorScheme == .dark ? 1.2 : 0.7 }
    private var bloomCoreSpreadBase:   CGFloat { colorScheme == .dark ? 1.2 : 0.9 }
    private var bloomCoreSpreadPulse:  CGFloat { colorScheme == .dark ? 1.0 : 0.6 }

    // VQ-07: Atmo blur base light 4.5 → 3.5.
    private var bloomAtmoBlurBase:     CGFloat { colorScheme == .dark ? 6.0 : 3.5 }    // VQ-07: light was 4.5
    private var bloomAtmoBlurPulse:    CGFloat { colorScheme == .dark ? 3.0 : 1.8 }
    private var bloomMidBlurBase:      CGFloat { colorScheme == .dark ? 5.0 : 3.5 }
    private var bloomMidBlurPulse:     CGFloat { colorScheme == .dark ? 3.0 : 1.8 }
    private var bloomCoreBlurBase:     CGFloat { colorScheme == .dark ? 2.0 : 1.6 }
    private var bloomCoreBlurPulse:    CGFloat { colorScheme == .dark ? 1.0 : 0.7 }

    // VQ-18: Light particle opacity scale raised 0.52 → 0.65.
    private var particleOpacityScale:  CGFloat { colorScheme == .dark ? 1.0 : 0.65 }   // VQ-18: light was 0.52

    // ── Accessibility ──────────────────────────────────────────────────────

    private var a11yLabel: String {
        ProgressBarStrings.stepLabel(
            description: progressDescription,
            current:     currentStep,
            total:       totalSteps
        )
    }

    private var a11yValue: String {
        ProgressBarStrings.percentValue(ratio: fillRatio)
    }

    // ── Timeline schedule (30 fps cap) ─────────────────────────────────────

    private var timelineSchedule: PeriodicTimelineSchedule {
        .periodic(from: .now, by: 1.0 / ProgressBarConstants.bloomFPS)
    }

    // ─────────────────────────────────────────────────────────────────────
    // MARK: body
    // ─────────────────────────────────────────────────────────────────────

    var body: some View {

        assert(totalSteps  >  0, "totalSteps must be > 0, got \(totalSteps)")
        assert(currentStep >= 0, "currentStep must be >= 0, got \(currentStep)")
        assert(
            currentStep <= totalSteps,
            "currentStep (\(currentStep)) exceeds totalSteps (\(totalSteps))"
        )

        return Group {
            if showCompletionEffect && !reduceMotion {
                TimelineView(timelineSchedule) { tl in
                    let e  = clock.elapsed(at: tl.date)
                    let sp = AnimationMath.shimmerPhase(
                        elapsed:       e,
                        cycleDuration: CGFloat(shimmerCycleDuration)
                    )
                    let bi = AnimationMath.bloomIntensity(phase: sp)
                    let br = AnimationMath.breatheIntensity(phase: sp)

                    finalBar(
                        elapsed:          e,
                        shimmerPhase:     sp,
                        bloomIntensity:   bi,
                        breatheIntensity: br
                    )
                }
                .onAppear    { clock.activate() }
                .onDisappear { clock.reset()    }
                .onReceive(
                    NotificationCenter.default.publisher(
                        for: UIApplication.didEnterBackgroundNotification
                    )
                ) { _ in clock.reset()    }
                .onReceive(
                    NotificationCenter.default.publisher(
                        for: UIApplication.willEnterForegroundNotification
                    )
                ) { _ in clock.activate() }
                .modifier(StepChangeModifier(currentStep: currentStep) {
                    if showCompletionEffect { clock.activate() }
                })

            } else {
                staticBar
                    .modifier(StepChangeModifier(currentStep: currentStep) { })
            }
        }
        .frame(width: totalWidth, height: barHeight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(currentStep) of \(totalSteps)")
        .accessibilityValue(a11yValue)
        .accessibilityAddTraits([.updatesFrequently, .isStaticText])
        .accessibilityIdentifier("OnboardingProgressBar")
        .modifier(StepChangeModifier(currentStep: currentStep) {
            postStepAnnouncement()
        })
    }

    // ─────────────────────────────────────────────────────────────────────
    // MARK: VoiceOver announcement
    // ─────────────────────────────────────────────────────────────────────

    private func postStepAnnouncement() {
        let msg = ProgressBarStrings.milestoneAnnouncement(
            current: currentStep,
            total:   totalSteps
        )
        UIAccessibility.post(notification: .announcement, argument: msg)
    }

    // ─────────────────────────────────────────────────────────────────────
    // MARK: Static bar
    // ─────────────────────────────────────────────────────────────────────

    private var staticBar: some View {
        ZStack(alignment: .leading) {

            Capsule()
                .fill(trackColor)
                .frame(width: totalWidth, height: barHeight)

            Capsule()
                .fill(staticFillGradient)
                .frame(width: fillWidth, height: barHeight)
                .animation(
                    .easeInOut(duration: animationDuration),
                    value: fillWidth
                )
        }
    }

    // ─────────────────────────────────────────────────────────────────────
    // MARK: Final-step bar
    // ─────────────────────────────────────────────────────────────────────

    @ViewBuilder
    private func finalBar(
        elapsed:          CGFloat,
        shimmerPhase:     CGFloat,
        bloomIntensity:   CGFloat,
        breatheIntensity: CGFloat
    ) -> some View {
        barContent(
            shimmerPhase:     shimmerPhase,
            bloomIntensity:   bloomIntensity,
            breatheIntensity: breatheIntensity
        )
        .drawingGroup()
        .overlay(
            bloomCanvas(
                elapsed:              elapsed,
                bloomIntensity:       bloomIntensity,
                breatheIntensity:     breatheIntensity,
                colorScheme:          colorScheme,
                barHeight:            barHeight,
                atmoOpacityBase:      bloomAtmoOpacityBase,
                atmoOpacityPulse:     bloomAtmoOpacityPulse,
                midOpacityBase:       bloomMidOpacityBase,
                midOpacityPulse:      bloomMidOpacityPulse,
                coreOpacityBase:      bloomCoreOpacityBase,
                coreOpacityPulse:     bloomCoreOpacityPulse,
                atmoSpreadBase:       bloomAtmoSpreadBase,
                atmoSpreadPulse:      bloomAtmoSpreadPulse,
                midSpreadBase:        bloomMidSpreadBase,
                midSpreadPulse:       bloomMidSpreadPulse,
                coreSpreadBase:       bloomCoreSpreadBase,
                coreSpreadPulse:      bloomCoreSpreadPulse,
                atmoBlurBase:         bloomAtmoBlurBase,
                atmoBlurPulse:        bloomAtmoBlurPulse,
                midBlurBase:          bloomMidBlurBase,
                midBlurPulse:         bloomMidBlurPulse,
                coreBlurBase:         bloomCoreBlurBase,
                coreBlurPulse:        bloomCoreBlurPulse,
                particleOpacityScale: particleOpacityScale
            )
            .frame(width: canvasWidth, height: maxBloomHeight)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        )
    }

    // ─────────────────────────────────────────────────────────────────────
    // MARK: Bar content (track + fill + shimmer)
    // ─────────────────────────────────────────────────────────────────────

    @ViewBuilder
    private func barContent(
        shimmerPhase:     CGFloat,
        bloomIntensity:   CGFloat,
        breatheIntensity: CGFloat
    ) -> some View {
        ZStack(alignment: .leading) {

            Capsule()
                .fill(trackColor)
                .frame(width: totalWidth, height: barHeight)

            Capsule()
                .fill(finalFillGradient)
                .frame(width: fillWidth, height: barHeight)

            shimmerOverlay(
                shimmerPhase:     shimmerPhase,
                breatheIntensity: breatheIntensity
            )
        }
        .compositingGroup()
        .clipShape(Capsule())
    }

    // ─────────────────────────────────────────────────────────────────────
    // MARK: Shimmer overlay
    // ─────────────────────────────────────────────────────────────────────
    // VQ-10: outer blur 2 → 3pt — softens rectangular edge on small bar.
    // VQ-11: light mode inner opacity branch added — white shimmer needs
    //        higher opacity to read against orange fill on cream.

    @ViewBuilder
    private func shimmerOverlay(
        shimmerPhase:     CGFloat,
        breatheIntensity: CGFloat
    ) -> some View {
        let xPos         = AnimationMath.shimmerXOffset(
            phase:     shimmerPhase,
            fillWidth: fillWidth
        )
        let outerOpacity = 0.10 + breatheIntensity * 0.18

        // VQ-11: inner opacity slightly higher in light mode so the white
        //        hotspot reads against the warm orange fill on cream.
        let innerOpacity: CGFloat = colorScheme == .light
            ? 0.32 + breatheIntensity * 0.36   // VQ-11: light (was no branch)
            : 0.28 + breatheIntensity * 0.32   // original dark values

        ZStack(alignment: .leading) {

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            .clear,
                            Color.white.opacity(outerOpacity),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint:   .trailing
                    )
                )
                .frame(width: 16, height: barHeight)
                .blur(radius: 3)            // VQ-10: was 2
                .offset(x: xPos - 2)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            .clear,
                            Color.white.opacity(innerOpacity),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint:   .trailing
                    )
                )
                .frame(width: 10, height: barHeight)
                .offset(x: xPos)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // ─────────────────────────────────────────────────────────────────────
    // MARK: Bloom canvas
    // ─────────────────────────────────────────────────────────────────────
    // LIGHT-03: colorScheme passed as parameter.
    // LIGHT-05: _ = elapsed inside Canvas prevents SwiftUI optimising
    //           away the redraw (was missing as _ = timeline.date in v2.1).
    //
    // VQ-03: Atmo gradient gains a cyan/orangeDeep anchor stop at leading
    //        edge so the bar's left-end color identity bleeds into atmosphere.
    // VQ-04: Atmo center magenta opacity: dark 0.80→0.70, light 0.80→0.50.
    // VQ-05: Mid center stop: light orangeHot 0.90→0.65.
    // VQ-06: Core opacity controlled via coreOpacityBase (dark 0.50→0.38).
    // VQ-12–VQ-17: Particle system tuning (see inline comments).
    //
    // barHeight is now explicitly threaded through so Canvas closure can
    // compute the correct Y launch origin (VQ-17) without capturing self.

    @ViewBuilder
    private func bloomCanvas(
        elapsed:              CGFloat,
        bloomIntensity:       CGFloat,
        breatheIntensity:     CGFloat,
        colorScheme:          ColorScheme,
        barHeight:            CGFloat,
        atmoOpacityBase:      CGFloat,
        atmoOpacityPulse:     CGFloat,
        midOpacityBase:       CGFloat,
        midOpacityPulse:      CGFloat,
        coreOpacityBase:      CGFloat,
        coreOpacityPulse:     CGFloat,
        atmoSpreadBase:       CGFloat,
        atmoSpreadPulse:      CGFloat,
        midSpreadBase:        CGFloat,
        midSpreadPulse:       CGFloat,
        coreSpreadBase:       CGFloat,
        coreSpreadPulse:      CGFloat,
        atmoBlurBase:         CGFloat,
        atmoBlurPulse:        CGFloat,
        midBlurBase:          CGFloat,
        midBlurPulse:         CGFloat,
        coreBlurBase:         CGFloat,
        coreBlurPulse:        CGFloat,
        particleOpacityScale: CGFloat
    ) -> some View {
        Canvas { ctx, size in

            _ = elapsed   // LIGHT-05: forces Canvas invalidation every tick.

            let barMinX   = bloomBleed
            let barMidY   = size.height / 2
            // VQ-17: bar top surface Y — particles launch from here, not centre.
            let barTopY   = barMidY - barHeight / 2

            let isLight = colorScheme == .light

            // ── Layer 3: Outer atmosphere ──────────────────────────────────
            // VQ-02: spread values reduced (passed in via parameters).
            // VQ-03: leading stop now uses cyan (dark) / orangeDeep (light)
            //        to anchor the bar's left-end color into the atmosphere.
            // VQ-04: center magenta opacity dark 0.80→0.70, light 0.80→0.50.

            let atmoSpread  = barHeight * (atmoSpreadBase + breatheIntensity * atmoSpreadPulse)
            let atmoOpacity = atmoOpacityBase + breatheIntensity * atmoOpacityPulse
            var atmoCtx     = ctx
            atmoCtx.addFilter(.blur(radius: atmoBlurBase + bloomIntensity * atmoBlurPulse))
            atmoCtx.opacity = atmoOpacity
            let atmoRect    = CGRect(
                x:      barMinX - 2,
                y:      barMidY - atmoSpread / 2 - 3,
                width:  fillWidth + 4,
                height: atmoSpread
            )
            atmoCtx.fill(
                Path(roundedRect: atmoRect, cornerRadius: atmoSpread / 2),
                with: .linearGradient(
                    Gradient(colors: isLight ? [
                        AppColors.orangeDeep.opacity(0.40),   // VQ-03: anchors left end
                        AppColors.orangeDeep.opacity(0.55),
                        AppColors.magenta.opacity(0.50),       // VQ-04: was 0.80
                        AppColors.orangeDeep.opacity(0.55),
                        AppColors.orangeDeep.opacity(0.30)
                    ] : [
                        AppColors.cyan.opacity(0.35),          // VQ-03: anchors cyan end
                        AppColors.purple.opacity(0.60),
                        AppColors.magenta.opacity(0.70),       // VQ-04: was 0.80
                        AppColors.purple.opacity(0.60),
                        AppColors.purple.opacity(0.30)
                    ]),
                    startPoint: CGPoint(x: atmoRect.minX, y: barMidY),
                    endPoint:   CGPoint(x: atmoRect.maxX, y: barMidY)
                )
            )

            // ── Layer 2: Mid halo ──────────────────────────────────────────
            // VQ-05: light mode center stop orangeHot 0.90→0.65.

            let midSpread  = barHeight * (midSpreadBase + breatheIntensity * midSpreadPulse)
            let midOpacity = midOpacityBase + breatheIntensity * midOpacityPulse
            var midCtx     = ctx
            midCtx.addFilter(.blur(radius: midBlurBase + bloomIntensity * midBlurPulse))
            midCtx.opacity = midOpacity
            let midRect    = CGRect(
                x:      barMinX - 4,
                y:      barMidY - midSpread / 2 - 2,
                width:  fillWidth + 8,
                height: midSpread
            )
            midCtx.fill(
                Path(roundedRect: midRect, cornerRadius: midSpread / 2),
                with: .linearGradient(
                    Gradient(colors: isLight ? [
                        AppColors.orangeDeep.opacity(0.18),
                        AppColors.orangeDeep.opacity(0.50),
                        AppColors.orangeHot.opacity(0.65),     // VQ-05: was 0.90
                        AppColors.magenta.opacity(0.60),
                        AppColors.magenta.opacity(0.30)
                    ] : [
                        AppColors.cyan.opacity(0.18),
                        AppColors.cyan.opacity(0.50),
                        AppColors.purple.opacity(0.90),
                        AppColors.magenta.opacity(0.60),
                        AppColors.magenta.opacity(0.30)
                    ]),
                    startPoint: CGPoint(x: midRect.minX, y: barMidY),
                    endPoint:   CGPoint(x: midRect.maxX, y: barMidY)
                )
            )

            // ── Layer 1: Tight core ────────────────────────────────────────
            // VQ-06: coreOpacityBase for dark passed in as 0.38 (was 0.50).
            //        This stops the core layer competing with the fill surface.

            let coreSpread  = barHeight * (coreSpreadBase + breatheIntensity * coreSpreadPulse)
            let coreOpacity = coreOpacityBase + breatheIntensity * coreOpacityPulse
            var coreCtx     = ctx
            coreCtx.addFilter(.blur(radius: coreBlurBase + bloomIntensity * coreBlurPulse))
            coreCtx.opacity = coreOpacity
            let coreRect    = CGRect(
                x:      barMinX - 3,
                y:      barMidY - coreSpread / 2 - 1,
                width:  fillWidth + 6,
                height: coreSpread
            )
            coreCtx.fill(
                Path(roundedRect: coreRect, cornerRadius: coreSpread / 2),
                with: .linearGradient(
                    Gradient(colors: isLight ? [
                        AppColors.orangeDeep.opacity(0.25),
                        AppColors.orangeHot.opacity(0.90),
                        AppColors.orangeHot.opacity(0.80),
                        AppColors.magenta.opacity(0.90),
                        AppColors.magenta.opacity(0.65)
                    ] : [
                        AppColors.cyan.opacity(0.25),
                        AppColors.cyan.opacity(0.90),
                        AppColors.purple.opacity(0.80),
                        AppColors.magenta.opacity(0.90),
                        AppColors.magenta.opacity(0.65)
                    ]),
                    startPoint: CGPoint(x: coreRect.minX, y: barMidY),
                    endPoint:   CGPoint(x: coreRect.maxX, y: barMidY)
                )
            )

            // ── Particles ──────────────────────────────────────────────────
            // LIGHT-04: color arrays branched on isLight.
            // VQ-18: particleOpacityScale handles overall light/dark scaling.

            let particleDefs: [(Color, CGFloat, Double)] = isLight ? [
                (AppColors.orangeHot,  0.08, 0.0),
                (AppColors.orangeDeep, 0.42, 0.6),
                (AppColors.magenta,    0.72, 1.2),
                (AppColors.orangeHot,  0.90, 0.3),
                (AppColors.magenta,    0.22, 0.95),
                (AppColors.orangeDeep, 0.55, 0.65),
            ] : [
                (AppColors.cyan,    0.08, 0.0),
                (AppColors.purple,  0.42, 0.6),
                (AppColors.magenta, 0.72, 1.2),
                (AppColors.cyan,    0.90, 0.3),
                (AppColors.magenta, 0.22, 0.95),
                (AppColors.purple,  0.55, 0.65),
            ]

            // VQ-18: particleOpacityScale passed in; 0.65 light, 1.0 dark.
            let dotOpacityMultiplier:  CGFloat = 0.90 * particleOpacityScale
            let haloOpacityMultiplier: CGFloat = 0.53 * particleOpacityScale

            let cycleDuration = CGFloat(shimmerCycleDuration)

            for (index, (color, xRatio, delay)) in particleDefs.enumerated() {
                let offsetElapsed = max(0, elapsed - CGFloat(delay))
                let phase: CGFloat = cycleDuration > 0
                    ? offsetElapsed.truncatingRemainder(
                        dividingBy: cycleDuration
                    ) / cycleDuration
                    : 0

                // VQ-16: fade-in window tightened 0–20% → 0–15% of cycle.
                //        At 3.0s this is 0.45s fade-in vs previous 0.72s,
                //        keeping it below the 300ms attention-capture threshold
                //        while still feeling smooth at 30fps.
                let pOpacity: CGFloat = phase < 0.15          // VQ-16: was 0.20
                    ? phase / 0.15                             // VQ-16: was / 0.20
                    : 1.0 - ((phase - 0.15) / 0.85)           // VQ-16: was (phase-0.20)/0.80
                guard pOpacity > 0.01 else { continue }

                let i = CGFloat(index)

                // VQ-12: rise height base 10 → 14pt, variation ±3 → ±5pt.
                //        Range was 7–13pt (barely clears bloom halo at 4pt bar).
                //        New range 9–19pt gives particles room to read distinctly.
                let riseHeight:  CGFloat = 14 + sin(i * 1.3) * 5   // VQ-12: was 10 + sin(i×1.3)×3

                // VQ-13: easeExp base 2.0 → 2.2, variation ±0.5 → ±0.9.
                //        New range [1.3, 3.1] vs old [1.5, 2.5].
                //        Wider spread creates visible arc-vs-drift character
                //        diversity — fast-arcing vs slow-drifting particles.
                let easeExp:     CGFloat = 2.2 + cos(i * 0.9) * 0.9   // VQ-13: was 2.0 + cos(i×0.9)×0.5

                // VQ-14: drift frequency 2.1 → 1.8 per index.
                //        Previous spacing clustered two particles at similar
                //        rightward drift. 1.8 produces better angular spread.
                let driftAmount: CGFloat = sin(i * 1.8) * 5    // VQ-14: was sin(i×2.1)×5

                // VQ-15: wobble amplitude easeOut×2 → easeOut×3.5.
                //        2pt max lateral movement was sub-perceptual on screen.
                //        3.5pt is clearly readable as organic sway.
                let wobbleFreq:  CGFloat = 2.5 + cos(i * 1.7) * 1.0

                let easeOut = 1.0 - pow(1.0 - phase, easeExp)

                // VQ-17: Y origin shifted to bar top surface (barTopY).
                //        Previously barMidY caused particles to appear to
                //        launch from inside the fill rather than off the surface.
                let yPos    = barTopY - easeOut * riseHeight    // VQ-17: was barMidY - easeOut×riseHeight
                let wobble  = sin(phase * .pi * wobbleFreq) * easeOut * 3.5   // VQ-15: was easeOut×2
                let xPos    = barMinX
                    + fillWidth * xRatio
                    + phase * driftAmount
                    + wobble

                // Three concentric ellipses — never .radialGradient
                let haloSizes: [(scale: Double, opacity: Double)] = [
                    (1.0,  Double(pOpacity * haloOpacityMultiplier) * 0.36),
                    (0.60, Double(pOpacity * haloOpacityMultiplier) * 0.22),
                    (0.32, Double(pOpacity * haloOpacityMultiplier) * 0.34),
                ]
                let glowRadius: CGFloat = 2.0
                for halo in haloSizes {
                    let hr = glowRadius * halo.scale
                    var haloCtx = ctx
                    haloCtx.opacity = halo.opacity
                    haloCtx.fill(
                        Path(ellipseIn: CGRect(
                            x: xPos - hr, y: yPos - hr,
                            width: hr * 2, height: hr * 2
                        )),
                        with: .color(color)
                    )
                }

                // 2×2pt dot
                var dotCtx = ctx
                dotCtx.opacity = Double(pOpacity * dotOpacityMultiplier)
                dotCtx.fill(
                    Path(ellipseIn: CGRect(
                        x: xPos - 1, y: yPos - 1,
                        width: 2,    height: 2
                    )),
                    with: .color(color)
                )
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Previews
// ─────────────────────────────────────────────────────────────────────────────

#Preview("Dark — default") {
    PreviewContent().preferredColorScheme(.dark)
}

#Preview("Light Mode") {
    PreviewContent().preferredColorScheme(.light)
}

#Preview("Reduce Motion") {
    PreviewContent()
        .preferredColorScheme(.dark)
}

#Preview("RTL Layout") {
    PreviewContent()
        .preferredColorScheme(.dark)
        .environment(\.layoutDirection, .rightToLeft)
}

#Preview("RTL Light Mode") {
    PreviewContent()
        .preferredColorScheme(.light)
        .environment(\.layoutDirection, .rightToLeft)
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Preview Content
// ─────────────────────────────────────────────────────────────────────────────

private struct PreviewContent: View {

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            (colorScheme == .light ? AppColors.lightPageBg : AppColors.pageBg)
                .ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {

                    sectionHeader("SOLO · COUPLE  (6 steps)")
                    stepGroup(total: 6)

                    sectionHeader("JUST BROWSING  (5 steps)")
                    stepGroup(total: 5)

                    sectionHeader("EDGE CASES")

                    edgeRow("Step 0 of 6  (empty bar)") {
                        OnboardingProgressBar(
                            currentStep: 0,
                            totalSteps:  6
                        )
                    }
                    edgeRow("Step 6 of 6  (full, no bloom)") {
                        OnboardingProgressBar(
                            currentStep: 6,
                            totalSteps:  6
                        )
                    }
                    edgeRow("Step 6 of 6  (full + bloom)") {
                        OnboardingProgressBar(
                            currentStep:          6,
                            totalSteps:           6,
                            showCompletionEffect: true
                        )
                    }
                    edgeRow("Step 1 of 1  (single step + bloom)") {
                        OnboardingProgressBar(
                            currentStep:          1,
                            totalSteps:           1,
                            showCompletionEffect: true
                        )
                    }
                    edgeRow("Narrow  (width: 60)") {
                        OnboardingProgressBar(
                            currentStep: 3,
                            totalSteps:  6,
                            totalWidth:  60
                        )
                    }
                    edgeRow("Tall  (height: 8)") {
                        OnboardingProgressBar(
                            currentStep: 4,
                            totalSteps:  6,
                            barHeight:   8
                        )
                    }
                }
                .padding(.vertical, 48)
            }
        }
    }

    @ViewBuilder
    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(AppFonts.overline)
            .foregroundStyle(AppColors.textTertiary)
            .tracking(2)
            .padding(.horizontal, 24)
    }

    @ViewBuilder
    private func stepGroup(total: Int) -> some View {
        VStack(spacing: 20) {
            ForEach(1...total, id: \.self) { step in
                OnboardingProgressBar(
                    currentStep:          step,
                    totalSteps:           total,
                    showCompletionEffect: step == total
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private func edgeRow<C: View>(
        _ label: String,
        @ViewBuilder content: () -> C
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundStyle(AppColors.textTertiary)
                .padding(.horizontal, 24)
            content()
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 24)
        }
    }
}

```

---

## File: `Open Lightly/Design/Components/Progress/OrbitIndicator.swift` {#file-open-lightly-design-components-progress-orbitindicator-swift}

```swift
// OrbitIndicator.swift
// Open Lightly
//
// Reusable orbit state indicator — extracted from OnboardingBuildingPathView.
// Used anywhere a three-state (pending → processing → complete) loading flow
// requires visual feedback with an animated comet tail orbit.
//
// USAGE
//
// Basic:
//   OrbitIndicator(state: .processing)
//   OrbitIndicator(state: .complete)
//   OrbitIndicator(state: .pending, size: 32)
//
// Driven by external state:
//   @State private var loadState: OrbitIndicatorState = .pending
//   OrbitIndicator(state: loadState)
//
// In a list row (matches OnboardingBuildingPathView pattern):
//   HStack(spacing: 14) {
//       OrbitIndicator(state: rowState)
//           .fixedSize()
//       VStack(alignment: .leading) { ... }
//   }
//
// Sizes:
//   22pt — default, matches onboarding build list
//   32pt — medium, standalone loading state
//   44pt — large, full-screen loading indicator
//
// Accessibility:
//   Wrap in an accessibilityElement with a dynamic label:
//   .accessibilityLabel(state == .complete ? "Complete" : "Loading")
//   .accessibilityAddTraits(state == .complete ? .isStaticText : [])
//
// ANIMATION NOTES
//
// BUG-3 FIX (OrbitIndicator): _OrbitCanvas previously used
// GraphicsContext.Shading.radialGradient for the spark head.
// That shading is silently discarded by the Xcode preview canvas
// renderer, making the spark invisible in previews. The spark now
// uses .color(opacity:) shading — identical to BPOrbitCanvas —
// which renders correctly in both the simulator and the preview canvas.

import SwiftUI

// MARK: - State Enum

/// Three-state indicator lifecycle.
public enum OrbitIndicatorState: Equatable {
    case pending      // static ring — zero GPU cost
    case processing   // animated comet orbit
    case complete     // gradient fill + glow, orbit dissolves
}

// MARK: - Public View

/// Reusable orbit state indicator for three-state async flows.
///
/// Animates smoothly between pending (static ring), processing (comet orbit),
/// and complete (gradient fill + glow). Uses the project's dark mode color spectrum
/// (cyan → purple → magenta) and follows PillBorder.swift's TimelineView + Canvas architecture.
/// All colors derived from AppColors tokens.
public struct OrbitIndicator: View {
    public let state: OrbitIndicatorState
    public var size: CGFloat = 22
    
    @State private var sheenOffset: CGFloat = -1.5
    @State private var sheenAnimating: Bool = false

    public init(
        state: OrbitIndicatorState,
        size: CGFloat = 22
    ) {
        self.state = state
        self.size = size
    }

    public var body: some View {
        ZStack {
            // LAYER 1 — Pending ring
            Circle()
                .strokeBorder(AppColors.border, lineWidth: 1.5)
                .opacity(state == .pending ? 1 : 0)
                .animation(.easeOut(duration: 0.3), value: state == .pending)

            // LAYER 2 — Orbit canvas
            //
            // Wrapped in withAnimation context at call sites so the
            // .transition(.opacity) fires correctly when state changes.
            if state == .processing {
                _OrbitCanvas(size: size)
                    .transition(.opacity)
            }

            // LAYER 3 — Complete fill
            // Dark mode spectrum: cyan → purple → magenta
            Circle()
                .fill(LinearGradient(
                    colors: [AppColors.cyan, AppColors.purple, AppColors.magenta],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .opacity(state == .complete ? 1 : 0)
                .animation(
                    .spring(response: 0.4, dampingFraction: 0.6),
                    value: state == .complete
                )

            // LAYER 4 — Complete glow
            if state == .complete {
                Circle()
                    .fill(Color.clear)
                    .shadow(
                        color: AppColors.glowCyan,
                        radius: 5,
                        x: 0, y: 0
                    )
                    .shadow(
                        color: AppColors.glowMagenta,
                        radius: 11,
                        x: 0, y: 0
                    )
                    .shadow(
                        color: AppColors.purple.opacity(0.13),
                        radius: 18,
                        x: 0, y: 0
                    )
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.6),
                        value: state == .complete
                    )
            }

            // LAYER 5 — Holographic sheen (complete state only)
            if state == .complete {
                Circle()
                    .fill(Color.clear)
                    .overlay {
                        LinearGradient(
                            stops: [
                                .init(color: .clear,                    location: 0.00),
                                .init(color: .clear,                    location: 0.25),
                                .init(color: Color.white.opacity(0.35), location: 0.38),
                                .init(color: Color.white.opacity(0.00), location: 0.45),
                                .init(color: .clear,                    location: 0.55),
                                .init(color: Color.white.opacity(0.20), location: 0.65),
                                .init(color: .clear,                    location: 0.72),
                                .init(color: .clear,                    location: 1.00),
                            ],
                            startPoint: UnitPoint(x: -0.1, y: 1.0),
                            endPoint:   UnitPoint(x: 1.1,  y: -0.25)
                        )
                        // Scale the sweep to the circle diameter.
                        // StatView uses 320pt for a ~140pt text block (2.3× ratio).
                        // A 22pt circle uses 50pt sweep for the same visual ratio.
                        .frame(width: size * 2.5)
                        .offset(x: sheenOffset * (size * 2.5))
                        .mask { Circle() }
                    }
                    .clipShape(Circle())
                    .allowsHitTesting(false)
                    .onAppear {
                        guard !sheenAnimating else { return }
                        sheenAnimating = true
                        withAnimation(
                            .easeInOut(duration: 4)
                            .repeatForever(autoreverses: true)
                        ) {
                            sheenOffset = 1.5
                        }
                    }
                    .onDisappear {
                        sheenAnimating = false
                        sheenOffset = -1.5
                    }
            }
        }
        .frame(width: size, height: size)
        .onChange(of: state) { _, newState in
            if newState != .complete {
                sheenAnimating = false
                sheenOffset = -1.5
            }
        }
    }
}

// MARK: - Private Orbit Canvas

/// TimelineView + Canvas orbit renderer.
/// Draws a 28-dot comet tail orbiting the circle perimeter with a
/// spark head using flat-color opacity shading.
///
/// Architecture mirrors PillBorder.swift: conditional mounting,
/// TimelineView(.animation) for frame-perfect timing, Canvas for
/// direct GPU drawing.
///
/// BUG-3 FIX: spark head previously used radialGradient shading, which
/// the Xcode preview canvas renderer silently discards, making the spark
/// invisible in previews. Now uses .color(opacity:) — matching
/// BPOrbitCanvas — which renders correctly everywhere.
///
/// Color: Dark mode only — comet trail lerps cyan → purple → magenta.
/// RGB components resolved dynamically from AppColors tokens via UIColor.
private struct _OrbitCanvas: View {
    let size: CGFloat

    private let revolutionDuration: TimeInterval = 1.4

    // Pre-resolved RGB triples for the three anchor colors.
    // Dark mode: cyan → purple → magenta spectrum
    private var primaryRGB: (r: Double, g: Double, b: Double) {
        components(of: AppColors.cyan)
    }
    private var secondaryRGB: (r: Double, g: Double, b: Double) {
        components(of: AppColors.purple)
    }
    private var tertiaryRGB: (r: Double, g: Double, b: Double) {
        components(of: AppColors.magenta)
    }

    // Spark head colors — dark mode only
    // BUG-3 FIX: used as .color(opacity:) shading in Canvas,
    // NOT as radialGradient shading (which breaks in preview renderer).
    private let sparkOuter: Color = AppColors.magenta
    private let sparkInner: Color = AppColors.cyan

    var body: some View {
        // Capture resolved values before entering Canvas closure.
        // Canvas closures have no Environment access.
        let pRGB        = primaryRGB
        let sRGB        = secondaryRGB
        let tRGB        = tertiaryRGB
        let outer       = sparkOuter
        let inner       = sparkInner
        let borderColor: Color = AppColors.borderHover

        TimelineView(.animation) { timeline in
            Canvas { context, canvasSize in
                let elapsed = timeline.date.timeIntervalSinceReferenceDate
                    .truncatingRemainder(dividingBy: revolutionDuration)
                let progress = elapsed / revolutionDuration
                drawOrbit(
                    context:     context,
                    size:        canvasSize,
                    progress:    progress,
                    pRGB:        pRGB,
                    sRGB:        sRGB,
                    tRGB:        tRGB,
                    sparkOuter:  outer,
                    sparkInner:  inner,
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

        // Border ring
        var borderPath = Path()
        borderPath.addEllipse(in: CGRect(
            x: cx - radius, y: cy - radius,
            width: radius * 2, height: radius * 2
        ))
        context.stroke(borderPath, with: .color(borderColor), lineWidth: 1.5)

        // Trailing dot loop — lerps across three anchor colors
        for i in 0..<steps {
            let t         = Double(i) / Double(steps - 1)
            let dotAngle  = headAngle - tailArc * (1.0 - t)
            let x         = cx + cos(dotAngle) * radius
            let y         = cy + sin(dotAngle) * radius
            let alpha     = t * 0.58
            let dotRadius = 0.9 + t * 0.65

            // Lerp between the three anchor colors:
            //   t < 0.40 → primary → secondary
            //   t ≥ 0.40 → secondary → tertiary
            let color: Color
            if t < 0.4 {
                let blend = t / 0.4
                color = Color(
                    red:   lerp(pRGB.r, sRGB.r, blend),
                    green: lerp(pRGB.g, sRGB.g, blend),
                    blue:  lerp(pRGB.b, sRGB.b, blend)
                )
            } else {
                let blend = (t - 0.4) / 0.6
                color = Color(
                    red:   lerp(sRGB.r, tRGB.r, blend),
                    green: lerp(sRGB.g, tRGB.g, blend),
                    blue:  lerp(sRGB.b, tRGB.b, blend)
                )
            }

            var dotPath = Path()
            dotPath.addEllipse(in: CGRect(
                x: x - dotRadius, y: y - dotRadius,
                width: dotRadius * 2, height: dotRadius * 2
            ))
            context.fill(dotPath, with: .color(color.opacity(alpha)))
        }

        // Spark head — three flat-color opacity layers.
        //
        // BUG-3 FIX: previously used GraphicsContext.Shading.radialGradient,
        // which is silently discarded by the Xcode preview canvas renderer,
        // making the spark invisible in previews. Now uses .color(opacity:)
        // shading — identical to BPOrbitCanvas — which renders correctly in
        // both the simulator and the Xcode preview canvas.
        let hx = cx + cos(headAngle) * radius
        let hy = cy + sin(headAngle) * radius

        // Outer glow — tertiary accent, large halo
        var outerPath = Path()
        outerPath.addEllipse(in: CGRect(
            x: hx - 5.5, y: hy - 5.5,
            width: 11, height: 11
        ))
        context.fill(outerPath, with: .color(sparkOuter.opacity(0.45)))

        // Inner glow — primary accent, tighter focus
        var innerPath = Path()
        innerPath.addEllipse(in: CGRect(
            x: hx - 3, y: hy - 3,
            width: 6, height: 6
        ))
        context.fill(innerPath, with: .color(sparkInner.opacity(0.55)))

        // Core — white focal point
        var corePath = Path()
        corePath.addEllipse(in: CGRect(
            x: hx - 1.8, y: hy - 1.8,
            width: 3.6, height: 3.6
        ))
        context.fill(corePath, with: .color(.white.opacity(0.96)))
    }

    // MARK: - Helpers

    private func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double {
        a + (b - a) * t
    }

    /// Resolve a SwiftUI Color to RGB components via UIColor.
    /// Bridges AppColors tokens into the Canvas rendering path.
    private func components(of color: Color) -> (r: Double, g: Double, b: Double) {
        let uiColor = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b))
    }
}

// MARK: - Previews
//
// BUG-4 FIX: previews now include a live cycling variant that drives
// OrbitIndicator through all three states on a loop. A purely static
// preview that never invalidates can pause the TimelineView(.animation)
// scheduler. The cycling preview keeps the host view alive and redrawing,
// which ensures TimelineView fires continuously.
//
// The static grid previews are retained for quick visual inspection of
// all sizes and both color schemes.

#Preview("Dark Mode — Static Grid") {
    ZStack {
        Color.black.ignoresSafeArea()
        ScrollView {
            VStack(spacing: 48) {
                Text("ORBIT INDICATOR")
                    .font(.system(size: 9, weight: .bold))
                    .kerning(2.2)
                    .foregroundStyle(AppColors.textTertiary)

                // ── Three states at default size (22pt) ──────────────
                VStack(spacing: 12) {
                    Text("22pt — default")
                        .font(.system(size: 9, weight: .semibold))
                        .kerning(1.8)
                        .foregroundStyle(AppColors.textTertiary)
                    HStack(spacing: 32) {
                        VStack(spacing: 8) {
                            OrbitIndicator(state: .pending)
                            Text("pending")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.textTertiary)
                        }
                        VStack(spacing: 8) {
                            OrbitIndicator(state: .processing)
                            Text("processing")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.textTertiary)
                        }
                        VStack(spacing: 8) {
                            OrbitIndicator(state: .complete)
                            Text("complete")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.textTertiary)
                        }
                    }
                }

                // ── Three states at medium size (32pt) ───────────────
                VStack(spacing: 12) {
                    Text("32pt — medium")
                        .font(.system(size: 9, weight: .semibold))
                        .kerning(1.8)
                        .foregroundStyle(AppColors.textTertiary)
                    HStack(spacing: 32) {
                        VStack(spacing: 8) {
                            OrbitIndicator(state: .pending, size: 32)
                            Text("pending")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.textTertiary)
                        }
                        VStack(spacing: 8) {
                            OrbitIndicator(state: .processing, size: 32)
                            Text("processing")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.textTertiary)
                        }
                        VStack(spacing: 8) {
                            OrbitIndicator(state: .complete, size: 32)
                            Text("complete")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.textTertiary)
                        }
                    }
                }

                // ── Three states at large size (44pt) ────────────────
                VStack(spacing: 12) {
                    Text("44pt — large")
                        .font(.system(size: 9, weight: .semibold))
                        .kerning(1.8)
                        .foregroundStyle(AppColors.textTertiary)
                    HStack(spacing: 32) {
                        VStack(spacing: 8) {
                            OrbitIndicator(state: .pending, size: 44)
                            Text("pending")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.textTertiary)
                        }
                        VStack(spacing: 8) {
                            OrbitIndicator(state: .processing, size: 44)
                            Text("processing")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.textTertiary)
                        }
                        VStack(spacing: 8) {
                            OrbitIndicator(state: .complete, size: 44)
                            Text("complete")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.textTertiary)
                        }
                    }
                }

                // ── In-row context ────────────────────────────────────
                VStack(spacing: 12) {
                    Text("IN-ROW CONTEXT")
                        .font(.system(size: 9, weight: .semibold))
                        .kerning(1.8)
                        .foregroundStyle(AppColors.textTertiary)
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 14) {
                            OrbitIndicator(state: .complete).fixedSize()
                            VStack(alignment: .leading, spacing: 2) {
                                Text("STARTING POINT")
                                    .font(.system(size: 9, weight: .bold))
                                    .kerning(1.5)
                                    .foregroundStyle(AppColors.textTertiary)
                                Text("Beginning from curiosity")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(AppColors.textPrimary)
                            }
                        }
                        HStack(spacing: 14) {
                            OrbitIndicator(state: .processing).fixedSize()
                            VStack(alignment: .leading, spacing: 2) {
                                Text("YOUR SITUATION")
                                    .font(.system(size: 9, weight: .bold))
                                    .kerning(1.5)
                                    .foregroundStyle(AppColors.textTertiary)
                                Text("Opening the conversation")
                                    .font(.system(size: 14))
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                        }
                        HStack(spacing: 14) {
                            OrbitIndicator(state: .pending).fixedSize()
                            VStack(alignment: .leading, spacing: 2) {
                                Text("FIRST TO EXPLORE")
                                    .font(.system(size: 9, weight: .bold))
                                    .kerning(1.5)
                                    .foregroundStyle(AppColors.textTertiary)
                                Text("Communication & connection")
                                    .font(.system(size: 14))
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                        }
                    }
                    .padding(20)
                    .background(AppColors.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(32)
        }
    }
    .preferredColorScheme(.dark)
}

// BUG-4 FIX: Live cycling preview.
//
// Drives a single OrbitIndicator through pending → processing → complete
// on a repeating loop. This keeps the host view alive and continuously
// invalidating, which ensures TimelineView(.animation) fires every frame.
// Use this preview to verify the comet orbit and complete-fill transitions.
#Preview("Dark Mode — Live Cycle") {
    // State sequence: pending(1.0s) → processing(2.5s) → complete(1.5s) → repeat
    @Previewable @State var cycleState: OrbitIndicatorState = .pending
    @Previewable @State var sizeIndex: Int = 1   // 0=22pt, 1=32pt, 2=44pt
    let sizes: [CGFloat] = [22, 32, 44]
    let sizeLabels = ["22pt", "32pt", "44pt"]

    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 32) {
            Text("LIVE CYCLE")
                .font(.system(size: 9, weight: .bold))
                .kerning(2.2)
                .foregroundStyle(AppColors.textTertiary)

            OrbitIndicator(state: cycleState, size: sizes[sizeIndex])

            Text(cycleState == .pending    ? "pending"    :
                 cycleState == .processing ? "processing" : "complete")
                .font(.system(size: 11, weight: .semibold))
                .kerning(1.6)
                .foregroundStyle(AppColors.textTertiary)
                .animation(.none, value: cycleState)

            // Size picker
            HStack(spacing: 0) {
                ForEach(0..<3) { i in
                    Button(sizeLabels[i]) { sizeIndex = i }
                        .font(.system(size: 12, weight: sizeIndex == i ? .bold : .regular))
                        .foregroundStyle(sizeIndex == i
                            ? AppColors.cyan
                            : AppColors.textTertiary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                }
            }
            .background(AppColors.cardBg)
            .clipShape(Capsule())
        }
    }
    .preferredColorScheme(.dark)
    .task {
        // Loop: pending → processing → complete → pending …
        while true {
            try? await Task.sleep(for: .seconds(1.0))
            withAnimation(.easeOut(duration: 0.3)) { cycleState = .processing }
            try? await Task.sleep(for: .seconds(2.5))
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                cycleState = .complete
            }
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation(.easeOut(duration: 0.3)) { cycleState = .pending }
        }
    }
}

#Preview("Light Mode — Static Grid") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        ScrollView {
            VStack(spacing: 48) {
                Text("ORBIT INDICATOR")
                    .font(.system(size: 9, weight: .bold))
                    .kerning(2.2)
                    .foregroundStyle(AppColors.lightTextTertiary)

                VStack(spacing: 12) {
                    Text("22pt — default")
                        .font(.system(size: 9, weight: .semibold))
                        .kerning(1.8)
                        .foregroundStyle(AppColors.lightTextTertiary)
                    HStack(spacing: 32) {
                        VStack(spacing: 8) {
                            OrbitIndicator(state: .pending)
                            Text("pending")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.lightTextTertiary)
                        }
                        VStack(spacing: 8) {
                            OrbitIndicator(state: .processing)
                            Text("processing")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.lightTextTertiary)
                        }
                        VStack(spacing: 8) {
                            OrbitIndicator(state: .complete)
                            Text("complete")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.lightTextTertiary)
                        }
                    }
                }

                VStack(spacing: 12) {
                    Text("32pt — medium")
                        .font(.system(size: 9, weight: .semibold))
                        .kerning(1.8)
                        .foregroundStyle(AppColors.lightTextTertiary)
                    HStack(spacing: 32) {
                        VStack(spacing: 8) {
                            OrbitIndicator(state: .pending, size: 32)
                            Text("pending")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.lightTextTertiary)
                        }
                        VStack(spacing: 8) {
                            OrbitIndicator(state: .processing, size: 32)
                            Text("processing")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.lightTextTertiary)
                        }
                        VStack(spacing: 8) {
                            OrbitIndicator(state: .complete, size: 32)
                            Text("complete")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.lightTextTertiary)
                        }
                    }
                }

                VStack(spacing: 12) {
                    Text("44pt — large")
                        .font(.system(size: 9, weight: .semibold))
                        .kerning(1.8)
                        .foregroundStyle(AppColors.lightTextTertiary)
                    HStack(spacing: 32) {
                        VStack(spacing: 8) {
                            OrbitIndicator(state: .pending, size: 44)
                            Text("pending")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.lightTextTertiary)
                        }
                        VStack(spacing: 8) {
                            OrbitIndicator(state: .processing, size: 44)
                            Text("processing")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.lightTextTertiary)
                        }
                        VStack(spacing: 8) {
                            OrbitIndicator(state: .complete, size: 44)
                            Text("complete")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.lightTextTertiary)
                        }
                    }
                }

                VStack(spacing: 12) {
                    Text("IN-ROW CONTEXT")
                        .font(.system(size: 9, weight: .semibold))
                        .kerning(1.8)
                        .foregroundStyle(AppColors.lightTextTertiary)
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 14) {
                            OrbitIndicator(state: .complete).fixedSize()
                            VStack(alignment: .leading, spacing: 2) {
                                Text("STARTING POINT")
                                    .font(.system(size: 9, weight: .bold))
                                    .kerning(1.5)
                                    .foregroundStyle(AppColors.lightTextTertiary)
                                Text("Beginning from curiosity")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(AppColors.lightTextPrimary)
                            }
                        }
                        HStack(spacing: 14) {
                            OrbitIndicator(state: .processing).fixedSize()
                            VStack(alignment: .leading, spacing: 2) {
                                Text("YOUR SITUATION")
                                    .font(.system(size: 9, weight: .bold))
                                    .kerning(1.5)
                                    .foregroundStyle(AppColors.lightTextTertiary)
                                Text("Opening the conversation")
                                    .font(.system(size: 14))
                                    .foregroundStyle(AppColors.lightTextSecondary)
                            }
                        }
                        HStack(spacing: 14) {
                            OrbitIndicator(state: .pending).fixedSize()
                            VStack(alignment: .leading, spacing: 2) {
                                Text("FIRST TO EXPLORE")
                                    .font(.system(size: 9, weight: .bold))
                                    .kerning(1.5)
                                    .foregroundStyle(AppColors.lightTextTertiary)
                                Text("Communication & connection")
                                    .font(.system(size: 14))
                                    .foregroundStyle(AppColors.lightTextSecondary)
                            }
                        }
                    }
                    .padding(20)
                    .background(AppColors.lightCardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(32)
        }
    }
    .preferredColorScheme(.light)
}

#Preview("Light Mode — Live Cycle") {
    @Previewable @State var cycleState: OrbitIndicatorState = .pending
    @Previewable @State var sizeIndex: Int = 1
    let sizes: [CGFloat] = [22, 32, 44]
    let sizeLabels = ["22pt", "32pt", "44pt"]

    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        VStack(spacing: 32) {
            Text("LIVE CYCLE")
                .font(.system(size: 9, weight: .bold))
                .kerning(2.2)
                .foregroundStyle(AppColors.lightTextTertiary)

            OrbitIndicator(state: cycleState, size: sizes[sizeIndex])

            Text(cycleState == .pending    ? "pending"    :
                 cycleState == .processing ? "processing" : "complete")
                .font(.system(size: 11, weight: .semibold))
                .kerning(1.6)
                .foregroundStyle(AppColors.lightTextTertiary)
                .animation(.none, value: cycleState)

            HStack(spacing: 0) {
                ForEach(0..<3) { i in
                    Button(sizeLabels[i]) { sizeIndex = i }
                        .font(.system(size: 12, weight: sizeIndex == i ? .bold : .regular))
                        .foregroundStyle(sizeIndex == i
                            ? AppColors.purple
                            : AppColors.lightTextTertiary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                }
            }
            .background(AppColors.lightCardBg)
            .clipShape(Capsule())
        }
    }
    .preferredColorScheme(.light)
    .task {
        while true {
            try? await Task.sleep(for: .seconds(1.0))
            withAnimation(.easeOut(duration: 0.3)) { cycleState = .processing }
            try? await Task.sleep(for: .seconds(2.5))
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                cycleState = .complete
            }
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation(.easeOut(duration: 0.3)) { cycleState = .pending }
        }
    }
}

```

---

## File: `Open Lightly/Design/Components/Progress/ProgressBar.swift` {#file-open-lightly-design-components-progress-progressbar-swift}

```swift
//
//  ProgressBar.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//


import SwiftUI

struct ProgressBar: View {
    @Environment(\.theme) private var t
    let value: Double
    let max: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(t.isAmoled ? .white.opacity(0.06) : t.surface3)

                Capsule()
                    .fill(t.buttonGradient)
                    .frame(width: geo.size.width * (value / max))
                    .animation(.easeOut(duration: 0.6), value: value)
            }
        }
        .frame(height: 4)
    }
}
```

---

## File: `Open Lightly/Design/Components/Progress/ProgressRingView.swift` {#file-open-lightly-design-components-progress-progressringview-swift}

```swift
import SwiftUI

// ✅ Design system audit — verified March 9, 2026

// MARK: - ProgressRingView
// Reusable circular progress ring component
struct ProgressRingView: View {
    let progress: Double // 0.0 to 1.0
    let lineWidth: CGFloat
    let size: CGFloat
    @Environment(\.theme) private var t

    init(progress: Double, lineWidth: CGFloat = 6, size: CGFloat = 60) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.size = size
    }

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .trim(from: 0, to: 1)
                .stroke(
                    t.isAmoled ? Color.white.opacity(0.06) : t.surface3,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
            // Progress arc
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(
                    t.buttonGradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
            // Center content
            Text("\(Int(progress * 100))%")
                .font(.system(size: size * 0.22, weight: .bold, design: .rounded))
                .foregroundStyle(t.text)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Preview
struct ProgressRingView_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 24) {
            ProgressRingView(progress: 0.0)
            ProgressRingView(progress: 0.33)
            ProgressRingView(progress: 0.67)
            ProgressRingView(progress: 1.0)
        }
        .padding()
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }
}

```

---

## File: `Open Lightly/Design/Components/Progress/ScoreRing.swift` {#file-open-lightly-design-components-progress-scorering-swift}

```swift
//
//  ScoreRing.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//


import SwiftUI

struct ScoreRing: View {
    @Environment(\.theme) private var t
    let score: Int
    var size: CGFloat = 110
    var lineWidth: CGFloat = 9

    @State private var progress: CGFloat = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    t.isAmoled ? .white.opacity(0.06) : t.surface3,
                    lineWidth: lineWidth
                )

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    t.ringGradient,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 2) {
                Text(score, format: .number)
                    .font(.system(
                        size: size > 80 ? 28 : 16,
                        weight: .bold,
                        design: .rounded
                    ))
                    .foregroundStyle(t.text)

                if size > 80 {
                    Text("OF 100")
                        .font(.system(size: 9, weight: .semibold))
                        .tracking(1.5)
                        .foregroundStyle(t.textMuted)
                }
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                progress = CGFloat(score) / 100.0
            }
        }
    }
}

```

---

## File: `Open Lightly/Design/Components/Progress/SpectrumBar.swift` {#file-open-lightly-design-components-progress-spectrumbar-swift}

```swift
//
//  SpectrumBar.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//


import SwiftUI

struct SpectrumBar: View {
    @Environment(\.theme) private var t
    var height: CGFloat = 3

    var body: some View {
        Capsule()
            .fill(t.spectrumGradient)
            .frame(height: height)
    }
}
```

---

## File: `Open Lightly/Design/Components/Text/GradientText.swift` {#file-open-lightly-design-components-text-gradienttext-swift}

```swift
// GradientText.swift
// Open Lightly
// Static gradient text — no animation, no shimmer

import SwiftUI

struct GradientText: View {
    let text: String
    let font: Font
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(
                LinearGradient(
                    colors: colorScheme == .light
                        ? [
                            AppColors.magentaDark,
                            AppColors.magenta,
                            AppColors.orangeHot
                          ]
                        : [
                            AppColors.pink,
                            AppColors.purple,
                            AppColors.magenta
                          ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
    }
}

```

---

## File: `Open Lightly/Design/Components/Text/KeywordHighlightText.swift` {#file-open-lightly-design-components-text-keywordhighlighttext-swift}

```swift
//
//  KeywordHighlightText.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import SwiftUI

// MARK: - KeywordHighlightText — keyword highlighting
struct KeywordHighlightText: View {
    let fullText: String
    let keywords: [(text: String, type: String)]
    var font: Font = AppFonts.cardTitle
    var baseColor: Color = AppColors.textPrimary

    private func highlightUIColor(for type: String) -> UIColor {
        switch type.lowercased() {
        case "cyan": return UIColor(AppColors.cyan)
        case "magenta": return UIColor(AppColors.magenta)
        case "gold": return UIColor(AppColors.gold)
        default: return UIColor(baseColor)
        }
    }

    var body: some View {
        Text(buildAttributedString())
            .font(font)
    }

    private func buildAttributedString() -> AttributedString {
        var result = AttributedString(fullText)
        result.font = font
        result.foregroundColor = UIColor(baseColor)
        for keyword in keywords {
            var searchRange = result.startIndex..<result.endIndex
            while let range = result[searchRange].range(of: keyword.text, options: .caseInsensitive) {
                result[range].foregroundColor = highlightUIColor(for: keyword.type)
                if range.upperBound < result.endIndex {
                    searchRange = range.upperBound..<result.endIndex
                } else {
                    break
                }
            }
        }
        return result
    }
}

// MARK: - Preview
#Preview {
    KeywordHighlightText(
        fullText: "What does vulnerability look like when you feel truly safe?",
        keywords: [
            (text: "vulnerability", type: "cyan"),
            (text: "truly safe", type: "magenta")
        ]
    )
    .padding()
    .background(AppColors.pageBg)
}

```

---

## File: `Open Lightly/Design/Components/Text/LivingText.swift` {#file-open-lightly-design-components-text-livingtext-swift}

```swift
import SwiftUI

struct LivingText: View {
    let text: String
    var font: Font = AppFonts.display(28, weight: .semibold)

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Gradient Stops
    //
    // Dark: clean three-stop directional gradient.
    // cyan left → purpleVivid mid → magenta right.
    // purpleVivid (9333EA) is bright enough to read as a
    // distinct color beat without muddying the transition.
    //
    // Light: directional warm sweep.
    // magenta left → orangeHot mid → gold right.

    private var gradientStops: [Color] {
        if colorScheme == .light {
            return [
                AppColors.magenta,
                AppColors.orangeHot,
                AppColors.gold,
            ]
        } else {
            return [
                AppColors.cyan,
                AppColors.purpleVivid,
                AppColors.magenta,
            ]
        }
    }

    // MARK: - Body

    var body: some View {
        Group {
            if UIAccessibility.isReduceMotionEnabled {
                // Static gradient — respects color scheme.
                Text(text)
                    .font(font)
                    .foregroundStyle(LinearGradient(
                        colors: colorScheme == .light
                            ? [AppColors.magenta, AppColors.orangeHot, AppColors.gold]
                            : [AppColors.cyan, AppColors.purpleVivid, AppColors.magenta],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
            } else {
                TimelineView(.animation) { timeline in
                    let elapsed = timeline.date.timeIntervalSinceReferenceDate

                    // Glow breath — 4.3s cycle.
                    // Drives all three bloom layers in unison.
                    let glowCycle = 4.3
                    let glowPhase = CGFloat(
                        elapsed.truncatingRemainder(dividingBy: glowCycle)
                        / glowCycle
                    )
                    let intensity = CGFloat(sin(glowPhase * .pi * 2) * 0.5 + 0.5)

                    // Scale breath — 5.0s cycle, independent of glow.
                    // Sub-perceptual as movement but adds physical presence.
                    let scaleCycle = 5.0
                    let scalePhase = CGFloat(
                        elapsed.truncatingRemainder(dividingBy: scaleCycle)
                        / scaleCycle
                    )
                    let scaleIntensity = CGFloat(sin(scalePhase * .pi * 2) * 0.5 + 0.5)

                    // Tri-color glow — each color blooms at a different phase.
                    // On dark: cyan peaks at 0°, magenta at 120°, purple at 240°.
                    // The three glows are never in the same state simultaneously
                    // so the text always feels alive without a visible loop point.
                    let cyanPhase    = CGFloat(elapsed / 3.0)
                        .truncatingRemainder(dividingBy: 1.0)
                    let magentaPhase = CGFloat(elapsed / 4.0)
                        .truncatingRemainder(dividingBy: 1.0)
                    let midPhase     = CGFloat(elapsed / 5.0)
                        .truncatingRemainder(dividingBy: 1.0)

                    let cyanGlow    = CGFloat(sin(cyanPhase    * .pi * 2) * 0.5 + 0.5)
                    let magentaGlow = CGFloat(sin(magentaPhase * .pi * 2) * 0.5 + 0.5)
                    let midGlow     = CGFloat(sin(midPhase     * .pi * 2) * 0.5 + 0.5)

                    // Animated gradient — static stops, opacity of each color
                    // breathes independently via tri-color phase offsets.
                    let animatedStops: [Color] = colorScheme == .light
                        ? [
                            AppColors.magenta.opacity(0.75 + cyanGlow * 0.25),
                            AppColors.orangeHot.opacity(0.75 + midGlow * 0.25),
                            AppColors.gold.opacity(0.75 + magentaGlow * 0.25),
                          ]
                        : [
                            AppColors.cyan.opacity(0.70 + cyanGlow * 0.30),
                            AppColors.purpleVivid.opacity(0.70 + midGlow * 0.30),
                            AppColors.magenta.opacity(0.70 + magentaGlow * 0.30),
                          ]

                    let baseGradient = LinearGradient(
                        colors: animatedStops,
                        startPoint: .leading,
                        endPoint:   .trailing
                    )

                    let glowOpacity = colorScheme == .light
                        ? 0.20 + Double(intensity) * 0.22
                        : 0.28 + Double(intensity) * 0.30

                    let glowBlur = colorScheme == .light
                        ? 5.0 + intensity * 4.0
                        : 8.0 + intensity * 7.0

                    // Scale breath — 1.000 → 1.008, barely perceptible.
                    let breathScale = colorScheme == .light
                        ? 1.0 + scaleIntensity * 0.008
                        : 1.0 + scaleIntensity * 0.010

                    ZStack {
                        // Outer bloom — wide, atmospheric.
                        Text(text)
                            .font(font)
                            .foregroundStyle(baseGradient)
                            .blur(radius: glowBlur * 1.6)
                            .opacity(glowOpacity * 0.40)
                            .accessibilityHidden(true)

                        // Inner glow — tighter halo ring.
                        Text(text)
                            .font(font)
                            .foregroundStyle(baseGradient)
                            .blur(radius: glowBlur * 0.45)
                            .opacity(glowOpacity * 0.80)
                            .accessibilityHidden(true)

                        // Primary crisp layer — full opacity, no blur.
                        // Scale breath applied here only so blur layers
                        // do not scale (which would spread them too wide).
                        Text(text)
                            .font(font)
                            .foregroundStyle(baseGradient)
                            .scaleEffect(breathScale)
                    }
                }
            }
        }
        .fixedSize()
        .accessibilityLabel(text)
    }
}

// MARK: - Previews

#Preview("Dark") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        VStack(alignment: .leading, spacing: 32) {
            LivingText(text: "acquainted.",
                       font: AppFonts.display(42, weight: .bold))
            LivingText(text: "exploring?",
                       font: AppFonts.heroTitle)
            LivingText(text: "Conversations",
                       font: AppFonts.screenTitle)
            LivingText(text: "Easier",
                       font: AppFonts.screenTitle)
            LivingText(text: "You're in good company.",
                       font: AppFonts.body(20, weight: .bold))
        }
        .padding(28)
    }
    .preferredColorScheme(.dark)
}

#Preview("Light") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        VStack(alignment: .leading, spacing: 32) {
            LivingText(text: "acquainted.",
                       font: AppFonts.display(42, weight: .bold))
            LivingText(text: "exploring?",
                       font: AppFonts.heroTitle)
            LivingText(text: "Conversations",
                       font: AppFonts.screenTitle)
        }
        .padding(28)
    }
    .preferredColorScheme(.light)
}

#Preview("Against atmosphere — Dark") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        Ellipse()
            .fill(RadialGradient(
                colors: [
                    AppColors.magenta.opacity(0.30),
                    AppColors.purple.opacity(0.15),
                    Color.clear,
                ],
                center: .top,
                startRadius: 30,
                endRadius: 360
            ))
            .frame(width: 500, height: 400)
            .offset(y: -200)
            .blur(radius: 80)
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 4) {
                Text("How are you")
                    .font(AppFonts.heroTitle)
                    .foregroundStyle(AppColors.textPrimary)
                LivingText(text: "exploring?", font: AppFonts.heroTitle)
            }
            LivingText(text: "acquainted.",
                       font: AppFonts.display(42, weight: .bold))
        }
        .padding(28)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .preferredColorScheme(.dark)
}

```

---

## File: `Open Lightly/Design/Components/CardStyle.swift` {#file-open-lightly-design-components-cardstyle-swift}

```swift
import SwiftUI

/// Reusable card-shell modifier: background + rounded clip + border stroke.
///
/// Replaces the repetitive 3-line pattern scattered across views:
/// ```swift
/// .background(AppColors.card)
/// .clipShape(RoundedRectangle(cornerRadius: 20))
/// .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppColors.border, lineWidth: 1))
/// ```
///
/// Usage:
/// ```swift
/// VStack { ... }
///     .cardStyle()                          // defaults: card bg, r20, border stroke
///     .cardStyle(cornerRadius: 12)          // custom radius
///     .cardStyle(background: .surfaceBg)    // custom bg
/// ```
struct CardStyle: ViewModifier {
    var background: Color = AppColors.card
    var cornerRadius: CGFloat = 20
    var borderColor: Color = AppColors.border
    var lineWidth: CGFloat = 1.5

    func body(content: Content) -> some View {
        content
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: lineWidth)
            )
    }
}

extension View {
    func cardStyle(
        background: Color = AppColors.card,
        cornerRadius: CGFloat = 20,
        borderColor: Color = AppColors.border,
        lineWidth: CGFloat = 1.5
    ) -> some View {
        modifier(CardStyle(
            background: background,
            cornerRadius: cornerRadius,
            borderColor: borderColor,
            lineWidth: lineWidth
        ))
    }
}

```

---

## File: `Open Lightly/Design/Components/FilamentMode.swift` {#file-open-lightly-design-components-filamentmode-swift}

```swift
// FilamentView.swift
// Open Lightly
//
// v4 — exitProgress parameter for orbit contraction transition

import SwiftUI
import Combine

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - FilamentMode
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

enum FilamentMode {
    case solo
    case duo
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - FilamentPattern
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

enum FilamentPattern: Int, CaseIterable {
    case figure8
    case lemniscate
    case sCurve
    case weave
    case circle
    case spiral
    case drift
    case pendulum

    func position(t: Double, offset: Double) -> CGPoint {
        switch self {

        case .figure8:
            return CGPoint(
                x: sin(t + offset),
                y: sin((t + offset) * 2) * 0.55
            )

        case .lemniscate:
            let s = t + offset
            let d = 1 + pow(sin(s), 2)
            return CGPoint(
                x: (cos(s) / d) * 1.2,
                y: (sin(s) * cos(s) / d) * 1.2
            )

        case .sCurve:
            return CGPoint(
                x: sin((t + offset) * 0.5) * 0.95,
                y: sin(t + offset) * 0.65
                    + cos((t + offset) * 1.5) * 0.28
            )

        case .weave:
            return CGPoint(
                x: sin((t + offset) * 0.7)
                    + sin((t + offset) * 1.9) * 0.35,
                y: cos((t + offset) * 0.9)
                    + cos((t + offset) * 2.3) * 0.22
            )

        case .circle:
            return CGPoint(
                x: cos(t + offset) * 0.88,
                y: sin(t + offset) * 0.88
            )

        case .spiral:
            let r = 0.5 + sin((t + offset) * 0.3) * 0.45
            return CGPoint(
                x: cos((t + offset) * 1.3) * r,
                y: sin((t + offset) * 1.3) * r * 0.85
            )

        case .drift:
            return CGPoint(
                x: sin((t + offset) * 0.4) * 0.75
                    + sin((t + offset) * 1.7) * 0.22,
                y: cos((t + offset) * 0.55) * 0.65
                    + sin((t + offset) * 1.3 + 1) * 0.28
            )

        case .pendulum:
            let swing = sin((t + offset) * 0.6) * 0.92
            return CGPoint(
                x: swing,
                y: -abs(cos((t + offset) * 0.6)) * 0.48
                    + sin((t + offset) * 2.4) * 0.28 + 0.18
            )
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - FilamentColorSet
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct FilamentColorSet {
    let primary: Color
    let light:   Color
    let glow:    Color

    static let darkSets: [FilamentColorSet] = [
        FilamentColorSet(
            primary: Color(hex: "#00C2FF"),
            light:   Color(hex: "#4DD8FF"),
            glow:    Color(hex: "#0078FF")
        ),
        FilamentColorSet(
            primary: Color(hex: "#FF006A"),
            light:   Color(hex: "#FF4D94"),
            glow:    Color(hex: "#BE185D")
        ),
        FilamentColorSet(
            primary: Color(hex: "#6C3AE0"),
            light:   Color(hex: "#A78BFA"),
            glow:    Color(hex: "#1A1A5E")
        ),
        FilamentColorSet(
            primary: Color(hex: "#C8960A"),
            light:   Color(hex: "#F0BC2E"),
            glow:    Color(hex: "#92680A")
        ),
        FilamentColorSet(
            primary: Color(hex: "#0891B2"),
            light:   Color(hex: "#22D3EE"),
            glow:    Color(hex: "#164E63")
        ),
    ]

    static let lightSets: [FilamentColorSet] = [
        FilamentColorSet(
            primary: Color(hex: "#BE185D"),
            light:   Color(hex: "#EC4899"),
            glow:    Color(hex: "#831843")
        ),
        FilamentColorSet(
            primary: Color(hex: "#7C3AED"),
            light:   Color(hex: "#A78BFA"),
            glow:    Color(hex: "#4C1D95")
        ),
        FilamentColorSet(
            primary: Color(hex: "#C2410C"),
            light:   Color(hex: "#FB923C"),
            glow:    Color(hex: "#7C2D12")
        ),
        FilamentColorSet(
            primary: Color(hex: "#0E7490"),
            light:   Color(hex: "#06B6D4"),
            glow:    Color(hex: "#164E63")
        ),
        FilamentColorSet(
            primary: Color(hex: "#B45309"),
            light:   Color(hex: "#F59E0B"),
            glow:    Color(hex: "#78350F")
        ),
    ]
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - FilamentState
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

final class FilamentState: ObservableObject {

    @Published var trail1: [CGPoint] = []
    @Published var trail2: [CGPoint] = []
    @Published var trail3: [CGPoint] = []

    @Published var currentColorSet: FilamentColorSet
    @Published var nextColorSet:    FilamentColorSet
    @Published var colorProgress:   Double = 0

    private var t: Double = 0

    private var currentPattern1:     FilamentPattern
    private var nextPattern1:        FilamentPattern? = nil
    private var transitionProgress1: Double           = 0
    private var patternTimer1:       Int              = 0
    private var patternDuration1:    Int

    private var currentPattern2:     FilamentPattern
    private var nextPattern2:        FilamentPattern? = nil
    private var transitionProgress2: Double           = 0
    private var patternTimer2:       Int              = 0
    private var patternDuration2:    Int

    private var currentPattern3:     FilamentPattern
    private var nextPattern3:        FilamentPattern? = nil
    private var transitionProgress3: Double           = 0
    private var patternTimer3:       Int              = 0
    private var patternDuration3:    Int

    private var colorTimer:         Int  = 0
    private var colorDuration:      Int
    private var colorTransitioning: Bool = false
    private var colorSets:          [FilamentColorSet]
    private var currentColorIndex:  Int

    private static let maxTrail:         Int    = 130
    private static let transitionFrames: Double = 120
    private static let colorFadeFrames:  Double = 180

    init(isDark: Bool = true) {
        let all = FilamentPattern.allCases
        let i1  = Int.random(in: 0 ..< all.count)
        let i2  = (i1 + 3 + Int.random(in: 0 ..< 3)) % all.count
        let i3  = (i2 + 2 + Int.random(in: 0 ..< 2)) % all.count
        currentPattern1  = all[i1]
        currentPattern2  = all[i2]
        currentPattern3  = all[i3]
        patternDuration1 = 280 + Int.random(in: 0 ..< 200)
        patternDuration2 = 320 + Int.random(in: 0 ..< 180)
        patternDuration3 = 300 + Int.random(in: 0 ..< 160)
        colorDuration    = 360 + Int.random(in: 0 ..< 240)

        colorSets         = isDark
            ? FilamentColorSet.darkSets.shuffled()
            : FilamentColorSet.lightSets.shuffled()
        currentColorIndex = 0
        currentColorSet   = colorSets[0]
        nextColorSet      = colorSets[1 % colorSets.count]
    }

    private func easeInOut(_ x: Double) -> Double {
        x < 0.5 ? 4*x*x*x : 1 - pow(-2*x + 2, 3) / 2
    }

    private func pickNext(avoiding c: FilamentPattern) -> FilamentPattern {
        let all        = FilamentPattern.allCases
        let cur        = c.rawValue
        let candidates = all.filter { abs($0.rawValue - cur) >= 2 }
        return (candidates.isEmpty
            ? all.filter { $0 != c }
            : candidates
        ).randomElement()!
    }

    private func lerped(
        current:  FilamentPattern,
        next:     FilamentPattern?,
        progress: Double,
        t:        Double,
        offset:   Double
    ) -> CGPoint {
        let base = current.position(t: t, offset: offset)
        guard let next, progress > 0 else { return base }
        let tgt = next.position(t: t, offset: offset)
        let e   = easeInOut(progress)
        return CGPoint(
            x: base.x * (1 - e) + tgt.x * e,
            y: base.y * (1 - e) + tgt.y * e
        )
    }

    // ── Advance ───────────────────────────────────
    //
    // exitProgress: nil = normal orbiting.
    // 0.0→1.0 = spiral contraction toward center.
    //
    // Two effects of exitProgress:
    //
    // 1. SPREAD REDUCTION
    //    spread is multiplied by (1 - exitProgress).
    //    At exitProgress=1.0, spread=0 — all particles
    //    converge to canvas center point.
    //
    // 2. SPIRAL ACCELERATION
    //    t advances faster as exitProgress increases.
    //    speedMultiplier = 1.0 + exitProgress * 4.0
    //    At exitProgress=0.5, particles orbit ~3x faster.
    //    At exitProgress=1.0, ~5x faster.
    //    This creates the visual spiral-inward effect —
    //    particles are still orbiting their patterns but
    //    the radius is shrinking, producing a spiral.
    //
    // Trail history is preserved during contraction so
    // the trail "chases" the contracting head — giving
    // the spiral a comet-tail appearance rather than
    // the entire trail collapsing at once.

    func advance(speed: Double, mode: FilamentMode, size: CGFloat,
                 exitProgress: CGFloat = 0) {

        // Speed multiplier — orbits accelerate as they contract.
        // easeInOut applied so acceleration starts gently.
        let ep             = Double(max(0, min(1, exitProgress)))
        let easedEP        = easeInOut(ep)
        let speedMultiplier = 1.0 + easedEP * 4.0
        t += 0.012 * speed * speedMultiplier

        // Spread shrinks toward zero as exitProgress reaches 1.
        // Particles converge on canvas center (cx, cy).
        let fullSpread = size * 0.36
        let spread     = fullSpread * CGFloat(1.0 - easedEP)
        let cx         = size / 2
        let cy         = size / 2

        // ── Pattern 1 cycling ─────────────────────
        // Pattern cycling is FROZEN during exit contraction.
        // exitProgress > 0 means the orbits are being wound down —
        // triggering a new pattern mid-contraction would cause a
        // jarring direction change at the worst moment.
        if ep == 0 {
            patternTimer1 += 1
            if nextPattern1 == nil, patternTimer1 > patternDuration1 {
                nextPattern1        = pickNext(avoiding: currentPattern1)
                transitionProgress1 = 0
            }
            if nextPattern1 != nil {
                transitionProgress1 += 1 / Self.transitionFrames
                if transitionProgress1 >= 1 {
                    currentPattern1     = nextPattern1!
                    nextPattern1        = nil
                    transitionProgress1 = 0
                    patternTimer1       = 0
                    patternDuration1    = 250 + Int.random(in: 0 ..< 250)
                }
            }
        }

        let p1n = lerped(
            current:  currentPattern1,
            next:     nextPattern1,
            progress: transitionProgress1,
            t:        t,
            offset:   0
        )
        var t1 = trail1
        t1.append(CGPoint(x: cx + p1n.x * spread,
                          y: cy + p1n.y * spread))
        if t1.count > Self.maxTrail { t1.removeFirst() }
        trail1 = t1

        // ── Pattern 2 cycling ─────────────────────

        if ep == 0 {
            patternTimer2 += 1
            if nextPattern2 == nil, patternTimer2 > patternDuration2 {
                nextPattern2        = pickNext(avoiding: currentPattern2)
                transitionProgress2 = 0
            }
            if nextPattern2 != nil {
                transitionProgress2 += 1 / Self.transitionFrames
                if transitionProgress2 >= 1 {
                    currentPattern2     = nextPattern2!
                    nextPattern2        = nil
                    transitionProgress2 = 0
                    patternTimer2       = 0
                    patternDuration2    = 280 + Int.random(in: 0 ..< 220)
                }
            }
        }

        let trail2T      = mode == .solo ? t * 0.82 : t * 0.85
        let trail2Offset = mode == .solo ? Double.pi  : 2.2

        let p2n = lerped(
            current:  currentPattern2,
            next:     nextPattern2,
            progress: transitionProgress2,
            t:        trail2T,
            offset:   trail2Offset
        )
        var t2 = trail2
        t2.append(CGPoint(x: cx + p2n.x * spread,
                          y: cy + p2n.y * spread))
        if t2.count > Self.maxTrail { t2.removeFirst() }
        trail2 = t2

        // ── Pattern 3 cycling ─────────────────────

        if ep == 0 {
            patternTimer3 += 1
            if nextPattern3 == nil, patternTimer3 > patternDuration3 {
                nextPattern3        = pickNext(avoiding: currentPattern3)
                transitionProgress3 = 0
            }
            if nextPattern3 != nil {
                transitionProgress3 += 1 / Self.transitionFrames
                if transitionProgress3 >= 1 {
                    currentPattern3     = nextPattern3!
                    nextPattern3        = nil
                    transitionProgress3 = 0
                    patternTimer3       = 0
                    patternDuration3    = 300 + Int.random(in: 0 ..< 160)
                }
            }
        }

        let p3n = lerped(
            current:  currentPattern3,
            next:     nextPattern3,
            progress: transitionProgress3,
            t:        t * 0.91,
            offset:   4.2
        )
        var t3 = trail3
        t3.append(CGPoint(x: cx + p3n.x * spread,
                          y: cy + p3n.y * spread))
        if t3.count > Self.maxTrail { t3.removeFirst() }
        trail3 = t3

        // ── Solo color cycling ────────────────────
        // Frozen during exit — no point cycling colors
        // during a 600ms contraction window.
        guard ep == 0 else { return }

        colorTimer += 1
        if !colorTransitioning, colorTimer > colorDuration {
            colorTransitioning = true
            colorProgress      = 0
        }
        if colorTransitioning {
            colorProgress += 1 / Self.colorFadeFrames
            if colorProgress >= 1 {
                currentColorIndex  = (currentColorIndex + 1) % colorSets.count
                currentColorSet    = colorSets[currentColorIndex]
                let nextIdx        = (currentColorIndex + 1) % colorSets.count
                nextColorSet       = colorSets[nextIdx]
                colorProgress      = 0
                colorTransitioning = false
                colorTimer         = 0
                colorDuration      = 360 + Int.random(in: 0 ..< 240)
            }
        }
    }

    func interpolatedColorSet() -> FilamentColorSet {
        guard colorProgress > 0 else { return currentColorSet }
        let e = easeInOut(colorProgress)
        return FilamentColorSet(
            primary: blendColor(currentColorSet.primary,
                                nextColorSet.primary, t: e),
            light:   blendColor(currentColorSet.light,
                                nextColorSet.light,   t: e),
            glow:    blendColor(currentColorSet.glow,
                                nextColorSet.glow,    t: e)
        )
    }

    private func blendColor(_ a: Color, _ b: Color, t: Double) -> Color {
        t < 0.5 ? a : b
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - FilamentView
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct FilamentView: View {

    var size:  CGFloat      = 300
    var mode:  FilamentMode = .duo
    var speed: Double       = 1.0

    // EXIT CONTRACTION
    // ─────────────────
    // nil  = normal orbiting — no contraction (default).
    //        All existing call sites pass no value and are unaffected.
    // 0.0  = contraction begins, full orbit radius, normal speed.
    // 1.0  = fully contracted, all particles at canvas center.
    //
    // Animate from nil→0→1 using withAnimation(.easeInOut(duration: 0.60))
    // in OnboardingBrandView at t=4700ms.
    //
    // Internal behaviour:
    //   — spread multiplied by (1 - easeInOut(exitProgress))
    //   — t advance speed multiplied by (1 + easeInOut(exitProgress) * 4)
    //   — pattern cycling frozen (no jarring direction changes mid-spiral)
    //   — color cycling frozen
    var exitProgress: CGFloat? = nil

    // 1, 2, or 3. Default 3 — all existing call sites unaffected.
    var orbitCount: Int = 3

    // false suppresses connection arcs between trail heads.
    // Use false in small tiles where arcs read as noise.
    // Default true — all existing call sites unaffected.
    var showConnections: Bool = true

    @Environment(\.colorScheme) private var colorScheme

    @StateObject private var fs = FilamentState()

    private let timer = Timer.publish(
        every: 1.0 / 60.0,
        on: .main,
        in: .common
    ).autoconnect()

    var body: some View {
        Canvas { context, _ in
            let f1primary = colorScheme == .dark ? AppColors.cyan        : AppColors.magenta
            let f1light   = colorScheme == .dark ? AppColors.cyanLight   : AppColors.magentaLight
            let f1glow    = colorScheme == .dark ? AppColors.deepBlue    : AppColors.magentaDark

            let f2primary = colorScheme == .dark ? AppColors.magenta     : AppColors.orangeHot
            let f2light   = colorScheme == .dark ? AppColors.magentaLight: AppColors.gold
            let f2glow    = colorScheme == .dark ? AppColors.pink        : AppColors.goldDark

            let f3primary = colorScheme == .dark ? AppColors.purple      : AppColors.purple
            let f3light   = colorScheme == .dark ? AppColors.purpleLight : AppColors.purpleLight
            let f3glow    = colorScheme == .dark ? AppColors.purpleDark  : AppColors.purpleDark

            // Orbit 1 — always drawn
            drawFilament(ctx: &context, trail: fs.trail1,
                         primary: f1primary, light: f1light, glow: f1glow)

            // Orbit 2 — drawn when orbitCount >= 2
            if orbitCount >= 2 {
                if showConnections {
                    drawConnection(ctx: &context,
                                   trail1: fs.trail1, trail2: fs.trail3)
                }
                drawFilament(ctx: &context, trail: fs.trail3,
                             primary: f3primary, light: f3light, glow: f3glow)
            }

            // Orbit 3 — drawn when orbitCount >= 3
            if orbitCount >= 3 {
                if showConnections {
                    drawConnection(ctx: &context,
                                   trail1: fs.trail3, trail2: fs.trail2)
                }
                drawFilament(ctx: &context, trail: fs.trail2,
                             primary: f2primary, light: f2light, glow: f2glow)
            }

            // NOTE: FilamentState always advances all three trails regardless
            // of orbitCount. Unused trails compute but don't render — this
            // keeps trail2/trail3 warm so switching orbitCount mid-session
            // produces no cold-start visual gap.
        }
        .frame(width: size, height: size)
        .onReceive(timer) { _ in
            fs.advance(
                speed:        speed,
                mode:         mode,
                size:         size,
                exitProgress: exitProgress ?? 0
            )
        }
        .onAppear {
            fs.resetColors(isDark: colorScheme == .dark)
        }
        .onChange(of: colorScheme) { _, newScheme in
            fs.resetColors(isDark: newScheme == .dark)
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - drawFilament
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private func drawFilament(
        ctx:       inout GraphicsContext,
        trail:     [CGPoint],
        primary:   Color,
        light:     Color,
        glow:      Color,
        dimFactor: Double = 1.0
    ) {
        guard trail.count >= 2 else { return }

        let count = Double(trail.count)

        // Pass 1 — glow
        for i in 1 ..< trail.count {
            let alpha = (0.04 + (Double(i) / count) * 0.18) * dimFactor
            let width = CGFloat(1.0 + (Double(i) / count) * 5.0)

            var seg = Path()
            seg.move(to: trail[i - 1])
            seg.addLine(to: trail[i])

            ctx.stroke(
                seg,
                with: .color(glow.opacity(alpha)),
                style: StrokeStyle(lineWidth: width + 8, lineCap: .round)
            )
        }

        // Pass 2 — mid + core
        for i in 1 ..< trail.count {
            let alpha = (0.08 + (Double(i) / count) * 0.88) * dimFactor
            let width = CGFloat(0.5 + (Double(i) / count) * 3.5)

            var seg = Path()
            seg.move(to: trail[i - 1])
            seg.addLine(to: trail[i])

            ctx.stroke(
                seg,
                with: .color(primary.opacity(alpha * 0.60)),
                style: StrokeStyle(lineWidth: width + 3, lineCap: .round)
            )
            ctx.stroke(
                seg,
                with: .color(light.opacity(alpha * 0.95)),
                style: StrokeStyle(lineWidth: width, lineCap: .round)
            )
        }

        // Head glow
        let head  = trail[trail.count - 1]
        let headR = size * 0.065 * CGFloat(dimFactor < 1.0 ? 0.80 : 1.0)

        ctx.fill(
            Path(ellipseIn: CGRect(
                x: head.x - headR, y: head.y - headR,
                width: headR * 2,  height: headR * 2
            )),
            with: .radialGradient(
                Gradient(stops: [
                    .init(color: light.opacity(0.95 * dimFactor),   location: 0.00),
                    .init(color: primary.opacity(0.55 * dimFactor), location: 0.35),
                    .init(color: primary.opacity(0.00),             location: 1.00)
                ]),
                center:      head,
                startRadius: 0,
                endRadius:   headR
            )
        )

        // White-hot dot
        let dotR: CGFloat = dimFactor < 1.0 ? 2.5 : 3.5
        ctx.fill(
            Path(ellipseIn: CGRect(
                x: head.x - dotR, y: head.y - dotR,
                width: dotR * 2,  height: dotR * 2
            )),
            with: .radialGradient(
                Gradient(stops: [
                    .init(color: Color.white.opacity(dimFactor), location: 0.0),
                    .init(color: light.opacity(0.0),             location: 1.0)
                ]),
                center:      head,
                startRadius: 0,
                endRadius:   dotR
            )
        )
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - drawConnection
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private func drawConnection(
        ctx:    inout GraphicsContext,
        trail1: [CGPoint],
        trail2: [CGPoint]
    ) {
        guard let p1 = trail1.last,
              let p2 = trail2.last else { return }

        let dist    = hypot(p2.x - p1.x, p2.y - p1.y)
        let maxDist = size * 0.50
        guard dist < maxDist else { return }

        let closeness = 1.0 - dist / maxDist
        let ease      = closeness * closeness

        let mx    = (p1.x + p2.x) / 2
        let my    = (p1.y + p2.y) / 2
        let perpX = -(p2.y - p1.y) * 0.2 * ease
        let perpY =  (p2.x - p1.x) * 0.2 * ease
        let ctrl  = CGPoint(x: mx + perpX, y: my + perpY)

        var arc = Path()
        arc.move(to: p1)
        arc.addQuadCurve(to: p2, control: ctrl)

        ctx.stroke(
            arc,
            with: .color(Color(hex: "#A78BFA").opacity(ease * 0.22)),
            style: StrokeStyle(lineWidth: CGFloat(ease * 12), lineCap: .round)
        )
        ctx.stroke(
            arc,
            with: .color(Color(hex: "#A78BFA").opacity(ease * 0.65)),
            style: StrokeStyle(lineWidth: CGFloat(ease * 2.5), lineCap: .round)
        )

        if ease > 0.3 {
            let mgR = size * 0.07
            let adj = ease - 0.3
            ctx.fill(
                Path(ellipseIn: CGRect(
                    x: ctrl.x - mgR, y: ctrl.y - mgR,
                    width: mgR * 2,  height: mgR * 2
                )),
                with: .radialGradient(
                    Gradient(stops: [
                        .init(color: Color(hex: "#A78BFA").opacity(adj * 0.55), location: 0.0),
                        .init(color: Color(hex: "#7C3AED").opacity(adj * 0.22), location: 0.5),
                        .init(color: Color(hex: "#6C3AE0").opacity(0.00),       location: 1.0)
                    ]),
                    center:      ctrl,
                    startRadius: 0,
                    endRadius:   mgR
                )
            )
        }

        if ease > 0.4 {
            let sparkCount = max(1, Int((ease - 0.4) * 10))
            let step1      = max(1, trail1.count / sparkCount)
            let step2      = max(1, trail2.count / sparkCount)
            var fired      = 0
            outer: for i in stride(from: 0, to: trail1.count, by: step1) {
                for j in stride(from: 0, to: trail2.count, by: step2) {
                    let tp1 = trail1[i], tp2 = trail2[j]
                    guard hypot(tp2.x - tp1.x, tp2.y - tp1.y) < size * 0.09
                    else { continue }
                    ctx.fill(
                        Path(ellipseIn: CGRect(
                            x: (tp1.x + tp2.x) / 2 - 1.5,
                            y: (tp1.y + tp2.y) / 2 - 1.5,
                            width: 3, height: 3
                        )),
                        with: .color(Color(hex: "#A78BFA").opacity(0.55))
                    )
                    fired += 1
                    if fired >= sparkCount { break outer }
                }
            }
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - FilamentState color reset
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extension FilamentState {
    func resetColors(isDark: Bool) {
        let sets           = isDark
            ? FilamentColorSet.darkSets.shuffled()
            : FilamentColorSet.lightSets.shuffled()
        currentColorIndex  = 0
        currentColorSet    = sets[0]
        nextColorSet       = sets[1 % sets.count]
        colorProgress      = 0
        colorTransitioning = false
        colorTimer         = 0
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Previews
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

#Preview("Dark — Solo (color cycling)") {
    ZStack {
        Color(hex: "#030305").ignoresSafeArea()
        VStack(spacing: 20) {
            Text("Solo · dark · color cycling")
                .font(.caption)
                .foregroundStyle(Color(hex: "#666680"))
            FilamentView(size: 300, mode: .solo, speed: 1.0)
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Dark — Solo — Exit contraction") {
    // Preview the exitProgress contraction at 50% and 100%
    ZStack {
        Color(hex: "#030305").ignoresSafeArea()
        VStack(spacing: 32) {
            Text("exitProgress: 0.5")
                .font(.caption)
                .foregroundStyle(Color(hex: "#666680"))
            FilamentView(size: 260, mode: .solo, speed: 1.0, exitProgress: 0.5)

            Text("exitProgress: 0.9")
                .font(.caption)
                .foregroundStyle(Color(hex: "#666680"))
            FilamentView(size: 260, mode: .solo, speed: 1.0, exitProgress: 0.9)
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Dark — Duo") {
    ZStack {
        Color(hex: "#030305").ignoresSafeArea()
        VStack(spacing: 20) {
            Text("Duo · dark · cyan + magenta")
                .font(.caption)
                .foregroundStyle(Color(hex: "#666680"))
            FilamentView(size: 300, mode: .duo, speed: 1.0)
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Light — Solo (color cycling)") {
    ZStack {
        Color(hex: "#F5F0E8").ignoresSafeArea()
        VStack(spacing: 20) {
            Text("Solo · light · color cycling")
                .font(.caption)
                .foregroundStyle(Color(hex: "#888880"))
            FilamentView(size: 300, mode: .solo, speed: 1.0)
        }
    }
    .preferredColorScheme(.light)
}

#Preview("Light — Duo") {
    ZStack {
        Color(hex: "#F5F0E8").ignoresSafeArea()
        VStack(spacing: 20) {
            Text("Duo · light · cyan + magenta")
                .font(.caption)
                .foregroundStyle(Color(hex: "#888880"))
            FilamentView(size: 300, mode: .duo, speed: 1.0)
        }
    }
    .preferredColorScheme(.light)
}

#Preview("orbitCount 1 / 2 / 3 — no connections") {
    ZStack {
        Color(hex: "#030305").ignoresSafeArea()
        HStack(spacing: 20) {
            VStack(spacing: 6) {
                FilamentView(
                    size:            52,
                    mode:           .solo,
                    speed:           1.0,
                    orbitCount:      1,
                    showConnections: false
                )
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                Text("1")
                    .font(.caption)
                    .foregroundStyle(Color(hex: "#666680"))
            }
            VStack(spacing: 6) {
                FilamentView(
                    size:            52,
                    mode:           .duo,
                    speed:           1.0,
                    orbitCount:      2,
                    showConnections: false
                )
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                Text("2")
                    .font(.caption)
                    .foregroundStyle(Color(hex: "#666680"))
            }
            VStack(spacing: 6) {
                FilamentView(
                    size:            52,
                    mode:           .duo,
                    speed:           1.0,
                    orbitCount:      3,
                    showConnections: false
                )
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                Text("3")
                    .font(.caption)
                    .foregroundStyle(Color(hex: "#666680"))
            }
        }
    }
    .preferredColorScheme(.dark)
}

```

---

## File: `Open Lightly/Design/Components/NavArrow.swift` {#file-open-lightly-design-components-navarrow-swift}

```swift
// NavArrow.swift
// Open Lightly
//
// Pill nav arrow — adaptive dark/light.
// Dark:  pillBorder()       (cyan → purple → magenta) border + arrow
// Light: warmAuroraBorder() border, magenta → orangeHot → gold arrow

import SwiftUI

// MARK: - Enums

enum ArrowDirection {
    case back
    case forward
}

enum OnboardingArrowStyle {
    case aurora
    case magentaGold
}

// MARK: - Size Constants

extension CGSize {
    /// Top nav bar weight — sits beside progress indicator
    static let navArrowTopBar = CGSize(width: 80, height: 44)
    /// Compact nav bar — smaller screens or tighter headers  //
      static let navArrowCompact = CGSize(width: 56, height: 32)
}

// MARK: - Shared Gradients

/// Dark mode — arrow + border: cyan → purple → magenta
private let spectrumGradient = LinearGradient(
    colors: [AppColors.cyan, AppColors.purple, AppColors.magenta],
    startPoint: .topLeading,
    endPoint:   .bottomTrailing
)

/// Light mode — arrow: magenta → orangeHot → gold
private let magentaGoldGradient = LinearGradient(
    stops: [
        .init(color: AppColors.magenta,   location: 0.00),
        .init(color: AppColors.orangeHot, location: 0.55),
        .init(color: AppColors.gold,      location: 1.00),
    ],
    startPoint: .topLeading,
    endPoint:   .bottomTrailing
)

// MARK: - NavArrowShape
// Direct port of the HTML SVG — viewBox 0 0 48 48
//
// Chevron top arm : (22,10) → (10,24)
// Chevron bot arm : (10,24) → (22,38)
// Upper line      : (14,20) → (38,20)
// Lower line      : (14,28) → (38,28)

struct NavArrowShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()

        // ── Chevron top arm: (22,10) → (10,24)
        path.move(to:    CGPoint(x: w * (22/48), y: h * (10/48)))
        path.addLine(to: CGPoint(x: w * (10/48), y: h * (24/48)))

        // ── Chevron bot arm: (10,24) → (22,38)
        path.addLine(to: CGPoint(x: w * (22/48), y: h * (38/48)))

        // ── Upper line: (14,20) → (38,20)
        path.move(to:    CGPoint(x: w * (14/48), y: h * (20/48)))
        path.addLine(to: CGPoint(x: w * (38/48), y: h * (20/48)))

        // ── Lower line: (14,28) → (38,28)
        path.move(to:    CGPoint(x: w * (14/48), y: h * (28/48)))
        path.addLine(to: CGPoint(x: w * (38/48), y: h * (28/48)))

        return path
    }
}

// MARK: - GradientStrokeArrow

struct GradientStrokeArrow: View {
    var gradient:     LinearGradient
    var strokeWidth:  CGFloat = 2.8
    var shadowColor1: Color
    var shadowColor2: Color

    var body: some View {
        NavArrowShape()
            .stroke(
                gradient,
                style: StrokeStyle(
                    lineWidth:  strokeWidth,
                    lineCap:    .round,
                    lineJoin:   .round
                )
            )
            .shadow(color: shadowColor1.opacity(0.55), radius: 5)
            .shadow(color: shadowColor2.opacity(0.30), radius: 10)
    }
}

// MARK: - DarkNavArrow
//
// Parameter order: size → action (enables trailing closure, fixes init ordering)
//
// Pill:  surfaceBg fill at 0.85 opacity + pillBorder() spectrum border
// Arrow: spectrumGradient (cyan → purple → magenta)
// Glow:  blurred border duplicate at 0.50 opacity
// strokeWidth scales proportionally with pill height.

struct DarkNavArrow: View {
    var size:   CGSize = .navArrowCompact  // ← first
    var action: () -> Void                // ← last, enables trailing closure

    // Stroke scales with height — 1.8 at 44pt
    private var strokeWidth: CGFloat {
        (size.height / 44) * 1.8
    }

    var body: some View {
        Button(action: action, label: {
            ZStack {

                // ── Pill fill
                Capsule()
                    .fill(AppColors.surfaceBg.opacity(0.85))
                    .frame(width: size.width, height: size.height)

                // ── Crisp spectrum border via existing modifier
                Capsule()
                    .strokeBorder(Color.clear, lineWidth: 0)
                    .frame(width: size.width, height: size.height)
                    .pillBorder()

                // ── Blurred glow border duplicate
                Capsule()
                    .strokeBorder(spectrumGradient, lineWidth: 4)
                    .blur(radius: 7)
                    .opacity(0.50)
                    .frame(width: size.width, height: size.height)

                // ── Arrow glyph — spectrum, 65% of pill
                GradientStrokeArrow(
                    gradient:     spectrumGradient,
                    strokeWidth:  strokeWidth,
                    shadowColor1: AppColors.cyan,
                    shadowColor2: AppColors.purple
                )
                .frame(
                    width:  size.width  * 0.65,
                    height: size.height * 0.65
                )
            }
            .frame(width: size.width, height: size.height)
            .shadow(color: AppColors.purple.opacity(0.22), radius: 8)
            .shadow(color: AppColors.cyan.opacity(0.12),   radius: 20)
            .shadow(color: AppColors.purple.opacity(0.08), radius: 28)
        })
        .buttonStyle(.plain)
    }
}

// MARK: - LightNavArrow
//
// Parameter order: size → style → action (enables trailing closure, fixes init ordering)
//
// Pill:  lightCardBg fill + warmAuroraBorder() or magentaGoldBorder()
// Arrow: magentaGoldGradient (magenta → orangeHot → gold)
// Glow:  coloured spread shadows
// strokeWidth scales proportionally with pill height.

struct LightNavArrow: View {
    var size:   CGSize               = .navArrowCompact  // ← first
    var style:  OnboardingArrowStyle = .magentaGold     // ← second
    var action: () -> Void                              // ← last, enables trailing closure

    // Stroke scales with height — 2.1 at 44pt
    private var strokeWidth: CGFloat {
        (size.height / 44) * 2.1
    }

    var body: some View {
        Button(action: action, label: {
            ZStack {

                // ── Pill fill
                Capsule()
                    .fill(AppColors.lightCardBg)
                    .frame(width: size.width, height: size.height)

                // ── Border — aurora or magentaGold
                Capsule()
                    .strokeBorder(Color.clear, lineWidth: 0)
                    .frame(width: size.width, height: size.height)
                    .modifier(LightBorderModifier(style: style))

                // ── Arrow glyph — magenta gold, 65% of pill
                GradientStrokeArrow(
                    gradient:     magentaGoldGradient,
                    strokeWidth:  strokeWidth,
                    shadowColor1: AppColors.magenta,
                    shadowColor2: AppColors.orangeHot
                )
                .frame(
                    width:  size.width  * 0.65,
                    height: size.height * 0.65
                )
            }
            .frame(width: size.width, height: size.height)
            .shadow(color: AppColors.lightShadowMagenta.opacity(0.35), radius: 10, x: 0, y: 4)
            .shadow(color: AppColors.lightShadowPurple.opacity(0.22),  radius: 20, x: 0, y: 6)
            .shadow(color: AppColors.lightShadowGold.opacity(0.18),    radius: 8,  x: 0, y: 2)
        })
        .buttonStyle(.plain)
    }
}

// MARK: - LightBorderModifier

private struct LightBorderModifier: ViewModifier {
    let style: OnboardingArrowStyle

    func body(content: Content) -> some View {
        switch style {
        case .aurora:
            content.warmAuroraBorder()
        case .magentaGold:
            content.magentaGoldBorder()
        }
    }
}

// MARK: - OnboardingNavArrow (Adaptive Wrapper)

/// Single drop-in component for all onboarding back/forward navigation.
/// Reads colorScheme automatically.
/// Mirrors horizontally for forward direction.
///
/// Usage (ModeSelectView and all onboarding screens):
///   OnboardingNavArrow(direction: .back)    { goBack() }
///   OnboardingNavArrow(direction: .forward) { goNext() }

struct OnboardingNavArrow: View {
    var direction: ArrowDirection                          // ← first
    var size:      CGSize               = .navArrowTopBar // ← second
    var style:     OnboardingArrowStyle = .magentaGold    // ← third, light mode only
    var action:    () -> Void                             // ← last, enables trailing closure

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            if colorScheme == .dark {
                DarkNavArrow(size: size, action: action)
            } else {
                LightNavArrow(size: size, style: style, action: action)
            }
        }
        .scaleEffect(x: direction == .forward ? -1 : 1)
        .accessibilityLabel(direction == .back ? "Go back" : "Continue")
    }
}

// MARK: - Previews

#Preview("NavArrow Dark") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        HStack(spacing: 24) {
            OnboardingNavArrow(direction: .back)    { }
            OnboardingNavArrow(direction: .forward) { }
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("NavArrow Light") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        HStack(spacing: 24) {
            OnboardingNavArrow(direction: .back)    { }
            OnboardingNavArrow(direction: .forward) { }
        }
    }
    .preferredColorScheme(.light)
}

```

---

## File: `Open Lightly/Design/Components/OrbitSparkBorderView.swift` {#file-open-lightly-design-components-orbitsparkborderview-swift}

```swift
//
//  OrbitSparkBorderView.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/24/26.
//


//
//  OrbitSparkBorderView.swift
//  Open Lightly
//

import SwiftUI

struct OrbitSparkBorderView: View {

    let size:         CGSize
    let cornerRadius: CGFloat
    let borderWidth:  CGFloat
    let colorScheme:  ColorScheme

    @State private var startDate = Date()

    private var borderGradient: LinearGradient {
        colorScheme == .dark
            ? LinearGradient(
                colors: [AppColors.cyan, AppColors.purple, AppColors.magenta],
                startPoint: .leading,
                endPoint: .trailing
              )
            : AppColors.warmAuroraBorder   // purple → magenta → gold
    }

    // NEW: tells the Metal shader which palette to use
    private var colorMode: Float {
        colorScheme == .dark ? 0.0 : 1.0
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            let elapsed = timeline.date.timeIntervalSince(startDate)

            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(borderGradient, lineWidth: borderWidth)
                .colorEffect(
                    ShaderLibrary.orbitSpark(
                        .float2(size),
                        .float(elapsed),
                        .float(Float(borderWidth)),
                        .float(Float(cornerRadius)),
                        .float(colorMode)    // NEW argument
                    )
                )
                .frame(width: size.width, height: size.height)
        }
    }
}

```

---

## File: `Open Lightly/Design/Components/PillBorder.swift` {#file-open-lightly-design-components-pillborder-swift}

```swift
import SwiftUI

// ─────────────────────────────────────────────
// MARK: Dark Mode — Spectrum Pill Border
// Unchanged. Used on all dark mode selected/active states.
// cyan → purple → magenta, topLeading → bottomTrailing
// ─────────────────────────────────────────────

/// Shared holographic pill border — single source of truth.
struct PillBorder: ViewModifier {
    var cornerRadius: CGFloat = 100
    var lineWidth: CGFloat = 3
    var glowRadius: CGFloat = 6
    var opacity: Double = 0.8

    func body(content: Content) -> some View {
        let gradient = LinearGradient(
            colors: [AppColors.cyan, AppColors.purple, AppColors.magenta],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        return content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(gradient, lineWidth: lineWidth)
                    .opacity(opacity)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(gradient, lineWidth: lineWidth + 1)
                    .blur(radius: glowRadius)
                    .opacity(0.35)
            )
            .shadow(color: AppColors.purple.opacity(0.18), radius: 6)
            .shadow(color: AppColors.cyan.opacity(0.08),   radius: 12)
            .shadow(color: AppColors.purple.opacity(0.06), radius: 16)
    }
}

extension View {
    func pillBorder(
        cornerRadius: CGFloat = 100,
        lineWidth: CGFloat = 3,
        glowRadius: CGFloat = 6,
        opacity: Double = 0.8
    ) -> some View {
        modifier(PillBorder(
            cornerRadius: cornerRadius,
            lineWidth: lineWidth,
            glowRadius: glowRadius,
            opacity: opacity
        ))
    }
}

// ─────────────────────────────────────────────
// MARK: Light Mode — Warm Aurora Border
//
// Used on ALL light mode selected/active states.
// Replaces .pillBorder() when colorScheme == .light.
//
// Gradient: AppColors.warmAuroraBorder
//   purple → magenta → gold, topLeading → bottomTrailing
//
// Key differences from dark PillBorder:
//   - No blur overlay — blur is invisible on cream, adds muddiness
//   - Shadows replaced with colored spread (shadow IS the glow on light)
//   - Default lineWidth 2.5 vs 3 — slightly finer on cream reads better
//   - Default opacity 0.82 — higher than dark because no glow canvas to boost it
//
// Usage:
//   .warmAuroraBorder()                         // pills, fields, cards
//   .warmAuroraBorder(cornerRadius: 20)         // rounded rect cards
//   .warmAuroraBorder(lineWidth: 3, opacity: 0.95) // CTA buttons
// ─────────────────────────────────────────────

struct WarmAuroraBorder: ViewModifier {
    var cornerRadius: CGFloat = 100
    var lineWidth: CGFloat    = 2.5
    var opacity: Double       = 0.82

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(AppColors.warmAuroraBorder, lineWidth: lineWidth)
                    .opacity(opacity)
            )
            .shadow(color: AppColors.lightShadowMagenta, radius: 8,  x: 0, y: 3)
            .shadow(color: AppColors.lightShadowPurple,  radius: 16, x: 0, y: 5)
            .shadow(color: AppColors.lightShadowGold,    radius: 6,  x: 0, y: 2)
    }
}

extension View {
    func warmAuroraBorder(
        cornerRadius: CGFloat = 100,
        lineWidth: CGFloat    = 2.5,
        opacity: Double       = 0.82
    ) -> some View {
        modifier(WarmAuroraBorder(
            cornerRadius: cornerRadius,
            lineWidth: lineWidth,
            opacity: opacity
        ))
    }
}

// ─────────────────────────────────────────────
// MARK: Light Mode — Magenta Gold Border
//
// Used on light mode pill selected states and LivingText
// contexts where the magentaGold palette is active.
//
// Gradient: magenta → orangeHot → gold
//   #FF006A 0% → #E07020 55% → #C8960A 100%
//   topLeading → bottomTrailing
//
// The 0.55 mid-stop extends the hot pink longer before
// amber arrives — mirrors the VQ-08 principle from the
// progress bar fill gradient.
//
// Glow pattern mirrors PillBorder exactly:
//   - Crisp stroke overlay at `opacity`
//   - Blurred duplicate at lineWidth+1, blur glowRadius, opacity 0.35
//     (same structure as dark PillBorder blur overlay)
//   - Three shadow spread layers: magenta tight, orangeHot mid, gold wide
//
// Usage:
//   .magentaGoldBorder()                          // pills — default
//   .magentaGoldBorder(cornerRadius: 20)          // rounded rect cards
//   .magentaGoldBorder(lineWidth: 3, opacity: 0.90) // CTA weight
// ─────────────────────────────────────────────

private let magentaGoldGradient = LinearGradient(
    stops: [
        .init(color: AppColors.magenta,    location: 0.00),
        .init(color: AppColors.orangeHot,  location: 0.55), // VQ-08: extended pink zone
        .init(color: AppColors.gold,       location: 1.00),
    ],
    startPoint: .topLeading,
    endPoint:   .bottomTrailing
)

struct MagentaGoldBorder: ViewModifier {
    var cornerRadius: CGFloat = 100
    var lineWidth: CGFloat    = 2.5
    var glowRadius: CGFloat   = 6
    var opacity: Double       = 0.82

    func body(content: Content) -> some View {
        content
            // Crisp gradient stroke
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(magentaGoldGradient, lineWidth: lineWidth)
                    .opacity(opacity)
            )
            // Blurred duplicate — mirrors PillBorder glow overlay pattern.
            // Visible on cream because the gradient is warm and saturated.
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(magentaGoldGradient, lineWidth: lineWidth + 1)
                    .blur(radius: glowRadius)
                    .opacity(0.35)
            )
            // Shadow spread — three layers, same pattern as WarmAuroraBorder.
            // Magenta: tight warm halo. OrangeHot: mid warmth. Gold: wide soft glow.
            .shadow(color: AppColors.magenta.opacity(0.18),   radius: 8,  x: 0, y: 3)
            .shadow(color: AppColors.orangeHot.opacity(0.12), radius: 16, x: 0, y: 5)
            .shadow(color: AppColors.gold.opacity(0.08),      radius: 6,  x: 0, y: 2)
    }
}

extension View {
    /// Light mode magenta → amber → gold border.
    /// Use on pill selected states that pair with the magentaGold
    /// LivingText palette, and anywhere the warm ember identity
    /// is stronger than the purple aurora identity.
    ///
    /// - Parameters:
    ///   - cornerRadius: Match the shape. Default 100 (pill).
    ///   - lineWidth: Default 2.5. Use 3.0 for CTA weight.
    ///   - glowRadius: Default 6. Blur radius of the glow duplicate overlay.
    ///   - opacity: Default 0.82. Use 0.90 for CTA. Use 0.65 for resting borders.
    func magentaGoldBorder(
        cornerRadius: CGFloat = 100,
        lineWidth: CGFloat    = 2.5,
        glowRadius: CGFloat   = 6,
        opacity: Double       = 0.82
    ) -> some View {
        modifier(MagentaGoldBorder(
            cornerRadius: cornerRadius,
            lineWidth: lineWidth,
            glowRadius: glowRadius,
            opacity: opacity
        ))
    }
}

```

---

## File: `Open Lightly/Design/Components/ScreenshotProtectionModifier.swift` {#file-open-lightly-design-components-screenshotprotectionmodifier-swift}

```swift
// ✅ Design system audit — verified March 9, 2026
import SwiftUI
import UIKit

// MARK: - ScreenshotProtectionModifier
struct ScreenshotProtectionModifier: ViewModifier {
    @State private var isObscured = false
    
    func body(content: Content) -> some View {
        content
            .overlay {
                if isObscured {
                    ZStack {
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .ignoresSafeArea()
                        VStack(spacing: 12) {
                            Image(systemName: "eye.slash.fill")
                                .font(.largeTitle)
                                .foregroundStyle(AppColors.gold)
                            Text("Content Protected")
                                .font(AppFonts.sectionHeading)
                                .foregroundStyle(AppColors.textPrimary)
                            Text("This content is private and cannot be captured.")
                                .font(AppFonts.caption)
                                .foregroundStyle(AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(40)
                    }
                    .transition(.opacity.animation(.easeIn(duration: 0.15)))
                }
            }
            .onAppear { checkCaptureStatus() }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.userDidTakeScreenshotNotification)) { _ in
                flashObscure()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIScreen.capturedDidChangeNotification)) { _ in
                checkCaptureStatus()
            }
    }
    
    private func checkCaptureStatus() {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first else { return }
        isObscured = windowScene.screen.isCaptured
    }
    
    private func flashObscure() {
        isObscured = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            checkCaptureStatus()
        }
    }
}

// MARK: - View Extension
extension View {
    func screenshotProtected() -> some View {
        modifier(ScreenshotProtectionModifier())
    }
}

```

---

## File: `Open Lightly/Design/Components/SectionHeader.swift` {#file-open-lightly-design-components-sectionheader-swift}

```swift
import SwiftUI

/// All-caps muted label used above sections in Settings, Home, and list screens.
/// Usage: `SectionHeader("PROFILE")`
struct SectionHeader: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(AppFonts.sectionHeader)
            .foregroundColor(AppColors.textMuted)
    }
}

```

---

## File: `Open Lightly/Design/Components/OrbitSpark.metal` {#file-open-lightly-design-components-orbitspark-metal}

```metal
//
//  OrbitSpark.metal
//  Open Lightly
//

#include <metal_stdlib>
using namespace metal;

[[ stitchable ]] half4 orbitSpark(
    float2 position,
    half4 currentColor,
    float2 size,
    float time,
    float borderWidth,
    float cornerRadius,
    float colorMode     // 0.0 = dark, 1.0 = light
) {
    float2 center = size * 0.5;
    float2 p = position - center;

    float2 d = abs(p) - (center - cornerRadius);
    float dist = length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - cornerRadius;

    float borderMask = 1.0 - smoothstep(0.0, 1.5, abs(dist) - borderWidth * 0.5);

    float angle = atan2(p.y, p.x);

    float orbitSpeed = 0.45;
    float orbitAngle = fmod(time * orbitSpeed * 2.0 * M_PI_F, 2.0 * M_PI_F) - M_PI_F;

    float angleDiff = angle - orbitAngle;
    angleDiff = angleDiff - 2.0 * M_PI_F * round(angleDiff / (2.0 * M_PI_F));

    float sparkWidth = 0.7;
    float spark = smoothstep(sparkWidth, 0.0, abs(angleDiff));
    spark = pow(spark, 2.0);

    float t = clamp(angleDiff / sparkWidth + 0.5, 0.0, 1.0);

    // Dark mode colors
    half3 darkA = half3(0.0,  0.76, 1.0);   // cyan    #00C2FF
    half3 darkB = half3(0.42, 0.23, 0.88);  // purple  #6C3AE0
    half3 darkC = half3(1.0,  0.0,  0.42);  // magenta #FF006A

    // Light mode colors (warm aurora)
    half3 lightA = half3(0.42, 0.23, 0.88);  // purple  #6C3AE0
    half3 lightB = half3(1.0,  0.0,  0.42);  // magenta #FF006A
    half3 lightC = half3(0.78, 0.59, 0.04);  // gold    #C8960A

    half3 colorA = mix(darkA, lightA, half(colorMode));
    half3 colorB = mix(darkB, lightB, half(colorMode));
    half3 colorC = mix(darkC, lightC, half(colorMode));

    half3 sparkColor = mix(colorA, colorB, half(t));
    sparkColor = mix(sparkColor, colorC, half(t * t));

    // Hot white core — stays white in both modes
    float core = smoothstep(0.15, 0.0, abs(angleDiff));
    sparkColor = mix(sparkColor, half3(1.0), half(core * 0.5));

    float alpha = spark * borderMask;

    return currentColor + half4(sparkColor * half(alpha), half(alpha));
}

```

---

