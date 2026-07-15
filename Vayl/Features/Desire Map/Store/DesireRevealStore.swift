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
//  The "request a hidden conversation" idea moved to the Vault consent flow
//  (VaultStore.askToOpen + VaultDesireSection), so it no longer lives here.
//

import Foundation
import PostHog
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
    // beat1   → (hold) → beat2: locked teasers stagger in — the ceremony rests here
    // beat2   → (user taps a locked star) → beat3: paywall opens
    // beat3   → (purchase) → revealed: all matches lit, confident lines
    //
    // The paywall never auto-rises — it only opens from an explicit tap on a locked star
    // (selectStar) or the Full Map/upgrade CTA. beat3 itself is reached the same way; there
    // is no timer past beat2, unlike the earlier auto-advancing version of this ceremony.
    //
    // Already-Core couples skip beats 2-3 and land directly in revealed.
    // Tap-to-advance (advanceBeat) skips the beat1 hold immediately.

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
    private(set) var matches: [RevealMatch] = [] {
        didSet { rebuildConstellation() }
    }

    // MARK: - Constellation (audit Blueprint C — the hero rule lives HERE, testable)

    /// The generated constellation (positions + MST edges), seeded by the couple so the
    /// sky is theirs and stable across beats. Rebuilt once per `matches` change — the
    /// View used to regenerate this (and pick the hero) inside body computed properties.
    private(set) var layout = ConstellationLayout.Result(points: [], edges: [], heroIndex: 0)

    /// Matches placed onto the layout: the free-reveal (or first mutual) star takes the
    /// central hero slot; the rest fill the remaining positions in order. Sizes scale
    /// with count so many stars do not crowd. Indices align with `layout.points`/`.edges`.
    private(set) var placedStars: [DesireConstellationView.Star] = []

    private func rebuildConstellation() {
        let seed = appState.coupleId.map { ConstellationLayout.seed(for: $0) } ?? 0
        let result = ConstellationLayout.generate(count: matches.count, seed: seed)
        layout = result

        guard !result.points.isEmpty, !matches.isEmpty else {
            placedStars = []
            return
        }

        // The hero rule (monetization-adjacent): the server-set free reveal wins the
        // hero slot; else the first mutual; else the first match. Shared with `heroMatch`
        // below so the constellation's lit star and the locked list's visible row always
        // agree on which match is "the one revealed."
        let hero = Self.selectHero(from: matches)
        let others = matches.filter { $0.id != hero?.id }

        var placed = [RevealMatch?](repeating: nil, count: result.points.count)
        if result.heroIndex < placed.count { placed[result.heroIndex] = hero }
        var oi = 0
        for i in placed.indices where i != result.heroIndex {
            if oi < others.count { placed[i] = others[oi]; oi += 1 }
        }

        let n = max(matches.count, 1)
        let base = max(9.0, min(16.0, 16.0 * (4.0 / Double(n)).squareRoot()))
        let heroSize = CGFloat(min(24.0, base * 1.5))

        placedStars = placed.enumerated().compactMap { index, match in
            guard let match else { return nil }
            let isHero = index == result.heroIndex
            return DesireConstellationView.Star(
                id: match.id.uuidString,
                point: result.points[index],
                size: isHero ? heroSize : CGFloat(base),
                label: match.itemName,
                isHero: isHero,
                isLocked: match.isLocked,
                cadence: match.isLocked ? .locked : .free,
                isAdjacent: match.alignment == .adjacent
            )
        }
    }

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

    #if DEBUG
    /// Debug-only: force a specific ceremony variant. Production picks it by coupleId.
    var debugVariantOverride: CeremonyVariant? = nil
    #endif

    // MARK: - Derived

    /// The one match everyone in the ceremony sees named — the constellation's hero star
    /// and the locked list's single visible row both derive from this same selection.
    var heroMatch: RevealMatch? { Self.selectHero(from: matches) }

    /// The hero-selection rule: the server-set free reveal wins; else the first mutual;
    /// else the first match. A shared `static` function so `rebuildConstellation()` and
    /// `heroMatch` can't drift into disagreeing about which match is the hero.
    private static func selectHero(from matches: [RevealMatch]) -> RevealMatch? {
        matches.first(where: { $0.isFreeReveal })
            ?? matches.first(where: { $0.alignment == .mutual })
            ?? matches.first
    }

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
        PostHogSDK.shared.capture("desire_reveal_viewed", properties: [
            "match_count": matches.count,
            "locked_count": lockedMatches.count,
            "is_fully_unlocked": isFullyUnlocked,
        ])
        if isFullyUnlocked || lockedCount == 0 {
            beatPhase = .revealed
            // Landing straight on the lit sky (already-Core, or a lone free match) is a full
            // viewing, so stamp full-seen: full_reveal_seen_at should reflect reality, mirroring
            // the post-purchase path (handleUnlockSuccess). load() already stamped free-seen.
            if let coupleId = appState.coupleId {
                Task { try? await service.markRevealSeen(coupleId: coupleId, full: true) }
            }
        } else {
            beatPhase = .beat1
            scheduleAutoAdvance()
        }
    }

    /// Tap-to-advance: skip the beat1 hold immediately, landing on beat2 (locked teasers). Idempotent.
    /// Animations are driven by the View observing beatPhase changes.
    ///
    /// The ceremony rests at beat2 — there is no further auto-advance. The paywall (beat3) only
    /// opens from an explicit tap on a locked star (selectStar) or the Full Map/upgrade CTA, never
    /// from a timer or a generic tap-anywhere.
    func advanceBeat() {
        autoAdvanceTask?.cancel()   // a tap supersedes the current auto-timer; the user drives from here
        if beatPhase == .beat1 {
            beatPhase = .beat2
        }
    }

    /// Beat1 hold, then beat1 → beat2. The ceremony has no further timer past this — beat2 is
    /// where it rests until the user taps a locked star (opening the paywall) or purchases.
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
            let meanings = try itemMeaningMap()
            let rows = try await service.fetchMatches(coupleId: coupleId)
            let core = entitlements.isCore
            matches = rows.map { row in
                RevealMatch(
                    id: row.id,
                    itemName: names[row.desireItemId] ?? row.desireItemId,
                    itemCategory: categories[row.desireItemId],
                    alignment: row.matchType,                       // mutual / adjacent
                    isLocked: !core && !row.isFreeReveal,           // free couple locks all but the free one
                    bridgeCardId: row.bridgeCardId,
                    isFreeReveal: row.isFreeReveal,                 // the server-set hero star
                    meaning: row.matchType.flatMap { meanings[row.desireItemId]?[$0.rawValue] }
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

    private func itemMeaningMap() throws -> [String: [String: String]] {
        try ContentLoader.loadDesireItems().reduce(into: [:]) { $0[$1.id] = $1.meaning }
    }

    // MARK: - Actions (stubbed — see file header)

    /// Unlock all matches for BOTH partners — runs the Core purchase (M2). On success the
    /// entitlement resolves Core (server + local StoreKit), so re-loading flips the locked teasers
    /// open. M5 (the dedicated paywall surface) can replace this entry with a richer sheet.
    func unlockAll() {
        Task {
            guard await entitlements.purchase() else { return }
            #if DEBUG
            if appState.coupleId == nil {
                matches = matches.map { RevealMatch(id: $0.id, itemName: $0.itemName, itemCategory: $0.itemCategory, alignment: $0.alignment, isLocked: false, bridgeCardId: $0.bridgeCardId, isFreeReveal: $0.isFreeReveal, meaning: $0.meaning) }
                beatPhase = .revealed
                return
            }
            #endif
            await load()
            guard let coupleId = appState.coupleId else { return }
            Task { try? await service.markRevealSeen(coupleId: coupleId, full: true) }
        }
    }

    // MARK: - Sheet interaction

    /// Tap a star: unlocked → open detail sheet; locked → open paywall. A locked tap is the only
    /// path into beat3 — the paywall never auto-rises (see the beat-phase doc above).
    func selectStar(_ match: RevealMatch) {
        if match.isLocked {
            autoAdvanceTask?.cancel()
            if beatPhase == .beat2 { beatPhase = .beat3 }
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
            #if DEBUG
            if appState.coupleId == nil {
                matches = matches.map { RevealMatch(id: $0.id, itemName: $0.itemName, itemCategory: $0.itemCategory, alignment: $0.alignment, isLocked: false, bridgeCardId: $0.bridgeCardId, isFreeReveal: $0.isFreeReveal, meaning: $0.meaning) }
                return
            }
            #endif
            await load()
            guard let coupleId = appState.coupleId else { return }
            Task { try? await service.markRevealSeen(coupleId: coupleId, full: true) }
        }
    }

    // MARK: - Preview seam

    #if DEBUG
    static func previewStore(matches: [RevealMatch], phase: Phase = .ready, entitlements: EntitlementStore? = nil) -> DesireRevealStore {
        let store = DesireRevealStore(
            appState: AppState(),
            entitlements: entitlements ?? EntitlementStore(modelContainer: .previewContainer, appState: AppState())
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
    /// The one server-set free reveal (the emotional-peak star). Drives the hero on the unlocked sky.
    var isFreeReveal: Bool = false
    /// Couple-framed reveal copy from desire_items.json (`DesireItem.meaning`), resolved for this
    /// match's alignment. Falls back to `celebration` when an item has no authored meaning yet.
    var meaning: String? = nil

    /// Celebratory subtitle by alignment (mutual = wholehearted; adjacent = mostly aligned).
    /// Fallback for items without authored `meaning` copy.
    var celebration: String {
        switch alignment {
        case .mutual:   return "You're both excited about this."
        case .adjacent: return "You're mostly aligned here."
        case .none:     return "You share this."
        }
    }

    /// The line the detail views show: authored meaning when available, else the generic celebration.
    var displayMeaning: String { meaning ?? celebration }

    #if DEBUG
    static func sample(_ name: String, _ alignment: DesireMatchType, locked: Bool = false, free: Bool = false, category: String? = "emotional", meaning: String? = nil) -> RevealMatch {
        RevealMatch(id: UUID(), itemName: name, itemCategory: category, alignment: alignment, isLocked: locked, bridgeCardId: nil, isFreeReveal: free, meaning: meaning)
    }
    #endif
}
