//
//  DealPointView.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/9/26.
//

//
//  DealPointView.swift
//  Vayl
//

// Features/Onboarding/Renderers/DealPointView.swift

import SwiftUI

/// The deal point — the origin from which all OB cards are launched.
/// Positioned at tableHorizonYFrac. Intensity driven by VaylDirector.
/// This view never responds to gestures and never holds state.
struct DealPointView: View {
    let intensity: Double
    let screenSize: CGSize

    // ── Proportional geometry ─────────────────────────────────
    // Everything scales from AppLayout.dealPointRadius (the glow-ring
    // radius) — no fixed pixels, per the OB proportional-geometry rule.
    // The fractions below are rendering constants, not layout tokens.

    /// Ring radius — the deal point's defining circle.
    private var ringRadius: CGFloat { AppLayout.dealPointRadius }

    /// 2.8× ring — outer haze reach. The warm lamp spill around the point.
    private var hazeRadius: CGFloat { ringRadius * 2.8 }

    /// 0.07× ring (~1.5pt) — crisp micro-ring stroke.
    private var ringLineCrisp: CGFloat { ringRadius * 0.07 }

    /// 0.16× ring (~3.5pt) — blurred glow pass beneath the crisp stroke.
    private var ringLineGlow: CGFloat { ringRadius * 0.16 }

    /// 0.28× ring (~6pt) — blur radius of the glow pass.
    private var ringGlowBlur: CGFloat { ringRadius * 0.28 }

    /// 0.18× ring (~4pt) — center dot radius. The ember at the origin.
    private var dotRadius: CGFloat { ringRadius * 0.18 }

    var body: some View {
        ZStack {
            // ── Outer warm amber haze ─────────────────────────
            // Same overhead-lamp amber as the table's pool
            // (AppColors.tableAmberPool — the deal point sits at the
            // center of that same lamp). Alpha is baked into the token;
            // the radial falloff carries it to transparent.
            Circle()
                .fill(
                    RadialGradient(
                        stops: [
                            .init(color: AppColors.tableAmberPool, location: 0.00),
                            .init(color: AppColors.tableAmberPool.opacity(0.45), location: 0.45),
                            .init(color: AppColors.tableAmberPool.opacity(0), location: 1.00)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: hazeRadius
                    )
                )
                .frame(width: hazeRadius * 2, height: hazeRadius * 2)

            // ── Spectrum micro-ring — glow pass ───────────────
            // Two-pass stroke per OB card face rules: blurred low-opacity
            // glow beneath, crisp stroke on top. Spectrum gradient on the
            // stroke via the universal spectrumBorder token.
            Circle()
                .stroke(AppColors.spectrumBorder, lineWidth: ringLineGlow)
                .frame(width: ringRadius * 2, height: ringRadius * 2)
                .blur(radius: ringGlowBlur)
                .opacity(0.55)

            // ── Spectrum micro-ring — crisp pass ──────────────
            Circle()
                .stroke(AppColors.spectrumBorder, lineWidth: ringLineCrisp)
                .frame(width: ringRadius * 2, height: ringRadius * 2)

            // ── Center amber dot ──────────────────────────────
            // Warm ember at the origin: cream-hot core (the table's
            // compass-star warm white) falling off through the lamp
            // amber to transparent — reads amber inside the haze.
            Circle()
                .fill(
                    RadialGradient(
                        stops: [
                            .init(color: AppColors.tableCompassStar, location: 0.00),
                            .init(color: AppColors.tableAmberPool, location: 0.62),
                            .init(color: AppColors.tableAmberPool.opacity(0), location: 1.00)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: dotRadius
                    )
                )
                .frame(width: dotRadius * 2, height: dotRadius * 2)
        }
        // Intensity is the single driver (VaylDirector) — one opacity,
        // one animation, no competing properties.
        .opacity(intensity)
        .position(
            x: screenSize.width  * 0.50,
            y: screenSize.height * AppLayout.dealPointYFrac
        )
        .animation(AppAnimation.standard, value: intensity)
        .allowsHitTesting(false)
    }
}
