// Vayl/Core/Models/PulsePosition.swift

import Foundation

/// A capacity reading as a point in the circumplex.
/// Axes are normalised 0...1: energy 0 = low, 1 = high; openness 0 = guarded, 1 = open.
/// Midline (0.5) ties resolve toward high/open (>= rule).
struct PulsePosition: Equatable, Codable {
    var energy: Double      // 0...1 (vertical; 0 = low, 1 = high)
    var openness: Double    // 0...1 (horizontal; 0 = guarded, 1 = open)

    init(energy: Double, openness: Double) {
        self.energy   = Self.clamp(energy)
        self.openness = Self.clamp(openness)
    }

    private static func clamp(_ v: Double) -> Double { max(0, min(1, v)) }

    /// Which quadrant this point falls in. Midline ties (>= 0.5) resolve toward high/open.
    var quadrant: PulseQuadrant {
        let charged = energy >= 0.5
        let open    = openness >= 0.5
        switch (charged, open) {
        case (true,  true):  return .expansive
        case (true,  false): return .reactive
        case (false, true):  return .receptive
        case (false, false): return .protective
        }
    }

    /// Distance to another reading (0 = same point, ~1.41 = opposite corners).
    func distance(to other: PulsePosition) -> Double {
        let de  = energy   - other.energy
        let dop = openness - other.openness
        return (de * de + dop * dop).squareRoot()
    }

    /// Legacy 1D capacity score (1...4) derived from energy, so existing tier callers keep working.
    var capacityScore: Double { 1 + energy * 3 }
}
