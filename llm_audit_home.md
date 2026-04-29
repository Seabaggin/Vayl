# LLM Audit Context — Open Lightly · Home Screen

> **Scope: Home tab — routing, state, dashboard, home-specific components, nav shell, theme tokens.**
>
> What's intentionally excluded to keep context tight:
>   - Pulse / Learn / Explore / Onboarding features
>   - Global design system (Buttons, Cards, Banners)
>   - Services, Auth, Supabase layer
>   - AppTheme / ThemeManager / ThemeModifiers
>
> File map:
>   ContentView        — auth gate, injects AppState + theme
>   AppState           — experience-type routing (solo/coupled/NM)
>   HomeRouterView     — decides which home variant to render
>   HomeStates         — enums + structs driving conditional UI
>   HomeDashboardView  — top-level home composition
>   Home Components    — PickUpCard, ReflectionCard, Banner, Chip, etc.
>   Nav Shell          — RacetrackTabBar, TabContentWrapper
>   Theme Tokens       — AppColors, AppFonts
>
> Generated: 2026-04-11 14:45:31 PDT

---

## Table of Contents

  1. [`Open Lightly/App/ContentView.swift`](#file-open-lightly-app-contentview-swift)
  2. [`Open Lightly/Core/Services/AppState.swift`](#file-open-lightly-core-services-appstate-swift)
  3. [`Open Lightly/Features/Home/HomeRouterView.swift`](#file-open-lightly-features-home-homerouterview-swift)
  4. [`Open Lightly/Features/Home/HomeStates.swift`](#file-open-lightly-features-home-homestates-swift)
  5. [`Open Lightly/Features/Home/HomeDashboardView.swift`](#file-open-lightly-features-home-homedashboardview-swift)
  6. [`Open Lightly/Features/Home/Components/PickUpCard.swift`](#file-open-lightly-features-home-components-pickupcard-swift)
  7. [`Open Lightly/Features/Home/Components/ReflectionCard.swift`](#file-open-lightly-features-home-components-reflectioncard-swift)
  8. [`Open Lightly/Features/Home/Components/ReflectionBannerView.swift`](#file-open-lightly-features-home-components-reflectionbannerview-swift)
  9. [`Open Lightly/Features/Home/Components/PartnerChip.swift`](#file-open-lightly-features-home-components-partnerchip-swift)
  10. [`Open Lightly/Features/Home/Components/DesireMapIndicator.swift`](#file-open-lightly-features-home-components-desiremapindicator-swift)
  11. [`Open Lightly/Features/Home/Components/ResearchTicker.swift`](#file-open-lightly-features-home-components-researchticker-swift)
  12. [`Open Lightly/Features/Home/Components/PostMapReflectionView.swift`](#file-open-lightly-features-home-components-postmapreflectionview-swift)
  13. [`Open Lightly/Design/Components/Navigation/RacetrackTabBar.swift`](#file-open-lightly-design-components-navigation-racetracktabbar-swift)
  14. [`Open Lightly/Design/Components/Navigation/TabContentWrapper.swift`](#file-open-lightly-design-components-navigation-tabcontentwrapper-swift)
  15. [`Open Lightly/App/Theme/AppColors.swift`](#file-open-lightly-app-theme-appcolors-swift)
  16. [`Open Lightly/App/Theme/AppFonts.swift`](#file-open-lightly-app-theme-appfonts-swift)

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
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    
    // ADD this just below the hasCompletedOnboarding @AppStorage line:
#if DEBUG
    private let forceOnboarding = false   // ← set false to test main app
#else
    private let forceOnboarding = false
#endif
    
    // ── Experience routing ───────────────────────────────────────────────
    @Environment(AppState.self) private var appState
    
    // ── Tab selection ────────────────────────────────────────────────────
    
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
            guestShell
        } else {
            AppShell()
        }
    }
    
    // MARK: - Guest Shell
    
    private var guestShell: some View {
        VStack(spacing: 0) {
            GuestBannerView()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.pageBg.ignoresSafeArea())
        .preferredColorScheme(.dark)
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

    var displayName: String {
        didSet {
            persist(displayName, forKey: .displayName)
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

        self.displayName = UserDefaults.standard.string(
            forKey: PersistenceKey.displayName.rawValue
        ) ?? ""
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
        case experienceType     = "experienceType"
        case onboardingComplete = "isOnboardingComplete"
        case displayName        = "displayName"
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

## File: `Open Lightly/Features/Home/HomeRouterView.swift` {#file-open-lightly-features-home-homerouterview-swift}

```swift
// HomeRouterView.swift
// Open Lightly

import SwiftUI

enum HomeState: Equatable {
    case gated
    case postReflection
    case waiting
    case matchReady
    case dashboard
}

struct HomeRouterView: View {

    @Environment(\.colorScheme) private var colorScheme
    @Environment(AppState.self) private var appState

    // ── Real state — placeholder bools until SwiftData models exist ──────
    // These will become @Bindable SwiftData model reads in a future batch.
    // Kept as @State for now so the router compiles and all states are
    // reachable for testing via the debug controls below.
    // AFTER
    #if DEBUG
    @State private var myMapComplete:      Bool    = true
    @State private var partnerMapComplete: Bool    = true
    @State private var partnerName:        String? = "Alex"
    @State private var revealDone:         Bool    = true
    @State private var postReflectionDone: Bool    = true
    #else
    @State private var myMapComplete:      Bool    = false
    @State private var partnerMapComplete: Bool    = false
    @State private var partnerName:        String? = nil
    @State private var revealDone:         Bool    = false
    @State private var postReflectionDone: Bool    = false
    #endif
    @State private var reflectionStep: Int = 1

    // ── Derived from AppState ────────────────────────────────────────────
    private var isPaired: Bool {
        appState.experienceType == .coupleNew
        || appState.experienceType == .coupleExperienced
    }

    private var isSolo: Bool {
        appState.experienceType == .soloSingle
        || appState.experienceType == .soloPartnered
    }

    // ── Single computed property drives all routing ──────────────────────
    private var homeState: HomeState {
        guard myMapComplete else                        { return .gated }
        guard postReflectionDone else                   { return .postReflection }
        // Temporarily bypass isPaired check for testing
        guard partnerMapComplete else                   { return .waiting }
        guard revealDone else                           { return .matchReady }
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
                    partnerName: "your partner",
                    onInvite: { /* open share sheet */ }
                )
                .transition(.opacity)

            case .matchReady:
                HomeMatchReadyView(
                    onReveal: { /* route to reveal / paywall */ }
                )
                .transition(.opacity)

            case .dashboard:
                HomeDashboardView(
                    displayName:         appState.displayName,
                    partnerChipState:    isPaired ? .invitePending : .none,
                    cards:               Prompt.samples,
                    desireMapState:      .hidden,
                    reflectionCardState: .hidden,
                    pickUpItems:         [],
                    stageIndex:          1,
                    cardsCompleted:      0,
                    recentEvents:        [],
                    isSolo:              isSolo
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: homeState)

        #if DEBUG
        // ── Debug overlay — lets you walk through all home states
        // in the preview canvas without touching real data
        .overlay(alignment: .bottomTrailing) {
            debugControls
        }
        #endif
    }

    // MARK: - Tab Lock Helper

    static func isTabLocked(_ tab: AppTab, homeState: HomeState) -> Bool {
        switch homeState {
        case .dashboard:
            return false
        default:
            return tab == .play || tab == .map
        }
    }

    // MARK: - Debug Controls

    #if DEBUG
    private var debugControls: some View {
        VStack(alignment: .trailing, spacing: 6) {
            Text("HomeState: \(String(describing: homeState))")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(AppColors.textTertiary)

            Button(myMapComplete ? "Map ✓" : "Map ✗") {
                myMapComplete.toggle()
            }
            Button(postReflectionDone ? "Reflected ✓" : "Reflected ✗") {
                postReflectionDone.toggle()
            }
            Button(partnerMapComplete ? "Partner ✓" : "Partner ✗") {
                partnerMapComplete.toggle()
            }
            Button(revealDone ? "Reveal ✓" : "Reveal ✗") {
                revealDone.toggle()
            }
        }
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(AppColors.cyan)
        .padding(12)
        .background(AppColors.cardBg.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.trailing, 16)
        .padding(.bottom, 100)
    }
    #endif
}

```

---

## File: `Open Lightly/Features/Home/HomeStates.swift` {#file-open-lightly-features-home-homestates-swift}

```swift
//
//  HomeStates.swift
//  Open Lightly
//
//  Consolidated home state views — Gate, Waiting, and MatchReady.
//  Each struct represents a distinct navigation state in the HomeRouterView.
//

import SwiftUI

// MARK: - HomeGateView

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

    // ...existing code...
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
            Text(parseInlineBold(text))
                .font(AppFonts.bodyText)
                .foregroundStyle(colorScheme == .light
                    ? AppColors.lightTextPrimary
                    : AppColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
        }
    }

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

// MARK: - HomeWaitingView

struct HomeWaitingView: View {
    let isPaired: Bool
    let partnerName: String
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

    // ...existing code...
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

// MARK: - HomeMatchReadyView

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

    // ...existing code...
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

```

---

## File: `Open Lightly/Features/Home/HomeDashboardView.swift` {#file-open-lightly-features-home-homedashboardview-swift}

```swift
// HomeDashboardView.swift
// Open Lightly

import SwiftUI

struct HomeDashboardView: View {

    // MARK: - Injected Properties

    var displayName: String = "Jordan"
    var partnerChipState: PartnerChipState = .none
    var cards: [Prompt] = Prompt.samples
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

    var onRemindPartner: (() -> Void)? = nil
    var onCardAction: ((Prompt, CardAction) -> Void)? = nil
    var onDesireMapReveal: (() -> Void)? = nil
    var onDesireMapUnlock: (() -> Void)? = nil
    var onReflectionDone: (([String], String?, Bool) -> Void)? = nil
    var onReflectionBannerDismiss: (() -> Void)? = nil
    var onMoreTap: (() -> Void)? = nil
    var onPickUpItemTap: ((PickUpItem) -> Void)? = nil
    var onInvitePartner: (() -> Void)? = nil

    // MARK: - Environment + State

    @Environment(\.colorScheme) private var colorScheme

    @State private var greetingVisible   = false
    @State private var sessionVisible    = false
    @State private var desireMapVisible  = false
    @State private var reflectionVisible = false
    @State private var pickUpVisible     = false
    @State private var tickerVisible     = false
    @State private var hasAnimated       = false
    @State private var isGraphActive     = false

    // MARK: - Body

    var body: some View {
        ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    Spacer(minLength: 16)

                    // ── Greeting ──────────────────────────────
                    greetingBlock
                        .padding(.horizontal, 24)
                        .opacity(greetingVisible ? 1 : 0)
                        .offset(y: greetingVisible ? 0 : 12)
                        .animation(.easeOut(duration: 0.5),
                                   value: greetingVisible)

                    Spacer(minLength: 16)

                    // ── Card Carousel ─────────────────────────
                    CardCarousel(
                        cards: cards,
                        onCardAction: onCardAction
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, -10)
                    .opacity(sessionVisible ? 1 : 0)
                    .offset(y: sessionVisible ? 0 : 16)
                    .animation(.easeOut(duration: 0.5),
                               value: sessionVisible)

                    // ── Desire Map Indicator ──────────────────
                    if desireMapState != .hidden
                        && desireMapState != .fullyUnlocked {

                        Spacer(minLength: 14)

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

                        Spacer(minLength: 14)

                        ReflectionCard(
                            state: reflectionCardState,
                            onMoreTap: onMoreTap,
                            onDone: { pills, note in
                                onReflectionDone?(pills, note, true)
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

                        Spacer(minLength: 14)

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

                    // ── Pulse Widget ──────────────────────────
                    Spacer(minLength: 14)

                    PulseWidget(isGraphActive: $isGraphActive)
                        .padding(.horizontal, 20)
                    // ── Research Ticker ───────────────────────
                    Spacer(minLength: 20)

                    ResearchTicker()
                        .opacity(tickerVisible ? 1 : 0)
                        .animation(.easeOut(duration: 0.6),
                                   value: tickerVisible)

                    Spacer(minLength: 120)
                }
            }
            .background {
                backgroundLayer
                    .ignoresSafeArea()
            }
            .scrollDisabled(isGraphActive)
            .simultaneousGesture(
                DragGesture(minimumDistance: 10)
            )
            .overlay {
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
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal:   .move(edge: .top).combined(with: .opacity)
                        )
                    )
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.8),
                        value: showReflectionBanner
                    )
                }
            }
            .onAppear {
                guard !hasAnimated else { return }
                hasAnimated = true
                runEntranceAnimations()
            }
    }

    // MARK: - Greeting Block

    private var greetingBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(greetingSalutation)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(
                            colorScheme == .light
                                ? AppColors.lightTextSecondary
                                : AppColors.textSecondary
                        )

                    if !displayName.isEmpty {
                        Text("\(displayName).")
                            .font(.system(size: 28, weight: .bold))
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

                PartnerChip(
                    state: partnerChipState,
                    onInviteTap: onInvitePartner
                )
                .padding(.top, 4)
            }

            Text(eventOneLiner)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(
                    colorScheme == .light
                        ? AppColors.lightTextSecondary
                        : AppColors.textSecondary
                )
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

   private var backgroundLayer: some View {
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
                        center:      .top,
                        startRadius: 30,
                        endRadius:   380
                    ))
                    .frame(width: 600, height: 400)
                    .blur(radius: 80)
            }

            if colorScheme == .light {
                AuroraGlowField()
            } else {
                OnboardingGlowField()
            }
        }
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

// MARK: - Equatable helpers

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

extension ReflectionCardState: Equatable {
    static func == (lhs: ReflectionCardState,
                    rhs: ReflectionCardState) -> Bool {
        switch (lhs, rhs) {
        case (.hidden, .hidden): return true
        default:                 return false
        }
    }
}

// MARK: - Previews

#Preview("Dark — Day Zero, Solo") {
    HomeDashboardView(
        displayName:         "Jordan",
        partnerChipState:    .none,
        cards:               Prompt.samples,
        desireMapState:      .hidden,
        reflectionCardState: .hidden,
        pickUpItems:         [],
        stageIndex:          1,
        cardsCompleted:      0,
        recentEvents:        [],
        isSolo:              true
    )
    .environmentObject(PulseStore())
    .preferredColorScheme(.dark)
}

#Preview("Dark — Day Zero, Invite Pending") {
    HomeDashboardView(
        displayName:         "Jordan",
        partnerChipState:    .invitePending,
        cards:               Prompt.samples,
        desireMapState:      .youDone(partnerName: "Alex"),
        reflectionCardState: .hidden,
        pickUpItems:         [],
        stageIndex:          1,
        cardsCompleted:      0,
        recentEvents:        []
    )
    .environmentObject(PulseStore())
    .preferredColorScheme(.dark)
}

#Preview("Dark — Mid Deck, Both Map Ready") {
    HomeDashboardView(
        displayName:         "Jordan",
        partnerChipState:    .active(name: "Alex", initial: "A"),
        cards:               Prompt.samples,
        desireMapState:      .bothReady,
        reflectionCardState: .pendingYours(
            sessionLabel: "Stage 1 · Session 1",
            sessionDate:  Date().addingTimeInterval(-172800)
        ),
        pickUpItems:         [],
        stageIndex:          1,
        cardsCompleted:      5,
        recentEvents:        [
            .partnerCompletedDesireMap(partnerName: "Alex")
        ]
    )
    .environmentObject(PulseStore())
    .preferredColorScheme(.dark)
}

#Preview("Dark — Both Reflected, Summary") {
    HomeDashboardView(
        displayName:         "Jordan",
        partnerChipState:    .active(name: "Alex", initial: "A"),
        cards:               Prompt.samples,
        desireMapState:      .hidden,
        reflectionCardState: .summary(
            arc:           "You've moved from something heavy surfacing to feeling connected twice running.",
            yourName:      "Jordan",
            yourDots:      [true, true, true],
            partnerName:   "Alex",
            partnerDots:   [true, true, false],
            swipePosition: 2
        ),
        pickUpItems:         [
            PickUpItem(
                contentType: .timelineScenario(
                    branchCurrent: 2, branchTotal: 4),
                title:       "Alex is home. Sam has been quiet.",
                contextLine: "You're at branch point 2 of 4",
                actionLabel: "Continue →"
            )
        ],
        stageIndex:          1,
        cardsCompleted:      8,
        recentEvents:        []
    )
    .environmentObject(PulseStore())
    .preferredColorScheme(.dark)
}

#Preview("Dark — Deck Complete") {
    HomeDashboardView(
        displayName:         "Jordan",
        partnerChipState:    .active(name: "Alex", initial: "A"),
        cards:               Prompt.samples,
        desireMapState:      .freeRevealSeen(partnerName: "Alex"),
        reflectionCardState: .bothReflected(
            sessionLabel: "Stage 1 · Session 4",
            yourName:     "Jordan",
            yourPills:    ["Connected", "Surprised"],
            yourNote:     "Didn't expect to feel that settled.",
            partnerName:  "Alex",
            partnerPills: ["Heavy", "Want to talk more"],
            partnerNote:  nil,
            swipePosition: 0
        ),
        pickUpItems:         [],
        stageIndex:          1,
        cardsCompleted:      12,
        recentEvents:        [.stageCompleted(stageName: "Curiosity")]
    )
    .environmentObject(PulseStore())
    .preferredColorScheme(.dark)
}

#Preview("Dark — Waiting on Partner") {
    HomeDashboardView(
        displayName:         "Jordan",
        partnerChipState:    .active(name: "Alex", initial: "A"),
        cards:               Prompt.samples,
        desireMapState:      .hidden,
        reflectionCardState: .hidden,
        pickUpItems:         [],
        stageIndex:          1,
        cardsCompleted:      5,
        recentEvents:        [.daysSinceSession(3, partnerName: "Alex")]
    )
    .environmentObject(PulseStore())
    .preferredColorScheme(.dark)
}

#Preview("Dark — Reflection Banner") {
    HomeDashboardView(
        displayName:          "Jordan",
        partnerChipState:     .active(name: "Alex", initial: "A"),
        cards:                Prompt.samples,
        desireMapState:       .hidden,
        reflectionCardState:  .hidden,
        pickUpItems:          [],
        stageIndex:           1,
        cardsCompleted:       3,
        recentEvents:         [],
        showReflectionBanner: true
    )
    .environmentObject(PulseStore())
    .preferredColorScheme(.dark)
}

#Preview("Light — Day Zero") {
    HomeDashboardView(
        displayName:         "Jordan",
        partnerChipState:    .invitePending,
        cards:               Prompt.samples,
        desireMapState:      .hidden,
        reflectionCardState: .hidden,
        pickUpItems:         [],
        stageIndex:          1,
        cardsCompleted:      0,
        recentEvents:        []
    )
    .environmentObject(PulseStore())
    .preferredColorScheme(.light)
}

#Preview("Dark — No Name") {
    HomeDashboardView(
        displayName:         "",
        partnerChipState:    .none,
        cards:               Prompt.samples,
        desireMapState:      .hidden,
        reflectionCardState: .hidden,
        pickUpItems:         [],
        stageIndex:          1,
        cardsCompleted:      0,
        recentEvents:        [],
        isSolo:              true
    )
    .environmentObject(PulseStore())
    .preferredColorScheme(.dark)
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

## File: `Open Lightly/Features/Home/Components/PostMapReflectionView.swift` {#file-open-lightly-features-home-components-postmapreflectionview-swift}

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

## File: `Open Lightly/Design/Components/Navigation/RacetrackTabBar.swift` {#file-open-lightly-design-components-navigation-racetracktabbar-swift}

```swift
// Design/Components/Navigation/RacetrackTabBar.swift
// Open Lightly

import SwiftUI

// MARK: - RacetrackTabBar

struct RacetrackTabBar: View {

    @Binding var selection: AppTab
    @Environment(\.colorScheme) private var colorScheme

    // ── Animation state — lifted up so bar coordinates the sequence ──────
    // Keyed by tab. Bar owns all trimEnd values so it can sequence
    // reverse (old) → forward (new) without the pills fighting each other.
    @State private var trimValues: [AppTab: CGFloat] = {
        var d = [AppTab: CGFloat]()
        AppTab.allCases.forEach { d[$0] = 0 }
        return d
    }()

    // Which tab is currently mid-animation — prevents interruption
    @State private var isAnimating: Bool = false

  var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                RacetrackTabPill(
                    tab:        tab,
                    isSelected: selection == tab,
                    trimEnd:    trimValues[tab] ?? 0
                ) {
                    guard selection != tab, !isAnimating else { return }
                    let previous = selection
                    selection = tab
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    runSequence(from: previous, to: tab)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(barBackground)
        .padding(.horizontal, 30)
        .onAppear {
            trimValues[selection] = 1.0
        }
    }

    // MARK: - Sequential animation
    
    private func runSequence(from old: AppTab, to new: AppTab) {
        let undoDuration = 0.35
        let drawDuration = 0.35
        
        // 🛠️ FIX: Instead of waiting the full 0.32s, we only wait 0.1s.
        // This means the new circle starts drawing while the old one is still erasing!
        let handoffDelay = 0.10

        isAnimating = true

        // 1. Reverse old
        withAnimation(.linear(duration: undoDuration)) {
            trimValues[old] = 0
        }

        // 2. Start the new draw ALMOST immediately, overlapping the animations
        DispatchQueue.main.asyncAfter(deadline: .now() + handoffDelay) {
            trimValues[new] = 0
            
            withAnimation(.linear(duration: drawDuration)) {
                trimValues[new] = 1.0
            }
            
            // 3. Unlock interactions once the draw is complete
            DispatchQueue.main.asyncAfter(deadline: .now() + drawDuration) {
                isAnimating = false
            }
        }
    }

    // MARK: - Bar background

  private var barBackground: some View {
        ZStack {
            // Base fill
            Capsule()
                .fill(
                    colorScheme == .light
                        ? AnyShapeStyle(AppColors.lightFrostCard)
                        : AnyShapeStyle(AppColors.surfaceBg.opacity(0.97))
                )

            // Shimmer — more opaque so it reads on the bar
            if colorScheme == .light {
                LightModeShimmer(duration: 6.0, usePillColors: true)
                    .opacity(0.15)
                    .clipShape(Capsule())
                    .allowsHitTesting(false)
            } else {
                HolographicShimmer(duration: 6.0)
                    .opacity(0.10)
                    .clipShape(Capsule())
                    .allowsHitTesting(false)
            }

            // Border on top of shimmer
            Capsule()
                .strokeBorder(
                    colorScheme == .light
                        ? AppColors.lightBorder
                        : AppColors.borderHover,
                    lineWidth: 1.5
                )
        }
        .shadow(
            color: colorScheme == .light
                ? AppColors.lightShadowPurple
                : AppColors.shadowDeep,
            radius: 24,
            y: -4
        )
    }
}

// MARK: - RacetrackTabPill

private struct RacetrackTabPill: View {

    let tab:        AppTab
    let isSelected: Bool
    let trimEnd:    CGFloat   // owned by bar, not pill
    let onTap:      () -> Void

    @State private var isPressed: Bool = false

    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }

    var body: some View {
        Button(action: onTap) {
            Image(systemName: tab.icon)
                .font(.system(size: 24, weight: .light))
                .frame(width: 24, height: 24) // Forces uniform size so circles match perfectly
                .foregroundStyle(iconColor)
                .padding(12)
                .background(pillBackground)
                .clipShape(Capsule())
                .overlay(racetrackBorder)   // outside clip so stroke isn't cut
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !isSelected else { return }
                    isPressed = true
                }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityLabel(tab.label)
        .accessibilityHint(isSelected ? "Selected" : "Switch to \(tab.label)")
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }

    // MARK: - Visual layers

    private var iconColor: Color {
        if isSelected { return isLight ? AppColors.lightCardTitle : .white }
        if isPressed  {
            return isLight
                ? AppColors.lightCardTitle
                : Color(white: 0.65)
        }
        return isLight ? AppColors.lightCardTitle.opacity(0.85) : Color(white: 0.80)
    }

    private var pillBackground: some View {
        Capsule()
            .fill(pillFill)
            .animation(.easeOut(duration: 0.25), value: isSelected)
            .animation(.easeOut(duration: 0.25), value: isPressed)
    }

    private var pillFill: Color {
        if isSelected {
            return isLight ? AppColors.lightFrostPillSel : AppColors.surfaceBg
        }
        if isPressed {
            return isLight
                ? AppColors.lightFrostPill
                : Color(red: 0.086, green: 0.079, blue: 0.141)
        }
        return .clear
    }

    private var racetrackBorder: some View {
        Capsule()
            .trim(from: 0, to: trimEnd)
            .stroke(
                AngularGradient(
                    colors: isLight
                        ? [AppColors.magenta, AppColors.orangeHot, AppColors.gold, AppColors.magenta]
                        : [AppColors.cyan, AppColors.purple, AppColors.magenta, AppColors.pink, AppColors.cyan],
                    center: .center
                ),
                style: StrokeStyle(
                    lineWidth: 3.5,     // ← was 2, now clearly visible
                    lineCap: .round
                )
            )
            .rotationEffect(.degrees(-90))
            // Glow — makes the stroke pop off the dark background
            .shadow(color: isLight
                ? AppColors.magenta.opacity(0.55)
                : AppColors.cyan.opacity(0.70),
                    radius: 4, x: 0, y: 0)
    }
}
// MARK: - Previews

#Preview("Dark — Interactive") {
    @Previewable @State var selection: AppTab = .home
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        VStack {
            Text(selection.label)
                .font(AppFonts.heroTitle)
                .foregroundStyle(AppColors.textSecondary)
                .animation(.easeInOut(duration: 0.2), value: selection)
            Spacer()
        }
        .padding(.top, 120)
        VStack {
            Spacer()
            RacetrackTabBar(selection: $selection)
                .padding(.bottom, 20)
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Light — Interactive") {
    @Previewable @State var selection: AppTab = .home
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        VStack {
            Text(selection.label)
                .font(AppFonts.heroTitle)
                .foregroundStyle(AppColors.lightTextSecondary)
                .animation(.easeInOut(duration: 0.2), value: selection)
            Spacer()
        }
        .padding(.top, 120)
        VStack {
            Spacer()
            RacetrackTabBar(selection: $selection)
                .padding(.bottom, 20)
        }
    }
    .preferredColorScheme(.light)
}

```

---

## File: `Open Lightly/Design/Components/Navigation/TabContentWrapper.swift` {#file-open-lightly-design-components-navigation-tabcontentwrapper-swift}

```swift
//
//  TabContentWrapper.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 4/8/26.
//


// Design/Components/Navigation/TabContentWrapper.swift
// Open Lightly
//
// Wraps every tab's content with:
//   1. Bottom content inset — last item scrolls clear of the bar
//   2. Gradient fade mask — Linear-style dissolve before the bar
//   3. Scroll indicator inset — indicator doesn't run under bar
//
// Usage:
//   TabContentWrapper { YourView() }
//
// Every tab gets this automatically. No per-tab configuration needed.
// The wrapper reads safeAreaInsets from the environment — injected
// once at AppShell, available to all children without GeometryReader.

import SwiftUI

struct TabContentWrapper<Content: View>: View {
    
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { geo in
            let bottomInset    = geo.safeAreaInsets.bottom
            let barHeight:     CGFloat = 62
            let barOffset:     CGFloat = bottomInset + 8
            let totalClearance: CGFloat = barHeight + barOffset + 16
            let fadeHeight:    CGFloat = 120

            content
                .contentMargins(
                    .bottom,
                    totalClearance,
                    for: .scrollContent
                )
                .contentMargins(
                    .bottom,
                    barHeight + barOffset,
                    for: .scrollIndicators
                )
                .mask(
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.black)
                        LinearGradient(
                            stops: [
                                .init(color: .black,              location: 0.00),
                                .init(color: .black,              location: 0.15),
                                .init(color: .black.opacity(0.85), location: 0.40),
                                .init(color: .black.opacity(0.40), location: 0.70),
                                .init(color: .clear,              location: 1.00),
                            ],
                            startPoint: .top,
                            endPoint:   .bottom
                        )
                        .frame(height: fadeHeight)
                    }
                    .ignoresSafeArea()
                )
        }
    }
}

// MARK: - Preview

#Preview("Dark — Scroll Test") {
    ZStack(alignment: .bottom) {
        AppColors.pageBg.ignoresSafeArea()

        TabContentWrapper {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(0..<20) { i in
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppColors.cardBg)
                            .overlay(
                                Text("Item \(i + 1)")
                                    .font(AppFonts.body(15))
                                    .foregroundStyle(AppColors.textSecondary)
                            )
                            .frame(height: 72)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(AppColors.border, lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }

        // Simulated bar so the fade target is visible
        RacetrackTabBar(selection: .constant(.home))
            .padding(.bottom, 8)
    }
    .preferredColorScheme(.dark)
}

#Preview("Light — Scroll Test") {
    ZStack(alignment: .bottom) {
        AppColors.lightPageBg.ignoresSafeArea()

        TabContentWrapper {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(0..<20) { i in
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppColors.lightFrostCard)
                            .overlay(
                                Text("Item \(i + 1)")
                                    .font(AppFonts.body(15))
                                    .foregroundStyle(AppColors.lightTextSecondary)
                            )
                            .frame(height: 72)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(AppColors.lightBorder, lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }

        RacetrackTabBar(selection: .constant(.home))
            .padding(.bottom, 8)
    }
    .preferredColorScheme(.light)
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

    /// Bright near-white for small labels that need to survive
    /// a purple-tinted ambient background (status strip counts,
    /// overline labels, etc). Device-absolute — cannot be tinted.
    static let textBright = Color(white: 0.90)

    /// Muted body text — sublabels inside cards.
    /// Use when textSecondary reads below threshold on deep backgrounds.
    static let textMutedBody = Color(white: 0.62)

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
    /// Gold usage rule:
    /// At full or near-full opacity: safety signals only
    /// (safe word button, warnings, hard stop actions).
    /// Never decorative at visible opacity.
    /// Aurora atmospheric use at ≤8% opacity is acceptable
    /// because it cannot be read as a directional signal
    /// at that opacity level. If it is visible enough to be
    /// noticed as gold, it is too opaque for non-safety use.
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

    /// Mid-tone label text on cream — labels, descriptions.
    /// Opaque equivalent of Color(hex:"1A1A1E").opacity(0.50) on #F8F6EE.
    static let lightTextSecondary = Color(hex: "8C8C94")

    /// Subtle meta text on cream — timestamps, hints, tertiary labels.
    /// Opaque equivalent of Color(hex:"1A1A1E").opacity(0.30) on #F8F6EE.
    static let lightTextTertiary  = Color(hex: "B3B3BA")

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

    // MARK: - Pill Tokens

    /// Unselected pill interior — dark mode.
    /// Sits ~15% brighter than cardBg so pill labels have a
    /// contrast floor against the purple ambient atmosphere.
    static let pillSurface = Color(red: 0.10, green: 0.09, blue: 0.16)
    static let pillSurfaceBottom = Color(red: 0.08, green: 0.07, blue: 0.13)

    /// Selected pill interior tint multiplier base.
    /// View applies .opacity() on top of this.
    static let pillSurfaceSelected = Color(red: 0.051, green: 0.043, blue: 0.122)

    /// Ambient lift shadow applied to every pill in dark mode.
    /// Keeps pills visually separated from the background without
    /// a directional light source.
    static let pillGlow = Color(white: 1.0).opacity(0.04)

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
    // TODO: replace with opaque equivalent
    static let lightHintText      = magentaDark.opacity(0.50)

    // Aurora atmosphere blobs
    // Four colors that pool in corners behind frosted cards.
    // Opacity intentionally low — these are felt, not seen.
    static let auroraBlob1 = magenta.opacity(0.09)    // magenta — top right
    static let auroraBlob2 = purple.opacity(0.08)     // purple  — bottom left
    static let auroraBlob3 = gold.opacity(0.07)       // gold at 7% — below signal threshold, atmospheric use only. See gold usage rule above.
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
            assertionFailure(
                "AppFonts.display: unsupported weight \(weight). " +
                "Supported: .bold, .semibold, .medium"
            )
            return Font.custom("ClashDisplay-Bold", size: size)
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

    // --- Display Scale (Clash Display) ---
    static var heroTitle: Font           { display(42, weight: .bold) }           // 42pt Bold
    static var displayHero: Font         { display(64, weight: .bold) }           // 64pt Bold
    static var scoreDisplay: Font        { display(32, weight: .bold) }           // 32pt Bold
    static var screenTitle: Font         { display(24, weight: .semibold) }       // 24pt Semibold
    static var cardTitle: Font           { display(22, weight: .semibold) }       // 22pt Semibold
    static var sectionHeading: Font      { display(20, weight: .medium) }         // 20pt Medium
    static var sectionLabelSmall: Font   { display(13, weight: .medium) }         // 13pt Medium
    static var prompt: Font              { display(17, weight: .medium) }         // 17pt Medium
    static var promptHighlight: Font     { display(17, weight: .semibold) }       // 17pt Semibold

    // --- Body Scale (Switzer) ---
    static var ctaLabel: Font            { body(16, weight: .semibold) }          // 16pt Semibold
    static var bodyText: Font            { body(16, weight: .regular) }           // 16pt Regular
    static var bodyMedium: Font          { body(15, weight: .medium) }            // 15pt Medium
    static var buttonLabel: Font         { body(14, weight: .semibold) }          // 14pt Semibold
    static var caption: Font             { body(13, weight: .regular) }           // 13pt Regular
    static var overline: Font            { body(11, weight: .semibold) }          // 11pt Semibold
    static var buttonLabelSmall: Font    { body(11, weight: .medium) }            // 11pt Medium
    static var tabLabel: Font            { body(10, weight: .medium) }            // 10pt Medium
    static var label: Font               { body(10, weight: .semibold) }          // 10pt Semibold
    static var badge: Font               { body(10, weight: .medium) }            // 10pt Medium
    static var meta: Font                { body(10, weight: .regular) }           // 10pt Regular

    // MARK: - Debug Font List
    static func debugFontList() {
        for family in UIFont.familyNames.sorted() {
            print("\n\(family)")
            for name in UIFont.fontNames(forFamilyName: family) {
                print("  \(name)")
            }
        }
    }
}

```

---

