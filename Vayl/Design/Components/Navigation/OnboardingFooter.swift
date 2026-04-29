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
            .font(.system(size: 12))
            .foregroundColor(colorScheme == .light
                ? AppColors.lightTextTertiary
                : AppColors.textHint)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, 12)
            .padding(.bottom, 24)
    }
}

#Preview {
    VStack(spacing: 0) {
        // Dark
        ZStack {
            AppColors.pageBg.ignoresSafeArea()
            VStack {
                OnboardingFooter()
                OnboardingFooter(text: "Custom footer copy for another screen.")
            }
        }
        .preferredColorScheme(.dark)
        .frame(maxWidth: .infinity)

        // Light
        ZStack {
            AppColors.lightPageBg.ignoresSafeArea()
            VStack {
                OnboardingFooter()
                OnboardingFooter(text: "Custom footer copy for another screen.")
            }
        }
        .preferredColorScheme(.light)
        .frame(maxWidth: .infinity)
    }
}
