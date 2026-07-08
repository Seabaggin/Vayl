import Foundation

enum CanvasEasing {
    /// nm: normalise t within a window [start, start+dur], clamp 0…1.
    static func nm(_ t: Double, _ s: Double, _ d: Double) -> Double {
        max(0, min(1, (t - s) / d))
    }

    /// ease-in-out cubic
    static func eIO3(_ x: Double) -> Double {
        x < 0.5 ? 4*x*x*x : 1 - pow(-2*x+2, 3)/2
    }

    /// ease-out quint
    static func eO5(_ x: Double) -> Double { 1 - pow(max(0, 1-x), 5) }

    /// ease-out sept
    static func eO7(_ x: Double) -> Double { 1 - pow(max(0, 1-x), 7) }
}
