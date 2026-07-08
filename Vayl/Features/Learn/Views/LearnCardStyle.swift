// Features/Learn/Views/LearnCardStyle.swift
//
// The Learn-tab card surface. Unlike the opaque `.themedCard()`, this fill is
// translucent so the page's OnboardingAtmosphere (void + spectrum bloom) shows
// THROUGH the card — the section's single-colour hairline (cyan / purple /
// magenta) is the only hard edge. Matches the OB glass-over-void direction the
// tabs are moving toward.
//
// DEVICE-TUNE: the fill is `AppColors.whisperFill` — the glass-vs-atmosphere
// knob lives on that token now; lower lets more atmosphere through, higher
// reads as a more solid card. Confirm on device.

import SwiftUI

extension View {
    func learnCard(_ accent: Color, cornerRadius: CGFloat = AppRadius.xl) -> some View {
        modifier(LearnCardStyle(accent: accent, cornerRadius: cornerRadius))
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

private struct LearnCardStyle: ViewModifier {
    let accent: Color
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(AppColors.whisperFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(accent.opacity(0.45), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}
