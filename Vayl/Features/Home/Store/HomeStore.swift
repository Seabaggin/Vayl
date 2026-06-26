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
    var partnerName: String? = nil
    var reflectionStep: Int = 1

    /// One-shot: set when the user just completed their Desire Map in the rater they closed.
    /// The dashboard plays a brief completion beat once, then clears it — the map is a moment,
    /// never a persistent home state.
    var showCompletionBeat: Bool = false

    // MARK: - Deck Loading

    var deck: Deck? = nil
    var deckLoadError: String? = nil
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

    // MARK: - Dependencies

    private let modelContainer: ModelContainer
    private let appState: AppState

    // MARK: - Init

    init(modelContainer: ModelContainer, appState: AppState) {
        self.modelContainer = modelContainer
        self.appState = appState

        #if DEBUG
        // Development quick-jump — skip to dashboard state.
        // Production always starts at false.
        self.myMapComplete = true
        self.partnerMapComplete = true
        self.revealDone = true
        self.postReflectionDone = true
        self.partnerName = "Alex"
        #endif
    }

    // MARK: - Derived

    var isPaired: Bool {
        appState.appMode == .together
    }

    var isSolo: Bool {
        appState.appMode == .solo
    }

    var partnerChipState: PartnerChipState {
        switch appState.linkState {
        case .linked:
            if let name = partnerName, !name.isEmpty {
                return .active(name: name, initial: String(name.prefix(1)).uppercased())
            }
            return .invitePending
        case .unlinked:
            return isPaired ? .invitePending : .none
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
        await loadProfile()
        await loadDesireStatus()
        resolveRecentDeck()
        await loadDeckProgress()
        await loadReflectionState()
        await loadDeck()
    }

    // MARK: - Recent Deck

    /// Picks the couple's most-recently-played deck (by lastPlayedAt, then firstOpenedAt).
    /// Leaves `recentDeckId` at the opener default when there's no history.
    private func resolveRecentDeck() {
        guard let coupleId = appState.coupleId else { return }
        let context = ModelContext(modelContainer)
        do {
            let all = try context.fetch(FetchDescriptor<DeckProgress>(
                predicate: #Predicate { $0.coupleId == coupleId }
            ))
            let recent = all.max {
                ($0.lastPlayedAt ?? $0.firstOpenedAt ?? .distantPast) <
                ($1.lastPlayedAt ?? $1.firstOpenedAt ?? .distantPast)
            }
            if let recent, !recent.deckId.isEmpty, recent.lastPlayedAt != nil {
                recentDeckId = recent.deckId
                logger.info("HomeStore: recent deck = \(recent.deckId)")
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
        guard let status = try? await DesireSyncService.shared.fetchStatus(coupleId: coupleId) else { return }
        partnerMapComplete = status.bothComplete
        let progress = try? await DesireSyncService.shared.fetchRevealProgress(coupleId: coupleId)
        revealDone = progress?.hasSeenFree ?? false
        resolvePostStatusDesireMapState(coupleId: coupleId)
    }

    /// Refines desireMapState after server status is known (partner completion + reveal progress).
    /// Called at the end of loadDesireStatus, after revealDone and partnerMapComplete are set.
    /// The initial state from loadProfile/resolveDesireMapState is still useful as a fast-path
    /// before the server responds.
    private func resolvePostStatusDesireMapState(coupleId: UUID) {
        guard isPaired else { return }
        let context = ModelContext(modelContainer)
        let canReveal = (try? context.fetch(
            FetchDescriptor<Couple>(predicate: #Predicate { $0.id == coupleId })
        ).first)?.canRevealDesireMap ?? false

        if !myMapComplete { desireMapState = .yourTurn; return }
        if canReveal { desireMapState = .fullyUnlocked; return }
        if revealDone { desireMapState = .freeRevealSeen(matchCount: 0); return }
        if partnerMapComplete { desireMapState = .bothReady; return }
        desireMapState = .youDone(partnerName: partnerName ?? "your partner")
    }

    // MARK: - Profile Load

    /// Reads UserProfile to resolve map completion and desire map state.
    private func loadProfile() async {
        let context = ModelContext(modelContainer)

        do {
            let descriptor = FetchDescriptor<UserProfile>()
            let profiles = try context.fetch(descriptor)

            guard let profile = profiles.first else {
                logger.info("HomeStore: no UserProfile found — staying at defaults")
                return
            }

            myMapComplete = profile.hasCompletedDesireMap
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
            // Partner completion is not yet tracked locally —
            // TODO: read partner status from Couple record when sync layer exists.
            // For now surface bothReady when this user is done and linked.
            return .bothReady
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
