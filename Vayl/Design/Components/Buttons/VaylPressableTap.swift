// Design/Components/Buttons/VaylPressableTap.swift
// Vayl
//
// The `.onTapGesture` counterpart to `.buttonStyle(.vaylPressable)`: the tap
// contract (press-scale + light haptic on touch-DOWN + action on release) for
// any tappable View that isn't a `Button`.
//
// `.onTapGesture` fires on touch-UP and carries no press state, so sites that
// want feedback hand-roll an `@State isPressed` — and usually get it wrong,
// flipping isPressed true on the tap (touch-up) with a timed reset, so the
// scale is a post-tap blip instead of a press-DOWN response. This modifier
// drives the press from a `minimumDistance: 0` drag, so the scale + haptic land
// the instant the finger touches, and the action fires on release within slop.
//
// Usage — replaces `.onTapGesture { action() }` plus any manual press state:
//   myCard.vaylPressableTap { store.open() }

import SwiftUI

extension View {
    /// Press-scale + light haptic on touch-DOWN, `action` on release within slop.
    /// `scale` defaults to the tap-contract 0.96; raise it toward 1.0 for large
    /// surfaces where 0.96 reads as too much travel.
    func vaylPressableTap(scale: CGFloat = 0.96, action: @escaping () -> Void) -> some View {
        modifier(VaylPressableTap(scale: scale, action: action))
    }
}

private struct VaylPressableTap: ViewModifier {

    let scale: CGFloat
    let action: () -> Void

    /// Movement (pt) past which the touch is a scroll/drag, not a tap — cancels.
    private let slop: CGFloat = 12

    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .scaleEffect(isPressed ? scale : 1.0)
            .animation(AppAnimation.fast, value: isPressed)
            .sensoryFeedback(trigger: isPressed) { _, pressed in
                pressed ? .impact(weight: .light) : nil
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in if !isPressed { isPressed = true } }
                    .onEnded { value in
                        isPressed = false
                        // Fire only if the finger stayed within slop — a scroll or
                        // drag-away cancels, matching a real tap's forgiveness.
                        if abs(value.translation.width) <= slop && abs(value.translation.height) <= slop {
                            action()
                        }
                    }
            )
    }
}
