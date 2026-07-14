// Design/Components/Navigation/ScrollTopEdgeFade.swift
// Vayl
//
// Top scroll-edge effect: content dissolves as it scrolls up under the top
// chrome (the masthead / Dynamic Island) instead of hard-cutting at the safe-
// area line. The BOTTOM edge is handled by TabContentWrapper's fade mask; this
// is its top-edge counterpart.
//
// Why scroll-DRIVEN, not a static mask: a tab's masthead is the first element
// inside its ScrollView, so it sits at the very top at rest. A static top mask
// would dim the page title before the user ever scrolls. Instead the fade
// engages proportionally to scroll offset — zero at the top (title crisp),
// ramping to full once content has slid up under the chrome.
//
// iOS 18+ (onScrollGeometryChange). Below that it is a no-op — the hard top edge
// is an acceptable degradation on the old baseline, not a broken layout.
//
// Apply to the ScrollView itself:
//   ScrollView { … }.scrollTopEdgeFade()

import SwiftUI

extension View {
    /// Fades the top edge of a ScrollView's content as it scrolls under the top
    /// chrome. See file header. `fadeHeight` and `engageDistance` are FEEL-GATE —
    /// tune on device.
    func scrollTopEdgeFade(fadeHeight: CGFloat = 40, engageDistance: CGFloat = 44) -> some View {
        modifier(ScrollTopEdgeFade(fadeHeight: fadeHeight, engageDistance: engageDistance))
    }
}

private struct ScrollTopEdgeFade: ViewModifier {

    let fadeHeight: CGFloat
    let engageDistance: CGFloat

    @State private var offset: CGFloat = 0

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content
                .onScrollGeometryChange(for: CGFloat.self) { geo in
                    // Distance scrolled past the resting top (content offset + the
                    // top content inset the safe area adds).
                    geo.contentOffset.y + geo.contentInsets.top
                } action: { _, newValue in
                    offset = newValue
                }
                .mask(alignment: .top) { fadeMask }
        } else {
            content
        }
    }

    /// 0 at rest (title crisp), 1 once scrolled past engageDistance (full fade).
    private var engaged: CGFloat { min(1, max(0, offset / engageDistance)) }

    private var fadeMask: some View {
        VStack(spacing: 0) {
            // Top strip: clear→black. Its top opacity interpolates from fully
            // opaque at rest (no fade) to clear when scrolled (content dissolves).
            LinearGradient(
                stops: [
                    .init(color: .black.opacity(Double(1 - engaged)), location: 0.0),
                    .init(color: .black, location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: fadeHeight)
            Rectangle().fill(Color.black)   // everything below the strip: fully visible
        }
        .animation(AppAnimation.fast, value: engaged)
    }
}
