//
//  CornerMarksView.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/9/26.
//


//
//  CornerMarksView.swift
//  Vayl
//

// Features/Onboarding/Components/CornerMarksView.swift

import SwiftUI

/// ✦ marks at tl / bl / br corners only.
/// tr is always the corner deck — never place a mark there.
/// Fixed position. No animation. No interaction.
struct CornerMarksView: View {

    // Physics constants — position from screen edges
    // Not tokens — these are specific to the corner mark geometry
    private let topOffset:    CGFloat = 17
    private let bottomOffset: CGFloat = 17
    private let sideOffset:   CGFloat = 21
    private let fontSize:     CGFloat = 9
    private let opacity:      Double  = 0.09

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // Top left
                mark
                    .position(x: sideOffset, y: topOffset)

                // Bottom left
                mark
                    .position(x: sideOffset, y: h - bottomOffset)

                // Bottom right
                mark
                    .position(x: w - sideOffset, y: h - bottomOffset)

                // Top right — intentionally omitted. Corner deck lives here.
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }

    private var mark: some View {
        Text("✦")
            .font(.system(size: fontSize, weight: .regular))
            .foregroundStyle(Color.white.opacity(opacity))
    }
}