//
//  BuildingPathPhase.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/10/26.
//


//
//  BuildingPathPhase.swift
//  Vayl
//

import SwiftUI

/// OB Phase — Building Path
/// Stub for routing verification. Cosmetics in visual pass.
/// Advances to .foil via director.
struct BuildingPathPhase: View {

    let director: VaylDirector

    var body: some View {
        ZStack {
            AppColors.void
                .ignoresSafeArea()

            VStack(spacing: AppSpacing.xl) {
                Spacer()

                Text("Building Path Phase")
                    .font(Font.custom("ClashDisplay-Medium", size: 24, relativeTo: .title))
                    .foregroundStyle(AppColors.textPrimary)

                Button("Continue") {
                    director.advance(to: .foil)
                }
                .font(Font.custom("ClashDisplay-Medium", size: 17, relativeTo: .body))
                .foregroundStyle(AppColors.textPrimary)
                .frame(minWidth: 44, minHeight: 44)

                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityLabel("Building path phase")
    }
}