//
//  CriticalButton.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//


import SwiftUI

struct CriticalButton: View {
    @Environment(\.theme) private var t
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
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(fillColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    fillColor.opacity(t.isDark ? 0.18 : 0.08)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
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
