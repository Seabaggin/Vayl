//
//  FounderLetterPhase.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/10/26.
//


//
//  FounderLetterPhase.swift
//  Vayl
//

import SwiftUI

/// OB Phase — Founder Letter
/// Stub for routing verification. Cosmetics in visual pass.
/// Terminal phase — commit fires in director.runFounderLetterEntry().
struct FounderLetterPhase: View {

    let director: VaylDirector

    var body: some View {
        ZStack {
            AppColors.void
                .ignoresSafeArea()

            VStack(spacing: AppSpacing.xl) {
                Spacer()

                Text("Founder Letter Phase")
                    .font(Font.custom("ClashDisplay-Medium", size: 24, relativeTo: .title))
                    .foregroundStyle(AppColors.textPrimary)

                Button("Continue") {
                    // Terminal phase — no further advance; commit already fired on entry.
                }
                .font(Font.custom("ClashDisplay-Medium", size: 17, relativeTo: .body))
                .foregroundStyle(AppColors.textPrimary)
                .frame(minWidth: 44, minHeight: 44)

                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityLabel("Founder letter phase")
    }
}