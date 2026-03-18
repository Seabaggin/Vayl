import SwiftUI

/// Shared holographic pill border — single source of truth.
struct PillBorder: ViewModifier {
    var cornerRadius: CGFloat = 100
    var lineWidth: CGFloat = 3
    var glowRadius: CGFloat = 6
    var opacity: Double = 0.8

    func body(content: Content) -> some View {
        let gradient = LinearGradient(
            colors: [AppColors.cyan, AppColors.purple, AppColors.magenta],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        return content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(gradient, lineWidth: lineWidth)
                    .opacity(opacity)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(gradient, lineWidth: lineWidth + 1)
                    .blur(radius: glowRadius)
                    .opacity(0.35)
            )
            .shadow(color: AppColors.purple.opacity(0.18), radius: 6)
            .shadow(color: AppColors.cyan.opacity(0.08), radius: 12)
            .shadow(color: AppColors.purple.opacity(0.06), radius: 16)
    }
}

extension View {
    func pillBorder(
        cornerRadius: CGFloat = 100,
        lineWidth: CGFloat = 3,
        glowRadius: CGFloat = 6,
        opacity: Double = 0.8
    ) -> some View {
        modifier(PillBorder(
            cornerRadius: cornerRadius,
            lineWidth: lineWidth,
            glowRadius: glowRadius,
            opacity: opacity
        ))
    }
}
