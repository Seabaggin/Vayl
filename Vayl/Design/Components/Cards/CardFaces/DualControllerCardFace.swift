//
//  DualControllerCardFace.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/23/26.
//
//  Two controllers, same scale as the solo face, stacked vertically and centred.
//  No rotation — both upright, same orientation as ControllerCardFace.
//  The size parity with the solo card makes the co-op pairing legible.
//
//  Layout (painter space: y = 160 → 540 is the controller visual span):
//    s       = (cardWidth × 0.82) / 800   (matches ControllerCardFace exactly)
//    xOff    = (cardWidth  − 800·s) / 2
//    gap     = 8pt
//    topYOff = cardHeight/2 − 540·s − gap/2   (painter origin for upper controller)
//    botYOff = cardHeight/2 − 160·s + gap/2   (painter origin for lower controller)

import SwiftUI

struct DualControllerCardFace: View {

    let cardWidth: CGFloat
    let cardHeight: CGFloat
    var activeButtonsFront: Set<Int> = []
    var activeButtonsBack: Set<Int> = []

    // Identical scale to ControllerCardFace — full-size controllers.
    private var s: CGFloat { (cardWidth * 0.82) / 800 }

    var body: some View {
        Canvas { context, _ in
            let gap: CGFloat = 8
            let xOff = (cardWidth - 800 * s) / 2

            // Controller visual bounds in painter space: y = 160s (top shoulder)
            // to y = 540s (grip bottoms). Centre the two-controller pair on the card.
            let topYOff = cardHeight / 2 - 540 * s - gap / 2
            let botYOff = cardHeight / 2 - 160 * s + gap / 2

            // ── Upper controller — rotated 180° to face the lower one ────────────
            context.drawLayer { ctx in
                ctx.translateBy(x: xOff, y: topYOff)
                ctx.translateBy(x: 400 * s, y: 350 * s)
                ctx.concatenate(CGAffineTransform(rotationAngle: .pi))
                ctx.translateBy(x: -400 * s, y: -350 * s)
                ControllerPainter.draw(ctx, s: s, glowBlur: 5 * s,
                                       activeButtons: activeButtonsBack)
            }

            // ── Lower controller ──────────────────────────────────────────────
            context.drawLayer { ctx in
                ctx.translateBy(x: xOff, y: botYOff)
                ControllerPainter.draw(ctx, s: s, glowBlur: 5 * s,
                                       activeButtons: activeButtonsFront)
            }
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
            DualControllerCardFace(cardWidth: cw, cardHeight: ch)
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
