//
//  AuroraGlowField.swift
//  Open Lightly
//
//  Warm Aurora atmospheric blob field for light mode screens.
//  Near-verbatim copy of OnboardingGlowField with warm palette
//  swapped in and opacities raised ~1.8–2.2× to compensate
//  for cream (#F8F6EE) absorbing color vs dark (#030305) amplifying it.
//

import SwiftUI

// ─────────────────────────────────────────────
// MARK: Private palette
// File-scoped only. DO NOT add to AppColors.swift.
// ─────────────────────────────────────────────

private extension Color {
    static let auroraOrange = Color(hex: "E04A10")
    static let auroraWine   = Color(hex: "6B1030")
    static let auroraPink   = Color(hex: "D42060")
    static let auroraWineLo = Color(hex: "8A1430")
}

// ─────────────────────────────────────────────
// MARK: Aurora Configuration
// ─────────────────────────────────────────────

struct AuroraConfig: Equatable {
    var topOpacityMult:    Double
    var midOpacityMult:    Double
    var bottomOpacityMult: Double
    var globalOpacity:     Double

    static let statView = AuroraConfig(
        topOpacityMult: 1.0, midOpacityMult: 0.4,
        bottomOpacityMult: 1.15, globalOpacity: 0.85)

    static let nameView = AuroraConfig(
        topOpacityMult: 1.0, midOpacityMult: 0.1,
        bottomOpacityMult: 1.15, globalOpacity: 0.60)

    static let modeSelectView = AuroraConfig(
        topOpacityMult: 0.1, midOpacityMult: 0.3,
        bottomOpacityMult: 1.15, globalOpacity: 0.70)

    static let contextView = AuroraConfig(
        topOpacityMult: 0.4, midOpacityMult: 0.2,
        bottomOpacityMult: 0.85, globalOpacity: 0.50)

    static let curiosityPickerView = AuroraConfig(
        topOpacityMult: 0.3, midOpacityMult: 0.1,
        bottomOpacityMult: 0.75, globalOpacity: 0.40)

    static let groundRulesView = AuroraConfig(
        topOpacityMult: 0.15, midOpacityMult: 0.2,
        bottomOpacityMult: 1.05, globalOpacity: 0.50)
}

// ─────────────────────────────────────────────
// MARK: Aurora Glow Field
// ─────────────────────────────────────────────

struct AuroraGlowField: View {
    var config: AuroraConfig = .statView

    @State private var blobVisible: [Bool]    = Array(repeating: false, count: 7)
    @State private var blobPhase:   [CGFloat] = Array(repeating: 0,     count: 7)
    @State private var hasStarted = false

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let global = config.globalOpacity

            ZStack {
                // Orange — upper-left  (was: Cyan 0.32 → Orange 0.58)
                blob(.auroraOrange, 0.58 * config.topOpacityMult * global, 300, 280, 75, 0)
                    .offset(x: sin(blobPhase[0] * .pi * 2) * 12,
                            y: sin(blobPhase[0] * .pi * 2 + .pi / 3) * 14)
                    .position(x: w * 0.22, y: h * 0.20)

                // Deep Wine — center  (was: Purple 0.28 → Wine 0.55)
                blob(.auroraWine, 0.55 * config.midOpacityMult * global, 380, 360, 75, 1)
                    .scaleEffect(blobVisible[1] ? 1 + 0.06 * sin(blobPhase[1] * .pi * 2) : 0.7)
                    .offset(x: sin(blobPhase[1] * .pi * 2) * 4)
                    .position(x: w * 0.50, y: h * 0.40)

                // Hot Pink — right edge  (was: Magenta 0.24 → Pink 0.52)
                blob(.auroraPink, 0.52 * config.topOpacityMult * global, 280, 300, 75, 2)
                    .offset(x: sin(blobPhase[2] * .pi * 2) * -10,
                            y: cos(blobPhase[2] * .pi * 2) * 12)
                    .position(x: w * 0.88, y: h * 0.33)

                // Orange — warm accent  (was: GoldLight 0.12 → Orange 0.28)
                blob(.auroraOrange, 0.28 * config.midOpacityMult * global, 200, 180, 80, 3)
                    .offset(x: sin(blobPhase[3] * .pi) * 8,
                            y: sin(blobPhase[3] * .pi) * -6)
                    .position(x: w * 0.20, y: h * 0.48)

                // Wine lo — mid-left  (was: Magenta 0.15 → WineLo 0.38 → ×1.6 = 0.608)
                blob(.auroraWineLo, 0.608 * config.midOpacityMult * global, 300, 220, 85, 4)
                    .scaleEffect(blobVisible[4] ? 1 + 0.05 * sin(blobPhase[4] * .pi * 2) : 0.7)
                    .offset(x: sin(blobPhase[4] * .pi) * 8,
                            y: sin(blobPhase[4] * .pi) * -6)
                    .position(x: w * 0.18, y: h * 0.60)

                // Floor wash  (was: deepBlue/purple → auroraWine/auroraPink; ×1.6 = 0.352/0.224)
                Ellipse()
                    .fill(RadialGradient(stops: [
                        .init(color: Color.auroraWine.opacity(0.352 * config.bottomOpacityMult * global), location: 0),
                        .init(color: Color.auroraPink.opacity(0.224 * config.bottomOpacityMult * global), location: 0.4),
                        .init(color: .clear, location: 0.7)
                    ], center: .center, startRadius: 0, endRadius: 200))
                    .frame(width: 420, height: 180)
                    .blur(radius: 90)
                    .scaleEffect(blobVisible[5] ? 1 + 0.06 * sin(blobPhase[5] * .pi * 2) : 0.7)
                    .opacity(blobVisible[5] ? 1 : 0)
                    .offset(x: sin(blobPhase[5] * .pi * 2) * 4)
                    .position(x: w * 0.5, y: h * 0.80)

                // Orange — bottom accent  (was: Cyan 0.08 → Orange 0.18 → ×1.8 = 0.324)
                blob(.auroraOrange, 0.324 * config.bottomOpacityMult * global, 240, 150, 90, 6)
                    .offset(x: sin(blobPhase[6] * .pi * 2) * -8)
                    .position(x: w * 0.45, y: h * 0.88)
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

    // MARK: - Blob builder

    @ViewBuilder
    private func blob(_ color: Color, _ opacity: Double, _ w: CGFloat, _ h: CGFloat, _ blur: CGFloat, _ i: Int) -> some View {
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

    private func startAtmosphere() {
        let fadeDelays:    [Double] = [0.1, 0.2, 0.3, 0.35, 0.4,  0.5,  0.6]
        let fadeDurations: [Double] = [0.9, 1.0, 0.9, 1.0,  1.0,  1.2,  1.0]
        let loopDurations: [Double] = [8,   10,  9,   11,   12,   14,   10]
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

// ─────────────────────────────────────────────
// MARK: Previews
// ─────────────────────────────────────────────

#Preview("Dark") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        AuroraGlowField(config: .statView)
    }
    .preferredColorScheme(.dark)
}

#Preview("Light") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        AuroraGlowField(config: .statView)
    }
    .preferredColorScheme(.light)
}
