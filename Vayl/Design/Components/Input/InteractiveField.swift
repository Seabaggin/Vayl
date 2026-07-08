//
//  InteractiveField.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import SwiftUI

struct InteractiveField: View {
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
        .background(AppColors.whisperFill)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(AppColors.borderSubtle, lineWidth: 1.5)
        )
        .shadow(
            color: AppColors.accentPrimary.opacity(0.20),
            radius: 6
        )
    }
}
