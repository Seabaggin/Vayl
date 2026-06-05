// Home/Models/HomeModels.swift
//
// View-layer structs and enums for the Home screen.
// No business logic. No SwiftData. Placeholder-ready.

import SwiftUI


// MARK: - Reflection Card State

enum ReflectionCardState {
    case hidden
    case pendingYours(sessionLabel: String, sessionDate: Date)
    case waitingOnPartner(sessionLabel: String,
                          yourPills: [String])
    case bothReflected(sessionLabel: String,
                       yourName: String,
                       yourPills: [String],
                       yourNote: String?,
                       partnerName: String,
                       partnerPills: [String],
                       partnerNote: String?,
                       swipePosition: Int)
    case summary(arc: String,
                 yourName: String,
                 yourDots: [Bool],
                 partnerName: String,
                 partnerDots: [Bool],
                 swipePosition: Int)
}

// MARK: - Reflection Pills

struct ReflectionPillGroup {
    static let howItFelt: [String] = [
        "Connected", "Tender", "Energized",
        "Heavy", "Relieved", "Uncertain",
        "Surprised", "Proud", "Raw"
    ]
    static let whatHappened: [String] = [
        "We went deeper than expected",
        "Something surfaced unexpectedly",
        "We disagreed on something",
        "We aligned on something big",
        "One of us needed to stop early",
        "Lighter than expected"
    ]
    static let whatYouNeedNow: [String] = [
        "Just marking this",
        "Want to sit with it",
        "Need some space",
        "Want to talk more",
        "Want something normal"
    ]
    static let inlineDefault: [String] = [
        "Connected", "Heavy", "Raw",
        "Relieved", "Surprised"
    ]
}

// MARK: - Pick Up Item

struct PickUpItem: Identifiable {
    let id = UUID()
    let contentType: PickUpContentType
    let title: String
    let contextLine: String
    let actionLabel: String
}

enum PickUpContentType {
    case timelineScenario(branchCurrent: Int, branchTotal: Int)
    case article(progressPercent: Int)
    case judgmentCall
    case autopsy(ratedMoments: Int, totalMoments: Int)
}

// MARK: - Research Ticker

struct ResearchFact: Identifiable {
    let id = UUID()
    let category: FactCategory
    let body: String
    let attribution: String?
}

enum FactCategory {
    case research
    case definition
    case reframe

    var overlineLabel: String {
        switch self {
        case .research:   return "RESEARCH"
        case .definition: return "DEFINITION"
        case .reframe:    return "OPEN LIGHTLY"
        }
    }
}

// MARK: - Home Event (for EventEngine)

enum HomeEvent {
    // Partner events
    case partnerCompletedDesireMap(partnerName: String)
    case partnerReflected(partnerName: String, sessionDay: String)
    case mutualReflectRevealReady

    // Milestone events
    case bothSawFreeReveal
    case fullMapUnlocked
    case stageCompleted(stageName: String)
    case stageUnlocked(stageIndex: Int)
    case firstSessionCompleted
    case firstMutualReflection

    // Time events
    case daysSinceSession(Int, partnerName: String?)
    case threeOpensNoSession

    var expiresAfterHours: Int {
        switch self {
        case .partnerCompletedDesireMap,
             .partnerReflected,
             .mutualReflectRevealReady,
             .bothSawFreeReveal,
             .fullMapUnlocked,
             .stageCompleted,
             .stageUnlocked,
             .firstSessionCompleted,
             .firstMutualReflection:
            return 24
        case .daysSinceSession,
             .threeOpensNoSession:
            return 0 // persistent until condition changes
        }
    }
}

// MARK: - Home State

/// The routing state that drives HomeRouterView.
/// Computed by HomeStore — never set directly by the view.
/// Order matters — each case gates the next.
enum HomeState: Equatable {
    case gated          // desire map not started
    case postReflection // desire map done, reflection not done
    case waiting        // reflection done, partner not done
    case matchReady     // both done, reveal not triggered
    case dashboard      // fully unlocked home
    case soloUnpaired   // solo user, OB complete, no partner yet — starter deck reachable, Desire Map gated
}
