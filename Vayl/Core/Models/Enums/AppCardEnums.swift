//
//  AppCardEnums.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/22/26.
//
import Foundation
import SwiftUI

// ─────────────────────────────────────────────────────────────
// MARK: - Card System
// ─────────────────────────────────────────────────────────────

/// What kind of card this is.
/// Determines how the session renders it and what mechanic fires.
enum CardType: String, CaseIterable, Codable {

    // ── Conversation ──────────────────────────────────────────
    case prompt         // standard discussion card
    case reflect        // individual reflection before sharing

    // ── Reveal mechanics (Living Cards) ───────────────────────
    case whisper        // both type privately → simultaneous reveal
    case unspoken       // both place on spectrum → simultaneous reveal
    case mirror         // A answers for self, B guesses A's answer → reveal
    case snapshot       // one word only, both private, simultaneous reveal

    // ── Playful & generative ──────────────────────────────────
    case dare           // small physical or verbal act done together now
    case greenLight     // one partner names want, other says "tell me more"
    case whatIf         // one hypothetical, whisper mechanic underneath

    // ── Emotional temperature ─────────────────────────────────
    case appreciationInterrupt  // tonal reset after heavy cards
    case permissionCard         // statement of permission, not a question
    case bodyCheck              // locate where conversation lives physically
    case coolOff                // warm connecting card, pressure valve

    // ── Memory & time ─────────────────────────────────────────
    case timeCapsule    // sealed, returns in 30/60/90 days
    case echo           // pulls quote from earlier session as prompt
    case callback       // references a card marked not ready previously
    case beforeAfter    // same question at start and end of deck

    // ── Shared creation ───────────────────────────────────────
    case sharedCanvas   // both contribute to same artifact simultaneously
    case spectrum       // both place on same visual axis simultaneously
    case wordCloud      // both add words to shared cloud in real time

    // ── Structural & ceremonial ───────────────────────────────
    case openingRitual  // moment before card one
    case closingRitual  // final card — each deck gets its own, never reused
    case pause          // designed silence, no prompt
}

/// Emotional intensity of a card or deck.
/// 8 levels — void is entry, supernova is most intense.
/// Int rawValue enables sorting and range checks.
/// Visual properties live in AppColors.swift as an extension.
enum CardIntensity: Int, CaseIterable, Identifiable, Codable, Comparable {
    case void        = 1
    case deepOcean   = 2
    case emberFloor  = 3
    case split       = 4
    case nebula      = 5
    case auroraBand  = 6
    case deepSpace   = 7
    case supernova   = 8

    var id: Int { rawValue }

    static func < (lhs: CardIntensity, rhs: CardIntensity) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var displayName: String {
        switch self {
        case .void:        return "Void"
        case .deepOcean:   return "Deep Ocean"
        case .emberFloor:  return "Ember Floor"
        case .split:       return "Split"
        case .nebula:      return "Nebula"
        case .auroraBand:  return "Aurora Band"
        case .deepSpace:   return "Deep Space"
        case .supernova:   return "Supernova"
        }
    }

    var difficultyLabel: String {
        switch self {
        case .void, .deepOcean:         return "Easy"
        case .emberFloor, .split:       return "Medium"
        case .nebula, .auroraBand:      return "Deep"
        case .deepSpace:                return "Sensitive"
        case .supernova:                return "Ultimate"
        }
    }

    /// Maps a string difficulty label from JSON content to an intensity level.
    static func from(difficulty: String) -> CardIntensity {
        switch difficulty.lowercased() {
        case "easy":      return .void
        case "light":     return .deepOcean
        case "medium":    return .split
        case "deep":      return .nebula
        case "sensitive": return .deepSpace
        case "ultimate":  return .supernova
        default:          return .deepOcean
        }
    }

    /// Maps a numeric score to an intensity level.
    static func from(score: Int) -> CardIntensity {
        switch score {
        case 1...2:  return .void
        case 3:      return .deepOcean
        case 4:      return .emberFloor
        case 5:      return .split
        case 6:      return .nebula
        case 7:      return .auroraBand
        case 8:      return .deepSpace
        case 9...10: return .supernova
        default:     return .deepOcean
        }
    }
}

/// Per-card result status tracked in CardResult.
enum CardStatus: String, CaseIterable, Codable {
    case discussed
    case skipped
    case bookmarked

    var displayName: String {
        switch self {
        case .discussed:  return "Discussed"
        case .skipped:    return "Skipped"
        case .bookmarked: return "Bookmarked"
        }
    }
}

/// Who initiates a card — which partner goes first, or both together.
/// Replaces TurnOrder. Adds solo for prep deck cards.
enum WhoStarts: String, CaseIterable, Codable {
    case partnerA
    case partnerB
    case both
    case solo       // solo prep deck cards only

    var displayName: String {
        switch self {
        case .partnerA: return "Partner A"
        case .partnerB: return "Partner B"
        case .both:     return "Together"
        case .solo:     return "Solo"
        }
    }
}

/// Which gender dynamic a gendered card is written for.
/// nil on non-gendered cards.
enum GenderDynamic: String, CaseIterable, Codable {
    case mf
    case mm
    case ff
    case flexible

    var displayName: String {
        switch self {
        case .mf:       return "Man + Woman"
        case .mm:       return "Man + Man"
        case .ff:       return "Woman + Woman"
        case .flexible: return "Flexible"
        }
    }

    /// Spec §9 derivation. Inputs are the raw GenderPhase drum strings
    /// ("Man" / "Woman" / "Trans Man" / "Trans Woman" / "Non-binary") or nil
    /// when a partner declined the drum. Returns the composition to PROPOSE
    /// (one-tap confirm at link completion), or nil when either answer is
    /// missing or non-binary — the caller then defaults .flexible silently.
    /// Trans men count as men and trans women as women for card-wording
    /// purposes; this maps what each person SAID, it never infers anything.
    /// Symmetric: proposal(a, b) == proposal(b, a).
    static func proposal(myGender: String?, partnerGender: String?) -> GenderDynamic? {
        func binaryAxis(_ raw: String?) -> Character? {
            switch raw?.trimmingCharacters(in: .whitespaces).lowercased() {
            case "man", "trans man":     return "m"
            case "woman", "trans woman": return "w"
            default:                     return nil   // Non-binary, declined, unknown
            }
        }
        guard let mine = binaryAxis(myGender),
              let theirs = binaryAxis(partnerGender) else { return nil }
        switch (mine, theirs) {
        case ("m", "m"): return .mm
        case ("w", "w"): return .ff
        default:         return .mf
        }
    }
}

/// Context beat type.
/// Banner is a short (1-2 line) kicker shown persistently above the card
/// while it's current (ContextKickerView) — it does NOT precede the card or
/// auto-dismiss.
/// Interstitial is full screen, appears BEFORE the card, user dismisses it.
enum ContextBeatType: String, Codable {
    case banner         // 1-2 lines, persistent header above the card (ContextKickerView)
    case interstitial   // full screen, before the card, user controls dismissal
}

// ─────────────────────────────────────────────────────────────
// MARK: - Experience Level / Candle Intensity
// ─────────────────────────────────────────────────────────────

/// Experience-level candle states. Render-layer enum (decoupled from the
/// domain `NMStage`); maps 1:1 onto it for selection.
public enum CandleIntensity: String, CaseIterable, Equatable {
    case curious, exploring, experienced

    /// Left → right row order.
    static var ordered: [CandleIntensity] { [.curious, .exploring, .experienced] }

    var nmStage: NMStage {
        switch self {
        case .curious:     return .curious
        case .exploring:   return .exploring
        case .experienced: return .experienced
        }
    }

    var displayName: String {
        switch self {
        case .curious:     return "Curious"
        case .exploring:   return "Exploring"
        case .experienced: return "Experienced"
        }
    }
}

// ─────────────────────────────────────────────────────────────
// MARK: - Deck System
// ─────────────────────────────────────────────────────────────

/// Which category a deck belongs to.
/// Drives library organization and deck recommendations.
enum DeckCategory: String, CaseIterable, Codable {
    case foundationEntry        // The Opener, The Bridge, The Check-In
    case relationshipCore       // Communication, Sex, Trust, Resentment
    case nmSpecific             // Jealousy, Flavors, Desire Map Conversations
    case styleSpecific          // Swinging, Poly, Open, Monogamish
    case experienceArc          // Before Tonight, After Last Night, First Time
    case identityDynamics       // Gender Dynamic, Autonomy, Desire & Identity
    case advancedExperienced    // Audit, Unfinished Business, NRE
    case soloPrep               // 5-card solo prep deck — unlinked users only
    case wildcard               // Right Now, Hypothetical, Appreciation, Body
    case multiPerson            // Network, Metamour — requires $7.99 connection

    var displayName: String {
        switch self {
        case .foundationEntry:     return "Foundation"
        case .relationshipCore:    return "Relationship Core"
        case .nmSpecific:          return "NM Specific"
        case .styleSpecific:       return "Style"
        case .experienceArc:       return "Experience Arc"
        case .identityDynamics:    return "Identity & Dynamics"
        case .advancedExperienced: return "Advanced"
        case .soloPrep:            return "Solo Prep"
        case .wildcard:            return "Wildcard"
        case .multiPerson:         return "Multi-Person"
        }
    }
}
