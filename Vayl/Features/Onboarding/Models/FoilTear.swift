//
//  FoilTear.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/9/26.
//


//
//  FoilTear.swift
//  Vayl
//

// Features/Onboarding/Models/FoilTear.swift

import CoreGraphics
import Foundation

/// A single tear in the foil surface during BuildDeckPhase.
/// Created by VaylDirector when the user taps the foil.
/// FoilRenderer reads the tap point and path to draw the tear.
/// Age drives the dissolve progress after the integrity threshold is crossed.
struct FoilTear: Identifiable {

    // MARK: - Identity

    let id: UUID = UUID()

    // MARK: - Geometry

    /// The screen point where the user tapped to create this tear.
    /// FoilRenderer uses this as the origin for the tear path and
    /// the center of the particle scatter on dissolve.
    let tapPoint: CGPoint

    /// The computed tear shape in screen coordinates.
    /// nil until FoilRenderer computes it on first render.
    /// The path represents the split in the foil surface —
    /// tear edges receive a bright spectrum line (1pt, 80% opacity).
    var path: CGPath? = nil

    // MARK: - Dissolve State

    /// Dissolve progress for this individual tear.
    /// 0.0 = tear just created, fully visible
    /// 1.0 = fully dissolved — particle scatter complete
    /// Driven by VaylDirector after the foil integrity threshold is crossed.
    /// AppAnimation.foilDissolve governs the transition.
    var age: Double = 0
}
