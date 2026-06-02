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

    // Viewbox 160 × 110 (ported from docs/mockups/book-mock.html, ÷5 of 800×600).
    private func draw(_ context: inout GraphicsContext, size: CGSize,
                      ribbon: CGFloat, turn: CGFloat, animate: Bool) {

        let s = min(size.width / 160, size.height / 110)
        context.translateBy(x: (size.width - 160 * s) / 2, y: (size.height - 110 * s) / 2)
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * s, y: y * s) }

        let shading = GraphicsContext.Shading.linearGradient(
            Gradient(stops: [
                .init(color: AppColors.spectrumCyan,    location: 0.00),
                .init(color: AppColors.spectrumPurple,  location: 0.50),
                .init(color: AppColors.spectrumMagenta, location: 1.00),
            ]),
            startPoint: .zero, endPoint: CGPoint(x: 160 * s, y: 110 * s))

        // ── Pages ─────────────────────────────────────────────────
        var leftPage = Path()
        leftPage.move(to: p(80, 30))
        leftPage.addCurve(to: p(25, 30), control1: p(60, 24), control2: p(30, 28))
        leftPage.addLine(to: p(20, 90))
        leftPage.addCurve(to: p(80, 96), control1: p(30, 88), control2: p(60, 84))
        var rightPage = Path()
        rightPage.move(to: p(80, 30))
        rightPage.addCurve(to: p(135, 30), control1: p(100, 24), control2: p(130, 28))
        rightPage.addLine(to: p(140, 90))
        rightPage.addCurve(to: p(80, 96), control1: p(130, 88), control2: p(100, 84))
        var spine = Path(); spine.move(to: p(80, 30)); spine.addLine(to: p(80, 96))

        // ── Cover / page-block (trapezoidal, wider at bottom) ─────
        var coverL1 = Path(); coverL1.move(to: p(80, 102))
        coverL1.addCurve(to: p(14, 98), control1: p(60, 96), control2: p(24, 98)); coverL1.addLine(to: p(21, 32))
        var coverL2 = Path(); coverL2.move(to: p(78, 98))
        coverL2.addCurve(to: p(17, 94), control1: p(60, 92), control2: p(26, 94)); coverL2.addLine(to: p(23, 31))
        var coverR1 = Path(); coverR1.move(to: p(80, 102))
        coverR1.addCurve(to: p(146, 98), control1: p(100, 96), control2: p(136, 98)); coverR1.addLine(to: p(139, 32))
        var coverR2 = Path(); coverR2.move(to: p(82, 98))
        coverR2.addCurve(to: p(143, 94), control1: p(100, 92), control2: p(134, 94)); coverR2.addLine(to: p(137, 31))
        var gusset = Path(); gusset.move(to: p(74, 99))
        gusset.addCurve(to: p(86, 99), control1: p(74, 103), control2: p(86, 103))

        // ── Text lines (perspective; right top line is short) ─────
        func line(_ x0: CGFloat, _ y0: CGFloat, _ cxp: CGFloat, _ cyp: CGFloat, _ x1: CGFloat, _ y1: CGFloat) -> Path {
            var pa = Path(); pa.move(to: p(x0, y0)); pa.addQuadCurve(to: p(x1, y1), control: p(cxp, cyp)); return pa
        }
        let textLines: [Path] = [
            line(26, 38, 50, 34, 76, 40), line(25, 46, 50, 42, 76, 48),
            line(24, 54, 50, 50, 76, 56), line(23, 62, 50, 58, 76, 64),
            line(22, 70, 50, 66, 76, 72), line(21, 78, 50, 74, 76, 80),
            line(20, 86, 50, 82, 76, 88),
            line(110, 38, 120, 36, 132, 38),   // short heading
            line(84, 46, 110, 40, 133, 46), line(84, 54, 110, 48, 134, 54),
            line(84, 62, 110, 56, 135, 62), line(84, 70, 110, 64, 136, 70),
            line(84, 78, 110, 72, 137, 78), line(84, 86, 110, 80, 138, 86),
        ]

        // ── Ribbon (band + swallowtail; lower part sways) ─────────
        let sway = ribbon * 3
        var ribbonPath = Path()
        ribbonPath.move(to: p(72, 27))
        ribbonPath.addLine(to: p(72 + sway, 78))
        ribbonPath.addLine(to: p(75 + sway, 73))      // notch
        ribbonPath.addLine(to: p(78 + sway, 78))
        ribbonPath.addLine(to: p(78, 29))
        ribbonPath.closeSubpath()

        // ── Page flip (one-shot, only mid-turn) ───────────────────
        var flip = Path(); var flipOpacity = 0.0
        if animate && turn > 0.001 && turn < 0.999 {
            let ex = 135 + (25 - 135) * turn
            let lift = sin(Double(turn) * .pi)
            let etopY = 30 - CGFloat(lift) * 7
            let ebotY = 90 - CGFloat(lift) * 4
            let ctrlX = 80 + (ex - 80) * 0.5
            flip.move(to: p(80, 30))
            flip.addQuadCurve(to: p(ex, etopY), control: p(ctrlX, etopY - CGFloat(lift) * 4))
            flip.addLine(to: p(ex, ebotY))
            flip.addQuadCurve(to: p(80, 96), control: p(ctrlX, ebotY + 4))
            flip.closeSubpath()
            flipOpacity = lift * 0.85
        }

        // ── Strokes ───────────────────────────────────────────────
        let pageStroke = StrokeStyle(lineWidth: 1.4 * s, lineCap: .round, lineJoin: .round)
        let thinStroke = StrokeStyle(lineWidth: 0.8 * s, lineCap: .round)
        let ribStroke  = StrokeStyle(lineWidth: 1.5 * s, lineCap: .round, lineJoin: .round)

        // Pass 1: glow
        context.drawLayer { ctx in
            ctx.addFilter(.blur(radius: 3 * s))
            ctx.opacity = 0.24
            ctx.stroke(leftPage,   with: shading, style: StrokeStyle(lineWidth: 6 * s, lineJoin: .round))
            ctx.stroke(rightPage,  with: shading, style: StrokeStyle(lineWidth: 6 * s, lineJoin: .round))
            ctx.stroke(ribbonPath, with: shading, style: StrokeStyle(lineWidth: 5 * s, lineJoin: .round))
        }

        // Pass 2: crisp
        var coverCtx = context; coverCtx.opacity = 0.5
        for pa in [coverL1, coverL2, coverR1, coverR2, gusset] {
            coverCtx.stroke(pa, with: shading, style: thinStroke)
        }

        var textCtx = context; textCtx.opacity = 0.38
        for pa in textLines { textCtx.stroke(pa, with: shading, style: thinStroke) }

        var spineCtx = context; spineCtx.opacity = 0.55
        spineCtx.stroke(spine, with: shading, style: thinStroke)

        context.stroke(leftPage,  with: shading, style: pageStroke)
        context.stroke(rightPage, with: shading, style: pageStroke)

        if flipOpacity > 0.01 {
            var fc = context; fc.opacity = flipOpacity
            fc.stroke(flip, with: shading, style: pageStroke)
        }

        // Ribbon — fills the card bg so it reads in front of the pages
        context.fill(ribbonPath, with: .color(AppColors.cardBg))
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
