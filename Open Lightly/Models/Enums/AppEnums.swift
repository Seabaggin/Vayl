//
//  AppEnums.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import Foundation
import SwiftUI

// Provide a default Identifiable.id for String-backed RawRepresentable types.
// This lives at the top so each enum can simply declare Identifiable and
// inherit a sensible id automatically (the raw string value).
extension RawRepresentable where Self: Identifiable, RawValue == String {
    var id: String { rawValue }
}

// ============================================================
// AppEnums.swift
// Shared enums used across every model and screen.
//
// WHY ENUMS?
// An enum is a type that can only be one of a fixed set of values.
// This prevents bugs like misspelling "easyy" as a difficulty
// because the compiler forces you to use .easy, .medium, or .deep.
//
// WHY CaseIterable?
// Lets you loop over all cases: Difficulty.allCases gives you
// [.easy, .medium, .deep]. Useful for building UI pickers.
//
// WHY Codable?
// Lets Swift automatically convert these to/from JSON.
// Needed when saving to device or syncing with Supabase.
//
// WHY String raw values?
// Each case stores a string like "easy" or "medium".
// This is what actually gets saved to JSON or a database.
// Without it, Swift would just store an integer index,
// which breaks if you reorder cases later.
// ============================================================


// MARK: - CategoryPhase
// The therapeutic stage a category belongs to.
// Categories are ordered to mirror clinical pacing:
// stabilize the foundation before exploring, explore
// before planning logistics.

enum CategoryPhase: String, CaseIterable, Identifiable, Codable {
    case foundation   // Categories 1-2: communication, security
    case exploration  // Categories 3-4: sexuality, compatibility
    case framework    // Category 5: boundaries and agreements
    case planning     // Category 6: logistics (unlocked last)

    var displayName: String {
        switch self {
        case .foundation:  return "Foundation"
        case .exploration: return "Exploration"
        case .framework:   return "Framework"
        case .planning:    return "Planning"
        }
    }

    var color: Color {
        switch self {
        case .foundation:  return .blue
        case .exploration: return .purple
        case .framework:   return .orange
        case .planning:    return .green
        }
    }
}


// MARK: - CategoryType
// The 6 topic buckets that cards are grouped into.
// These match the spec exactly — 6 categories in therapeutic order.
// See PROJECT_SCOPE.md Section 8.2 for clinical rationale.
//
// ORDER MATTERS: sortOrder is used by the session system to
// recommend which category to tackle next. NM Logistics is
// always last and requires 2+ categories completed to unlock.

enum CategoryType: String, CaseIterable, Identifiable, Codable {
    case relationshipHealth  // Foundation — communication, conflict, intimacy
    case insecurities        // Foundation — fears, attachment, jealousy, compersion
    case sexualSatisfaction  // Exploration — desires, fantasies, satisfaction
    case compatibility       // Exploration — ENM style, hierarchy, time, vision
    case boundaries          // Framework — hard/soft limits, veto, renegotiation
    case nmLogistics         // Planning — scheduling, safer sex, finances, social media

    // Human-readable name for headers and labels
    var displayName: String {
        switch self {
        case .relationshipHealth: return "Relationship Health"
        case .insecurities:       return "Insecurities & Jealousy"
        case .sexualSatisfaction: return "Sexual Satisfaction"
        case .compatibility:      return "Compatibility & Vision"
        case .boundaries:         return "Boundaries & Agreements"
        case .nmLogistics:        return "NM Logistics"
        }
    }

    // Card ID prefix used in JSON content files (e.g. "RH-1", "IJ-3")
    var cardPrefix: String {
        switch self {
        case .relationshipHealth: return "RH"
        case .insecurities:       return "IJ"
        case .sexualSatisfaction: return "SS"
        case .compatibility:      return "CV"
        case .boundaries:         return "BA"
        case .nmLogistics:        return "NL"
        }
    }

    // SF Symbol icon for category headers and list items
    var icon: String {
        switch self {
        case .relationshipHealth: return "heart.fill"
        case .insecurities:       return "shield.fill"
        case .sexualSatisfaction: return "flame.fill"
        case .compatibility:      return "chart.bar.fill"
        case .boundaries:         return "lock.fill"
        case .nmLogistics:        return "list.bullet.clipboard.fill"
        }
    }

    // Which therapeutic phase this category belongs to
    var phase: CategoryPhase {
        switch self {
        case .relationshipHealth: return .foundation
        case .insecurities:       return .foundation
        case .sexualSatisfaction: return .exploration
        case .compatibility:      return .exploration
        case .boundaries:         return .framework
        case .nmLogistics:        return .planning
        }
    }

    // Position in the recommended order (1-indexed, matches spec)
    var sortOrder: Int {
        switch self {
        case .relationshipHealth: return 1
        case .insecurities:       return 2
        case .sexualSatisfaction: return 3
        case .compatibility:      return 4
        case .boundaries:         return 5
        case .nmLogistics:        return 6
        }
    }

    // NM Logistics requires 2+ other categories completed before unlocking.
    // All other categories are available from the start.
    var requiresUnlock: Bool {
        self == .nmLogistics
    }
}


// MARK: - CardType
// What kind of card this is — determines how the session
// renders the card and whether it has a discussion prompt.
//
//   prompt         — partners take turns sharing, discussion required
//   education      — informational content, no prompt
//   educationPrompt — info block followed by a discussion prompt
//   coolOff        — grounding exercise auto-inserted after heavy cards

enum CardType: String, CaseIterable, Identifiable, Codable {
    case prompt
    case education
    case educationPrompt
    case coolOff

    var displayName: String {
        switch self {
        case .prompt:           return "Prompt"
        case .education:        return "Education"
        case .educationPrompt:  return "Education + Prompt"
        case .coolOff:          return "Cool-off"
        }
    }
}


// MARK: - CardStatus
// Per-card state tracked for each couple's session history.
// A card lives in exactly one state at any given time.

enum CardStatus: String, CaseIterable, Identifiable, Codable {
    case notStarted  // Never shown to this couple
    case discussed   // Partners marked "We've Discussed"
    case skipped     // Partners tapped "Not ready"
    case bookmarked  // Flagged to revisit

    var displayName: String {
        switch self {
        case .notStarted: return "Not Started"
        case .discussed:  return "Discussed"
        case .skipped:    return "Skipped"
        case .bookmarked: return "Bookmarked"
        }
    }
}


// MARK: - Difficulty
// How emotionally intense a conversation card is.
// Screens use this to show a label and sort cards by depth.
// (Not in spec — kept as a useful concrete enum for content authors.)

enum Difficulty: String, CaseIterable, Identifiable, Codable {
    case easy    // light warmup prompts
    case medium  // requires some vulnerability
    case deep    // emotionally intense, may trigger safe word

    var displayName: String {
        switch self {
        case .easy:   return "Easy"
        case .medium: return "Medium"
        case .deep:   return "Deep"
        }
    }

    var color: Color {
        switch self {
        case .easy:   return .green
        case .medium: return .orange
        case .deep:   return .red
        }
    }
}


// MARK: - Sensitivity
// How sensitive a card's content is — determines whether
// screenshot protection activates on this card.
// Separate from Difficulty: a card can be emotionally easy
// but still sensitive (e.g. a kink-related education card).

enum Sensitivity: String, CaseIterable, Identifiable, Codable {
    case low
    case medium
    case high

    var displayName: String {
        switch self {
        case .low:    return "Low"
        case .medium: return "Medium"
        case .high:   return "High"
        }
    }
}


// MARK: - DesireLevel
// How a partner feels about a kink/boundary item.
// Used on the Desire Map screen — each partner picks one per item.
//
// PRIVACY: Hard No ratings are NEVER revealed to the partner.
// The matching logic returns nil for any hard-no combination.
// See ContentDesireItem.computeAlignment for implementation.

enum DesireLevel: Int, Codable, CaseIterable {
    case notForMe = 1
    case probablyNot = 2
    case openToIt = 3
    case excitedAboutIt = 4
    
    var displayLabel: String {
        switch self {
        case .notForMe:       return "Not For Me"
        case .probablyNot:    return "Probably Not"
        case .openToIt:       return "Open To It"
        case .excitedAboutIt: return "Excited About It"
        }
    }
    
    var color: String {
        switch self {
        case .notForMe:       return "red"
        case .probablyNot:    return "orange"
        case .openToIt:       return "green"
        case .excitedAboutIt: return "darkGreen"
        }
    }
}


// MARK: - AlignmentLevel
// The result of comparing two partners' kink ratings.
// Only positive matches (mutualYes, exploreZone, worthDiscussing) are stored.
// Hard No combinations are NEVER stored or revealed.
// See PROJECT_SCOPE.md Section 10 for the matching matrix.

enum AlignmentLevel: String, Codable, CaseIterable {
    case strongAlignment
    case aligned
    case talkAboutIt
    case boundary
    case mutualPass
    
    var displayLabel: String {
        switch self {
        case .strongAlignment: return "Strong Alignment"
        case .aligned:         return "Aligned"
        case .talkAboutIt:     return "Talk About It"
        case .boundary:        return "Boundary Respected"
        case .mutualPass:      return "Mutual Pass"
        }
    }
    
    var emoji: String {
        switch self {
        case .strongAlignment: return "🔥"
        case .aligned:         return "💚"
        case .talkAboutIt:     return "💛"
        case .boundary:        return "🔒"
        case .mutualPass:      return "⬜"
        }
    }
}


// MARK: - SessionStatus
// Tracks where a session is in its lifecycle.
// paused is used by the safe word — session suspends but
// is not complete, and can be resumed.

enum SessionStatus: String, CaseIterable, Identifiable, Codable {
    case notStarted
    case inProgress
    case paused     // triggered by safe word; resumes to inProgress
    case completed

    var displayName: String {
        switch self {
        case .notStarted: return "Not Started"
        case .inProgress: return "In Progress"
        case .paused:     return "Paused"
        case .completed:  return "Completed"
        }
    }
}


// MARK: - TurnOrder
// Who speaks first on a given card.
// Alternating turns prevents one partner from dominating.
// "together" is used on lighter prompts where simultaneous
// discussion is more natural than taking turns.

enum TurnOrder: String, CaseIterable, Identifiable, Codable {
    case partnerA  // partner A shares first, B listens
    case partnerB  // partner B shares first, A listens
    // NOTE: Not yet used in card JSON content. Cards only specify "A" or "B".
    // Added for future use. Ensure ContentLoader handles missing case gracefully.
    case together  // both discuss simultaneously

    var displayName: String {
        switch self {
        case .partnerA: return "Partner A"
        case .partnerB: return "Partner B"
        case .together: return "Together"
        }
    }
}


// MARK: - PartnerLabel
// Identifies which person in a couple owns a piece of data.
// Each partner gets a label when the couple links.
// Used on AssessmentResponse, DesireRating, and any other
// per-person data that needs to be attributed.
//
// This is NOT the same as TurnOrder — TurnOrder describes
// who speaks first on a card. PartnerLabel identifies whose
// data this is in the database.

enum PartnerLabel: String, CaseIterable, Identifiable, Codable {
    case partnerA
    case partnerB

    var displayName: String {
        switch self {
        case .partnerA: return "Partner A"
        case .partnerB: return "Partner B"
        }
    }

    var opposite: PartnerLabel {
        switch self {
        case .partnerA: return .partnerB
        case .partnerB: return .partnerA
        }
    }
}


// MARK: - ReadinessLevel
// The five result bands for the couple's overall readiness score.
// Assigned after scoring the 5-domain assessment.
// See PROJECT_SCOPE.md Section 10 for score ranges.

enum ReadinessLevel: String, CaseIterable, Identifiable, Codable {
    case thriving            // 85-100
    case ready               // 70-84
    case someGaps            // 50-69
    case significantConcerns // 35-49
    case notReady            // 0-34

    var displayName: String {
        switch self {
        case .thriving:            return "Thriving Foundation"
        case .ready:               return "Ready with Awareness"
        case .someGaps:            return "Some Gaps to Address"
        case .significantConcerns: return "Significant Concerns"
        case .notReady:            return "Not Ready — Foundation Work Needed"
        }
    }

    // Score range for this level
    var scoreRange: ClosedRange<Int> {
        switch self {
        case .thriving:            return 85...100
        case .ready:               return 70...84
        case .someGaps:            return 50...69
        case .significantConcerns: return 35...49
        case .notReady:            return 0...34
        }
    }

    var color: Color {
        switch self {
        case .thriving:            return .green
        case .ready:               return .blue
        case .someGaps:            return .yellow
        case .significantConcerns: return .orange
        case .notReady:            return .red
        }
    }

    static func level(for score: Int) -> ReadinessLevel {
        let clamped = max(0, min(100, score))
        return allCases.first { $0.scoreRange.contains(clamped) } ?? .notReady
    }
}


// MARK: - AssessmentDomain
// The 5 scored domains in the individual assessment.
// Each domain has 4 questions (20 total across the assessment).
// Domain weights for overall score: Communication 25%, Trust 25%,
// Emotional Security 20%, Sexual Openness 15%, Boundary Awareness 15%.

enum AssessmentDomain: String, CaseIterable, Identifiable, Codable {
    case communication      // weight: 0.25
    case trust              // weight: 0.25
    case emotionalSecurity  // weight: 0.20
    case sexualOpenness     // weight: 0.15
    case boundaryAwareness  // weight: 0.15

    var displayName: String {
        switch self {
        case .communication:     return "Communication"
        case .trust:             return "Trust"
        case .emotionalSecurity: return "Emotional Security"
        case .sexualOpenness:    return "Sexual Openness"
        case .boundaryAwareness: return "Boundary Awareness"
        }
    }

    var weight: Double {
        switch self {
        case .communication:     return 0.25
        case .trust:             return 0.25
        case .emotionalSecurity: return 0.20
        case .sexualOpenness:    return 0.15
        case .boundaryAwareness: return 0.15
        }
    }
}


// MARK: - AssessmentQuestionType
// The input type for an assessment question.
// Scale = 5-point Likert. Multi-select = pick all that apply.
// See PROJECT_SCOPE.md Section 8.1 for question format.

enum AssessmentQuestionType: String, CaseIterable, Identifiable, Codable {
    case scale
    case multiSelect = "multi_select"

    var displayName: String {
        switch self {
        case .scale:       return "Scale (1-5)"
        case .multiSelect: return "Multi-Select"
        }
    }
}


// MARK: - PurchaseTier
// The three entitlement levels.
// Free: assessment + score + 3-5 sample cards + 5 kink items
// Core: full card library (30-40 cards, 5 categories), sessions, notes
// Complete: everything + full Desire Map (40+ items) + NM Logistics + cool-off cards

enum PurchaseTier: String, CaseIterable, Identifiable, Codable {
    case free
    case core
    case complete

    var displayName: String {
        switch self {
        case .free:     return "Free"
        case .core:     return "Core"
        case .complete: return "Complete"
        }
    }

    // Whether this tier includes access to a given category
    func includesCategory(_ category: CategoryType) -> Bool {
        switch self {
        case .free:
            // Free only gets sample content — no full category access
            return false
        case .core:
            // Core includes all categories except NM Logistics
            return category != .nmLogistics
        case .complete:
            // Complete includes everything
            return true
        }
    }
}


// MARK: - NMFlavor
// Which style of ethical non-monogamy the couple is interested in.
// Collected during onboarding or compatibility assessment.
// "unsure" is always a valid answer — the app doesn't require certainty.

enum NMFlavor: String, CaseIterable, Identifiable, Codable {
    case swinging
    case openRelationship
    case polyamory
    case relationshipAnarchy
    case monogamish
    case unsure

    var displayName: String {
        switch self {
        case .swinging:            return "Swinging"
        case .openRelationship:    return "Open Relationship"
        case .polyamory:           return "Polyamory"
        case .relationshipAnarchy: return "Relationship Anarchy"
        case .monogamish:          return "Monogamish"
        case .unsure:              return "Not Sure Yet"
        }
    }
}
