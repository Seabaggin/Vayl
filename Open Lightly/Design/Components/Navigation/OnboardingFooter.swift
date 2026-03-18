// OnboardingFooter.swift
// Open Lightly
//
// Footer shown below the CTA on onboarding screens.

import SwiftUI

struct OnboardingFooter: View {
    var text: String = "Your data is encrypted and always stays yours."

    var body: some View {
        Text(text)
            .font(.system(size: 12))
            .foregroundColor(Color(red: 0.42, green: 0.42, blue: 0.50))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, 12)
            .padding(.bottom, 24)
    }
}

#Preview {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        VStack {
            OnboardingFooter()
            OnboardingFooter(text: "Custom footer copy for another screen.")
        }
    }
}
