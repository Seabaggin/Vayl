//
//  CriticalButton.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//


import SwiftUI

struct CriticalButton: View {
    @Environment(\.theme) private var t // ARCHITECTURAL FLAG: legacy theme env — do not migrate to AppColors until theme system is unified
    let title: String
    let icon: String
    var style: CriticalStyle = .neutral
    var action: () -> Void = {}

    enum CriticalStyle {
        case neutral
        case danger
    }

    private var fillColor: Color {
        switch style {
        case .neutral: return t.textSecondary
        case .danger:  return t.error
        }
    }

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(AppFonts.caption)
                .foregroundStyle(fillColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.sm)
                .background(
                    fillColor.opacity(t.isDark ? 0.18 : 0.08)
                )
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                .shadow(
                    color: t.isDark && style == .danger
                        ? t.error.opacity(0.2)
                        : .clear,
                    radius: 8
                )
        }
        .buttonStyle(.plain)
    }
}
