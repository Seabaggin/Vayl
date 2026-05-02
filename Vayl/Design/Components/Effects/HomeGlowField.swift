// HomeGlowField.swift
// Open Lightly
//
// Full-page atmospheric background for HomeDashboardView.
// morphProgress 0.0 = glow blobs (identical to OnboardingGlowField).
// morphProgress 1.0 = deep space galaxy (dark gradient + stars + blooms).
// Crossfades smoothly between states as the user scrolls to the constellation.

import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Star model
// ─────────────────────────────────────────────────────────────────────────────

private struct GlowStar: Identifiable {
    let id:      Int
    let x:       CGFloat
    let y:       CGFloat
    let r:       CGFloat
    let opacity: Double
    let speed:   Double
}

private let glowStars: [GlowStar] = (0..<130).map { i in
    GlowStar(
        id:      i,
        x:       CGFloat.random(in: 0...1),
        y:       CGFloat.random(in: 0...1),
        r:       CGFloat.random(in: 0.25...2.2),
        opacity: Double.random(in: 0.12...0.70),
        speed:   Double.random(in: 26...58)
    )
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Galaxy star layer
// ─────────────────────────────────────────────────────────────────────────────

private struct GalaxyStarLayer: View {
    let opacity: Double
    @State private var drift = false

    var body: some View {
        GeometryReader { geo in
            ForEach(glowStars) { star in
                Circle()
                    .fill(Color.white.opacity(star.opacity * opacity))
                    .frame(width: star.r * 2, height: star.r * 2)
                    .position(
                        x: star.x * geo.size.width,
                        y: star.y * geo.size.height + (drift ? -42 : 0)
                    )
                    .animation(
                        .linear(duration: star.speed)
                        .repeatForever(autoreverses: true)
                        .delay(star.speed * Double(star.x) * 0.25),
                        value: drift
                    )
            }
        }
        .allowsHitTesting(false)
        .onAppear { drift = true }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - HomeGlowField
// ─────────────────────────────────────────────────────────────────────────────

struct HomeGlowField: View {

    /// 0.0 = full glow-blob atmosphere
    /// 1.0 = full deep-space galaxy
    var morphProgress: CGFloat = 0

    @State private var blobVisible: [Bool]    = Array(repeating: false, count: 7)
    @State private var blobPhase:   [CGFloat] = Array(repeating: 0,     count: 7)
    @State private var hasStarted             = false

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {

                // ── Layer A: Glow blobs — lingers until 60% through transition ──
                ZStack {
                    blob(AppColors.accentPrimary,      0.32, 300, 280, 75, 0)
                        .offset(x: sin(blobPhase[0] * .pi * 2) * 12,
                                y: sin(blobPhase[0] * .pi * 2 + .pi / 3) * 14)
                        .position(x: w * 0.22, y: h * 0.20)

                    blob(AppColors.accentSecondary, 0.28, 380, 360, 75, 1)
                        .scaleEffect(blobVisible[1] ? 1 + 0.06 * sin(blobPhase[1] * .pi * 2) : 0.7)
                        .offset(x: sin(blobPhase[1] * .pi * 2) * 4)
                        .position(x: w * 0.50, y: h * 0.40)

                    blob(AppColors.accentTertiary, 0.24, 280, 300, 75, 2)
                        .offset(x: sin(blobPhase[2] * .pi * 2) * -10,
                                y: cos(blobPhase[2] * .pi * 2) * 12)
                        .position(x: w * 0.88, y: h * 0.33)

                    blob(AppColors.safetyAccent, 0.12, 200, 180, 80, 3)
                        .offset(x: sin(blobPhase[3] * .pi) * 8,
                                y: sin(blobPhase[3] * .pi) * -6)
                        .position(x: w * 0.20, y: h * 0.48)

                    blob(AppColors.accentTertiary, 0.15, 300, 220, 85, 4)
                        .scaleEffect(blobVisible[4] ? 1 + 0.05 * sin(blobPhase[4] * .pi * 2) : 0.7)
                        .offset(x: sin(blobPhase[4] * .pi) * 8,
                                y: sin(blobPhase[4] * .pi) * -6)
                        .position(x: w * 0.18, y: h * 0.60)

                    Ellipse()
                        .fill(RadialGradient(stops: [
                            .init(color: AppColors.accentSecondary.opacity(0.12), location: 0),
                            .init(color: AppColors.accentSecondary.opacity(0.08),   location: 0.4),
                            .init(color: .clear,                           location: 0.7),
                        ], center: .center, startRadius: 0, endRadius: 200))
                        .frame(width: 420, height: 180)
                        .blur(radius: 90)
                        .scaleEffect(blobVisible[5] ? 1 + 0.06 * sin(blobPhase[5] * .pi * 2) : 0.7)
                        .opacity(blobVisible[5] ? 1 : 0)
                        .offset(x: sin(blobPhase[5] * .pi * 2) * 4)
                        .position(x: w * 0.5, y: h * 0.80)

                    blob(AppColors.accentPrimary, 0.08, 240, 150, 90, 6)
                        .offset(x: sin(blobPhase[6] * .pi * 2) * -8)
                        .position(x: w * 0.45, y: h * 0.88)
                }
                .opacity(Double(1.0 - morphProgress))

                // ── Layer B: Deep space galaxy — fades in ────────────
                ZStack {
                    LinearGradient(
                        colors: [
                            Color(hex: "0C0820"),
                            Color(hex: "060312"),
                            Color(hex: "030305"),
                        ],
                        startPoint: .init(x: 0.42, y: 0.0),
                        endPoint:   .bottomTrailing
                    )

                    Ellipse()
                        .fill(RadialGradient(
                            colors: [
                                AppColors.accentSecondary.opacity(0.26),
                                AppColors.accentSecondary.opacity(0.12),
                                Color.clear,
                            ],
                            center:      .init(x: 0.45, y: 0.35),
                            startRadius: 0,
                            endRadius:   320
                        ))
                        .blur(radius: 80)

                    Ellipse()
                        .fill(RadialGradient(
                            colors: [AppColors.accentTertiary.opacity(0.12), Color.clear],
                            center:      .init(x: 0.85, y: 0.30),
                            startRadius: 0,
                            endRadius:   200
                        ))
                        .blur(radius: 60)

                    Ellipse()
                        .fill(RadialGradient(
                            colors: [AppColors.accentPrimary.opacity(0.09), Color.clear],
                            center:      .init(x: 0.15, y: 0.70),
                            startRadius: 0,
                            endRadius:   160
                        ))
                        .blur(radius: 50)

                    GalaxyStarLayer(opacity: Double(morphProgress))
                }
                .opacity(Double(morphProgress))
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            guard !hasStarted else { return }
            hasStarted = true
            startAtmosphere()
        }
    }

    // ─────────────────────────────────────────────────
    // MARK: Blob builder
    // ─────────────────────────────────────────────────

    @ViewBuilder
    private func blob(
        _ color:   Color,
        _ opacity: Double,
        _ w:       CGFloat,
        _ h:       CGFloat,
        _ blur:    CGFloat,
        _ i:       Int
    ) -> some View {
        Ellipse()
            .fill(color.opacity(opacity))
            .frame(width: w, height: h)
            .blur(radius: blur)
            .scaleEffect(blobVisible[i] ? 1.0 : 0.7)
            .opacity(blobVisible[i] ? 1 : 0)
    }

    // ─────────────────────────────────────────────────
    // MARK: Animation orchestration
    // ─────────────────────────────────────────────────

    private func startAtmosphere() {
        let fadeDelays:    [Double] = [0.1, 0.2, 0.3, 0.35, 0.4,  0.5,  0.6]
        let fadeDurations: [Double] = [0.9, 1.0, 0.9, 1.0,  1.0,  1.2,  1.0]
        let loopDurations: [Double] = [8,   10,  9,   11,   12,   14,   10  ]
        let loopDelays:    [Double] = [0.8, 1.0, 1.2, 1.3,  1.5,  1.6,  1.8]

        for i in 0..<7 {
            withAnimation(.easeInOut(duration: fadeDurations[i]).delay(fadeDelays[i])) {
                blobVisible[i] = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + loopDelays[i]) {
                withAnimation(.linear(duration: loopDurations[i]).repeatForever(autoreverses: false)) {
                    blobPhase[i] = 1.0
                }
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Previews
// ─────────────────────────────────────────────────────────────────────────────

#Preview("Glow blobs — morphProgress 0") {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        HomeGlowField(morphProgress: 0)
    }
}

#Preview("Mid morph — morphProgress 0.5") {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        HomeGlowField(morphProgress: 0.5)
    }
}

#Preview("Full galaxy — morphProgress 1") {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        HomeGlowField(morphProgress: 1.0)
    }
}
