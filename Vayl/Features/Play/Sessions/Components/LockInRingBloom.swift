//
//  LockInRingBloom.swift
//  Vayl
//
//  The airlock's vivid resting ring — the mock's "Us" ring. A visual layer
//  placed BEHIND the functional lock-in ring (SyncLockInRing) as its
//  `.background`: it supplies the resting gradient + glow halo + core dot
//  the mock shows at focal, while the functional ring keeps its press-to-arm
//  fill mechanic on top. This is the "touch the ring" the mock needs WITHOUT
//  editing the protected two-device sync ring's logic — it's a sibling layer.
//
//  `bloomed` crossfades the latent ring (dim cyan→violet, the Us not yet formed)
//  into the bloomed ring (full cyan→purple→magenta, the emergent Us). The glow
//  halo and core dot breathe; both are Reduce-Motion / Low-Power gated (ambient).
//  The bloom crossfade itself is a one-shot reactive tied to the entrance.
//

import SwiftUI

struct LockInRingBloom: View {

    /// Latent (false) vs the emergent Us (true). Driven by the airlock entrance.
    var bloomed: Bool
    /// Must match the functional ring's `ringSize` so the two align as a unit.
    var ringSize: CGFloat = AppLayout.lockInRingSize

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The living breath of the focal ring: the glow pulses in size AND intensity
    /// on the `auraBreathe` tempo (a real presence, not inert chrome). One shared
    /// Bool toggled once on appear; the bloom crossfade (keyed on `bloomed`) and
    /// the breath (keyed on `breathe`) drive opacity off DIFFERENT values, so they
    /// never fight (Animation Feel Contract). Gated off under Reduce Motion / LPM.
    @State private var breathe = false

    private var scale: CGFloat { ringSize / AppLayout.lockInRingSize }

    /// Diagonal cyan→violet, NO magenta: the Us has not formed yet.
    private var latentStroke: LinearGradient {
        LinearGradient(
            colors: [AppColors.spectrumCyan.opacity(0.7), AppColors.spectrumPurple.opacity(0.7)],
            startPoint: .bottomLeading, endPoint: .topTrailing)
    }

    /// Full diagonal cyan→purple→magenta: the emergent Us, matching the mock.
    private var bloomStroke: LinearGradient {
        LinearGradient(
            colors: [AppColors.spectrumCyan, AppColors.spectrumPurple, AppColors.spectrumMagenta],
            startPoint: .bottomLeading, endPoint: .topTrailing)
    }

    var body: some View {
        ZStack {
            // Glow — a blurred copy of the bloomed ring, hugging it so the result
            // reads as ONE ring plus its halo (no inner disc). It BREATHES: the
            // halo pulses in size + intensity on the auraBreathe tempo, so the
            // focal ring feels alive. Two-pass stroke recipe.
            Circle()
                .stroke(bloomStroke, style: StrokeStyle(lineWidth: 7 * scale))
                .blur(radius: 8)
                .scaleEffect(breathe ? 1.09 : 1.0)
                .opacity(bloomed ? (breathe ? 0.62 : 0.32) : 0)
                .animation(AppAnimation.airlockConverge.reduceMotionSafe, value: bloomed)
                .ambientAnimation(
                    .easeInOut(duration: AppAnimation.auraBreathe).repeatForever(autoreverses: true),
                    value: breathe)

            // Latent ring — cyan→violet, dim. Fades out as the Us blooms.
            Circle()
                .stroke(latentStroke, style: StrokeStyle(lineWidth: 1.6 * scale))
                .opacity(bloomed ? 0 : 0.5)
                .animation(AppAnimation.airlockConverge.reduceMotionSafe, value: bloomed)

            // Bloomed ring — the single crisp full-spectrum ring, the emergent Us.
            // FEEL-GATE: crisp stroke weight bumped 2.4 → 3.4 toward the mock's
            // proportionally heavier "Us" ring (docs/mockups/airlock-lock-in.html).
            Circle()
                .stroke(bloomStroke, style: StrokeStyle(lineWidth: 3.4 * scale))
                .opacity(bloomed ? 0.95 : 0)
                .animation(AppAnimation.airlockConverge.reduceMotionSafe, value: bloomed)

            // Core dot — the mock's small breathing white point at focal. A crisp
            // dot over a soft blurred sibling (glow via blur, never .shadow()). It
            // fades in with the bloom crossfade and breathes on the living tempo;
            // the breath is inherited-gated (breathe is set only when
            // !reduceMotion && !lowPower). Two opacity sources drive off DIFFERENT
            // values (bloomed vs breathe) so they never fight.
            ZStack {
                Circle()
                    .fill(AppColors.textPrimary)
                    .frame(width: 10 * scale, height: 10 * scale)
                    .blur(radius: 4)
                    .opacity(bloomed ? (breathe ? 0.35 : 0.15) : 0)
                    .animation(AppAnimation.airlockConverge.reduceMotionSafe, value: bloomed)

                Circle()
                    .fill(AppColors.textPrimary)
                    .frame(width: 5 * scale, height: 5 * scale)
                    .opacity(bloomed ? (breathe ? 0.7 : 0.3) : 0)
                    .animation(AppAnimation.airlockConverge.reduceMotionSafe, value: bloomed)
            }
            .scaleEffect(breathe ? 1.1 : 0.85)
            .ambientAnimation(
                .easeInOut(duration: AppAnimation.auraBreathe).repeatForever(autoreverses: true),
                value: breathe)
        }
        .frame(width: ringSize, height: ringSize)
        .onAppear {
            guard !reduceMotion, !AppAnimation.lowPower else { return }
            breathe = true
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Preview

#Preview("Lock-in ring bloom") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        OnboardingAtmosphere(config: .stat).ignoresSafeArea()
        VStack(spacing: AppSpacing.xxl) {
            LockInRingBloom(bloomed: false)
            LockInRingBloom(bloomed: true)
        }
    }
    .preferredColorScheme(.dark)
}
