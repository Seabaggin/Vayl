//
//  LightModeShimmer.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/20/26.
//


// LightModeShimmer.swift
// Open Lightly
//
// Warm Aurora shimmer fill for light mode surfaces.
// Light mode counterpart to HolographicShimmer.swift.
//
// Key differences from HolographicShimmer:
//   - Colors: AppColors.lightShimmerColors (purple/magenta/gold/magentaLight)
//             No cyan — reads clinical on cream
//   - Opacity: 7–11% vs 40–50% in dark — tinted ink-wash, not a light blast
//   - Duration: 11s default vs 6s — slower sweep on cream reads more languid
//   - Everything else: identical structure, identical mechanics
//
// Usage (identical pattern to HolographicShimmer):
// ```swift
// Capsule()
//     .fill(AppColors.lightFrostPill)
//     .overlay { LightModeShimmer().clipShape(Capsule()) }
// ```

import SwiftUI

/// Self-contained animated warm aurora shimmer fill for light mode.
/// Renders a 3× wide warm gradient that sweeps left→right continuously.
///
/// Use as a background layer clipped to any shape:
/// ```swift
/// Capsule()
///     .fill(AppColors.lightFrostPill)
///     .overlay { LightModeShimmer().clipShape(Capsule()) }
/// ```
struct LightModeShimmer: View {
    /// Animation duration in seconds. Defaults to 11 (languid warm sweep).
    /// Use 9 for selected pills, 13 for CTA buttons.
    var duration: Double = 11
    var usePillColors: Bool = false

    @State private var phase: CGFloat = 0

    private var effectiveDuration: Double {
        // Pills need faster sweep to feel alive —
        // matches HolographicShimmer's 6s default.
        // Background washes keep the languid 11s.
        usePillColors ? min(duration, 7.0) : duration
    }

    // Reads directly from AppColors — single source of truth.
    // purple → magenta → gold → magentaLight → purple
    // Same wrap-around structure as HolographicShimmer for seamless loop.
    private var colors: [Color] {
        usePillColors
            ? AppColors.lightPillShimmerColors
            : AppColors.lightShimmerColors
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
                .frame(width: w * 3, height: geo.size.height)
                .offset(x: phase * -w * 2)
        }
        .clipped()
        .onAppear {
            withAnimation(.easeInOut(duration: effectiveDuration).repeatForever(autoreverses: true)) {
                phase = 1
            }
        }
    }
}
