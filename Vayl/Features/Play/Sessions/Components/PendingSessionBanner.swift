//
//  PendingSessionBanner.swift
//  Vayl
//
//  "<name> set up a session." Top-anchored, dismissible, reused by Home and
//  Play. Purely presentational; decisions live in SessionEntryStore.
//

import SwiftUI

struct PendingSessionBanner: View {

    let initiatorName: String
    let deckTitle: String
    let onJoin: () -> Void
    let onDismiss: () -> Void

    @State private var isPressed = false

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Circle()
                .fill(AppColors.spectrumBorder)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text("\(initiatorName) set up a session")
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(AppColors.textBody)
                Text("\(deckTitle) · tap to join")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer(minLength: 0)

            Button(action: onDismiss) {
                Image(systemName: AppIcons.close)
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
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .sensoryFeedback(.impact(weight: .light), trigger: isPressed)
        .contentShape(Rectangle())
        .onTapGesture { onJoin() }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

#Preview("Pending session banner") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        PendingSessionBanner(
            initiatorName: "Alex",
            deckTitle: "The Opener",
            onJoin: {},
            onDismiss: {}
        )
        .padding(AppSpacing.lg)
    }
    .preferredColorScheme(.dark)
}
