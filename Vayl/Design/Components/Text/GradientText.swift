// GradientText.swift
// Open Lightly
// Static gradient text — no animation, no shimmer
// Two-tone secondary gradient only.
// Premium three-tone lives in LivingText exclusively.

import SwiftUI

struct GradientText: View {
    let text: String
    let font: Font
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(
                LinearGradient(
                    colors: colorScheme == .light
                        ? [AppColors.gold, AppColors.magenta]
                        : [AppColors.cyan, AppColors.purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
    }
}

// MARK: - Previews

#Preview("Dark Mode") {
    VStack(alignment: .leading, spacing: 20) {
        GradientText(
            text: "Jordan.",
            font: .system(size: 28, weight: .bold)
        )
        GradientText(
            text: "Good evening",
            font: .system(size: 15, weight: .medium)
        )
        GradientText(
            text: "Secondary label",
            font: .system(size: 13, weight: .regular)
        )
    }
    .padding(24)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(AppColors.pageBg)
    .preferredColorScheme(.dark)
}

#Preview("Light Mode") {
    VStack(alignment: .leading, spacing: 20) {
        GradientText(
            text: "Jordan.",
            font: .system(size: 28, weight: .bold)
        )
        GradientText(
            text: "Good evening",
            font: .system(size: 15, weight: .medium)
        )
        GradientText(
            text: "Secondary label",
            font: .system(size: 13, weight: .regular)
        )
    }
    .padding(24)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(AppColors.lightPageBg)
    .preferredColorScheme(.light)
}
