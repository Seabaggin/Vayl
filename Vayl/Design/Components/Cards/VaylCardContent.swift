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

    /// Curiosity category face — gimbaled compass operated by the keep/pass swipe.
    /// deflection −1.0 (full PASS) … 1.0 (full KEEP) drives the needle.
    case curiosity(category: String, deflection: Double = 0)

    /// Session prompt face.
    case session(prompt: String, highlights: [String])

    /// Founder letter face.
    case letter(name: String, body: String)

    /// Typewriter symbol face — used during NamePhase.
    /// activeKey: -1 = none, 0–14 = letter keys, 15 = space bar.
    /// carriageProgress: 0.0 (left) → 1.0 (right).
    case typewriter(activeKey: Int, carriageProgress: CGFloat)

    /// Vintage radio tuner face — used during GenderPhase.
    /// signalStrength 0.0 (scanning) → 1.0 (locked). Dial progress 0.0–1.0.
    /// scanPhase shifts sine waves as user scrolls drum pickers.
    case radioTuner(signalStrength: Double, scanPhase: Double, leftDialProgress: Double, rightDialProgress: Double)

    /// Solo controller card face — used for Solo Discovery mode selection.
    case controller(activeButtons: Set<Int> = [])

    /// Stacked dual-controller card face — used for Shared Journey / co-op mode selection.
    case dualController(activeButtonsFront: Set<Int> = [], activeButtonsBack: Set<Int> = [])

    /// Blank — face-up but no content assigned yet.
    case blank

    /// Experience-level candle face. `time` is the shared flame clock from the phase.
    case candle(intensity: CandleIntensity, time: Double)

    /// DemoPhase snapshot card — "I [verb] [noun]." sentence completion.
    /// `toneProgress` 0.0 (need, cool) → 1.0 (desire, warm) tints the face.
    /// `sealProgress` 0.0 (composing: chevron + underline visible) → 1.0 (sealed:
    /// brackets fused into a clean sentence). The verb drum and noun field are
    /// gesture overlays owned by the phase — this face only draws the sentence.
    case snapshot(verb: DemoVerb, noun: String, toneProgress: Double, sealProgress: Double)
}

/// Visual style for the glass bar motif on mode cards.
public enum ModeMotifStyle: Equatable {
    case single  // Solo Discovery — one glass bar
    case dual    // Shared Journey — two glass bars
}
