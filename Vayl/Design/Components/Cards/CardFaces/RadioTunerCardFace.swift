// Vayl/Design/Components/Cards/CardFaces/RadioTunerCardFace.swift

import SwiftUI

/// Vintage radio tuner card face for GenderPhase.
///
/// Pure Canvas illustration — owns nothing but pixels.
/// No @State, no gestures, no text rendering.
/// All live state passes in from GenderPhase via the three parameters.
///
/// Canvas geometry
/// ───────────────
/// Frame:         cardWidth × cardHeight  (full card face)
/// Viewbox:       160 × 110 internal units
/// Scale:         s = (cardWidth * 0.72) / 160
/// Centering:     context.translateBy — illustration floats in the card
///
/// The canvas is transparent. VaylCardFace layer 1 owns cardBg.
/// VaylCardFace layer 2 atmosphere shows in the card margins.
///
/// Parameters (pass-through, zero logic in this component):
///   signalStrength   — 0.0 = searching/static, 1.0 = signal locked
///   leftDialProgress  — 0.0–1.0 across gender options (left dial + band needle)
///   rightDialProgress — 0.0–1.0 across pronoun options (right dial)
struct RadioTunerCardFace: View {

    let cardWidth:  CGFloat
    let cardHeight: CGFloat

    var signalStrength:    Double = 0  // 0.0 = searching/static, 1.0 = signal locked
    var leftDialProgress:  Double = 0  // 0.0–1.0 across gender options
    var rightDialProgress: Double = 0  // 0.0–1.0 across pronoun options

    // Illustration spans 72% of card width; viewbox is 160 × 110 internal units.
    private var illustrationWidth:  CGFloat { cardWidth * 0.72 }
    private var illustrationHeight: CGFloat { illustrationWidth * (110.0 / 160.0) }

    // MARK: — Dial helpers

    /// 240° sweep centred so 0% = bottom-left, 50% = top, 100% = bottom-right.
    private func dialAngleDeg(_ progress: Double) -> Double {
        -120.0 + progress * 240.0
    }

    private func needleEnd(cx: CGFloat, cy: CGFloat, dialR: CGFloat, progress: Double) -> CGPoint {
        let rad = dialAngleDeg(progress) * .pi / 180.0
        return CGPoint(
            x: cx + dialR * 0.58 * CGFloat(sin(rad)),
            y: cy - dialR * 0.58 * CGFloat(cos(rad))
        )
    }

    var body: some View {
        Canvas { context, size in

            // Scale factor: maps 160-unit viewbox → illustrationWidth points.
            let s: CGFloat = illustrationWidth / 160

            // Center illustration within the full card canvas.
            // 0.44 sits the illustration slightly above card center.
            let xOffset = (size.width  - illustrationWidth)  / 2
            let yOffset = (size.height - illustrationHeight) * 0.44
            context.translateBy(x: xOffset, y: yOffset)

            // ── Cabinet geometry — 160×110 viewbox ────────────────────

            let cabX: CGFloat  =  0 * s
            let cabY: CGFloat  =  0 * s
            let cabW: CGFloat  = 160 * s
            let cabH: CGFloat  = 110 * s
            let cabR: CGFloat  =  12 * s

            // ── Spectrum gradient — illustration-relative ─────────────
            let specGrad = Gradient(stops: [
                .init(color: AppColors.spectrumCyan,    location: 0.00),
                .init(color: AppColors.spectrumPurple,  location: 0.50),
                .init(color: AppColors.spectrumMagenta, location: 1.00),
            ])
            let shading = GraphicsContext.Shading.linearGradient(
                specGrad,
                startPoint: CGPoint(x: cabX,        y: cabY),
                endPoint:   CGPoint(x: cabX + cabW,  y: cabY + cabH)
            )

            // ── Antenna ───────────────────────────────────────────────
            // Base at ~78% across, top of cabinet. Angles up-right: 26 up, 16 right.
            let antBaseX: CGFloat = cabX + cabW * 0.78
            let antBaseY: CGFloat = cabY
            let antTipX:  CGFloat = antBaseX + 16 * s
            let antTipY:  CGFloat = antBaseY - 26 * s
            var antennaPath = Path()
            antennaPath.move(to:    CGPoint(x: antBaseX, y: antBaseY))
            antennaPath.addLine(to: CGPoint(x: antTipX,  y: antTipY))

            // ── Speaker grille ────────────────────────────────────────
            // Rounded rect: ~56% wide, ~48% tall, 22% from left, 10% from top.
            let grilleX: CGFloat = cabX + cabW * 0.22
            let grilleY: CGFloat = cabY + cabH * 0.10
            let grilleW: CGFloat = cabW * 0.56
            let grilleH: CGFloat = cabH * 0.48
            let grilleR: CGFloat =  5 * s

            let grillePath = Path(roundedRect: CGRect(
                x: grilleX, y: grilleY,
                width: grilleW, height: grilleH
            ), cornerRadius: grilleR)

            // 6 evenly-spaced horizontal lines inside grille (clipped)
            let lineCount = 6
            let linePad:   CGFloat = 4 * s
            let lineSpacing = (grilleH - linePad * 2) / CGFloat(lineCount - 1)
            var grilleLinesPath = Path()
            for i in 0..<lineCount {
                let ly = grilleY + linePad + CGFloat(i) * lineSpacing
                grilleLinesPath.move(to:    CGPoint(x: grilleX + linePad,        y: ly))
                grilleLinesPath.addLine(to: CGPoint(x: grilleX + grilleW - linePad, y: ly))
            }

            // ── Dials ──────────────────────────────────────────────────
            // Left dial at 11.5% from cabinet left, right dial at 88.5%.
            // Vertically centred on grille midpoint.
            let dialR:  CGFloat = 11 * s
            let dialCY: CGFloat = grilleY + grilleH * 0.5

            let leftDialCX:  CGFloat = cabX + cabW * 0.115
            let rightDialCX: CGFloat = cabX + cabW * 0.885

            let leftDialPath = Path(ellipseIn: CGRect(
                x: leftDialCX  - dialR, y: dialCY - dialR,
                width: dialR * 2, height: dialR * 2
            ))
            let rightDialPath = Path(ellipseIn: CGRect(
                x: rightDialCX - dialR, y: dialCY - dialR,
                width: dialR * 2, height: dialR * 2
            ))

            // Dial needles — from centre to edge point
            let leftNeedleEnd  = needleEnd(cx: leftDialCX,  cy: dialCY, dialR: dialR, progress: leftDialProgress)
            let rightNeedleEnd = needleEnd(cx: rightDialCX, cy: dialCY, dialR: dialR, progress: rightDialProgress)

            var leftNeedlePath = Path()
            leftNeedlePath.move(to:    CGPoint(x: leftDialCX,  y: dialCY))
            leftNeedlePath.addLine(to: leftNeedleEnd)

            var rightNeedlePath = Path()
            rightNeedlePath.move(to:    CGPoint(x: rightDialCX, y: dialCY))
            rightNeedlePath.addLine(to: rightNeedleEnd)

            // ── Frequency band strip ──────────────────────────────────
            // ~76% down cabinet, full-width minus 8% padding each side, ~11% tall.
            let bandX: CGFloat = cabX + cabW * 0.08
            let bandY: CGFloat = cabY + cabH * 0.76
            let bandW: CGFloat = cabW * 0.84
            let bandH: CGFloat = cabH * 0.11
            let bandR: CGFloat =  3 * s

            let bandPath = Path(roundedRect: CGRect(
                x: bandX, y: bandY, width: bandW, height: bandH
            ), cornerRadius: bandR)

            // ── Band needle — vertical marker tracking leftDialProgress ─
            let needleX: CGFloat = bandX + bandW * CGFloat(leftDialProgress)
            var bandNeedlePath = Path()
            bandNeedlePath.move(to:    CGPoint(x: needleX, y: bandY - 2 * s))
            bandNeedlePath.addLine(to: CGPoint(x: needleX, y: bandY + bandH + 2 * s))

            // ── Cabinet rounded rect ───────────────────────────────────
            let cabinetPath = Path(roundedRect: CGRect(
                x: cabX, y: cabY, width: cabW, height: cabH
            ), cornerRadius: cabR)

            // ── Stroke styles ──────────────────────────────────────────
            let cabinetStroke   = StrokeStyle(lineWidth: 1.2 * s, lineCap: .square, lineJoin: .miter)
            let grilleStroke    = StrokeStyle(lineWidth: 1.0 * s, lineCap: .round)
            let grilleLnStroke  = StrokeStyle(lineWidth: 0.55 * s, lineCap: .round)
            let antennaStroke   = StrokeStyle(lineWidth: 0.9 * s, lineCap: .round)
            let dialStroke      = StrokeStyle(lineWidth: 1.0 * s, lineCap: .round)
            let needleStroke    = StrokeStyle(lineWidth: 1.4 * s, lineCap: .round)
            let bandStroke      = StrokeStyle(lineWidth: 1.0 * s, lineCap: .round)
            let bandNeedleWidth = 1.6 * s

            // ── Pass 1: Glow — primary structural elements only ───────
            let glowOpacity = 0.22 + 0.16 * signalStrength
            context.drawLayer { ctx in
                ctx.addFilter(.blur(radius: 3 * s))
                ctx.opacity = glowOpacity
                ctx.stroke(cabinetPath, with: shading, style: StrokeStyle(lineWidth: 7 * s))
                ctx.stroke(grillePath,  with: shading, style: StrokeStyle(lineWidth: 5 * s))
                ctx.stroke(leftDialPath,  with: shading, style: StrokeStyle(lineWidth: 5 * s))
                ctx.stroke(rightDialPath, with: shading, style: StrokeStyle(lineWidth: 5 * s))
                ctx.stroke(bandPath,    with: shading, style: StrokeStyle(lineWidth: 5 * s))
            }

            // ── Band needle signal glow (signal > 0 only) ─────────────
            if signalStrength > 0 {
                context.drawLayer { ctx in
                    ctx.addFilter(.blur(radius: 2.5 * s))
                    ctx.opacity = signalStrength * 0.70
                    ctx.stroke(bandNeedlePath, with: shading,
                        style: StrokeStyle(lineWidth: bandNeedleWidth * 2.5, lineCap: .round))
                }
            }

            // ── Pass 2: Crisp — all structural elements in draw order ─

            // 1. Cabinet body
            context.stroke(cabinetPath, with: shading, style: cabinetStroke)

            // 2. Antenna — dim, subordinate structural element
            var antCtx = context
            antCtx.opacity = 0.72
            antCtx.stroke(antennaPath, with: shading, style: antennaStroke)

            // 3. Speaker grille outline
            context.stroke(grillePath, with: shading, style: grilleStroke)

            // 4. Grille lines — clipped to grille shape, subordinate
            var grilleCtx = context
            grilleCtx.clip(to: grillePath)
            var grilleLnCtx = grilleCtx
            grilleLnCtx.opacity = 0.36
            grilleLnCtx.stroke(grilleLinesPath, with: shading, style: grilleLnStroke)

            // 5. Left dial outline
            context.stroke(leftDialPath, with: shading, style: dialStroke)

            // 6. Right dial outline
            context.stroke(rightDialPath, with: shading, style: dialStroke)

            // 7. Left dial needle
            context.stroke(leftNeedlePath, with: shading, style: needleStroke)

            // 8. Right dial needle
            context.stroke(rightNeedlePath, with: shading, style: needleStroke)

            // 9. Left dial centre dot — tiny accent fill
            let dotR: CGFloat = 1.4 * s
            let leftDotPath = Path(ellipseIn: CGRect(
                x: leftDialCX - dotR, y: dialCY - dotR,
                width: dotR * 2, height: dotR * 2
            ))
            context.fill(leftDotPath, with: .color(AppColors.accentPrimary.opacity(0.22)))

            // 10. Right dial centre dot
            let rightDotPath = Path(ellipseIn: CGRect(
                x: rightDialCX - dotR, y: dialCY - dotR,
                width: dotR * 2, height: dotR * 2
            ))
            context.fill(rightDotPath, with: .color(AppColors.accentPrimary.opacity(0.22)))

            // 11. Frequency band strip
            context.stroke(bandPath, with: shading, style: bandStroke)

            // 12. Band needle — opacity scales with signalStrength
            let bandNeedleOpacity = 0.35 + 0.65 * signalStrength
            var bandNeedleCtx = context
            bandNeedleCtx.opacity = bandNeedleOpacity
            bandNeedleCtx.stroke(bandNeedlePath, with: shading,
                style: StrokeStyle(lineWidth: bandNeedleWidth, lineCap: .round))

        }
        .frame(width: cardWidth, height: cardHeight)
    }
}

// MARK: - Preview

#Preview("Static — signal 0") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        RadioTunerCardFace(
            cardWidth:  AppLayout.obCardWidth(in: 390),
            cardHeight: AppLayout.obCardHeight(in: 390),
            signalStrength:   0,
            leftDialProgress: 0.5,
            rightDialProgress: 0.2
        )
        .frame(
            width:  AppLayout.obCardWidth(in: 390),
            height: AppLayout.obCardHeight(in: 390)
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("Locked — signal 1") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        RadioTunerCardFace(
            cardWidth:  AppLayout.obCardWidth(in: 390),
            cardHeight: AppLayout.obCardHeight(in: 390),
            signalStrength:   1,
            leftDialProgress: 0.4,
            rightDialProgress: 0.6
        )
        .frame(
            width:  AppLayout.obCardWidth(in: 390),
            height: AppLayout.obCardHeight(in: 390)
        )
    }
    .preferredColorScheme(.dark)
}
