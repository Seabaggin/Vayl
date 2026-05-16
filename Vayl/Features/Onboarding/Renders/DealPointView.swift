//
//  DealPointView.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/9/26.
//


//
//  DealPointView.swift
//  Vayl
//

// Features/Onboarding/Renderers/DealPointView.swift

import SwiftUI

/// The deal point — the origin from which all OB cards are launched.
/// Positioned at tableHorizonYFrac. Intensity driven by VaylDirector.
/// This view never responds to gestures and never holds state.
struct DealPointView: View {
    let intensity:  Double
    let screenSize: CGSize

    var body: some View {
        // TODO: outer warm amber haze radial gradient
        // TODO: spectrum micro-ring radial gradient
        // TODO: center amber dot

        // Barebones: simple glow circle until full implementation
        Circle()
            .fill(AppColors.spectrumPurple.opacity(0.40 * intensity))
            .frame(
                width:  AppLayout.dealPointRadius * 2,
                height: AppLayout.dealPointRadius * 2
            )
            .position(
                x: screenSize.width  * 0.50,
                y: screenSize.height * AppLayout.dealPointYFrac
            )
            .animation(AppAnimation.standard, value: intensity)
            .allowsHitTesting(false)
    }
}