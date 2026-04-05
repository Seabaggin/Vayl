// Features/Onboarding/OnboardingFlowView.swift

import SwiftUI
import OSLog

private let logger = Logger(subsystem: "com.openlightly.app", category: "OnboardingFlowView")

// Step order is intentional and load-bearing.
// cardReveal precedes buildingPath: CardReveal collects
// nmCardResponse, which BuildingPath reads for its fourth
// orbit row and personalised exit copy. Do not reorder.
enum OnboardingStep: Int, CaseIterable {
    case stat
    case brand
    case name
    case modeSelect
    case contextSelect
    case curiosityPicker
    case cardReveal
    case buildingPath
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
            // ── Shared background ─────────────────────────────────────
            (colorScheme == .light ? AppColors.lightPageBg : AppColors.pageBg)
                .ignoresSafeArea()

            // ── Persistent atmosphere ─────────────────────────────────
            OnboardingAtmosphere(
                config:      atmosphereConfig,
                sparkConfig: sparkConfig
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .accessibilityHidden(true)

            // ── Screen switch ─────────────────────────────────────────
            switch currentStep {

            case .stat:
                OnboardingStatView(onContinue: {
                    advance(to: .brand, animation: .easeInOut(duration: 0.35))
                })
                .transition(.opacity)

            case .brand:
                OnboardingBrandView(
                    onFinished: {
                        advance(to: .name)
                    }
                )

            // No onBack — NameView is the first data-entry screen.
            // BrandView (the previous screen) auto-advances and
            // cannot be safely navigated back to. Back is suppressed
            // to prevent a BrandView → NameView loop.
            case .name:
                OnboardingNameView(
                    data:       $onboardingData,
                    onContinue: { advance(to: .modeSelect) }
                )

            case .modeSelect:
                OnboardingModeSelectView(
                    data:       $onboardingData,
                    onContinue: {
                        if onboardingData.explorationMode == .browsing {
                            advance(to: .curiosityPicker)
                        } else {
                            advance(to: .contextSelect)
                        }
                    },
                    onBack: { advance(to: .name) }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))

            case .contextSelect:
                OnboardingContextView(
                    data:       $onboardingData,
                    onContinue: { advance(to: .curiosityPicker) },
                    onBack:     { advance(to: .modeSelect) }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))

            case .curiosityPicker:
                OnboardingCuriosityPickerView(
                    data:       $onboardingData,
                    onContinue: { advance(to: .cardReveal) },
                    onBack: {
                        if onboardingData.explorationMode == .browsing {
                            advance(to: .modeSelect)
                        } else {
                            advance(to: .contextSelect)
                        }
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))

            case .buildingPath:
                OnboardingBuildingPathView(
                    data:       $onboardingData,
                    onFinished: { advance(to: .groundRules) }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))

            case .cardReveal:
                OnboardingCardRevealView(
                    data:       $onboardingData,
                    onContinue: { advance(to: .buildingPath) }
                )
                .transition(.opacity)

            case .groundRules:
                OnboardingGroundRulesView(
                    data:       $onboardingData,
                    onFinished: {
                        let experience = deriveExperienceType(from: onboardingData)
                        appState.experienceType = experience
                        logger.info("Onboarding complete — experienceType: \(experience.rawValue)")
                        hasCompletedOnboarding = true
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
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
        case .cardReveal:      return .cardRevealView
        case .groundRules:     return .groundRulesView
        }
    }

    // MARK: - Navigation

    private func advance(
        to step: OnboardingStep,
        animation: Animation = .spring(response: 0.35, dampingFraction: 0.8)
    ) {
        withAnimation(animation) {
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
            // Routes to coupleExperienced if the user has signalled
            // prior experience via nmStage OR relationship context.
            // .someExperience = "We've tried some things"
            // .needsReset = "We need a reset" — implies prior history,
            //   needs repair/advanced content, not foundational.
            // .exploring nmStage intentionally routes to coupleNew —
            //   the app is conservative; exploring users benefit from
            //   foundational content before advanced tools surface.
            let isExperienced = data.nmStage == .experienced
                || data.relationshipContext == .someExperience
                || data.relationshipContext == .needsReset
            return isExperienced ? .coupleExperienced : .coupleNew
        case .none:
            logger.warning("deriveExperienceType: explorationMode nil — defaulting to soloSingle")
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

#Preview("Jump → Curiosity Picker") {
    OnboardingFlowView(startAt: .curiosityPicker)
        .environment(AppState())
        .preferredColorScheme(.dark)
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
