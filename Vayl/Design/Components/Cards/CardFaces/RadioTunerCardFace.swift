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

    let cardWidth: CGFloat
    let cardHeight: CGFloat

    var signalStrength: Double = 0  // 0.0 = searching/static, 1.0 = signal locked
    var scanPhase: Double = 0  // shifts sine waves as user scrolls drums
    var leftDialProgress: Double = 0  // 0.0–1.0 across gender options
    var rightDialProgress: Double = 0  // 0.0–1.0 across pronoun options

    // Illustration spans 72% of card width; viewbox is 160 × 110 internal units.
    private var illustrationWidth: CGFloat { cardWidth * 0.72 }
    private var illustrationHeight: CGFloat { illustrationWidth * (110.0 / 160.0) }

    var body: some View {
        Canvas { context, size in
            // All geometry, paths, gradients and stroke styles are precomputed in a
            // plain struct so the type-checker solves each statement in isolation.
            // The closure below does ONLY drawing — keeping its body trivial to
            // type-check (was 2.1s as one monolithic closure).
            let g = RadioTunerGeometry(
                size: size,
                illustrationWidth: illustrationWidth,
                illustrationHeight: illustrationHeight,
                signalStrength: signalStrength,
                scanPhase: scanPhase,
                leftDialProgress: leftDialProgress,
                rightDialProgress: rightDialProgress
            )

            let s       = g.s
            let shading = g.shading
            context.translateBy(x: g.xOffset, y: g.yOffset)

            // ── Pass 1: Glow — primary structural elements only ───────
            context.drawLayer { ctx in
                ctx.addFilter(.blur(radius: 3 * s))
                ctx.opacity = g.glowOpacity
                ctx.stroke(g.cabinetPath, with: shading, style: StrokeStyle(lineWidth: 7 * s))
                ctx.stroke(g.grillePath, with: shading, style: StrokeStyle(lineWidth: 5 * s))
                ctx.stroke(g.leftDialPath, with: shading, style: StrokeStyle(lineWidth: 5 * s))
                ctx.stroke(g.rightDialPath, with: shading, style: StrokeStyle(lineWidth: 5 * s))
                ctx.stroke(g.bandPath, with: shading, style: StrokeStyle(lineWidth: 5 * s))
            }

            // ── Band needle signal glow (signal > 0 only) ─────────────
            if signalStrength > 0 {
                context.drawLayer { ctx in
                    ctx.addFilter(.blur(radius: 2.5 * s))
                    ctx.opacity = signalStrength * 0.70
                    ctx.stroke(g.bandNeedlePath, with: shading,
                        style: StrokeStyle(lineWidth: g.bandNeedleWidth * 2.5, lineCap: .round))
                }
            }

            // ── Pass 2: Crisp — all structural elements in draw order ─

            // 1. Cabinet body
            context.stroke(g.cabinetPath, with: shading, style: g.cabinetStroke)

            // 2. Antenna — dim, subordinate structural element
            var antCtx = context
            antCtx.opacity = 0.72
            antCtx.stroke(g.antennaPath, with: shading, style: g.antennaStroke)

            // 3. Speaker grille outline
            context.stroke(g.grillePath, with: shading, style: g.grilleStroke)

            // 4. Sine waves — clipped to grille shape
            var grilleCtx = context
            grilleCtx.clip(to: g.grillePath)
            for wavePath in g.sineWavePaths {
                var waveCtx = grilleCtx
                waveCtx.opacity = 0.38
                waveCtx.stroke(wavePath, with: shading, style: g.grilleLnStroke)
            }

            // 5. Left dial outline
            context.stroke(g.leftDialPath, with: shading, style: g.dialStroke)

            // 6. Right dial outline
            context.stroke(g.rightDialPath, with: shading, style: g.dialStroke)

            // 7. Left dial needle
            context.stroke(g.leftNeedlePath, with: shading, style: g.needleStroke)

            // 8. Right dial needle
            context.stroke(g.rightNeedlePath, with: shading, style: g.needleStroke)

            // 9. Left dial centre dot — tiny accent fill
            context.fill(g.leftDotPath, with: .color(AppColors.accentPrimary.opacity(0.22)))

            // 10. Right dial centre dot
            context.fill(g.rightDotPath, with: .color(AppColors.accentPrimary.opacity(0.22)))

            // 11. Frequency band strip
            context.stroke(g.bandPath, with: shading, style: g.bandStroke)

            // 12. Band needle — opacity scales with signalStrength
            var bandNeedleCtx = context
            bandNeedleCtx.opacity = g.bandNeedleOpacity
            bandNeedleCtx.stroke(g.bandNeedlePath, with: shading,
                style: StrokeStyle(lineWidth: g.bandNeedleWidth, lineCap: .round))
        }
        .frame(width: cardWidth, height: cardHeight)
    }
}

// MARK: - RadioTunerGeometry

/// Precomputed geometry for `RadioTunerCardFace`.
///
/// Every value is an explicitly-typed stored property resolved in `init`, where
/// the type-checker handles each statement independently. This keeps the `Canvas`
/// drawing closure trivial to type-check — pixel-identical output, no per-edit hang.
private struct RadioTunerGeometry {

    let s: CGFloat
    let xOffset: CGFloat
    let yOffset: CGFloat

    let shading: GraphicsContext.Shading

    let cabinetPath: Path
    let antennaPath: Path
    let grillePath: Path
    let sineWavePaths: [Path]
    let leftDialPath: Path
    let rightDialPath: Path
    let leftNeedlePath: Path
    let rightNeedlePath: Path
    let leftDotPath: Path
    let rightDotPath: Path
    let bandPath: Path
    let bandNeedlePath: Path

    let cabinetStroke: StrokeStyle
    let grilleStroke: StrokeStyle
    let grilleLnStroke: StrokeStyle
    let antennaStroke: StrokeStyle
    let dialStroke: StrokeStyle
    let needleStroke: StrokeStyle
    let bandStroke: StrokeStyle

    let bandNeedleWidth: CGFloat
    let glowOpacity: Double
    let bandNeedleOpacity: Double

    /// 240° sweep centred so 0% = bottom-left, 50% = top, 100% = bottom-right.
    private static func needleEnd(cx: CGFloat, cy: CGFloat, dialR: CGFloat, progress: Double) -> CGPoint {
        let deg: Double = -120.0 + progress * 240.0
        let rad: Double = deg * .pi / 180.0
        return CGPoint(
            x: cx + dialR * 0.58 * CGFloat(sin(rad)),
            y: cy - dialR * 0.58 * CGFloat(cos(rad))
        )
    }

    init(
        size: CGSize,
        illustrationWidth: CGFloat,
        illustrationHeight: CGFloat,
        signalStrength: Double,
        scanPhase: Double,
        leftDialProgress: Double,
        rightDialProgress: Double
    ) {
        // Scale factor: maps 160-unit viewbox → illustrationWidth points.
        let s: CGFloat = illustrationWidth / 160
        self.s = s

        // Center illustration within the full card canvas.
        // 0.44 sits the illustration slightly above card center.
        self.xOffset = (size.width  - illustrationWidth)  / 2
        self.yOffset = (size.height - illustrationHeight) * 0.44

        // ── Cabinet geometry — 160×110 viewbox ────────────────────
        let cabX: CGFloat =   0 * s
        let cabY: CGFloat =   0 * s
        let cabW: CGFloat = 160 * s
        let cabH: CGFloat = 110 * s
        let cabR: CGFloat =  12 * s

        // ── Spectrum gradient — illustration-relative ─────────────
        let specGrad = Gradient(stops: [
            .init(color: AppColors.spectrumCyan, location: 0.00),
            .init(color: AppColors.spectrumPurple, location: 0.50),
            .init(color: AppColors.spectrumMagenta, location: 1.00)
        ])
        self.shading = GraphicsContext.Shading.linearGradient(
            specGrad,
            startPoint: CGPoint(x: cabX, y: cabY),
            endPoint: CGPoint(x: cabX + cabW, y: cabY + cabH)
        )

        // ── Antenna ───────────────────────────────────────────────
        let antBaseX: CGFloat = cabX + cabW * 0.78
        let antBaseY: CGFloat = cabY
        let antTipX: CGFloat = antBaseX + 16 * s
        let antTipY: CGFloat = antBaseY - 26 * s
        var antennaPath = Path()
        antennaPath.move(to: CGPoint(x: antBaseX, y: antBaseY))
        antennaPath.addLine(to: CGPoint(x: antTipX, y: antTipY))
        self.antennaPath = antennaPath

        // ── Speaker grille ────────────────────────────────────────
        let grilleX: CGFloat = cabX + cabW * 0.22
        let grilleY: CGFloat = cabY + cabH * 0.10
        let grilleW: CGFloat = cabW * 0.56
        let grilleH: CGFloat = cabH * 0.48
        let grilleR: CGFloat =   5 * s
        self.grillePath = Path(roundedRect: CGRect(
            x: grilleX, y: grilleY, width: grilleW, height: grilleH
        ), cornerRadius: grilleR)

        // ── Sine waves — 3 lanes inside grille ────────────────────
        let linePad: CGFloat = 4 * s
        let waveAmp: CGFloat = grilleH * 0.055
        let waveW: CGFloat = grilleW - linePad * 2
        let waveSteps: Int    = max(40, Int(waveW / s))
        let waveConfig: [(CGFloat, Double, Double)] = [
            (0.22, 1.8, 0.0),
            (0.50, 2.4, .pi * 0.6),
            (0.78, 1.5, .pi * 1.3)
        ]
        var sineWavePaths: [Path] = []
        for (laneFrac, freq, phaseOff) in waveConfig {
            let laneY: CGFloat = grilleY + grilleH * laneFrac
            var path = Path()
            for step in 0...waveSteps {
                let t: Double      = Double(step) / Double(waveSteps)
                let x: CGFloat     = grilleX + linePad + CGFloat(t) * waveW
                let angle: Double  = 2 * .pi * freq * t + scanPhase * 0.04 + phaseOff
                let y: CGFloat     = laneY + waveAmp * CGFloat(sin(angle))
                if step == 0 { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
            }
            sineWavePaths.append(path)
        }
        self.sineWavePaths = sineWavePaths

        // ── Dials ──────────────────────────────────────────────────
        let dialR: CGFloat = 11 * s
        let dialCY: CGFloat = grilleY + grilleH * 0.5
        let leftDialCX: CGFloat = cabX + cabW * 0.115
        let rightDialCX: CGFloat = cabX + cabW * 0.885

        self.leftDialPath = Path(ellipseIn: CGRect(
            x: leftDialCX - dialR, y: dialCY - dialR,
            width: dialR * 2, height: dialR * 2
        ))
        self.rightDialPath = Path(ellipseIn: CGRect(
            x: rightDialCX - dialR, y: dialCY - dialR,
            width: dialR * 2, height: dialR * 2
        ))

        // Dial needles — from centre to edge point
        let leftNeedleEnd  = Self.needleEnd(cx: leftDialCX, cy: dialCY, dialR: dialR, progress: leftDialProgress)
        let rightNeedleEnd = Self.needleEnd(cx: rightDialCX, cy: dialCY, dialR: dialR, progress: rightDialProgress)
        var leftNeedlePath = Path()
        leftNeedlePath.move(to: CGPoint(x: leftDialCX, y: dialCY))
        leftNeedlePath.addLine(to: leftNeedleEnd)
        self.leftNeedlePath = leftNeedlePath
        var rightNeedlePath = Path()
        rightNeedlePath.move(to: CGPoint(x: rightDialCX, y: dialCY))
        rightNeedlePath.addLine(to: rightNeedleEnd)
        self.rightNeedlePath = rightNeedlePath

        // Dial centre dots
        let dotR: CGFloat = 1.4 * s
        self.leftDotPath = Path(ellipseIn: CGRect(
            x: leftDialCX - dotR, y: dialCY - dotR,
            width: dotR * 2, height: dotR * 2
        ))
        self.rightDotPath = Path(ellipseIn: CGRect(
            x: rightDialCX - dotR, y: dialCY - dotR,
            width: dotR * 2, height: dotR * 2
        ))

        // ── Frequency band strip ──────────────────────────────────
        let bandX: CGFloat = cabX + cabW * 0.08
        let bandY: CGFloat = cabY + cabH * 0.76
        let bandW: CGFloat = cabW * 0.84
        let bandH: CGFloat = cabH * 0.11
        let bandR: CGFloat =   3 * s
        self.bandPath = Path(roundedRect: CGRect(
            x: bandX, y: bandY, width: bandW, height: bandH
        ), cornerRadius: bandR)

        // ── Band needle — vertical marker tracking leftDialProgress ─
        let needleX: CGFloat = bandX + bandW * CGFloat(leftDialProgress)
        var bandNeedlePath = Path()
        bandNeedlePath.move(to: CGPoint(x: needleX, y: bandY - 2 * s))
        bandNeedlePath.addLine(to: CGPoint(x: needleX, y: bandY + bandH + 2 * s))
        self.bandNeedlePath = bandNeedlePath

        // ── Cabinet rounded rect ───────────────────────────────────
        self.cabinetPath = Path(roundedRect: CGRect(
            x: cabX, y: cabY, width: cabW, height: cabH
        ), cornerRadius: cabR)

        // ── Stroke styles ──────────────────────────────────────────
        self.cabinetStroke  = StrokeStyle(lineWidth: 1.2 * s, lineCap: .square, lineJoin: .miter)
        self.grilleStroke   = StrokeStyle(lineWidth: 1.0 * s, lineCap: .round)
        self.grilleLnStroke = StrokeStyle(lineWidth: 0.55 * s, lineCap: .round)
        self.antennaStroke  = StrokeStyle(lineWidth: 0.9 * s, lineCap: .round)
        self.dialStroke     = StrokeStyle(lineWidth: 1.0 * s, lineCap: .round)
        self.needleStroke   = StrokeStyle(lineWidth: 1.4 * s, lineCap: .round)
        self.bandStroke     = StrokeStyle(lineWidth: 1.0 * s, lineCap: .round)
        self.bandNeedleWidth = 1.6 * s

        // ── Opacities ──────────────────────────────────────────────
        self.glowOpacity       = 0.22 + 0.16 * signalStrength
        self.bandNeedleOpacity = 0.35 + 0.65 * signalStrength
    }
}

// MARK: - Preview

#Preview("Static — signal 0") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        RadioTunerCardFace(
            cardWidth: AppLayout.obCardWidth(in: 390),
            cardHeight: AppLayout.obCardHeight(in: 390),
            signalStrength: 0,
            leftDialProgress: 0.5,
            rightDialProgress: 0.2
        )
        .frame(
            width: AppLayout.obCardWidth(in: 390),
            height: AppLayout.obCardHeight(in: 390)
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("Locked — signal 1") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        RadioTunerCardFace(
            cardWidth: AppLayout.obCardWidth(in: 390),
            cardHeight: AppLayout.obCardHeight(in: 390),
            signalStrength: 1,
            leftDialProgress: 0.4,
            rightDialProgress: 0.6
        )
        .frame(
            width: AppLayout.obCardWidth(in: 390),
            height: AppLayout.obCardHeight(in: 390)
        )
    }
    .preferredColorScheme(.dark)
}
