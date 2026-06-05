//
//  AppOBEnums.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/22/26.
//
import Foundation
import SwiftUI

// ─────────────────────────────────────────────────────────────
// MARK: - OB Canvas
//
// These enums are exclusive to the Onboarding canvas system.
// They must never be referenced in main-app features.
// VaylDirector is the only thing that reads and writes OBPhase.
// Phase overlays read director.phase — they never hold it.
// ─────────────────────────────────────────────────────────────


/// The complete sequence of phases in the Onboarding canvas.
/// VaylDirector advances through these in order.
/// No phase may be skipped — each has a gate condition.
/// stat has no overlay — the canvas itself is the content.
enum OBPhase: CaseIterable {
    case stat               // "1 in 5", dealer copy, CTA → table world
    case name               // table fades in, dealer types, card deals/flips, name input → deck[1]
    case modeSelect         // mirror deal, two cards, tap to lift, swipe up → deck[2]
    case gender             // slot machine drag, reel spin, card tear, drum picker → deck[3]
    case experienceLevel    // Monte deal, shuffle, flip, candle face, swipe up → deck[4]
    case context            // deal face-up, table fades, carousel, swipe up → deck[5]
    case compass            // three-question calibration (agency/motivation/register) — no deck card
    case curiosity          // tinder swipe, two rounds, dealer copy between — deck[6] full
    case confirmation       // cards fan from corner, review, edit, swipe right → build
    case buildDeck          // foil materializes, dealer types, tear to accept → letter
    case founderLetter      // sheet rises, dealer letter, signature writes, swipe down → home
}

/// The data credentials collected across all OB phases.
/// Each case maps to exactly one field on OnboardingData.
/// Used to tag VaylCardModel with what credential it carries
/// when it pockets to the corner deck.
/// CaseIterable allows the corner deck to verify all six are present.
enum OBCredential: String, CaseIterable {
    case name               // OnboardingData.displayName — deck[1]
    case gender             // OnboardingData.genderIdentity — deck[2]
    case mode               // OnboardingData.appMode — deck[3]
    case experienceLevel    // OnboardingData.nmStage — deck[4]
    case context            // OnboardingData.relationshipContext + situationalRegister — deck[5]
    case curiosity          // OnboardingData.curiositySelections — deck[6]
}
// MARK: - Dealer Typing
//
// Deliberate typing model for all OB dealer copy.
// Pure math. No state. No dependencies.
// Each phase owns its own rendering and copy strings.
// This is the shared timing contract only.
//
// Deliberate model:
//   baseMs:      58ms flat
//   period/!/?:  3.8× — full stop lands
//   comma:       2.6× — breath
//   apostrophe:  1.3× — catch
//   space:       1.4× — word boundary
//   first char:  1.1× — dealer finds the key
//   variance:    ±10% on body chars
//
// Transition model:
//   Lines 1→2, 2→3: medium shuffle
//     exit:  400ms cubic-bezier(0.4, 0, 0.6, 1) — slide up + fade
//     gap:   120ms — dealer's hand moving
//     enter: 350ms cubic-bezier(0.2, 0.8, 0.3, 1) — drops in with weight
//   Final line exit: 600ms ease-out fade — nothing follows
//
// Hang times per line length:
//   Line 1 — long:   1000ms
//   Line 2 — medium:  800ms
//   Line 3 — short:   600ms
//
// Never reference outside the Onboarding canvas.

internal enum AppDealerTyping {

    // MARK: — Character delay

    static func charDelay(_ char: Character, prev: Character?) -> Double {
        let base = 58.0
        switch char {
        case ".", "!", "?": return base * 3.8
        case ",":           return base * 2.6
        case "'":           return base * 1.3
        case " ":           return base * 1.4
        default:
            if prev == nil || prev == " " { return base * 1.1 }
            return base * Double.random(in: 0.88...1.06)
        }
    }

    // MARK: — Hang times

    static let hangLong:   Int = 600
    static let hangMedium: Int = 500
    static let hangShort:  Int = 400

    // MARK: — Shuffle transition (lines 1→2, 2→3)

    static let shuffleExitMs:  Int = 250
    static let shuffleGapMs:   Int = 60
    static let shuffleEnterMs: Int = 200

    static let shuffleExitAnim:  Animation = .timingCurve(0.4, 0, 0.6, 1, duration: 0.25)
    static let shuffleEnterAnim: Animation = .timingCurve(0.2, 0.8, 0.3, 1, duration: 0.20)

    // MARK: — Final fade (line 3 exit after card lands)

    static let finalFadeMs:   Int       = 350
    static let finalFadeAnim: Animation = .easeOut(duration: 0.35)

    // MARK: — Font

    /// PostScript name for Volkhov Italic — confirmed via TTF name table.
    static let fontName: String  = "Volkhov-Italic"
    static let fontSize: CGFloat = 22
}
/// Which opener deck sequence is assigned after OB data collection.
/// Evaluated silently by VaylDirector.evaluateOpenerDeckType() at the
/// end of CuriosityPhase round 2. Never shown to the user in any form.
/// Drives card sequencing and tone in the first session deck.
enum OpenerDeckType: String, Codable {
    case anxious    // lower stakes, builds safety first — emotionalRegister == anxious + fewer curiosity selections
    case excited    // goes deeper faster — all other signal combinations
}
