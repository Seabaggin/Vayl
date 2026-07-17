// Tabs/LearnTab/Views/LearnCardStyle.swift
//
// The Learn-tab card surface — Map-family CLEAR glass. Bryan's call, 2026-07-16.
//
// `.vaylGlassCard()` fills with `glassSurface` (white at 3%) and strokes a
// hairline: no material, no backdrop blur. It is clear, not frosted, and that's
// deliberate — the token's comment says so ("this lets the aurora bloom read
// through the card"). The atmosphere showing through IS the look.
//
// Know the trade you're taking. The app has two card languages, and this is the
// atmospheric one:
//
//   .vaylGlassCard()  clear 3% — Map tab, void-native surfaces. The bloom reads
//                     through. Few words.
//   HomePulseRail     OPAQUE cardBackground + spectrum top hairline. Its comment:
//                     "so the atmosphere does NOT bleed through". Same hairline,
//                     same brand language, readable pane.
//
// Learn takes the clear one, so the bloom lands at full strength behind body copy
// — the research card sits under the atmosphere's brightest point (.stat runs
// top 1.00). Legibility therefore has to be solved in the TEXT (weight, colour,
// size), because the surface is deliberately not helping.
//
// Two things tried and rejected here, both because they kill the clear look:
//   • iOS 26 Liquid Glass (.glassEffect(.regular), as PartnerChip uses) — real
//     frosted glass, diffuses the bloom, helps small text.
//   • Opaque reading cards (the HomePulseRail pattern).
// Don't re-introduce either without asking.
//
// DEVICE-TUNE: the glass-vs-atmosphere knob is `AppColors.glassSurface` (0.03) —
// shared with the Map tab, so Learn-only weight means giving this modifier its own
// fill rather than moving the token.

import SwiftUI

extension View {
    /// The one Learn surface: Map-family clear glass + a tapered spectrum top
    /// hairline. The hairline is inset horizontally so it fades before the corner.
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
