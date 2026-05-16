// LightModeShimmer.swift
// Open Lightly
//
// Rewritten to match HolographicShimmer's energy on cream surfaces.
//
// Key fixes vs original:
//   - Removed .multiply blend mode — was darkening colours into mud
//   - Added second diagonal pass at different speed — depth/foil feel
//   - Matched HolographicShimmer's normal compositing
//   - Kept warm palette (purple/magenta/gold) — no cyan on cream

import SwiftUI

struct LightModeShimmer: View {
    var duration: Double = 6
    var usePillColors: Bool = false

    @State private var phase1: CGFloat = 0   // primary horizontal sweep
    @State private var phase2: CGFloat = 0   // secondary diagonal sweep

    // Primary sweep — matches HolographicShimmer's colour slot count
    // and opacity range exactly. Only the hues differ (warm vs neon).
    private var primaryColors: [Color] {
        [
            AppColors.accentSecondary.opacity(0.55),
            AppColors.accentTertiary.opacity(0.60),
            AppColors.safetyAccent.opacity(0.55),
            AppColors.pulseTierProtective.opacity(0.58),
            AppColors.accentSecondary.opacity(0.55),
        ]
    }

    // Secondary pass — softer, offset palette
    // Sits on top of primary at lower opacity to create depth.
    // Diagonal start/end point fakes a 2D foil angle.
    private var secondaryColors: [Color] {
        [
            AppColors.safetyAccent.opacity(0.30),
            AppColors.accentSecondary.opacity(0.25),
            AppColors.accentTertiary.opacity(0.28),
            AppColors.safetyAccent.opacity(0.22),
            AppColors.pulseTierProtective.opacity(0.25),
        ]
    }

    // Background wash variant — same structure, lower opacity
    private var washColors: [Color] {
        AppColors.lightShimmerColors
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // ── Pass 1: primary horizontal sweep ─────────────────
                // Identical mechanics to HolographicShimmer.
                // No blend mode — normal compositing, colours at face value.
                LinearGradient(
                    colors: usePillColors ? primaryColors : washColors,
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: w * 3, height: h)
                .offset(x: phase1 * -w * 2)

                // ── Pass 2: secondary diagonal sweep (pills only) ─────
                // Offset diagonal gradient at 60% speed of primary.
                // Creates the illusion of depth — light catching a
                // different facet of the foil at a different angle.
                // Skipped for background wash — too busy on large surfaces.
                if usePillColors {
                    LinearGradient(
                        colors: secondaryColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: w * 3, height: h)
                    .offset(x: phase2 * -w * 2)
                    .blendMode(.screen)   // screen on cream = gentle brightening,
                                          // not the darkening that multiply caused
                }
            }
        }
        .clipped()
        .onAppear {
            // Primary sweep — same timing as HolographicShimmer
            withAnimation(
                .easeInOut(duration: usePillColors ? min(duration, 5.5) : duration)
                .repeatForever(autoreverses: true)
            ) {
                phase1 = 1
            }

            // Secondary sweep — 60% speed, starts offset so
            // the two passes are never in sync (avoids strobing)
            withAnimation(
                .easeInOut(duration: usePillColors ? min(duration, 5.5) * 1.65 : duration * 1.4)
                .repeatForever(autoreverses: true)
                .delay(0.8)
            ) {
                phase2 = 1
            }
        }
    }
}
