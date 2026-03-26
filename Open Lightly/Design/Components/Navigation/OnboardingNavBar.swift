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
                .padding(10)
                .background(
                    Circle()
                        .fill(Color.black.opacity(0.05))
                        .overlay(
                            Circle()
                                .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
                        )
                )
        } else {
            content
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
            // Back button — or invisible spacer to keep bar centered
            if let onBack {
                Button(action: onBack) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(colorScheme == .light
                            ? AppColors.lightTextSecondary
                            : .white.opacity(0.55))
                        .modifier(BackButtonModifier(colorScheme: colorScheme))
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
