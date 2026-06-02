// Design/Components/Cards/CardFaces/ContextCardFace.swift
//
// Content face for the relationship-context cards (ContextPhase carousel).
// Rendered by VaylCardFace when its content is `.context(...)`.
//
// Signature object: an OPEN BOOK with a bookmark ribbon — the phase's identity
// ("Where are you starting from?" → which chapter of your story), mirroring how
// NamePhase uses the typewriter, ModeSelect the controller, Gender the slot
// machine, ExperienceLevel the candle. Pure Canvas line illustration in the
// spectrum language (two passes: blurred glow + crisp stroke), upper region;
// number + title sit beneath as the card's header.
//
// Life (only the FRONT card animates; all guarded by Reduce Motion):
//   · text lines write in   — a spectrum "write head" sweeps down the page lines
//   · bookmark ribbon sway  — the ribbon tail drifts gently
//   · page-turn on focus    — a page settles open when the card becomes front
//
// Dark-only, spectrum language. All geometry proportional to card width
// (OB card-face rule — no fixed pixels). `subtitle`/`detail` are retained as
// props (unused for rendering) so the 4-param `.context` call site in
// VaylCardFace keeps compiling; subtitle/detail are shown by ContextPhase in its
// bottom panel, not on the card.

import SwiftUI

struct ContextCardFace: View {

    let number:   String
    let title:    String
    let subtitle: String
    let detail:   String
    var isFront:  Bool = true

    // Page-turn is a one-shot driven on focus. 1.0 = settled/open.
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

                // Signature object — the open book + ribbon
                BookObject(animate: animate, turnProgress: turnProgress)
                    .frame(maxWidth: .infinity)
                    .frame(height: h * 0.44)

                // Spectrum hairline — ties the object to the header
                Rectangle()
                    .fill(LinearGradient(
                        colors: [AppColors.spectrumCyan, AppColors.spectrumPurple, AppColors.spectrumMagenta],
                        startPoint: .leading, endPoint: .trailing))
                    .frame(height: 1)
                    .opacity(0.5)
                    .padding(.top, h * 0.035)
                    .padding(.bottom, h * 0.03)

                // Header — number overline + title headline
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

    /// One-shot page settle when this card becomes the front card.
    private func firePageTurn() {
        guard !reduceMotion else { turnProgress = 1; return }
        turnProgress = 0
        withAnimation(.easeOut(duration: 0.55)) { turnProgress = 1 }
    }
}

// MARK: - Book object (Canvas line illustration)

/// Open book + bookmark ribbon. Continuous motion (text write-in + ribbon sway)
/// is self-driven by a TimelineView while `animate` is true; the one-shot page
/// turn is driven externally via `turnProgress`. When `animate` is false (not the
/// front card, or Reduce Motion) the book renders fully static: all lines bright,
/// ribbon centered, page settled.
private struct BookObject: View {

    let animate:      Bool
    let turnProgress: CGFloat

    var body: some View {
        if animate {
            TimelineView(.animation) { tl in
                let t = tl.date.timeIntervalSinceReferenceDate
                let textPhase = CGFloat((t / 2.4).truncatingRemainder(dividingBy: 1)) // 0→1 loop
                let ribbon    = CGFloat(sin(t / 2.6 * 2 * .pi))                        // -1→1
                Canvas { ctx, size in
                    draw(&ctx, size: size, textPhase: textPhase, ribbon: ribbon,
                         turn: turnProgress, full: false)
                }
            }
        } else {
            Canvas { ctx, size in
                draw(&ctx, size: size, textPhase: 0, ribbon: 0, turn: 1, full: true)
            }
        }
    }

    /// Draw the book. `textPhase` positions the write-head band; `ribbon` sways the
    /// tail; `turn` (0→1) opens the settling page; `full` renders every line bright.
    private func draw(_ context: inout GraphicsContext, size: CGSize,
                      textPhase: CGFloat, ribbon: CGFloat, turn: CGFloat, full: Bool) {

        let s: CGFloat = size.width / 160
        let drawnH = 120 * s
        context.translateBy(x: 0, y: max(0, (size.height - drawnH) / 2))

        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * s, y: y * s) }

        let specGrad = Gradient(stops: [
            .init(color: AppColors.spectrumCyan,    location: 0.00),
            .init(color: AppColors.spectrumPurple,  location: 0.50),
            .init(color: AppColors.spectrumMagenta, location: 1.00),
        ])
        let shading = GraphicsContext.Shading.linearGradient(
            specGrad,
            startPoint: CGPoint(x: 0, y: 0),
            endPoint:   CGPoint(x: 160 * s, y: 120 * s))

        // ── Geometry (160 × 120 viewbox) ──────────────────────────
        let spineTopY: CGFloat = 30, spineBotY: CGFloat = 96, cx: CGFloat = 80

        // Left page (closed quad, belly curve on the bottom)
        var leftPage = Path()
        leftPage.move(to: p(cx, spineTopY))
        leftPage.addLine(to: p(16, 42))
        leftPage.addLine(to: p(13, 88))
        leftPage.addQuadCurve(to: p(cx, spineBotY), control: p(46, 94))
        leftPage.closeSubpath()

        // Right page (mirror)
        var rightPage = Path()
        rightPage.move(to: p(cx, spineTopY))
        rightPage.addLine(to: p(144, 42))
        rightPage.addLine(to: p(147, 88))
        rightPage.addQuadCurve(to: p(cx, spineBotY), control: p(114, 94))
        rightPage.closeSubpath()

        // Spine
        var spine = Path()
        spine.move(to: p(cx, spineTopY))
        spine.addLine(to: p(cx, spineBotY))

        // Text lines — 4 per page; brightened by the sweeping write-head band
        let lineYs: [CGFloat] = [50, 60, 70, 80]
        let bandY = 46 + (84 - 46) * textPhase   // sweeps top→bottom
        func lineBrightness(_ y: CGFloat) -> Double {
            if full { return 0.85 }
            let d = abs(y - bandY)
            let near = max(0, 1 - d / 9)          // 1 at band, 0 by ~9 units
            return 0.22 + 0.68 * Double(near)
        }
        func textLine(_ x0: CGFloat, _ x1: CGFloat, _ y: CGFloat) -> Path {
            var pa = Path(); pa.move(to: p(x0, y)); pa.addLine(to: p(x1, y)); return pa
        }

        // Bookmark ribbon — top fixed at spine, tail sways; swallowtail notch
        let ribTopY: CGFloat = 26, ribW: CGFloat = 5
        let tailY: CGFloat = 112
        let sway = ribbon * 6
        let tlx = cx - ribW / 2 + sway, trx = cx + ribW / 2 + sway
        var ribbonPath = Path()
        ribbonPath.move(to: p(cx - ribW / 2, ribTopY))
        ribbonPath.addLine(to: p(tlx, tailY))
        ribbonPath.addLine(to: p(cx + sway, tailY - 6))   // notch
        ribbonPath.addLine(to: p(trx, tailY))
        ribbonPath.addLine(to: p(cx + ribW / 2, ribTopY))

        // Settling page (page-turn): a page that opens from the spine out to the
        // right as `turn` goes 0→1. At rest (1) it coincides with the right page.
        let edgeX = cx + (144 - cx) * turn
        let edgeBX = cx + (147 - cx) * turn
        var turningPage = Path()
        turningPage.move(to: p(cx, spineTopY))
        turningPage.addLine(to: p(edgeX, 42))
        turningPage.addLine(to: p(edgeBX, 88))
        turningPage.addQuadCurve(to: p(cx, spineBotY), control: p(cx + (114 - cx) * turn, 94))
        turningPage.closeSubpath()

        // ── Stroke styles ─────────────────────────────────────────
        let pageStroke = StrokeStyle(lineWidth: 1.3 * s, lineCap: .round, lineJoin: .round)
        let spineStroke = StrokeStyle(lineWidth: 1.0 * s, lineCap: .round)
        let lineStroke = StrokeStyle(lineWidth: 0.8 * s, lineCap: .round)
        let ribStroke  = StrokeStyle(lineWidth: 1.5 * s, lineCap: .round, lineJoin: .round)

        // ── Pass 1: Glow — page outlines + ribbon ─────────────────
        context.drawLayer { ctx in
            ctx.addFilter(.blur(radius: 3 * s))
            ctx.opacity = 0.26
            ctx.stroke(leftPage,    with: shading, style: StrokeStyle(lineWidth: 6 * s, lineJoin: .round))
            ctx.stroke(rightPage,   with: shading, style: StrokeStyle(lineWidth: 6 * s, lineJoin: .round))
            ctx.stroke(ribbonPath,  with: shading, style: StrokeStyle(lineWidth: 5 * s, lineJoin: .round))
        }

        // ── Pass 2: Crisp ─────────────────────────────────────────

        // Text lines (drawn first, under the page edges)
        for y in lineYs {
            var lc = context; lc.opacity = lineBrightness(y)
            lc.stroke(textLine(26, 66, y),  with: shading, style: lineStroke)
            var rc = context; rc.opacity = lineBrightness(y)
            rc.stroke(textLine(94, 134, y), with: shading, style: lineStroke)
        }

        // Spine — dim
        var spineCtx = context; spineCtx.opacity = 0.5
        spineCtx.stroke(spine, with: shading, style: spineStroke)

        // Pages — full
        context.stroke(leftPage,  with: shading, style: pageStroke)
        context.stroke(rightPage, with: shading, style: pageStroke)

        // Settling page — only visible mid-turn (fades out as it lands)
        if !full && turn < 0.999 {
            var tp = context; tp.opacity = Double(1 - turn) * 0.9
            tp.stroke(turningPage, with: shading, style: pageStroke)
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
