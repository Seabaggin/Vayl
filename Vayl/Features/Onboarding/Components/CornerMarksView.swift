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

    // Visual constants — not on the 4/8pt grid; specific to corner mark geometry
    private let topOffset:    CGFloat = 17  // token pending AppLayout.cornerMarkTopOffset
    private let bottomOffset: CGFloat = 17  // token pending AppLayout.cornerMarkBottomOffset
    private let sideOffset:   CGFloat = 21  // token pending AppLayout.cornerMarkSideOffset
    private let fontSize:     CGFloat = 9   // sub-grid glyph size — token pending AppFonts
    private let opacity:      Double  = 0.09 // structural mark opacity — token pending AppColors

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
            .font(AppFonts.meta) // 9pt not in type scale — using meta(10pt) as closest token, pending AppFonts.cornerDeckCount
            // 0.09 intentional — marks are structural not readable
            .foregroundStyle(AppColors.textMuted)
    }
}