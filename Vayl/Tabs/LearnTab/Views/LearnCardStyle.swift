// Tabs/LearnTab/Views/LearnCardStyle.swift
//
// Learn has TWO surfaces, and the difference is the point (2026-07-16).
//
// `learnCard()` — GLASS. The Knowledge hub only. `glassSurface` is white at 3%,
// which makes it 97% window: what you see is the OnboardingAtmosphere behind it.
// That's why it looks alive, and it's the whole reason it's reserved.
//
// `learnReadingCard()` — OPAQUE. Everything else. Same reason, inverted: when
// every card was glass, they all LOOKED different despite sharing one token,
// because `.stat`'s atmosphere runs top 1.00 → mid 0.50 → bottom 1.00 and the
// cards sit at different heights. Worse, the atmosphere is pinned to the screen
// while cards scroll over it, so a single card changed shade as you scrolled it
// through the gradient. Nothing makes a 3% fill look consistent — consistency
// isn't what a window does. A reading surface needs to hold still.
//
// So glass now means "this one is alive" instead of being wallpaper, which is
// what DESIGN.md says it's for: "glass is one canonical surface, not decoration
// sprinkled everywhere."
//
// DEVICE-TUNE: if the finding text struggles over the bright top of the
// atmosphere, the knob is `AppColors.glassSurface` (0.03) — but that token is
// shared with the Map tab, so raising it there moves those surfaces too. If Learn
// alone needs a heavier glass, give this modifier its own fill rather than
// changing the shared token.

import SwiftUI

extension View {
    /// The alive card: Map-family glass + a tapered spectrum top hairline. The
    /// hairline is inset horizontally so it fades before the corner radius.
    ///
    /// Reserve it. If more than one thing on a screen wears this, it stops
    /// meaning anything.
    func learnCard(cornerRadius: CGFloat = AppRadius.xl) -> some View {
        modifier(LearnGlassCardStyle(cornerRadius: cornerRadius))
    }

    /// The reading card: opaque, quiet, identical wherever it sits and stable
    /// while it scrolls. No hairline — the spectrum belongs to the alive card.
    func learnReadingCard(cornerRadius: CGFloat = AppRadius.xl) -> some View {
        modifier(LearnReadingCardStyle(cornerRadius: cornerRadius))
    }
}

/// Tap feedback for Learn buttons — the CLAUDE.md trio (press-scale + light
/// haptic on press + the button's action). Use in place of `.buttonStyle(.plain)`.
struct PressableCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(AppAnimation.fast, value: configuration.isPressed)
            .sensoryFeedback(trigger: configuration.isPressed) { _, pressed in
                pressed ? .impact(weight: .light) : nil
            }
    }
}

private struct LearnGlassCardStyle: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .vaylGlassCard(radius: cornerRadius)
            .overlay(alignment: .top) {
                TaperedSpectrumHairline(thickness: 1.5)
                    .padding(.horizontal, AppSpacing.md)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

/// Opaque `cardBackground` rather than `.themedCard()`: that modifier hardcodes
/// `AppRadius.lg`, strokes at 1.5pt, and branches on `@Environment(\.colorScheme)`
/// — a legacy holdover DESIGN.md says not to copy into new views. This matches the
/// glass card's radius and 1pt stroke so the two read as siblings.
private struct LearnReadingCardStyle: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                AppColors.cardBackground,
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(AppColors.borderSubtle, lineWidth: 1)
            )
    }
}
