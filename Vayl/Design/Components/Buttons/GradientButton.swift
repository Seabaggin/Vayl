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
    @Environment(\.theme) private var t
    let title: String
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(t.buttonGradient)
                .clipShape(RoundedRectangle(cornerRadius: 14))
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
    @Environment(\.theme) private var t
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 9, weight: .bold))
            .tracking(0.8)
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .background(t.buttonGradient)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
