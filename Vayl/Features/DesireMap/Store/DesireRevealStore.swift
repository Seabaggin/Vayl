//
//  DesireRevealStore.swift
//  Vayl
//
//  Store for D4 — the Desire-Map reveal (the "magic moment"). Reads the couple's computed
//  matches (alignment only — NEVER raw partner answers) and renders the free/locked split
//  the SERVER already decided.
//
//  4-Layer arch: View → Store → Service. Reads `DesireSyncService.fetchMatches`, which goes
//  through the entitlement-checked RPC (launch hardening, review 2026-07-09 §1.2): Core
//  couples get full rows; free couples get the free match full plus opaque locked stubs
//  (nil item id / alignment, stub category only). The client never re-derives lock state
//  from entitlements — a row is locked iff the server withheld its identity.
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
        case empty(EmptyReason)   // graceful, not an error — the reason picks honest copy
        case failed(String)
    }

    /// Why the reveal has nothing to show (review 2026-07-09 §1.4). Three different truths
    /// that used to share one lying copy line ("when you both finish…"):
    enum EmptyReason: Equatable {
        case unpaired            // no couple yet — never mention a partner
        case waitingForPartner   // at least one side hasn't finished
        case noMatches           // both finished, compute ran (self-heal included): a true zero
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
    // Couples whose rows arrive with nothing locked (Core, or a lone free match) skip
    // beats 2-3 and land directly in revealed.
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

    /// All matches as the server chose to show them: unlocked rows carry a real name,
    /// locked stubs carry only an (optional) category teaser. Lock state is server truth.
    private(set) var matches: [RevealMatch] = [] {
        didSet { rebuildConstellation() }
    }

    /// True between "the purchase succeeded" and "the server confirmed Core rows"
    /// (review 2026-07-09 §1.2: unlock truth = server tier). The view shows the
    /// "Payment received" interim state while this is set.
    private(set) var unlockPending: Bool = false

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
        // Bumped 2026-07-21 (was 9…16 / hero ≤24): the stars read as faint pinpricks against the
        // atmosphere. `size` is the core diameter — glow is 3.2× it — so a few points here is a
        // visible jump in presence.
        var base = max(12.0, min(21.0, 21.0 * (4.0 / Double(n)).squareRoot()))
        var heroSize = min(31.0, base * 1.5)
        #if DEBUG
        base *= DesireSequenceTuning.shared.starSizeScale
        heroSize *= DesireSequenceTuning.shared.starSizeScale
        #endif

        placedStars = placed.enumerated().compactMap { index, match in
            guard let match else { return nil }
            let isHero = index == result.heroIndex
            return DesireConstellationView.Star(
                id: match.id.uuidString,
                point: result.points[index],
                size: isHero ? heroSize : CGFloat(base),
                label: match.itemName,   // nil for locked stubs — the star stays anonymous
                isHero: isHero,
                isLocked: match.isLocked,
                cadence: match.isLocked ? .locked : .free,
                isAdjacent: match.alignment == .adjacent
            )
        }
    }

    /// Drives the 3-beat ceremony. View observes this to choreograph the visual sequence.
    private(set) var beatPhase: BeatPhase = .idle

    /// True once the free (hero) match has opened — its star lights and its row shows a real name,
    /// on the same frame. False through the whole beat-1 ceremony: the sky arrives entirely locked
    /// and *then* one star opens, so the free match gets a moment of its own instead of merely
    /// being the row that was always bright.
    private(set) var heroRevealed: Bool = false

    /// Drives the match-row cascade. Flipped false → true when beat2 begins, which is what the
    /// rows' stagger animates off. It must be a value that genuinely *changes* after the rows are
    /// on screen: the previous implementation keyed the stagger off `beatPhase.rawValue >= 2`,
    /// which was already true when the rows were first constructed, so `.animation(value:)` saw no
    /// change and every row appeared at once with the cascade silently dead.
    private(set) var rowsVisible: Bool = false

    /// True when the rows are arriving at their terminal state rather than performing — a
    /// tap-to-skip, Reduce Motion, or a couple who has nothing locked to gate. The rows read this
    /// to decide whether to cascade at all; it cannot be inferred from `heroRevealed`, because on
    /// the skip path that flag flips in the same runloop as the rows' first render.
    private(set) var skipsCeremony: Bool = false

    /// The pending auto-advance timer (held weakly inside; tracked here so a new sequence
    /// or an unlock can cancel a stale one). Never strongly retains the store.
    @ObservationIgnored private var autoAdvanceTask: Task<Void, Never>?

    // MARK: - Seen-stamp guards (review 2026-07-09 addendum)
    //
    // Stamps must reflect ACTUAL viewing — they gate future first-time-only ceremonies
    // (First Light / assemble). Stamping in load() would let a crash or back-out during
    // loading permanently skip the ceremony, so the stamps fire only when the user
    // reaches the corresponding beat. The flags dedupe repeat stamps within one session.

    @ObservationIgnored private var stampedFree = false
    @ObservationIgnored private var stampedFull = false

    /// One-shot guard so the unlock retry loop's repeated load() calls don't emit a
    /// spurious reveal_opened per attempt (payload rule aside, the funnel would lie).
    @ObservationIgnored private var loggedRevealOpened = false

    /// The user actually saw the free reveal (beat2, or any full viewing).
    private func stampFreeSeen() {
        guard !stampedFree, let coupleId = appState.coupleId else { return }
        stampedFree = true
        Task { try? await service.markRevealSeen(coupleId: coupleId, full: false) }
    }

    /// The user actually saw the full sky (.revealed). Seeing full implies seeing free.
    private func stampFullSeen() {
        stampFreeSeen()
        guard !stampedFull, let coupleId = appState.coupleId else { return }
        stampedFull = true
        Task { try? await service.markRevealSeen(coupleId: coupleId, full: true) }
    }

    /// beat1 → beat2, from either the tap or the timer: the free reveal has now truly
    /// been seen, so this is where the free stamp (and the funnel joint) lives.
    private func enterBeat2() {
        beatPhase = .beat2
        stampFreeSeen()
        FunnelEventService.shared.log(.beat2Reached, coupleId: appState.coupleId)
    }

    // MARK: - Interaction state (sheet hosts live inside the reveal cover)

    /// Set when the user taps a star — drives the detail sheet.
    var selectedMatch: RevealMatch?
    /// True while the full-map list sheet is open.
    var showFullMap: Bool = false
    /// True while the paywall sheet is open (tapped a locked star or the upgrade CTA).
    var showPaywall: Bool = false

    #if DEBUG
    /// Debug-only: force a specific ceremony variant. Production picks it by coupleId.
    var debugVariantOverride: CeremonyVariant?
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
    var lockedMatches: [RevealMatch] { matches.filter { $0.isLocked } }
    var lockedCount: Int { lockedMatches.count }
    var totalCount: Int { matches.count }

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
    ///
    /// The skip rule is server truth (review 2026-07-09 §1.2): if no row arrived locked
    /// — a Core couple, or a free couple whose ONLY match is the free one — there is
    /// nothing to gate, so land straight on the lit end-state, no ask, no gap. The store
    /// never consults entitlements here; the rows already encode the decision.
    /// (matches / lockedCount are populated by load() before .ready, which gates this call.)
    func startBeatSequence() {
        guard beatPhase == .idle else { return }
        if lockedCount == 0 {
            beatPhase = .revealed
            heroRevealed = true
            rowsVisible = true
            skipsCeremony = true
            // Landing straight on the lit sky is a full viewing — stamp it as one
            // (the addendum rule: stamps reflect actual viewing, at the beat, not at load).
            stampFullSeen()
        } else {
            beatPhase = .beat1
            scheduleAutoAdvance()
        }
    }

    /// Tap-to-advance: skip the whole beat-1 ceremony and land on its terminal state — rows in,
    /// free match open. Idempotent. Never trap someone in an animation they can't get out of;
    /// this is also the exact state Reduce Motion lands on, so the two share one definition.
    ///
    /// The ceremony rests at beat2 — there is no further auto-advance. The paywall (beat3) only
    /// opens from an explicit tap on a locked star (selectStar) or the Full Map/upgrade CTA, never
    /// from a timer or a generic tap-anywhere.
    func advanceBeat() {
        autoAdvanceTask?.cancel()   // a tap supersedes the current auto-timer; the user drives from here
        guard beatPhase == .beat1 || (beatPhase == .beat2 && !heroRevealed) else { return }
        skipsCeremony = true
        if beatPhase == .beat1 { enterBeat2() }
        rowsVisible = true
        heroRevealed = true
    }

    /// How long the beat-1 constellation ceremony runs: the star cascade, the hold, then the line
    /// draw rippling outward by MST depth. It scales with the match count and with the figure's own
    /// depth, so it cannot be a constant — which is why `desireBeatHold1` is now only the tail.
    private var ceremonyDuration: Double {
        let starCount = max(placedStars.count, 1)
        let edgeCount = layout.edges.count
        let cascade = Double(starCount - 1) * AppAnimation.desireStarCascadeStep
            + AppAnimation.desireStarBloomDuration
        // Per-LINE stagger now (see desireLineDrawStep): the last line starts at
        // (edgeCount - 1) × step, so the draw phase ends one full draw-duration after that.
        let draw = Double(max(edgeCount - 1, 0)) * AppAnimation.desireLineDrawStep
            + AppAnimation.desireLineDrawDuration
        return cascade + AppAnimation.desireHoldStarsToLines + draw + AppAnimation.desireBeatHold1
    }

    /// How long the locked rows take to finish cascading in, once beat2 begins.
    private var rowCascadeDuration: Double {
        let rows = max(min(lockedMatches.count, 4) + (heroMatch == nil ? 0 : 1), 1)
        return Double(rows - 1) * AppAnimation.desireBeatStaggerStep
            + AppAnimation.desireLockedRowEnterDuration
    }

    /// The beat-1 → beat-2 → first-reveal timeline. Runs the constellation ceremony, brings the
    /// rows in (all locked, the free one included), lets them settle, then opens the free match.
    /// [weak self]: a fire-and-forget timer must NOT keep the store alive past the reveal.
    /// A strong capture would release the store on a background executor when the Task ends
    /// (after the cover dismissed / in tests, after the case returned), routing the
    /// @MainActor isolated deinit through the wrong executor.
    private func scheduleAutoAdvance() {
        // Reduce Motion: no timed ceremony at all — land directly on the terminal state, the same
        // one a tap produces.
        guard !UIAccessibility.isReduceMotionEnabled else {
            skipsCeremony = true
            enterBeat2()
            rowsVisible = true
            heroRevealed = true
            return
        }
        let ceremony = ceremonyDuration
        let rowsSettle = rowCascadeDuration + AppAnimation.desireHoldRowsToReveal
        autoAdvanceTask?.cancel()
        autoAdvanceTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(ceremony))
            guard let self, beatPhase == .beat1 else { return }
            enterBeat2()
            rowsVisible = true
            try? await Task.sleep(for: .seconds(rowsSettle))
            guard !Task.isCancelled, beatPhase == .beat2 || beatPhase == .beat3 else { return }
            heroRevealed = true
        }
    }

    // MARK: - Load

    /// Fetch the couple's matches as the server chose to show them. Empty results branch
    /// three ways (review 2026-07-09 §1.4): unpaired, waiting on a partner, or — after the
    /// one-shot compute self-heal (§1.1) — a true zero.
    func load() async {
        guard let coupleId = appState.coupleId else { phase = .empty(.unpaired); return }
        phase = .loading
        do {
            let names = try itemNameMap()
            let categories = try itemCategoryMap()
            let meanings = try itemMeaningMap()

            let rows = try await service.fetchMatches(coupleId: coupleId)
            var mapped = mapRows(rows, names: names, categories: categories, meanings: meanings)

            if mapped.isEmpty {
                // Empty self-heal (§1.1): zero rows despite both maps complete means the
                // compute never fired (or drifted) — invoke it ONCE and refetch. Anything
                // else empty means someone hasn't finished yet.
                let status = try? await service.fetchStatus(coupleId: coupleId)
                guard status?.bothComplete == true else {
                    matches = []
                    phase = .empty(.waitingForPartner)
                    return
                }
                FunnelEventService.shared.log(.computeSelfHeal, coupleId: coupleId)
                _ = try? await service.computeMatches()
                let healedRows = (try? await service.fetchMatches(coupleId: coupleId)) ?? []
                mapped = mapRows(healedRows, names: names, categories: categories, meanings: meanings)
                if mapped.isEmpty {
                    matches = []
                    phase = .empty(.noMatches)
                    return
                }
            }

            matches = mapped
            phase = .ready
            // Seen-stamps intentionally NOT written here (addendum rule) — they fire at
            // the beats. This is only the funnel joint, deduped across the unlock retries.
            if !loggedRevealOpened {
                loggedRevealOpened = true
                FunnelEventService.shared.log(.revealOpened, coupleId: coupleId)
            }
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    /// Server rows → view models. Two guards:
    /// • Locked stubs (nil item id) become anonymous locked matches — the identity never
    ///   reached the client, only the (optional) teaser category.
    /// • Content-drift guard (addendum): an unlocked row whose item id isn't in the local
    ///   corpus is SKIPPED — never render a raw id slug in display type.
    private func mapRows(
        _ rows: [DesireMatchRow],
        names: [String: String],
        categories: [String: String],
        meanings: [String: [String: String]]
    ) -> [RevealMatch] {
        rows.compactMap { row in
            if row.isLockedStub {
                return RevealMatch(
                    id: row.id,
                    itemName: nil,
                    itemCategory: row.category,
                    alignment: nil,
                    isLocked: true,
                    bridgeCardId: nil,
                    isFreeReveal: false,
                    meaning: nil
                )
            }
            guard let itemId = row.desireItemId, let name = names[itemId] else { return nil }
            return RevealMatch(
                id: row.id,
                itemName: name,
                itemCategory: categories[itemId],
                alignment: row.matchType,                       // mutual / adjacent
                isLocked: false,                                // the server sent it named → it's visible
                bridgeCardId: row.bridgeCardId,
                isFreeReveal: row.isFreeReveal,                 // the server-set hero star
                meaning: row.matchType.flatMap { meanings[itemId]?[$0.rawValue] }
            )
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

    // MARK: - Sheet interaction

    /// Tap a star: unlocked → open detail sheet; locked → open paywall. A locked tap is the only
    /// path into beat3 — the paywall never auto-rises (see the beat-phase doc above).
    func selectStar(_ match: RevealMatch) {
        if match.isLocked {
            autoAdvanceTask?.cancel()
            if beatPhase == .beat2 { beatPhase = .beat3 }
            showPaywall = true
            FunnelEventService.shared.log(.paywallOpened, coupleId: appState.coupleId)
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

    /// Dismiss the paywall sheet only. Closing it rewinds beat3 → beat2 (review punch #13):
    /// beat3 means "paywall open", so a dismissed paywall must not strand the ceremony there.
    func closePaywall() {
        showPaywall = false
        if beatPhase == .beat3 { beatPhase = .beat2 }
    }

    /// Called by `PaywallSheet.onUnlocked` after the purchase has already succeeded.
    ///
    /// Unlock truth = SERVER tier (review 2026-07-09 §1.2 / decision #7): the ceremony
    /// transitions to .revealed only when a reload returns fully-unlocked rows. Until then
    /// `unlockPending` drives the "Payment received" interim state. The grant can lag the
    /// charge, so retry up to 3 times (refreshing entitlements between attempts). If all
    /// fail, unlockPending stays set — the next load / self-heal resolves it, and the grant
    /// itself auto-retries via Transaction.updates.
    func handleUnlockSuccess() {
        autoAdvanceTask?.cancel()
        showPaywall = false
        unlockPending = true
        #if DEBUG
        // Unpaired preview seam: no server to confirm against — flip everything open.
        if appState.coupleId == nil {
            matches = matches.map { RevealMatch(id: $0.id, itemName: $0.itemName, itemCategory: $0.itemCategory, alignment: $0.alignment, isLocked: false, bridgeCardId: $0.bridgeCardId, isFreeReveal: $0.isFreeReveal, meaning: $0.meaning) }
            beatPhase = .revealed
            heroRevealed = true
            rowsVisible = true
            unlockPending = false
            return
        }
        #endif
        // [weak self]: same executor rule as scheduleAutoAdvance — this loop sleeps for
        // seconds and must not keep the store alive past the reveal cover.
        Task { [weak self] in
            for attempt in 1...3 {
                guard let self else { return }
                await self.load()
                if !self.matches.isEmpty && self.lockedCount == 0 {
                    // Server confirmed Core: real named rows arrived for every match.
                    self.beatPhase = .revealed
                    self.heroRevealed = true
                    self.rowsVisible = true
                    self.unlockPending = false
                    self.stampFullSeen()
                    FunnelEventService.shared.log(.unlockRendered, coupleId: self.appState.coupleId)
                    return
                }
                FunnelEventService.shared.log(.grantRetried, coupleId: self.appState.coupleId, detail: "attempt \(attempt)")
                await self.entitlements.refresh()
                try? await Task.sleep(for: .seconds(2))
            }
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

/// One match as the reveal renders it. Carries NO raw answers or gap (the read path never
/// has them). `itemName == nil` means a LOCKED STUB — the server withheld the identity
/// (free couple, non-free match); only the optional teaser category arrived.
struct RevealMatch: Identifiable, Equatable {
    let id: UUID
    let itemName: String?               // nil = locked stub (identity never left the server)
    let itemCategory: String?           // e.g. "emotional", "sexual", "communication"
    let alignment: DesireMatchType?     // mutual ("Mutual") / adjacent ("Worth Exploring")
    let isLocked: Bool
    let bridgeCardId: String?
    /// The one server-set free reveal (the emotional-peak star). Drives the hero on the unlocked sky.
    var isFreeReveal: Bool = false
    /// Couple-framed reveal copy from desire_items.json (`DesireItem.meaning`), resolved for this
    /// match's alignment. Falls back to `celebration` when an item has no authored meaning yet.
    var meaning: String?

    /// The locked-row teaser line ("A shared desire · EMOTIONAL"). Honest about what the
    /// client actually knows: a category at most, never a blurred fake of a real name.
    var teaserTitle: String {
        if let itemCategory { return "A shared desire · \(itemCategory.uppercased())" }
        return "A shared desire"
    }

    /// Celebratory subtitle by alignment (mutual = wholehearted; adjacent = mostly aligned).
    /// Fallback for items without authored `meaning` copy.
    var celebration: String {
        switch alignment {
        case .mutual:   return "You're both excited about this."
        case .adjacent: return "You're mostly aligned here."
        case .none:     return "You share this."
        }
    }

    /// The line the detail views show: authored meaning when available, else the generic
    /// celebration. Only unlocked matches (real names) ever reach the detail surfaces.
    var displayMeaning: String { meaning ?? celebration }

    #if DEBUG
    static func sample(_ name: String, _ alignment: DesireMatchType, locked: Bool = false, free: Bool = false, category: String? = "emotional", meaning: String? = nil) -> RevealMatch {
        RevealMatch(id: UUID(), itemName: name, itemCategory: category, alignment: alignment, isLocked: locked, bridgeCardId: nil, isFreeReveal: free, meaning: meaning)
    }
    #endif
}
