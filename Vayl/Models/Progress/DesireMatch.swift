//
//  DesireMatch.swift
//  Vayl
//

import Foundation
import SwiftData

// MARK: - DesireMatch
// Represents a positive match between two partners on a Desire Map item.
// Computed by the Supabase Edge Function — never by the client.
// Contains no individual ratings — only confirmed mutual positives.
//
// notForUs combinations never produce a DesireMatch.
// Individual ratings live in DesireMapEntry — local only, never crossed.
//
// isFreeReveal is server-authoritative — the client cannot set this to true.
// If the client could set it, the paywall is trivially bypassed.
// revealedAt is nil until the paywall is cleared.

@Model
final class DesireMatch {

    // MARK: - Identity

    var id: UUID
    var coupleId: UUID
    var itemId: String          // one of 17 canonical item IDs
    var computedAt: Date

    // MARK: - Match Type

    var matchType: DesireMatchType  // mutual (both yes) / adjacent (one yes, one curious)

    // MARK: - Reveal State

    var isFreeReveal: Bool      // the one free match — set by Edge Function only
    var revealedAt: Date?       // nil until paywall cleared

    // MARK: - Init

    init(
        coupleId: UUID,
        itemId: String,
        matchType: DesireMatchType
    ) {
        self.id = UUID()
        self.coupleId = coupleId
        self.itemId = itemId
        self.matchType = matchType
        self.computedAt = Date()
        self.isFreeReveal = false   // always set by Edge Function — never client
        self.revealedAt = nil
    }

    // MARK: - Computed

    var isRevealed: Bool {
        revealedAt != nil
    }

    // MARK: - Preview Helpers

    static let example = DesireMatch(
        coupleId: UUID(),
        itemId: "desire-001",
        matchType: .mutual
    )

    static let freeRevealExample: DesireMatch = {
        let m = DesireMatch(
            coupleId: UUID(),
            itemId: "desire-002",
            matchType: .adjacent
        )
        m.isFreeReveal = true
        return m
    }()
}
