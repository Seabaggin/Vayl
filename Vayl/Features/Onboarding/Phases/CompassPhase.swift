//
//  CompassPhase.swift
//  Vayl
//

import SwiftUI

/// OB Phase — Compass (replaces the former Quiz phase).
/// Three-question calibration (agency / motivation / emotional register) dealt at
/// the table. Ephemeral — no corner-deck card.
///
/// STUB: routing target for the ContextPhase handoff. The full three-question
/// sequence (MC cards + slider, CompassStore, couple derivation) is a dedicated
/// follow-up build. Advances to .curiosity via the director.
struct CompassPhase: View {

    let director:   VaylDirector
    let screenSize: CGSize

    var body: some View {
        ZStack {
            AppColors.void
                .ignoresSafeArea()

            VStack(spacing: AppSpacing.xl) {
                Spacer()

                Text("Compass Phase")
                    .font(Font.custom("ClashDisplay-Medium", size: 24, relativeTo: .title))
                    .foregroundStyle(AppColors.textPrimary)

                Button("Continue") {
                    director.advance(to: .curiosity)
                }
                .font(Font.custom("ClashDisplay-Medium", size: 17, relativeTo: .body))
                .foregroundStyle(AppColors.textPrimary)
                .frame(minWidth: 44, minHeight: 44)

                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityLabel("Compass phase")
    }
}
