//
//  VaylCardRenderer.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/9/26.
//


//
//  VaylCardRenderer.swift
//  Vayl
//

// Design/Components/Cards/VaylCardRenderer.swift

import SwiftUI

/// Reads VaylCardModel physics state and renders the correct card face.
/// This is the only file that translates VaylCardModel data into pixels.
/// All transforms are applied here — VaylCardBack and VaylCardFace
/// never apply their own shadow, scale, rotation, or opacity.
///
/// Flip logic:
///   flipProgress < 0.5  → show VaylCardBack,  scaleX positive
///   flipProgress >= 0.5 → show VaylCardFace,  scaleX mirrored (-1) to correct orientation
struct VaylCardRenderer: View {
    let card:       VaylCardModel
    let screenSize: CGSize
    var onAction:   ((VaylCardAction) -> Void)? = nil

    private var cardW: CGFloat { AppLayout.obCardWidth(in: screenSize.width) }
    private var cardH: CGFloat { AppLayout.obCardHeight(in: screenSize.width) }

    var body: some View {
        let shadow = AppElevation.cardShadow(elevation: card.elevation)

        ZStack {
            if card.flipProgress < 0.5 {
                VaylCardBack()
            } else {
                VaylCardFace(content: card.content, onAction: onAction)
                    .scaleEffect(x: -1) // mirror to correct face-up orientation
            }
        }
        .frame(width: cardW, height: cardH)
        .scaleEffect(x: card.scaleX, y: card.scale)
        .rotationEffect(.degrees(card.rotation))
        .shadow(
            color:  shadow.color,
            radius: shadow.radius,
            y:      shadow.y
        )
        .opacity(card.opacity)
        .position(card.position)
    }
}