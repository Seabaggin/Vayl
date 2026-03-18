import SwiftUI

/// Animated multi-blob atmospheric glow field used behind onboarding screens.
/// Pass in the `blobVisible` and `blobPhase` state arrays driven by the parent.
///
/// Configuration: 8 blobs — cyan upper-left, purple center, magenta right,
/// gold warm accent, deep-blue floor wash, lower purple/cyan fades, and a
/// radial floor gradient.
struct GlowFieldView: View {
    let blobVisible: [Bool]
    let blobPhase: [CGFloat]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                solidBlobView(width: 260, height: 240,
                              x: w * -0.12 + 130, y: h * 0.16 + 120,
                              color: AppColors.cyan, opacity: 0.24, blur: 80, idx: 0,
                              driftX: sin(blobPhase[0] * .pi * 2) * 12,
                              driftY: sin(blobPhase[0] * .pi * 2 + .pi / 3) * 14,
                              driftScale: 1)

                solidBlobView(width: 340, height: 320,
                              x: w * 0.5, y: h * 0.22 + 160,
                              color: AppColors.purple, opacity: 0.18, blur: 80, idx: 1,
                              driftX: sin(blobPhase[1] * .pi * 2) * 4,
                              driftY: 0,
                              driftScale: 1 + 0.06 * sin(blobPhase[1] * .pi * 2))

                solidBlobView(width: 240, height: 260,
                              x: w * 1.10 - 120, y: h * 0.32 + 130,
                              color: AppColors.magenta, opacity: 0.17, blur: 80, idx: 2,
                              driftX: sin(blobPhase[2] * .pi * 2) * -10,
                              driftY: cos(blobPhase[2] * .pi * 2) * 12,
                              driftScale: 1)

                solidBlobView(width: 180, height: 160,
                              x: w * 0.16 + 90, y: h * 0.44 + 80,
                              color: AppColors.goldLight, opacity: 0.07, blur: 80, idx: 3,
                              driftX: sin(blobPhase[3] * .pi) * 8,
                              driftY: sin(blobPhase[3] * .pi) * -6,
                              driftScale: 1)

                // Floor wash — radial deep-blue/purple blend
                Ellipse()
                    .fill(RadialGradient(
                        stops: [
                            .init(color: AppColors.deepBlue.opacity(0.15), location: 0),
                            .init(color: AppColors.purple.opacity(0.08),   location: 0.5),
                            .init(color: .clear,                           location: 0.7)
                        ],
                        center: .center, startRadius: 0, endRadius: 190))
                    .frame(width: 380, height: 140)
                    .scaleEffect(blobVisible[4] ? 1 + 0.06 * sin(blobPhase[4] * .pi * 2) : 0.7)
                    .opacity(blobVisible[4] ? 1 : 0)
                    .blur(radius: 80)
                    .offset(x: sin(blobPhase[4] * .pi * 2) * 4)
                    .position(x: w * 0.5, y: h * 0.54 + 70)

                solidBlobView(width: 280, height: 200,
                              x: w * -0.05 + 140, y: h * 0.68 + 100,
                              color: AppColors.purple, opacity: 0.035, blur: 90, idx: 5,
                              driftX: sin(blobPhase[5] * .pi) * 8,
                              driftY: sin(blobPhase[5] * .pi) * -6,
                              driftScale: 1)

                solidBlobView(width: 240, height: 180,
                              x: w * 1.08 - 120, y: h * 0.72 + 90,
                              color: AppColors.cyan, opacity: 0.03, blur: 100, idx: 6,
                              driftX: sin(blobPhase[6] * .pi * 2) * 12,
                              driftY: sin(blobPhase[6] * .pi * 2 + .pi / 3) * 14,
                              driftScale: 1)

                // Bottom radial — subtle purple/deep-blue fade
                Ellipse()
                    .fill(RadialGradient(
                        stops: [
                            .init(color: AppColors.purple.opacity(0.04),   location: 0),
                            .init(color: AppColors.deepBlue.opacity(0.02), location: 0.5),
                            .init(color: .clear,                           location: 0.7)
                        ],
                        center: .center, startRadius: 0, endRadius: 160))
                    .frame(width: 320, height: 160)
                    .scaleEffect(blobVisible[7] ? 1 : 0.7)
                    .opacity(blobVisible[7] ? 1 : 0)
                    .blur(radius: 100)
                    .position(x: w * 0.5, y: h * 0.78 + 80)
            }
        }
    }

    @ViewBuilder
    private func solidBlobView(
        width: CGFloat, height: CGFloat,
        x: CGFloat, y: CGFloat,
        color: Color, opacity: Double,
        blur: CGFloat, idx: Int,
        driftX: CGFloat, driftY: CGFloat, driftScale: CGFloat
    ) -> some View {
        Ellipse()
            .fill(color.opacity(opacity))
            .frame(width: width, height: height)
            .scaleEffect(blobVisible[idx] ? driftScale : 0.7)
            .opacity(blobVisible[idx] ? 1 : 0)
            .blur(radius: blur)
            .offset(x: driftX, y: driftY)
            .position(x: x, y: y)
    }
}
