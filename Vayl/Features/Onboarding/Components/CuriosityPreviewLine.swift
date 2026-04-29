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
        HStack(alignment: .top, spacing: 8) {
            Text(text)
                .font(AppFonts.caption)
                .italic()
                .foregroundStyle(
                    isLight
                        ? AppColors.lightCardTitle.opacity(0.70)
                        : AppColors.textSecondary
                )
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    isLight
                        ? AppColors.magenta.opacity(0.05)
                        : AppColors.cyan.opacity(0.05)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(
                            isLight
                                ? AppColors.magenta.opacity(0.12)
                                : AppColors.cyan.opacity(0.12),
                            lineWidth: 1
                        )
                )
        )
        .padding(.top, 8)
        .transition(.opacity.combined(with: .offset(y: 6)))
    }
}

#Preview("Dark") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        CuriosityPreviewLine(
            text: "We'll center your path on desire clarity — the cards most people circle for years.",
            isLight: false
        )
        .padding(24)
    }
    .preferredColorScheme(.dark)
}

#Preview("Light") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        CuriosityPreviewLine(
            text: "We'll center your path on desire clarity — the cards most people circle for years.",
            isLight: true
        )
        .padding(24)
    }
    .preferredColorScheme(.light)
}