// Vayl/Features/Onboarding/Canvas/ControllerCardFace.swift

import SwiftUI

struct ControllerCardFace: View {

    let cardWidth:  CGFloat
    let cardHeight: CGFloat

    private var s: CGFloat { (cardWidth * 0.82) / 800 }
    private var xOffset: CGFloat { (cardWidth  - 800 * s) / 2 }
    private var yOffset: CGFloat { (cardHeight - 600 * s) / 2 }

    var body: some View {
        Canvas { context, size in

            context.translateBy(x: xOffset, y: yOffset)

            let specGrad = Gradient(stops: [
                .init(color: AppColors.spectrumCyan,    location: 0.00),
                .init(color: AppColors.spectrumPurple,  location: 0.45),
                .init(color: AppColors.spectrumMagenta, location: 1.00),
            ])
            let shading = GraphicsContext.Shading.linearGradient(
                specGrad,
                startPoint: CGPoint(x: 0,       y: 0),
                endPoint:   CGPoint(x: 800 * s, y: 600 * s)
            )

            var bodyPath = Path()
            bodyPath.move(to: CGPoint(x: 250*s, y: 180*s))
            bodyPath.addCurve(
                to:       CGPoint(x: 150*s, y: 250*s),
                control1: CGPoint(x: 250*s, y: 180*s),
                control2: CGPoint(x: 200*s, y: 180*s)
            )
            bodyPath.addCurve(
                to:       CGPoint(x: 120*s, y: 500*s),
                control1: CGPoint(x: 100*s, y: 320*s),
                control2: CGPoint(x: 100*s, y: 450*s)
            )
            bodyPath.addCurve(
                to:       CGPoint(x: 220*s, y: 500*s),
                control1: CGPoint(x: 140*s, y: 550*s),
                control2: CGPoint(x: 200*s, y: 550*s)
            )
            bodyPath.addCurve(
                to:       CGPoint(x: 400*s, y: 420*s),
                control1: CGPoint(x: 250*s, y: 430*s),
                control2: CGPoint(x: 320*s, y: 420*s)
            )
            bodyPath.addCurve(
                to:       CGPoint(x: 580*s, y: 500*s),
                control1: CGPoint(x: 480*s, y: 420*s),
                control2: CGPoint(x: 550*s, y: 430*s)
            )
            bodyPath.addCurve(
                to:       CGPoint(x: 680*s, y: 500*s),
                control1: CGPoint(x: 600*s, y: 550*s),
                control2: CGPoint(x: 660*s, y: 550*s)
            )
            bodyPath.addCurve(
                to:       CGPoint(x: 650*s, y: 250*s),
                control1: CGPoint(x: 700*s, y: 450*s),
                control2: CGPoint(x: 700*s, y: 320*s)
            )
            bodyPath.addCurve(
                to:       CGPoint(x: 550*s, y: 180*s),
                control1: CGPoint(x: 600*s, y: 180*s),
                control2: CGPoint(x: 550*s, y: 180*s)
            )
            bodyPath.closeSubpath()

            // Glow pass
            context.drawLayer { ctx in
                ctx.addFilter(.blur(radius: 4 * s))
                ctx.opacity = 0.28
                ctx.stroke(bodyPath, with: shading,
                    style: StrokeStyle(lineWidth: 14 * s,
                                       lineCap: .round,
                                       lineJoin: .round))
            }

            // Crisp pass
            context.stroke(bodyPath, with: shading,
                style: StrokeStyle(lineWidth: 4 * s,
                                   lineCap: .round,
                                   lineJoin: .round))
        }
        .frame(width: cardWidth, height: cardHeight)
    }
}

#Preview {
    ZStack {
        AppColors.void.ignoresSafeArea()
        ControllerCardFace(
            cardWidth:  AppLayout.obCardWidth(in: 390),
            cardHeight: AppLayout.obCardHeight(in: 390)
        )
    }
    .preferredColorScheme(.dark)
}