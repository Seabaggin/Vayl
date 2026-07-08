// Vayl/Design/Components/Cards/CardFaces/CompassCardFace.swift

import SwiftUI

// Procedural card-face art: fixed hairline/stroke insets are geometry, not
// layout spacing, so raw padding values are intentional here.
// swiftlint:disable no_hardcoded_padding

// MARK: - Deflection Mapping

/// Per-layer rotation ratios for the gimbal stack. The needle leads the gesture,
/// the dial card counter-rotates against it, the gimbal ring trails with it —
/// the disagreement between layers is what sells the suspended-instrument feel.
/// Ratios locked against the approved HTML motion reference (compass-premium V3).
private enum CompassDeflection {
    static let needleMaxDegrees: Double = 55.0
    static let dialRatio: Double = -0.5   // of needle angle
    static let gimbalRatio: Double =  0.4   // of needle angle
}

// MARK: - Geometry

/// All compass math resolved once per render — no arithmetic inside the Canvas
/// closures or any @ViewBuilder. Proportional to canvas size, zero fixed pixels.
/// Pattern mirrors RadioTunerGeometry / TypewriterGeometry.
///
/// All paths are built centered on the canvas midpoint; rotation is applied by
/// `.rotationEffect` on the layer views (animatable), never inside the Canvas.
private struct CompassGeometry {

    let center: CGPoint
    let radius: CGFloat   // outer gimbal reach — everything scales from this

    // ── Paths ────────────────────────────────────────────────────────────────
    let gimbalRingPath: Path   // outer ellipse — tilts with the drag
    let gimbalPivotsPath: Path   // two pivot circles on the gimbal axis
    let bowlOuterPath: Path   // static bowl rings
    let bowlInnerPath: Path
    let dialTicksPath: Path   // 8 bearing ticks — counter-rotates
    let needleNorthPath: Path   // cyan dart
    let needleSouthPath: Path   // magenta dart
    let hubPath: Path   // static jeweled bearing
    let hubDotRect: CGRect

    // ── N marker (drawn as text on the dial layer) ───────────────────────────
    let northMarkPoint: CGPoint
    let northMarkFont: Font

    // ── Shading ──────────────────────────────────────────────────────────────
    let shading: GraphicsContext.Shading

    // ── Stroke styles ────────────────────────────────────────────────────────
    let glowStroke: StrokeStyle
    let crispStroke: StrokeStyle   // gimbal + bowl + hub
    let tickStroke: StrokeStyle   // dial ticks — thinner, dimmed
    let needleStroke: StrokeStyle

    init(size: CGSize) {
        let c = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        // Sized so the gimbal ring plus glow bloom clears the zone edges.
        let r = min(size.width, size.height) * 0.42

        center = c
        radius = r

        // ── Gimbal ring — slightly squashed ellipse + axis pivots ──────────
        gimbalRingPath = Path(ellipseIn: CGRect(
            x: c.x - r, y: c.y - r * 0.95, width: r * 2.0, height: r * 1.90
        ))
        gimbalPivotsPath = Path { p in
            let pr = r * 0.05
            p.addEllipse(in: CGRect(x: c.x - r - pr, y: c.y - pr, width: pr * 2, height: pr * 2))
            p.addEllipse(in: CGRect(x: c.x + r - pr, y: c.y - pr, width: pr * 2, height: pr * 2))
        }

        // ── Bowl — static double ring the dial floats inside ───────────────
        let bowlR = r * 0.74
        bowlOuterPath = Path(ellipseIn: CGRect(
            x: c.x - bowlR, y: c.y - bowlR, width: bowlR * 2, height: bowlR * 2
        ))
        let innerR = r * 0.665
        bowlInnerPath = Path(ellipseIn: CGRect(
            x: c.x - innerR, y: c.y - innerR, width: innerR * 2, height: innerR * 2
        ))

        // ── Dial card — 8 bearing ticks every 45° ──────────────────────────
        dialTicksPath = Path { p in
            let tickIn: CGFloat = r * 0.55
            let tickOut: CGFloat = r * 0.65
            for i in 0..<8 {
                let a = CGFloat(i) * .pi / 4.0 - .pi / 2.0
                p.move(to: CGPoint(x: c.x + cos(a) * tickIn, y: c.y + sin(a) * tickIn))
                p.addLine(to: CGPoint(x: c.x + cos(a) * tickOut, y: c.y + sin(a) * tickOut))
            }
        }
        northMarkPoint = CGPoint(x: c.x, y: c.y - r * 0.78)
        northMarkFont  = AppFonts.body(r * 0.16, weight: .medium, relativeTo: .caption)

        // ── Needle — north dart leads, south dart counterweights ───────────
        needleNorthPath = Path { p in
            p.move(to: CGPoint(x: c.x, y: c.y - r * 0.577))
            p.addLine(to: CGPoint(x: c.x + r * 0.077, y: c.y - r * 0.064))
            p.addLine(to: CGPoint(x: c.x, y: c.y + r * 0.026))
            p.addLine(to: CGPoint(x: c.x - r * 0.077, y: c.y - r * 0.064))
            p.closeSubpath()
        }
        needleSouthPath = Path { p in
            p.move(to: CGPoint(x: c.x, y: c.y + r * 0.577))
            p.addLine(to: CGPoint(x: c.x + r * 0.077, y: c.y + r * 0.064))
            p.addLine(to: CGPoint(x: c.x, y: c.y - r * 0.026))
            p.addLine(to: CGPoint(x: c.x - r * 0.077, y: c.y + r * 0.064))
            p.closeSubpath()
        }

        // ── Hub — jeweled bearing over the needle pivot ─────────────────────
        let hubR = r * 0.0705
        hubPath = Path(ellipseIn: CGRect(
            x: c.x - hubR, y: c.y - hubR, width: hubR * 2, height: hubR * 2
        ))
        let dotR = r * 0.026
        hubDotRect = CGRect(x: c.x - dotR, y: c.y - dotR, width: dotR * 2, height: dotR * 2)

        // ── Spectrum gradient across the instrument ─────────────────────────
        shading = .linearGradient(
            Gradient(colors: [
                AppColors.spectrumCyan,
                AppColors.spectrumPurple,
                AppColors.spectrumMagenta
            ]),
            startPoint: CGPoint(x: c.x - r, y: c.y - r),
            endPoint: CGPoint(x: c.x + r, y: c.y + r)
        )

        // ── Stroke styles — thin watchmaker lines, glow pass bloomed ───────
        let lw = r * 0.025
        glowStroke   = StrokeStyle(lineWidth: lw * 2.6, lineCap: .round)
        crispStroke  = StrokeStyle(lineWidth: lw, lineCap: .round)
        tickStroke   = StrokeStyle(lineWidth: lw * 0.65, lineCap: .round)
        needleStroke = StrokeStyle(lineWidth: lw * 1.1, lineCap: .round, lineJoin: .round)
    }
}

// MARK: - CompassCardFace

/// Card face for CuriosityPhase sort cards — a gimbaled ship's compass whose
/// needle is operated by the keep/pass swipe itself.
///
/// `deflection` −1.0 (full PASS) … 1.0 (full KEEP), normally drag ÷ commit
/// threshold. Three layers rotate independently for parallax depth:
///   • outer gimbal ring tilts with the drag,
///   • the dial card (ticks + N) counter-rotates against it,
///   • the needle leads.
/// Rotations are `.rotationEffect` on separate Canvas layers — animatable, so
/// the director's cardSettle snap-back springs the needle home for free.
///
/// Instrument-readout layout — the context card's anatomy (illustration →
/// hairline rule → overline → gradient title) with every typographic element
/// re-cast as part of the instrument:
///   • the hairline rule is a HEADING RULER whose index marker slides with the
///     needle,
///   • the overline is a LIVE BEARING readout (BRG 000° → E — KEEP / W — PASS),
///     tinting cyan or magenta as the drag commits,
///   • the title is the spectrum-gradient topic, left-aligned like the deck.
///
/// Glow + crisp passes per the OB card-face rule; spectrum gradient on every
/// stroke. South needle is spectrumMagenta by explicit direction — never red.
/// Visual chrome (spectrum card border, hairlines, atmosphere) comes from the
/// VaylCardFace shell.
struct CompassCardFace: View {

    let cardWidth: CGFloat
    let cardHeight: CGFloat
    let topic: String
    let deflection: Double   // −1 … 1

    /// Dead band around center where the readout stays neutral — keeps the
    /// bearing from flickering KEEP/PASS on incidental finger wobble.
    private static let neutralBand: Double = 0.08

    private var clamped: Double { min(max(deflection, -1.0), 1.0) }

    private var needleDegrees: Double {
        clamped * CompassDeflection.needleMaxDegrees
    }

    var body: some View {
        GeometryReader { geo in
            let w   = geo.size.width
            let h   = geo.size.height
            let pad = w * 0.10

            VStack(alignment: .leading, spacing: 0) {

                Spacer(minLength: 0)

                // ── Instrument ────────────────────────────────────────────
                ZStack {
                    gimbalLayer
                        .rotationEffect(.degrees(needleDegrees * CompassDeflection.gimbalRatio))
                    bowlLayer
                    dialLayer
                        .rotationEffect(.degrees(needleDegrees * CompassDeflection.dialRatio))
                    needleLayer
                        .rotationEffect(.degrees(needleDegrees))
                    hubLayer
                }
                .frame(maxWidth: .infinity)
                .frame(height: h * 0.42)

                // ── Heading ruler — the rule, as part of the instrument ───
                HeadingRuler(deflection: clamped, indexColor: directionColor)
                    .frame(height: h * 0.030)
                    .padding(.top, h * 0.035)
                    .padding(.bottom, h * 0.03)

                // ── Live bearing readout — the overline ───────────────────
                Text(bearingText)
                    .font(AppFonts.overline)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .foregroundStyle(bearingStyle)
                    .opacity(isNeutral ? 0.55 : 1.0)

                // ── Topic — the gradient title ────────────────────────────
                // Proportional type: the sort cards are far smaller than the
                // context cards (obTableCardWidth ~30% of screen × cinematic
                // 1.5), so a fixed point size overflows. 0.085 × cardWidth ≈
                // the context card's display-24 at its 280pt width.
                // Fixed-height zone so a long topic can never push the
                // instrument; content budget ≤ 45 chars (see design spec) →
                // ≤ 3 lines before minimumScaleFactor engages.
                Text(topic)
                    .font(AppFonts.display(w * 0.085, weight: .semibold, relativeTo: .title2))
                    .foregroundStyle(AppColors.spectrumText)
                    .lineLimit(3)
                    .minimumScaleFactor(0.8)
                    .padding(.top, w * 0.02)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .frame(height: h * 0.24, alignment: .topLeading)

                Spacer(minLength: 0)
            }
            .padding(pad)
            .frame(width: geo.size.width, height: geo.size.height, alignment: .leading)
        }
        .frame(width: cardWidth, height: cardHeight)
    }

    // MARK: - Bearing readout

    private var isNeutral: Bool { abs(clamped) <= Self.neutralBand }

    private var bearingText: String {
        guard !isNeutral else { return "BRG 000°" }
        let degrees = String(format: "BRG %03d°", Int(abs(needleDegrees).rounded()))
        return clamped > 0 ? degrees + " E — KEEP" : degrees + " W — PASS"
    }

    /// Cyan toward keep, magenta toward pass — matches the needle's darts.
    private var directionColor: Color {
        if isNeutral { return AppColors.spectrumPurple }
        return clamped > 0 ? AppColors.spectrumCyan : AppColors.spectrumMagenta
    }

    private var bearingStyle: AnyShapeStyle {
        isNeutral ? AnyShapeStyle(AppColors.spectrumText) : AnyShapeStyle(directionColor)
    }

    // MARK: - Layers

    /// Outer gimbal ring + axis pivots — tilts with the drag.
    private var gimbalLayer: some View {
        Canvas { context, size in
            let g = CompassGeometry(size: size)

            var glowCtx = context
            glowCtx.addFilter(.blur(radius: 7))
            glowCtx.opacity = 0.26
            glowCtx.stroke(g.gimbalRingPath, with: g.shading, style: g.glowStroke)

            context.stroke(g.gimbalRingPath, with: g.shading, style: g.crispStroke)
            context.stroke(g.gimbalPivotsPath, with: g.shading, style: g.crispStroke)
        }
    }

    /// Static bowl rings the dial floats inside.
    private var bowlLayer: some View {
        Canvas { context, size in
            let g = CompassGeometry(size: size)

            var glowCtx = context
            glowCtx.addFilter(.blur(radius: 6))
            glowCtx.opacity = 0.22
            glowCtx.stroke(g.bowlOuterPath, with: g.shading, style: g.glowStroke)

            context.stroke(g.bowlOuterPath, with: g.shading, style: g.crispStroke)

            var innerCtx = context
            innerCtx.opacity = 0.50
            innerCtx.stroke(g.bowlInnerPath, with: g.shading, style: g.crispStroke)
        }
    }

    /// Dial card — bearing ticks + N marker, counter-rotates against the needle.
    private var dialLayer: some View {
        Canvas { context, size in
            let g = CompassGeometry(size: size)

            var tickCtx = context
            tickCtx.opacity = 0.70
            tickCtx.stroke(g.dialTicksPath, with: g.shading, style: g.tickStroke)

            context.draw(
                Text(verbatim: "N")
                    .font(g.northMarkFont)
                    .foregroundStyle(AppColors.spectrumPurple),
                at: g.northMarkPoint
            )
        }
    }

    /// The needle — cyan north dart, magenta south counterweight.
    private var needleLayer: some View {
        Canvas { context, size in
            let g = CompassGeometry(size: size)

            context.stroke(g.needleNorthPath, with: .color(AppColors.spectrumCyan), style: g.needleStroke)

            var southCtx = context
            southCtx.opacity = 0.75
            southCtx.stroke(g.needleSouthPath, with: .color(AppColors.spectrumMagenta), style: g.needleStroke)
        }
    }

    /// Jeweled bearing over the pivot — static, draws above the needle.
    private var hubLayer: some View {
        Canvas { context, size in
            let g = CompassGeometry(size: size)
            context.stroke(g.hubPath, with: g.shading, style: g.crispStroke)
            context.fill(Path(ellipseIn: g.hubDotRect), with: .color(AppColors.spectrumPurple))
        }
    }
}

// MARK: - HeadingRuler

/// The card's hairline rule, re-cast as a heading scale: a spectrum baseline
/// with bearing ticks and an index triangle that slides with the needle
/// deflection. The offset is animatable, so the director's cardSettle snap-back
/// springs the index home together with the needle.
private struct HeadingRuler: View {

    let deflection: Double   // −1 … 1, pre-clamped
    let indexColor: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            // Index travel stops short of the rule ends, like a real scale.
            let travel = w * 0.44

            ZStack(alignment: .bottom) {

                // Baseline + ticks — static.
                Canvas { context, size in
                    let baseY = size.height - 0.5

                    var baseline = Path()
                    baseline.move(to: CGPoint(x: 0, y: baseY))
                    baseline.addLine(to: CGPoint(x: size.width, y: baseY))

                    let shading = GraphicsContext.Shading.linearGradient(
                        Gradient(colors: [
                            AppColors.spectrumCyan,
                            AppColors.spectrumPurple,
                            AppColors.spectrumMagenta
                        ]),
                        startPoint: .zero,
                        endPoint: CGPoint(x: size.width, y: 0)
                    )

                    var baseCtx = context
                    baseCtx.opacity = 0.55
                    baseCtx.stroke(baseline, with: shading, style: StrokeStyle(lineWidth: 1))

                    // 9 bearing ticks — center tallest, then alternating depths.
                    var ticks = Path()
                    for i in 0..<9 {
                        let x = size.width * (0.06 + CGFloat(i) * 0.11)
                        let depth: CGFloat = i == 4 ? 0.70 : (i % 2 == 0 ? 0.45 : 0.28)
                        ticks.move(to: CGPoint(x: x, y: baseY))
                        ticks.addLine(to: CGPoint(x: x, y: baseY - size.height * depth))
                    }
                    var tickCtx = context
                    tickCtx.opacity = 0.60
                    tickCtx.stroke(ticks, with: .color(AppColors.spectrumPurple),
                                   style: StrokeStyle(lineWidth: 1, lineCap: .round))
                }

                // Index marker — slides with the needle.
                RulerIndex()
                    .fill(indexColor)
                    .frame(width: h * 0.55, height: h * 0.42)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .offset(x: CGFloat(deflection) * travel)
                    .frame(maxHeight: .infinity, alignment: .top)
            }
            .frame(width: w, height: h)
        }
    }
}

/// Small downward-pointing index triangle for the heading ruler.
private struct RulerIndex: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            p.closeSubpath()
        }
    }
}

// MARK: - Preview

#Preview("Compass — device size, longest topic") {
    // Real sort-card footprint on a 390pt phone:
    // obTableCardWidth (30%) × cinematic scale (1.5) ≈ 176 × 263.
    let w = AppLayout.obTableCardWidth(in: 390) * AppLayout.obTableCardCinematicScale
    let h = AppLayout.obTableCardHeight(in: 390) * AppLayout.obTableCardCinematicScale

    ZStack {
        AppColors.cardBg.ignoresSafeArea()

        CompassCardFace(
            cardWidth: w,
            cardHeight: h,
            topic: "What I want — not what I've settled for",
            deflection: 0
        )
        .frame(width: w, height: h)
    }
    .clipShape(RoundedRectangle(cornerRadius: 14))
    .padding(40)
    .preferredColorScheme(.dark)
}

#Preview("Compass — interactive deflection") {
    struct DeflectionPreview: View {
        @State private var deflection: Double = 0.4
        let w: CGFloat = 280
        let h: CGFloat = 420

        var body: some View {
            VStack(spacing: AppSpacing.lg) {
                ZStack {
                    AppColors.cardBg

                    CompassCardFace(
                        cardWidth: w,
                        cardHeight: h,
                        topic: "I don't know what I actually want",
                        deflection: deflection
                    )
                }
                .frame(width: w, height: h)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                Slider(value: $deflection, in: -1...1)
                    .frame(width: w)
            }
            .padding(40)
        }
    }

    return DeflectionPreview()
        .preferredColorScheme(.dark)
}
