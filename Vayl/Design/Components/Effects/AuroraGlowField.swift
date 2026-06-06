//
//  AuroraGlowField.swift
//  Open Lightly
//
//  Warm Aurora atmospheric blob field for light mode screens.
//  Near-verbatim copy of OnboardingAtmosphere with warm palette
//  swapped in and opacities raised ~1.8–2.2× to compensate
//  for cream (#F8F6EE) absorbing color vs dark (#030305) amplifying it.
//

import SwiftUI

// ─────────────────────────────────────────────
// MARK: Private palette
// File-scoped only. DO NOT add to AppColors.swift.
// ─────────────────────────────────────────────

// These are intentional file-scoped effect colors — do NOT replace with
// AppColors.auroraBlob tokens. auroraBlob tokens have opacity pre-baked;
// these are raw base colors with opacity applied dynamically by the renderer.
// Reviewed and approved: April 20, 2026

private extension Color {
    static let auroraOrange  = Color(hex: "E04A10")
    static let auroraWine    = Color(hex: "6B1030")
    static let auroraPink    = Color(hex: "D42060")
    static let auroraWineLo  = Color(hex: "8A1430")
    // CHANGE (v2): Added purple — required for brandView gradient harmony.
    // Purple bridges the gap between wine/pink and gold in the brand palette.
    static let auroraPurple  = Color(hex: "6B28AA")
    // CHANGE (v2): Added gold — brandView uses magenta→orange→gold arc.
    static let auroraGold    = Color(hex: "E8A020")
}

// ─────────────────────────────────────────────
// MARK: Aurora Configuration
// ─────────────────────────────────────────────

struct AuroraConfig: Equatable {
    var topOpacityMult:    Double
    var midOpacityMult:    Double
    var bottomOpacityMult: Double
    var globalOpacity:     Double

    // CHANGE (v2): Added brandView config.
    // Heavy top-right (gold/orange) + strong left (purple/pink) +
    // fading bottom. Mirrors the asymmetric distribution in the mockup.
    // globalOpacity 0.78 — slightly under statView (0.85) because the
    // brand screen has a filament orbit that already contributes color
    // energy. Aurora should be atmospheric, not competing.
    static let brandView = AuroraConfig(
        topOpacityMult:    1.0,
        midOpacityMult:    0.35,
        bottomOpacityMult: 0.70,
        globalOpacity: 0.88
    )

    static let statView = AuroraConfig(
        topOpacityMult: 1.0, midOpacityMult: 0.4,
        bottomOpacityMult: 1.15, globalOpacity: 1.0)

    static let nameView = AuroraConfig(
        topOpacityMult: 1.0, midOpacityMult: 0.1,
        bottomOpacityMult: 1.15, globalOpacity: 0.85)

    static let modeSelectView = AuroraConfig(
        topOpacityMult: 0.1, midOpacityMult: 0.3,
        bottomOpacityMult: 1.15, globalOpacity: 0.90)

    static let contextView = AuroraConfig(
        topOpacityMult: 0.4, midOpacityMult: 0.2,
        bottomOpacityMult: 0.85, globalOpacity: 0.75)

    static let curiosityPickerView = AuroraConfig(
        topOpacityMult: 0.3, midOpacityMult: 0.1,
        bottomOpacityMult: 0.75, globalOpacity: 0.65)

    static let groundRulesView = AuroraConfig(
        topOpacityMult: 0.15, midOpacityMult: 0.2,
        bottomOpacityMult: 1.05, globalOpacity: 0.75)
}

// ─────────────────────────────────────────────
// MARK: Aurora Glow Field
// ─────────────────────────────────────────────

struct AuroraGlowField: View {
    var config: AuroraConfig = .statView

    @State private var blobVisible: [Bool]    = Array(repeating: false, count: 9)
    @State private var blobPhase:   [CGFloat] = Array(repeating: 0,     count: 9)
    @State private var hasStarted = false

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let global = config.globalOpacity

            ZStack {
                topTier(w: w, h: h, global: global)
                midTier(w: w, h: h, global: global)
                lowerTier(w: w, h: h, global: global)
            }
        }
        .allowsHitTesting(false)
        .animation(.easeInOut(duration: 1.0), value: config)
        .onAppear {
            guard !hasStarted else { return }
            hasStarted = true
            startAtmosphere()
        }
    }

    // MARK: - Tiers
    // Split from `body` so each group is type-checked in isolation — the inline
    // 10-blob ZStack with per-blob sin offsets was 210ms.

    @ViewBuilder
    private func topTier(w: CGFloat, h: CGFloat, global: Double) -> some View {
        // Gold — dominant top-right
        blob(.auroraGold, 0.82 * config.topOpacityMult * global, 340, 280, 80, 0)
            .offset(
                x: sin(blobPhase[0] * .pi * 2) * 14,
                y: sin(blobPhase[0] * .pi * 2 + .pi / 3) * 10
            )
            .position(x: w * 0.78, y: h * 0.14)

        // Pink — strong top-left
        blob(.auroraPink, 0.76 * config.topOpacityMult * global, 280, 240, 72, 1)
            .offset(
                x: sin(blobPhase[1] * .pi * 2) * -10,
                y: sin(blobPhase[1] * .pi * 2 + .pi / 4) * 12
            )
            .position(x: w * 0.18, y: h * 0.17)
    }

    @ViewBuilder
    private func midTier(w: CGFloat, h: CGFloat, global: Double) -> some View {
        // Purple — center-right
        blob(.auroraPurple, 0.70 * config.midOpacityMult * global, 300, 260, 78, 2)
            .scaleEffect(
                blobVisible[2]
                    ? 1 + 0.05 * sin(blobPhase[2] * .pi * 2)
                    : 0.7
            )
            .offset(x: sin(blobPhase[2] * .pi * 2) * 8)
            .position(x: w * 0.80, y: h * 0.36)

        // Wine — center-left
        blob(.auroraWine, 0.67 * config.midOpacityMult * global, 320, 280, 78, 3)
            .scaleEffect(
                blobVisible[3]
                    ? 1 + 0.06 * sin(blobPhase[3] * .pi * 2)
                    : 0.7
            )
            .offset(x: sin(blobPhase[3] * .pi * 2) * 5)
            .position(x: w * 0.28, y: h * 0.40)

        // Orange — warm mid accent
        blob(.auroraOrange, 0.42 * config.midOpacityMult * global, 200, 180, 80, 4)
            .offset(
                x: sin(blobPhase[4] * .pi) * 8,
                y: sin(blobPhase[4] * .pi) * -6
            )
            .position(x: w * 0.55, y: h * 0.50)
    }

    @ViewBuilder
    private func lowerTier(w: CGFloat, h: CGFloat, global: Double) -> some View {
        // WineLo — lower left
        blob(.auroraWineLo, 0.67 * config.midOpacityMult * global, 280, 200, 85, 5)
            .scaleEffect(
                blobVisible[5]
                    ? 1 + 0.05 * sin(blobPhase[5] * .pi * 2)
                    : 0.7
            )
            .offset(
                x: sin(blobPhase[5] * .pi) * 8,
                y: sin(blobPhase[5] * .pi) * -5
            )
            .position(x: w * 0.22, y: h * 0.64)

        // Floor wash — wide radial sweep across bottom
        Ellipse()
            .fill(RadialGradient(
                stops: [
                    .init(
                        color: Color.auroraWine.opacity(
                            0.48 * config.bottomOpacityMult * global
                        ),
                        location: 0
                    ),
                    .init(
                        color: Color.auroraPink.opacity(
                            0.28 * config.bottomOpacityMult * global
                        ),
                        location: 0.4
                    ),
                    .init(color: .clear, location: 0.7)
                ],
                center: .center,
                startRadius: 0,
                endRadius: 200
            ))
            .frame(width: 420, height: 180)
            .blur(radius: 90)
            .scaleEffect(
                blobVisible[6]
                    ? 1 + 0.06 * sin(blobPhase[6] * .pi * 2)
                    : 0.7
            )
            .opacity(blobVisible[6] ? 1 : 0)
            .offset(x: sin(blobPhase[6] * .pi * 2) * 4)
            .position(x: w * 0.5, y: h * 0.86)

        // Orange — bottom accent
        blob(.auroraOrange, 0.35 * config.bottomOpacityMult * global, 220, 140, 88, 7)
            .offset(x: sin(blobPhase[7] * .pi * 2) * -8)
            .position(x: w * 0.46, y: h * 0.91)

        // Gold — bottom-right faint accent
        blob(.auroraGold, 0.26 * config.bottomOpacityMult * global, 200, 140, 85, 8)
            .offset(x: sin(blobPhase[8] * .pi * 2) * 6)
            .position(x: w * 0.80, y: h * 0.88)
    }

    // MARK: - Blob builder

    @ViewBuilder
    private func blob(
        _ color: Color,
        _ opacity: Double,
        _ w: CGFloat,
        _ h: CGFloat,
        _ blur: CGFloat,
        _ i: Int
    ) -> some View {
        Ellipse()
            .fill(RadialGradient(
                stops: [
                    .init(color: color.opacity(opacity),        location: 0.20),
                    .init(color: color.opacity(opacity * 0.55), location: 0.55),
                    .init(color: .clear,                        location: 1.0)
                ],
                center: .center,
                startRadius: 0,
                endRadius: max(w, h) / 2
            ))
            .frame(width: w, height: h)
            .blur(radius: blur)
            .scaleEffect(blobVisible[i] ? 1.0 : 0.7)
            .opacity(blobVisible[i] ? 1 : 0)
    }

    // MARK: - Animation orchestration
    //
    // CHANGE (v2): Extended from 7 blobs → 9 blobs.
    // Two new entries appended to all arrays (indices 7, 8).
    // Phase-drifted durations prevent synchronization across blobs.

    private func startAtmosphere() {
        let fadeDelays:    [Double] = [0.10, 0.20, 0.30, 0.35, 0.40, 0.50, 0.60, 0.65, 0.70]
        let fadeDurations: [Double] = [0.90, 1.00, 0.90, 1.00, 1.00, 1.20, 1.00, 1.00, 1.10]
        let loopDurations: [Double] = [8,    10,   9,    11,   12,   14,   10,   13,   11  ]
        let loopDelays:    [Double] = [0.80, 1.00, 1.20, 1.30, 1.50, 1.60, 1.80, 1.90, 2.00]

        for i in 0..<9 {
            withAnimation(
                .easeInOut(duration: fadeDurations[i])
                .delay(fadeDelays[i])
            ) {
                blobVisible[i] = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + loopDelays[i]) {
                withAnimation(
                    .linear(duration: loopDurations[i])
                    .repeatForever(autoreverses: false)
                ) {
                    blobPhase[i] = 1.0
                }
            }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: Previews
// ─────────────────────────────────────────────

#Preview("Brand View — Light") {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        AuroraGlowField(config: .brandView)
    }
    .preferredColorScheme(.light)
}

#Preview("Stat View — Light") {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        AuroraGlowField(config: .statView)
    }
    .preferredColorScheme(.light)
}

#Preview("Stat View — Dark") {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        AuroraGlowField(config: .statView)
    }
    .preferredColorScheme(.dark)
}
