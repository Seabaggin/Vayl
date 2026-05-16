//
//  CuriosityPreviewLine.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/30/26.
//


//
//  CuriosityPreviewLine.swift
//  Open Lightly
//
//  Italic preview text shown beneath a selected pill.
//  Tells the user how their selection shapes their path.
//

import SwiftUI

struct CuriosityPreviewLine: View {
    let text:    String
    let isLight: Bool

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Text(text)
                .font(AppFonts.caption)
                .italic()
                .foregroundStyle(
                    isLight
                        ? AppColors.textBody.opacity(0.70)
                        : AppColors.textSecondary
                )
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .fill(
                    isLight
                        ? AppColors.accentTertiary.opacity(0.05)
                        : AppColors.accentPrimary.opacity(0.05)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .strokeBorder(
                            isLight
                                ? AppColors.accentTertiary.opacity(0.12)
                                : AppColors.accentPrimary.opacity(0.12),
                            lineWidth: 1
                        )
                )
        )
        .padding(.top, AppSpacing.sm)
        .transition(.opacity.combined(with: .offset(y: 6)))
    }
}

#Preview("Dark") {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        CuriosityPreviewLine(
            text: "We'll center your path on desire clarity — the cards most people circle for years.",
            isLight: false
        )
        .padding(AppSpacing.lg)
    }
    .preferredColorScheme(.dark)
}

#Preview("Light") {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        CuriosityPreviewLine(
            text: "We'll center your path on desire clarity — the cards most people circle for years.",
            isLight: true
        )
        .padding(AppSpacing.lg)
    }
    .preferredColorScheme(.light)
}
