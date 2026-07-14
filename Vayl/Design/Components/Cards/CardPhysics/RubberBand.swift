// Design/Components/Cards/CardPhysics/RubberBand.swift
// Vayl
//
// Apple's rubber-band easing (Designing Fluid Interfaces sample code). The
// further past a boundary you drag, the less the element follows — so an edge
// reads as "responsive, but there is nothing more here," never a hard wall.
//
// Shared by every bounded drag so the resistance feel is identical everywhere:
// the card carousel ends (CarouselPhysics) and the gender drum ends (GenderPhase).

import CoreGraphics

enum VaylRubberBand {

    /// The default resistance constant Apple ships (0.55). Lower resists harder.
    static let defaultConstant: CGFloat = 0.55

    /// Damped overshoot. `overshoot` and the return value are in the same units
    /// as `dimension`; the result saturates toward `dimension` as `overshoot`
    /// grows, so you can never pull more than ~`dimension` past the bound.
    static func damp(_ overshoot: CGFloat, dimension: CGFloat, constant: CGFloat = defaultConstant) -> CGFloat {
        (overshoot * dimension * constant) / (dimension + constant * abs(overshoot))
    }

    /// Double convenience for index-unit callers (CarouselPhysics.position).
    static func damp(_ overshoot: Double, dimension: Double, constant: Double = Double(defaultConstant)) -> Double {
        (overshoot * dimension * constant) / (dimension + constant * abs(overshoot))
    }
}
