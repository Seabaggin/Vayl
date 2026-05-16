//
//  ModeSelectPhase.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/10/26.
//


//
//  ModeSelectPhase.swift
//  Vayl
//

import SwiftUI

/// OB Phase — Mode Select
/// Stub for routing verification. Cosmetics in visual pass.
/// Advances to .experienceLevel via director.
struct ModeSelectPhase: View {

    let director:   VaylDirector
    let screenSize: CGSize

    var body: some View {
        ZStack {
            AppColors.void
                .ignoresSafeArea()

            VStack(spacing: AppSpacing.xl) {
                Spacer()

                Text("Mode Select Phase")
                    .font(Font.custom("ClashDisplay-Medium", size: 24, relativeTo: .title))
                    .foregroundStyle(AppColors.textPrimary)

                Button("Continue") {
                    director.advance(to: .experienceLevel)
                }
                .font(Font.custom("ClashDisplay-Medium", size: 17, relativeTo: .body))
                .foregroundStyle(AppColors.textPrimary)
                .frame(minWidth: 44, minHeight: 44)

                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityLabel("Mode select phase")
    }
}