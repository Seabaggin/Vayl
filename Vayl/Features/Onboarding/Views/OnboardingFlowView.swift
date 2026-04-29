//
//  OnboardingFlowView.swift
//  Vayl
//

import SwiftUI
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.vayl.app", category: "OnboardingFlowView")

struct OnboardingFlowView: View {

    // MARK: - Store

    @State private var store: OnboardingStore

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Init

    init(modelContainer: ModelContainer, appState: AppState, startAt: OnboardingStep = .stat) {
        _store = State(wrappedValue: OnboardingStore(
            modelContainer: modelContainer,
            appState: appState,
            startAt: startAt
        ))
    }

    // MARK: - Body

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
            switch store.currentStep {

            case .stat:
                OnboardingStatView(onContinue: {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        store.advance()
                    }
                })
                .transition(.opacity)

            case .brand:
                OnboardingBrandView(
                    onFinished: {
                        store.advance()
                    }
                )

            // No onBack — NameView is the first data-entry screen.
            // BrandView (the previous screen) auto-advances and
            // cannot be safely navigated back to. Back is suppressed
            // to prevent a BrandView → NameView loop.
            case .name:
                OnboardingNameView(
                    data:       $store.data,
                    onContinue: { store.advance() }
                )

            case .modeSelect:
                OnboardingModeSelectView(
                    data:       $store.data,
                    onContinue: { store.advance() },
                    onBack:     { store.goBack() }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))

            case .contextSelect:
                OnboardingContextView(
                    data:       $store.data,
                    onContinue: { store.advance() },
                    onBack:     { store.goBack() }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))

            case .curiosityPicker:
                OnboardingCuriosityPickerView(
                    data:       $store.data,
                    onContinue: { store.advance() },
                    onBack:     { store.goBack() }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))

            case .cardReveal:
                OnboardingCardRevealView(
                    data:       $store.data,
                    onContinue: { store.advance() }
                )
                .transition(.opacity)

            case .buildingPath:
                OnboardingBuildingPathView(
                    data:       $store.data,
                    onFinished: { store.advance() }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))

            case .groundRules:
                OnboardingGroundRulesView(
                    data:       $store.data,
                    onFinished: { store.advance() }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }

            // ── Error overlay ─────────────────────────────────────────
            if let error = store.lastCommitError {
                VStack(spacing: 16) {
                    Text("Something went wrong")
                        .font(AppFonts.screenTitle)
                        .foregroundStyle(AppColors.textPrimary)

                    Text(error.localizedDescription)
                        .font(AppFonts.bodyText)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)

                    Button("Try Again") {
                        store.advance()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(24)
                .background(AppColors.pageBg)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(32)
            }
        }
    }

    // MARK: - Atmosphere config per step

    private var atmosphereConfig: AtmosphereConfig {
        switch store.currentStep {
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
        switch store.currentStep {
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
}

// TODO: ExperienceType routing was removed — reimplement when content routing is rebuilt

// MARK: - Previews

#Preview("Full Flow — Dark") {
    let container = ModelContainer.previewContainer
    let appState = AppState()
    return OnboardingFlowView(modelContainer: container, appState: appState)
        .environment(appState)
        .preferredColorScheme(.dark)
}

#Preview("Full Flow — Light") {
    let container = ModelContainer.previewContainer
    let appState = AppState()
    return OnboardingFlowView(modelContainer: container, appState: appState)
        .environment(appState)
        .preferredColorScheme(.light)
}

#Preview("Jump → Curiosity Picker") {
    let container = ModelContainer.previewContainer
    let appState = AppState()
    return OnboardingFlowView(
        modelContainer: container,
        appState: appState,
        startAt: .curiosityPicker
    )
    .environment(appState)
    .preferredColorScheme(.dark)
}

#Preview("Jump → Name") {
    let container = ModelContainer.previewContainer
    let appState = AppState()
    return OnboardingFlowView(
        modelContainer: container,
        appState: appState,
        startAt: .name
    )
    .environment(appState)
    .preferredColorScheme(.dark)
}
