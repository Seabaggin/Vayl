import SwiftUI

/// Reusable card-shell modifier: background + rounded clip + border stroke.
///
/// Replaces the repetitive 3-line pattern scattered across views:
/// ```swift
/// .background(AppColors.card)
/// .clipShape(RoundedRectangle(cornerRadius: 20))
/// .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppColors.border, lineWidth: 1))
/// ```
///
/// Usage:
/// ```swift
/// VStack { ... }
///     .cardStyle()                          // defaults: card bg, r20, border stroke
///     .cardStyle(cornerRadius: 12)          // custom radius
///     .cardStyle(background: .surfaceBg)    // custom bg
/// ```
struct CardStyle: ViewModifier {
    var background: Color = AppColors.card
    var cornerRadius: CGFloat = 20
    var borderColor: Color = AppColors.border
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
        background: Color = AppColors.card,
        cornerRadius: CGFloat = 20,
        borderColor: Color = AppColors.border,
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
