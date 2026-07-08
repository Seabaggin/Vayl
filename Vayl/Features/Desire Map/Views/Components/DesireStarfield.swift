//
//  DesireStarfield.swift
//  Vayl
//

import SwiftUI

/// Ambient background dust-field shared by every Desire Map screen — rating, charted,
/// mirror, and the reveal's beat sequence. Previously lived only on `DesireMapView`'s
/// `.start` screen; extracted so `DesireRevealView` can share the identical field instead
/// of duplicating the dataset. Static positions + per-star twinkle period, unchanged from
/// the original tuning.
struct DesireStarfield: View {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let stars: [(x: Double, y: Double, d: Double, base: Double, period: Double)] = [
        (0.08, 0.04, 1.2, 0.20, 0), (0.52, 0.03, 1.0, 0.14, 0), (0.75, 0.12, 0.7, 0.10, 0),
        (0.42, 0.16, 0.8, 0.12, 0), (0.05, 0.28, 0.9, 0.18, 0), (0.35, 0.32, 0.7, 0.08, 0),
        (0.80, 0.30, 1.2, 0.15, 0), (0.70, 0.35, 0.8, 0.10, 0), (0.60, 0.50, 0.9, 0.12, 0),
        (0.32, 0.55, 1.3, 0.08, 0), (0.05, 0.58, 0.8, 0.07, 0), (0.45, 0.65, 1.0, 0.09, 0),
        (0.15, 0.70, 0.7, 0.07, 0), (0.62, 0.78, 0.9, 0.07, 0), (0.38, 0.82, 1.2, 0.08, 0),
        (0.10, 0.85, 0.6, 0.06, 0), (0.72, 0.88, 1.0, 0.07, 0), (0.50, 0.92, 0.8, 0.05, 0),
        (0.30, 0.20, 0.9, 0.13, 0), (0.90, 0.14, 0.7, 0.09, 0), (0.18, 0.44, 0.8, 0.10, 0),
        (0.85, 0.50, 0.7, 0.08, 0), (0.25, 0.62, 1.0, 0.08, 0), (0.68, 0.62, 0.8, 0.07, 0),
        (0.95, 0.72, 0.6, 0.06, 0), (0.55, 0.88, 0.9, 0.06, 0),
        (0.92, 0.07, 0.9, 0.20, 3.2), (0.28, 0.10, 1.5, 0.22, 4.8),
        (0.18, 0.18, 1.1, 0.18, 3.8), (0.65, 0.08, 1.3, 0.20, 4.1),
        (0.87, 0.21, 1.0, 0.16, 2.9), (0.55, 0.25, 1.4, 0.22, 4.5),
        (0.12, 0.38, 1.0, 0.18, 3.6), (0.48, 0.42, 1.1, 0.16, 2.7),
        (0.22, 0.45, 1.5, 0.20, 4.2), (0.90, 0.44, 0.8, 0.14, 3.4),
        (0.78, 0.60, 1.0, 0.12, 4.7), (0.88, 0.72, 1.1, 0.10, 3.1),
        (0.58, 0.15, 1.2, 0.18, 4.0), (0.40, 0.75, 1.3, 0.10, 2.8),
        (0.96, 0.38, 0.9, 0.12, 3.9), (0.02, 0.52, 1.0, 0.10, 4.3),
        (0.73, 0.48, 0.8, 0.12, 2.6), (0.14, 0.96, 1.1, 0.08, 3.7)
    ]

    var body: some View {
        Group {
            if reduceMotion || AppAnimation.lowPower {
                // Reduce Motion / Low Power: one static frame — no periodic twinkle loop.
                // Twinkling stars (period > 0) hold at their base opacity.
                Canvas { ctx, size in
                    for star in Self.stars {
                        let r = star.d / 2
                        let x = size.width * star.x
                        let y = size.height * star.y
                        ctx.fill(
                            Path(ellipseIn: CGRect(x: x - r, y: y - r, width: star.d, height: star.d)),
                            with: .color(.white.opacity(star.base))
                        )
                    }
                }
            } else {
                TimelineView(.periodic(from: .now, by: 0.067)) { timeline in
                    Canvas { ctx, size in
                        let elapsed = timeline.date.timeIntervalSinceReferenceDate
                            .truncatingRemainder(dividingBy: 1000)
                        for (idx, star) in Self.stars.enumerated() {
                            let opacity: Double = star.period > 0
                                ? 0.2 + (sin((elapsed / star.period + Double(idx) * 0.37) * .pi * 2) * 0.5 + 0.5) * 0.6
                                : star.base
                            let r = star.d / 2
                            let x = size.width * star.x
                            let y = size.height * star.y
                            ctx.fill(
                                Path(ellipseIn: CGRect(x: x - r, y: y - r, width: star.d, height: star.d)),
                                with: .color(.white.opacity(opacity))
                            )
                        }
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

#Preview("Desire Starfield") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        DesireStarfield()
    }
    .preferredColorScheme(.dark)
}
