//
//  HomeStore.swift
//  Vayl
//
//  Brain of the Home flow.
//  Owns all routing state, deck loading, and map completion tracking.
//  The view renders. The store decides.
//
//  Dependencies injected via init — never from @Environment.
//  ModelContext created fresh at write time — never stored on self.
//

import SwiftUI
import SwiftData
import OSLog

private let logger = Logger(
    subsystem: "com.vayl.app",
    category: "HomeStore"
)

@Observable
@MainActor
final class HomeStore {

    // MARK: - Routing State

    /// The single computed state that drives all routing in HomeRouterView.
    /// View reads this. View never writes this.
    var homeState: HomeState { resolveHomeState() }

    /// The post-onboarding "first steps" activation, derived from the same flags as `homeState`.
    var gettingStarted: GettingStarted {
        GettingStarted.resolve(
            myMapComplete: myMapComplete,
            isPaired: isPaired,
            partnerMapComplete: partnerMapComplete,
            revealDone: revealDone
        )
    }

    // MARK: - Map Completion

    var myMapComplete: Bool = false
    var partnerMapComplete: Bool = false
    var revealDone: Bool = false
    var postReflectionDone: Bool = false
    var reflectionStep: Int = 1

    /// Partner identity — read from the couple-fact single source of truth.
    /// (The old stored copy here had NO production writer — only a DEBUG seed —
    /// so release builds rendered "your partner" everywhere. 2026-07-04 audit F1.)
    var partnerName: String? { couple.partnerName }

    /// One-shot: set when the user just completed their Desire Map in the rater they closed.
    /// The dashboard plays a brief completion beat once, then clears it — the map is a moment,
    /// never a persistent home state.
    var showCompletionBeat: Bool = false

    /// How long an invite can sit unclaimed before the chip shifts from quiet
    /// "invite pending" to the warmer "nudge" tone. Matches the approved
    /// tap-to-expand design (docs/superpowers/specs/2026-07-05-partner-chip-and-pairing-design.md).
    private static let nudgeThreshold: TimeInterval = 3 * 24 * 60 * 60 // 3 days

    private(set) var firstInviteSentAt: Date?

    /// Partner's current Pulse position, for the chip's quick-view tile only
    /// (current position, not history — the 30-day grid stays exclusive to Map).
    /// Nil if the partner hasn't logged, or has `share_pulse_with_partner` off.
    private(set) var partnerPulsePosition: PulsePosition?

    /// True when the last partner-pulse fetch failed outright (offline, server
    /// error) — distinct from a nil position, which means confirmed no data
    /// (sharing off or never logged). The chip copy uses this to avoid claiming
    /// "Not sharing" when the truth is "couldn't reach it."
    private(set) var partnerPulseFetchFailed: Bool = false

    // MARK: - Deck Loading

    var deck: Deck?
    var deckLoadError: String?
    var isLoadingDeck: Bool = false

    /// The deck Home leads with — the couple's most-recently-played deck, resolved
    /// from DeckProgress.lastPlayedAt. Falls back to the opener for a fresh couple.
    private var recentDeckId: String = "the-opener"

    // MARK: - Dashboard Data

    /// Cards completed in the active deck — derived from DeckProgress.
    /// Zero until DeckProgress exists for this couple and deck.
    var cardsCompleted: Int = 0

    /// Stage index — hardcoded to 1 until Stage model exists.
    /// TODO: wire from Stage model when built.
    var stageIndex: Int = 1

    /// Desire map state — derived from UserProfile and link state.
    var desireMapState: DesireMapState = .hidden

    /// Reflection card state — derived from most recent CardSession.
    var reflectionCardState: ReflectionCardState = .hidden

    // MARK: - Lexicon (Home "Today") content

    /// Server-overridden daily-5 content, fetched once per Home load. Nil → HomeLexicon
    /// uses its bundled baseline. Owned here so the view never calls ContentService (H-2).
    var lexiconRemotePool: LexiconRemotePool?

    // MARK: - Dependencies

    private let modelContainer: ModelContainer
    private let appState: AppState
    private let couple: CoupleContext
    private let pulseSync: PulseSyncService
    private let content: ContentService
    private let desireSync: DesireSyncService
    private let deckCatalog: DeckCatalogService

    // MARK: - Init

    /// Service params nil-resolve inside the MainActor-isolated body — a `= .shared`
    /// default argument would evaluate in a nonisolated context and not compile
    /// (same pattern as SettingsStore).
    init(
        modelContainer: ModelContainer,
        appState: AppState,
        couple: CoupleContext,
        pulseSync: PulseSyncService? = nil,
        content: ContentService? = nil,
        desireSync: DesireSyncService? = nil,
        deckCatalog: DeckCatalogService? = nil
    ) {
        self.modelContainer = modelContainer
        self.appState = appState
        self.couple = couple
        self.pulseSync = pulseSync ?? .shared
        self.content = content ?? .shared
        self.desireSync = desireSync ?? .shared
        self.deckCatalog = deckCatalog ?? DeckCatalogService()

        #if DEBUG
        // Development quick-jump — skip to dashboard state.
        // Production always starts at false. (Partner name is no longer seeded
        // here — CoupleContext owns the one debug fallback.)
        self.myMapComplete = true
        self.partnerMapComplete = true
        self.revealDone = true
        self.postReflectionDone = true
        #endif
    }

    // MARK: - Derived

    var isPaired: Bool {
        appState.appMode == .together
    }

    var isSolo: Bool {
        appState.appMode == .solo
    }

    // Note: this reads Date() directly, which @Observable doesn't track — the
    // UI won't re-render purely because wall-clock time crosses the threshold
    // while the app sits idle in foreground. In practice Home re-renders often
    // enough via other state changes that this is an accepted staleness window,
    // not a bug.
    var partnerChipState: PartnerChipState {
        switch appState.linkState {
        case .linked:
            if let name = partnerName, !name.isEmpty {
                return .active(name: name, initial: String(name.prefix(1)).uppercased())
            }
            return .invitePending
        case .unlinked:
            guard isPaired else { return .none }
            if let sentAt = firstInviteSentAt,
               Date().timeIntervalSince(sentAt) >= Self.nudgeThreshold {
                return .nudge
            }
            return .invitePending
        }
    }

    // MARK: - Routing

    /// Resolves the current HomeState from completion flags.
    /// Each guard gates the next state — order is intentional.
    private func resolveHomeState() -> HomeState {
        // Home ALWAYS leads with the card dashboard — the deck is the premiere product; the
        // Desire Map is secondary and must never gate Home. The post-map progression (your turn →
        // waiting on partner → reveal-ready) is surfaced quietly in the Getting Started path and a
        // one-shot completion beat — not as a full-screen takeover. The reveal itself stays
        // reachable via the Getting Started `seeReveal` step (gated on both maps, inherently).
        // Home always leads with the dashboard. `.gated` is vestigial (renders the dashboard);
        // `.postReflection/.waiting/.matchReady` are removed — "waiting on your partner" is driven
        // by the Getting Started tracker + partner pill, and the both-complete celebration is a
        // separate screen (Segment 3).
        if isSolo && appState.linkState == .unlinked { return .soloUnpaired }
        return .dashboard
    }

    /// Whether a given tab should be locked in the current home state.
    func isTabLocked(_ tab: AppTab) -> Bool {
        switch homeState {
        case .dashboard:
            return false
        case .soloUnpaired:
            return tab == .map   // starter deck (play) reachable; Desire Map locked until paired
        default:
            return tab == .play || tab == .map
        }
    }

    // MARK: - Rater-dismiss outcome (audit Blueprint C — the fork lives HERE, testable)

    /// What Home does after the Desire rater closes. One owner for the
    /// reveal-vs-celebration-vs-nothing decision (the router previously ran this
    /// branch itself, duplicating flow knowledge DesireMapView also derived).
    enum RaterDismissOutcome {
        case showReveal            // both maps done, reveal unseen → hand off to the reveal
        case celebrateCompletion   // just finished, partner pending → one-shot charted beat
        case none
    }

    /// Refreshes Home state, then resolves the post-rater branch.
    /// `wasCompleteOnOpen`: whether the user's map was already complete when the
    /// rater opened — distinguishes a fresh completion from a re-visit.
    func raterDismissOutcome(wasCompleteOnOpen: Bool) async -> RaterDismissOutcome {
        await loadAll()
        guard myMapComplete else { return .none }
        if partnerMapComplete, !revealDone { return .showReveal }
        if !wasCompleteOnOpen, isPaired { return .celebrateCompletion }
        return .none
    }

    // MARK: - Actions

    func markPostReflectionDone() {
        postReflectionDone = true
    }

    /// Trigger the one-shot map-completion beat (called by the router when the rater the user
    /// just closed flipped the map false → true).
    func celebrateMapCompletion() {
        showCompletionBeat = true
    }

    func dismissCompletionBeat() {
        showCompletionBeat = false
    }

    func advanceReflectionStep() {
        reflectionStep += 1
    }

    // MARK: - Load

    /// Loads all data the home screen depends on in one pass.
    /// Call once on appear from HomeRouterView.
    func loadAll() async {
        await couple.refreshIfNeeded()   // partner identity (no-op once loaded)
        await loadProfile()
        await loadDesireStatus()
        await loadPartnerPulsePosition()
        await refreshDeckState()
        await loadLexiconContent()
    }

    /// The deck-facing slice of loadAll — cheap enough to re-run when a session
    /// cover dismisses on Home or the app returns to foreground, so the hero
    /// reflects tonight's play without a tab switch.
    func refreshDeckState() async {
        resolveRecentDeck()
        await loadDeckProgress()
        await loadReflectionState()
        await loadDeck()
    }

    // MARK: - Partner Pulse Load

    /// Reads the partner's current Pulse position via PulseSyncService directly —
    /// Store-to-Store coupling across features (going through MapStore) is what
    /// the architecture rules forbid; Store->Service is fine. Gating (couple
    /// membership + the partner's own share_pulse_with_partner flag) is enforced
    /// server-side by get_partner_pulse_positions(), never here.
    func loadPartnerPulsePosition() async {
        guard case .linked = appState.linkState else {
            partnerPulsePosition = nil
            partnerPulseFetchFailed = false
            return
        }
        switch await pulseSync.fetchPartnerEntries() {
        case .success(let entries):
            partnerPulseFetchFailed = false
            partnerPulsePosition = entries.last?.resolvedPosition
        case .failure:
            partnerPulseFetchFailed = true
            logger.error("HomeStore: partner pulse fetch failed — keeping cached position")
        }
    }

    // MARK: - Lexicon Content Load

    /// Fetches server-driven daily-5 content. Best-effort — leaves lexiconRemotePool nil on
    /// any failure so HomeLexicon keeps its bundled baseline.
    private func loadLexiconContent() async {
        let f = await content.fetchFindings()
        let t = await content.fetchGlossary()
        let q = await content.fetchQuotes()
        if f != nil || t != nil || q != nil {
            lexiconRemotePool = LexiconRemotePool(findings: f, terms: t, quotes: q)
        } else {
            logger.error("HomeStore: lexicon content fetch failed — keeping bundled baseline")
        }
    }

    // MARK: - Recent Deck

    /// Picks the couple's engaged deck via the SAME rule Play's hero uses
    /// (FeaturedDeckRule) — the two surfaces must never hero different decks.
    /// Entitlement-filtered: Home never serves a locked deck's cards, even
    /// after a downgrade. Falls back to the opener when there's no history.
    private func resolveRecentDeck() {
        guard let coupleId = appState.coupleId else { return }
        let context = ModelContext(modelContainer)
        do {
            let all = try context.fetch(FetchDescriptor<DeckProgress>(
                predicate: #Predicate { $0.coupleId == coupleId }
            ))
            let summaries = (try? deckCatalog.loadSummaries()) ?? []
            let availableIDs = Set(
                summaries.filter { !$0.isLocked || couple.canRevealAll }.map(\.id)
            )
            var profileFetch = FetchDescriptor<UserProfile>()
            profileFetch.fetchLimit = 1
            let openerID = (try? context.fetch(profileFetch).first)?
                .openerDeckType.welcomeDeckId
            if let engaged = FeaturedDeckRule.engagedDeckId(
                progress: all, availableIDs: availableIDs, openerID: openerID
            ) {
                recentDeckId = engaged
                logger.info("HomeStore: engaged deck = \(engaged)")
            }
        } catch {
            logger.error("HomeStore: recent deck resolve failed — \(error.localizedDescription)")
        }
    }

    // MARK: - Desire Status Load (D-read)

    /// Reads the couple's `desire_map_status` to drive the waiting → match-ready flow.
    /// `partnerMapComplete` is derived from `bothComplete` — we only reach the partner gate
    /// once our own map is done, so `bothComplete` equals the partner's completion at that point.
    private func loadDesireStatus() async {
        guard appState.appMode == .together, let coupleId = appState.coupleId else { return }
        let status: DesireMapStatusRow?
        do {
            status = try await desireSync.fetchStatus(coupleId: coupleId)
        } catch {
            logger.error("HomeStore: desire status fetch failed — \(error.localizedDescription)")
            return
        }
        guard let status else { return }
        partnerMapComplete = status.bothComplete
        do {
            let progress = try await desireSync.fetchRevealProgress(coupleId: coupleId)
            revealDone = progress?.hasSeenFree ?? false
        } catch {
            logger.error("HomeStore: reveal progress fetch failed — \(error.localizedDescription)")
            revealDone = false
        }
        resolvePostStatusDesireMapState(coupleId: coupleId)
    }

    /// Refines desireMapState after server status is known (partner completion + reveal progress).
    /// Called at the end of loadDesireStatus, after revealDone and partnerMapComplete are set.
    /// The initial state from loadProfile/resolveDesireMapState is still useful as a fast-path
    /// before the server responds.
    private func resolvePostStatusDesireMapState(coupleId: UUID) {
        guard isPaired else { return }
        // THE gate rule (CoupleContext.canRevealAll = OR'd entitlement). The old
        // read here used the local Couple.canRevealDesireMap mirror — the exact
        // lagging rule MapStore/VaultStore already distrusted, so a just-purchased
        // buyer saw Map/Vault unlocked while Home stayed on the pre-purchase branch.
        let canReveal = couple.canRevealAll

        if !myMapComplete { desireMapState = .yourTurn; return }
        if canReveal { desireMapState = .fullyUnlocked; return }
        if revealDone { desireMapState = .freeRevealSeen(matchCount: 0); return }
        if partnerMapComplete { desireMapState = .bothReady; return }
        desireMapState = .youDone(partnerName: partnerName ?? "your partner")
    }

    // MARK: - Profile Load

    /// Reads UserProfile to resolve map completion and desire map state.
    /// Internal (not private) specifically so @testable import Vayl can call it
    /// directly in tests without triggering loadAll()'s network-touching siblings
    /// (loadLexiconContent() in particular has no offline guard).
    func loadProfile() async {
        let context = ModelContext(modelContainer)

        do {
            let descriptor = FetchDescriptor<UserProfile>()
            let profiles = try context.fetch(descriptor)

            guard let profile = profiles.first else {
                logger.info("HomeStore: no UserProfile found — staying at defaults")
                return
            }

            myMapComplete = profile.hasCompletedDesireMap
            firstInviteSentAt = profile.firstInviteSentAt
            desireMapState = resolveDesireMapState(from: profile)

            logger.info("HomeStore: profile loaded — mapComplete: \(profile.hasCompletedDesireMap)")

        } catch {
            logger.error("HomeStore: profile load failed — \(error.localizedDescription)")
        }
    }

    /// Derives DesireMapState from UserProfile fields and current link state.
    private func resolveDesireMapState(from profile: UserProfile) -> DesireMapState {
        guard isPaired else { return .hidden }

        switch appState.linkState {
        case .unlinked:
            return profile.hasCompletedDesireMap ? .youDone(partnerName: "your partner") : .yourTurn
        case .linked:
            if !profile.hasCompletedDesireMap { return .yourTurn }
            // Conservative fast-path: the partner's completion is not known until the server
            // resolve (resolvePostStatusDesireMapState) runs a hop later. Show "waiting" rather
            // than optimistically flashing "both ready" — the server resolve upgrades to
            // .bothReady / .fullyUnlocked once it confirms.
            return .youDone(partnerName: partnerName ?? "your partner")
        }
    }

    // MARK: - Deck Progress Load

    /// Reads DeckProgress to resolve cardsCompleted for the active deck.
    private func loadDeckProgress() async {
        guard let coupleId = appState.coupleId else {
            logger.info("HomeStore: no coupleId — skipping DeckProgress fetch")
            return
        }

        let context = ModelContext(modelContainer)
        let deckId = recentDeckId

        do {
            var descriptor = FetchDescriptor<DeckProgress>(
                predicate: #Predicate { $0.coupleId == coupleId && $0.deckId == deckId }
            )
            descriptor.fetchLimit = 1
            let results = try context.fetch(descriptor)

            if let progress = results.first {
                cardsCompleted = progress.currentCardIndex
                logger.info("HomeStore: DeckProgress loaded — cardsCompleted: \(progress.currentCardIndex)")
            }

        } catch {
            logger.error("HomeStore: DeckProgress load failed — \(error.localizedDescription)")
        }
    }

    // MARK: - Reflection State Load

    /// Reads the most recent completed CardSession to derive reflectionCardState.
    private func loadReflectionState() async {
        guard let coupleId = appState.coupleId else {
            logger.info("HomeStore: no coupleId — skipping CardSession fetch")
            return
        }

        let context = ModelContext(modelContainer)

        do {
            var descriptor = FetchDescriptor<CardSession>(
                predicate: #Predicate { $0.coupleId == coupleId },
                sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
            )
            descriptor.fetchLimit = 1
            let sessions = try context.fetch(descriptor)

            guard let session = sessions.first,
                  session.completedAt != nil else {
                reflectionCardState = .hidden
                return
            }

            // Session exists and is complete — surface pending reflection.
            // sessionLabel derived from deckId until Deck model has a title lookup.
            // TODO: resolve human-readable deck title from ContentLoader.
            let label = "Session \(session.sessionNumber)"
            reflectionCardState = .pendingYours(
                sessionLabel: label,
                sessionDate: session.completedAt ?? session.startedAt
            )

            logger.info("HomeStore: reflection state — pendingYours for session \(session.sessionNumber)")

        } catch {
            logger.error("HomeStore: CardSession load failed — \(error.localizedDescription)")
        }
    }

    // MARK: - Deck Loading

    func loadDeck() async {
        guard !isLoadingDeck else { return }
        isLoadingDeck = true
        deckLoadError = nil

        do {
            let loaded = try ContentLoader.loadDeck(id: recentDeckId)
            deck = loaded
            logger.info("HomeStore: deck loaded — \(loaded.id)")
        } catch {
            // Recent deck couldn't be loaded — fall back to the opener.
            if recentDeckId != "the-opener", let fallback = try? ContentLoader.loadDeck(id: "the-opener") {
                recentDeckId = "the-opener"
                deck = fallback
                logger.info("HomeStore: recent deck failed, fell back to the-opener")
            } else {
                deckLoadError = error.localizedDescription
                logger.error("HomeStore: deck load failed — \(error.localizedDescription)")
            }
        }

        isLoadingDeck = false
    }
}

// MARK: - LexiconRemotePool

/// The three server content arrays HomeLexicon needs to rebuild its pool. Nil arrays mean
/// "no server override for this kind"; the view falls back to bundled JSON per kind.
struct LexiconRemotePool {
    let findings: [ResearchFinding]?
    let terms: [LexiconTerm]?
    let quotes: [MediaQuote]?
}
