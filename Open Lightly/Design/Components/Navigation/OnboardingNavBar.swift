// OnboardingNavBar.swift
// Open Lightly
//
// Reusable nav row: back chevron + centered progress bar.
// Used at the top of every onboarding screen that shows navigation.
import SwiftUI

struct OnboardingNavBar: View {
    let currentStep: Int
    let totalSteps: Int
    var onBack: (() -> Void)?  // nil = no back button (ground rules, priming, arrival)

    var body: some View {
        HStack {
            // Back button — or invisible spacer to keep bar centered
            if let onBack {
                Button(action: onBack) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.55))
                }
                .accessibilityLabel("Go back")
            } else {
                Color.clear.frame(width: 18, height: 18)
            }

            Spacer()
            OnboardingProgressBar(currentStep: currentStep, totalSteps: totalSteps)
            Spacer()

            // Trailing spacer to balance the back button
            Color.clear.frame(width: 18, height: 18)
        }
    }
}

#Preview {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        VStack(spacing: 40) {
            OnboardingNavBar(currentStep: 1, totalSteps: 6, onBack: { })
            OnboardingNavBar(currentStep: 3, totalSteps: 6, onBack: nil)
        }
        .padding(24)
    }
}
