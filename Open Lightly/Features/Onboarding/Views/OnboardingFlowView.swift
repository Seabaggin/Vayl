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
// COMPLETION FLOW (groundRules → main app):
//   1. deriveExperienceType(from: onboardingData) → ExperienceType
//   2. appState.experienceType = derived value (persists to UserDefaults)
//   3. hasCompletedOnboarding = true (triggers ContentView gate via @AppStorage)

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
    @State private var currentStep: OnboardingStep = .stat

    // Persisted onboarding data (builds up across screens)
    @State private var onboardingData = OnboardingData()

    // Completion gate — written here, read by ContentView
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    // Experience routing — set on completion, drives HomeView router
    @Environment(AppState.self) private var appState

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Shared BG so transitions never flash the wrong surface color.
            // Dark: near-black (#030305). Light: warm cream (#F8F6EE).
            (colorScheme == .light ? AppColors.lightPageBg : AppColors.pageBg)
                .ignoresSafeArea()

            switch currentStep {
            case .stat:
                OnboardingStatView(onContinue: {
                    advance(to: .brand)
                })
                .transition(.opacity)

            case .brand:
                OnboardingBrandView(onFinished: {
                    advance(to: .name)
                })
                .transition(.opacity)

            case .name:
                OnboardingNameView(data: $onboardingData, onContinue: {
                    advance(to: .modeSelect)
                })
                .transition(.opacity)

            case .modeSelect:
                OnboardingModeSelectView(
                    data: $onboardingData,
                    onContinue: {
                        // Browsing users skip contextSelect — they have no relationship context to declare
                        if onboardingData.explorationMode == .browsing {
                            advance(to: .curiosityPicker)
                        } else {
                            advance(to: .contextSelect)
                        }
                    },
                    onBack: { advance(to: .name) }
                )
                .transition(.opacity)

            case .contextSelect:
                OnboardingContextView(
                    data: $onboardingData,
                    onContinue: { advance(to: .curiosityPicker) },
                    onBack:     { advance(to: .modeSelect) }
                )
                .transition(.opacity)

            case .curiosityPicker:
                OnboardingCuriosityPickerView(
                    data: $onboardingData,
                    onContinue: { advance(to: .buildingPath) },
                    onBack: {
                        // Browsing users went modeSelect → curiosityPicker, so back goes to modeSelect
                        if onboardingData.explorationMode == .browsing {
                            advance(to: .modeSelect)
                        } else {
                            advance(to: .contextSelect)
                        }
                    }
                )
                .transition(.opacity)

            case .buildingPath:
                OnboardingBuildingPathView(data: $onboardingData, onFinished: {
                    advance(to: .cardReveal)
                })
                .transition(.opacity)

            case .cardReveal:
                OnboardingCardRevealView(onContinue: {
                    advance(to: .groundRules)
                })
                .transition(.opacity)

            case .groundRules:
                OnboardingGroundRulesView(data: $onboardingData, onFinished: {
                    let experience = deriveExperienceType(from: onboardingData)
                    appState.experienceType = experience
                    logger.info("Onboarding complete — experienceType set to: \(experience.rawValue)")
                    hasCompletedOnboarding = true
                })
                .transition(.opacity)
            }
        }
    }

    private func advance(to step: OnboardingStep) {
        withAnimation(.easeInOut(duration: 0.5)) {
            currentStep = step
        }
    }

    // MARK: - Experience Type Derivation

    /// Maps onboarding answers → ExperienceType for AppState routing.
    ///
    /// Mapping rules:
    ///   .browsing                              → .browsing
    ///   .solo + .single (or no context)        → .soloSingle
    ///   .solo + .partneredOpen/.partneredHidden → .soloPartnered
    ///   .couple + nmStage == .experienced
    ///           OR context == .someExperience  → .coupleExperienced
    ///   .couple (otherwise)                    → .coupleNew
    ///   nil mode (should not happen)           → .soloSingle (safe fallback)
    private func deriveExperienceType(from data: OnboardingData) -> ExperienceType {
        switch data.explorationMode {
        case .browsing:
            return .browsing

        case .solo:
            switch data.relationshipContext {
            case .partneredOpen, .partneredHidden:
                return .soloPartnered
            default:
                // .single, nil, or any unrecognised context
                return .soloSingle
            }

        case .couple:
            let isExperienced = data.nmStage == .experienced
                || data.relationshipContext == .someExperience
            return isExperienced ? .coupleExperienced : .coupleNew

        case .none:
            // explorationMode should always be set by modeSelect;
            // .none means the user somehow skipped it — default safely.
            logger.warning("deriveExperienceType: explorationMode is nil — defaulting to soloSingle")
            return .soloSingle
        }
    }
}
