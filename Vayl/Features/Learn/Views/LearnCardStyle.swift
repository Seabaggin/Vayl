// Features/Learn/Views/LearnCardStyle.swift
//
// The Learn-tab card surface. Unlike the opaque `.themedCard()`, this fill is
// translucent so the page's OnboardingAtmosphere (void + spectrum bloom) shows
// THROUGH the card — the section's single-colour hairline (cyan / purple /
// magenta) is the only hard edge. Matches the OB glass-over-void direction the
// tabs are moving toward.
//
// DEVICE-TUNE: `fillOpacity` is the glass-vs-atmosphere knob — lower lets more
// atmosphere through, higher reads as a more solid card. Confirm on device.

import SwiftUI

extension View {
    func learnCard(_ accent: Color, cornerRadius: CGFloat = AppRadius.xl) -> some View {
        modifier(LearnCardStyle(accent: accent, cornerRadius: cornerRadius))
    }
}

private struct LearnCardStyle: ViewModifier {
    let accent: Color
    let cornerRadius: CGFloat
    private let fillOpacity: Double = 0.04   // faint glass lift over the atmosphere

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white.opacity(fillOpacity))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(accent.opacity(0.30), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}
