// Design/Components/Cards/CardFaces/ContextCardFace.swift
//
// Content face for the relationship-context cards (ContextPhase carousel).
// Rendered by VaylCardFace when its content is `.context(...)`.
//
// Signature object: an OPEN BOOK (splayed pages, page-block thickness) — the
// phase's identity ("Where are you starting from?"), mirroring NamePhase=
// typewriter / ModeSelect=controller / Gender=slot-machine / ExpLevel=candle.
// Pure Canvas line illustration in the spectrum language (two passes: blurred
// glow + crisp stroke); number + title sit beneath as the header. Geometry
// ported from a browser SVG reference (docs/mockups/book-mock.html, ÷5 of 800).
//
// Motion (front card only; a TimelineView clock drives the Canvas with
// time-based easing — a plain @State does NOT animate a Canvas smoothly):
//   · page turn — fires when a card BECOMES front (a curled page sweeps right →
//     up over the top → left, "turning to this page"). Fixed ~0.6s, so it always
//     plays fully even on a fast swipe.
//   · bookmark ribbon — hidden while browsing; on CONFIRM it DRAPES into the
//     gutter (drop with overshoot + damped pendulum settle), and lifts out on
//     deselect. The only at-rest motion; a resting unconfirmed card is calm.
//
// `subtitle`/`detail` are retained props (unused for rendering) so the
// VaylCardFace `.context` call site keeps compiling.

import SwiftUI

struct ContextCardFace: View {

    let number:   String
    let title:    String
    let subtitle: String
    let detail:   String
    var isFront:  Bool    = true
    var confirmed: Bool   = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var turnStart:   Date = .distantPast
    @State private var ribbonStart: Date = .distantPast

    var body: some View {
        GeometryReader { geo in
            let w   = geo.size.width
            let h   = geo.size.height
            let pad = w * 0.10

            VStack(alignment: .leading, spacing: 0) {

                Spacer(minLength: 0)

                BookObject(live: isFront && !reduceMotion,
                           confirmed: confirmed,
                           turnStart: turnStart, ribbonStart: ribbonStart)
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
        // Trigger the page turn when this card becomes the front card.
        .onChange(of: isFront) { _, front in if front { turnStart = Date() } }
        // Trigger ribbon drape-in / lift-out on confirm change.
        .onChange(of: confirmed) { _, _ in ribbonStart = Date() }
    }
}

// MARK: - Easing helpers

private func clamp01(_ x: CGFloat) -> CGFloat { min(1, max(0, x)) }
private func easeInOut(_ t: CGFloat) -> CGFloat { t < 0.5 ? 2*t*t : 1 - pow(-2*t + 2, 2)/2 }
private func easeOut(_ t: CGFloat) -> CGFloat { 1 - pow(1 - t, 2) }
private func easeOutBack(_ t: CGFloat) -> CGFloat {
    let c1: CGFloat = 1.70158, c3 = 1.70158 + 1
    return 1 + c3 * pow(t - 1, 3) + c1 * pow(t - 1, 2)
}

// MARK: - Book object (Canvas line illustration)

/// Static open book + time-driven page turn and ribbon. When `live` (front card,
/// motion allowed) a TimelineView clock re-renders the Canvas each frame so the
/// turn/ribbon animate from elapsed time. When not live it draws the settled
/// state (no turn; ribbon present iff confirmed).
private struct BookObject: View {

    let live:        Bool
    let confirmed:   Bool
    let turnStart:   Date
    let ribbonStart: Date

    private let turnDur = 0.6
    private let dropDur: CGFloat = 0.95   // slow, ceremonious drape-in
    private let liftDur: CGFloat = 0.45

    var body: some View {
        if live {
            TimelineView(.animation) { tl in
                Canvas { ctx, size in draw(&ctx, size: size, now: tl.date) }
            }
        } else {
            Canvas { ctx, size in draw(&ctx, size: size, now: nil) }
        }
    }

    // Viewbox 160 × 110.
    private func draw(_ context: inout GraphicsContext, size: CGSize, now: Date?) {

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

        // ── Animation state from the clock ────────────────────────
        var turnT: CGFloat = -1          // -1 = no turn
        var reveal: CGFloat = confirmed ? 1 : 0
        var sway: CGFloat = 0
        if let now {
            let te = CGFloat(now.timeIntervalSince(turnStart))
            if te >= 0 && te <= CGFloat(turnDur) { turnT = easeInOut(te / CGFloat(turnDur)) }
            let re = CGFloat(now.timeIntervalSince(ribbonStart))
            if confirmed {
                reveal = easeOutBack(clamp01(re / dropDur))
                sway   = re < 3.0 ? exp(-re * 2.4) * sin(re * 8) : 0   // slow damped pendulum
            } else {
                reveal = 1 - easeOut(clamp01(re / liftDur))           // 1→0 (lift out)
            }
        }

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

        // ── Text lines — straight ruled lines (control = midpoint) ─
        func line(_ x0: CGFloat, _ y0: CGFloat, _ x1: CGFloat, _ y1: CGFloat) -> Path {
            var pa = Path(); pa.move(to: p(x0, y0))
            pa.addQuadCurve(to: p(x1, y1), control: p((x0 + x1) / 2, (y0 + y1) / 2))
            return pa
        }
        let textLines: [Path] = [
            line(26, 38, 76, 40), line(25, 46, 76, 48), line(24, 54, 76, 56),
            line(23, 62, 76, 64), line(22, 70, 76, 72), line(21, 78, 76, 80),
            line(20, 86, 76, 88),
            line(84, 40, 134, 40), line(84, 48, 134, 48), line(84, 56, 135, 56),
            line(84, 64, 135, 64), line(84, 72, 136, 72), line(84, 80, 137, 80),
            line(84, 88, 138, 88),
        ]

        // ── Ribbon — drapes into the gutter (reveal 0→1 with overshoot) and the
        //    tail swings to rest (sway). Anchored at the spine top. ────────────
        var ribbonPath = Path()
        let hasRibbon = reveal > 0.01
        if hasRibbon {
            let topY: CGFloat = 27
            let tailY  = 30 + 58 * reveal
            let notchY = tailY - 4.8
            let sx = sway * 5                       // pendulum offset at the tail
            let lx: CGFloat = 72.6, rx: CGFloat = 78.2, mid: CGFloat = 75.4, bow: CGFloat = 1.2
            ribbonPath.move(to: p(lx, topY))
            ribbonPath.addCurve(to: p(lx + sx, tailY),
                                control1: p(lx, topY + 12),
                                control2: p(lx - bow + sx * 0.7, tailY - 14))
            ribbonPath.addLine(to: p(mid + sx, notchY))
            ribbonPath.addLine(to: p(rx + sx, tailY))
            ribbonPath.addCurve(to: p(rx, topY),
                                control1: p(rx + bow + sx * 0.7, tailY - 14),
                                control2: p(rx, topY + 12))
            ribbonPath.closeSubpath()
        }

        // ── Page turn — curled page sweeping right → over the top → left. ──────
        var flip = Path(); var flipOpacity = 0.0
        if turnT > 0.02 && turnT < 0.98 {
            let ang = Double(turnT) * .pi
            let cA  = CGFloat(cos(ang)), arc = CGFloat(sin(ang))
            let fx  = 80 + 55 * cA
            let fbx = 80 + 60 * cA
            let topY = 30 - arc * 19
            let botY = 90 - arc * 6
            let curl = arc * 14 * (cA >= 0 ? 1 : -1)
            let cTopX = (80 + fx)  / 2 + curl
            let cBotX = (80 + fbx) / 2 + curl
            flip.move(to: p(80, 30))
            flip.addQuadCurve(to: p(fx, topY),  control: p(cTopX, topY - arc * 11))
            flip.addLine(to: p(fbx, botY))
            flip.addQuadCurve(to: p(80, 96), control: p(cBotX, botY + arc * 4.4))
            flip.closeSubpath()
            flipOpacity = sin(Double(turnT) * .pi) * 0.95
        }

        // ── Strokes ───────────────────────────────────────────────
        let pageStroke = StrokeStyle(lineWidth: 1.4 * s, lineCap: .round, lineJoin: .round)
        let thinStroke = StrokeStyle(lineWidth: 0.8 * s, lineCap: .round)
        let ribStroke  = StrokeStyle(lineWidth: 1.5 * s, lineCap: .round, lineJoin: .round)

        // Pass 1: glow
        context.drawLayer { ctx in
            ctx.addFilter(.blur(radius: 3 * s))
            ctx.opacity = 0.24
            ctx.stroke(leftPage,  with: shading, style: StrokeStyle(lineWidth: 6 * s, lineJoin: .round))
            ctx.stroke(rightPage, with: shading, style: StrokeStyle(lineWidth: 6 * s, lineJoin: .round))
            if hasRibbon {
                ctx.stroke(ribbonPath, with: shading, style: StrokeStyle(lineWidth: 5 * s, lineJoin: .round))
            }
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

        // Ribbon — bg-filled so it reads in front of the pages
        if hasRibbon {
            context.fill(ribbonPath, with: .color(AppColors.cardBg))
            context.stroke(ribbonPath, with: shading, style: ribStroke)
        }

        // Turning page — bg-filled so it occludes the pages as it sweeps
        if flipOpacity > 0.01 {
            var fc = context; fc.opacity = flipOpacity
            fc.fill(flip, with: .color(AppColors.cardBg))
            fc.stroke(flip, with: shading, style: pageStroke)
        }
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
            ),
            confirmed: true
        )
        .frame(
            width:  AppLayout.obCardWidth(in: 390),
            height: AppLayout.obCardHeight(in: 390)
        )
    }
    .preferredColorScheme(.dark)
}
