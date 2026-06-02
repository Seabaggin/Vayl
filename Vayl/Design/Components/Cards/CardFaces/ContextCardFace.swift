// Design/Components/Cards/CardFaces/ContextCardFace.swift
//
// Content face for the relationship-context cards (ContextPhase carousel).
// Rendered by VaylCardFace when its content is `.context(...)`.
//
// Signature object: an OPEN BOOK (splayed pages, page-block thickness) with a
// bookmark ribbon — the phase's identity ("Where are you starting from?" → which
// chapter of your story), mirroring NamePhase=typewriter / ModeSelect=controller
// / Gender=slot-machine / ExperienceLevel=candle. Pure Canvas line illustration
// in the spectrum language (two passes: blurred glow + crisp stroke), upper
// region; number + title sit beneath as the header. Geometry ported from a
// browser SVG reference (docs/mockups/book-mock.html), halved to a 160-unit box.
//
// Motion (front card only, Reduce-Motion guarded):
//   · ribbon sway — the idle "alive" animation while the user rests on a card
//   · page turn   — a one-shot page flip each time a card BECOMES the front card
//                   (i.e. when the user swipes between cards)
//
// `subtitle`/`detail` are retained props (unused) so the 4-param `.context` call
// site in VaylCardFace keeps compiling.

import SwiftUI

struct ContextCardFace: View {

    let number:   String
    let title:    String
    let subtitle: String
    let detail:   String
    var isFront:  Bool = true

    // Page-turn one-shot, fired when this card becomes front. 1.0 = settled.
    @State private var turnProgress: CGFloat = 1
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var animate: Bool { isFront && !reduceMotion }

    var body: some View {
        GeometryReader { geo in
            let w   = geo.size.width
            let h   = geo.size.height
            let pad = w * 0.10

            VStack(alignment: .leading, spacing: 0) {

                Spacer(minLength: 0)

                BookObject(animate: animate, turnProgress: turnProgress)
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
        .onAppear { if isFront { firePageTurn() } }
        .onChange(of: isFront) { _, front in if front { firePageTurn() } }
    }

    /// One page flip when the card becomes front (a chapter turned to).
    private func firePageTurn() {
        guard !reduceMotion else { turnProgress = 1; return }
        turnProgress = 0
        withAnimation(.easeInOut(duration: 0.6)) { turnProgress = 1 }
    }
}

// MARK: - Book object (Canvas line illustration)

/// Open book + ribbon. While `animate` is true a TimelineView drives the idle
/// ribbon sway and samples `turnProgress` so the one-shot page flip renders.
/// When false the book is fully static (ribbon centered, no flip).
private struct BookObject: View {

    let animate:      Bool
    let turnProgress: CGFloat

    var body: some View {
        if animate {
            TimelineView(.animation) { tl in
                let t = tl.date.timeIntervalSinceReferenceDate
                Canvas { ctx, size in
                    draw(&ctx, size: size, ribbon: CGFloat(sin(t / 2.8 * 2 * .pi)),
                         turn: turnProgress, animate: true)
                }
            }
        } else {
            Canvas { ctx, size in
                draw(&ctx, size: size, ribbon: 0, turn: 1, animate: false)
            }
        }
    }

    // Viewbox 160 × 96.
    private func draw(_ context: inout GraphicsContext, size: CGSize,
                      ribbon: CGFloat, turn: CGFloat, animate: Bool) {

        let s: CGFloat = size.width / 160
        context.translateBy(x: 0, y: max(0, (size.height - 96 * s) / 2))
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * s, y: y * s) }

        let shading = GraphicsContext.Shading.linearGradient(
            Gradient(stops: [
                .init(color: AppColors.spectrumCyan,    location: 0.00),
                .init(color: AppColors.spectrumPurple,  location: 0.50),
                .init(color: AppColors.spectrumMagenta, location: 1.00),
            ]),
            startPoint: .zero, endPoint: CGPoint(x: 160 * s, y: 96 * s))

        // ── Pages (splayed open book) ─────────────────────────────
        var leftPage = Path()
        leftPage.move(to: p(80, 30))
        leftPage.addCurve(to: p(14, 21), control1: p(58, 26), control2: p(31, 21))
        leftPage.addCurve(to: p(12, 79), control1: p(9, 43),  control2: p(9, 61))
        leftPage.addCurve(to: p(80, 75), control1: p(35, 84), control2: p(59, 81))
        leftPage.closeSubpath()

        var rightPage = Path()
        rightPage.move(to: p(80, 30))
        rightPage.addCurve(to: p(146, 21), control1: p(102, 26), control2: p(129, 21))
        rightPage.addCurve(to: p(148, 79), control1: p(151, 43), control2: p(151, 61))
        rightPage.addCurve(to: p(80, 75),  control1: p(125, 84), control2: p(101, 81))
        rightPage.closeSubpath()

        var spine = Path(); spine.move(to: p(80, 30)); spine.addLine(to: p(80, 75))

        // ── Page-block thickness (shallow nested smile) ───────────
        var block1 = Path()
        block1.move(to: p(12, 79))
        block1.addCurve(to: p(80, 81),  control1: p(35, 88),  control2: p(59, 86))
        block1.addCurve(to: p(148, 79), control1: p(101, 86), control2: p(125, 88))
        var block2 = Path()
        block2.move(to: p(13, 78.5))
        block2.addCurve(to: p(80, 79),    control1: p(36, 85),    control2: p(59, 83.5))
        block2.addCurve(to: p(147, 78.5), control1: p(101, 83.5), control2: p(124, 85))
        var tickL = Path(); tickL.move(to: p(12, 79));  tickL.addLine(to: p(14, 82))
        var tickR = Path(); tickR.move(to: p(148, 79)); tickR.addLine(to: p(146, 82))

        // ── Text lines (perspective: rise toward outer edge) ──────
        let leftLines: [(CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat)] = [
            (75, 37, 46, 35, 18, 32), (75, 44, 46, 42, 16.5, 39), (75, 51, 46, 49, 15.5, 46),
            (75, 58, 46, 56, 15.5, 53.5), (75, 65, 46, 63.5, 16.5, 61.5),
        ]
        func line(_ x0: CGFloat, _ y0: CGFloat, _ cxp: CGFloat, _ cyp: CGFloat, _ x1: CGFloat, _ y1: CGFloat) -> Path {
            var pa = Path(); pa.move(to: p(x0, y0)); pa.addQuadCurve(to: p(x1, y1), control: p(cxp, cyp)); return pa
        }

        // ── Ribbon (band + swallowtail; lower part sways) ─────────
        let sway = ribbon * 4
        var ribbonPath = Path()
        ribbonPath.move(to: p(77.5, 23))
        ribbonPath.addLine(to: p(77.5 + sway, 56))
        ribbonPath.addLine(to: p(80 + sway, 52.5))     // notch
        ribbonPath.addLine(to: p(82.5 + sway, 56))
        ribbonPath.addLine(to: p(82.5, 23))

        // ── Page flip (one-shot, only mid-turn) ───────────────────
        var flip = Path(); var flipOpacity = 0.0
        if animate && turn > 0.001 && turn < 0.999 {
            let ex = 146 + (14 - 146) * turn
            let lift = sin(Double(turn) * .pi)
            let etopY = 21 - CGFloat(lift) * 10
            let ebotY = 79 - CGFloat(lift) * 6
            let ctrlX = 80 + (ex - 80) * 0.5
            flip.move(to: p(80, 30))
            flip.addQuadCurve(to: p(ex, etopY), control: p(ctrlX, etopY - CGFloat(lift) * 5))
            flip.addLine(to: p(ex, ebotY))
            flip.addQuadCurve(to: p(80, 75), control: p(ctrlX, ebotY + 4))
            flip.closeSubpath()
            flipOpacity = lift * 0.9
        }

        // ── Strokes ───────────────────────────────────────────────
        let pageStroke = StrokeStyle(lineWidth: 1.3 * s, lineCap: .round, lineJoin: .round)
        let thinStroke = StrokeStyle(lineWidth: 0.8 * s, lineCap: .round)
        let ribStroke  = StrokeStyle(lineWidth: 1.6 * s, lineCap: .round, lineJoin: .round)

        // Pass 1: glow
        context.drawLayer { ctx in
            ctx.addFilter(.blur(radius: 3 * s))
            ctx.opacity = 0.24
            ctx.stroke(leftPage,   with: shading, style: StrokeStyle(lineWidth: 6 * s, lineJoin: .round))
            ctx.stroke(rightPage,  with: shading, style: StrokeStyle(lineWidth: 6 * s, lineJoin: .round))
            ctx.stroke(ribbonPath, with: shading, style: StrokeStyle(lineWidth: 5 * s, lineJoin: .round))
        }

        // Pass 2: crisp
        var textCtx = context; textCtx.opacity = 0.4
        for l in leftLines {
            textCtx.stroke(line(l.0, l.1, l.2, l.3, l.4, l.5), with: shading, style: thinStroke)
            textCtx.stroke(line(160 - l.0, l.1, 160 - l.2, l.3, 160 - l.4, l.5), with: shading, style: thinStroke)
        }

        var blockCtx = context; blockCtx.opacity = 0.5
        for pa in [block1, block2, tickL, tickR] { blockCtx.stroke(pa, with: shading, style: thinStroke) }

        var spineCtx = context; spineCtx.opacity = 0.5
        spineCtx.stroke(spine, with: shading, style: thinStroke)

        context.stroke(leftPage,  with: shading, style: pageStroke)
        context.stroke(rightPage, with: shading, style: pageStroke)

        if flipOpacity > 0.01 {
            var fc = context; fc.opacity = flipOpacity
            fc.stroke(flip, with: shading, style: pageStroke)
        }

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
