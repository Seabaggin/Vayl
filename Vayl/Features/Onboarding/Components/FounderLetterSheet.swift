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
            Capsule()
                .fill(AppColors.textTertiary)
                .frame(width: 36, height: 5)
                .padding(.top, AppSpacing.sm)

            Text("A note from the founder")
                .font(AppFonts.overline)
                .foregroundStyle(AppColors.textSecondary)
                .padding(.top, AppSpacing.sm)

            content()

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius:  AppRadius.container,
                topTrailingRadius: AppRadius.container
            )
            .fill(AppColors.modalBackground)
            .ignoresSafeArea(edges: .bottom)
        )
        .overlay(
            UnevenRoundedRectangle(
                topLeadingRadius:  AppRadius.container,
                topTrailingRadius: AppRadius.container
            )
            .strokeBorder(AppColors.spectrumBorder, lineWidth: 1)
            .opacity(0.4)
        )
        .modalElevation()
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
