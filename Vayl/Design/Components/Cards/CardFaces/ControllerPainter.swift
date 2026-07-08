//
//  ControllerPainter.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/23/26.
//
//  Shared drawing logic for all controller card faces.
//  ControllerCardFace (solo) and DualControllerCardFace (coop) both call
//  ControllerPainter.draw — coordinates are in the 800-unit SVG space,
//  pre-multiplied by `s`. The caller applies any position/rotation transform
//  to the context before calling draw().

import SwiftUI

enum ControllerPainter {

    // MARK: - Body path (exposed for clipping)

    /// Returns the closed outer silhouette of the controller in the painter's
    /// coordinate space (all coordinates are `value * s`).
    /// DualControllerCardFace uses this to build a clip mask for the back controller.
    static func bodyPath(s: CGFloat) -> Path {
        var body = Path()
        body.move(to: CGPoint(x: 250*s, y: 180*s))
        body.addCurve(to: CGPoint(x: 150*s, y: 250*s),
                      control1: CGPoint(x: 250*s, y: 180*s),
                      control2: CGPoint(x: 200*s, y: 180*s))
        body.addCurve(to: CGPoint(x: 120*s, y: 500*s),
                      control1: CGPoint(x: 100*s, y: 320*s),
                      control2: CGPoint(x: 100*s, y: 450*s))
        body.addCurve(to: CGPoint(x: 220*s, y: 500*s),
                      control1: CGPoint(x: 140*s, y: 550*s),
                      control2: CGPoint(x: 200*s, y: 550*s))
        body.addCurve(to: CGPoint(x: 400*s, y: 420*s),
                      control1: CGPoint(x: 250*s, y: 430*s),
                      control2: CGPoint(x: 320*s, y: 420*s))
        body.addCurve(to: CGPoint(x: 580*s, y: 500*s),
                      control1: CGPoint(x: 480*s, y: 420*s),
                      control2: CGPoint(x: 550*s, y: 430*s))
        body.addCurve(to: CGPoint(x: 680*s, y: 500*s),
                      control1: CGPoint(x: 600*s, y: 550*s),
                      control2: CGPoint(x: 660*s, y: 550*s))
        body.addCurve(to: CGPoint(x: 650*s, y: 250*s),
                      control1: CGPoint(x: 700*s, y: 450*s),
                      control2: CGPoint(x: 700*s, y: 320*s))
        body.addCurve(to: CGPoint(x: 550*s, y: 180*s),
                      control1: CGPoint(x: 600*s, y: 180*s),
                      control2: CGPoint(x: 550*s, y: 180*s))
        body.closeSubpath()
        return body
    }

    // MARK: - Draw

    /// Draw one complete controller illustration.
    ///
    /// - Parameters:
    ///   - context: The SwiftUI Canvas `GraphicsContext`. Drawing is applied to its
    ///              underlying Metal layer regardless of value-copy semantics.
    ///   - s: Scale factor mapping the 800-unit coordinate space → points.
    ///        Solo: `(cardWidth * 0.82) / 800`. Dual: `(cardWidth * 0.653) / 800`.
    ///   - shading: Spectrum gradient shading, defined by the caller in card-space.
    ///   - glowBlur: Gaussian blur radius for the glow pass (points, pre-scaled).
    ///              Solo uses 5*s; dual uses 4*s (smaller illustration).
    static func draw(
        _ context: GraphicsContext,
        s: CGFloat,
        glowBlur: CGFloat,
        activeButtons: Set<Int> = []   // 0=top  1=right  2=bottom  3=left
    ) {
        // Gradient is always defined in the painter's own coordinate space (0 → 800s × 600s).
        // This ensures correct colours regardless of any translate/rotate applied by the caller.
        let shading = GraphicsContext.Shading.linearGradient(
            Gradient(stops: [
                .init(color: AppColors.spectrumCyan, location: 0.00),
                .init(color: AppColors.spectrumPurple, location: 0.45),
                .init(color: AppColors.spectrumMagenta, location: 1.00)
            ]),
            startPoint: .zero,
            endPoint: CGPoint(x: 800 * s, y: 600 * s)
        )

        // ── Local helpers ────────────────────────────────────────────────

        func ellipse(cx: CGFloat, cy: CGFloat, r: CGFloat) -> Path {
            Path(ellipseIn: CGRect(x: (cx - r) * s, y: (cy - r) * s,
                                   width: 2 * r * s, height: 2 * r * s))
        }

        // ── Trigger paths ────────────────────────────────────────────────

        var trigL1 = Path()
        trigL1.move(to: CGPoint(x: 200*s, y: 185*s))
        trigL1.addCurve(to: CGPoint(x: 265*s, y: 175*s),
                        control1: CGPoint(x: 205*s, y: 160*s),
                        control2: CGPoint(x: 240*s, y: 160*s))
        trigL1.addLine(to: CGPoint(x: 255*s, y: 185*s))
        trigL1.closeSubpath()

        var trigL2 = Path()
        trigL2.move(to: CGPoint(x: 175*s, y: 220*s))
        trigL2.addCurve(to: CGPoint(x: 265*s, y: 185*s),
                        control1: CGPoint(x: 180*s, y: 180*s),
                        control2: CGPoint(x: 230*s, y: 170*s))
        trigL2.addLine(to: CGPoint(x: 250*s, y: 205*s))
        trigL2.closeSubpath()

        var trigR1 = Path()
        trigR1.move(to: CGPoint(x: 600*s, y: 185*s))
        trigR1.addCurve(to: CGPoint(x: 535*s, y: 175*s),
                        control1: CGPoint(x: 595*s, y: 160*s),
                        control2: CGPoint(x: 560*s, y: 160*s))
        trigR1.addLine(to: CGPoint(x: 545*s, y: 185*s))
        trigR1.closeSubpath()

        var trigR2 = Path()
        trigR2.move(to: CGPoint(x: 625*s, y: 220*s))
        trigR2.addCurve(to: CGPoint(x: 535*s, y: 185*s),
                        control1: CGPoint(x: 620*s, y: 180*s),
                        control2: CGPoint(x: 570*s, y: 170*s))
        trigR2.addLine(to: CGPoint(x: 550*s, y: 205*s))
        trigR2.closeSubpath()

        // ── Main body ────────────────────────────────────────────────────

        var body = Path()
        body.move(to: CGPoint(x: 250*s, y: 180*s))
        body.addCurve(to: CGPoint(x: 150*s, y: 250*s),
                      control1: CGPoint(x: 250*s, y: 180*s),
                      control2: CGPoint(x: 200*s, y: 180*s))
        body.addCurve(to: CGPoint(x: 120*s, y: 500*s),
                      control1: CGPoint(x: 100*s, y: 320*s),
                      control2: CGPoint(x: 100*s, y: 450*s))
        body.addCurve(to: CGPoint(x: 220*s, y: 500*s),
                      control1: CGPoint(x: 140*s, y: 550*s),
                      control2: CGPoint(x: 200*s, y: 550*s))
        body.addCurve(to: CGPoint(x: 400*s, y: 420*s),
                      control1: CGPoint(x: 250*s, y: 430*s),
                      control2: CGPoint(x: 320*s, y: 420*s))
        body.addCurve(to: CGPoint(x: 580*s, y: 500*s),
                      control1: CGPoint(x: 480*s, y: 420*s),
                      control2: CGPoint(x: 550*s, y: 430*s))
        body.addCurve(to: CGPoint(x: 680*s, y: 500*s),
                      control1: CGPoint(x: 600*s, y: 550*s),
                      control2: CGPoint(x: 660*s, y: 550*s))
        body.addCurve(to: CGPoint(x: 650*s, y: 250*s),
                      control1: CGPoint(x: 700*s, y: 450*s),
                      control2: CGPoint(x: 700*s, y: 320*s))
        body.addCurve(to: CGPoint(x: 550*s, y: 180*s),
                      control1: CGPoint(x: 600*s, y: 180*s),
                      control2: CGPoint(x: 550*s, y: 180*s))
        body.closeSubpath()

        // ── Face buttons ─────────────────────────────────────────────────
        let fbCenters: [(CGFloat, CGFloat)] = [
            (565, 265), // index 0 — top
            (595, 295), // index 1 — right
            (565, 325), // index 2 — bottom
            (535, 295) // index 3 — left
        ]

        // ── Thumbstick centres ────────────────────────────────────────────
        let stickCenters: [(CGFloat, CGFloat)] = [(300, 365), (500, 365)]

        // ═══════════════════════════════════════════════════════════════
        // GLOW PASS
        // ═══════════════════════════════════════════════════════════════
        context.drawLayer { ctx in
            ctx.addFilter(.blur(radius: glowBlur))
            ctx.opacity = 0.28

            let glow = StrokeStyle(lineWidth: 14 * s, lineCap: .round, lineJoin: .round)
            ctx.stroke(trigL1, with: shading, style: glow)
            ctx.stroke(trigL2, with: shading, style: glow)
            ctx.stroke(trigR1, with: shading, style: glow)
            ctx.stroke(trigR2, with: shading, style: glow)
            ctx.stroke(body, with: shading, style: glow)

            for (cx, cy) in fbCenters {
                ctx.stroke(ellipse(cx: cx, cy: cy, r: 14),
                           with: shading, style: StrokeStyle(lineWidth: 10 * s))
            }
            for (cx, cy) in stickCenters {
                ctx.stroke(ellipse(cx: cx, cy: cy, r: 40),
                           with: shading, style: StrokeStyle(lineWidth: 10 * s))
            }
        }

        // ═══════════════════════════════════════════════════════════════
        // CRISP PASS
        // ═══════════════════════════════════════════════════════════════
        let r4 = StrokeStyle(lineWidth: 4 * s, lineCap: .round, lineJoin: .round)

        // Triggers — opacity 0.80
        context.drawLayer { ctx in
            ctx.opacity = 0.80
            ctx.stroke(trigL1, with: shading, style: r4)
            ctx.stroke(trigL2, with: shading, style: r4)
            ctx.stroke(trigR1, with: shading, style: r4)
            ctx.stroke(trigR2, with: shading, style: r4)
        }

        // Body — opacity 0.90
        context.drawLayer { ctx in
            ctx.opacity = 0.90
            ctx.stroke(body, with: shading, style: r4)
        }

        // Touchpad — opacity 0.68, strokeWidth 3.5
        var touchpad = Path()
        touchpad.move(to: CGPoint(x: 300*s, y: 170*s))
        touchpad.addLine(to: CGPoint(x: 500*s, y: 170*s))
        touchpad.addCurve(to: CGPoint(x: 510*s, y: 200*s),
                          control1: CGPoint(x: 510*s, y: 170*s),
                          control2: CGPoint(x: 520*s, y: 180*s))
        touchpad.addLine(to: CGPoint(x: 480*s, y: 320*s))
        touchpad.addCurve(to: CGPoint(x: 400*s, y: 340*s),
                          control1: CGPoint(x: 475*s, y: 330*s),
                          control2: CGPoint(x: 460*s, y: 340*s))
        touchpad.addCurve(to: CGPoint(x: 320*s, y: 320*s),
                          control1: CGPoint(x: 340*s, y: 340*s),
                          control2: CGPoint(x: 325*s, y: 330*s))
        touchpad.addLine(to: CGPoint(x: 290*s, y: 200*s))
        touchpad.addCurve(to: CGPoint(x: 300*s, y: 170*s),
                          control1: CGPoint(x: 280*s, y: 180*s),
                          control2: CGPoint(x: 290*s, y: 170*s))
        touchpad.closeSubpath()
        context.drawLayer { ctx in
            ctx.opacity = 0.68
            ctx.stroke(touchpad, with: shading,
                       style: StrokeStyle(lineWidth: 3.5 * s, lineCap: .round, lineJoin: .round))
        }

        // Side detail curves — opacity 0.30, strokeWidth 3
        var sideL = Path()
        sideL.move(to: CGPoint(x: 175*s, y: 320*s))
        sideL.addCurve(to: CGPoint(x: 195*s, y: 530*s),
                       control1: CGPoint(x: 145*s, y: 380*s),
                       control2: CGPoint(x: 145*s, y: 480*s))
        var sideR = Path()
        sideR.move(to: CGPoint(x: 625*s, y: 320*s))
        sideR.addCurve(to: CGPoint(x: 605*s, y: 530*s),
                       control1: CGPoint(x: 655*s, y: 380*s),
                       control2: CGPoint(x: 655*s, y: 480*s))
        context.drawLayer { ctx in
            ctx.opacity = 0.30
            let side = StrokeStyle(lineWidth: 3 * s, lineCap: .round, lineJoin: .round)
            ctx.stroke(sideL, with: shading, style: side)
            ctx.stroke(sideR, with: shading, style: side)
        }

        // D-pad — opacity 0.82, strokeWidth 4, miter join
        // Shifted +25y: centre at y=295, matching face-button group centre.
        var dpad = Path()
        dpad.move(to: CGPoint(x: 210*s, y: 285*s))
        dpad.addLine(to: CGPoint(x: 210*s, y: 265*s))
        dpad.addLine(to: CGPoint(x: 230*s, y: 265*s))
        dpad.addLine(to: CGPoint(x: 230*s, y: 285*s))
        dpad.addLine(to: CGPoint(x: 250*s, y: 285*s))
        dpad.addLine(to: CGPoint(x: 250*s, y: 305*s))
        dpad.addLine(to: CGPoint(x: 230*s, y: 305*s))
        dpad.addLine(to: CGPoint(x: 230*s, y: 325*s))
        dpad.addLine(to: CGPoint(x: 210*s, y: 325*s))
        dpad.addLine(to: CGPoint(x: 210*s, y: 305*s))
        dpad.addLine(to: CGPoint(x: 190*s, y: 305*s))
        dpad.addLine(to: CGPoint(x: 190*s, y: 285*s))
        dpad.closeSubpath()
        context.drawLayer { ctx in
            ctx.opacity = 0.82
            ctx.stroke(dpad, with: shading,
                       style: StrokeStyle(lineWidth: 4 * s, lineCap: .round, lineJoin: .miter))
        }

        // Face buttons — active buttons get a dim fill + bright stroke
        context.drawLayer { ctx in
            let activeFill = GraphicsContext.Shading.linearGradient(
                Gradient(stops: [
                    .init(color: AppColors.spectrumCyan.opacity(0.35), location: 0.0),
                    .init(color: AppColors.spectrumPurple.opacity(0.25), location: 1.0)
                ]),
                startPoint: CGPoint(x: 565 * s, y: 265 * s),
                endPoint: CGPoint(x: 565 * s, y: 325 * s)
            )
            for (idx, (cx, cy)) in fbCenters.enumerated() {
                let circle = ellipse(cx: cx, cy: cy, r: 14)
                if activeButtons.contains(idx) {
                    ctx.opacity = 1.0
                    ctx.fill(circle, with: activeFill)
                    ctx.stroke(circle, with: shading,
                               style: StrokeStyle(lineWidth: 3.5 * s))
                } else {
                    ctx.opacity = 0.85
                    ctx.stroke(circle, with: shading,
                               style: StrokeStyle(lineWidth: 3.5 * s))
                }
            }
        }

        // Thumbsticks — 3 concentric rings per stick
        for (cx, cy) in stickCenters {
            context.drawLayer { ctx in
                ctx.opacity = 0.88
                ctx.stroke(ellipse(cx: cx, cy: cy, r: 40), with: shading,
                           style: StrokeStyle(lineWidth: 4 * s))
            }
            context.drawLayer { ctx in
                ctx.opacity = 0.40
                ctx.stroke(ellipse(cx: cx, cy: cy, r: 27), with: shading,
                           style: StrokeStyle(lineWidth: 2 * s))
            }
            context.drawLayer { ctx in
                ctx.opacity = 0.20
                ctx.stroke(ellipse(cx: cx, cy: cy, r: 13), with: shading,
                           style: StrokeStyle(lineWidth: 1.5 * s))
            }
        }

        // Mute bar — opacity 0.38, strokeWidth 3
        let muteBar = Path(roundedRect: CGRect(x: 390*s, y: 380*s,
                                               width: 20*s, height: 10*s),
                           cornerRadius: 5 * s)
        context.drawLayer { ctx in
            ctx.opacity = 0.38
            ctx.stroke(muteBar, with: shading,
                       style: StrokeStyle(lineWidth: 3 * s, lineCap: .round, lineJoin: .round))
        }

    }
}
