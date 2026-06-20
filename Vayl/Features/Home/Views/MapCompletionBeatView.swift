//
//  MapCompletionBeatView.swift
//  Vayl
//
//  A brief, one-shot celebration beat shown over the Home dashboard the moment the user
//  finishes their Desire Map. Transient — tap to continue into the dashboard. The map is a
//  moment, never a persistent home state (Home always leads with the card deck).
//
//  STRUCTURE ONLY — the FEEL (timing, motion, copy, whether it auto-fades) is Bryan's
//  on-device pass. Reuses the reveal's ✦ prism emblem so the completion motif is consistent.
//

import SwiftUI

struct MapCompletionBeatView: View {

    let partnerName: String?
    let onDone: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var appeared = false
    @State private var pulse = false

    var body: some View {
        ZStack {
            // Dim the dashboard behind; tap anywhere to continue.
            AppColors.void.opacity(0.72)
                .ignoresSafeArea()

            VStack(spacing: AppSpacing.lg) {
                emblem

                VStack(spacing: AppSpacing.sm) {
                    Text("That's yours now")
                        .font(AppFonts.sectionHeading)
                        .foregroundStyle(AppColors.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(forwardLine)
                        .font(AppFonts.bodyText)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text("Tap to continue")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
                    .padding(.top, AppSpacing.sm)
            }
            .padding(AppSpacing.xl)
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared || reduceMotion ? 1 : 0.94)
        }
        .contentShape(Rectangle())
        .onTapGesture { onDone() }
        .onAppear {
            withAnimation(AppAnimation.enter) { appeared = true }
            pulse = true
        }
    }

    private var forwardLine: String {
        let name = (partnerName?.isEmpty == false) ? partnerName! : "your partner"
        return "When \(name) finishes theirs, you'll see where you align."
    }

    /// ✦ concentric prism emblem — mirrors DesireRevealView so the completion motif is consistent.
    private var emblem: some View {
        ZStack {
            Circle()
                .fill(AppColors.spectrumCyan.opacity(pulse ? 0.18 : 0.08))
                .frame(width: 96, height: 96)
                .blur(radius: 16)
            Circle()
                .stroke(AppColors.spectrumBorder, lineWidth: 1.5)
                .frame(width: 72, height: 72)
            Circle()
                .fill(AppColors.void)
                .frame(width: 60, height: 60)
            Text("✦")
                .font(AppFonts.cardTitle)
                .foregroundStyle(AppColors.spectrumBorder)
        }
        .spectrumBorderGlow(intensity: pulse ? 0.6 : 0.3)
        .ambientAnimation(
            .easeInOut(duration: AppAnimation.ambientPulse).repeatForever(autoreverses: true),
            value: pulse
        )
    }
}

#if DEBUG
#Preview("Completion beat") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        MapCompletionBeatView(partnerName: "Alex", onDone: {})
    }
    .preferredColorScheme(.dark)
}
#endif
