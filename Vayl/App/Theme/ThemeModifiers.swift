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

    func body(content: Content) -> some View {
        content
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
    @Environment(\.colorScheme) private var colorScheme
    var selected: Bool = false

    func body(content: Content) -> some View {
        content
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .stroke(
                        selected ? AppColors.accentPrimary : AppColors.borderSubtle,
                        lineWidth: selected ? 2 : 1.5
                    )
            )
            .shadow(
                color: selected && colorScheme == .dark
                    ? AppColors.accentPrimary.opacity(0.20)
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

// MARK: - Glass Card Modifier
//
// The canonical Map-tab surface: a translucent glass card that floats on the void
// + atmosphere (the aurora reads through it, unlike the opaque `.themedCard`), with
// one fill, one radius, one hairline, and one optional accent tint. Every Map
// surface uses this; the foil playing-card / Me-card look (Seg 3) is a variant
// layered on top, never a separate card system.

struct VaylGlassCardModifier: ViewModifier {
    /// When set, tints the hairline with the accent (the identity / "lit" variant,
    /// e.g. the Me card's Flavor colour); omit for a neutral surface.
    var accent: Color?
    var radius: CGFloat = AppRadius.lg

    func body(content: Content) -> some View {
        content
            .background(
                AppColors.glassSurface,
                in: RoundedRectangle(cornerRadius: radius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(
                        accent?.opacity(0.30) ?? AppColors.borderSubtle,
                        lineWidth: 1
                    )
            )
    }
}

extension View {
    /// Canonical Map glass surface. `accent` tints the hairline for identity / lit
    /// surfaces; omit for a neutral card.
    func vaylGlassCard(accent: Color? = nil, radius: CGFloat = AppRadius.lg) -> some View {
        modifier(VaylGlassCardModifier(accent: accent, radius: radius))
    }
}

// MARK: - Conditional Modifier

extension View {
    @ViewBuilder
    func `if`<Content: View>(
        _ condition: Bool,
        transform: (Self) -> Content
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
