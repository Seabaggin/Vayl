// Vayl/Design/Components/Cards/CardFaces/CompassSliderCardFace.swift

import SwiftUI

/// CompassPhase Q3 register card face — a felt-state slider.
///
/// Two aspirational endpoints, no numeric value shown. The user drags the thumb to
/// point at where they want this to take them; position maps to `EmotionalRegister`
/// (handled by the phase, not here). This view only DRAWS — the drag gesture is an
/// overlay owned by the phase, mirroring how NamePhase overlays its write line.
///
/// `value`   0.0 ("I want to feel safer") → 1.0 ("I want to feel more alive")
/// `dragging` scales the thumb (1.12) and brightens its glow while active.
///
/// Geometry proportional to the card size — no fixed pixels. The slider is drawn
/// along the card's width, so the card is given a landscape frame in Q3.
struct CompassSliderCardFace: View {

    let cardWidth:  CGFloat
    let cardHeight: CGFloat
    let value:      Double   // 0...1
    let dragging:   Bool

    private var trackWidth: CGFloat { cardWidth * 0.74 }
    private var thumbSize:  CGFloat { min(cardWidth, cardHeight) * 0.11 }
    private var clamped:    CGFloat { CGFloat(min(max(value, 0), 1)) }

    var body: some View {
        VStack(spacing: cardHeight * 0.07) {
            Spacer()

            // ── Track + thumb ──────────────────────────────────────
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppColors.spectrumText)
                    .frame(width: trackWidth, height: 3)
                    .opacity(0.16)

                Capsule()
                    .fill(AppColors.spectrumText)
                    .frame(width: max(thumbSize / 2, trackWidth * clamped), height: 3)
                    .opacity(0.90)

                thumb
                    .offset(x: trackWidth * clamped - thumbSize / 2)
            }
            .frame(width: trackWidth, height: thumbSize * 1.6)

            // ── Felt-state endpoints ───────────────────────────────
            HStack(alignment: .top, spacing: AppSpacing.md) {
                Text("I want to feel safer")
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: trackWidth * 0.42, alignment: .leading)
                Spacer(minLength: 0)
                Text("I want to feel more alive")
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: trackWidth * 0.42, alignment: .trailing)
            }
            .font(AppFonts.caption)
            .foregroundStyle(AppColors.textSecondary)
            .frame(width: trackWidth)

            Spacer()
        }
        .frame(width: cardWidth, height: cardHeight)
        .allowsHitTesting(false)
    }

    // Glow + crisp passes, per OB card-face rule.
    private var thumb: some View {
        ZStack {
            Circle()
                .fill(AppColors.spectrumText)
                .frame(width: thumbSize * 1.5, height: thumbSize * 1.5)
                .blur(radius: 8)
                .opacity(dragging ? 0.80 : 0.45)

            Circle()
                .fill(AppColors.spectrumText)
                .frame(width: thumbSize, height: thumbSize)

            Circle()
                .fill(Color.white)
                .frame(width: thumbSize * 0.34, height: thumbSize * 0.34)
                .opacity(0.92)
        }
        .scaleEffect(dragging ? 1.12 : 1.0)
        .animation(AppAnimation.fast, value: dragging)
    }
}

// Previewed inside VaylCardFace, landscape — the card shell is owned by VaylCardFace.
#Preview("Compass slider — in card (mid)") {
    ZStack {
        Color.black.ignoresSafeArea()
        VaylCardFace(content: .compassSlider(value: 0.5, dragging: false))
            .frame(width: 330, height: 220)
    }
    .preferredColorScheme(.dark)
}

#Preview("Compass slider — in card (dragging right)") {
    ZStack {
        Color.black.ignoresSafeArea()
        VaylCardFace(content: .compassSlider(value: 0.82, dragging: true))
            .frame(width: 330, height: 220)
    }
    .preferredColorScheme(.dark)
}
