//
//  InteractiveField.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//


import SwiftUI

struct InteractiveField: View {
    @Environment(\.theme) private var t // ARCHITECTURAL FLAG: legacy theme env — do not migrate to AppColors until theme system is unified
    let placeholder: String
    let icon: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Text(icon)
                .font(.system(size: 13)) // intentional exception: emoji/symbol icon passed as String param — size set for visual balance
            TextField(placeholder, text: $text)
                .font(AppFonts.caption)
                .foregroundStyle(t.text)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(
            t.isDark ? .white.opacity(0.03) : t.surface1
        )
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(t.cardBorder, lineWidth: 1.5)
        )
        .shadow(
            color: t.isDark ? t.glowCyan : .clear,
            radius: 6
        )
    }
}
