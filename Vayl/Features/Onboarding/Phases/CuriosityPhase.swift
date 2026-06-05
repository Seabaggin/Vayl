//
//  CuriosityPhase.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/10/26.
//


//
//  CuriosityPhase.swift
//  Vayl
//

import SwiftUI

/// OB Phase — Curiosity (two rounds handled internally)
/// Stub for routing verification. Cosmetics in visual pass.
/// Advances to .confirmation via director.
struct CuriosityPhase: View {

    let director:   VaylDirector
    let screenSize: CGSize

    var body: some View {
        ZStack {
            AppColors.void
                .ignoresSafeArea()

            VStack(spacing: AppSpacing.xl) {
                Spacer()

                Text("Curiosity Phase")
                    .font(Font.custom("ClashDisplay-Medium", size: 24, relativeTo: .title))
                    .foregroundStyle(AppColors.textPrimary)

                Button("Continue") {
                    director.advance(to: .confirmation)
                }
                .font(Font.custom("ClashDisplay-Medium", size: 17, relativeTo: .body))
                .foregroundStyle(AppColors.textPrimary)
                .frame(minWidth: 44, minHeight: 44)

                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityLabel("Curiosity phase")
    }
}