//
//  RevealCardChrome.swift
//  Vayl
//
//  The special-card treatment for reveal-mechanic cards (spec §4.4): an
//  animated spectrum border + slow drifting sparks framing the reveal surface.
//  Reuses VaylBorderEffect + .spectrumBorderGlow — no new primitives.
//  Reduce Motion: border holds steady, sparks are stilled.
//

import SwiftUI

struct RevealCardChrome<Content: View>: View {

    /// Glow ramps up through the ceremony: composing 0.3 → countdown 1.0.
    let intensity: Double
    @ViewBuilder let content: Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathe = false

    var body: some View {
        content
            .padding(AppSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    .fill(AppColors.cardBg)
            )
            .overlay(
                GeometryReader { geo in
                    VaylBorderEffect(
                        width: geo.size.width,
                        height: geo.size.height,
                        cornerRadius: AppRadius.lg,
                        progress: 1.0,
                        glowIntensity: breathe ? intensity : intensity * 0.6,
                        hairlineVisible: false
                    )
                    .allowsHitTesting(false)
                }
            )
            .overlay(sparkField.allowsHitTesting(false))
            .spectrumBorderGlow(intensity: intensity * 0.5)
            .onAppear {
                guard !reduceMotion else { return }
                breathe = true
            }
            .ambientAnimation(
                .easeInOut(duration: AppAnimation.ambientPulse).repeatForever(autoreverses: true),
                value: breathe
            )
    }

    /// A sparse ring of sparks that drift with the breath. Stilled under
    /// Reduce Motion (breathe stays false → fixed positions).
    private var sparkField: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ForEach(0..<6, id: \.self) { i in
                let t = Double(i) / 6.0
                Text("✦")
                    .font(AppFonts.display(8, weight: .medium, relativeTo: .caption2))
                    .foregroundStyle(AppColors.spectrumText)
                    .opacity(0.25 + 0.35 * intensity)
                    .position(
                        x: w * (0.08 + 0.84 * t),
                        y: (i.isMultiple(of: 2) ? (breathe ? -6 : 2) : h + (breathe ? 6 : -2))
                    )
            }
        }
    }
}
