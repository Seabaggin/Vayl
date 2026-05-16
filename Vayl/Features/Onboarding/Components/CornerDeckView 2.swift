//
//  CornerDeckView.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/9/26.
//


//
//  CornerDeckView.swift
//  Vayl
//

// Features/Onboarding/Components/CornerDeckView.swift

import SwiftUI

/// The corner deck — top right of the OB canvas.
/// Visible from NamePhase onward. Shows collected credential cards.
/// Maximum 6 cards — one per OBCredential case.
///
/// Full visual implementation — TODO:
///   - Spectrum hairline on each mini-card top edge
///   - Glow pulse on card landing via AppAnimation.deckReceive
///   - Full stack offset and rotation per card position
///
/// This view never responds to gestures and never holds state.
struct CornerDeckView: View {
    let cards:      [VaylCardModel]
    let screenSize: CGSize

    // Stack offsets for up to 6 cards — index 0 is front card
    // Physics constants — not tokens. These are specific to the
    // corner deck stacking geometry.
    private let stackOffsets: [(x: CGFloat, y: CGFloat, rot: Double)] = [
        ( 0, 0,   0.0),   // card 1 — front
        (-1, -2, -1.5),   // card 2
        ( 1, -4,  1.2),   // card 3
        (-1, -6, -0.8),   // card 4
        ( 0, -8,  0.5),   // card 5
        (-1, -10, -0.3),  // card 6
    ]

    var body: some View {
        ZStack {
            // Stack — render back to front
            ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                let offsetIndex = min(index, stackOffsets.count - 1)
                let offset      = stackOffsets[offsetIndex]

                RoundedRectangle(cornerRadius: AppRadius.cornerCard)
                    .fill(AppColors.cardBg)
                    .overlay {
                        RoundedRectangle(cornerRadius: AppRadius.cornerCard)
                            .strokeBorder(
                                AppColors.spectrumPurple.opacity(0.27),
                                lineWidth: 0.5
                            )
                    }
                    .frame(
                        width:  AppLayout.cornerDeckWidth,
                        height: AppLayout.cornerDeckHeight
                    )
                    .rotationEffect(.degrees(offset.rot))
                    .offset(x: offset.x, y: offset.y)
                    // TODO: spectrum hairline top edge
                    // TODO: glow pulse on landing
            }

            // Count label — only visible when cards present
            if !cards.isEmpty {
                Text("\(cards.count) / 6")
                    .font(.system(size: 9, weight: .medium))
                    // TODO: replace with AppFonts.tertiaryText()
                    .foregroundStyle(Color.white.opacity(0.38))
                    .offset(y: AppLayout.cornerDeckHeight / 2 + 6)
            }
        }
        .position(
            x: screenSize.width  - AppLayout.cornerDeckRight - AppLayout.cornerDeckWidth  / 2,
            y: AppLayout.cornerDeckTop                       + AppLayout.cornerDeckHeight / 2
        )
        .animation(AppAnimation.deckReceive, value: cards.count)
    }
}