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
                .fill(AppColors.accentPrimary)
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
        .sensoryFeedback(.impact(weight: .light), trigger: isPressed) { _, pressed in pressed }
        .contentShape(Rectangle())
        .onTapGesture { onJoin() }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

/// "Pick your session back up." Same visual language as the invite banner, but
/// no dismiss-X — the only exits are Resume (tap body) or End it (confirmed).
/// A user who wants the row gone must end it; there is no way to bury it and
/// still leave the couple's DB row open.
struct ResumeSessionBanner: View {

    let deckTitle: String
    let cardPosition: Int
    let cardCount: Int
    let onResume: () -> Void
    let onEnd: () -> Void

    @State private var isPressed = false
    @State private var isEndPressed = false
    @State private var showEndConfirm = false

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.md) {
                Circle()
                    .fill(AppColors.accentPrimary)
                    .frame(width: 8, height: 8)

                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text("Pick your session back up")
                        .font(AppFonts.bodyMedium)
                        .foregroundStyle(AppColors.textBody)
                    Text("\(deckTitle) · card \(cardPosition) of \(cardCount)")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
            .onTapGesture { onResume() }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
            .accessibilityElement(children: .ignore)
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel("Resume session")

            Button {
                isEndPressed = true
                showEndConfirm = true
            } label: {
                Text("End it")
                    .font(AppFonts.buttonLabelSmall)
                    .foregroundStyle(AppColors.textTertiary)
            }
            .buttonStyle(.plain)
            .scaleEffect(isEndPressed ? 0.96 : 1.0)
            .sensoryFeedback(.impact(weight: .light), trigger: isEndPressed) { _, pressed in pressed }
            .accessibilityLabel("End it")
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
        .sensoryFeedback(.impact(weight: .light), trigger: isPressed) { _, pressed in pressed }
        .confirmationDialog(
            "End this session?",
            isPresented: $showEndConfirm,
            titleVisibility: .visible
        ) {
            Button("End it", role: .destructive) { onEnd() }
            Button("Keep it", role: .cancel) {}
        }
        .onChange(of: showEndConfirm) { _, isShowing in
            if !isShowing { isEndPressed = false }
        }
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

#Preview("Resume session banner") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        ResumeSessionBanner(
            deckTitle: "The Opener",
            cardPosition: 3,
            cardCount: 8,
            onResume: {},
            onEnd: {}
        )
        .padding(AppSpacing.lg)
    }
    .preferredColorScheme(.dark)
}
