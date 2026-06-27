// Features/Home/Components/CardChestContainer.swift
// Vayl
//
// The deck interaction now lives in CardCarousel (the in-place, elevating deck),
// wired up by HomeDashboardView (hand selection + "Settle in"). The previous
// fullScreenCover / DeckCarousel reinventions were removed — a cover always slides,
// and CardCarousel already elevates in place with a screen-wide dim.
//
// This file retains the shared NoiseTexture helper.

import SwiftUI

struct NoiseTexture: View {
    var opacity: CGFloat = 0.028

    var body: some View {
        Canvas { context, size in
            for _ in 0..<Int(size.width * size.height * 0.04) {
                let x          = CGFloat.random(in: 0..<size.width)
                let y          = CGFloat.random(in: 0..<size.height)
                let brightness = CGFloat.random(in: 0.4...1.0)
                context.fill(
                    Path(CGRect(x: x, y: y, width: 1, height: 1)),
                    with: .color(Color.white.opacity(brightness * opacity))
                )
            }
        }
        .allowsHitTesting(false)
    }
}
