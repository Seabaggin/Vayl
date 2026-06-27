//
//  StarVeil.swift
//  Vayl
//
//  A subtle ambient starfield: fixed, deterministic stars with a gentle twinkle. Used to
//  re-establish the desire-map "world" over an obscured Home (transparent, so the dimmed
//  dashboard still reads faintly through it, the "almost home but still in the map" feel).
//  Reduce Motion: static stars, no twinkle.
//

import SwiftUI

struct StarVeil: View {
    var count: Int = 46
    var maxOpacity: Double = 0.55

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let stars: [Star]

    private struct Star { let x, y, r, phase, speed: Double }

    init(count: Int = 46, maxOpacity: Double = 0.55, seed: UInt64 = 0x5641_594C_5354_4152) {
        self.count = count
        self.maxOpacity = maxOpacity
        var rng = SplitMix64(seed: seed)
        self.stars = (0..<count).map { _ in
            Star(
                x: rng.unit(),
                y: rng.unit(),
                r: 0.6 + rng.unit() * 1.2,
                phase: rng.unit() * 6.2831,
                speed: 0.5 + rng.unit() * 1.4
            )
        }
    }

    var body: some View {
        Group {
            if reduceMotion {
                Canvas { ctx, size in draw(&ctx, size: size, time: nil) }
            } else {
                TimelineView(.animation) { tl in
                    Canvas { ctx, size in
                        draw(&ctx, size: size, time: tl.date.timeIntervalSinceReferenceDate)
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func draw(_ ctx: inout GraphicsContext, size: CGSize, time: Double?) {
        for s in stars {
            let twinkle: Double = time == nil ? 0.6 : (sin(time! * s.speed + s.phase) + 1) / 2
            let opacity = maxOpacity * (0.25 + 0.75 * twinkle) * min(1, s.r / 1.4)
            let d = s.r
            let rect = CGRect(x: s.x * size.width - d / 2, y: s.y * size.height - d / 2, width: d, height: d)
            ctx.fill(Path(ellipseIn: rect), with: .color(.white.opacity(opacity)))
        }
    }
}

/// Deterministic RNG so the star positions are stable across redraws (only the twinkle moves).
private struct SplitMix64 {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
    mutating func unit() -> Double { Double(next() >> 11) * (1.0 / 9_007_199_254_740_992.0) }
}
