//
//  BreathGuide.swift
//  Vayl
//
//  The "Breathe together" ritual: a paced orb, inhale/exhale, a few cycles,
//  then hands back to the lock-in. Reduce Motion / Low Power never trap the
//  user in a timed sequence they can't see animate — they get a static orb
//  and a manual continue instead.
//

import SwiftUI

struct BreathGuide: View {

    var onComplete: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var expanded = false
    @State private var cycle = 0
    @State private var hint = "settle…"

    private var motionDisabled: Bool { reduceMotion || AppAnimation.lowPower }

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            orb
            Text(hint)
                .font(AppFonts.bodyMedium)
                .foregroundStyle(AppColors.textPrimary)

            if motionDisabled {
                Button(action: onComplete) {
                    Text("continue")
                        .font(AppFonts.buttonLabel)
                        .foregroundStyle(AppColors.textAccent)
                }
                .buttonStyle(.plain)
            }
        }
        .onAppear { if !motionDisabled { runCycle() } else { hint = "take a slow breath, together" } }
    }

    private var orb: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [AppColors.auraLightCyan, AppColors.auraCoreCyan, AppColors.auraDeepCyan],
                    center: .center, startRadius: 0, endRadius: 60
                )
            )
            .shadow(color: AppColors.auraGlowCyan, radius: 24)
            .frame(width: 112, height: 112)
            .scaleEffect(motionDisabled ? 0.85 : (expanded ? 1.08 : 0.72))
    }

    private func runCycle() {
        guard cycle < AppAnimation.breatheCycles else {
            hint = "there you are"
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(1.1))
                onComplete()
            }
            return
        }
        hint = "breathe in…"
        withAnimation(.easeInOut(duration: AppAnimation.breathePhase)) { expanded = true }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(AppAnimation.breathePhase))
            hint = "and out…"
            withAnimation(.easeInOut(duration: AppAnimation.breathePhase)) { expanded = false }
            try? await Task.sleep(for: .seconds(AppAnimation.breathePhase))
            cycle += 1
            runCycle()
        }
    }
}

// MARK: - Preview

#Preview("Breath Guide") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        BreathGuide { }
    }
    .preferredColorScheme(.dark)
}
