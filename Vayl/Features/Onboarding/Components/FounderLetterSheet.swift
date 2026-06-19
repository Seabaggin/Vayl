//
//  FounderLetterSheet.swift
//  Vayl
//
//  Shared sheet chrome for the founder letter — rendered by BuildDeckPhase at
//  the PEEK detent and by FounderLetterPhase fully expanded. One component on
//  both sides of the phase swap guarantees the covering frame is identical, so
//  `advance(to: .founderLetter)` happens invisibly behind it
//  (ceremony spec, Beats 7–8).
//

import SwiftUI

struct FounderLetterSheet<Content: View>: View {

    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            // Spectrum grab handle.
            // Native iOS dimensions: 36x5pt, 5pt from the top edge.
            Capsule()
                .fill(AppColors.spectrumBorder)
                .frame(width: 36, height: 5)
                .opacity(0.6)
                .padding(.top, 8)

            content()

            Spacer(minLength: 0)
        }
        // Native-style chrome — identical to the edit sheet.
        .obSheetChrome()
    }
}

#Preview("Peek + full") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        VStack(spacing: AppSpacing.xl) {
            FounderLetterSheet { EmptyView() }
                .frame(height: 90)
            FounderLetterSheet {
                Text("Letter body…")
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textBody)
                    .padding(AppSpacing.xl)
            }
            .frame(height: 420)
        }
        .padding(AppSpacing.lg)
    }
    .preferredColorScheme(.dark)
}
