// Tabs/LearnTab/Views/LearnCardStyle.swift
//
// The Learn-tab card surface — one glass card, unified 2026-07-16.
//
// Before, `learnCard(_ accent:)` took a colour and each section passed its own
// (purple research, magenta hub), so the tab was a stack of differently-coloured
// containers. Now every Learn card is the Map-family surface: `.vaylGlassCard()`
// (glass over the atmosphere) plus one tapered spectrum hairline along the top
// edge — the same chrome as HomePulseRail and the journal threshold. The gradient
// appears once per card, on a stroke, which is exactly the Earned Spectrum Rule.
//
// DEVICE-TUNE: the fill comes from `.vaylGlassCard()`'s `glassSurface`; the
// glass-vs-atmosphere knob lives on that token. Confirm on device.

import SwiftUI

extension View {
    /// The one Learn surface: Map-family glass + a tapered spectrum top hairline.
    /// The hairline is inset horizontally so it fades before the corner radius.
    func learnCard(cornerRadius: CGFloat = AppRadius.xl) -> some View {
        modifier(LearnCardStyle(cornerRadius: cornerRadius))
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
