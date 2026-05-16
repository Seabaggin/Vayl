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
///
/// The caller owns:
///   · frame · scale · rotation · opacity · offset · shadow
///   · All interactive overlays (write line, greeting, pills)
///
/// NamePhase positions WriteLineView and greeting overlay
/// over this card's frame. This component never knows about
/// typed names, selections, or interaction state.

struct VaylCardFace: View {

    var question:   String?       = nil
    var credential: OBCredential? = nil

    var body: some View {
        GeometryReader { geo in
            let size      = geo.size
            let shortSide = min(size.width, size.height)
            let radius    = AppRadius.obCard

            ZStack {

                // ── 1 · Void base ──────────────────────────────────
                AppColors.cardBg

                // ── 2 · Atmosphere ─────────────────────────────────
                FaceAtmosphere(size: size, shortSide: shortSide)

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

                // ── 4 · Spectrum diamond — center motif ───────────
                // Ornamental. Dims when the card carries a question.
                SpectrumDiamond(size: size)
                    .opacity(question == nil ? 1.0 : 0.18)
                    .animation(
                        AppAnimation.standard.reduceMotionSafe,
                        value: question == nil
                    )

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

                // ── 10 · ✦ Corner marks ────────────────────────────
                CornerMarks(size: size)
            }
            .clipShape(RoundedRectangle(cornerRadius: radius))
        }
    }
}

// MARK: - FaceAtmosphere

/// Front atmosphere is quieter than the back.
/// Opacity values ~20% lower — front is the still side.

private struct FaceAtmosphere: View {
    let size:      CGSize
    let shortSide: CGFloat

    var body: some View {
        ZStack {
            // Blob A — cyan, upper-left
            RadialGradient(
                colors: [AppColors.spectrumCyan.opacity(0.07), .clear],
                center: UnitPoint(x: 0.30, y: 0.32),
                startRadius: 0,
                endRadius: shortSide * 0.48
            )

            // Blob B — magenta, lower-right
            RadialGradient(
                colors: [AppColors.spectrumMagenta.opacity(0.07), .clear],
                center: UnitPoint(x: 0.72, y: 0.70),
                startRadius: 0,
                endRadius: shortSide * 0.48
            )

            // Blob C — purple, center
            RadialGradient(
                colors: [AppColors.spectrumPurple.opacity(0.11), .clear],
                center: .center,
                startRadius: 0,
                endRadius: shortSide * 0.44
            )
        }
    }
}

// MARK: - SpectrumDiamond

/// Rotated 45° square — spectrum gradient stroke.
/// Sits at vertical center of card.
/// Ornamental. Dims when the card carries a question.
///
/// Stroke weights are decorative motif geometry — no AppGlows token
/// covers interior card motifs. Values documented here as the
/// single source of truth for this element.
///   Glow pass:  6pt stroke, blur 6 — atmospheric bloom
///   Core pass:  0.6pt stroke — lighter than hairline (1.2pt) because
///               the diamond is interior decoration, not a border element

private struct SpectrumDiamond: View {
    let size: CGSize

    private var side: CGFloat { min(size.width, size.height) * 0.22 }

    var body: some View {
        ZStack {
            // Glow pass
            Rectangle()
                .rotation(.degrees(45))
                .stroke(AppColors.spectrumBorder, lineWidth: 6)
                .blur(radius: 6)
                .opacity(0.20)
                .frame(width: side, height: side)

            // Core pass
            Rectangle()
                .rotation(.degrees(45))
                .stroke(AppColors.spectrumBorder, lineWidth: 0.6)
                .opacity(0.72)
                .frame(width: side, height: side)
        }
        .frame(width: size.width, height: size.height)
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

// MARK: - CornerMarks

/// ✦ spark mark at each corner — 12% white opacity.
/// Inset: AppLayout.cardHPad (16pt) from each edge.

private struct CornerMarks: View {
    let size: CGSize

    private let inset: CGFloat = AppLayout.cardHPad  // 16pt

    private var positions: [CGPoint] {[
        CGPoint(x: inset,              y: inset),
        CGPoint(x: size.width - inset, y: inset),
        CGPoint(x: inset,              y: size.height - inset),
        CGPoint(x: size.width - inset, y: size.height - inset),
    ]}

    var body: some View {
        ZStack {
            ForEach(positions.indices, id: \.self) { i in
                Text("✦")
                    .font(AppFonts.label)
                    .foregroundStyle(Color.white.opacity(0.12))
                    .position(positions[i])
            }
        }
        .frame(width: size.width, height: size.height)
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
