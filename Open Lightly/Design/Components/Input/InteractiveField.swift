//
//  InteractiveField.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//


import SwiftUI

struct InteractiveField: View {
    @Environment(\.theme) private var t
    let placeholder: String
    let icon: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 8) {
            Text(icon)
                .font(.system(size: 13))
            TextField(placeholder, text: $text)
                .font(.system(size: 12))
                .foregroundStyle(t.text)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            t.isAmoled ? .white.opacity(0.03) : t.surface1
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(t.cardBorder, lineWidth: 1.5)
        )
        .shadow(
            color: t.isAmoled ? t.glowCyan : .clear,
            radius: 6
        )
    }
}