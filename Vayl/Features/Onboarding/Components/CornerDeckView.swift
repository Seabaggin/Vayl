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
/// Visible from DemoPhase onward. Shows collected credential cards.
/// Maximum 7 cards — one per OBCredential case.
///
/// Full visual implementation:
///   - Spectrum hairline (cyan → purple → magenta) on each mini-card top edge
///   - Glow pulse on card landing — `.cornerDeckGlow(visible:)` animated via
///     AppAnimation.deckReceive; `deckPulse` is raised by
///     `VaylDirector.receiveCardIntoCornerDeck` and dropped after the pulse
///   - Full stack offset and rotation per card position
///
/// This view never responds to gestures and never holds state.
struct CornerDeckView: View {
    let cards: [VaylCardModel]
    let screenSize: CGSize
    let deckPulse: Bool

    // Stack offsets for up to 7 cards — index 0 is front card
    // Physics constants — not tokens. These are specific to the
    // corner deck stacking geometry.
    private let stackOffsets: [(x: CGFloat, y: CGFloat, rot: Double)] = [
        ( 0, 0, 0.0),   // card 1 — front
        (-1, -3, -1.5),  // card 2
        ( 1, -5, 1.2),  // card 3
        (-1, -7, -0.8),  // card 4
        ( 0, -9, 0.5),  // card 5
        (-1, -11, -0.3),  // card 6
        ( 1, -13, 0.9)  // card 7
    ]

    var body: some View {
        ZStack {
            // Stack — render back to front
            ForEach(Array(cards.enumerated()), id: \.element.id) { index, _ in
                let offsetIndex = min(index, stackOffsets.count - 1)
                let offset      = stackOffsets[offsetIndex]

                // Render the real VaylCardBack at a reference frame sized so
                // its internal AppRadius.obCard (14pt) corner radius scales to
                // exactly AppRadius.cornerCard (4pt) at the mini-card display size.
                // ref = cornerDeckWidth / (cornerCard / obCard) = 38 / (4/14) = 133pt
                // scale = cornerDeckWidth / refW = 38 / 133 ≈ 0.286
                // 14pt × 0.286 ≈ 4pt — matches AppRadius.cornerCard exactly.
                let refW: CGFloat = 133
                let refH: CGFloat = 200
                VaylCardBack()
                    .frame(width: refW, height: refH)
                    .scaleEffect(AppLayout.cornerDeckWidth / refW)
                    .frame(
                        width: AppLayout.cornerDeckWidth,
                        height: AppLayout.cornerDeckHeight
                    )
                    // Spectrum hairline on the mini-card top edge — crisp single
                    // pass (the hairline does not glow; the landing pulse below is
                    // the deck's only emissive moment). Inset horizontally by the
                    // mini-card corner radius so the strip never overhangs the
                    // rounded corners; applied before rotation so it rides each
                    // card's stack tilt.
                    .overlay(alignment: .top) {
                        RoundedRectangle(cornerRadius: AppRadius.micro)
                            .fill(AppColors.spectrumBorder)
                            .frame(
                                width: AppLayout.cornerDeckWidth - AppRadius.cornerCard * 2,
                                height: AppGlows.spectrumBorder.hairlineHeight
                            )
                    }
                    .rotationEffect(.degrees(offset.rot))
                    .offset(x: offset.x, y: offset.y)
            }

            // Count label — only visible when cards present
            if !cards.isEmpty {
                Text("\(cards.count) / 7")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .offset(y: AppLayout.cornerDeckHeight / 2 + 6)
            }
        }
        .cornerDeckGlow(visible: deckPulse)
        .position(
            x: screenSize.width  - AppLayout.cornerDeckRight - AppLayout.cornerDeckWidth  / 2,
            y: AppLayout.cornerDeckTop                       + AppLayout.cornerDeckHeight / 2
        )
        .animation(AppAnimation.deckReceive, value: cards.count)
        .animation(AppAnimation.deckReceive, value: deckPulse)
    }
}
