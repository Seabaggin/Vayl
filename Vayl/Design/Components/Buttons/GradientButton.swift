//
//  GradientButton.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//
//  ✅ Design system audit — verified March 9, 2026
//

import SwiftUI

struct GradientButton: View {
    @Environment(\.theme) private var t // ARCHITECTURAL FLAG: legacy theme env — do not migrate to AppColors until theme system is unified
    let title: String
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppFonts.bodyMedium)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.md)
                .background(t.buttonGradient)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                .shadow(
                    color: t.isDark
                        ? t.glowCyan.opacity(0.5)
                        : t.magenta.opacity(0.2),
                    radius: t.isDark ? 16 : 12,
                    y: t.isDark ? 0 : 4
                )
                .shadow(
                    color: t.isDark
                        ? t.glowMagenta.opacity(0.3)
                        : .clear,
                    radius: 24,
                    y: 0
                )
        }
        .buttonStyle(.plain)
    }
}

struct GradBadge: View {
    @Environment(\.theme) private var t // ARCHITECTURAL FLAG: legacy theme env — do not migrate to AppColors until theme system is unified
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 9, weight: .bold)) // intentional exception: micro badge label — below AppFonts minimum (overline=11pt)
            .tracking(0.8)
            .foregroundStyle(.white)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, 3) // intentional exception: micro badge vertical padding — no token between xxs(2) and xs(4)
            .background(t.buttonGradient)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm)) // intentional exception: badge-specific corner — no token between micro(2) and sm(8)
    }
}
