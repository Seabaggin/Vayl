//
//  ThemePickerView.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//


import SwiftUI

struct ThemePickerView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.theme) private var t

    var body: some View {
        @Bindable var tm = themeManager

        VStack(spacing: AppSpacing.sm) {
            Text("Appearance")
                .font(Font.custom("Switzer-Bold", size: 13, relativeTo: .caption))
                .foregroundStyle(t.text)

            HStack(spacing: AppSpacing.sm) {
                ForEach(ThemeMode.allCases) { mode in
                    Button {
                        withAnimation(AppAnimation.standard) {
                            tm.mode = mode
                        }
                    } label: {
                        VStack(spacing: AppSpacing.sm) {
                            Image(systemName: mode.icon)
                                .font(Font.custom("Switzer-Regular", size: 16, relativeTo: .body))
                            Text(mode.displayName)
                                .font(Font.custom("Switzer-Medium", size: 10, relativeTo: .caption2))
                        }
                        .foregroundStyle(
                            tm.mode == mode ? .white : t.textSecondary
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.sm)
                        .background(
                            tm.mode == mode
                                ? AnyShapeStyle(t.buttonGradient)
                                : AnyShapeStyle(t.surface1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.md)
                                .stroke(
                                    tm.mode == mode ? .clear : t.cardBorder,
                                    lineWidth: 1.5
                                )
                        )
                    }
                }
            }
        }
        .padding(AppSpacing.md)
    }
}
