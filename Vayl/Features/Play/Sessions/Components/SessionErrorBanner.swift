//
//  SessionErrorBanner.swift
//  Vayl
//
//  Small dismissible error banner for session launch failures (spec
//  2026-07-09 §1.8: joining/launching must fail loud, never silent). Same
//  visual language as PlayView's pre-existing failed-open banner; purely
//  presentational, reused by Home and Play.
//

import SwiftUI

struct SessionErrorBanner: View {

    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Text(message)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textBody)
            Spacer(minLength: 0)
            Button {
                onDismiss()
            } label: {
                Image(systemName: AppIcons.close)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }
            .buttonStyle(PressableCardStyle())
            .accessibilityLabel("Dismiss error")
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm + AppSpacing.xxs)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .fill(AppColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .strokeBorder(AppColors.borderDefault, lineWidth: 1)
                )
        )
    }
}

#Preview("Session error banner") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        VStack {
            Spacer()
            SessionErrorBanner(
                message: "Couldn't open that session. Make sure you're both on the latest version, then try again.",
                onDismiss: {}
            )
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.lg)
        }
    }
    .preferredColorScheme(.dark)
}
