import SwiftUI

/// Reusable card-shell modifier: background + rounded clip + border stroke.
///
/// Replaces the repetitive 3-line pattern scattered across views:
/// ```swift
/// .background(AppColors.cardBackground)
/// .clipShape(RoundedRectangle(cornerRadius: AppRadius.container))
/// .overlay(RoundedRectangle(cornerRadius: AppRadius.container).stroke(AppColors.borderSubtle, lineWidth: 1))
/// ```
///
/// Usage:
/// ```swift
/// VStack { ... }
///     .cardStyle()                          // defaults: card bg, r20, border stroke
///     .cardStyle(cornerRadius: AppRadius.md)          // custom radius
///     .cardStyle(background: .surfaceBg)    // custom bg
/// ```
struct CardStyle: ViewModifier {
    var background: Color = AppColors.cardBackground
    var cornerRadius: CGFloat = 20
    var borderColor: Color = AppColors.borderSubtle
    var lineWidth: CGFloat = 1.5

    func body(content: Content) -> some View {
        content
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: lineWidth)
            )
    }
}

extension View {
    func cardStyle(
        background: Color = AppColors.cardBackground,
        cornerRadius: CGFloat = 20,
        borderColor: Color = AppColors.borderSubtle,
        lineWidth: CGFloat = 1.5
    ) -> some View {
        modifier(CardStyle(
            background: background,
            cornerRadius: cornerRadius,
            borderColor: borderColor,
            lineWidth: lineWidth
        ))
    }
}
