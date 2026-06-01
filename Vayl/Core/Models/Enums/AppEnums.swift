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
/// Written EXCLUSIVELY by ContextPhase (1:1 with the chosen option).
/// Together and solo modes draw from disjoint subsets of these cases.
/// Governs the content category entry point.
enum RelationshipContext: String, CaseIterable, Codable {
    // Solo × Curious
    case singleCurious, partneredSupportiveCurious, partneredUndisclosed, soloCuriousUndecided
    // Solo × Exploring
    case singleExploring, partneredHandsOff, multipleUndefined, soloExploringUndecided
    // Solo × Experienced
    case singleExperienced, partneredAware, soloPolyIndependent, soloExperiencedUndecided
    // Couple × Curious
    case coupleSymmetricCurious, coupleAsymmetricCurious, coupleStalledConversation, coupleCuriousUndecided
    // Couple × Exploring
    case coupleSolidifying, coupleReorienting, coupleParallelExploring, coupleExploringUndecided
    // Couple × Experienced
    case coupleFreshIntentional, coupleSkillBuilding, coupleEvolving, coupleExperiencedUndecided
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
