//
//  HandBackFollow.swift
//  Vayl
//

import SwiftUI

/// Banded, weighty finger-follow for a lifted card being handed UP to the dealer.
///
/// The locked mechanic from the NamePhase pilot (Phase 4), shared so every
/// "lift → swipe up to hand it back" reads identically and tunes from ONE place:
///   • Upward travel is STIFFENED (sub-1:1 gain) and eases into a soft ceiling, so the
///     card follows with weight and a hard flick can't launch it off the top.
///   • Lateral drift is BANDED toward a cap, keeping the card near center so the
///     corner-deck pocket flight always takes over from a sane position.
///   • Downward barely gives — you can't shove the card back into the table.
///
/// IMPORTANT: this drives the VISUAL follow only. Commit must still key off the RAW
/// finger translation at the call site, so the stiffer follow never makes the toss
/// harder to trigger. On commit, animate the returned offset back to `.zero` inside the
/// pocket flight (so drift + tilt resolve INTO the corner animation, no snap); on a
/// short release, settle it back with `AppAnimation.cardSettle`.
enum HandBackFollow {

    /// Visual offset for the lifted card given the live drag `translation`.
    static func offset(for translation: CGSize, cardWidth: CGFloat, cardHeight: CGFloat) -> CGSize {
        let xCap  = Double(cardWidth)  * 0.45                                 // FEEL-GATE: lateral band
        let upCap = Double(cardHeight) * 0.70                                 // FEEL-GATE: upward ceiling
        let drift = CGFloat(xCap * tanh(Double(translation.width) * 0.5 / xCap))
        let lift: CGFloat
        if translation.height < 0 {
            // Upward: stiff (sub-1:1) + soft ceiling — weighty, bounded, can't fly off.
            lift = CGFloat(-upCap * tanh(Double(-translation.height) * 0.6 / upCap))   // FEEL-GATE: upward stiffness
        } else {
            lift = translation.height * 0.2                                   // FEEL-GATE: downward resistance
        }
        return CGSize(width: drift, height: lift)
    }

    /// Gentle tilt (degrees) as the card drifts sideways — a held card leaning as it moves.
    static func tilt(for driftWidth: CGFloat, screenWidth: CGFloat) -> Double {
        Double(driftWidth) / Double(screenWidth) * 12.0                       // FEEL-GATE: tilt degrees
    }
}
