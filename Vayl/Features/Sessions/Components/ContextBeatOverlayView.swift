//
//  ContextBeatOverlayView.swift
//  Vayl
//
//  Pre-card context beats (spec §4.4). banner: 1-2 lines over the dimmed card,
//  auto-dismiss after 5s, tap-through (never blocks the player). interstitial:
//  full screen, the user dismisses it. Both appear BEFORE the card presents —
//  never on it (AppCardEnums ContextBeatType). Presentation only; the store
//  owns when a beat is active.
//

import SwiftUI

struct ContextBeatOverlayView: View {

    let type: ContextBeatType
    let copy: String
    /// Store callback — banner fires it on its own after the dwell; the
    /// interstitial fires it from its button.
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// 🎚️ Banner dwell before it slips away (spec: 5s).
    private static let bannerDwellSeconds: Double = 5.0

    var body: some View {
        switch type {
        case .banner:  banner
        case .interstitial: interstitial
        }
    }

    // MARK: - Banner: over the dimmed card, tap-through

    private var banner: some View {
        VStack {
            Text(copy)
                .font(AppFonts.bodyText)
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .fill(AppColors.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                                .strokeBorder(AppColors.borderSubtle, lineWidth: 1)
                        )
                )
                .padding(.horizontal, AppSpacing.xl)
                .padding(.top, AppSpacing.xxl)
            Spacer()
        }
        .background(
            // The dim behind the banner — also tap-through.
            AppColors.void.opacity(0.4).ignoresSafeArea()
        )
        .allowsHitTesting(false)   // tap-through: the player stays interactive
        .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
        .task {
            try? await Task.sleep(for: .seconds(Self.bannerDwellSeconds))
            onDismiss()
        }
    }

    // MARK: - Interstitial: full screen, user-dismissed

    private var interstitial: some View {
        ZStack {
            AppColors.void.ignoresSafeArea()
            VStack(spacing: AppSpacing.xl) {
                Text("worth knowing")
                    .font(AppFonts.overline)
                    .tracking(3)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.spectrumText)

                Text(copy)
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textBody)
                    .lineSpacing(AppSpacing.xs)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, AppSpacing.xl)

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onDismiss()
                } label: {
                    Text("got it")
                        .font(AppFonts.buttonLabel)
                        .foregroundStyle(AppColors.void)
                        .padding(.horizontal, AppSpacing.xl)
                        .padding(.vertical, AppSpacing.sm)
                        .background(Capsule().fill(AppColors.spectrumBorder))
                }
                .buttonStyle(.plain)
            }
        }
        .transition(.opacity)
    }
}
