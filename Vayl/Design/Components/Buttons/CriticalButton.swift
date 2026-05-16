//
//  CriticalButton.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//


import SwiftUI

struct CriticalButton: View {
    @Environment(\.colorScheme) private var colorScheme
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
        case .neutral: return AppColors.textSecondary
        case .danger:  return AppColors.destructive
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
                    fillColor.opacity(colorScheme == .dark ? 0.18 : 0.08)
                )
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                .shadow(
                    color: colorScheme == .dark && style == .danger
                        ? AppColors.destructive.opacity(0.2)
                        : .clear,
                    radius: 8
                )
        }
        .buttonStyle(.plain)
    }
}
