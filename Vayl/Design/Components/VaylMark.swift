//
//  VaylMark.swift
//  Vayl
//
//  The Vayl mark — a nested-diamond "aperture" (a portal you look through; Vayl ≈ veil)
//  rendered in the canonical spectrumBorder glow language: a thin spectrum-gradient stroke
//  + the 3-layer .spectrumBorderGlow + a lit core, on void. Reuses AppColors.spectrumBorder
//  and the existing glow modifier — no new tokens. Replaces the placeholder "champion star"
//  and scales as an accent across the app (waiting card centre, card backs, etc.).
//
//  Geometry is tunable on device: ringCount, concavity (diamond ↔ sharp star), stroke weight,
//  glow strength. Settle the feel here before wiring it into surfaces.
//

import SwiftUI

// MARK: - Aperture ring
// One 4-point concave-diamond ring: tips at N/E/S/W with the sides bowed toward the centre.
// `concavity` 0 = a plain diamond, ~0.8 = a sharp star. `scale` is the fraction of the frame.

struct ApertureRing: Shape {
    var scale: CGFloat = 1
    var concavity: CGFloat = 0.78

    var animatableData: CGFloat {
        get { concavity }
        set { concavity = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2 * scale
        let n = CGPoint(x: c.x, y: c.y - r)
        let e = CGPoint(x: c.x + r, y: c.y)
        let s = CGPoint(x: c.x, y: c.y + r)
        let w = CGPoint(x: c.x - r, y: c.y)

        // A side's control point: its midpoint pulled toward the centre by `concavity`.
        func control(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
            let mid = CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
            return CGPoint(x: mid.x + (c.x - mid.x) * concavity,
                           y: mid.y + (c.y - mid.y) * concavity)
        }

        var p = Path()
        p.move(to: n)
        p.addQuadCurve(to: e, control: control(n, e))
        p.addQuadCurve(to: s, control: control(e, s))
        p.addQuadCurve(to: w, control: control(s, w))
        p.addQuadCurve(to: n, control: control(w, n))
        p.closeSubpath()
        return p
    }
}

// MARK: - Vayl mark

struct VaylMark: View {
    /// Nested rings, outer → inner. 1 = a single star.
    var ringCount: Int = 3
    /// Side concavity: 0 = diamond, ~0.8 = sharp star.
    var concavity: CGFloat = 0.78
    /// Crisp stroke weight as a fraction of the mark size (keeps the weight proportional).
    var strokeFraction: CGFloat = 0.013
    /// Glow strength (0...1) driving `.spectrumBorderGlow`.
    var glow: Double = 1.0
    /// The lit centre core (the point "behind the veil").
    var showsCore: Bool = true

    var body: some View {
        GeometryReader { geo in
            let dim = min(geo.size.width, geo.size.height)
            let lineWidth = max(1, dim * strokeFraction)
            let rings = max(1, ringCount)

            ZStack {
                // Nested rings, glowed once as a group so the halo reads cohesive.
                ZStack {
                    ForEach(0..<rings, id: \.self) { i in
                        let t = rings <= 1 ? 0 : CGFloat(i) / CGFloat(rings - 1)
                        let scale = 1.0 - t * 0.66          // outer 1.0 → inner ~0.34
                        ApertureRing(scale: scale, concavity: concavity)
                            .stroke(
                                AppColors.spectrumBorder,
                                style: StrokeStyle(lineWidth: lineWidth, lineJoin: .round)
                            )
                    }
                }
                .spectrumBorderGlow(intensity: glow)

                if showsCore {
                    Circle()
                        .fill(AppColors.textPrimary)
                        .frame(width: dim * 0.05, height: dim * 0.05)
                        .spectrumBorderGlow(intensity: glow)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

// MARK: - Previews

#Preview("Vayl mark — sizes on void") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        OnboardingAtmosphere(config: .cardReveal).ignoresSafeArea()

        VStack(spacing: AppSpacing.xxl) {
            VaylMark()
                .frame(width: 150, height: 150)

            HStack(spacing: AppSpacing.xl) {
                VaylMark()
                    .frame(width: 56, height: 56)
                VaylMark(ringCount: 2, strokeFraction: 0.03)
                    .frame(width: 28, height: 28)
            }
        }
    }
}

#Preview("Vayl mark — in the waiting card") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        OnboardingAtmosphere(config: .cardReveal).ignoresSafeArea()

        VStack(spacing: AppSpacing.md) {
            VaylMark()
                .frame(width: 76, height: 76)
            Text("That's yours now")
                .font(AppFonts.cardTitle)
                .foregroundStyle(AppColors.textPrimary)
            Text("When Alex finishes theirs,\nyou'll see where you align.")
                .font(AppFonts.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(AppSpacing.xl)
        .vaylGlassCard()
        .padding(AppSpacing.xl)
    }
}
