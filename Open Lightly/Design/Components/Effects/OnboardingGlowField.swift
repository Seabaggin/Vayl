// OnboardingGlowField.swift
// Open Lightly
//
// Atmospheric glow blob field shared across all onboarding screens.
// Extracted from OnboardingNameView's inline glowField implementation.
// Usage: OnboardingGlowField() — manages its own animation state.
import SwiftUI

struct OnboardingGlowField: View {
    @State private var blobVisible: [Bool]    = Array(repeating: false, count: 7)
    @State private var blobPhase:   [CGFloat] = Array(repeating: 0,     count: 7)
    @State private var hasStarted = false

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                // Cyan — upper-left
                blob(AppColors.cyan, 0.32, 300, 280, 75, 0)
                    .offset(x: sin(blobPhase[0] * .pi * 2) * 12,
                            y: sin(blobPhase[0] * .pi * 2 + .pi / 3) * 14)
                    .position(x: w * 0.22, y: h * 0.20)

                // Purple — center
                blob(AppColors.purple, 0.28, 380, 360, 75, 1)
                    .scaleEffect(blobVisible[1] ? 1 + 0.06 * sin(blobPhase[1] * .pi * 2) : 0.7)
                    .offset(x: sin(blobPhase[1] * .pi * 2) * 4)
                    .position(x: w * 0.50, y: h * 0.40)

                // Magenta — right edge
                blob(AppColors.magenta, 0.24, 280, 300, 75, 2)
                    .offset(x: sin(blobPhase[2] * .pi * 2) * -10,
                            y: cos(blobPhase[2] * .pi * 2) * 12)
                    .position(x: w * 0.88, y: h * 0.33)

                // Gold — warm accent
                blob(AppColors.goldLight, 0.12, 200, 180, 80, 3)
                    .offset(x: sin(blobPhase[3] * .pi) * 8,
                            y: sin(blobPhase[3] * .pi) * -6)
                    .position(x: w * 0.20, y: h * 0.48)

                // Magenta — mid-left
                blob(AppColors.magenta, 0.15, 300, 220, 85, 4)
                    .scaleEffect(blobVisible[4] ? 1 + 0.05 * sin(blobPhase[4] * .pi * 2) : 0.7)
                    .offset(x: sin(blobPhase[4] * .pi) * 8,
                            y: sin(blobPhase[4] * .pi) * -6)
                    .position(x: w * 0.18, y: h * 0.60)

                // Floor wash
                Ellipse()
                    .fill(RadialGradient(stops: [
                        .init(color: AppColors.deepBlue.opacity(0.12), location: 0),
                        .init(color: AppColors.purple.opacity(0.08),   location: 0.4),
                        .init(color: .clear,                           location: 0.7)
                    ], center: .center, startRadius: 0, endRadius: 200))
                    .frame(width: 420, height: 180)
                    .blur(radius: 90)
                    .scaleEffect(blobVisible[5] ? 1 + 0.06 * sin(blobPhase[5] * .pi * 2) : 0.7)
                    .opacity(blobVisible[5] ? 1 : 0)
                    .offset(x: sin(blobPhase[5] * .pi * 2) * 4)
                    .position(x: w * 0.5, y: h * 0.80)

                // Cyan accent — bottom
                blob(AppColors.cyan, 0.08, 240, 150, 90, 6)
                    .offset(x: sin(blobPhase[6] * .pi * 2) * -8)
                    .position(x: w * 0.45, y: h * 0.88)
            }
        }
        .allowsHitTesting(false)
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
            .fill(color.opacity(opacity))
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

#Preview {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        OnboardingGlowField()
    }
}
