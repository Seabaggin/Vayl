// Design/Components/Cards/CardFaces/ContextCardFace.swift
//
// Content face for the relationship-context cards (ContextPhase carousel).
// Rendered by VaylCardFace when its content is `.context(...)`.
//
// Signature object: an OPEN BOOK with page thickness + a bookmark ribbon — the
// phase's identity ("Where are you starting from?" → which chapter of your
// story), mirroring NamePhase=typewriter / ModeSelect=controller /
// Gender=slot-machine / ExperienceLevel=candle. Pure Canvas line illustration in
// the spectrum language (two passes: blurred glow + crisp stroke), upper region;
// number + title sit beneath as the header.
//
// Life (only the FRONT card animates; all guarded by Reduce Motion):
//   · text lines write in  — a spectrum "write head" sweeps down the page lines
//   · bookmark ribbon sway — the ribbon tail drifts gently
//   · page flip (looping)  — a page continuously lifts from the right, arcs over
//                            the spine, and lands left; repeats forever
// All three are self-driven by TimelineView while the card is front, so the flip
// keeps looping no matter how many times the user cycles cards 1–4.
//
// Dark-only, spectrum language. Geometry proportional to card width (OB rule).
// `subtitle`/`detail` are retained props (unused) so the 4-param `.context` call
// site in VaylCardFace keeps compiling.

import SwiftUI

struct ContextCardFace: View {

    let number:   String
    let title:    String
    let subtitle: String
    let detail:   String
    var isFront:  Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var animate: Bool { isFront && !reduceMotion }

    var body: some View {
        GeometryReader { geo in
            let w   = geo.size.width
            let h   = geo.size.height
            let pad = w * 0.10

            VStack(alignment: .leading, spacing: 0) {

                Spacer(minLength: 0)

                BookObject(animate: animate)
                    .frame(maxWidth: .infinity)
                    .frame(height: h * 0.44)

                Rectangle()
                    .fill(LinearGradient(
                        colors: [AppColors.spectrumCyan, AppColors.spectrumPurple, AppColors.spectrumMagenta],
                        startPoint: .leading, endPoint: .trailing))
                    .frame(height: 1)
                    .opacity(0.5)
                    .padding(.top, h * 0.035)
                    .padding(.bottom, h * 0.03)

                Text(number)
                    .font(AppFonts.overline)
                    .foregroundStyle(AppColors.spectrumText)
                    .opacity(0.55)

                Text(title)
                    .font(AppFonts.display(24, weight: .semibold, relativeTo: .title2))
                    .foregroundStyle(AppColors.spectrumText)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, w * 0.02)

                Spacer(minLength: 0)
            }
            .padding(pad)
            .frame(width: geo.size.width, height: geo.size.height, alignment: .leading)
        }
    }
}

// MARK: - Book object (Canvas line illustration)

/// Open book + page thickness + bookmark ribbon. While `animate` is true the
/// motion (text write-in, ribbon sway, looping page flip) is self-driven by a
/// TimelineView; when false the book is fully static (lines bright, ribbon
/// centered, no flip).
private struct BookObject: View {

    let animate: Bool

    var body: some View {
        if animate {
            TimelineView(.animation) { tl in
                let t = tl.date.timeIntervalSinceReferenceDate
                Canvas { ctx, size in
                    draw(&ctx, size: size,
                         textPhase: CGFloat((t / 2.6).truncatingRemainder(dividingBy: 1)),
                         ribbon:    CGFloat(sin(t / 2.8 * 2 * .pi)),
                         flipPhase: CGFloat((t / 3.4).truncatingRemainder(dividingBy: 1)),
                         full: false)
                }
            }
        } else {
            Canvas { ctx, size in
                draw(&ctx, size: size, textPhase: 0, ribbon: 0, flipPhase: -1, full: true)
            }
        }
    }

    // Viewbox 160 × 100. `flipPhase` < 0 disables the flipping page.
    private func draw(_ context: inout GraphicsContext, size: CGSize,
                      textPhase: CGFloat, ribbon: CGFloat, flipPhase: CGFloat, full: Bool) {

        let s: CGFloat = size.width / 160
        let drawnH = 100 * s
        context.translateBy(x: 0, y: max(0, (size.height - drawnH) / 2))
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * s, y: y * s) }

        let specGrad = Gradient(stops: [
            .init(color: AppColors.spectrumCyan,    location: 0.00),
            .init(color: AppColors.spectrumPurple,  location: 0.50),
            .init(color: AppColors.spectrumMagenta, location: 1.00),
        ])
        let shading = GraphicsContext.Shading.linearGradient(
            specGrad, startPoint: .zero, endPoint: CGPoint(x: 160 * s, y: 100 * s))

        // Key points
        let cx: CGFloat = 80
        let spineTopY: CGFloat = 20, spineBotY: CGFloat = 80

        // ── Page surfaces (curved quads) ──────────────────────────
        // Left page: spine-top → domed top edge → outer-top → outer edge →
        //            outer-bottom → concave bottom edge → spine-bottom.
        var leftPage = Path()
        leftPage.move(to: p(cx, spineTopY))
        leftPage.addQuadCurve(to: p(12, 30), control: p(46, 14))   // top edge domes up
        leftPage.addLine(to: p(16, 70))                            // outer edge
        leftPage.addQuadCurve(to: p(cx, spineBotY), control: p(46, 80)) // bottom sags
        leftPage.closeSubpath()

        var rightPage = Path()
        rightPage.move(to: p(cx, spineTopY))
        rightPage.addQuadCurve(to: p(148, 30), control: p(114, 14))
        rightPage.addLine(to: p(144, 70))
        rightPage.addQuadCurve(to: p(cx, spineBotY), control: p(114, 80))
        rightPage.closeSubpath()

        // ── Page-block thickness (stacked edges under each page) ───
        func thicknessCurve(outerX: CGFloat, outerTopY: CGFloat, outerBotY: CGFloat,
                            ctrlX: CGFloat, dy: CGFloat) -> Path {
            var pa = Path()
            pa.move(to: p(outerX, outerBotY + dy))
            pa.addQuadCurve(to: p(cx, spineBotY + dy), control: p(ctrlX, spineBotY + dy + 6))
            return pa
        }
        // Two offset bottom curves per side = the closed page block.
        let leftThick1  = thicknessCurve(outerX: 16,  outerTopY: 30, outerBotY: 70, ctrlX: 46,  dy: 4)
        let leftThick2  = thicknessCurve(outerX: 16,  outerTopY: 30, outerBotY: 70, ctrlX: 46,  dy: 8)
        let rightThick1 = thicknessCurve(outerX: 144, outerTopY: 30, outerBotY: 70, ctrlX: 114, dy: 4)
        let rightThick2 = thicknessCurve(outerX: 144, outerTopY: 30, outerBotY: 70, ctrlX: 114, dy: 8)
        // Short outer-edge ticks (the page block's outer face)
        var leftTick = Path();  leftTick.move(to: p(16, 70));  leftTick.addLine(to: p(16, 78))
        var rightTick = Path(); rightTick.move(to: p(144, 70)); rightTick.addLine(to: p(144, 78))

        // Spine + binding nub
        var spine = Path()
        spine.move(to: p(cx, spineTopY)); spine.addLine(to: p(cx, spineBotY))
        let nub = Path(roundedRect: CGRect(x: (cx - 6) * s, y: (spineBotY) * s,
                                           width: 12 * s, height: 6 * s), cornerRadius: 2 * s)

        // ── Curved text lines ─────────────────────────────────────
        let lineYs: [CGFloat] = [30, 38, 46, 54, 62, 70]
        let bandY = 28 + (72 - 28) * textPhase
        func brightness(_ y: CGFloat) -> Double {
            if full { return 0.85 }
            return 0.20 + 0.70 * Double(max(0, 1 - abs(y - bandY) / 8))
        }
        func line(_ x0: CGFloat, _ x1: CGFloat, _ y: CGFloat) -> Path {
            var pa = Path(); pa.move(to: p(x0, y))
            pa.addQuadCurve(to: p(x1, y), control: p((x0 + x1) / 2, y + 3)) // gentle sag
            return pa
        }

        // ── Bookmark ribbon (sways) ───────────────────────────────
        let ribTopY: CGFloat = 14, ribW: CGFloat = 6, tailY: CGFloat = 58
        let sway = ribbon * 5
        var ribbonPath = Path()
        ribbonPath.move(to: p(cx - ribW / 2, ribTopY))
        ribbonPath.addLine(to: p(cx - ribW / 2 + sway, tailY))
        ribbonPath.addLine(to: p(cx + sway, tailY - 6))                 // swallowtail notch
        ribbonPath.addLine(to: p(cx + ribW / 2 + sway, tailY))
        ribbonPath.addLine(to: p(cx + ribW / 2, ribTopY))

        // ── Looping page flip ─────────────────────────────────────
        // A page lifts off the right, arcs up over the spine, and lands left.
        // Invisible at the ends (aligns with the static pages); peaks mid-flip.
        var flipPage = Path()
        var flipOpacity = 0.0
        if !full && flipPhase >= 0 {
            let ex = 148 + (12 - 148) * flipPhase           // outer edge sweeps R→L
            let lift = sin(Double(flipPhase) * .pi)         // 0→1→0
            let topY = 30 - CGFloat(lift) * 16
            let botY = 70 - CGFloat(lift) * 10
            let ctrlTopX = cx + (ex - cx) * 0.5
            flipPage.move(to: p(cx, spineTopY))
            flipPage.addQuadCurve(to: p(ex, topY), control: p(ctrlTopX, topY - CGFloat(lift) * 8))
            flipPage.addLine(to: p(ex, botY))
            flipPage.addQuadCurve(to: p(cx, spineBotY), control: p(ctrlTopX, botY + 6))
            flipPage.closeSubpath()
            flipOpacity = lift * 0.9
        }

        // ── Stroke styles ─────────────────────────────────────────
        let pageStroke  = StrokeStyle(lineWidth: 1.3 * s, lineCap: .round, lineJoin: .round)
        let thinStroke  = StrokeStyle(lineWidth: 0.8 * s, lineCap: .round)
        let lineStroke  = StrokeStyle(lineWidth: 0.8 * s, lineCap: .round)
        let ribStroke   = StrokeStyle(lineWidth: 1.6 * s, lineCap: .round, lineJoin: .round)

        // ── Pass 1: Glow ──────────────────────────────────────────
        context.drawLayer { ctx in
            ctx.addFilter(.blur(radius: 3 * s))
            ctx.opacity = 0.24
            ctx.stroke(leftPage,   with: shading, style: StrokeStyle(lineWidth: 6 * s, lineJoin: .round))
            ctx.stroke(rightPage,  with: shading, style: StrokeStyle(lineWidth: 6 * s, lineJoin: .round))
            ctx.stroke(ribbonPath, with: shading, style: StrokeStyle(lineWidth: 5 * s, lineJoin: .round))
        }

        // ── Pass 2: Crisp ─────────────────────────────────────────
        // Text lines (under page edges)
        for y in lineYs {
            var lc = context; lc.opacity = brightness(y)
            lc.stroke(line(22, 70, y),  with: shading, style: lineStroke)
            var rc = context; rc.opacity = brightness(y)
            rc.stroke(line(90, 138, y), with: shading, style: lineStroke)
        }

        // Page-block thickness — dim
        var thickCtx = context; thickCtx.opacity = 0.45
        for pa in [leftThick1, leftThick2, rightThick1, rightThick2, leftTick, rightTick] {
            thickCtx.stroke(pa, with: shading, style: thinStroke)
        }

        // Spine — dim
        var spineCtx = context; spineCtx.opacity = 0.5
        spineCtx.stroke(spine, with: shading, style: thinStroke)
        spineCtx.stroke(nub,   with: shading, style: thinStroke)

        // Pages — full
        context.stroke(leftPage,  with: shading, style: pageStroke)
        context.stroke(rightPage, with: shading, style: pageStroke)

        // Flipping page — mid-flip only
        if flipOpacity > 0.01 {
            var fc = context; fc.opacity = flipOpacity
            fc.stroke(flipPage, with: shading, style: pageStroke)
        }

        // Ribbon — bold focal accent
        context.stroke(ribbonPath, with: shading, style: ribStroke)
    }
}

// MARK: - Preview

#Preview("Context face — book") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        VaylCardFace(
            content: .context(
                number:   "01",
                title:    "I'm single",
                subtitle: "Dating and still figuring out who I am in NM",
                detail:   "No relationship to navigate — just you and your curiosity."
            )
        )
        .frame(
            width:  AppLayout.obCardWidth(in: 390),
            height: AppLayout.obCardHeight(in: 390)
        )
    }
    .preferredColorScheme(.dark)
}
