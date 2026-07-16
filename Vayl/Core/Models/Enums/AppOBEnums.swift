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
    case demo               // first card: teach tap+swipe, snapshot sentence "I [verb][noun]" → emotionalRegister → deck[1]
    case name               // table fades in, dealer types, card deals/flips, name input → deck[2]
    case modeSelect         // mirror deal, two cards, tap to lift, swipe up → deck[2]
    case gender             // slot machine drag, reel spin, card tear, drum picker → deck[3]
    case experienceLevel    // Monte deal, shuffle, flip, candle face, swipe up → deck[4]
    case context            // deal face-up, table fades, carousel, swipe up → deck[5]
    case curiosity          // tinder swipe, two rounds, dealer copy between — deck[6] full
    case confirmation       // cards fan from corner, review, edit, swipe right → build
    case buildDeck          // foil materializes, dealer types, tear to accept → letter
    case founderLetter      // sheet rises, dealer letter, signature writes, swipe down → home
}

/// The data credentials collected across all OB phases.
/// Each case maps to exactly one field on OnboardingData.
/// Used to tag VaylCardModel with what credential it carries
/// when it pockets to the corner deck.
/// The verb on the DemoPhase snapshot card — "I [need / want / desire] [noun]."
/// The verb modulates the card's tone gradient (cool → warm) and, combined with
/// the noun's keyword category, triangulates the user's EmotionalRegister
/// (see DemoDictionary).
public enum DemoVerb: String, Codable, CaseIterable, Identifiable {
    case need, want, desire

    public var id: String { rawValue }

    /// Tone position for the card gradient: need = coolest, desire = warmest.
    var toneProgress: Double {
        switch self {
        case .need:   return 0.0
        case .want:   return 0.5
        case .desire: return 1.0
        }
    }
}

/// CaseIterable allows the corner deck to verify all seven are present.
enum OBCredential: String, CaseIterable, Identifiable {
    case snapshot           // OnboardingData.demoVerb/demoNoun → emotionalRegister — deck[1]
    case name               // OnboardingData.displayName — deck[2]
    case gender             // OnboardingData.genderIdentity — deck[3]
    case mode               // OnboardingData.appMode — deck[4]
    case experienceLevel    // OnboardingData.nmStage — deck[5]
    case context            // OnboardingData.relationshipContext + situationalRegister — deck[6]
    case curiosity          // OnboardingData.curiositySelections — deck[7]

    // id is provided by the RawRepresentable+Identifiable extension (id == rawValue).

    /// Short label for the confirmation edit-sheet header.
    var displayName: String {
        switch self {
        case .snapshot:        return "Baseline"
        case .name:            return "Name"
        case .gender:          return "Gender"
        case .mode:            return "Mode"
        case .experienceLevel: return "Experience"
        case .context:         return "Context"
        case .curiosity:       return "Curiosity"
        }
    }
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
        case ".":
            // A dot continuing an ellipsis ticks, it doesn't pause —
            // "..." costs one full stop + two ticks, not three stops.
            return prev == "." ? base : base * 3.8
        case "!", "?", "…": return base * 3.8
        case ",":           return base * 2.6
        case "'":           return base * 1.3
        case " ":           return base * 1.4
        default:
            if prev == nil || prev == " " { return base * 1.1 }
            return base * Double.random(in: 0.88...1.06)
        }
    }

    // MARK: — Type duration

    /// Expected total type-out time for a line, in ms — deterministic mean of
    /// charDelay over the string (body-char variance ±10% averages to ~0.97).
    /// Phases use this to gate interactivity until the dealer has finished
    /// asking. Table must mirror charDelay above.
    static func typeDuration(_ text: String) -> Int {
        let base = 58.0
        var prev: Character?
        var total = 0.0
        for char in text {
            switch char {
            case ".":           total += prev == "." ? base : base * 3.8
            case "!", "?", "…": total += base * 3.8
            case ",":           total += base * 2.6
            case "'":           total += base * 1.3
            case " ":           total += base * 1.4
            default:
                total += (prev == nil || prev == " ") ? base * 1.1 : base * 0.97
            }
            prev = char
        }
        return Int(total)
    }

    // MARK: — Hang times

    static let hangLong: Int = 600
    static let hangMedium: Int = 500
    static let hangShort: Int = 400

    // MARK: — Shuffle transition (lines 1→2, 2→3)

    static let shuffleExitMs: Int = 250
    static let shuffleGapMs: Int = 60
    static let shuffleEnterMs: Int = 200

    static let shuffleExitAnim: Animation = .timingCurve(0.4, 0, 0.6, 1, duration: 0.25)
    static let shuffleEnterAnim: Animation = .timingCurve(0.2, 0.8, 0.3, 1, duration: 0.20)

    // MARK: — Float-away (lift-lesson prompt exit — gentler than the shuffle swap)

    /// Once the card is hovered, the "Tap the card" prompt drifts up and dissolves on a
    /// long ease-out so it floats away, rather than snapping out like the shuffle swap
    /// used between ordinary lines. Felt values — tune on device.
    static let floatAwayAnim: Animation = .easeOut(duration: 0.55)
    static let floatAwayMs: Int       = 550
    static let floatAwayDrift: CGFloat   = -48

    // MARK: — Final fade (line 3 exit after card lands)

    static let finalFadeMs: Int       = 350
    static let finalFadeAnim: Animation = .easeOut(duration: 0.35)

    // MARK: — Font

    /// PostScript name for Menlo Regular — built-in system font, no bundling required.
    static let fontName: String  = "Menlo-Regular"
    static let fontSize: CGFloat = 22

    /// The dealer's voice as a SwiftUI Font — the single source every dealer-copy
    /// renderer (ProjectedTextView and NamePhase) reads, so the typeface/size changes
    /// in exactly one place.
    static var font: Font {
        Font.custom(fontName, size: fontSize, relativeTo: .title2)
    }
}
/// Which opener deck sequence is assigned after OB data collection.
/// Evaluated silently by VaylDirector.evaluateOpenerDeckType() at the
/// end of the Curiosity sort. Never shown to the user in any form.
/// Drives card sequencing and tone in the first session deck.
enum OpenerDeckType: String, Codable, CaseIterable {
    case anxious          // newer + anxious register → reassurance-first, anticipatory
    case excited          // newer + other register → expansion-first, anticipatory
    case reflectiveCalm   // experienced + anxious register → retrospective, measured
    case reflectiveOpen   // experienced + other register → retrospective, expansive

    /// The real catalog deck forged for this opener type — the deck the BuildDeck
    /// ceremony names and Play features first. Ids must match `deck-catalog.json`;
    /// `BuildDeckPhase.welcomeDeck` loads it directly via `ContentLoader.loadDeck(id:)`.
    var welcomeDeckId: String {
        switch self {
        case .anxious:        return "opener-steady"
        case .excited:        return "opener-opening"
        case .reflectiveCalm: return "opener-return"
        case .reflectiveOpen: return "opener-wider"
        }
    }

    /// Every opener deck id — Play hides the three that aren't the user's.
    static let allWelcomeDeckIds: Set<String> = Set(allCases.map(\.welcomeDeckId))
}

// MARK: - Age Range

enum AgeRange: String, CaseIterable, Codable {
    case under25     = "under_25"
    case range25to35 = "25_35"
    case range35to45 = "35_45"
    case over45      = "over_45"

    var displayLabel: String {
        switch self {
        case .under25:     return "Under 25"
        case .range25to35: return "25–35"
        case .range35to45: return "35–45"
        case .over45:      return "45+"
        }
    }
}

// MARK: - Relationship Tenure

enum RelationshipTenure: String, CaseIterable, Codable {
    case earlyDays    = "early_days"
    case findingShape = "finding_shape"
    case shifted      = "something_shifted"
    case beenThrough  = "been_through_it"

    var stageLabel: String {
        switch self {
        case .earlyDays:    return "Still figuring each other out"
        case .findingShape: return "Finding our shape"
        case .shifted:      return "Something's shifted"
        case .beenThrough:  return "We've been through it"
        }
    }

    var timeLabel: String {
        switch self {
        case .earlyDays:    return "under 1 year"
        case .findingShape: return "1–3 years"
        case .shifted:      return "3–7 years"
        case .beenThrough:  return "7+ years"
        }
    }
}
