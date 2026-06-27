//
//  SessionStore.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/2/26.
//


//
//  SessionStore.swift
//  Vayl
//
//  Brain of the card session flow.
//  Owns card navigation, result recording, and persistence.
//  Created from either Home (resume) or Play (new or resume).
//
//  Dependencies injected via init — never from @Environment.
//  ModelContext created fresh at write time — never stored on self.
//

import SwiftUI
import SwiftData
import OSLog

private let logger = Logger(
    subsystem: "com.vayl.app",
    category: "SessionStore"
)

@Observable
@MainActor
final class SessionStore: Identifiable {

    // MARK: - State

    let id = UUID()
    var currentIndex: Int
    var sessionEnded: Bool = false
    var isLoading: Bool = false
    var error: String? = nil

    // MARK: - Session Data

    private(set) var deck: Deck
    private(set) var cards: [Card]
    private(set) var results: [(card: Card, status: CardStatus)] = []

    // MARK: - Dependencies

    private let modelContainer: ModelContainer
    private let appState: AppState

    // MARK: - Init

    /// - Parameters:
    ///   - deck: The deck to play.
    ///   - startIndex: Card index to resume from. Pass 0 for new sessions.
    ///   - modelContainer: Injected — never read from @Environment in a store.
    ///   - appState: Injected — needed for coupleId on CardSession write.
    init(
        deck: Deck,
        startIndex: Int = 0,
        modelContainer: ModelContainer,
        appState: AppState
    ) {
        self.deck = deck
        self.cards = deck.orderedCards
        self.currentIndex = min(startIndex, max(0, deck.orderedCards.count - 1))
        self.modelContainer = modelContainer
        self.appState = appState
    }

    // MARK: - Derived

    var currentCard: Card? {
        guard cards.indices.contains(currentIndex) else { return nil }
        return cards[currentIndex]
    }

    var isLastCard: Bool {
        currentIndex >= cards.count - 1
    }

    var progress: Double {
        guard !cards.isEmpty else { return 0 }
        return Double(currentIndex) / Double(cards.count)
    }

    var discussedCount: Int {
        results.filter { $0.status == .discussed }.count
    }

    var skippedCount: Int {
        results.filter { $0.status == .skipped }.count
    }

    var bookmarkedCount: Int {
        results.filter { $0.status == .bookmarked }.count
    }

    // MARK: - Actions

    /// Records a result for the current card and advances to the next.
    func recordAndAdvance(status: CardStatus) {
        guard let card = currentCard else { return }
        results.append((card: card, status: status))

        if isLastCard {
            saveSession()
            sessionEnded = true
        } else {
            currentIndex += 1
            updateDeckProgress()
        }
    }

    /// Resets the session state for replay from the beginning.
    func restart() {
        currentIndex = 0
        sessionEnded = false
        results = []
        error = nil
    }

    // MARK: - Persistence

    /// Writes the completed CardSession and all CardResults to SwiftData.
    /// Writes DeckProgress.completedAt to mark the deck done.
    private func saveSession() {
        guard let coupleId = appState.coupleId else {
            logger.warning("SessionStore: no coupleId — session not persisted")
            return
        }

        let context = ModelContext(modelContainer)

        do {
            // ── CardSession ──────────────────────────────────────────
            let session = CardSession(coupleId: coupleId, deckId: deck.id)
            session.completedAt = Date()
            session.cardsAttempted = results.count
            session.cardsDiscussed = discussedCount
            session.cardsSkipped = skippedCount
            session.cardsBookmarked = bookmarkedCount

            // Resolve session number from existing sessions for this deck
            var sessionFetch = FetchDescriptor<CardSession>(
                predicate: #Predicate { $0.coupleId == coupleId && $0.deckId == deck.id }
            )
            sessionFetch.fetchLimit = 100
            let existingSessions = try context.fetch(sessionFetch)
            session.sessionNumber = existingSessions.count + 1

            context.insert(session)

            // ── CardResults ──────────────────────────────────────────
            for result in results {
                let cardResult = CardResult(
                    sessionId: session.id,
                    cardId: result.card.id,
                    status: result.status
                )
                session.cardResults.append(cardResult)
                context.insert(cardResult)
            }

            // ── DeckProgress ─────────────────────────────────────────
            var progressFetch = FetchDescriptor<DeckProgress>(
                predicate: #Predicate { $0.coupleId == coupleId && $0.deckId == deck.id }
            )
            progressFetch.fetchLimit = 1
            let progressRecords = try context.fetch(progressFetch)

            if let progress = progressRecords.first {
                progress.completedAt = Date()
                progress.currentCardIndex = cards.count
            } else {
                let newProgress = DeckProgress(coupleId: coupleId, deckId: deck.id)
                newProgress.completedAt = Date()
                newProgress.currentCardIndex = cards.count
                context.insert(newProgress)
            }

            try context.saveWithLogging()
            logger.info("SessionStore: session saved — \(self.results.count) cards, deck \(self.deck.id)")

            // Enqueue async sync to Supabase
            let payloadObj = SessionRecordPayload(
                id: session.id,
                coupleId: coupleId,
                startedAt: session.startedAt,
                endedAt: session.completedAt,
                cardsDiscussed: session.cardsDiscussed
            )
            if let payloadData = try? JSONEncoder().encode(payloadObj) {
                Task { @MainActor in
                    SyncManager.shared.enqueueSyncTask(
                        taskType: "sync_session",
                        entityId: session.id.uuidString,
                        payload: payloadData
                    )
                }
            }

        } catch {
            self.error = error.localizedDescription
            logger.error("SessionStore: save failed — \(error.localizedDescription)")
        }
    }

    /// Updates DeckProgress.currentCardIndex mid-session so the user
    /// can resume from the correct card if they leave.
    private func updateDeckProgress() {
        guard let coupleId = appState.coupleId else { return }

        let context = ModelContext(modelContainer)

        do {
            var descriptor = FetchDescriptor<DeckProgress>(
                predicate: #Predicate { $0.coupleId == coupleId && $0.deckId == deck.id }
            )
            descriptor.fetchLimit = 1
            let records = try context.fetch(descriptor)

            if let progress = records.first {
                progress.currentCardIndex = currentIndex
            } else {
                let newProgress = DeckProgress(coupleId: coupleId, deckId: deck.id)
                newProgress.firstOpenedAt = Date()
                newProgress.currentCardIndex = currentIndex
                context.insert(newProgress)
            }

            try context.saveWithLogging()

        } catch {
            logger.error("SessionStore: DeckProgress update failed — \(error.localizedDescription)")
        }
    }
}