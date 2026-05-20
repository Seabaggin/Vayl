//
//  VaylCardContent.swift
//  Vayl
//
//  Created by Claude Code Agent.
//
//  Design/Components/Cards/VaylCardFace/VaylCardContent.swift
//
//  Public enum describing what content lives on a VaylCardFace.
//  VaylCardFace switches on this. No other file should switch on this directly.
//  Director writes VaylCardContent onto VaylCardModel. Renderer reads it and passes it to VaylCardFace.
//

import SwiftUI

/// Describes the content type of a VaylCardFace.
/// Add new cases here when a new card face type is needed.
/// Each case maps to a private content view inside the VaylCardFace folder.
public enum VaylCardContent: Equatable {

    /// "The Deep" portal face — bioluminescent center, tide rings, star field.
    /// Used during NamePhase and GenderPhase portal sequences.
    /// startDate drives the continuous elapsed-time animation via TimelineView.
    case portal(startDate: Date)

    /// Mode selection face — title, subtitle, orbit style.
    /// Used in ModeSelectPhase for Solo Discovery and Shared Journey cards.
    case mode(title: String, subtitle: String, orbit: OrbitStyle)

    /// Context selection face — numbered card with title, subtitle, detail copy.
    /// Used in ContextPhase for the thrown context cards.
    case context(number: String, title: String, subtitle: String, detail: String)

    /// Curiosity category face — category label.
    /// Used in CuriosityPhase for the spread cards.
    case curiosity(category: String)

    /// Session prompt face — prompt text with highlighted keywords.
    /// Used in post-OB session card play.
    case session(prompt: String, highlights: [String])

    /// Founder letter face — personalised letter with name and body.
    /// Used in FounderLetterPhase.
    case letter(name: String, body: String)

    /// Blank face — card is face-up but shows no content.
    /// Used during transitions where the face is visible but content has not yet been assigned.
    case blank
}

/// Orbit animation style for mode cards.
/// Controls how many orbit rings are rendered and their density.
public enum OrbitStyle: Equatable {
    case single     // Solo Discovery — one tight orbit
    case dual       // Shared Journey — two orbits, slightly offset
    case scattered  // Just Looking — three orbits, loose
}
