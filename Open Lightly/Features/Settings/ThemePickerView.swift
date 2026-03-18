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

        VStack(spacing: 12) {
            Text("Appearance")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(t.text)

            HStack(spacing: 8) {
                ForEach(ThemeMode.allCases) { mode in
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            tm.mode = mode
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 16))
                            Text(mode.displayName)
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundStyle(
                            tm.mode == mode ? .white : t.textSecondary
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            tm.mode == mode
                                ? AnyShapeStyle(t.buttonGradient)
                                : AnyShapeStyle(t.surface1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(
                                    tm.mode == mode ? .clear : t.cardBorder,
                                    lineWidth: 1.5
                                )
                        )
                    }
                }
            }
        }
        .padding(16)
    }
}