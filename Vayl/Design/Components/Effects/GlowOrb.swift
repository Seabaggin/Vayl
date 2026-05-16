//
//  GlowOrb.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

// ✅ Design system audit — verified March 9, 2026

import SwiftUI

struct GlowOrb: View {
    @Environment(\.colorScheme) private var colorScheme
    let color: Color
    var size: CGFloat = 200

    // Matches AppPalette.glowOpacity values: 0.18 dark, 0.06 light.
    private var glowOpacity: Double { colorScheme == .dark ? 0.18 : 0.06 }

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [color, .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: size / 2
                )
            )
            .frame(width: size, height: size)
            .blur(radius: 40)
            .opacity(glowOpacity)
            .allowsHitTesting(false)
    }
}
