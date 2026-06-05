// Vayl/Features/Onboarding/Canvas/SlotMachineCardFace.swift

import SwiftUI

/// Slot machine symbol face for GenderPhase.
///
/// Pure Canvas illustration — owns nothing but pixels.
/// No @State, no gestures, no text rendering.
/// All live state passes in from GenderPhase via the four Segment 3 parameters.
///
/// Canvas geometry
/// ───────────────
/// Frame:         cardWidth × cardHeight  (full card face)
/// Illustration:  cardWidth × 0.68        (68% of card width)
/// Viewbox:       160 × 130 internal units
/// Scale:         s = (cardWidth * 0.82) / 160
/// Centering:     context.translateBy — illustration floats in the card
///
/// The canvas is transparent. VaylCardFace layer 1 owns cardBg.
/// VaylCardFace layer 2 atmosphere shows in the card margins.
///
/// Segment 3 parameters (pass-through, zero logic in this component):
///   handleOffset   — internal units; shifts ball + stem down, foot stays fixed
///   reelOffsets    — screen points per reel; scrolls symbols when settledSymbols == nil
///   settledSymbols — symbol index per reel; centres that symbol when not nil
///   activeReel     — reel index for glow highlight; nil = none
struct SlotMachineCardFace: View {

    let cardWidth:  CGFloat
    let cardHeight: CGFloat

    // MARK: — Segment 3 pass-through parameters (zero logic in this component)

    var handleOffset:   CGFloat   = 0          // internal illustration units
    var reelOffsets:    [CGFloat] = [0, 0, 0]  // screen points per reel
    var settledSymbols: [Int?]    = [nil, nil, nil]  // nil element = use reelOffset for that reel
    var activeReel:     Int?      = nil         // nil = no reel glow

    // MARK: — Symbol catalogue

    // One entry per genderOptions item — index must match drum selection index.
    // Trans Man and Trans Woman share the same image; the drum label distinguishes them.
    private let symbolNames: [String] = [
        "gender-man",         // 0: Man
        "gender-woman",       // 1: Woman
        "gender-trans",       // 2: Trans Man
        "gender-trans",       // 3: Trans Woman
        "gender-non-binary",  // 4: Non-binary
    ]

    // One reel slot = full reel window height in internal units (58).
    // This guarantees a settled symbol lands exactly at the reel centre.
    // Proof: symY = reelY + symbolSlotH*s*0.5 = reelY + (58*s)/2 = reelY + reelH/2  ✓
    private let symbolSlotH: CGFloat = 58

    private var illustrationWidth:  CGFloat { cardWidth  * 0.68 }
    private var illustrationHeight: CGFloat { illustrationWidth * (130.0 / 160.0) }

    var body: some View {
        Canvas { context, size in

            let s: CGFloat = illustrationWidth / 160

            // Cabinet + handle geometry defined first so totalDrawnWidth
            // can center the full unit (cabinet + protruding handle) before
            // any downstream screen/reel geometry is calculated.
            let cabW: CGFloat = 180 * s
            let cabH: CGFloat = 116 * s
            let cabR: CGFloat =   8 * s

            let stemOffsetX:      CGFloat = 20 * s
            let ballR:            CGFloat =  9 * s
            let handleProtrusion: CGFloat = stemOffsetX + ballR + 8 * s

            // Shift cabinet right by half the protrusion so the
            // full unit (cabinet + handle) optically centers in the card.
            let cabX: CGFloat = handleProtrusion / 2
            let cabY: CGFloat = ballR + 4 * s

            // illustrationWidth is the scale reference only; actual drawn
            // content is wider because the handle protrudes right.
            let totalDrawnWidth: CGFloat = cabX + cabW + handleProtrusion
            let xOffset = (size.width  - totalDrawnWidth)  / 2
            let yOffset = (size.height - illustrationHeight) * 0.44
            context.translateBy(x: xOffset, y: yOffset)

            // ── Spectrum gradient — illustration-relative ─────────────
            let specGrad = Gradient(stops: [
                .init(color: AppColors.spectrumCyan,    location: 0.00),
                .init(color: AppColors.spectrumPurple,  location: 0.50),
                .init(color: AppColors.spectrumMagenta, location: 1.00),
            ])
            let shading = GraphicsContext.Shading.linearGradient(
                specGrad,
                startPoint: CGPoint(x: 0,                y: 0),
                endPoint:   CGPoint(x: illustrationWidth, y: illustrationHeight)
            )

            // Screen window (contains the three reels)
            let scrPad: CGFloat = 11 * s
            let scrW:   CGFloat = cabW - scrPad * 2
            let scrH:   CGFloat = 74  * s
            let scrR:   CGFloat =  4  * s
            let scrX:   CGFloat = cabX + scrPad
            let scrY:   CGFloat = cabY + scrPad + 2 * s

            // Three reel windows
            let reelW:   CGFloat = 44 * s
            let reelH:   CGFloat = 58 * s
            let reelPad: CGFloat = (scrW - reelW * 3) / 4
            let reelY:   CGFloat = scrY + (scrH - reelH) / 2
            let reelXs: [CGFloat] = [
                scrX + reelPad,
                scrX + reelPad * 2 + reelW,
                scrX + reelPad * 3 + reelW * 2,
            ]

            // Handle — Segment 3: ballCY and stemTopY shift with handleOffset.
            // stemBotY and footY are fixed so the foot stays anchored to the cabinet.
            let stemX:    CGFloat = cabX + cabW + stemOffsetX
            let ballCX:   CGFloat = stemX
            let ballCY:   CGFloat = (cabY + 2 * s) + handleOffset * s
            let stemTopY: CGFloat = ballCY + ballR + 1 * s
            let stemBotY: CGFloat = cabY + cabH - 16 * s   // unchanged
            let footEndX: CGFloat = cabX + cabW             // unchanged
            let footY:    CGFloat = stemBotY                // unchanged

            // ── Build paths ───────────────────────────────────────────

            // Cabinet body
            let cabinetPath = Path(roundedRect: CGRect(
                x: cabX, y: cabY, width: cabW, height: cabH
            ), cornerRadius: cabR)

            // Screen window
            let screenPath = Path(roundedRect: CGRect(
                x: scrX, y: scrY, width: scrW, height: scrH
            ), cornerRadius: scrR)

            // Reel window paths
            let reelPaths: [Path] = reelXs.map { rx in
                Path(roundedRect: CGRect(x: rx, y: reelY, width: reelW, height: reelH),
                     cornerRadius: 2 * s)
            }

            // Handle — vertical stem down, horizontal foot left to cabinet edge
            var handlePath = Path()
            handlePath.move(to:    CGPoint(x: stemX,    y: stemTopY))
            handlePath.addLine(to: CGPoint(x: stemX,    y: stemBotY))
            handlePath.addLine(to: CGPoint(x: footEndX, y: footY))

            // Ball — circle at stem top
            let ballPath = Path(ellipseIn: CGRect(
                x: ballCX - ballR, y: ballCY - ballR,
                width: ballR * 2, height: ballR * 2
            ))

            // Reel divider lines — vertical, inset 8*s from screen top/bottom
            var dividerPath = Path()
            let div1X = reelXs[0] + reelW + reelPad / 2
            let div2X = reelXs[1] + reelW + reelPad / 2
            dividerPath.move(to:    CGPoint(x: div1X, y: scrY + 8 * s))
            dividerPath.addLine(to: CGPoint(x: div1X, y: scrY + scrH - 8 * s))
            dividerPath.move(to:    CGPoint(x: div2X, y: scrY + 8 * s))
            dividerPath.addLine(to: CGPoint(x: div2X, y: scrY + scrH - 8 * s))

            // Handle gradient — userSpaceOnUse, ball top to foot
            let handleGrad = Gradient(stops: [
                .init(color: AppColors.spectrumCyan,    location: 0.00),
                .init(color: AppColors.spectrumPurple,  location: 0.55),
                .init(color: AppColors.spectrumMagenta, location: 1.00),
            ])
            let handleShading = GraphicsContext.Shading.linearGradient(
                handleGrad,
                startPoint: CGPoint(x: stemX,    y: ballCY - ballR),
                endPoint:   CGPoint(x: footEndX, y: stemBotY)
            )

            // ── Pass 1: Glow — primary structural elements only ───────
            context.drawLayer { ctx in
                ctx.addFilter(.blur(radius: 3 * s))
                ctx.opacity = 0.26
                ctx.stroke(cabinetPath, with: shading,       style: StrokeStyle(lineWidth: 7 * s))
                ctx.stroke(screenPath,  with: shading,       style: StrokeStyle(lineWidth: 5 * s))
                ctx.stroke(handlePath,  with: handleShading, style: StrokeStyle(lineWidth: 9 * s))
                ctx.stroke(ballPath,    with: handleShading, style: StrokeStyle(lineWidth: 9 * s))
            }

            // ── Pass 2: Crisp — all structural elements in draw order ─

            // 1. Cabinet body — square caps for rectangular structural edges
            context.stroke(cabinetPath, with: shading,
                style: StrokeStyle(lineWidth: 1.2 * s, lineCap: .square, lineJoin: .miter))

            // 2. Screen window
            context.stroke(screenPath, with: shading,
                style: StrokeStyle(lineWidth: 1.2 * s, lineCap: .round))

            // 3. Reel windows — dim, they're interior framing
            var reelWinCtx = context
            reelWinCtx.opacity = 0.72
            for rp in reelPaths {
                reelWinCtx.stroke(rp, with: shading,
                    style: StrokeStyle(lineWidth: 1.2 * s, lineCap: .round))
            }

            // 4. Reel divider lines — subordinate structural hint
            var divCtx = context
            divCtx.opacity = 0.28
            divCtx.stroke(dividerPath, with: shading,
                style: StrokeStyle(lineWidth: 0.55 * s, lineCap: .round))

            // 5. Handle path
            context.stroke(handlePath, with: handleShading,
                style: StrokeStyle(lineWidth: 1.6 * s, lineCap: .round, lineJoin: .miter))

            // 6. Ball outline
            context.stroke(ballPath, with: handleShading,
                style: StrokeStyle(lineWidth: 1.6 * s, lineCap: .round))

            // 7. Ball inner fill — soft accent glow
            let ballInnerR = ballR * 0.38
            let ballInnerPath = Path(ellipseIn: CGRect(
                x: ballCX - ballInnerR,
                y: ballCY - ballInnerR,
                width:  ballInnerR * 2,
                height: ballInnerR * 2
            ))
            context.fill(ballInnerPath, with: .color(AppColors.accentPrimary.opacity(0.20)))

            // ── Pass 3: Symbol rendering — per reel ───────────────────
            //
            // Each reel is an independent clipped context.
            // Scroll position:
            //   settledSymbols != nil → symbol[i] is centred in the reel window
            //   settledSymbols == nil → reelOffsets[i] drives continuous scroll
            //
            // Symbol colour is applied in the symbols: block via foregroundStyle.
            // Each symbol is drawn twice per visible slot:
            //   1. Glow pass — blurred copy at reduced opacity (behind)
            //   2. Crisp pass — full opacity symbol on top

            let stripH = CGFloat(symbolNames.count) * symbolSlotH * s

            for i in 0..<3 {
                var reelCtx = context
                reelCtx.clip(to: reelPaths[i])

                // Normalised scroll offset in [0, stripH)
                // Per-reel: settled element → centre that symbol; nil → live scroll offset.
                let rawOff: CGFloat
                if let symIdx = settledSymbols[i] {
                    rawOff = CGFloat(symIdx) * symbolSlotH * s
                } else {
                    rawOff = reelOffsets[i].truncatingRemainder(dividingBy: stripH)
                }
                let norm = ((rawOff.truncatingRemainder(dividingBy: stripH)) + stripH)
                    .truncatingRemainder(dividingBy: stripH)

                for rep in -1...2 {
                    for symIdx in 0..<symbolNames.count {
                        guard let resolved = reelCtx.resolveSymbol(id: symIdx) else { continue }

                        // Centre of this symbol in canvas coordinates
                        let symY = reelY
                            + CGFloat(symIdx) * symbolSlotH * s
                            + CGFloat(rep) * stripH
                            - norm
                            + symbolSlotH * s * 0.5

                        // Cull: skip symbols entirely outside the reel ± one slot
                        guard symY > reelY - symbolSlotH * s,
                              symY < reelY + reelH + symbolSlotH * s else { continue }

                        let cx = reelXs[i] + reelW / 2
                        let sz = CGSize(width: reelW * 0.62, height: reelW * 0.62)
                        let symRect = CGRect(
                            x: cx - sz.width  / 2,
                            y: symY - sz.height / 2,
                            width:  sz.width,
                            height: sz.height
                        )

                        // Glow — blurred spectrum-coloured copy behind the symbol
                        reelCtx.drawLayer { gCtx in
                            gCtx.addFilter(.blur(radius: 5 * s))
                            gCtx.opacity = 0.50
                            gCtx.draw(resolved, in: symRect)
                        }
                        // Crisp — spectrum-coloured symbol on top
                        reelCtx.draw(resolved, in: symRect)
                    }
                }

                // Active reel glow — drawn after symbols, inside the clip
                if activeReel == i {
                    reelCtx.drawLayer { gCtx in
                        gCtx.addFilter(.blur(radius: 6 * s))
                        gCtx.opacity = 0.45
                        gCtx.stroke(reelPaths[i], with: shading,
                            style: StrokeStyle(lineWidth: 3 * s))
                    }
                }
            }

        } symbols: {
            ForEach(Array(symbolNames.enumerated()), id: \.offset) { idx, name in
                Image(name)
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(LinearGradient(
                        stops: [
                            .init(color: AppColors.spectrumCyan,    location: 0.0),
                            .init(color: AppColors.spectrumPurple,  location: 0.5),
                            .init(color: AppColors.spectrumMagenta, location: 1.0),
                        ],
                        startPoint: .topLeading,
                        endPoint:   .bottomTrailing
                    ))
                    .tag(idx)
            }
        }
        .frame(width: cardWidth, height: cardHeight)
    }
}

// MARK: - Preview

#Preview("Default — all zeros") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        VaylCardFace(content: .slotMachine)
            .frame(
                width:  AppLayout.obCardWidth(in: 390),
                height: AppLayout.obCardHeight(in: 390)
            )
    }
    .preferredColorScheme(.dark)
}

#Preview("Settled — handle down, active reel glow") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        SlotMachineCardFace(
            cardWidth:      AppLayout.obCardWidth(in: 390),
            cardHeight:     AppLayout.obCardHeight(in: 390),
            handleOffset:   15,
            settledSymbols: [0, 1, 2],
            activeReel:     1
        )
        .frame(
            width:  AppLayout.obCardWidth(in: 390),
            height: AppLayout.obCardHeight(in: 390)
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("Scrolling — reels mid-transition") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        SlotMachineCardFace(
            cardWidth:    AppLayout.obCardWidth(in: 390),
            cardHeight:   AppLayout.obCardHeight(in: 390),
            handleOffset: 8,
            reelOffsets:  [150, 80, 30],
            activeReel:   0
        )
        .frame(
            width:  AppLayout.obCardWidth(in: 390),
            height: AppLayout.obCardHeight(in: 390)
        )
    }
    .preferredColorScheme(.dark)
}
