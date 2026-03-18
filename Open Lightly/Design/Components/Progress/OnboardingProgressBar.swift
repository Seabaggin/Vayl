// OnboardingProgressBar.swift
// Open Lightly
//
// Segmented capsule progress bar for onboarding flow.
// Step 1 of 6 = 20pt fill, Step 3 of 6 = 60pt fill, etc.
import SwiftUI

struct OnboardingProgressBar: View {
    let currentStep: Int   // 1-indexed
    let totalSteps: Int

    private let totalWidth: CGFloat = 120
    private let barHeight: CGFloat = 4

    private var fillWidth: CGFloat {
        guard totalSteps > 0 else { return 0 }
        return totalWidth * CGFloat(currentStep) / CGFloat(totalSteps)
    }

    var body: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(Color.white.opacity(0.08))
                .frame(width: totalWidth, height: barHeight)
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [AppColors.cyan, AppColors.purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: fillWidth, height: barHeight)
                .animation(.easeInOut(duration: 0.35), value: currentStep)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(currentStep) of \(totalSteps)")
    }
}

#Preview {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        VStack(spacing: 20) {
            OnboardingProgressBar(currentStep: 1, totalSteps: 6)
            OnboardingProgressBar(currentStep: 2, totalSteps: 6)
            OnboardingProgressBar(currentStep: 4, totalSteps: 6)
            OnboardingProgressBar(currentStep: 6, totalSteps: 6)
        }
    }
}
