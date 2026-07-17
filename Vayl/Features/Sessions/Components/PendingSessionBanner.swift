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

    var body: some View {
        Button(action: onJoin) {
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

                // Reserve the dismiss button's footprint inside the label so
                // the layout matches; the live button sits in the overlay
                // (a Button nested inside a Button label never receives taps).
                Color.clear
                    .frame(width: 28, height: 28)
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
            .contentShape(Rectangle())
        }
        // TODO(haptics): Join is a commit-weight action; bump to .medium once
        // VaylPressableStyle gains a weight parameter.
        .buttonStyle(.vaylPressable(scale: 0.98))
        .accessibilityLabel("\(initiatorName) set up a session. \(deckTitle). Join")
        .overlay(alignment: .trailing) {
            Button(action: onDismiss) {
                Image(systemName: AppIcons.close)
                    .font(AppFonts.buttonLabelSmall)
                    .foregroundStyle(AppColors.textTertiary)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.vaylPressable)
            .accessibilityLabel("Dismiss")
            .padding(.trailing, AppSpacing.md)
        }
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

    @State private var showEndConfirm = false

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Button(action: onResume) {
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
            }
            // TODO(haptics): Resume is a commit-weight action; bump to .medium
            // once VaylPressableStyle gains a weight parameter.
            .buttonStyle(.vaylPressable(scale: 0.98))
            .accessibilityLabel("Resume session")

            Button {
                showEndConfirm = true
            } label: {
                Text("End it")
                    .font(AppFonts.buttonLabelSmall)
                    .foregroundStyle(AppColors.textTertiary)
            }
            .buttonStyle(.vaylPressable(scale: 0.96))
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
        .confirmationDialog(
            "End this session?",
            isPresented: $showEndConfirm,
            titleVisibility: .visible
        ) {
            Button("End it", role: .destructive) { onEnd() }
            Button("Keep it", role: .cancel) {}
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
