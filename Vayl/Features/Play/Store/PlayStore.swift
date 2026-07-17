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
    var ceremonyDeckID: String?
    /// Ceremony finished → the builder shapes tonight's plan for this deck.
    var builderDeck: Deck?
    /// Non-nil → present the session .vaylCover (lobby-first for remote sessions).
    var launch: SessionLaunch?
    var paywallDeck: DeckSummary?       // non-nil → present the Core paywall for this deck
    private(set) var openError: String?

    // deps
    private let catalog: DeckCatalogService
    private let modelContainer: ModelContainer
    private let appState: AppState
    private let entitlements: EntitlementStore          // M3: the single Core gate
    private let realtime: RealtimeSessionService        // opens the lobby row
    private let pairing: PairingService                 // couple composition read (spec §9)

    init(modelContainer: ModelContainer,
         appState: AppState,
         entitlements: EntitlementStore,
         catalog: DeckCatalogService? = nil,
         realtime: RealtimeSessionService? = nil,
         pairing: PairingService? = nil) {
        self.modelContainer = modelContainer
        self.appState = appState
        self.entitlements = entitlements
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

    /// Pick the featured deck (most-recent in-progress, else the user's forged
    /// opener deck until it's completed, else first available) and resolve its
    /// continuity, both from real `DeckProgress`. Mirrors `HomeStore.loadDeckProgress`.
    /// "Most-recent" means most-recently-opened: `DeckProgress` has no last-touched stamp yet.
    private func resolveFeatured() {
        let progress = fetchProgress()
        let availableIDs = Set(summaries.filter { !isLocked($0) }.map(\.id))   // playable = free OR Core-unlocked
        let recentInProgress = progress
            .filter { availableIDs.contains($0.deckId) && $0.completedAt == nil && $0.currentCardIndex > 0 }
            .max { ($0.firstOpenedAt ?? .distantPast) < ($1.firstOpenedAt ?? .distantPast) }
        // The OB forge's promise lands here: with nothing in progress, the hero
        // is the deck the ceremony revealed — until the user completes it, after
        // which normal recency takes over.
        let openerID: String? = {
            guard let id = localProfile()?.openerDeckType.welcomeDeckId,
                  availableIDs.contains(id),
                  !progress.contains(where: { $0.deckId == id && $0.completedAt != nil })
            else { return nil }
            return id
        }()
        let fallback = openerID ?? summaries.first { !isLocked($0) }?.id ?? summaries.first?.id
        featuredID = recentInProgress?.deckId ?? fallback
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
    func openDetail(_ id: String) { detailID = id }
    func closeDetail() { detailID = nil }

    /// Begin → play the open ceremony, which then hands the deck's cards to a session.
    func beginCeremony(_ id: String) { detailID = nil; ceremonyDeckID = id }

    func ceremonyFinished() {
        guard let id = ceremonyDeckID, let deck = try? catalog.loadDeck(id: id) else {
            ceremonyDeckID = nil
            return
        }
        ceremonyDeckID = nil
        resolveBuilderStartIndex(deckId: deck.id)
        builderDeck = deck                    // SessionBuilderView presents (Seam B)
    }

    /// Direct begin (no ceremony) — fallback / Reduce Motion path. Still goes
    /// through the builder.
    func begin(_ id: String) {
        guard let deck = try? catalog.loadDeck(id: id) else { return }
        detailID = nil
        resolveBuilderStartIndex(deckId: deck.id)
        builderDeck = deck
    }

    func cancelBuilder() { builderDeck = nil }

    /// SEAM B (assembler ruling 1): the builder hands back the Codable
    /// SessionPlan struct; the row snapshot is `plan.draft` at the openSession
    /// call site. Open the row, then present the lobby cover.
    func builderDidFinish(_ plan: SessionPlan) {
        guard let deck = builderDeck else { return }
        builderDeck = nil
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
        Task { @MainActor in
            do {
                let dto = try await realtime.openSession(
                    coupleId: coupleId, initiatorId: myId, draft: draft
                )
                launch = SessionLaunch(hand: hand, entry: .initiator,
                                       role: role(for: myId), session: dto)
            } catch {
                openError = "Couldn't start the session. Try again."
            }
        }
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
}

#if DEBUG
extension PlayStore {
    /// In-memory store for SwiftUI previews (loads the bundled catalog).
    @MainActor static var preview: PlayStore {
        let appState = AppState()
        return PlayStore(
            modelContainer: .previewContainer,
            appState: appState,
            entitlements: EntitlementStore(modelContainer: .previewContainer, appState: appState)
        )
    }
}
#endif
