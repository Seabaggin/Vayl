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

    // MARK: - Beat phase (3-beat reveal ceremony)
    //
    // idle    → (load completes) → beat1: free match entrance; auto-advances after kHold12
    // beat1   → (hold) → beat2: locked teasers stagger in; auto-advances after kHold23
    // beat2   → (hold) → beat3: paywall auto-rises
    // beat3   → (purchase) → revealed: all matches lit, confident lines
    //
    // Already-Core couples skip beats 2-3 and land directly in revealed.
    // Tap-to-advance (advanceBeat) skips the current hold immediately.

    enum BeatPhase: Int, Equatable {
        case idle     = 0
        case beat1    = 1   // free match visible only
        case beat2    = 2   // locked teasers stagger in
        case beat3    = 3   // paywall open
        case revealed = 4   // post-unlock: all matches lit
    }

    // MARK: - Published state

    private(set) var phase: Phase = .loading

    /// All matches, each resolved to a display name + alignment + locked flag.
    /// Free couple: the one `is_free_reveal` is unlocked, the rest locked. Core: all unlocked.
    private(set) var matches: [RevealMatch] = []

    /// Drives the 3-beat ceremony. View observes this to choreograph the visual sequence.
    private(set) var beatPhase: BeatPhase = .idle

    /// The pending auto-advance timer (held weakly inside; tracked here so a new sequence
    /// or an unlock can cancel a stale one). Never strongly retains the store.
    @ObservationIgnored private var autoAdvanceTask: Task<Void, Never>?

    // MARK: - Interaction state (sheet hosts live inside the reveal cover)

    /// Set when the user taps a star — drives the detail sheet.
    var selectedMatch: RevealMatch? = nil
    /// True while the full-map list sheet is open.
    var showFullMap: Bool = false
    /// True while the paywall sheet is open (tapped a locked star or the upgrade CTA).
    var showPaywall: Bool = false

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

    // MARK: - Beat sequence

    /// Kick off the reveal ceremony. No-op if a sequence is already running.
    /// Already-Core couples skip straight to .revealed (no conversion moment needed).
    func startBeatSequence() {
        guard beatPhase == .idle else { return }
        if isFullyUnlocked {
            beatPhase = .revealed
        } else {
            beatPhase = .beat1
            scheduleAutoAdvance()
        }
    }

    /// Tap-to-advance: skip the current hold immediately. Idempotent — safe to call at any beat.
    /// Animations are driven by the View observing beatPhase changes.
    func advanceBeat() {
        autoAdvanceTask?.cancel()   // a tap supersedes the auto-timer; the user drives from here
        switch beatPhase {
        case .beat1: beatPhase = .beat2
        case .beat2: beatPhase = .beat3; showPaywall = true
        case .beat3: showPaywall = true  // re-open paywall if the user dismissed it without purchasing
        default: break
        }
    }

    private func scheduleAutoAdvance() {
        // Holds from desire-reveal.html control panel (default values; feel in the mockup):
        //   kHold12 (flip-settle → gap): 1.5s
        //   kHold23 (gap appears → paywall rises): 1.2s
        let kHold12: Double = 1.5
        let kHold23: Double = 1.2
        // [weak self]: a fire-and-forget timer must NOT keep the store alive past the reveal.
        // A strong capture would release the store on a background executor when the Task ends
        // (after the cover dismissed / in tests, after the case returned), routing the
        // @MainActor isolated deinit through the wrong executor.
        autoAdvanceTask?.cancel()
        autoAdvanceTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(kHold12))
            guard let self, beatPhase == .beat1 else { return }
            beatPhase = .beat2

            // Wait for all locked rows to stagger in before the hold begins
            let staggerDone = Double(lockedCount) * 0.08 + 0.14
            try? await Task.sleep(for: .seconds(staggerDone + kHold23))
            guard beatPhase == .beat2 else { return }
            beatPhase = .beat3
            showPaywall = true
        }
    }

    // MARK: - Load

    /// Fetch the couple's matches and resolve the free/locked split. No-op (empty) when unpaired.
    func load() async {
        guard let coupleId = appState.coupleId else { phase = .empty; return }
        phase = .loading
        do {
            let names = try itemNameMap()
            let categories = try itemCategoryMap()
            let rows = try await service.fetchMatches(coupleId: coupleId)
            let core = entitlements.isCore
            matches = rows.map { row in
                RevealMatch(
                    id: row.id,
                    itemName: names[row.desireItemId] ?? row.desireItemId,
                    itemCategory: categories[row.desireItemId],
                    alignment: row.matchType,                       // mutual / adjacent
                    isLocked: !core && !row.isFreeReveal,           // free couple locks all but the free one
                    bridgeCardId: row.bridgeCardId
                )
            }
            phase = matches.isEmpty ? .empty : .ready
            if !matches.isEmpty {
                // Always stamp free-seen. This closes the latent edge where a Core couple
                // opening the reveal stamped only full: true, leaving free_reveal_seen_at null
                // and HomeStore.revealDone (= hasSeenFree) permanently false.
                Task { try? await service.markRevealSeen(coupleId: coupleId, full: false) }
            }
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    private func itemNameMap() throws -> [String: String] {
        try ContentLoader.loadDesireItems().reduce(into: [:]) { $0[$1.id] = $1.name }
    }

    private func itemCategoryMap() throws -> [String: String] {
        try ContentLoader.loadDesireItems().reduce(into: [:]) { $0[$1.id] = $1.category }
    }

    // MARK: - Actions (stubbed — see file header)

    /// Unlock all matches for BOTH partners — runs the Core purchase (M2). On success the
    /// entitlement resolves Core (server + local StoreKit), so re-loading flips the locked teasers
    /// open. M5 (the dedicated paywall surface) can replace this entry with a richer sheet.
    func unlockAll() {
        Task {
            guard let coupleId = appState.coupleId else { return }
            guard await entitlements.purchase() else { return }
            await load()
            // Stamp full-seen now that the whole map is accessible.
            Task { try? await service.markRevealSeen(coupleId: coupleId, full: true) }
        }
    }

    /// Request a conversation about a question the couple did NOT match on (a hidden / big-gap item).
    /// The exact behavior is the spec's open decision — surfaces only the requester's own answer,
    /// never the partner's score. Stubbed until that decision lands.
    func requestHiddenConversation() {
        // TODO(D4): define what a request DOES (notify partner? queue a discussion card?).
    }

    // MARK: - Sheet interaction

    /// Tap a star: unlocked → open detail sheet; locked → open paywall.
    func selectStar(_ match: RevealMatch) {
        if match.isLocked {
            showPaywall = true
        } else {
            selectedMatch = match
        }
    }

    /// Open the full-map list sheet from the top-right pill.
    func openFullMap() {
        showFullMap = true
    }

    /// Dismiss the detail sheet or the full-map sheet (not the paywall).
    func dismissSheets() {
        selectedMatch = nil
        showFullMap = false
    }

    /// Dismiss the paywall sheet only.
    func closePaywall() {
        showPaywall = false
    }

    /// Called by `PaywallSheet.onUnlocked` after the purchase has already succeeded.
    /// Closes the paywall, transitions to .revealed, and reloads — at this point
    /// `entitlements.isCore` is already true, so `load()` resolves all matches as unlocked,
    /// lighting the constellation in place. Also stamps `full: true` seen.
    func handleUnlockSuccess() {
        autoAdvanceTask?.cancel()
        showPaywall = false
        beatPhase = .revealed
        Task {
            await load()
            guard let coupleId = appState.coupleId else { return }
            Task { try? await service.markRevealSeen(coupleId: coupleId, full: true) }
        }
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
    let itemCategory: String?           // e.g. "emotional", "sexual", "communication"
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
    static func sample(_ name: String, _ alignment: DesireMatchType, locked: Bool = false, category: String? = "emotional") -> RevealMatch {
        RevealMatch(id: UUID(), itemName: name, itemCategory: category, alignment: alignment, isLocked: locked, bridgeCardId: nil)
    }
    #endif
}
