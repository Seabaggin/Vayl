//
//  PlayStore.swift
//  Vayl — Play
//

import SwiftUI
import SwiftData

/// Where the featured deck stands for this couple, driving the continuity-aware hero
/// header. Resolved from real `DeckProgress` (never aspirational).
enum DeckContinuity: Equatable {
    case fresh                              // never opened, or not advanced past the first card
    case inProgress(index: Int, total: Int)
    case completed
}

// MARK: - Realtime seam (test injection)
//
// Minimal additive seam: PlayStore only ever calls these three methods on its
// injected RealtimeSessionService. Same pattern as SessionEntryRealtime /
// AirlockTransport — a small protocol so tests can fake the network.
protocol PlaySessionOpening: AnyObject {
    func openSession(coupleId: UUID, initiatorId: UUID, draft: CuratedSessionDraft) async throws -> CuratedSessionDTO
    func fetchOpenSession(coupleId: UUID) async throws -> CuratedSessionDTO?
    func setStatus(sessionId: UUID, status: CuratedSessionStatus) async throws
}

extension RealtimeSessionService: PlaySessionOpening {}

@Observable
@MainActor
final class PlayStore {

    // Catalog
    private(set) var summaries: [DeckSummary] = []
    private(set) var loadError: String?
    private(set) var featuredCards: [Card] = []   // the featured deck's cards, for the hero carousel
    private(set) var featuredContinuity: DeckContinuity = .fresh   // continuity read for the hero header

    // Dial
    var activeMode: PlayMode = .cards
    var enabledModes: [PlayMode] { PlayFeatureFlags.enabledModes }

    // Hero / wall / detail / ceremony / builder / lobby / session
    var featuredID: String?
    var detailID: String?
    /// The open detail's preview cards (first few real cards). Loaded by the
    /// store on openDetail — the view never touches DeckCatalogService.
    private(set) var detailPreviewCards: [Card] = []
    var ceremonyDeckID: String?
    /// Ceremony finished → the builder shapes tonight's plan for this deck.
    var builderDeck: Deck?
    /// Non-nil → present the session .vaylCover (lobby-first for remote sessions).
    var launch: SessionLaunch?
    var paywallDeck: DeckSummary?       // non-nil → present the Core paywall for this deck
    private(set) var openError: String?
    /// The (deck, plan) of a failed session open, kept so "Try again" can
    /// re-run it without the user rebuilding blind.
    private var failedOpen: (deck: Deck, plan: SessionPlan)?
    /// An existing active/paused row that blocks a NEW session from opening
    /// (the DB's one-open-per-couple index would reject the insert). The
    /// (deck, plan) the user just built is retained so "Start fresh" can
    /// re-run it once the conflict row is abandoned.
    private(set) var conflictSession: CuratedSessionDTO?
    private var conflictPending: (deck: Deck, plan: SessionPlan)?
    /// The conflict row's deck title, resolved for the confirmation dialog
    /// (catalog lookup, falls back to the raw deckId — same pattern as
    /// SessionEntryStore's pendingSession.deckTitle).
    var conflictDeckTitle: String? {
        guard let conflictSession else { return nil }
        return (try? catalog.loadSummaries())?.first { $0.id == conflictSession.deckId }?.title
            ?? conflictSession.deckId
    }
    /// One open at a time — a slow network must not allow a second ceremony
    /// or a duplicate lobby row.
    private(set) var isOpeningSession = false
    /// The local user's starred deck ids — the observable mirror of
    /// DeckUserState.starredByMe, so the star re-renders on toggle.
    private(set) var starredIDs: Set<String> = []

    // deps
    private let catalog: DeckCatalogService
    private let modelContainer: ModelContainer
    private let appState: AppState
    private let entitlements: EntitlementStore          // M3: the single Core gate
    private let realtime: PlaySessionOpening             // opens the lobby row
    private let pairing: PairingService                 // couple composition read (spec §9)
    private let coupleContext: CoupleContext            // partner identity (single source of truth)

    init(modelContainer: ModelContainer,
         appState: AppState,
         entitlements: EntitlementStore,
         coupleContext: CoupleContext,
         catalog: DeckCatalogService? = nil,
         realtime: PlaySessionOpening? = nil,
         pairing: PairingService? = nil) {
        self.modelContainer = modelContainer
        self.appState = appState
        self.entitlements = entitlements
        self.coupleContext = coupleContext
        // Construct the default services on the main actor (this init's isolation),
        // not in a nonisolated default-argument expression.
        self.catalog = catalog ?? DeckCatalogService()
        self.realtime = realtime ?? RealtimeSessionService()
        self.pairing = pairing ?? PairingService()
        load()
    }

    /// Live lock state: catalog flag AND not Core. One purchase flips
    /// entitlements.isCore and every gate below re-derives. Views call this,
    /// never summary.isLocked directly.
    func isLocked(_ summary: DeckSummary) -> Bool {
        summary.isLocked && !entitlements.isCore
    }

    /// StoreKit display price for the locked-detail CTA sub-line (nil until the
    /// product loads — the view falls back to the reference price).
    var corePriceText: String? { entitlements.corePriceText }

    func load() {
        do {
            var loaded = try catalog.loadSummaries()
            // Opener decks are personal: the forge revealed ONE of the four
            // (UserProfile.openerDeckType). The other three never appear on the
            // wall — a user has their forged deck, not a menu of forgeries.
            let mine = localProfile()?.openerDeckType.welcomeDeckId
            loaded.removeAll { OpenerDeckType.allWelcomeDeckIds.contains($0.id) && $0.id != mine }
            summaries = loaded
            loadError = nil
        } catch {
            summaries = []
            loadError = "Couldn't load decks."
        }
        resolveFeatured()
        loadFeatured()
        refreshComposition()
        refreshStars()
    }

    // MARK: - Connection composition (seam ruling 6)

    /// The couple's composition for card filtering. Hydrated from the local
    /// Couple mirror instantly (rows may not exist — nothing creates them
    /// locally), then the remote couples row. Defaults .flexible when unknown;
    /// never blocks the builder on a fetch.
    private(set) var composition: GenderDynamic = .flexible

    private func refreshComposition() {
        guard let coupleId = appState.coupleId else {
            composition = .flexible
            return
        }
        // Instant local mirror, if a Couple row happens to exist.
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<Couple>(predicate: #Predicate { $0.id == coupleId })
        if let couple = try? context.fetch(descriptor).first {
            composition = couple.connectionComposition
        }
        // Remote truth, best-effort — lands well before the builder opens.
        Task { @MainActor in
            if let remote = try? await pairing.fetchComposition(coupleId: coupleId) {
                composition = remote
            }
        }
    }

    /// Resume point for the builder: the featured/selected deck's
    /// DeckProgress.currentCardIndex, 0 when fresh or completed.
    private(set) var builderStartIndex: Int = 0

    private func resolveBuilderStartIndex(deckId: String) {
        let row = fetchProgress().first { $0.deckId == deckId }
        builderStartIndex = (row?.completedAt == nil) ? (row?.currentCardIndex ?? 0) : 0
    }

    /// Pick the featured deck (most-recently-played in-progress, else the
    /// user's forged opener deck until it's completed, else first available)
    /// and resolve its continuity, both from real `DeckProgress`.
    /// HomeStore's engaged-deck read follows the same rule — keep them in step.
    private func resolveFeatured() {
        let progress = fetchProgress()
        let availableIDs = Set(summaries.filter { !isLocked($0) }.map(\.id))   // playable = free OR Core-unlocked
        let engaged = FeaturedDeckRule.engagedDeckId(
            progress: progress,
            availableIDs: availableIDs,
            openerID: localProfile()?.openerDeckType.welcomeDeckId
        )
        // No locked fallback: with nothing playable the hero shows nothing —
        // a locked deck must never sit one tap from a session start.
        featuredID = engaged ?? summaries.first { !isLocked($0) }?.id
        featuredContinuity = continuity(forDeck: featuredID, in: progress)
    }

    /// All `DeckProgress` rows for the active couple (empty when solo / no couple yet).
    private func fetchProgress() -> [DeckProgress] {
        guard let coupleId = appState.coupleId else { return [] }
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<DeckProgress>(
            predicate: #Predicate { $0.coupleId == coupleId }
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Resolve where a deck stands from its `DeckProgress` row (fresh when none exists).
    private func continuity(forDeck id: String?, in progress: [DeckProgress]) -> DeckContinuity {
        guard let id,
              let total = summary(id)?.cardCount,
              let row = progress.first(where: { $0.deckId == id }) else { return .fresh }
        if row.completedAt != nil { return .completed }
        if row.currentCardIndex > 0 { return .inProgress(index: row.currentCardIndex, total: total) }
        return .fresh
    }

    /// Load the featured deck's full cards so the hero carousel shows real cards.
    private func loadFeatured() {
        guard let id = featuredID, let deck = try? catalog.loadDeck(id: id) else {
            featuredCards = []
            return
        }
        featuredCards = deck.orderedCards
    }

    // Derived
    func summary(_ id: String?) -> DeckSummary? { summaries.first { $0.id == id } }
    var featured: DeckSummary? { summary(featuredID) }
    func style(for s: DeckSummary) -> DeckStyle { DeckStyle.make(for: s) }

    /// True when there is nothing to show — a load failure (`loadError`) or an
    /// empty catalog. Drives the wall's empty/error state instead of a blank grid.
    var isEmpty: Bool { summaries.isEmpty }

    /// Re-attempt the catalog load (Retry from the empty/error state).
    func retry() { load() }

    /// Decks grouped into category clusters for the wall, ordered by spectrum position.
    var clusters: [(category: DeckCategory, decks: [DeckSummary])] {
        Dictionary(grouping: summaries, by: \.category)
            .map { ($0.key, $0.value.sorted { $0.title < $1.title }) }
            .sorted { $0.category.spectrumPosition < $1.category.spectrumPosition }
    }

    // Intent
    func setMode(_ m: PlayMode) { guard enabledModes.contains(m) else { return }; activeMode = m }

    func openDetail(_ id: String) {
        detailID = id
        // Store-owned preview load (the view never calls the catalog service).
        detailPreviewCards = Array(((try? catalog.loadDeck(id: id))?.orderedCards ?? []).prefix(5))
    }

    func closeDetail() {
        detailID = nil
        detailPreviewCards = []
    }

    /// Begin → play the open ceremony, which then hands the deck's cards to a
    /// session. THE entitlement gate for every session start: a locked deck
    /// routes to the paywall here, at the store, not only in a CTA branch.
    func beginCeremony(_ id: String) {
        guard !isOpeningSession else { return }
        if let summary = summary(id), isLocked(summary) {
            requestUnlock(summary)
            return
        }
        detailID = nil
        ceremonyDeckID = id
    }

    func ceremonyFinished() {
        // A live session cover (e.g. the joiner banner accepted mid-ceremony)
        // outranks the ceremony — never pop the builder under an active cover.
        guard launch == nil else { ceremonyDeckID = nil; return }
        guard let id = ceremonyDeckID, let deck = try? catalog.loadDeck(id: id) else {
            ceremonyDeckID = nil
            return
        }
        ceremonyDeckID = nil
        resolveBuilderStartIndex(deckId: deck.id)
        builderDeck = deck                    // SessionBuilderView presents (Seam B)
    }

    func cancelBuilder() { builderDeck = nil }

    /// SEAM B (assembler ruling 1): the builder hands back the Codable
    /// SessionPlan struct; the row snapshot is `plan.draft` at the openSession
    /// call site. Open the row, then present the lobby cover.
    func builderDidFinish(_ plan: SessionPlan) {
        guard let deck = builderDeck, !isOpeningSession else { return }
        builderDeck = nil
        openSession(deck: deck, plan: plan)
    }

    /// "Try again" on the failed-open banner — re-runs the exact plan the user
    /// built, no rebuilding blind.
    func retryOpen() {
        guard let failed = failedOpen, !isOpeningSession else { return }
        openSession(deck: failed.deck, plan: failed.plan)
    }

    func dismissOpenError() {
        openError = nil
        failedOpen = nil
    }

    private func openSession(deck: Deck, plan: SessionPlan) {
        openError = nil
        guard let coupleId = appState.coupleId, let myId = localProfileId() else {
            // Solo / unpaired: keep the local single-device path behind DEBUG only.
            #if DEBUG
            launch = SessionLaunch(hand: deck.orderedCards, entry: .localDebug,
                                   role: .a, session: nil)
            #endif
            return
        }
        let hand = plan.cardIds.compactMap { id in deck.orderedCards.first { $0.id == id } }
        let draft = plan.draft
        isOpeningSession = true
        Task { @MainActor in
            defer { isOpeningSession = false }
            do {
                // Self-heal: a lobby/airlock row I opened earlier and walked
                // away from would violate the one-open-session index and brick
                // every future open. Abandon it first; a partner-initiated
                // fresh row surfaces as the pending banner instead.
                if let existing = try? await realtime.fetchOpenSession(coupleId: coupleId) {
                    if existing.status == CuratedSessionStatus.lobby.rawValue
                        || existing.status == CuratedSessionStatus.airlock.rawValue,
                       existing.initiatorId == myId {
                        try? await realtime.setStatus(sessionId: existing.id, status: .abandoned)
                    } else if existing.status == CuratedSessionStatus.active.rawValue
                                || existing.status == CuratedSessionStatus.paused.rawValue {
                        // A genuinely unfinished couple session — inserting a new
                        // row would violate the one-open-per-couple index and
                        // dead-end on a generic error the user can never fix by
                        // retrying. Surface the conflict instead of attempting.
                        conflictSession = existing
                        conflictPending = (deck, plan)
                        return
                    }
                }
                let dto = try await realtime.openSession(
                    coupleId: coupleId, initiatorId: myId, draft: draft
                )
                failedOpen = nil
                launch = SessionLaunch(hand: hand, entry: .initiator,
                                       role: role(for: myId), session: dto)
            } catch {
                failedOpen = (deck, plan)
                openError = "Couldn't start the session. Try again."
            }
        }
    }

    // MARK: - Open-session conflict (spec §1.1: never dead-end on an existing row)

    /// "Resume" on the conflict dialog. Mirrors SessionEntryStore.resume():
    /// revalidate against the server first (the row may have ended between
    /// the conflict surfacing and this tap), rebuild the hand, then hand off
    /// to the existing launch → cover wiring (CoupleSessionStore.resumeIfNeeded
    /// picks the airlock-skip logic up from there).
    func resumeConflict() {
        guard let conflict = conflictSession, let coupleId = appState.coupleId else { return }
        Task { @MainActor in
            guard let dto = try? await realtime.fetchOpenSession(coupleId: coupleId),
                  dto.id == conflict.id,
                  dto.status == CuratedSessionStatus.active.rawValue
                    || dto.status == CuratedSessionStatus.paused.rawValue,
                  let deck = try? catalog.loadDeck(id: dto.deckId),
                  let myId = localProfileId()
            else {
                // The row resolved itself (partner ended it) — clear the
                // conflict and let the pending open the user actually asked
                // for proceed, rather than stranding them on a dead dialog.
                conflictSession = nil
                if let pending = conflictPending {
                    conflictPending = nil
                    openSession(deck: pending.deck, plan: pending.plan)
                }
                return
            }
            let hand = dto.cardIds.compactMap { id in deck.orderedCards.first { $0.id == id } }
            conflictSession = nil
            conflictPending = nil
            guard !hand.isEmpty else { return }
            launch = SessionLaunch(
                hand: hand,
                entry: dto.initiatorId == myId ? .initiator : .joiner,
                role: role(for: myId), session: dto
            )
        }
    }

    /// "Start fresh" on the conflict dialog: abandon the blocking row, then
    /// re-run the retained plan. If the insert still fails (a race), the
    /// existing openError/retryOpen banner remains the fallback.
    func startFreshFromConflict() {
        guard let conflict = conflictSession, let pending = conflictPending else { return }
        conflictSession = nil
        conflictPending = nil
        Task { @MainActor in
            try? await realtime.setStatus(sessionId: conflict.id, status: .abandoned)
            openSession(deck: pending.deck, plan: pending.plan)
        }
    }

    /// "Cancel" on the conflict dialog: drop the conflict and the retained
    /// plan, no error shown — the user simply didn't want either option.
    func cancelConflict() {
        conflictSession = nil
        conflictPending = nil
    }

    func endSession() { launch = nil }

    /// SessionRole identity rule (spec 4.2, hard): derives from the local Couple
    /// row's partnerAId vs my LOCAL profile id. Never the supabase auth id.
    private func role(for profileId: UUID) -> SessionRole {
        let context = ModelContext(modelContainer)
        guard let coupleId = appState.coupleId else { return .a }
        var fetch = FetchDescriptor<Couple>(predicate: #Predicate { $0.id == coupleId })
        fetch.fetchLimit = 1
        guard let couple = try? context.fetch(fetch).first else { return .a }
        return couple.partnerAId == profileId ? .a : .b
    }

    /// The local SwiftData profile id (auth-id vs profile-id convention: this is
    /// the PROFILE id, which is what couples rows reference).
    private func localProfileId() -> UUID? { localProfile()?.id }

    /// The local SwiftData profile row (single-profile device convention).
    private func localProfile() -> UserProfile? {
        let context = ModelContext(modelContainer)
        var fetch = FetchDescriptor<UserProfile>()
        fetch.fetchLimit = 1
        return try? context.fetch(fetch).first
    }

    /// Locked deck → open the Core paywall (closes the detail first).
    func requestUnlock(_ deck: DeckSummary) { detailID = nil; paywallDeck = deck }
    func dismissPaywall() { paywallDeck = nil }

    // MARK: - Star state

    /// All `DeckUserState` rows for the active couple (empty when solo / no couple yet).
    private func fetchUserStates() -> [DeckUserState] {
        guard let coupleId = appState.coupleId else { return [] }
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<DeckUserState>(
            predicate: #Predicate { $0.coupleId == coupleId }
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Whether the local user has starred this deck (observable cache — a
    /// plain SwiftData fetch here would never invalidate the calling view).
    func isStarredByMe(_ deck: DeckSummary) -> Bool {
        starredIDs.contains(deck.id)
    }

    /// Whether starring is possible at all (needs a couple to hang the row on).
    var canStar: Bool { appState.coupleId != nil }

    private func refreshStars() {
        starredIDs = Set(fetchUserStates().filter(\.starredByMe).map(\.deckId))
    }

    /// Whether the partner has starred this deck. Real-time partner sync is a
    /// follow-up task — always false until that lands.
    func isStarredByPartner(_ deck: DeckSummary) -> Bool { false }

    /// The partner's display name for the "Starred by X" label.
    var partnerName: String? { coupleContext.partnerName }

    /// Toggle the local user's star on a deck. Writes to SwiftData immediately
    /// and mirrors into the observable cache so the view re-renders.
    func toggleStar(_ deck: DeckSummary) {
        guard let coupleId = appState.coupleId else { return }
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<DeckUserState>(
            predicate: #Predicate { $0.coupleId == coupleId && $0.deckId == deck.id }
        )
        let nowStarred: Bool
        if let existing = try? context.fetch(descriptor).first {
            existing.starredByMe.toggle()
            nowStarred = existing.starredByMe
        } else {
            let row = DeckUserState(deckId: deck.id, coupleId: coupleId)
            row.starredByMe = true
            context.insert(row)
            nowStarred = true
        }
        try? context.save()
        if nowStarred { starredIDs.insert(deck.id) } else { starredIDs.remove(deck.id) }
    }

    // MARK: - Last played

    /// The most recent completion date for this deck, or nil if never played.
    func lastPlayed(_ deck: DeckSummary) -> Date? {
        fetchProgress().first { $0.deckId == deck.id }?.completedAt
    }

    // MARK: - Start deck

    /// Sets this deck as the active featured deck, then triggers the ceremony
    /// (which itself closes the detail overlay via `beginCeremony`). Locked
    /// decks route to the paywall inside `beginCeremony` — the hero is only
    /// switched for a start that actually proceeds.
    func startDeck(_ deck: DeckSummary) {
        if isLocked(deck) {
            requestUnlock(deck)
            return
        }
        featuredID = deck.id
        featuredContinuity = continuity(forDeck: deck.id, in: fetchProgress())
        loadFeatured()
        beginCeremony(deck.id)
    }
}

#if DEBUG
extension PlayStore {
    /// In-memory store for SwiftUI previews (loads the bundled catalog).
    @MainActor static var preview: PlayStore {
        let appState = AppState()
        let entitlements = EntitlementStore(modelContainer: .previewContainer, appState: appState)
        return PlayStore(
            modelContainer: .previewContainer,
            appState: appState,
            entitlements: entitlements,
            coupleContext: CoupleContext(
                appState: appState,
                entitlements: entitlements,
                modelContainer: .previewContainer
            )
        )
    }
}
#endif
