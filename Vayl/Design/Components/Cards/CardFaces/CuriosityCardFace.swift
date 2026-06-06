// Vayl/Design/Components/Cards/CardFaces/CuriosityCardFace.swift

import SwiftUI

// MARK: - Geometry

/// All binoculars math resolved once per render — no arithmetic inside
/// the Canvas closure or any @ViewBuilder. Proportional to canvas size,
/// zero fixed pixels. Pattern mirrors RadioTunerGeometry / TypewriterGeometry.
private struct BinocularsGeometry {

    // ── Centers / radius ─────────────────────────────────────────────────────
    let leftCenter:  CGPoint
    let rightCenter: CGPoint
    let lensRadius:  CGFloat

    // ── Paths ────────────────────────────────────────────────────────────────
    let leftOuterPath:  Path   // outer barrel ring
    let rightOuterPath: Path
    let leftInnerPath:  Path   // inner ring — "glass sitting inside the barrel"
    let rightInnerPath: Path
    let leftHighlight:  Path   // short arc — light catching the glass
    let rightHighlight: Path
    let bridgePath:     Path   // connecting bar between barrels
    let focusKnobPath:  Path   // center focus wheel

    // ── Shading ──────────────────────────────────────────────────────────────
    let shading: GraphicsContext.Shading

    // ── Stroke styles ────────────────────────────────────────────────────────
    let glowStroke:   StrokeStyle
    let crispStroke:  StrokeStyle   // outer rings + bridge
    let innerStroke:  StrokeStyle   // inner rings — thinner, dimmed
    let hlStroke:     StrokeStyle   // highlight arcs — thinnest
    let knobStroke:   StrokeStyle   // focus knob

    init(size: CGSize) {
        let w   = size.width
        let h   = size.height
        let cx  = w * 0.5
        let cy  = h * 0.52          // slightly below canvas center

        // Lens radius: sized so both barrels fit comfortably with margins.
        let r   = min(w, h) * 0.22
        // Center-to-center separation: r × 3.0 gives a realistic inter-barrel gap.
        let sep = r * 3.0

        let lc  = CGPoint(x: cx - sep / 2.0, y: cy)
        let rc  = CGPoint(x: cx + sep / 2.0, y: cy)

        leftCenter  = lc
        rightCenter = rc
        lensRadius  = r

        // ── Outer barrel rings ─────────────────────────────────────────────
        leftOuterPath = Path { p in
            p.addArc(center: lc, radius: r,
                     startAngle: .degrees(0), endAngle: .degrees(360), clockwise: false)
        }
        rightOuterPath = Path { p in
            p.addArc(center: rc, radius: r,
                     startAngle: .degrees(0), endAngle: .degrees(360), clockwise: false)
        }

        // ── Inner rings — 82% radius, creates barrel-frame depth ──────────
        leftInnerPath = Path { p in
            p.addArc(center: lc, radius: r * 0.82,
                     startAngle: .degrees(0), endAngle: .degrees(360), clockwise: false)
        }
        rightInnerPath = Path { p in
            p.addArc(center: rc, radius: r * 0.82,
                     startAngle: .degrees(0), endAngle: .degrees(360), clockwise: false)
        }

        // ── Highlight arcs — upper-left quadrant of each lens ─────────────
        // 215°–265° in screen-coord angles (Y-down) = upper-left to near-top.
        leftHighlight = Path { p in
            p.addArc(center: lc, radius: r * 0.52,
                     startAngle: .degrees(215), endAngle: .degrees(265), clockwise: false)
        }
        rightHighlight = Path { p in
            p.addArc(center: rc, radius: r * 0.52,
                     startAngle: .degrees(215), endAngle: .degrees(265), clockwise: false)
        }

        // ── Bridge — spans the gap between inner barrel edges ─────────────
        // Drawn first so the barrel rings render cleanly on top.
        let gapLeft:  CGFloat = lc.x + r          // right edge of left barrel
        let gapRight: CGFloat = rc.x - r           // left edge of right barrel
        let bw:       CGFloat = gapRight - gapLeft
        let bh:       CGFloat = r * 0.58

        bridgePath = Path(roundedRect: CGRect(
            x:      gapLeft,
            y:      cy - bh / 2.0,
            width:  bw,
            height: bh
        ), cornerRadius: bh * 0.30)

        // ── Focus knob — small circle at bridge centre ────────────────────
        focusKnobPath = Path { p in
            p.addArc(center: CGPoint(x: cx, y: cy), radius: r * 0.17,
                     startAngle: .degrees(0), endAngle: .degrees(360), clockwise: false)
        }

        // ── Spectrum gradient spanning both barrels ───────────────────────
        shading = .linearGradient(
            Gradient(colors: [
                AppColors.spectrumCyan,
                AppColors.spectrumPurple,
                AppColors.spectrumMagenta
            ]),
            startPoint: CGPoint(x: lc.x - r, y: cy - r),
            endPoint:   CGPoint(x: rc.x + r, y: cy + r)
        )

        // ── Stroke styles ─────────────────────────────────────────────────
        let lw       = r * 0.10
        glowStroke   = StrokeStyle(lineWidth: lw * 2.4, lineCap: .round)
        crispStroke  = StrokeStyle(lineWidth: lw,        lineCap: .round)
        innerStroke  = StrokeStyle(lineWidth: lw * 0.60, lineCap: .round)
        hlStroke     = StrokeStyle(lineWidth: lw * 0.65, lineCap: .round)
        knobStroke   = StrokeStyle(lineWidth: lw * 0.70, lineCap: .round)
    }
}

// MARK: - CuriosityCardFace

/// Card face for CuriosityPhase sort cards.
///
/// Two-zone layout matching the other card faces:
///   • Top ~44% — binoculars illustration (Canvas).
///   • Bottom ~56% — topic text, full card width.
///
/// The binoculars use the same layered-opacity pattern as RadioTunerCardFace
/// and TypewriterCardFace: glow pass (thick, blurred) on main shapes, then a
/// crisp pass with secondary details at reduced opacity for object depth.
///
/// Visual chrome (spectrum card border, hairlines, atmosphere) comes from
/// VaylCardFace shell. Segment 2 adds the ambient glint sweep on the lenses.
struct CuriosityCardFace: View {

    let cardWidth:  CGFloat
    let cardHeight: CGFloat
    let topic:      String

    var body: some View {
        VStack(spacing: 0) {

            // ── Illustration zone ─────────────────────────────────────────
            Canvas { context, size in
                let g = BinocularsGeometry(size: size)

                // Glow pass — outer rings + bridge only (no detail elements)
                var glowCtx = context
                glowCtx.addFilter(.blur(radius: 7))
                glowCtx.opacity = 0.28
                glowCtx.stroke(g.bridgePath,     with: g.shading, style: g.glowStroke)
                glowCtx.stroke(g.leftOuterPath,  with: g.shading, style: g.glowStroke)
                glowCtx.stroke(g.rightOuterPath, with: g.shading, style: g.glowStroke)

                // Crisp pass — bridge first so barrel rings sit on top
                context.stroke(g.bridgePath,     with: g.shading, style: g.crispStroke)
                context.stroke(g.leftOuterPath,  with: g.shading, style: g.crispStroke)
                context.stroke(g.rightOuterPath, with: g.shading, style: g.crispStroke)

                // Inner rings — barrel-frame depth
                var innerCtx = context
                innerCtx.opacity = 0.32
                innerCtx.stroke(g.leftInnerPath,  with: g.shading, style: g.innerStroke)
                innerCtx.stroke(g.rightInnerPath, with: g.shading, style: g.innerStroke)

                // Highlight arcs — glass surface reflections
                var hlCtx = context
                hlCtx.opacity = 0.24
                hlCtx.stroke(g.leftHighlight,  with: g.shading, style: g.hlStroke)
                hlCtx.stroke(g.rightHighlight, with: g.shading, style: g.hlStroke)

                // Focus knob — centre of bridge
                var knobCtx = context
                knobCtx.opacity = 0.45
                knobCtx.stroke(g.focusKnobPath, with: g.shading, style: g.knobStroke)
            }
            .frame(width: cardWidth, height: cardHeight * 0.44)

            // ── Topic text zone ───────────────────────────────────────────
            Text(topic)
                .font(AppFonts.cardTitle)
                .minimumScaleFactor(0.75)
                .lineLimit(5)
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, cardWidth * 0.12)
                .frame(width: cardWidth, height: cardHeight * 0.56, alignment: .center)
        }
        .frame(width: cardWidth, height: cardHeight)
    }
}

// MARK: - Preview

#Preview {
    let w: CGFloat = 280
    let h: CGFloat = 420

    ZStack {
        AppColors.cardBg.ignoresSafeArea()

        CuriosityCardFace(
            cardWidth:  w,
            cardHeight: h,
            topic:      "I don't know what I actually want"
        )
        .frame(width: w, height: h)
    }
    .clipShape(RoundedRectangle(cornerRadius: 14))
    .padding(40)
    .preferredColorScheme(.dark)
}
