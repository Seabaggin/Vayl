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

    // Hero / wall / detail / ceremony / session
    var featuredID: String?
    var detailID: String?
    var ceremonyDeckID: String?
    var sessionHand: [Card]?            // non-nil → present the session cover
    var paywallDeck: DeckSummary?       // non-nil → present the Core paywall for this deck

    // deps
    private let catalog: DeckCatalogService
    private let modelContainer: ModelContainer
    private let appState: AppState

    init(modelContainer: ModelContainer,
         appState: AppState,
         catalog: DeckCatalogService = DeckCatalogService()) {
        self.modelContainer = modelContainer
        self.appState = appState
        self.catalog = catalog
        load()
    }

    func load() {
        do {
            summaries = try catalog.loadSummaries()
            loadError = nil
        } catch {
            summaries = []
            loadError = "Couldn't load decks."
        }
        resolveFeatured()
        loadFeatured()
    }

    /// Pick the featured deck (most-recent in-progress, else first available) and resolve
    /// its continuity, both from real `DeckProgress`. Mirrors `HomeStore.loadDeckProgress`.
    /// "Most-recent" means most-recently-opened: `DeckProgress` has no last-touched stamp yet.
    private func resolveFeatured() {
        let progress = fetchProgress()
        let availableIDs = Set(summaries.filter { !$0.isLocked }.map(\.id))   // free = playable
        let recentInProgress = progress
            .filter { availableIDs.contains($0.deckId) && $0.completedAt == nil && $0.currentCardIndex > 0 }
            .max { ($0.firstOpenedAt ?? .distantPast) < ($1.firstOpenedAt ?? .distantPast) }
        let fallback = summaries.first { !$0.isLocked }?.id ?? summaries.first?.id
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
        sessionHand = deck.orderedCards
    }

    /// Direct begin (no ceremony) — fallback / Reduce Motion path.
    func begin(_ id: String) {
        guard let deck = try? catalog.loadDeck(id: id) else { return }
        detailID = nil
        sessionHand = deck.orderedCards
    }

    func endSession() { sessionHand = nil }

    /// Locked deck → open the Core paywall (closes the detail first).
    func requestUnlock(_ deck: DeckSummary) { detailID = nil; paywallDeck = deck }
    func dismissPaywall() { paywallDeck = nil }
}

#if DEBUG
extension PlayStore {
    /// In-memory store for SwiftUI previews (loads the bundled catalog).
    @MainActor static var preview: PlayStore {
        PlayStore(modelContainer: .previewContainer, appState: AppState())
    }
}
#endif
