# LLM Context — Open Lightly · Foundation

> **Scope: App entry, routing, state, enums, and the full theme system.**
> This is the irreducible core. Every other context bundle includes these files.
>
> Load this bundle when working on:
> - App-wide routing or ExperienceType logic
> - Theme system changes (colors, fonts, palette, modes)
> - Any question that spans multiple features
>
> FILE_TRACKER revision: 2026-03-30
> Generated: 2026-03-30 15:40:52 PDT

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

