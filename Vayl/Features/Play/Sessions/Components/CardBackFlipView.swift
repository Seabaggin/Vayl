//
//  CardBackFlipView.swift
//  Vayl
//
//  The back-copy flip (spec §4.4): backCopy cards earn a flip affordance after
//  discussion, before advance. Tapping flips the face over to the responsive
//  back copy (Reduce Motion = crossfade). Presentation only; the store owns
//  showingCardBack.
//

import SwiftUI

struct CardBackFlipView: View {

    let backCopy: String
    let showingBack: Bool
    let onFlip: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if showingBack {
            backFace
        } else {
            flipAffordance
        }
    }

    private var flipAffordance: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onFlip()
        } label: {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: AppIcons.arrowTriangle2Circle)
                    .font(AppFonts.caption)
                Text("turn the card over")
                    .font(AppFonts.buttonLabelSmall)
            }
            .foregroundStyle(AppColors.spectrumText)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(
                Capsule().fill(AppColors.cardBackground.opacity(0.6))
                    .overlay(Capsule().strokeBorder(AppColors.borderDefault, lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
    }

    private var backFace: some View {
        Text(backCopy)
            .font(AppFonts.bodyText)
            .foregroundStyle(AppColors.textBody)
            .lineSpacing(AppSpacing.xs)
            .padding(AppSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.obCard, style: .continuous)
                    .fill(AppColors.cardBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.obCard, style: .continuous)
                            .strokeBorder(AppColors.spectrumBorder.opacity(0.6), lineWidth: 1.1)
                    )
            )
            .transition(reduceMotion
                        ? .opacity
                        : .asymmetric(
                            insertion: .scale(scale: 0.96).combined(with: .opacity),
                            removal: .opacity))
    }
}

#Preview("Flip affordance") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        CardBackFlipView(
            backCopy: Card.samples[1].backCopy ?? "",
            showingBack: false,
            onFlip: {}
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("Back face") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        CardBackFlipView(
            backCopy: Card.samples[1].backCopy ?? "",
            showingBack: true,
            onFlip: {}
        )
        .padding(AppSpacing.lg)
    }
    .preferredColorScheme(.dark)
}
