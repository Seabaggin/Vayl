// Vayl/Features/DesignSystem/Components/VaylFlourishView.swift

import SwiftUI

// MARK: - VaylFlourishView

/// Signature decorative flourish for Vayl.
/// Two paths orbit and meet at a single center node, encoding duality and connection.
///
/// Usage:
///   VaylFlourishView()
///     .frame(width: AppLayout.flourishWidth, height: AppLayout.flourishHeight)
///
/// The view renders nothing meaningful at widths below 120pt.
struct VaylFlourishView: View {

    @State private var isPulsing: Bool = false

    var body: some View {
        GeometryReader { _ in
            ZStack {
                Canvas { context, size in
                    drawStrokes(context: context, size: size)
                    drawCenterNode(context: context, size: size)
                }
                .opacity(AppColors.flourishBaseOpacity)
            }
        }
        .scaleEffect(isPulsing ? AppLayout.flourishPulseScale : 1.0)
        .ambientAnimation(
            AppAnimation.flourishBreath.repeatForever(autoreverses: true),
            value: isPulsing
        )
        .onAppear {
            isPulsing = true
        }
        .accessibilityHidden(true)
    }

    // MARK: - Drawing

    private func drawStrokes(context: GraphicsContext, size: CGSize) {
        let w = size.width
        let h = size.height

        func x(_ n: Double) -> Double { n * w }
        func y(_ n: Double) -> Double { n * h }

        // ── Gradient definitions ──────────────────────────────────────────

        let leftGradient = Gradient(stops: [
            .init(color: AppColors.flourishLeft.opacity(0.0),   location: 0.00),
            .init(color: AppColors.flourishLeft.opacity(0.55),  location: 0.25),
            .init(color: AppColors.flourishMid.opacity(0.75),   location: 0.50),
            .init(color: AppColors.flourishRight.opacity(0.55), location: 0.75),
            .init(color: AppColors.flourishRight.opacity(0.0),  location: 1.00),
        ])

        let rightGradient = Gradient(stops: [
            .init(color: AppColors.flourishRight.opacity(0.0),  location: 0.00),
            .init(color: AppColors.flourishRight.opacity(0.40), location: 0.25),
            .init(color: AppColors.flourishMid.opacity(0.55),   location: 0.50),
            .init(color: AppColors.flourishLeft.opacity(0.40),  location: 0.75),
            .init(color: AppColors.flourishLeft.opacity(0.0),   location: 1.00),
        ])

        let secondaryGradientLeft = Gradient(stops: [
            .init(color: AppColors.flourishLeft.opacity(0.0),  location: 0.00),
            .init(color: AppColors.flourishLeft.opacity(0.28), location: 0.40),
            .init(color: AppColors.flourishMid.opacity(0.38),  location: 1.00),
        ])

        let secondaryGradientRight = Gradient(stops: [
            .init(color: AppColors.flourishRight.opacity(0.0),  location: 0.00),
            .init(color: AppColors.flourishRight.opacity(0.28), location: 0.40),
            .init(color: AppColors.flourishMid.opacity(0.38),   location: 1.00),
        ])

        // ── Stroke paths ─────────────────────────────────────────────────

        // Left tail
        var leftTail = Path()
        leftTail.move(to: .init(x: x(0.025), y: y(0.50)))
        leftTail.addQuadCurve(
            to:      .init(x: x(0.162), y: y(0.483)),
            control: .init(x: x(0.100), y: y(0.50))
        )

        // Right tail
        var rightTail = Path()
        rightTail.move(to: .init(x: x(0.838), y: y(0.483)))
        rightTail.addQuadCurve(
            to:      .init(x: x(0.975), y: y(0.50)),
            control: .init(x: x(0.900), y: y(0.50))
        )

        // Left primary arm → center
        var leftArm = Path()
        leftArm.move(to: .init(x: x(0.162), y: y(0.483)))
        leftArm.addCurve(
            to:       .init(x: x(0.500), y: y(0.367)),
            control1: .init(x: x(0.287), y: y(0.467)),
            control2: .init(x: x(0.420), y: y(0.483))
        )

        // Right primary arm → center (mirror)
        var rightArm = Path()
        rightArm.move(to: .init(x: x(0.838), y: y(0.483)))
        rightArm.addCurve(
            to:       .init(x: x(0.500), y: y(0.367)),
            control1: .init(x: x(0.713), y: y(0.467)),
            control2: .init(x: x(0.580), y: y(0.483))
        )

        // Left inner curl — open loop
        var leftCurl = Path()
        leftCurl.move(to: .init(x: x(0.500), y: y(0.367)))
        leftCurl.addCurve(
            to:       .init(x: x(0.465), y: y(0.467)),
            control1: .init(x: x(0.470), y: y(0.300)),
            control2: .init(x: x(0.430), y: y(0.367))
        )
        leftCurl.addCurve(
            to:       .init(x: x(0.500), y: y(0.367)),
            control1: .init(x: x(0.483), y: y(0.533)),
            control2: .init(x: x(0.497), y: y(0.433))
        )

        // Right inner curl — open loop (mirror)
        var rightCurl = Path()
        rightCurl.move(to: .init(x: x(0.500), y: y(0.367)))
        rightCurl.addCurve(
            to:       .init(x: x(0.535), y: y(0.467)),
            control1: .init(x: x(0.530), y: y(0.300)),
            control2: .init(x: x(0.570), y: y(0.367))
        )
        rightCurl.addCurve(
            to:       .init(x: x(0.500), y: y(0.367)),
            control1: .init(x: x(0.517), y: y(0.533)),
            control2: .init(x: x(0.503), y: y(0.433))
        )

        // Secondary lower wave — left
        var secondaryLeft = Path()
        secondaryLeft.move(to: .init(x: x(0.250), y: y(0.600)))
        secondaryLeft.addCurve(
            to:       .init(x: x(0.500), y: y(0.558)),
            control1: .init(x: x(0.363), y: y(0.567)),
            control2: .init(x: x(0.413), y: y(0.583))
        )

        // Secondary lower wave — right (mirror)
        var secondaryRight = Path()
        secondaryRight.move(to: .init(x: x(0.750), y: y(0.600)))
        secondaryRight.addCurve(
            to:       .init(x: x(0.500), y: y(0.558)),
            control1: .init(x: x(0.637), y: y(0.567)),
            control2: .init(x: x(0.587), y: y(0.583))
        )

        // ── Render strokes with gradients ────────────────────────────────

        let leftStart  = UnitPoint(x: 0, y: 0.5)
        let leftEnd    = UnitPoint(x: 1, y: 0.5)

        let strokes: [(Path, Gradient, UnitPoint, UnitPoint, CGFloat)] = [
            (leftTail,       leftGradient,           leftStart, leftEnd,   0.75),
            (rightTail,      rightGradient,           leftEnd,  leftStart,  0.75),
            (leftArm,        leftGradient,            leftStart, leftEnd,   1.10),
            (rightArm,       rightGradient,           leftEnd,  leftStart,  1.10),
            (leftCurl,       leftGradient,            leftStart, leftEnd,   1.00),
            (rightCurl,      rightGradient,           leftEnd,  leftStart,  1.00),
            (secondaryLeft,  secondaryGradientLeft,   leftStart, leftEnd,   0.55),
            (secondaryRight, secondaryGradientRight,  leftEnd,  leftStart,  0.55),
        ]

        for (path, gradient, start, end, lineWidth) in strokes {
            let ctx = context
            ctx.stroke(
                path,
                with: .linearGradient(
                    gradient,
                    startPoint: CGPoint(x: start.x * w, y: start.y * h),
                    endPoint:   CGPoint(x: end.x * w,   y: end.y * h)
                ),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
            )
        }
    }

    private func drawCenterNode(context: GraphicsContext, size: CGSize) {
        let cx = size.width  * 0.500
        let cy = size.height * 0.367
        let r: CGFloat = 2.0

        let nodePath = Path(ellipseIn: CGRect(
            x: cx - r, y: cy - r,
            width: r * 2, height: r * 2
        ))

        context.stroke(
            nodePath,
            with: .color(AppColors.flourishMid.opacity(0.60)),
            style: StrokeStyle(lineWidth: 0.8)
        )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VaylFlourishView()
            .frame(width: AppLayout.flourishWidth, height: AppLayout.flourishHeight)
    }
}
