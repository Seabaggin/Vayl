//
//  TableSurfaceMath.swift
//  Vayl
//
import SwiftUI

// Module-level functions — no CoreGraphics, no UIKit, pure arithmetic.
// Called exclusively from the Canvas closure in TableSurfaceView.

/// Linear interpolation between two CGFloat values.
func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
    a + (b - a) * t
}

/// Clamp a CGFloat to a closed range.
func clamp(_ value: CGFloat, _ minimum: CGFloat, _ maximum: CGFloat) -> CGFloat {
    Swift.max(minimum, Swift.min(maximum, value))
}

/// Fractal Brownian Motion — 4 octaves.
/// Combines layered sin/cos noise at increasing frequencies and decreasing
/// amplitudes to produce organic, terrain-like variation along a 2D field.
/// x, y are normalised noise-space coordinates, not screen pixels.
func fbm(_ x: CGFloat, _ y: CGFloat, _ octaves: Int) -> CGFloat {
    var v: CGFloat         = 0
    var amplitude: CGFloat = 1.0
    var frequency: CGFloat = 1.0
    var sum: CGFloat       = 0

    for octave in 0 ..< octaves {
        let o     = CGFloat(octave)
        let sx    = x * frequency
        let sy    = y * frequency
        let layer =
            sin(sx * 1.10 + sy * 0.65 + o * 2.3) +
            cos(sx * 0.72 - sy * 1.28 + o * 1.8)
        v   += amplitude * layer
        sum += amplitude * 2
        amplitude *= 0.52
        frequency *= 1.95
    }

    return v / sum
}

/// Domain-warped FBM.
/// Displaces the input coordinates using two fbm samples before the final
/// evaluation. Produces the characteristic curved, flowing distortion visible
/// in the topo lines — straight vertical lines would read as digital.
func domainWarp(_ x: CGFloat, _ y: CGFloat, _ warpStrength: CGFloat) -> CGFloat {
    let wx = fbm(x, y, 4)
    let wy = fbm(x + 3.8, y + 1.6, 4)
    return fbm(x + warpStrength * wx, y + warpStrength * wy, 4)
}
