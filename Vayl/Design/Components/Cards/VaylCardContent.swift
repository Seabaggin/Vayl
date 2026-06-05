//
//  VaylCardContent.swift
//  Vayl
//
//  Design/Components/Cards/VaylCardContent.swift
//
//  Public enum describing what content lives on a VaylCardFace.
//  VaylCardFace switches on this. Director writes it onto VaylCardModel.
//  Renderer reads it and passes it to VaylCardFace.
//

import SwiftUI

/// Describes the content type of a VaylCardFace.
/// Add new cases here when a new face type is needed.
public enum VaylCardContent: Equatable {

    /// "The Deep" portal face — bioluminescent center, tide rings, star field.
    /// Used during NamePhase and GenderPhase portal sequences.
    case portal(startDate: Date)

    /// Mode selection face — glass bar motif, title.
    /// Solo Discovery = single bar. Shared Journey = dual bars.
    case mode(title: String, subtitle: String, motif: ModeMotifStyle)

    /// Context selection face — numbered card with title, subtitle, detail.
    case context(number: String, title: String, subtitle: String, detail: String)

    /// Curiosity category face.
    case curiosity(category: String)

    /// Session prompt face.
    case session(prompt: String, highlights: [String])

    /// Founder letter face.
    case letter(name: String, body: String)

    /// Typewriter symbol face — used during NamePhase.
    /// activeKey: -1 = none, 0–14 = letter keys, 15 = space bar.
    /// carriageProgress: 0.0 (left) → 1.0 (right).
    case typewriter(activeKey: Int, carriageProgress: CGFloat)

    /// Slot machine symbol face — used during GenderPhase.
    case slotMachine

    /// Vintage radio tuner face — used during GenderPhase.
    /// signalStrength 0.0 (scanning) → 1.0 (locked). Dial progress 0.0–1.0.
    case radioTuner(signalStrength: Double, leftDialProgress: Double, rightDialProgress: Double)

    /// Solo controller card face — used for Solo Discovery mode selection.
    case controller(activeButtons: Set<Int> = [])

    /// Stacked dual-controller card face — used for Shared Journey / co-op mode selection.
    case dualController(activeButtonsFront: Set<Int> = [], activeButtonsBack: Set<Int> = [])

    /// Blank — face-up but no content assigned yet.
    case blank

    /// Experience-level candle face. `time` is the shared flame clock from the phase.
    case candle(intensity: CandleIntensity, time: Double)

    /// CompassPhase Q1/Q2 answer card — one option label per card.
    /// Revealed by the flip cascade after the 2×2 grid settles.
    case compassOption(label: String)

    /// CompassPhase Q3 register card — felt-state slider on the card face.
    /// `value` 0.0 ("I want to feel safer") → 1.0 ("I want to feel more alive").
    /// `dragging` scales the thumb while the user is actively dragging.
    /// The drag gesture itself is an overlay owned by the phase — this only draws.
    case compassSlider(value: Double, dragging: Bool)
}

/// Visual style for the glass bar motif on mode cards.
public enum ModeMotifStyle: Equatable {
    case single  // Solo Discovery — one glass bar
    case dual    // Shared Journey — two glass bars
}
