//
//  InteractiveField.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//


import SwiftUI

struct InteractiveField: View {
    @Environment(\.colorScheme) private var colorScheme
    let placeholder: String
    let icon: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Text(icon)
                .font(.system(size: 13)) // intentional exception: emoji/symbol icon passed as String param — size set for visual balance
            TextField(placeholder, text: $text)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textPrimary)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(
            colorScheme == .dark ? .white.opacity(0.03) : AppColors.cardBackground
        )
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(AppColors.borderSubtle, lineWidth: 1.5)
        )
        .shadow(
            color: colorScheme == .dark ? AppColors.accentPrimary.opacity(0.20) : .clear,
            radius: 6
        )
    }
}
