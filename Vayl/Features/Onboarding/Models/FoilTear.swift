//
//  FoilTear.swift
//  Vayl
//

// Features/Onboarding/Models/FoilTear.swift

import CoreGraphics
import Foundation

/// A single crack in the sealed case during BuildDeckPhase.
/// Created by VaylDirector when the user taps the case (Beat 5, crack ceremony).
/// Three tears → the foil integrity collapses and the case shatters.
struct FoilTear: Identifiable {

    // MARK: - Identity

    let id: UUID = UUID()

    // MARK: - Geometry

    /// The tap point in FACE-LOCAL UV (u across the case front, v down it).
    /// Stored in face space — never screen space — so the crack sticks to the
    /// case while it floats and tilts (ceremony spec: tears convert to
    /// face-local UV at tap time).
    let faceUV: CGPoint

    /// Authored dominant orientation of this crack's main fracture, in degrees
    /// (0 = horizontal across the face, 90 = vertical down it). Each sequence
    /// gives its three strikes deliberately different orientations.
    let angleDeg: Double

    /// Stable seed for the tear's generated branch geometry — the crack
    /// pattern is procedural but identical frame to frame.
    let seed: UInt64 = .random(in: .min ... .max)

    /// When the strike landed — drives the crack's propagation animation
    /// (cracks travel outward from the finger; they don't appear formed).
    let struck: Date = .now
}
