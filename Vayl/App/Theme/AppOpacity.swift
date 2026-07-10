// App/Theme/AppOpacity.swift

import CoreGraphics

/// Tier 2 — Semantic opacity ramp.
///
/// The recurring `.opacity(0.xx)` literals across the Views collapse onto this
/// one ordered scale. Reach for the nearest rung by role, not by eyeballing a
/// decimal: a barely-there wash is `whisper`, a hard structural stroke is
/// `stroke`, and a breathing glow travels between `glowFloor` and `glowPeak`.
///
/// Rules:
///   • No raw opacity literal in a View when a rung fits (Design Token Contract).
///   • Glow opacity never travels outside `glowFloor…glowPeak` (0.30→0.70) —
///     the Animation Feel Contract's "never 0→1" rule, encoded.
enum AppOpacity {

    /// 0.04 — The faintest tonal wash. A surface you sense more than see.
    static let whisper: CGFloat = 0.04

    /// 0.08 — Hairline dividers and the softest separators.
    static let hairline: CGFloat = 0.08

    /// 0.15 — Structural borders and resting strokes on glass.
    static let border: CGFloat = 0.15

    /// 0.25 — Dimmed/receded content, secondary fills, disabled tints.
    static let dim: CGFloat = 0.25

    /// 0.45 — A present, deliberate stroke — an accent outline that reads.
    static let stroke: CGFloat = 0.45

    /// 0.30 — The floor of a breathing glow. Never dip a glow below this.
    static let glowFloor: CGFloat = 0.30

    /// 0.70 — The peak of a breathing glow. Never push a glow above this.
    static let glowPeak: CGFloat = 0.70
}
