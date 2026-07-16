// Tabs/LearnTab/Views/LearnCardStyle.swift
//
// The Learn-tab card surface — the Map-family glass card, unified 2026-07-16.
//
// Before: each section painted its own accent (purple research, magenta hub) over
// a hand-rolled whisperFill + tinted-stroke surface. That per-section paint is what
// made Learn read as a content-hub template rather than a place: three differently
// coloured containers stacked in a tab. Now every Learn card is the same chrome as
// HomePulseRail and the journal threshold — `.vaylGlassCard()` (glass over the
// atmosphere) plus one tapered spectrum hairline along the top edge. The gradient
// appears once per card, on a stroke, which is exactly the Earned Spectrum Rule.
// Accent colour survives only on interactive text.
//
// Reference: docs/mockups/learn-tab-v2.html, direction D (locked 2026-07-16).

import SwiftUI

extension View {
    /// The one Learn surface: Map-family glass + a tapered spectrum top hairline.
    /// The hairline is inset horizontally so it fades before the corner radius,
    /// mirroring the journal threshold's top-edge rule.
    func learnCard(cornerRadius: CGFloat = AppRadius.container) -> some View {
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

/// The section overline — 11pt tracked uppercase, the same label role Pulse and the
/// journal threshold use. Replaces Learn's old 16pt coloured ClashDisplay section
/// headers, which competed with the masthead and painted each section a colour.
struct LearnOverline: View {
    let text: String

    /// Keep `text` sentence-case at the call site: `overlineTracked()` owns the
    /// uppercase transform, the font, and the tracking.
    var body: some View {
        Text(text)
            .overlineTracked()
            .foregroundStyle(AppColors.textSectionLabel)
    }
}

/// A quiet trailing text action ("All terms ›"). The old shimmer-capsule pills are
/// gone: shimmer is a CTA material, not section chrome.
struct LearnTextLink: View {
    let label: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xxs) {
                Text(label)
                    .font(AppFonts.buttonLabel)
                Image(systemName: AppIcons.chevronRight)
                    .font(AppFonts.caption)
            }
            .foregroundStyle(AppColors.textAccent)
            .frame(minHeight: 44)          // hit target; the visual stays compact
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableCardStyle())
    }
}
