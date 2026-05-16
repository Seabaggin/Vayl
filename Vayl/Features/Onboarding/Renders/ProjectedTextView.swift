//
//  ProjectedTextView.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/9/26.
//


//
//  ProjectedTextView.swift
//  Vayl
//

// Features/Onboarding/Renderers/ProjectedTextView.swift

import SwiftUI

/// Dealer text projected onto the felt surface.
/// Positioned above the table horizon. Never floating UI.
/// Driven by VaylDirector.projectedText and projectedTextVisible.
///
/// Full visual implementation — TODO:
///   - Warm amber tint: rgba(245,235,215,0.90)
///   - Shadow beneath: rgba(0,0,0,0.55) blur 10 offsetY 3
///   - Entrance: scaleY 0.94→1.0 + opacity 0→1 over textProject
///   - Italic serif font — not the app display font
///   - Spectrum line beneath (2pt, 9% opacity) — projection glow on felt
///
/// This view never responds to gestures and never holds state.
struct ProjectedTextView: View {
    let text:       String
    let screenSize: CGSize

    var body: some View {
        Text(text)
            .font(.system(size: 15, weight: .regular, design: .serif))
            // TODO: replace with full felt projection styling
            .italic()
            .foregroundStyle(Color.white.opacity(0.90))
            .multilineTextAlignment(.center)
            .padding(.horizontal, AppLayout.screenHPad)
            .position(
                x: screenSize.width  * 0.50,
                y: screenSize.height * AppLayout.tableHorizonYFrac - 28
            )
            .allowsHitTesting(false)
    }
}