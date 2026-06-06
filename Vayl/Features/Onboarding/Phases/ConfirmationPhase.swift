//
//  ConfirmationPhase.swift
//  Vayl
//

import SwiftUI

/// OB Phase — Confirmation (renders OBPhase.confirmation)
/// Stub for routing verification. Cosmetics in visual pass.
/// Advances to .buildDeck via director.
struct ConfirmationPhase: View {

    let director: VaylDirector

    var body: some View {
        ZStack {
            AppColors.void
                .ignoresSafeArea()

            VStack(spacing: AppSpacing.xl) {
                Spacer()

                Text("Confirmation Phase")
                    .font(Font.custom("ClashDisplay-Medium", size: 24, relativeTo: .title))
                    .foregroundStyle(AppColors.textPrimary)

                Button("Continue") {
                    director.advance(to: .buildDeck)
                }
                .font(Font.custom("ClashDisplay-Medium", size: 17, relativeTo: .body))
                .foregroundStyle(AppColors.textPrimary)
                .frame(minWidth: 44, minHeight: 44)

                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityLabel("Confirmation phase")
    }
}
