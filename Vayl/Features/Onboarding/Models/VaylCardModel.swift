//
//  VaylCardModel.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/9/26.
//

//
//  VaylCardModel.swift
//  Vayl
//

// Features/Onboarding/Models/VaylCardModel.swift

import SwiftUI

/// A single card in the OB canvas system.
/// VaylDirector writes all physics state. Renderers read only.
/// This class is never persisted — it lives only during the OB flow.
/// When a card pockets to the corner deck, a new lightweight
/// VaylCardModel is created for the corner deck representation.
/// The original is removed from tableCards or inFlightCards.
@Observable
final class VaylCardModel: Identifiable {

    // MARK: - Identity

    let id: UUID = UUID()

    // MARK: - Content
    // Written by VaylDirector when the card is created.
    // Never changed after the card is dealt.

    /// The question or prompt on the card face.
    /// nil for cards that have no text content (e.g. corner deck representations).
    var question: String? = nil

    /// The content displayed on this card's face.
    /// Director writes this when creating or mutating a card.
    /// VaylCardRenderer reads it and passes it to VaylCardFace.
    /// Defaults to .blank — a card with no content assigned yet.
    var content: VaylCardContent = .blank

    /// Whether the card is currently showing its face.
    /// VaylDirector writes this. VaylCardRenderer reads it to choose
    /// VaylCardBack vs VaylCardFace. Do not use as an animation driver —
    /// flipProgress is the animation value.
    var isFaceUp: Bool = false

    /// Which OB credential this card carries.
    /// Written when the card is created. Used by CornerDeckView
    /// to verify all six credentials are collected.
    /// nil for quiz cards and cards with no credential association.
    var credential: OBCredential? = nil

    // MARK: - Physics State
    // VaylDirector writes only. VaylCardRenderer reads only.
    // No view or component may write these values directly.
    // All physics state changes go through VaylDirector methods.

    /// Position of the card center in screen coordinates.
    /// VaylDirector sets this to the deal point origin before dealing,
    /// then animates to the destination.
    var position: CGPoint = .zero

    /// Rotation in degrees. Positive = clockwise.
    /// Used for table scatter and corner deck fan offsets.
    var rotation: Double = 0

    /// Uniform scale applied by VaylCardRenderer after flipProgress scale.
    /// 1.0 = natural size. Used for raise-and-confirm press-down on unchosen cards.
    var scale: Double = 1.0

    /// Flip progress along the horizontal axis.
    /// 0.0 = fully face-down (back visible)
    /// 0.5 = edge-on (neither face visible — swap surfaces at this moment)
    /// 1.0 = fully face-up (front visible)
    /// VaylCardRenderer applies this as scaleX.
    /// VaylDirector drives this through AppAnimation.cardFlip.
    var flipProgress: Double = 0

    /// Elevation above the table surface.
    /// 0.0 = flat on the felt
    /// 1.0 = fully lifted toward the user
    /// AppElevation.cardShadow(elevation:) reads this to compute shadow.
    var elevation: Double = 0

    /// Overall opacity. 0.0 = invisible, 1.0 = fully opaque.
    /// Used for fade-in on deal and fade-out on pocket/retract.
    var opacity: Double = 1.0

    /// Horizontal scale for the flip animation axis.
    /// Driven from 1.0 → 0.0 → -1.0 by VaylDirector during a flip.
    /// VaylCardRenderer swaps VaylCardBack ↔ VaylCardFace at the
    /// moment scaleX crosses zero (flipProgress == 0.5).
    /// Do not use for any purpose other than flip axis rendering.
    var scaleX: Double = 1.0
}
