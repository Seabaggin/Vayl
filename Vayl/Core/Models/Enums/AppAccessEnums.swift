//
//  AppAccessEnums.swift.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/22/26.
//
import Foundation
import SwiftUI
// ─────────────────────────────────────────────────────────────
// MARK: - Access
// ─────────────────────────────────────────────────────────────

/// The three access tiers.
/// Lives on Couple — one purchase covers both partners.
/// pro is Act 2 — not active in V1.
enum AccessTier: String, CaseIterable, Codable {
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
enum ConnectionPlan: String, CaseIterable, Codable {
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
enum Milestone: String, CaseIterable, Codable {
    case openedFirstDeck
    case completedFirstCard
    case firstPulseEntry
    case readThreeResearchOrbs      // tracks specific items, not a count
    case acknowledgedGroundRules    // gates Card 2
    case linkedPartner              // first time partner link completes
    case completedSoloDeck          // solo prep deck finished
}
