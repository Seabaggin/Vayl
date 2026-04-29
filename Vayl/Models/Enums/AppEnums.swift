//
//  AppEnums.swift
//  Vayl
//

import Foundation
import SwiftUI

// MARK: - Identifiable default for String-backed enums
// Any String RawRepresentable that declares Identifiable
// gets its rawValue as id automatically.

extension RawRepresentable where Self: Identifiable, RawValue == String {
    var id: String { rawValue }
}

// ─────────────────────────────────────────────────────────────
// MARK: - Onboarding & Routing
// ─────────────────────────────────────────────────────────────

/// Where this person is in their NM journey.
/// Collected during onboarding. Lives on UserProfile permanently.
/// Drives deck difficulty defaults and content routing.
enum NMStage: String, CaseIterable, Codable {
    case curious        // new to the concept, still exploring
    case exploring      // in it, early days
    case experienced    // been doing this, wants to go deeper

    var displayName: String {
        switch self {
        case .curious:    return "Just Curious"
        case .exploring:  return "Exploring"
        case .experienced: return "Experienced"
        }
    }

    /// Default card difficulty for this stage.
    /// Drives deck recommendations and content sequencing.
    var defaultDifficulty: CardIntensity {
        switch self {
        case .curious:    return .deepOcean
        case .exploring:  return .split
        case .experienced: return .nebula
        }
    }
}

/// The mode the user selected in ModeSelectView.
/// Drives onboarding path, tab structure, and content routing.
/// Mutable — user can switch between together and solo in Settings.
/// browsing users cannot switch to together/solo without completing full onboarding.
enum AppMode: String, CaseIterable, Codable {
    case together   // both partners talked, doing this as a couple
    case solo       // in a relationship, conversation hasn't happened yet
    case browsing   // just looking, two-tab experience

    var displayName: String {
        switch self {
        case .together: return "Shared Journey"
        case .solo:     return "Solo Discovery"
        case .browsing: return "Safe Learning"
        }
    }
}

/// Whether this user has linked a partner.
/// Derived from Couple record — never stored independently.
/// Controls content visibility and home state rendering.
enum LinkState: String, Codable {
    case unlinked   // onboarding complete, no partner linked yet
    case linked     // partner connected, full access unlocked
}

/// Pronoun options for profile display.
enum PronounOption: String, CaseIterable, Identifiable, Hashable {
    case sheHer   = "she/her"
    case heHim    = "he/him"
    case theyThem = "they/them"

    var id: String { rawValue }
}

/// How this user experiences emotional content.
/// Collected during onboarding. Lives on UserProfile.
/// User-adjustable in Settings at any time.
enum EmotionalRegister: String, CaseIterable, Codable {
    case anxious    // reassurance-first, safety-focused
    case excited    // expansion-first, pleasure-focused
    case flexible   // calibrated blend — default

    var displayName: String {
        switch self {
        case .anxious:  return "Thoughtful"
        case .excited:  return "Expansive"
        case .flexible: return "Flexible"
        }
    }
}

/// Internal routing tag. Never shown to the user in any form.
/// Derived from onboarding signals. Drives card sequencing
/// and deck recommendations. Invisible infrastructure only.
enum ArchetypeTag: String, Codable {
    case curious
    case anxious
    case thrilled
    case wanting
    case goingAlong
    case processing
    case stuck
    case communicator
    case builder
}

// ─────────────────────────────────────────────────────────────
// MARK: - Home State
// ─────────────────────────────────────────────────────────────

/// State of the partner chip on the home dashboard.
/// Computed by HomeEventEngine from AppMode +
/// LinkState + onboardingCompletedAt.
/// Never stored directly — always derived on render.
enum PartnerChipState {
    case none                                   // solo context, no partner expected yet
    case invitePending                          // together, unlinked, under 3-5 days
    case nudge                                  // together, unlinked, 3-5+ days — show nudge
    case active(name: String, initial: String)  // one linked partner
    case multipleActive(partners: [(String, String)], selected: String?) // multiple active connections
}

extension PartnerChipState: Equatable {
    static func == (lhs: PartnerChipState, rhs: PartnerChipState) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none),
             (.invitePending, .invitePending),
             (.nudge, .nudge):
            return true
        case (.active(let a, let b), .active(let c, let d)):
            return a == c && b == d
        case (.multipleActive(let a, let b), .multipleActive(let c, let d)):
            return a.map(\.0) == c.map(\.0) && b == d
        default:
            return false
        }
    }
}

/// State of the Desire Map indicator on the home dashboard.
/// Computed by HomeEventEngine. Never stored directly.
enum DesireMapState {
    case hidden                                             // partner not yet linked
    case gated                                              // linked but neither has started
    case yourTurn                                           // this user has not completed
    case youDone(partnerName: String)                       // this user done, partner not yet
    case waiting                                            // generic waiting state
    case bothReady                                          // both complete, reveal not triggered
    case freeRevealSeen(matchCount: Int)                    // free reveal viewed
    case matchReady                                         // paywall cleared, ready to show
    case redoInProgress(partnerName: String, matchCount: Int) // redo underway
    case revealed                                           // full reveal complete
    case fullyUnlocked                                      // all access granted
}

extension DesireMapState: Equatable {
    static func == (lhs: DesireMapState, rhs: DesireMapState) -> Bool {
        switch (lhs, rhs) {
        case (.hidden, .hidden),
             (.gated, .gated),
             (.yourTurn, .yourTurn),
             (.waiting, .waiting),
             (.bothReady, .bothReady),
             (.matchReady, .matchReady),
             (.revealed, .revealed),
             (.fullyUnlocked, .fullyUnlocked):
            return true
        case (.youDone(let a), .youDone(let b)):
            return a == b
        case (.freeRevealSeen(let a), .freeRevealSeen(let b)):
            return a == b
        case (.redoInProgress(let a, let b), .redoInProgress(let c, let d)):
            return a == c && b == d
        default:
            return false
        }
    }
}

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
}

/// Pre-card context beat type.
/// Banner is brief and auto-dismisses.
/// Interstitial is full screen and user-controlled.
/// Both appear before the card arrives — never on it.
enum ContextBeatType: String, Codable {
    case banner         // 1-2 lines, auto-dismiss 5 seconds, card dimmed behind
    case interstitial   // full screen, user controls dismissal
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

// ─────────────────────────────────────────────────────────────
// MARK: - Desire Map
// ─────────────────────────────────────────────────────────────

/// How a partner rates a Desire Map item.
/// notForUs NEVER leaves the device under any circumstances.
/// Three enforcement layers — all three must hold simultaneously:
///   1. Swift: notForUs never included in any Supabase write payload
///   2. Edge Function: filters before writing to desire_matches table
///   3. Supabase RLS: partner cannot query desire_map_entries at all
enum DesireRatingValue: String, CaseIterable, Codable {
    case yes
    case curious
    case notForUs   // NEVER leaves device — three layer enforcement above

    var displayName: String {
        switch self {
        case .yes:      return "Yes"
        case .curious:  return "Curious"
        case .notForUs: return "Not For Us"
        }
    }
}

/// The type of match computed by the Edge Function.
/// Only positive matches are ever stored.
/// notForUs combinations are never written to desire_matches.
enum DesireMatchType: String, CaseIterable, Codable {
    case mutual     // both rated yes
    case adjacent   // one yes, one curious

    var displayName: String {
        switch self {
        case .mutual:   return "Mutual"
        case .adjacent: return "Worth Exploring"
        }
    }
}

// ─────────────────────────────────────────────────────────────
// MARK: - Pulse
// ─────────────────────────────────────────────────────────────

/// What created a pulse entry.
/// All three sources write to the same PulseEntry store.
enum PulseSource: String, CaseIterable, Codable {
    case manual
    case lockIn
    case postSession

    var displayName: String {
        switch self {
        case .manual:      return "Manual"
        case .lockIn:      return "Lock In"
        case .postSession: return "Post Session"
        }
    }
}

/// The type of insight generated from pulse data.
/// Insights are observational — never evaluative.
/// "Your bandwidth has been lower this week" not "You seem stressed."
enum InsightType: String, CaseIterable, Codable {
    case weeklyPattern
    case trending
    case anomaly
}

/// Color tier for a pulse entry — maps to AppColors in AppColors.swift extension.
/// Names and tiers are not final — revisit when PulseEntry shape is confirmed.
enum PulseCapacityColor: String, Codable, CaseIterable {
    case rose       // tier 1 — lowest
    case magenta    // tier 2
    case indigo     // tier 3
    case cyan       // tier 4 — highest

    var label: String {
        switch self {
        case .rose:    return "Empty"
        case .magenta: return "Low"
        case .indigo:  return "Good"
        case .cyan:    return "Abundant"
        }
    }
}

/// Tier derived from pulse capacityScore.
/// Names are not final — revisit when PulseEntry shape is confirmed.
/// Visual properties (color, lightColor) live in AppColors.swift extension.
enum PulseTier: String, CaseIterable, Codable {
    case expansive   // 3.5+
    case sovereign   // 2.5–3.5
    case friction    // 1.5–2.5
    case protective  // below 1.5

    static func tier(for score: Double) -> PulseTier {
        switch score {
        case 3.5...: return .expansive
        case 2.5...: return .sovereign
        case 1.5...: return .friction
        default:     return .protective
        }
    }

    var label: String {
        switch self {
        case .expansive:  return "The Expansive Space"
        case .sovereign:  return "The Sovereign Space"
        case .friction:   return "The Friction Space"
        case .protective: return "The Protective Space"
        }
    }

    var color: Color {
        switch self {
        case .expansive:  return AppColors.cyan
        case .sovereign:  return AppColors.purple
        case .friction:   return AppColors.magenta
        case .protective: return AppColors.magentaLight
        }
    }

    var sublabel: String {
        switch self {
        case .expansive:  return "Connected · Adventurous"
        case .sovereign:  return "Grounded · Secure"
        case .friction:   return "Anxious · Defensive"
        case .protective: return "Overwhelmed · Need Space"
        }
    }
}

/// Time window for pulse graph display.
/// widgetDefault drives the home screen widget.
/// Full window selector appears in PulseFullView only.
enum PulseWindow: String, CaseIterable, Identifiable {
    case oneWeek      = "1W"
    case twoWeeks     = "2W"
    case oneMonth     = "1M"
    case threeMonths  = "3M"
    case sixMonths    = "6M"
    case oneYear      = "1Y"
    case twoYears     = "2Y"
    case lifetime     = "All"

    var id: String { rawValue }

    var startDate: Date? {
        guard self != .lifetime else { return nil }
        return Calendar.current.date(
            byAdding: .day,
            value: -days,
            to: Date()
        )
    }

    func includes(_ date: Date) -> Bool {
        guard let start = startDate else { return true }
        return date >= start
    }

    func filter(_ entries: [PulseEntry]) -> [PulseEntry] {
        guard let start = startDate else { return entries }
        return entries.filter { $0.date >= start }
    }

    var days: Int {
        switch self {
        case .oneWeek:     return 7
        case .twoWeeks:    return 14
        case .oneMonth:    return 30
        case .threeMonths: return 90
        case .sixMonths:   return 180
        case .oneYear:     return 365
        case .twoYears:    return 730
        case .lifetime:    return Int.max
        }
    }

    var graphWidth: CGFloat {
        switch self {
        case .oneWeek:     return 320
        case .twoWeeks:    return 320
        case .oneMonth:    return 480
        case .threeMonths: return 640
        case .sixMonths:   return 960
        case .oneYear:     return 1400
        case .twoYears:    return 2400
        case .lifetime:    return 2400
        }
    }

    var label: String { rawValue }

    var accessibilityLabel: String {
        switch self {
        case .oneWeek:     return "One week"
        case .twoWeeks:    return "Two weeks"
        case .oneMonth:    return "One month"
        case .threeMonths: return "Three months"
        case .sixMonths:   return "Six months"
        case .oneYear:     return "One year"
        case .twoYears:    return "Two years"
        case .lifetime:    return "All time"
        }
    }

    static let widgetDefault: PulseWindow = .twoWeeks
}

// ─────────────────────────────────────────────────────────────
// MARK: - Entitlements
// ─────────────────────────────────────────────────────────────

/// The three entitlement tiers.
/// Lives on Couple — one purchase covers both partners.
/// pro is Act 2 — not active in V1.
enum EntitlementTier: String, CaseIterable, Codable {
    case free
    case core   // $24.99 lifetime — Act 1
    case pro    // $6.99-9.99/mo — Act 2, not yet active

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .core: return "Core"
        case .pro:  return "Pro"
        }
    }
}

/// Whether this is a primary couple connection or an additional one.
/// Primary is the main couple. Additional is $7.99 permanent per connection.
enum ConnectionType: String, CaseIterable, Codable {
    case primary    // $24.99 — main couple
    case additional // $7.99 — permanent, per additional connection
}

// ─────────────────────────────────────────────────────────────
// MARK: - Milestones
// ─────────────────────────────────────────────────────────────

/// One-time milestone events. Never reset once completed.
/// acknowledgedGroundRules gates Card 2.
/// readThreeResearchOrbs requires tracking specific Beacon
/// items — not just a count.
/// Milestone completion fires a visible in-app moment —
/// never a silent flag update.
enum MilestoneType: String, CaseIterable, Codable {
    case openedFirstDeck
    case completedFirstCard
    case firstPulseEntry
    case readThreeResearchOrbs      // tracks specific items, not a count
    case acknowledgedGroundRules    // gates Card 2
    case linkedPartner              // first time partner link completes
    case completedSoloDeck          // solo prep deck finished
}
