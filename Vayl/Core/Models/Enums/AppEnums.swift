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
enum AppMode: String, CaseIterable, Codable {
    case together   // both partners talked, doing this as a couple
    case solo       // in a relationship, conversation hasn't happened yet

    var displayName: String {
        switch self {
        case .together: return "Shared Journey"
        case .solo:     return "Solo Discovery"
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

/// How this user wants to feel — the aspirational register.
/// Written EXCLUSIVELY by CompassPhase Q3. ContextPhase never touches this.
/// Collected during onboarding. Lives on UserProfile.
/// User-adjustable in Settings at any time.
/// Governs tone and warmth of card copy — never content category or pacing.
enum EmotionalRegister: String, CaseIterable, Codable {
    case anxious    // "I want to feel safer"      → reassurance-first tone
    case excited    // "I want to feel more alive" → expansion-first tone
    case flexible   // midpoint / neither          → clarity-first tone
    case unknown    // "Honestly, I'm not sure yet" → defers to AgencySignal

    var displayName: String {
        switch self {
        case .anxious:  return "Thoughtful"
        case .excited:  return "Expansive"
        case .flexible: return "Flexible"
        case .unknown:  return "Unsure"
        }
    }

    /// Maps a Q3 slider value (0.0 = "I want to feel safer" … 1.0 = "more alive")
    /// to a register. 0–35% → .anxious · 36–64% → .flexible · 65–100% → .excited.
    /// `.unknown` is set separately via the "not sure yet" escape — never the slider.
    static func from(sliderValue v: Double) -> EmotionalRegister {
        switch v {
        case ..<0.36: return .anxious
        case 0.65...: return .excited
        default:      return .flexible
        }
    }
}

/// How chosen being here feels for this user — CompassPhase Q1.
/// The most load-bearing Compass signal: governs personal pacing and, in couple
/// mode, sets the shared-deck pacing floor (slowest partner governs — never averaged).
/// Written EXCLUSIVELY by CompassPhase Q1. Never shown to the user as a label.
enum AgencySignal: String, CaseIterable, Codable {
    case fullyIn       // "I'm genuinely excited about this"
    case cautiouslyIn  // "I'm curious but a little nervous"
    case hesitant      // "I'm here, but I'm not totally sure yet"
    case goingAlong    // "Honestly, I'm going along with it"

    var label: String {
        switch self {
        case .fullyIn:      return "I'm genuinely excited about this"
        case .cautiouslyIn: return "I'm curious but a little nervous"
        case .hesitant:     return "I'm here, but I'm not totally sure yet"
        case .goingAlong:   return "Honestly, I'm going along with it"
        }
    }

    /// Dealt-card order for the 2×2 grid (reading order: top-left → bottom-right).
    static var ordered: [AgencySignal] { [.fullyIn, .cautiouslyIn, .hesitant, .goingAlong] }
}

/// What would feel like a win for this user — CompassPhase Q2.
/// Drives card-category priority individually; in couple mode the gap between
/// partners' motivations seeds the first shared deck topic. ONE enum — the option
/// SET shown depends on appMode. Written EXCLUSIVELY by CompassPhase Q2.
enum MotivationShape: String, CaseIterable, Codable {
    case connection       // couple: "Understanding my partner better"
    case selfClarity      // both:   "Feeling more confident in myself" / "…about all of this"
    case alignment        // couple: "Finding a pace that works for both of us"
    case selfDiscovery    // both:   "Figuring out / Knowing what I actually want"
    case readiness        // solo:   "Finding the words to bring this up"
    case openExploration  // solo:   "Just exploring — no agenda yet"

    /// Couple-mode option order (top-left → bottom-right).
    static var coupleOptions: [MotivationShape] { [.connection, .selfClarity, .alignment, .selfDiscovery] }
    /// Solo-mode option order.
    static var soloOptions:   [MotivationShape] { [.selfDiscovery, .readiness, .selfClarity, .openExploration] }

    /// Option order for the given app mode.
    static func options(for mode: AppMode) -> [MotivationShape] {
        mode == .together ? coupleOptions : soloOptions
    }

    /// Mode-dependent label — selfClarity / selfDiscovery read differently per mode.
    func label(for mode: AppMode) -> String {
        switch (self, mode) {
        case (.connection, _):            return "Understanding my partner better"
        case (.alignment, _):             return "Finding a pace that works for both of us"
        case (.readiness, _):             return "Finding the words to bring this up"
        case (.openExploration, _):       return "Just exploring — no agenda yet"
        case (.selfClarity, .together):   return "Feeling more confident in myself"
        case (.selfClarity, _):           return "Feeling more confident about all of this"
        case (.selfDiscovery, .together): return "Figuring out what I actually want"
        case (.selfDiscovery, _):         return "Knowing what I actually want"
        }
    }
}

/// What situation this user is dealing with — the situational register.
/// Written EXCLUSIVELY by ContextPhase (derived from the chosen option).
/// Distinct from EmotionalRegister (Compass Q3): different field, no overlap.
/// Governs content category weights and deck topic priority — never tone or pacing.
enum SituationalRegister: String, CaseIterable, Codable {
    case anxious    // hard situation / needs repair
    case excited    // momentum / moving forward
    case flexible   // early or neutral — default
}

/// Where this user's relationship actually stands — the concrete starting point.
/// Written EXCLUSIVELY by ContextPhase (1:1 with the chosen option). Reason-based:
/// solo = why you're exploring alone, couple = your first-person goal/feeling about the
/// relationship. Solo and couple draw from disjoint subsets (`single` is solo-only, shared
/// across both solo cells). Persisted for record only — nothing branches on the specific
/// case; the behavioural driver is the derived SituationalRegister (ContextOption.derivedRegister).
enum RelationshipContext: String, CaseIterable, Codable {
    // Solo · Curious — reasons to explore alone, new to NM
    case soloLearning, soloUndisclosed, soloSeekingClarity
    // Solo · In it — reasons to explore alone, already practicing
    case soloIntentional, soloExpandKnowledge, soloCheckingOut
    // Single — shared across both solo cells; triggers the couples-first greeting
    case single
    // Couple · Curious — first-person, new to it
    case coupleExcited, coupleNervous, coupleInitiator, coupleFiguringOut
    // Couple · In it — first-person, already in it
    case coupleGoDeeper, coupleGetBetter, coupleRecalibrating, coupleKeepItFun
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



// ─────────────────────────────────────────────────────────────
// MARK: - UI Constants
// ─────────────────────────────────────────────────────────────

/// SF Symbol names used across the app.
/// Raw strings for SF Symbols are banned — always reference via this enum.
/// Add a case here before using any new symbol anywhere in the codebase.
enum AppIcons {
    // ── Navigation & actions ──────────────────────────────────
    static let close              = "xmark"
    static let chevronRight       = "chevron.right"
    static let chevronLeft        = "chevron.left"
    static let chevronUp          = "chevron.up"
    static let arrowRight         = "arrow.right"
    static let arrowLeft          = "arrow.left"
    static let arrowTurnUpLeft    = "arrow.turn.up.left"
    static let forwardFill        = "forward.fill"
    static let chevronDown        = "chevron.down"

    // ── Desire Map & onboarding ───────────────────────────────
    static let lock               = "lock.fill"
    static let clock              = "clock.fill"
    static let eyeSlash           = "eye.slash.fill"
    static let eye                = "eye.fill"
    static let lightbulb          = "lightbulb.fill"
    static let heartFill          = "heart.fill"
    static let figureWalk         = "figure.walk"
    static let handRaised         = "hand.raised.fill"
    static let heartTextSquare    = "heart.text.square.fill"

    // ── Education & content ───────────────────────────────────
    static let books              = "books.vertical.fill"

    // ── Input ─────────────────────────────────────────────────
    static let mic                = "mic.fill"

    // ── Actions & status ──────────────────────────────────────
    static let checkmark          = "checkmark"
    static let checkmarkCircle    = "checkmark.circle.fill"
    static let plus               = "plus"
    static let bookmarkFill       = "bookmark.fill"
    static let docOnDoc           = "doc.on.doc"
    static let sparkles           = "sparkles"
    static let exclamationTriangle = "exclamationmark.triangle"

    // ── People & social ───────────────────────────────────────
    static let personBadgePlus    = "person.badge.plus"
    static let personBadgeClock   = "person.badge.clock"
    static let heartCircleFill    = "heart.circle.fill"

    // ── System & settings ─────────────────────────────────────
    static let paintpalette       = "paintpalette.fill"
    static let appleLogo          = "apple.logo"
    static let eyeSlashScreen     = "eye.slash.fill"

    // ── Status & feedback ─────────────────────────────────────
    static let warning            = "exclamationmark.triangle"
    static let gridCircle         = "grid.circle"
    static let gridCircleFill     = "grid.circle.fill"
    static let infoCircle         = "info.circle"
    static let link               = "link"

    // ── Pairing & sharing ──────────────────────────────
    static let gear                 = "gearshape.fill"
    static let paperplane           = "paperplane.fill"
    static let squareAndArrowUp     = "square.and.arrow.up"
    static let arrowTriangle2Circle = "arrow.triangle.2.circlepath"

    // ── Tab bar ───────────────────────────────────────────────
    // Tab icons live on AppTab — not duplicated here.
}

enum VaylButtonStyle {
    case primary    // full holographic shimmer + spectrum border
    case secondary  // reduced shimmer, border on confirm only
    case ghost      // no fill, border visible at low opacity always
    case gold       // opaque metallic sweep — warm gold angled highlight
}

enum VaylButtonSize {
    case fullWidth
    case compact
    case pill(width: CGFloat)

    var height: CGFloat {
        switch self {
        case .fullWidth: return 56
        case .compact:   return 48
        case .pill:      return 44
        }
    }

    var width: CGFloat? {
        switch self {
        case .fullWidth:        return nil   // .infinity handled in VaylButton
        case .compact:          return 200
        case .pill(let w):      return w
        }
    }
}
