// Design/Components/Buttons/VaylPressableStyle.swift
// Vayl
//
// The shared press-feedback ButtonStyle — the CLAUDE.md tap contract as one
// reusable style so a control never has to re-implement (or forget) it:
//
//   1. press-scale on touch-DOWN   (RESPONSE: feedback is instant, on press)
//   2. a light haptic on touch-DOWN (not on release inside the action)
//   3. the button's own action      (fires on touch-UP, as SwiftUI does)
//
// Use in place of `.buttonStyle(.plain)` on any Button whose only feedback
// need is the standard press trio. Controls with a richer press sequence
// (VaylButton's border-charge, PressableCardStyle's card surface) keep their
// own styles; this is the plain-pill / plain-row default.
//
// `scale` defaults to the tap-contract 0.97; pass a lighter value for large
// surfaces where 0.97 reads as too much travel.

import SwiftUI

struct VaylPressableStyle: ButtonStyle {

    var scale: CGFloat = 0.97

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(AppAnimation.fast, value: configuration.isPressed)
            // Haptic fires the instant the finger lands, not when the action
            // runs on release — the felt half of the RESPONSE principle.
            .sensoryFeedback(trigger: configuration.isPressed) { _, pressed in
                pressed ? .impact(weight: .light) : nil
            }
    }
}

extension ButtonStyle where Self == VaylPressableStyle {
    /// The shared press-feedback style (press-scale + light haptic on touch-down).
    static var vaylPressable: VaylPressableStyle { VaylPressableStyle() }

    /// Press-feedback style with a custom scale (e.g. `.vaylPressable(scale: 0.99)`
    /// for a large surface where the default 0.97 reads as too much travel).
    static func vaylPressable(scale: CGFloat) -> VaylPressableStyle {
        VaylPressableStyle(scale: scale)
    }
}
