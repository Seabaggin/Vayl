// OnboardingFooter.swift
// Open Lightly
//
// Footer shown below the CTA on onboarding screens.

import SwiftUI

struct OnboardingFooter: View {
    var text: String = "Your data is encrypted and always stays yours."

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Text(text)
            // .caption2 scales with Dynamic Type — correct for
            // legal/privacy footer copy at minimum legible size.
            .font(.caption2)
            .foregroundColor(colorScheme == .light
                ? AppColors.textTertiary
                : AppColors.textHint)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, AppSpacing.md)
            .padding(.bottom, AppSpacing.lg)
    }
}

#Preview {
    VStack(spacing: 0) {
        ZStack {
            AppColors.pageBackground.ignoresSafeArea()
            VStack {
                OnboardingFooter()
                OnboardingFooter(text: "Custom footer copy for another screen.")
            }
        }
        .preferredColorScheme(.dark)
        .frame(maxWidth: .infinity)

        ZStack {
            AppColors.pageBackground.ignoresSafeArea()
            VStack {
                OnboardingFooter()
                OnboardingFooter(text: "Custom footer copy for another screen.")
            }
        }
        .preferredColorScheme(.light)
        .frame(maxWidth: .infinity)
    }
}
