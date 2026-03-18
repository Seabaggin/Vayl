// Features/Onboarding/OnboardingFlowView.swift

import SwiftUI

// MARK: - Screen Sequence (Batch 11 Spec)
// 0. StatView        → trust trigger
// 1. BrandView       → identity (auto-advance)
// 2. NameView        → name + pronouns
// 3. ModeSelectView  → solo vs couple
// ...

enum OnboardingStep: Int, CaseIterable {
    case stat           // Screen 0
    case brand          // Screen 0.5 (auto-advance)
    case name           // Screen 1
    case modeSelect
    case contextSelect
    case relationshipStatus
    case personalize
    case pairing
    case groundRules
    case priming
    case arrival
}

struct OnboardingFlowView: View {
    @State private var currentStep: OnboardingStep = .stat
    
    // Persisted onboarding data (builds up across screens)
    @State private var onboardingData = OnboardingData()
    
    var body: some View {
        ZStack {
            // Shared dark BG so transitions never flash white
            OnboardingTokens.screenBG
                .ignoresSafeArea()
            
            switch currentStep {
            case .stat:
                OnboardingStatView {
                    advance(to: .brand)
                }
                .transition(.opacity)
                
            case .brand:
                OnboardingBrandView {
                    advance(to: .name)
                }
                .transition(.opacity)
                
            case .name:
                OnboardingNameView(data: $onboardingData) {
                    advance(to: .modeSelect)
                }
                .transition(.opacity)

            case .modeSelect:
                OnboardingModeSelectView(
                    data: $onboardingData,
                    onContinue: { advance(to: .contextSelect) },
                    onBack:     { advance(to: .name) }
                )
                .transition(.opacity)

            case .contextSelect:
                OnboardingContextView(
                    data: $onboardingData,
                    onContinue: {
                        // TODO: advance to ground rules screen (step 5)
                        print("[OnboardingFlow] Context selected: \(onboardingData.relationshipContext?.rawValue ?? "none")")
                    },
                    onBack: { advance(to: .modeSelect) }
                )
                .transition(.opacity)

            // ... remaining steps
            default:
                EmptyView()
            }
        }
        .animation(.easeInOut(duration: 0.5), value: currentStep)
    }
    
    private func advance(to step: OnboardingStep) {
        withAnimation(.easeInOut(duration: 0.5)) {
            currentStep = step
        }
    }
}
