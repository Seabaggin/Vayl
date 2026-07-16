//
//  SessionTimerBar.swift
//  Vayl
//
//  The gentle per-card timer: a quiet mm:ss while running, and at zero a soft
//  chime (haptic) + "wrap up when you're ready / keep going". It never advances
//  the card and never hard-cuts. Presentation only.
//

import SwiftUI

struct SessionTimerBar: View {

    @Bindable var store: CoupleSessionStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if let remaining = store.timerRemaining {
            Group {
                if store.timerElapsed {
                    HStack(spacing: AppSpacing.md) {
                        Text("no rush, wrap up when you're ready")
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textSecondary)
                        Button {
                            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                            store.keepGoing()
                        } label: {
                            Text("keep going")
                                .font(AppFonts.buttonLabelSmall)
                                .foregroundStyle(AppColors.spectrumText)
                        }
                        .buttonStyle(.plain)
                    }
                    .transition(.opacity)
                } else {
                    Text(mmss(remaining))
                        .font(AppFonts.overline)
                        .tracking(2)
                        .foregroundStyle(AppColors.textTertiary)
                        .monospacedDigit()
                }
            }
            .animation((reduceMotion ? AppAnimation.fast : AppAnimation.standard),
                       value: store.timerElapsed)
            // 🎚️ soft chime at zero: haptic default (house idiom); Bryan may swap
            // for an audio chime on device.
            .sensoryFeedback(.impact(weight: .light), trigger: store.timerElapsed)
        }
    }

    private func mmss(_ t: TimeInterval) -> String {
        let s = Int(t.rounded())
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}
