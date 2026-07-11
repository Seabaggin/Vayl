//
//  OfflineBanner.swift
//  Vayl
//
//  Quiet, top-anchored, dismissible notice shown on Home when the user entered the
//  app authenticated-but-offline (returning user, cold-launched with no connection).
//  Purely informational — no dead-end, no blocking. It clears itself the moment
//  connectivity returns (AuthService.isOffline flips false). Matches the
//  PendingSessionBanner idiom; dark-only per V1 scope.
//

import SwiftUI

struct OfflineBanner: View {

    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: "wifi.slash")
                .font(AppFonts.buttonLabelSmall)
                .foregroundStyle(AppColors.textSecondary)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text("You're offline")
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(AppColors.textBody)
                Text("Showing your latest saved info.")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer(minLength: 0)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(AppFonts.buttonLabelSmall)
                    .foregroundStyle(AppColors.textTertiary)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss")
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.container, style: .continuous)
                .fill(AppColors.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.container, style: .continuous)
                        .strokeBorder(AppColors.spectrumBorder.opacity(0.5), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .combine)
    }
}

#Preview("Offline banner") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        OfflineBanner(onDismiss: {})
            .padding(AppSpacing.lg)
    }
    .preferredColorScheme(.dark)
}
