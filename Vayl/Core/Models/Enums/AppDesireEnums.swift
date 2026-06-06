//
//  AppDesireEnums.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/22/26.
//

import Foundation
import SwiftUI


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

