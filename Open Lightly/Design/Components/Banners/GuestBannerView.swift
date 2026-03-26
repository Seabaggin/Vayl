// Design/Components/Banners/GuestBannerView.swift
// Open Lightly
//
// Persistent banner shown at the top of the guest (browsing) shell.
// Tapping "create an account" resets the onboarding gate, returning
// the user to the onboarding flow where they can sign up properly.

import SwiftUI
import OSLog

private let logger = Logger(subsystem: "com.openlightly.app", category: "GuestBannerView")

struct GuestBannerView: View {

    @Environment(AppState.self) private var appState
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        HStack(spacing: 6) {
            Text("You're browsing —")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)

            Button {
                logger.info("Guest tapped create account — resetting onboarding gate")
                appState.experienceType = .soloSingle   // reset to safe default
                hasCompletedOnboarding = false          // returns to onboarding
            } label: {
                HStack(spacing: 3) {
                    Text("create an account to unlock everything")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.cyan)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppColors.cyan)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Create an account to unlock everything")
            .accessibilityHint("Starts the account creation flow")

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(AppColors.surfaceBg)
        .overlay(
            Rectangle()
                .fill(AppColors.border)
                .frame(height: 1),
            alignment: .bottom
        )
    }
}

// MARK: - Preview

#Preview {
    let state = AppState()
    state.experienceType = .browsing
    return VStack(spacing: 0) {
        GuestBannerView()
        Spacer()
    }
    .background(AppColors.pageBg.ignoresSafeArea())
    .environment(state)
    .preferredColorScheme(.dark)
}
