//
//  ThemeModifiers.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import SwiftUI

// MARK: - Root Modifier

struct ThemedRootModifier: ViewModifier {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.colorScheme) private var systemScheme

    func body(content: Content) -> some View {
        let palette = themeManager.palette(for: systemScheme)
        content
            .environment(\.theme, palette)
            .preferredColorScheme(themeManager.preferredColorScheme)
    }
}

extension View {
    func themedRoot() -> some View {
        modifier(ThemedRootModifier())
    }
}

// MARK: - Card Modifier

struct ThemedCardModifier: ViewModifier {
    @Environment(\.theme) private var t
    var selected: Bool = false

    func body(content: Content) -> some View {
        content
            .background(t.surface1)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        selected ? t.cyan : t.cardBorder,
                        lineWidth: selected ? 2 : 1.5
                    )
            )
            .shadow(
                color: selected && t.isDark
                    ? t.glowCyan
                    : .clear,
                radius: selected ? 8 : 0
            )
    }
}

extension View {
    func themedCard(selected: Bool = false) -> some View {
        modifier(ThemedCardModifier(selected: selected))
    }
}

// MARK: - Conditional Modifier Helper
// Applies a modifier only when `condition` is true.
// Usage: .if(someFlag) { $0.screenshotProtected() }

extension View {
    @ViewBuilder
    func `if`<T: View>(_ condition: Bool, transform: (Self) -> T) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
