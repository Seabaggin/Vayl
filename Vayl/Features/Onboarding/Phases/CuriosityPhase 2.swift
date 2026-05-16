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

/// OB Phase — Curiosity (Round 1 and Round 2)
/// Stub for routing verification. Cosmetics in visual pass.
/// Round 1 advances to .curiosityRound2.
/// Round 2 advances to .buildingPath.
struct CuriosityPhase: View {

    let director:   VaylDirector
    let round:      Int
    let screenSize: CGSize

    var body: some View {
        ZStack {
            AppColors.void
                .ignoresSafeArea()

            VStack(spacing: AppSpacing.xl) {
                Spacer()

                Text("Curiosity Phase — Round \(round)")
                    .font(Font.custom("ClashDisplay-Medium", size: 24, relativeTo: .title))
                    .foregroundStyle(AppColors.textPrimary)

                Button("Continue") {
                    if round == 1 {
                        director.advance(to: .curiosityRound2)
                    } else {
                        director.advance(to: .buildingPath)
                    }
                }
                .font(Font.custom("ClashDisplay-Medium", size: 17, relativeTo: .body))
                .foregroundStyle(AppColors.textPrimary)
                .frame(minWidth: 44, minHeight: 44)

                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityLabel("Curiosity phase round \(round)")
    }
}