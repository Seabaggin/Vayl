// Shared/Components/VaylCardFace.swift

import SwiftUI

// MARK: - VaylCardFace

/// Front face of the Vayl card.
///
/// Visible during:
///   · PAUSE phase of OB deal — ornamental, question nil
///   · All OB phases — question passed in, rendered centered upper zone
///   · LIFT phase → card expands to near full screen
///
/// The card owns:
///   · Shell — base, atmosphere, hairlines, frame, border glow
///   · Spectrum diamond — center motif, dims when question present
///   · ✦ corner marks
///   · Question text — when question != nil
///   · Content face — when content != nil (mode, curiosity, etc.)
///
/// The caller owns:
///   · frame · scale · rotation · opacity · offset · shadow
///   · All interactive overlays (write line, greeting, pills)
///
/// NamePhase positions WriteLineView and greeting overlay
/// over this card's frame. This component never knows about
/// typed names, selections, or interaction state.

struct VaylCardFace: View {

    var question:   String?                      = nil
    var credential: OBCredential?                = nil
    var content:    VaylCardContent?             = nil
    var onAction:   ((VaylCardAction) -> Void)?  = nil

    /// True when this card is the frontmost card in a browsable stack.
    /// Only consulted by content faces that reveal extra detail when frontmost
    /// (currently `.context`). Ignored by all other faces. Defaults true.
    var isFront:    Bool                         = true

    /// True when this card is the confirmed selection. Forwarded to `.context`
    /// so the bookmark ribbon drops in on confirm. Ignored by all other faces.
    var confirmed:  Bool                         = false

    /// Deck identity tint (Play / session). nil = the canonical fixed look — Onboarding
    /// passes nothing and renders byte-identical to before.
    var colorway:   FoilColorway?                = nil
    /// Card weight 0…1 (from intensity) — drives the base-heat glow. Ignored when colorway is nil.
    var heat:       Double                       = 0
    /// Faint category-glyph watermark — a path in a 44×40 box. nil = none.
    var glyphPath:  Path?                         = nil

    var body: some View {
        GeometryReader { geo in
            let size      = geo.size
            let shortSide = min(size.width, size.height)
            let radius    = AppRadius.obCard

            ZStack {

                // ── 1 · Void base ──────────────────────────────────
                AppColors.cardBg

                // ── 2 · Atmosphere ─────────────────────────────────
                FaceAtmosphere(size: size, shortSide: shortSide, colorway: colorway, heat: heat)

                // ── 3 · Spectrum border glow ───────────────────────
                // Resting-state ambient bloom at card edge.
                // Uses AppGlows.spectrumBorder outer layer at fixed opacity —
                // this is not a press-driven glow so spectrumBorderGlow(intensity:)
                // does not apply here.
                RoundedRectangle(cornerRadius: radius)
                    .stroke(
                        AppGlows.spectrumBorder.outer.color,
                        lineWidth: AppGlows.spectrumBorder.strokeResting
                    )
                    .blur(radius: AppGlows.spectrumBorder.outer.radius)
                    .padding(0.75)

                // ── 3b · Deck identity + card weight (Play / session only) ─
                // Generated from the deck colorway + card intensity; nil colorway = OB,
                // skipped entirely → canonical look. Sits behind the question text; the
                // shell (frame, hairlines, border, drawingGroup) is untouched.
                if let colorway {
                    if let glyphPath {
                        GlyphWatermark(path: glyphPath, color: colorway.c1, heat: heat)
                    }
                    CardHeatGlow(colorway: colorway, heat: heat)
                }

                // ── 4 · Content face — when VaylCardContent is provided ─
                // Extracted to contentFace(for:size:) so the GeometryReader body
                // remains a short expression — long switch statements inside
                // GeometryReader cause quadratic Swift type-checking overhead.
                if let content {
                    contentFace(for: content, size: size)
                }

                // ── 5 · Question text ──────────────────────────────
                if let question {
                    QuestionText(question: question, size: size)
                        .transition(.opacity.combined(with: .offset(y: 6)))
                }

                // ── 6 · Top hairline ───────────────────────────────
                CardHairline(size: size, edge: .top)

                // ── 7 · Bottom hairline ────────────────────────────
                CardHairline(size: size, edge: .bottom)

                // ── 8 · Inset frame ────────────────────────────────
                RoundedRectangle(cornerRadius: radius - 4)
                    .strokeBorder(AppColors.spectrumBorder, lineWidth: 0.55)
                    .opacity(0.27)
                    .padding(9)

                // ── 9 · Outer hairline ─────────────────────────────
                RoundedRectangle(cornerRadius: radius)
                    .strokeBorder(AppColors.spectrumBorder, lineWidth: 1.1)
                    .opacity(0.52)
                    .padding(0.75)



            }
            .contentShape(RoundedRectangle(cornerRadius: radius))
            // Built-in tap/swipe-up gestures attach ONLY when the caller wants
            // to receive actions. With `onAction == nil` (e.g. a card embedded in
            // a carousel that owns its own browse gestures) the face is fully
            // inert and never swallows the parent's drag.
            .modifier(FaceGestures(
                enabled:    onAction != nil,
                cardHeight: geo.size.height,
                onAction:   onAction
            ))
            .clipShape(RoundedRectangle(cornerRadius: radius))
        }
        .drawingGroup() // rasterize ZStack of gradients + strokes to Metal texture for card transforms
    }

    // MARK: - Content face router
    //
    // Extracted from body so the GeometryReader closure stays short.
    // Long switch statements inside a GeometryReader body compound the
    // result-builder type-check cost — pulling the switch into a named
    // @ViewBuilder function lets the compiler handle each in isolation.

    @ViewBuilder
    private func contentFace(for content: VaylCardContent, size: CGSize) -> some View {
        switch content {
        case .typewriter(let activeKey, let carriageProgress):
            TypewriterCardFace(
                cardWidth:        size.width,
                cardHeight:       size.height,
                activeKey:        activeKey,
                carriageProgress: carriageProgress
            )
        case .slotMachine:
            SlotMachineCardFace(
                cardWidth:  size.width,
                cardHeight: size.height
            )
        case .radioTuner(let sig, let phase, let left, let right):
            RadioTunerCardFace(
                cardWidth:         size.width,
                cardHeight:        size.height,
                signalStrength:    sig,
                scanPhase:         phase,
                leftDialProgress:  left,
                rightDialProgress: right
            )
        case .controller(let activeButtons):
            ControllerCardFace(
                cardWidth:     size.width,
                cardHeight:    size.height,
                activeButtons: activeButtons
            )
        case .dualController(let front, let back):
            DualControllerCardFace(
                cardWidth:          size.width,
                cardHeight:         size.height,
                activeButtonsFront: front,
                activeButtonsBack:  back
            )
        case .mode(let title, let subtitle, let motif):
            ModeFaceContent(
                title:    title,
                subtitle: subtitle,
                motif:    motif,
                cardSize: size,
                lifted:   false,
                onAction: onAction
            )
        case .candle(let intensity, let time):
            CandleCardFace(intensity: intensity, time: time)
        case .compassOption(let label):
            CompassOptionCardFace(
                cardWidth:  size.width,
                cardHeight: size.height,
                label:      label
            )
        case .compassSlider(let value, let dragging):
            CompassSliderCardFace(
                cardWidth:  size.width,
                cardHeight: size.height,
                value:      value,
                dragging:   dragging
            )
        case .snapshot(let verb, let noun, let toneProgress, let sealProgress):
            SnapshotCardFace(
                cardWidth:    size.width,
                cardHeight:   size.height,
                verb:         verb,
                noun:         noun,
                toneProgress: toneProgress,
                sealProgress: sealProgress
            )
        case .context(let number, let title, let subtitle, let detail):
            ContextCardFace(
                number:    number,
                title:     title,
                subtitle:  subtitle,
                detail:    detail,
                isFront:   isFront,
                confirmed: confirmed
            )
        case .curiosity(let category, let deflection):
            CompassCardFace(
                cardWidth:  size.width,
                cardHeight: size.height,
                topic:      category,
                deflection: deflection
            )
        default:
            EmptyView()
        }
    }
}

// MARK: - FaceGestures

/// Conditionally attaches the card's built-in tap (`.tapped`) and swipe-up
/// (`.swipedUp`) gestures. When `enabled` is false the face passes all touches
/// straight through — used when a parent (e.g. a carousel) owns the gestures.
private struct FaceGestures: ViewModifier {
    let enabled:    Bool
    let cardHeight: CGFloat
    let onAction:   ((VaylCardAction) -> Void)?

    func body(content: Content) -> some View {
        if enabled {
            content
                .onTapGesture { onAction?(.tapped) }
                .gesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged { value in
                            // Live drag forwarding (opt-in via .dragChanged) — lets a phase make
                            // the lifted card track the finger. Consumers that don't handle
                            // .dragChanged ignore it, so no existing card's behaviour changes.
                            onAction?(.dragChanged(translation: value.translation))
                        }
                        .onEnded { value in
                            let velocity    = value.predictedEndLocation.y - value.location.y
                            let translation = value.translation.height
                            if translation <= -(cardHeight * 0.14) || velocity <= -400 {
                                onAction?(.swipedUp)                      // committed hand-off
                            } else {
                                onAction?(.dragEnded(velocity: .zero))   // released short → spring back
                            }
                        }
                )
        } else {
            content
        }
    }
}

// MARK: - FaceAtmosphere

/// Front atmosphere is quieter than the back.
/// Opacity values ~20% lower — front is the still side.

private struct FaceAtmosphere: View {
    let size:      CGSize
    let shortSide: CGFloat
    var colorway:  FoilColorway? = nil
    var heat:      Double        = 0

    var body: some View {
        if let colorway {
            tinted(colorway)
        } else {
            canonical
        }
    }

    /// The canonical fixed look — cyan / magenta / purple. Onboarding and any untinted
    /// caller. Unchanged from the original face.
    private var canonical: some View {
        ZStack {
            RadialGradient(
                colors: [AppColors.spectrumCyan.opacity(0.07), .clear],
                center: UnitPoint(x: 0.30, y: 0.32),
                startRadius: 0,
                endRadius: shortSide * 0.48
            )
            RadialGradient(
                colors: [AppColors.spectrumMagenta.opacity(0.07), .clear],
                center: UnitPoint(x: 0.72, y: 0.70),
                startRadius: 0,
                endRadius: shortSide * 0.48
            )
            RadialGradient(
                colors: [AppColors.spectrumPurple.opacity(0.11), .clear],
                center: .center,
                startRadius: 0,
                endRadius: shortSide * 0.44
            )
        }
    }

    /// Deck-tinted: the three blobs take the deck's colorway, and overall presence rises
    /// with the card's heat (intensity). Same geometry as canonical.
    private func tinted(_ cw: FoilColorway) -> some View {
        let base = 0.07 + heat * 0.10
        return ZStack {
            RadialGradient(
                colors: [cw.c0.opacity(base), .clear],
                center: UnitPoint(x: 0.30, y: 0.30),
                startRadius: 0,
                endRadius: shortSide * 0.50
            )
            RadialGradient(
                colors: [cw.c2.opacity(base), .clear],
                center: UnitPoint(x: 0.72, y: 0.72),
                startRadius: 0,
                endRadius: shortSide * 0.50
            )
            RadialGradient(
                colors: [cw.c1.opacity(base + 0.04), .clear],
                center: .center,
                startRadius: 0,
                endRadius: shortSide * 0.46
            )
        }
    }
}

// MARK: - CardHeatGlow

/// Bottom-up glow in the deck colorway — taller and brighter with heat (card intensity).
/// Play / session only; sits behind the question text.
private struct CardHeatGlow: View {
    let colorway: FoilColorway
    let heat:     Double

    var body: some View {
        GeometryReader { geo in
            LinearGradient(
                colors: [colorway.c2.opacity(0), colorway.c1.opacity(0.05 + heat * 0.20)],
                startPoint: .top,
                endPoint:   .bottom
            )
            .frame(height: geo.size.height * (0.22 + heat * 0.34))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .blendMode(.plusLighter)
        .allowsHitTesting(false)
    }
}

// MARK: - GlyphWatermark

/// Faint category-glyph watermark behind the question. Takes a Path in a 44×40 box, so
/// Design stays decoupled from Play's DeckGlyphKind, and tints it to the colorway.
private struct GlyphWatermark: View {
    let path:  Path
    let color: Color
    let heat:  Double

    var body: some View {
        GeometryReader { geo in
            let s  = min(geo.size.width, geo.size.height) * 0.5 / 44
            let gw = 44 * s
            let gh = 40 * s
            let t  = CGAffineTransform(scaleX: s, y: s)
                .concatenating(.init(translationX: (geo.size.width - gw) / 2,
                                     y: (geo.size.height - gh) / 2))
            path.applying(t)
                .stroke(color.opacity(0.10 + heat * 0.05),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
        .allowsHitTesting(false)
    }
}



// MARK: - QuestionText

/// Vertically centered between topPad and botPad zones.
///
/// topPad — 28pt when no type label (standard OB card face).
///           Phase overlays handle label-present cases externally.
/// botPad — 28pt — space above bottom hairline.

private struct QuestionText: View {
    let question: String
    let size:     CGSize

    private let topPad: CGFloat = AppSpacing.lg    // 24pt
    private let botPad: CGFloat = AppSpacing.lg    // 24pt

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: topPad)

            Spacer()

            Text(question)
                .font(AppFonts.prompt)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppColors.textBody)
                .lineSpacing(AppSpacing.sm)
                .padding(.horizontal, AppSpacing.lg)

            Spacer()

            Spacer().frame(height: botPad)
        }
        .frame(width: size.width, height: size.height)
    }
}

// MARK: - CardHairline

/// Spectrum hairline at top or bottom card edge.
///
/// top:    y = 0.75pt
/// bottom: y = cardHeight − 0.75pt
/// x:      14pt → cardWidth − 14pt

private enum CardEdge { case top, bottom }

private struct CardHairline: View {
    let size: CGSize
    let edge: CardEdge

    private var y: CGFloat {
        edge == .top ? 0.75 : size.height - 0.75
    }

    var body: some View {
        Path { p in
            p.move(to:    CGPoint(x: 14,              y: y))
            p.addLine(to: CGPoint(x: size.width - 14, y: y))
        }
        .stroke(AppColors.spectrumBorder, lineWidth: 1.2)
        .opacity(0.60)
        .frame(width: size.width, height: size.height)
    }
}

// MARK: - ModeFaceContent

/// Glass bar motif for ModeSelectPhase cards.
/// Single bar = Solo Discovery. Dual bars = Shared Journey (together).
/// Handles tap → .tapped and swipe-up → .swipedUp via onAction.

private struct ModeFaceContent: View {
    let title:    String
    let subtitle: String
    let motif:    ModeMotifStyle
    let cardSize: CGSize
    let lifted:   Bool
    let onAction: ((VaylCardAction) -> Void)?

    @State private var holoShift: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Bar rendering constants — relative to card width.
    private var barW:      CGFloat { cardSize.width  * 0.20 }
    private var barH:      CGFloat { barW * 3.08 }
    private var barGap:    CGFloat { cardSize.width  * 0.16 }
    private let barRadius: CGFloat = 3

    /// Single unified gradient for all bars regardless of motif.
    /// Magenta top → purple mid → cyan bottom.
    /// The number of bars communicates Solo vs Shared — not the color.
    private var gradColors: [Color] {
        [
            AppColors.spectrumMagenta,
            AppColors.spectrumPurple,
            AppColors.spectrumCyan,
        ]
    }

    private func startHoloShift() {
        guard !reduceMotion, !AppAnimation.lowPower else { return }
        withAnimation(
            .easeInOut(duration: 2.6)
            .repeatForever(autoreverses: true)
        ) {
            holoShift = 1.0
        }
    }

    // MARK: — Bar Canvas

    private func barCanvas(reversed: Bool) -> some View {
        let colors = reversed ? gradColors.reversed() : gradColors
        let bW     = barW
        let bH     = barH
        let bR     = barRadius
        let lift   = lifted
        let shift  = holoShift

        return Canvas { context, _ in
            let barRect = CGRect(x: 0, y: 0, width: bW, height: bH)
            let barPath = Path(roundedRect: barRect, cornerRadius: bR)

            // ── 1. Cast shadow — blurred ellipse below bar ────────────
            context.drawLayer { ctx in
                let shadowRect = CGRect(
                    x: bW * 0.175, y: bH + 2,
                    width: bW * 0.65, height: 10
                )
                ctx.addFilter(.blur(radius: 6))
                ctx.fill(
                    Path(ellipseIn: shadowRect),
                    with: .color(colors[1].opacity(lift ? 0.45 : 0.08))
                )
            }

            // ── 2. Bloom glow — blurred bar behind core fill ─────────
            context.drawLayer { ctx in
                ctx.addFilter(.blur(radius: 6))
                ctx.opacity = lift ? 0.65 : 0.18
                ctx.fill(barPath, with: .linearGradient(
                    Gradient(colors: colors),
                    startPoint: CGPoint(x: bW / 2, y: 0),
                    endPoint:   CGPoint(x: bW / 2, y: bH)
                ))
            }

            // ── 3. Core fill — spectrum gradient ─────────────────────
            context.fill(barPath, with: .linearGradient(
                Gradient(colors: colors),
                startPoint: CGPoint(x: bW / 2, y: 0),
                endPoint:   CGPoint(x: bW / 2, y: bH)
            ))

            // ── 4. Glass gloss — NO drawLayer, NO clip ────────────────
            // Gradient fades to .clear at 11% — self-constrains without clipping.
            // drawLayer+clip was silently failing in SwiftUI Canvas.
            context.fill(barPath, with: .linearGradient(
                Gradient(stops: [
                    .init(color: .white.opacity(0.92), location: 0.000),
                    .init(color: .white.opacity(0.32), location: 0.028),
                    .init(color: .white.opacity(0.06), location: 0.070),
                    .init(color: .white.opacity(0.00), location: 0.110),
                    .init(color: .white.opacity(0.00), location: 1.000),
                ]),
                startPoint: CGPoint(x: bW / 2, y: 0),
                endPoint:   CGPoint(x: bW / 2, y: bH)
            ))

            // ── 5. Specular sweep — diagonal, animated by holoShift ──
            // Fades to .clear at both ends — no clip needed.
            let specX1 = CGPoint(x: shift * (-bW * 1.5), y: 0)
            let specX2 = CGPoint(x: shift * (bW * 2.5) + bW, y: bH)
            context.fill(barPath, with: .linearGradient(
                Gradient(stops: [
                    .init(color: .clear,                                location: 0.00),
                    .init(color: .white.opacity(lift ? 0.42 : 0.10),   location: 0.32),
                    .init(color: .white.opacity(lift ? 0.20 : 0.05),   location: 0.52),
                    .init(color: .white.opacity(lift ? 0.06 : 0.01),   location: 0.72),
                    .init(color: .clear,                                location: 1.00),
                ]),
                startPoint: specX1,
                endPoint:   specX2
            ))

            // ── 6. Top edge highlight — primary glass read ────────────
            // Horizontal gradient fades in/out at corners to follow bar radius.
            // Drawn on top of all fill passes — must be last before border.
            let topHighlight = Path(CGRect(x: 1, y: 0, width: bW - 2, height: 2))
            context.fill(
                topHighlight,
                with: .linearGradient(
                    Gradient(stops: [
                        .init(color: .white.opacity(0.0),                location: 0.00),
                        .init(color: .white.opacity(lift ? 1.0 : 0.70),  location: 0.15),
                        .init(color: .white.opacity(lift ? 1.0 : 0.70),  location: 0.85),
                        .init(color: .white.opacity(0.0),                location: 1.00),
                    ]),
                    startPoint: CGPoint(x: 0, y: 0),
                    endPoint:   CGPoint(x: bW, y: 0)
                )
            )

            // ── 7. Bottom boundary ────────────────────────────────────
            let bottomEdge = Path(CGRect(x: 0, y: bH - 0.5, width: bW, height: 0.5))
            context.fill(bottomEdge, with: .color(.black.opacity(0.40)))

            // ── 8. Hairline border stroke ─────────────────────────────
            context.stroke(
                barPath,
                with: .linearGradient(
                    Gradient(colors: colors),
                    startPoint: CGPoint(x: bW / 2, y: 0),
                    endPoint:   CGPoint(x: bW / 2, y: bH)
                ),
                style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round)
            )
            context.opacity = 1.0  // reset after layer ops
        }
        .frame(width: barW, height: barH + 24)
    }

    // MARK: — Floor line

    private var floorLine: some View {
        Rectangle()
            .frame(width: cardSize.width * 0.78, height: 1)
            .foregroundStyle(LinearGradient(
                colors: [
                    .clear,
                    AppColors.spectrumMagenta,
                    AppColors.spectrumPurple,
                    AppColors.spectrumCyan,
                    .clear
                ],
                startPoint: .leading,
                endPoint:   .trailing
            ))
            .opacity(lifted ? 0.70 : 0.22)
            .animation(AppAnimation.standard, value: lifted)
    }

    // MARK: — Title block

    private var titleBlock: some View {
        VStack(spacing: AppSpacing.sm) {
            // Spectrum hairline divider
            Rectangle()
                .frame(width: cardSize.width * 0.78, height: 0.6)
                .foregroundStyle(LinearGradient(
                    colors: [
                        .clear,
                        AppColors.spectrumMagenta,
                        AppColors.spectrumPurple,
                        AppColors.spectrumCyan,
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint:   .trailing
                ))
                .opacity(lifted ? 0.55 : 0.10)
                .animation(AppAnimation.standard, value: lifted)

            Text(title)
                .font(AppFonts.display(22, weight: .bold, relativeTo: .title))
                .foregroundStyle(AppColors.spectrumText)
                .kerning(-1.0)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, AppSpacing.lg)
    }

    // MARK: — Body

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: AppSpacing.sm) {
                HStack(spacing: motif == .dual ? barGap : 0) {
                    barCanvas(reversed: false)
                    if motif == .dual {
                        barCanvas(reversed: false)
                    }
                }
                floorLine
            }

            Spacer()

            titleBlock
                .padding(.bottom, AppSpacing.xl)
        }
        .frame(width: cardSize.width, height: cardSize.height)
        .allowsHitTesting(false)
        .onAppear { startHoloShift() }
    }
}

// MARK: - Preview

#Preview("Ornamental — no question") {
    ZStack {
        Color.black.ignoresSafeArea()
        VaylCardFace()
            .frame(width: 340, height: 480)
    }
    .preferredColorScheme(.dark)
}

#Preview("With question") {
    ZStack {
        Color.black.ignoresSafeArea()
        VaylCardFace(question: "What do I call you?")
            .frame(width: 340, height: 480)
    }
    .preferredColorScheme(.dark)
}

#Preview("Near full screen — LIFT end state") {
    ZStack {
        Color.black.ignoresSafeArea()
        VaylCardFace(question: "What do I call you?")
            .frame(width: 390, height: 780)
    }
    .preferredColorScheme(.dark)
}

#Preview("Mode — Solo Discovery") {
    ZStack {
        Color.black.ignoresSafeArea()
        VaylCardFace(content: .mode(title: "Solo Discovery", subtitle: "Just you", motif: .single))
            .frame(width: 220, height: 330)
    }
    .preferredColorScheme(.dark)
}

#Preview("Mode — Together") {
    ZStack {
        Color.black.ignoresSafeArea()
        VaylCardFace(content: .mode(title: "Together", subtitle: "You and a partner", motif: .dual))
            .frame(width: 220, height: 330)
    }
    .preferredColorScheme(.dark)
}
