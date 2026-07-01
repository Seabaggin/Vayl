//
//  SessionEntryStore.swift
//  Vayl
//
//  One question for Home + Play: "did my partner set up a session?"
//  Polls fetchOpenSession on appear/foreground; a row in lobby/airlock whose
//  initiator is NOT me becomes the pending banner. Accepting builds the joiner
//  SessionLaunch. Rows already active/paused are the reconnect path, handled by
//  the cover itself (CoupleSessionStore.resumeIfNeeded), not a banner.
//

import SwiftUI
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.vayl.app", category: "SessionEntryStore")

@Observable
@MainActor
final class SessionEntryStore {

    struct Pending: Identifiable, Equatable {
        let id: UUID
        let initiatorName: String
        let deckTitle: String
        let dto: CuratedSessionDTO
        static func == (l: Pending, r: Pending) -> Bool { l.id == r.id }
    }

    private(set) var pendingSession: Pending?
    /// Set on accept; the host view presents the cover with it, then clears it.
    var acceptedLaunch: SessionLaunch?

    private let modelContainer: ModelContainer
    private let appState: AppState
    private let realtime: RealtimeSessionService
    private let catalog: DeckCatalogService
    /// Partner display name provider; nil-safe ("Your partner").
    private let partnerName: () -> String?
    private var dismissedSessionId: UUID?

    init(modelContainer: ModelContainer,
         appState: AppState,
         realtime: RealtimeSessionService = RealtimeSessionService(),
         catalog: DeckCatalogService = DeckCatalogService(),
         partnerName: @escaping () -> String? = { nil }) {
        self.modelContainer = modelContainer
        self.appState = appState
        self.realtime = realtime
        self.catalog = catalog
        self.partnerName = partnerName
    }

    func refresh() {
        guard let coupleId = appState.coupleId else { pendingSession = nil; return }
        Task { @MainActor in
            do {
                guard let dto = try await realtime.fetchOpenSession(coupleId: coupleId),
                      dto.status == CuratedSessionStatus.lobby.rawValue
                        || dto.status == CuratedSessionStatus.airlock.rawValue,
                      dto.initiatorId != localProfileId(),
                      dto.id != dismissedSessionId
                else { pendingSession = nil; return }
                let title = (try? catalog.loadSummaries())?
                    .first { $0.id == dto.deckId }?.title ?? dto.deckId
                pendingSession = Pending(
                    id: dto.id,
                    initiatorName: partnerName() ?? "Your partner",
                    deckTitle: title,
                    dto: dto
                )
            } catch {
                logger.warning("open-session fetch failed: \(error.localizedDescription)")
                pendingSession = nil
            }
        }
    }

    func accept() {
        guard let pending = pendingSession else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        let dto = pending.dto
        guard let deck = try? catalog.loadDeck(id: dto.deckId) else { return }
        let hand = dto.cardIds.compactMap { id in deck.orderedCards.first { $0.id == id } }
        guard !hand.isEmpty, let myId = localProfileId() else { return }
        acceptedLaunch = SessionLaunch(
            hand: hand, entry: .joiner, role: role(for: myId), session: dto
        )
        pendingSession = nil
    }

    func dismissBanner() {
        dismissedSessionId = pendingSession?.id
        pendingSession = nil
    }

    private func localProfileId() -> UUID? {
        let context = ModelContext(modelContainer)
        var fetch = FetchDescriptor<UserProfile>()
        fetch.fetchLimit = 1
        return try? context.fetch(fetch).first?.id
    }

    /// Identity rule (spec 4.2, hard): role derives from the local Couple row's
    /// partnerAId vs my LOCAL profile id. Never the supabase auth id.
    private func role(for profileId: UUID) -> SessionRole {
        guard let coupleId = appState.coupleId else { return .b }
        let context = ModelContext(modelContainer)
        var fetch = FetchDescriptor<Couple>(predicate: #Predicate { $0.id == coupleId })
        fetch.fetchLimit = 1
        guard let couple = try? context.fetch(fetch).first else { return .b }
        return couple.partnerAId == profileId ? .a : .b
    }
}
