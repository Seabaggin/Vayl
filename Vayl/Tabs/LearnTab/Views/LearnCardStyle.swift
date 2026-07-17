// Tabs/LearnTab/Views/LearnCardStyle.swift
//
// The Learn-tab card surface — real Liquid Glass, 2026-07-16.
//
// `.vaylGlassCard()` is not glass. It fills with `glassSurface` — white at 3% —
// and strokes a hairline. No material, no backdrop blur, nothing frosted. Its
// token comment says why, and it's deliberate: "this lets the aurora bloom read
// through the card." That is exactly right for the Map tab, where the bloom
// reading through IS the content and there are a handful of words on screen.
//
// Learn is a reading surface with paragraphs, and the research card sits directly
// under the atmosphere's brightest point (`.stat` runs top 1.00). With nothing
// diffusing it, the bloom arrives at full strength behind body copy — which is
// what made a 13pt gradient citation vanish into purple light. The card wasn't
// doing a card's job.
//
// So Learn uses iOS 26's Liquid Glass (deployment target is 26.0). PartnerChip
// already adopted it — `.glassEffect(.regular, in: Capsule())` — and this follows
// its pattern, including the gotcha its comment documents: the material goes in a
// `.background`, never `glassEffect`'s own `content:` closure, whose vibrancy pass
// darkens and desaturates whatever it samples.
//
// Same spectrum hairline, same radius, same everything else. The difference is
// that it now diffuses what's behind it, which is the whole point of glass.

import SwiftUI

extension View {
    /// The Learn surface: iOS 26 Liquid Glass + a tapered spectrum top hairline.
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

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    func body(content: Content) -> some View {
        content
            // The material is a `.background`, never `glassEffect`'s `content:`
            // closure — its vibrancy pass darkens whatever it composites, and the
            // background form also sizes off the real content (PartnerChip's
            // comment documents both). `.fill(.clear)` gives glassEffect a shape to
            // sample through without painting over it.
            .background {
                shape
                    .fill(.clear)
                    .glassEffect(.regular, in: shape)
                    .overlay(shape.strokeBorder(AppColors.borderSubtle, lineWidth: 1))
            }
            .overlay(alignment: .top) {
                TaperedSpectrumHairline(thickness: 1.5)
                    .padding(.horizontal, AppSpacing.md)
            }
            .clipShape(shape)
    }
}
