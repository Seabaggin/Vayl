//
//  SessionLobbyView.swift
//  Vayl
//
//  The lobby: the row exists, one or both partners are not tracked on the
//  channel yet. Initiator: waiting + tonight's shape + cancel. Joiner: the same
//  screen reads as "you're here, waiting for the room". Auto-advances to the
//  airlock when AirlockStore reports bothPresent (the container's switch owns
//  that routing). Cover-family chrome.
//

import SwiftUI

struct SessionLobbyView: View {

    @Bindable var store: CoupleSessionStore
    let airlock: AirlockStore

    @Environment(\.vaylDismiss) private var vaylDismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var waitingPulse = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: AppSpacing.sm) {
                Text("✦")
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(AppColors.spectrumText)
                Text("session lobby")
                    .font(AppFonts.overline)
                    .tracking(2)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.textTertiary)
            }
            .padding(.bottom, AppSpacing.lg)

            Text(store.entry == .initiator
                 ? "Waiting for \(store.partnerLabel)"
                 : "You're in the room")
                .font(AppFonts.screenTitle)
                .foregroundStyle(AppColors.textPrimary)

            if case .failed(let reason) = airlock.state {
                Text(reason)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .padding(.top, AppSpacing.sm)
            }

            shapeCard
                .padding(.top, AppSpacing.lg)

            Spacer(minLength: 0)

            HStack(spacing: AppSpacing.md) {
                Circle()
                    .fill(AppColors.accentPrimary)
                    .frame(width: 9, height: 9)
                    .opacity(waitingPulse ? 0.75 : 0.4)
                    .ambientAnimation(
                        .easeInOut(duration: AppAnimation.ambientPulse)
                            .repeatForever(autoreverses: true),
                        value: waitingPulse
                    )
                Text(airlock.partnerPresent
                     ? "\(store.partnerLabel) is here"
                     : "waiting for \(store.partnerLabel)…")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .padding(.bottom, AppSpacing.lg)

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                store.abandonRemoteSession()
                airlock.leave()
                vaylDismiss(confirm: false)
            } label: {
                Text(store.entry == .initiator ? "Cancel session" : "Not now")
                    .font(AppFonts.buttonLabel)
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                            .strokeBorder(AppColors.borderDefault, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.top, AppSpacing.xxl)
        .padding(.bottom, AppSpacing.xl)
        .onAppear { waitingPulse = true }
    }

    private var shapeCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            shapeRow(icon: "rectangle.stack", label: "Deck", value: store.deckTitle)
            shapeRow(icon: "square.grid.2x2", label: "Cards", value: "\(store.hand.count)")
            shapeRow(icon: "clock", label: "Roughly",
                     value: "~\(max(1, store.hand.count * 2)) min")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.container, style: .continuous)
                .fill(AppColors.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.container, style: .continuous)
                        .strokeBorder(AppColors.spectrumBorder.opacity(0.4), lineWidth: 0.8)
                )
        )
    }

    private func shapeRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(AppFonts.bodyMedium)
                .foregroundStyle(AppColors.spectrumText)
                .frame(width: 22)
            Text(label)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
            Spacer()
            Text(value)
                .font(AppFonts.bodyMedium)
                .foregroundStyle(AppColors.textBody)
        }
    }
}
