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
import SwiftUI   // AppAnimation tokens + UIAccessibility (Reduce Motion checks in the beat ceremony)

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
    ///
    /// Edge case (fix #2): a free couple whose ONLY match is the free one (lockedCount == 0)
    /// has nothing to gate. Auto-advancing them to beat3 would float a paywall over an empty
    /// locked section. Treat them like already-Core: land on the lit end-state, no ask, no gap.
    /// (matches / lockedCount are populated by load() before .ready, which gates this call.)
    func startBeatSequence() {
        guard beatPhase == .idle else { return }
        if isFullyUnlocked || lockedCount == 0 {
            beatPhase = .revealed
        } else {
            beatPhase = .beat1
            scheduleAutoAdvance()
        }
    }

    /// Tap-to-advance: skip the current hold immediately. Idempotent — safe to call at any beat.
    /// Animations are driven by the View observing beatPhase changes.
    ///
    /// Fix #1: a beat1 tap lands on beat2, but the beat2 → beat3 leg must still auto-arm so the
    /// paywall eventually rises on its own. Both the auto path (scheduleAutoAdvance) and a tap
    /// route the second leg through scheduleBeat2ToBeat3() so neither strands the ceremony.
    func advanceBeat() {
        autoAdvanceTask?.cancel()   // a tap supersedes the current auto-timer; the user drives from here
        switch beatPhase {
        case .beat1:
            beatPhase = .beat2
            scheduleBeat2ToBeat3()   // re-arm the second leg so the paywall still auto-rises
        case .beat2: beatPhase = .beat3; showPaywall = true
        case .beat3: showPaywall = true  // re-open paywall if the user dismissed it without purchasing
        default: break
        }
    }

    /// First leg of the ceremony: beat1 hold, then beat1 → beat2, then chains the second leg.
    /// [weak self]: a fire-and-forget timer must NOT keep the store alive past the reveal.
    /// A strong capture would release the store on a background executor when the Task ends
    /// (after the cover dismissed / in tests, after the case returned), routing the
    /// @MainActor isolated deinit through the wrong executor.
    private func scheduleAutoAdvance() {
        // Fix #3a: with Reduce Motion on, collapse the hold to 0 so there is no timed ceremony.
        let hold: Double = UIAccessibility.isReduceMotionEnabled ? 0 : AppAnimation.desireBeatHold1
        autoAdvanceTask?.cancel()
        autoAdvanceTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(hold))
            guard let self, beatPhase == .beat1 else { return }
            beatPhase = .beat2
            scheduleBeat2ToBeat3()
        }
    }

    /// Second leg: wait for the locked rows to stagger in plus the beat-2 hold, then beat2 → beat3
    /// and raise the paywall. Reusable so both the auto path and a beat1 tap reach beat3.
    private func scheduleBeat2ToBeat3() {
        let reduceMotion = UIAccessibility.isReduceMotionEnabled
        // Fix #4: tokenized holds + stagger (was kHold23 1.2 / 0.08 step / 0.14 base).
        let stagger = Double(lockedCount) * AppAnimation.desireBeatStaggerStep + AppAnimation.desireBeatStaggerBase
        // Fix #3a: Reduce Motion collapses the hold so beat3 lands immediately (no timed ceremony).
        let wait: Double = reduceMotion ? 0 : (stagger + AppAnimation.desireBeatHold2)
        autoAdvanceTask?.cancel()
        autoAdvanceTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(wait))
            guard let self, beatPhase == .beat2 else { return }
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
