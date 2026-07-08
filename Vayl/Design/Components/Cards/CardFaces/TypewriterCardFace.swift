// Vayl/Design/Components/Cards/TypewriterCardFace.swift

import SwiftUI

/// Typewriter symbol face for NamePhase.
///
/// Pure Canvas illustration — owns nothing but pixels.
/// No @State, no gestures, no text rendering.
/// All live state (activeKey, carriageProgress) passes in from NamePhase
/// via VaylCardContent.typewriter and VaylCardFace.
///
/// Canvas geometry
/// ───────────────
/// Frame:         cardWidth × cardHeight  (full card face)
/// Illustration:  cardWidth × 0.82       (82% of card width)
/// Viewbox:       160 × 130 internal units
/// Scale:         s = (cardWidth * 0.82) / 160
/// Centering:     context.translateBy — illustration floats in the card
///
/// The canvas is transparent. VaylCardFace layer 1 owns cardBg.
/// VaylCardFace layer 2 atmosphere shows in the card margins.
struct TypewriterCardFace: View {

    let cardWidth: CGFloat
    let cardHeight: CGFloat
    let activeKey: Int      // -1 = none, 0–14 = letter keys, 15 = space bar
    let carriageProgress: CGFloat  // 0.0 (left) → 1.0 (right)

    private var illustrationWidth: CGFloat { cardWidth * 0.68 }
    private var illustrationHeight: CGFloat { illustrationWidth * (130.0 / 160.0) }

    var body: some View {
        Canvas { context, size in

            // Scale factor: maps 160-unit viewbox → illustrationWidth points.
            // Every spec coordinate × s = rendered point.
            let s: CGFloat = illustrationWidth / 160

            // Center illustration within the full card canvas.
            // yOffset * 0.48 sits the illustration slightly above card center,
            // leaving more breathing room at the bottom.
            let xOffset = (size.width  - illustrationWidth)  / 2
            let yOffset = (size.height - illustrationHeight) * 0.44
            context.translateBy(x: xOffset, y: yOffset)

            // ── Spectrum gradient — illustration-relative ─────────────
            let specGrad = Gradient(stops: [
                .init(color: AppColors.spectrumCyan, location: 0.00),
                .init(color: AppColors.spectrumPurple, location: 0.50),
                .init(color: AppColors.spectrumMagenta, location: 1.00)
            ])
            let shading = GraphicsContext.Shading.linearGradient(
                specGrad,
                startPoint: CGPoint(x: 0, y: 0),
                endPoint: CGPoint(x: illustrationWidth, y: illustrationHeight)
            )

            // ── Geometry — 160×130 viewbox, all values × s ────────────

            // Platen roller bounds (used by several derived elements)
            let px: CGFloat =   6 * s
            let py: CGFloat =  18 * s
            let pw: CGFloat = 148 * s
            let ph: CGFloat =  12 * s

            // Cabinet body bounds (used by several derived elements)
            let bx: CGFloat =   6 * s
            let by: CGFloat =  30 * s
            let bw: CGFloat = 148 * s
            let bh: CGFloat =  88 * s

            // Key grid dimensions
            let numCols = 5
            let numRows = 3
            let keyGapX = 4 * s
            let keyGapY = 4 * s
            let kw       = (bw * 0.80 - CGFloat(numCols - 1) * keyGapX) / CGFloat(numCols)
            let kh       = kw * 0.72
            let kTotalW  = CGFloat(numCols) * kw + CGFloat(numCols - 1) * keyGapX
            let kTotalH  = CGFloat(numRows) * kh + CGFloat(numRows - 1) * keyGapY
            let kStartX  = bx + (bw - kTotalW) / 2
            let kStartY  = by + (bh - kTotalH) / 2 - 4 * s  // slightly above body center

            // ── Build paths ───────────────────────────────────────────

            // 1. Paper sheet
            let paperPath = Path(roundedRect: CGRect(
                x: 48 * s, y: 0,
                width: 64 * s, height: 18 * s
            ), cornerRadius: 1 * s)

            // 2. Platen roller
            let platenPath = Path(roundedRect: CGRect(
                x: px, y: py, width: pw, height: ph
            ), cornerRadius: 6 * s)

            // 3. Carriage tick — vertical line that travels across the platen
            let carriageX = (px + 10 * s) + (pw - 20 * s) * carriageProgress
            var carriagePath = Path()
            carriagePath.move(to: CGPoint(x: carriageX, y: py - 4 * s))
            carriagePath.addLine(to: CGPoint(x: carriageX, y: py + ph + 4 * s))

            // 4. Ribbon spools — flank platen ends, partially clipped at canvas edges
            let spR: CGFloat      = 7 * s
            let spInnerR: CGFloat = 4 * s
            let sp1cx: CGFloat    =   2 * s
            let sp1cy: CGFloat    =  24 * s
            let sp2cx: CGFloat    = 158 * s
            let sp2cy: CGFloat    =  24 * s

            let spool1Outer = Path(ellipseIn: CGRect(
                x: sp1cx - spR, y: sp1cy - spR, width: spR * 2, height: spR * 2))
            let spool2Outer = Path(ellipseIn: CGRect(
                x: sp2cx - spR, y: sp2cy - spR, width: spR * 2, height: spR * 2))
            let spool1Inner = Path(ellipseIn: CGRect(
                x: sp1cx - spInnerR, y: sp1cy - spInnerR, width: spInnerR * 2, height: spInnerR * 2))
            let spool2Inner = Path(ellipseIn: CGRect(
                x: sp2cx - spInnerR, y: sp2cy - spInnerR, width: spInnerR * 2, height: spInnerR * 2))

            // 5. Cabinet body
            let bodyPath = Path(roundedRect: CGRect(
                x: bx, y: by, width: bw, height: bh
            ), cornerRadius: 6 * s)

            // 6. Interior rail — structural divide, subordinate
            let railY = by + bh * 0.17
            var railPath = Path()
            railPath.move(to: CGPoint(x: bx + 10 * s, y: railY))
            railPath.addLine(to: CGPoint(x: bx + bw - 10 * s, y: railY))

            // 7. Carriage return lever — angled arm from body top-right, ball at tip.
            //    Arm extends past the 160-unit viewbox right edge — clipped by canvas.
            let lx1: CGFloat = bx + bw
            let ly1: CGFloat = py + ph * 0.5
            let lx2: CGFloat = lx1 + 14 * s
            let ly2: CGFloat = ly1 -  9 * s
            var leverPath = Path()
            leverPath.move(to: CGPoint(x: lx1, y: ly1))
            leverPath.addLine(to: CGPoint(x: lx2, y: ly2))
            let leverBallR: CGFloat = 2.2 * s
            let leverBallPath = Path(ellipseIn: CGRect(
                x: lx2 - leverBallR, y: ly2 - leverBallR,
                width: leverBallR * 2, height: leverBallR * 2
            ))

            // 8. Key grid — 5 × 3 = indices 0–14
            var keyPaths: [(path: Path, active: Bool)] = []
            for row in 0..<numRows {
                for col in 0..<numCols {
                    let idx      = row * numCols + col
                    let isActive = idx == activeKey
                    let kx = kStartX + CGFloat(col) * (kw + keyGapX)
                    let ky = kStartY + CGFloat(row) * (kh + keyGapY) + (isActive ? 2 * s : 0)
                    keyPaths.append((
                        Path(roundedRect: CGRect(x: kx, y: ky, width: kw, height: kh),
                             cornerRadius: 2.5 * s),
                        isActive
                    ))
                }
            }

            // 9. Space bar — index 15
            let isSpActive = activeKey == 15
            let spBarW = kTotalW * 0.50
            let spBarH = kh * 0.70
            let spBarX = bx + (bw - spBarW) / 2
            let spBarY = kStartY + CGFloat(numRows) * (kh + keyGapY) + 5 * s
            let spacePath = Path(roundedRect: CGRect(
                x: spBarX,
                y: spBarY + (isSpActive ? 2 * s : 0),
                width: spBarW, height: spBarH
            ), cornerRadius: 2.5 * s)

            // ── Stroke styles ─────────────────────────────────────────
            // Curves  (.round):  platen, carriage, spools, lever, paper
            // Straights (.square): body, rail, keys, space bar
            let paperStroke     = StrokeStyle(lineWidth: 0.7  * s, lineCap: .round)
            let platenStroke    = StrokeStyle(lineWidth: 1.1  * s, lineCap: .round, lineJoin: .round)
            let carriageStroke  = StrokeStyle(lineWidth: 2.0  * s, lineCap: .round)
            let spoolStroke     = StrokeStyle(lineWidth: 1.1  * s, lineCap: .round)
            let spoolInnerStyle = StrokeStyle(lineWidth: 0.55 * s, lineCap: .round)
            let bodyStroke      = StrokeStyle(lineWidth: 1.2  * s, lineCap: .square, lineJoin: .miter)
            let railStroke      = StrokeStyle(lineWidth: 0.55 * s)
            let leverStroke     = StrokeStyle(lineWidth: 1.1  * s, lineCap: .round)
            let keyActiveStroke = StrokeStyle(lineWidth: 1.4  * s, lineCap: .square)
            let keyDimStroke    = StrokeStyle(lineWidth: 0.95 * s, lineCap: .square)

            // ── Pass 1: Glow — body, platen, spools only ──────────────
            // Keys and lever are detail, not primary read — excluded from glow.
            // Wider stroke widths spread the bloom before blur is applied.
            context.drawLayer { ctx in
                ctx.addFilter(.blur(radius: 3 * s))
                ctx.opacity = 0.26
                ctx.stroke(bodyPath, with: shading, style: StrokeStyle(lineWidth: 7 * s))
                ctx.stroke(platenPath, with: shading, style: StrokeStyle(lineWidth: 5 * s))
                ctx.stroke(spool1Outer, with: shading, style: StrokeStyle(lineWidth: 5 * s))
                ctx.stroke(spool2Outer, with: shading, style: StrokeStyle(lineWidth: 5 * s))
            }

            // ── Pass 2: Crisp — all elements in draw order ────────────

            // 1. Paper — dim, communicates feed
            var paperCtx = context
            paperCtx.opacity = 0.28
            paperCtx.stroke(paperPath, with: shading, style: paperStroke)

            // 2. Platen roller
            context.stroke(platenPath, with: shading, style: platenStroke)

            // 3. Carriage tick
            context.stroke(carriagePath, with: shading, style: carriageStroke)

            // 4. Ribbon spools — outer ring full, inner hub ring dim
            context.stroke(spool1Outer, with: shading, style: spoolStroke)
            context.stroke(spool2Outer, with: shading, style: spoolStroke)
            var spoolHubCtx = context
            spoolHubCtx.opacity = 0.36
            spoolHubCtx.stroke(spool1Inner, with: shading, style: spoolInnerStyle)
            spoolHubCtx.stroke(spool2Inner, with: shading, style: spoolInnerStyle)

            // 5. Cabinet body
            context.stroke(bodyPath, with: shading, style: bodyStroke)

            // 6. Interior rail — dim structural hint
            var railCtx = context
            railCtx.opacity = 0.22
            railCtx.stroke(railPath, with: shading, style: railStroke)

            // 7. Carriage return lever — arm then ball
            context.stroke(leverPath, with: shading, style: leverStroke)
            context.stroke(leverBallPath, with: shading, style: leverStroke)

            // 8. Keys
            for (kp, isActive) in keyPaths {
                if isActive {
                    context.fill(kp, with: .color(AppColors.accentPrimary.opacity(0.18)))
                    context.stroke(kp, with: shading, style: keyActiveStroke)
                } else {
                    var dimCtx = context
                    dimCtx.opacity = 0.62
                    dimCtx.stroke(kp, with: shading, style: keyDimStroke)
                }
            }

            // 9. Space bar
            if isSpActive {
                context.fill(spacePath, with: .color(AppColors.accentPrimary.opacity(0.18)))
                context.stroke(spacePath, with: shading, style: keyActiveStroke)
            } else {
                var dimCtx = context
                dimCtx.opacity = 0.62
                dimCtx.stroke(spacePath, with: shading, style: keyDimStroke)
            }
        }
        .frame(width: cardWidth, height: cardHeight)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        AppColors.void.ignoresSafeArea()
        VaylCardFace(
            content: .typewriter(
                activeKey: 3,
                carriageProgress: 0.45
            )
        )
        .frame(
            width: AppLayout.obCardWidth(in: 390),
            height: AppLayout.obCardHeight(in: 390)
        )
    }
    .preferredColorScheme(.dark)
}
