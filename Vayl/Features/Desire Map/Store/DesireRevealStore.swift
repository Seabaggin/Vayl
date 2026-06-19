//
//  DesireRevealStore.swift
//  Vayl
//
//  Store for D4 — the Desire-Map reveal (the "magic moment"). Reads the couple's computed
//  matches (alignment only — NEVER raw partner answers) and resolves the free/locked split.
//
//  4-Layer arch: View → Store → Service. Reads `DesireSyncService.fetchMatches` (client-safe:
//  id, item, alignment, is_free_reveal — no partner values/gap). The free/locked gate is the
//  conversion mechanic (D4 shows it; M5 wires the actual purchase).
//
//  STUB STATUS (2026-06-17): structure + data wiring complete; FEEL/styling is Bryan's pass.
//  Deferred: unlockAll() → M5 (StoreKit → grant-entitlement); requestHiddenConversation()
//  behavior is the spec's open decision ("what does a request DO?").
//

import Foundation
import SwiftData

@Observable
@MainActor
final class DesireRevealStore: Identifiable {

    /// Identity for `.fullScreenCover(item:)` presentation (mirrors DesireMapStore).
    let id = UUID()

    // MARK: - Phase

    enum Phase: Equatable {
        case loading
        case ready
        case empty            // both complete but no positive matches — graceful, not an error
        case failed(String)
    }

    // MARK: - Published state

    private(set) var phase: Phase = .loading

    /// All matches, each resolved to a display name + alignment + locked flag.
    /// Free couple: the one `is_free_reveal` is unlocked, the rest locked. Core: all unlocked.
    private(set) var matches: [RevealMatch] = []

    // MARK: - Derived

    var unlockedMatches: [RevealMatch] { matches.filter { !$0.isLocked } }
    var lockedMatches:   [RevealMatch] { matches.filter { $0.isLocked } }
    var lockedCount: Int { lockedMatches.count }
    var totalCount:  Int { matches.count }

    /// True once the couple is `core` — every match is shown, no unlock CTA.
    var isFullyUnlocked: Bool { entitlements.isCore }

    // MARK: - Dependencies

    private let appState: AppState
    private let entitlements: EntitlementStore
    private let service: DesireSyncService

    init(
        appState: AppState,
        entitlements: EntitlementStore,
        service: DesireSyncService? = nil
    ) {
        self.appState = appState
        self.entitlements = entitlements
        // Resolve the main-actor singleton in the @MainActor init body, not as a nonisolated default arg.
        self.service = service ?? .shared
    }

    // MARK: - Load

    /// Fetch the couple's matches and resolve the free/locked split. No-op (empty) when unpaired.
    func load() async {
        guard let coupleId = appState.coupleId else { phase = .empty; return }
        phase = .loading
        do {
            let names = try itemNameMap()
            let rows = try await service.fetchMatches(coupleId: coupleId)
            let core = entitlements.isCore
            matches = rows.map { row in
                RevealMatch(
                    id: row.id,
                    itemName: names[row.desireItemId] ?? row.desireItemId,
                    alignment: row.matchType,                       // mutual / adjacent
                    isLocked: !core && !row.isFreeReveal,           // free couple locks all but the free one
                    bridgeCardId: row.bridgeCardId
                )
            }
            phase = matches.isEmpty ? .empty : .ready
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    private func itemNameMap() throws -> [String: String] {
        try ContentLoader.loadDesireItems().reduce(into: [:]) { $0[$1.id] = $1.name }
    }

    // MARK: - Actions (stubbed — see file header)

    /// Unlock all matches for BOTH partners — runs the Core purchase (M2). On success the
    /// entitlement resolves Core (server + local StoreKit), so re-loading flips the locked teasers
    /// open. M5 (the dedicated paywall surface) can replace this entry with a richer sheet.
    func unlockAll() {
        Task {
            if await entitlements.purchase() { await load() }
        }
    }

    /// Request a conversation about a question the couple did NOT match on (a hidden / big-gap item).
    /// The exact behavior is the spec's open decision — surfaces only the requester's own answer,
    /// never the partner's score. Stubbed until that decision lands.
    func requestHiddenConversation() {
        // TODO(D4): define what a request DOES (notify partner? queue a discussion card?).
    }

    // MARK: - Preview seam

    #if DEBUG
    static func previewStore(matches: [RevealMatch], phase: Phase = .ready) -> DesireRevealStore {
        let store = DesireRevealStore(
            appState: AppState(),
            entitlements: EntitlementStore(modelContainer: .previewContainer, appState: AppState())
        )
        store.matches = matches
        store.phase = phase
        return store
    }
    #endif
}

// MARK: - RevealMatch (view model)

/// One match as the reveal renders it — display name + alignment + locked flag.
/// Carries NO raw answers or gap (the read path never has them).
struct RevealMatch: Identifiable, Equatable {
    let id: UUID
    let itemName: String
    let alignment: DesireMatchType?     // mutual ("Mutual") / adjacent ("Worth Exploring")
    let isLocked: Bool
    let bridgeCardId: String?

    /// Celebratory subtitle by alignment (mutual = wholehearted; adjacent = mostly aligned).
    var celebration: String {
        switch alignment {
        case .mutual:   return "You're both excited about this."
        case .adjacent: return "You're mostly aligned here."
        case .none:     return "You share this."
        }
    }

    #if DEBUG
    static func sample(_ name: String, _ alignment: DesireMatchType, locked: Bool = false) -> RevealMatch {
        RevealMatch(id: UUID(), itemName: name, alignment: alignment, isLocked: locked, bridgeCardId: nil)
    }
    #endif
}
