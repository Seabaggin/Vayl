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
                .padding(AppSpacing.sm)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.55))
                        .overlay(
                            Circle()
                                .strokeBorder(AppColors.spectrumBorder, lineWidth: 2.0)
                        )
                )
                .shadow(color: AppColors.accentTertiary.opacity(0.12), radius: 8, y: 2)
                .shadow(color: AppColors.accentSecondary.opacity(0.08), radius: 16, y: 2)
        } else {
            content
                .padding(AppSpacing.sm)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [AppColors.accentPrimary, AppColors.accentSecondary, AppColors.accentTertiary],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2.0
                                )
                        )
                )
                .shadow(color: AppColors.accentSecondary.opacity(0.22), radius: 8)
                .shadow(color: AppColors.accentPrimary.opacity(0.12), radius: 20)
                .shadow(color: AppColors.accentSecondary.opacity(0.08), radius: 28)
        }
    }
}

// MARK: - View

struct OnboardingNavBar: View {
    let currentStep: Int
    let totalSteps: Int
    var onBack: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack {
            if let onBack {
                Button(action: onBack) {
                    Image(systemName: AppIcons.arrowLeft)
                        // .body scales with Dynamic Type — correct for
                        // navigation back buttons at this visual weight.
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(colorScheme == .light
                            ? AppColors.textSecondary
                            : Color.white.opacity(0.80))
                        .modifier(BackButtonModifier(colorScheme: colorScheme))
                }
                .accessibilityLabel("Go back")
            } else {
                // Match the 38pt rendered size of the back button
                Color.clear.frame(width: 38, height: 38)
            }

            Spacer()
            OnboardingProgressBar(currentStep: currentStep, totalSteps: totalSteps)
            Spacer()

            Color.clear.frame(width: 38, height: 38)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        ZStack {
            AppColors.pageBackground.ignoresSafeArea()
            VStack(spacing: AppSpacing.xxl) {
                OnboardingNavBar(currentStep: 1, totalSteps: 6, onBack: { })
                OnboardingNavBar(currentStep: 3, totalSteps: 6, onBack: nil)
            }
            .padding(AppSpacing.lg)
        }
        .preferredColorScheme(.dark)
        .frame(maxWidth: .infinity)

        ZStack {
            AppColors.pageBackground.ignoresSafeArea()
            VStack(spacing: AppSpacing.xxl) {
                OnboardingNavBar(currentStep: 1, totalSteps: 6, onBack: { })
                OnboardingNavBar(currentStep: 3, totalSteps: 6, onBack: nil)
            }
            .padding(AppSpacing.lg)
        }
        .preferredColorScheme(.light)
        .frame(maxWidth: .infinity)
    }
}
