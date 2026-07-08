//
//  ControllerCardFace.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/23/26.
//

import SwiftUI

// Procedural card-face art: fixed hairline/stroke insets are geometry, not
// layout spacing, so raw padding values are intentional here.
// swiftlint:disable no_hardcoded_padding

/// Solo controller card face — one upright controller centred on the card.
/// Drawing logic lives in ControllerPainter. DualControllerCardFace reuses the same painter.
struct ControllerCardFace: View {

    let cardWidth: CGFloat
    let cardHeight: CGFloat
    var activeButtons: Set<Int> = []

    // Scale factor — maps the 800-unit SVG coordinate space to card width.
    // Matches the HTML reference solo layout: scale = 0.295 on a 260px card → s ≈ 0.288 on 281pt.
    private var s: CGFloat { (cardWidth * 0.82) / 800 }

    // Centre the 800×600 coordinate space on the card.
    // ty subtracts 8pt matching the HTML reference (ty = CARD_H/2 − 600*0.295/2 − 8 = 85.5).
    private var xOffset: CGFloat { (cardWidth  - 800 * s) / 2 }
    private var yOffset: CGFloat { (cardHeight - 600 * s) / 2 - 8 }

    var body: some View {
        Canvas { context, _ in
            context.translateBy(x: xOffset, y: yOffset)
            ControllerPainter.draw(context, s: s, glowBlur: 5 * s,
                                   activeButtons: activeButtons)
        }
        .frame(width: cardWidth, height: cardHeight)
        .allowsHitTesting(false)
    }
}

#Preview {
    let cw = AppLayout.obCardWidth(in: 390)
    let ch = AppLayout.obCardHeight(in: 390)

    return ZStack {
        AppColors.void.ignoresSafeArea()

        ZStack {
            AppColors.cardBg
            ControllerCardFace(cardWidth: cw, cardHeight: ch)
            RoundedRectangle(cornerRadius: AppRadius.obCard)
                .strokeBorder(AppColors.spectrumBorder, lineWidth: 1.1)
                .opacity(0.52)
                .padding(0.75)
            RoundedRectangle(cornerRadius: AppRadius.obCard - 4)
                .strokeBorder(AppColors.spectrumBorder, lineWidth: 0.55)
                .opacity(0.27)
                .padding(9)
        }
        .frame(width: cw, height: ch)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.obCard))
    }
    .preferredColorScheme(.dark)
}
