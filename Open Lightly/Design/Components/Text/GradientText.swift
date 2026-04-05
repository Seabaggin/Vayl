// GradientText.swift
// Open Lightly
// Static gradient text — no animation, no shimmer

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
                        ? [
                            AppColors.magentaDark,
                            AppColors.magenta,
                            AppColors.orangeHot
                          ]
                        : [
                            AppColors.pink,
                            AppColors.purple,
                            AppColors.magenta
                          ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
    }
}
