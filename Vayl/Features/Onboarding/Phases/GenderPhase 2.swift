//
//  GenderPhase.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/10/26.
//


//
//  GenderPhase.swift
//  Vayl
//

import SwiftUI

/// OB Phase — Gender
/// Stub for routing verification. Cosmetics in visual pass.
/// Selection advances to .modeSelect via director.
struct GenderPhase: View {

    let director:   VaylDirector
    let screenSize: CGSize

    var body: some View {
        ZStack {
            AppColors.void
                .ignoresSafeArea()

            VStack(spacing: AppSpacing.xl) {
                Spacer()

                Text("Gender Phase")
                    .font(Font.custom("ClashDisplay-Medium", size: 24, relativeTo: .title))
                    .foregroundStyle(AppColors.textPrimary)

                Button("Continue") {
                    director.advance(to: .modeSelect)
                }
                .font(Font.custom("ClashDisplay-Medium", size: 17, relativeTo: .body))
                .foregroundStyle(AppColors.textPrimary)
                .frame(minWidth: 44, minHeight: 44)

                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityLabel("Gender phase")
    }
}