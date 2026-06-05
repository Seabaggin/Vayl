// Vayl/Design/Components/Cards/CardFaces/CompassOptionCardFace.swift

import SwiftUI

/// CompassPhase Q1/Q2 answer card face — a single option label, centered.
///
/// One option per card. Four of these are dealt into a 2×2 grid and revealed by
/// the flip cascade. The label is the whole content — readable first, ornamental
/// second. State (which card is selected) lives on the model/elevation, never here.
///
/// Pure presentation — no @State, no gestures. The label passes in via
/// `VaylCardContent.compassOption(label:)` → `VaylCardFace`.
///
/// Geometry is proportional to the card size — no fixed pixels.
struct CompassOptionCardFace: View {

    let cardWidth:  CGFloat
    let cardHeight: CGFloat
    let label:      String

    var body: some View {
        VStack(spacing: cardHeight * 0.045) {

            // Small spectrum tick above the label — quiet motif, keeps the
            // answer card visually a member of the OB card family.
            Capsule()
                .fill(AppColors.spectrumText)
                .frame(width: cardWidth * 0.16, height: 2)
                .opacity(0.55)

            Text(label)
                .font(AppFonts.bodyText)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppColors.textPrimary)
                .lineSpacing(AppSpacing.xs)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, cardWidth * 0.12)
        }
        .frame(width: cardWidth, height: cardHeight)
        .allowsHitTesting(false)
    }
}

// Previewed inside VaylCardFace — the shell (border, atmosphere, hairlines) is
// owned by the card, not the content face. This is how it renders in the phase.
#Preview("Compass option — in card") {
    ZStack {
        Color.black.ignoresSafeArea()
        VaylCardFace(content: .compassOption(label: "I'm here, but I'm not totally sure yet"))
            .frame(width: 220, height: 330)
    }
    .preferredColorScheme(.dark)
}

#Preview("Compass option grid (2×2)") {
    ZStack {
        Color.black.ignoresSafeArea()
        LazyVGrid(
            columns: [GridItem(.fixed(150), spacing: 12), GridItem(.fixed(150), spacing: 12)],
            spacing: 12
        ) {
            ForEach(AgencySignal.ordered, id: \.self) { signal in
                VaylCardFace(content: .compassOption(label: signal.label))
                    .frame(width: 150, height: 210)
            }
        }
    }
    .preferredColorScheme(.dark)
}
