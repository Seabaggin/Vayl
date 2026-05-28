// Vayl/Design/Components/Cards/TypewriterCardFace.swift

import SwiftUI

struct TypewriterCardFace: View {

    let cardWidth:        CGFloat
    let cardHeight:       CGFloat
    let name:             String
    let activeKey:        Int      // -1 = none, 0–11 = letter key, 12 = space bar
    let carriageProgress: CGFloat  // 0.0 (left) → 1.0 (right)

    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height

            // ── Card background ──────────────────────────────────────
            context.fill(
                Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: AppRadius.obCard),
                with: .color(AppColors.cardBg)
            )

            // ── Spectrum gradient (diagonal, card-relative) ──────────
            let specGrad = Gradient(stops: [
                .init(color: AppColors.spectrumCyan,    location: 0.00),
                .init(color: AppColors.spectrumPurple,  location: 0.50),
                .init(color: AppColors.spectrumMagenta, location: 1.00),
            ])
            let shading = GraphicsContext.Shading.linearGradient(
                specGrad,
                startPoint: CGPoint(x: 0, y: 0),
                endPoint:   CGPoint(x: w, y: h)
            )

            // ── Geometry — all values proportional to card size ──────
            let bodyW      = w * 0.82
            let bodyH      = h * 0.38
            let bodyX      = (w - bodyW) / 2
            let bodyY      = h * 0.28
            let keySize    = bodyW * 0.09
            let platenH    = bodyH * 0.14
            let platenW    = bodyW * 0.92
            let platenX    = (w - platenW) / 2
            let platenY    = bodyY - platenH * 0.5
            let leverArmW  = bodyW * 0.22
            let leverBallR = leverArmW * 0.12

            // ── Build paths ──────────────────────────────────────────

            // Paper sheet — two vertical edges + top horizontal rule
            let paperTopY = platenY - h * 0.12
            let paperW    = bodyW * 0.52
            let paperX    = (w - paperW) / 2
            var paperPath = Path()
            paperPath.move(to:    CGPoint(x: paperX,          y: paperTopY))
            paperPath.addLine(to: CGPoint(x: paperX,          y: platenY + platenH * 0.55))
            paperPath.move(to:    CGPoint(x: paperX + paperW, y: paperTopY))
            paperPath.addLine(to: CGPoint(x: paperX + paperW, y: platenY + platenH * 0.55))
            paperPath.move(to:    CGPoint(x: paperX,          y: paperTopY))
            paperPath.addLine(to: CGPoint(x: paperX + paperW, y: paperTopY))

            // Platen roller (rounded rect — curved element)
            let platenRect = CGRect(x: platenX, y: platenY, width: platenW, height: platenH)
            let platenPath = Path(roundedRect: platenRect, cornerRadius: platenH * 0.32)

            // Carriage indicator — vertical tick that travels across the platen
            let carriageX = platenX + platenW * 0.08 + (platenW * 0.84) * carriageProgress
            var carriagePath = Path()
            carriagePath.move(to:    CGPoint(x: carriageX, y: platenY - 3))
            carriagePath.addLine(to: CGPoint(x: carriageX, y: platenY + platenH + 3))

            // Cabinet body (rectangular — straight-line element)
            let bodyRect = CGRect(x: bodyX, y: bodyY, width: bodyW, height: bodyH)
            let bodyPath = Path(roundedRect: bodyRect, cornerRadius: AppRadius.sm)

            // Mechanism rail — subtle horizontal divide inside body
            let railY = bodyY + bodyH * 0.18
            var railPath = Path()
            railPath.move(to:    CGPoint(x: bodyX + bodyW * 0.04, y: railY))
            railPath.addLine(to: CGPoint(x: bodyX + bodyW * 0.96, y: railY))

            // Carriage return lever — arm extends from right side of body, ball at tip
            let leverStartX  = bodyX + bodyW
            let leverStartY  = platenY + platenH * 0.5
            let leverArmEndX = leverStartX + leverArmW - leverBallR * 2.4
            var leverPath = Path()
            leverPath.move(to:    CGPoint(x: leverStartX,  y: leverStartY))
            leverPath.addLine(to: CGPoint(x: leverArmEndX, y: leverStartY))
            let ballRect = CGRect(
                x: leverArmEndX,
                y: leverStartY - leverBallR,
                width:  leverBallR * 2,
                height: leverBallR * 2
            )
            let leverBallPath = Path(ellipseIn: ballRect)

            // Keys — 3 rows × 4 cols = indices 0–11
            let numCols   = 4
            let numRows   = 3
            let keyAreaY  = bodyY + bodyH * 0.24
            let keyAreaH  = bodyH * 0.62
            let keySpX    = bodyW * 0.84 / CGFloat(numCols)
            let keySpY    = keyAreaH  / CGFloat(numRows)
            let keyStartX = bodyX + bodyW * 0.08

            var keyPaths: [(path: Path, active: Bool)] = []
            for row in 0..<numRows {
                for col in 0..<numCols {
                    let idx      = row * numCols + col
                    let isActive = idx == activeKey
                    let kx = keyStartX + keySpX * CGFloat(col) + keySpX * 0.5
                    let ky = keyAreaY  + keySpY  * CGFloat(row) + keySpY  * 0.5
                             + (isActive ? 3 : 0)
                    let r  = CGRect(x: kx - keySize / 2, y: ky - keySize / 2, width: keySize, height: keySize)
                    keyPaths.append((Path(roundedRect: r, cornerRadius: keySize * 0.28), isActive))
                }
            }

            // Space bar
            let spBarY     = keyAreaY + keyAreaH + keySize * 0.32
            let spBarW     = bodyW * 0.48
            let spBarH     = keySize * 0.52
            let spBarX     = (w - spBarW) / 2
            let isSpActive = activeKey == 12
            let spaceRect  = CGRect(
                x: spBarX,
                y: spBarY + (isSpActive ? 3 : 0),
                width:  spBarW,
                height: spBarH
            )
            let spacePath  = Path(roundedRect: spaceRect, cornerRadius: spBarH * 0.32)

            // ── Stroke styles ────────────────────────────────────────
            // .round on curved elements (platen, lever ball, carriage)
            // .square on straight geometric elements (body, keys, lever arm)
            let roundStroke    = StrokeStyle(lineWidth: 1.2, lineCap: .round,  lineJoin: .round)
            let squareStroke   = StrokeStyle(lineWidth: 1.2, lineCap: .square, lineJoin: .miter)
            let carriageStroke = StrokeStyle(lineWidth: 2.0, lineCap: .round)
            let activeStroke   = StrokeStyle(lineWidth: 2.0, lineCap: .square)

            // ── Glow pass — blurred, 0.35 opacity ───────────────────
            // All paths drawn into a single layer, then blurred and composited.
            context.drawLayer { ctx in
                ctx.addFilter(.blur(radius: 6))
                ctx.opacity = 0.35

                ctx.stroke(platenPath,    with: shading, style: roundStroke)
                ctx.stroke(carriagePath,  with: shading, style: carriageStroke)
                ctx.stroke(bodyPath,      with: shading, style: squareStroke)
                ctx.stroke(leverPath,     with: shading, style: squareStroke)
                ctx.stroke(leverBallPath, with: shading, style: roundStroke)

                for (kp, isActive) in keyPaths {
                    ctx.stroke(kp, with: shading, style: isActive ? activeStroke : squareStroke)
                }
                ctx.stroke(spacePath, with: shading, style: isSpActive ? activeStroke : squareStroke)
            }

            // ── Crisp pass — full opacity ────────────────────────────

            // Paper — always drawn dim (it is background context, not a primary element)
            var paperCtx = context
            paperCtx.opacity = 0.38
            paperCtx.stroke(paperPath, with: shading, style: StrokeStyle(lineWidth: 1.0, lineCap: .round))

            // Platen — round linecap (curved element)
            context.stroke(platenPath, with: shading, style: roundStroke)

            // Carriage indicator — round linecap
            context.stroke(carriagePath, with: shading, style: carriageStroke)

            // Body — square linecap (rectangular element)
            context.stroke(bodyPath, with: shading, style: squareStroke)

            // Rail — dim, no linecap distinction needed at this weight
            var railCtx = context
            railCtx.opacity = 0.22
            railCtx.stroke(railPath, with: shading, style: StrokeStyle(lineWidth: 1.0))

            // Lever arm — square; lever ball — round
            context.stroke(leverPath,     with: shading, style: squareStroke)
            context.stroke(leverBallPath, with: shading, style: roundStroke)

            // Keys — square linecap; active key gets fill + brighter stroke
            for (kp, isActive) in keyPaths {
                if isActive {
                    context.fill(kp, with: .color(AppColors.accentPrimary.opacity(0.18)))
                    context.stroke(kp, with: shading, style: activeStroke)
                } else {
                    var dimCtx = context
                    dimCtx.opacity = 0.55
                    dimCtx.stroke(kp, with: shading, style: squareStroke)
                }
            }

            // Space bar
            if isSpActive {
                context.fill(spacePath, with: .color(AppColors.accentPrimary.opacity(0.18)))
                context.stroke(spacePath, with: shading, style: activeStroke)
            } else {
                var dimCtx = context
                dimCtx.opacity = 0.55
                dimCtx.stroke(spacePath, with: shading, style: squareStroke)
            }
        }
        .frame(width: cardWidth, height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.obCard))
    }
}
