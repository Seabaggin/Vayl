// Features/Onboarding/Models/CardLandingSlot.swift

import CoreGraphics

/// One predefined landing zone for the OB card deal.
///
/// `xFrac`/`yFrac` define the card center as a fraction of screen dimensions,
/// so the zone adapts to any device without per-device tuning.
///
/// `angleDeg` is in SwiftUI degrees (positive = clockwise). The jitter fields
/// add per-deal randomness within the zone, keeping each deal feeling organic
/// while staying within the intended visual region.
struct CardLandingSlot {
    let id: Int
    let xFrac: CGFloat
    let yFrac: CGFloat
    let angleDeg: Double
    let jitterX: CGFloat
    let jitterY: CGFloat
    let jitterAngle: Double

    struct Resolved {
        let position: CGPoint
        let angleDeg: Double
    }

    func resolve(in size: CGSize) -> Resolved {
        let x = size.width  * xFrac + CGFloat.random(in: -jitterX...jitterX)
        let y = size.height * yFrac + CGFloat.random(in: -jitterY...jitterY)
        let a = angleDeg    + Double.random(in: -jitterAngle...jitterAngle)
        return Resolved(position: CGPoint(x: x, y: y), angleDeg: a)
    }
}
