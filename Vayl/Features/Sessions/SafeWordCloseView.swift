//
//  SafeWordCloseView.swift
//  Vayl
//
//  The safe-word landing: neutral, warm, zero guilt, on BOTH devices. No
//  reflection prompt, no stats, no "are you sure". Saying the word worked;
//  this screen just holds the room while you leave it.
//

import SwiftUI

struct SafeWordCloseView: View {

    @Bindable var store: CoupleSessionStore

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Spacer()
            Text("stopped, together")
                .font(AppFonts.overline)
                .tracking(2)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.accentSecondary)
            Text("Good call.")
                .font(AppFonts.screenTitle)
                .foregroundStyle(AppColors.textPrimary)
            Text("The word did its job. Nothing else is asked of either of you tonight.")
                .font(AppFonts.bodyText)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)
            Spacer()
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                store.acknowledgeSafeClose()
            } label: {
                Text("Close")
                    .font(AppFonts.ctaLabel)
                    .foregroundStyle(AppColors.textBody)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                            .strokeBorder(AppColors.borderDefault, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
