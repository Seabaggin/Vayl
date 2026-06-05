//
//  MilestoneRecord.swift
//  Vayl
//
//  Created by Bryan Jorden on 4/27/26.
//


//
//  MilestoneRecord.swift
//  Vayl
//
//  Location: Models/Persistence/MilestoneRecord.swift
//

import Foundation
import SwiftData

// MARK: - MilestoneRecord
// Records a one-time milestone event for a user.
// Device only — never synced to Supabase.
//
// Milestones are one-time events — once completed, never reset.
// acknowledgedGroundRules gates Card 2 — checked before
// CardSession advances past Card 1.
//
// readThreeResearchOrbs requires tracking which specific Beacon
// items were tapped — not just a count. Use beaconItemsRead
// to store the specific IDs.
//
// Milestone completion always fires a visible in-app moment.
// Never a silent flag update.

@Model
final class MilestoneRecord {

    // MARK: - Identity

    var id: UUID
    var userId: UUID
    var milestone: Milestone
    var completedAt: Date

    // MARK: - Supplementary Data
    // Some milestones need additional context beyond the completion flag.
    // beaconItemsRead — tracks specific Beacon item IDs for
    // readThreeResearchOrbs. nil for all other milestones.

    var beaconItemsRead: [String]?  // nil unless milestone == .readThreeResearchOrbs

    // MARK: - Init

    init(
        userId: UUID,
        milestone: Milestone,
        beaconItemsRead: [String]? = nil
    ) {
        self.id = UUID()
        self.userId = userId
        self.milestone = milestone
        self.completedAt = Date()
        self.beaconItemsRead = beaconItemsRead
    }

    // MARK: - Computed

    /// Whether the research orbs milestone has enough
    /// distinct items read to be considered complete.
    /// Only relevant when milestone == .readThreeResearchOrbs.
    var researchOrbsComplete: Bool {
        guard milestone == .readThreeResearchOrbs else { return false }
        return (beaconItemsRead ?? []).count >= 3
    }

    // MARK: - Preview Helpers

    static let example = MilestoneRecord(
        userId: UUID(),
        milestone: .completedFirstCard
    )

    static let groundRulesExample = MilestoneRecord(
        userId: UUID(),
        milestone: .acknowledgedGroundRules
    )

    static let researchOrbsExample = MilestoneRecord(
        userId: UUID(),
        milestone: .readThreeResearchOrbs,
        beaconItemsRead: ["beacon-001", "beacon-002", "beacon-003"]
    )

    static let linkedPartnerExample = MilestoneRecord(
        userId: UUID(),
        milestone: .linkedPartner
    )

    static let soloDeckExample = MilestoneRecord(
        userId: UUID(),
        milestone: .completedSoloDeck
    )
}