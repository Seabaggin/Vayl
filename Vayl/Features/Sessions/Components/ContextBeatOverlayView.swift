//
//  ContextBeatOverlayView.swift
//  Vayl
//
//  Full-screen pre-card context beat (spec §4.4, narrowed 2026-07-07 — the
//  old `banner` case moved to ContextKickerView, a persistent header on the
//  card itself). This view now only renders `interstitial`: full screen,
//  appears BEFORE the card presents, user-dismissed. Presentation only; the
//  store owns when a beat is active.
//

import SwiftUI

struct ContextBeatOverlayView: View {

    let copy: String
    let onDismiss: () -> Void

    var body: some View {
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
