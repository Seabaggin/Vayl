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

// MARK: - Realtime seam (test injection)
//
// Minimal additive seam: SessionEntryStore only ever calls fetchOpenSession
// on its injected RealtimeSessionService (a concrete, network-backed final
// class with no fake-able surface). This protocol exposes just that one
// method — same pattern as AirlockTransport/LiveAirlockTransport.
protocol SessionEntryRealtime: AnyObject {
    func fetchOpenSession(coupleId: UUID) async throws -> CuratedSessionDTO?
    func setStatus(sessionId: UUID, status: CuratedSessionStatus) async throws
}

extension RealtimeSessionService: SessionEntryRealtime {}

@Observable
@MainActor
final class SessionEntryStore {

    enum Kind: Equatable { case invite, resume }

    struct Pending: Identifiable, Equatable {
        let id: UUID
        let kind: Kind
        let initiatorName: String
        let deckTitle: String
        let cardPosition: Int      // 1-based "card N of M" — invite kind ignores this
        let cardCount: Int
        let dto: CuratedSessionDTO
        static func == (l: Pending, r: Pending) -> Bool { l.id == r.id }
    }

    private(set) var pendingSession: Pending?
    /// Set on accept; the host view presents the cover with it, then clears it.
    var acceptedLaunch: SessionLaunch?
    /// Loud failure surface (spec 2026-07-09 §1.8): set when accept()/resume()
    /// fails to load the deck or build a valid hand — never when the row
    /// simply vanished server-side (that path silently clears the banner, by
    /// design). Cleared on the next successful refresh/accept/resume.
    private(set) var joinError: String?

    private let modelContainer: ModelContainer
    private let appState: AppState
    private let realtime: SessionEntryRealtime
    private let catalog: DeckCatalogService
    /// Partner display name provider; nil-safe ("Your partner").
    private let partnerName: () -> String?

    /// A pending lobby older than this is a walked-away-from setup, not an
    /// invitation — don't banner it. 🎚️ hours.
    private let pendingMaxAgeHours: Double = 12

    /// Dismissal is shared across surfaces (Home and Play each hold their own
    /// store instance): dismissing the banner on one tab must not resurrect it
    /// on the other.
    private var dismissedSessionId: UUID? {
        get { UserDefaults.standard.string(forKey: UserDefaultsKey.dismissedPendingSessionId)
                .flatMap(UUID.init(uuidString:)) }
        set { UserDefaults.standard.set(newValue?.uuidString,
                                        forKey: UserDefaultsKey.dismissedPendingSessionId) }
    }

    init(modelContainer: ModelContainer,
         appState: AppState,
         realtime: SessionEntryRealtime? = nil,
         catalog: DeckCatalogService? = nil,
         partnerName: @escaping () -> String? = { nil }) {
        self.modelContainer = modelContainer
        self.appState = appState
        // Construct default services on the main actor (this init's isolation).
        self.realtime = realtime ?? RealtimeSessionService()
        self.catalog = catalog ?? DeckCatalogService()
        self.partnerName = partnerName
    }

    func refresh() {
        guard let coupleId = appState.coupleId else { pendingSession = nil; return }
        Task { @MainActor in
            do {
                joinError = nil
                guard let dto = try await realtime.fetchOpenSession(coupleId: coupleId) else {
                    pendingSession = nil
                    return
                }
                if isStale(dto) {
                    // Walked away from and never came back — reclaim the row so
                    // the couple isn't blocked from starting anything new.
                    try? await realtime.setStatus(sessionId: dto.id, status: .abandoned)
                    pendingSession = nil
                    return
                }
                if isResumableRow(dto) {
                    let title = (try? catalog.loadSummaries())?
                        .first { $0.id == dto.deckId }?.title ?? dto.deckId
                    pendingSession = Pending(
                        id: dto.id,
                        kind: .resume,
                        initiatorName: partnerName() ?? "Your partner",
                        deckTitle: title,
                        cardPosition: dto.currentIndex + 1,
                        cardCount: dto.cardIds.count,
                        dto: dto
                    )
                    return
                }
                guard isJoinablePending(dto) else { pendingSession = nil; return }
                let title = (try? catalog.loadSummaries())?
                    .first { $0.id == dto.deckId }?.title ?? dto.deckId
                pendingSession = Pending(
                    id: dto.id,
                    kind: .invite,
                    initiatorName: partnerName() ?? "Your partner",
                    deckTitle: title,
                    cardPosition: dto.currentIndex + 1,
                    cardCount: dto.cardIds.count,
                    dto: dto
                )
            } catch {
                logger.warning("open-session fetch failed: \(error.localizedDescription)")
                pendingSession = nil
            }
        }
    }

    /// A pending row worth bannering: lobby/airlock, someone else's, not
    /// dismissed, and not so old the invitation is clearly dead.
    private func isJoinablePending(_ dto: CuratedSessionDTO) -> Bool {
        guard dto.status == CuratedSessionStatus.lobby.rawValue
                || dto.status == CuratedSessionStatus.airlock.rawValue,
              dto.initiatorId != localProfileId(),
              dto.id != dismissedSessionId
        else { return false }
        return true
    }

    /// An interrupted session (active/paused) is resumable by EITHER partner —
    /// no initiator check, unlike the invite path.
    private func isResumableRow(_ dto: CuratedSessionDTO) -> Bool {
        dto.status == CuratedSessionStatus.active.rawValue
            || dto.status == CuratedSessionStatus.paused.rawValue
    }

    /// Age basis: updatedAt (last touch) for active/paused rows, createdAt
    /// (freshness of the invite itself) for lobby/airlock rows.
    private func isStale(_ dto: CuratedSessionDTO) -> Bool {
        let basis = isResumableRow(dto) ? dto.updatedAt : dto.createdAt
        guard let date = Self.isoFractional.date(from: basis) ?? Self.isoPlain.date(from: basis)
        else { return false }
        return Date().timeIntervalSince(date) > pendingMaxAgeHours * 3600
    }

    private static let isoFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    private static let isoPlain = ISO8601DateFormatter()

    /// Join. Revalidates against the server first — the cached DTO may be a
    /// session the initiator has since cancelled; entering a dead lobby would
    /// strand the joiner at "waiting" forever.
    func accept() {
        guard let pending = pendingSession, pending.kind == .invite,
              let coupleId = appState.coupleId
        else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        Task { @MainActor in
            guard let dto = try? await realtime.fetchOpenSession(coupleId: coupleId),
                  dto.id == pending.id,
                  isJoinablePending(dto)
            else {
                pendingSession = nil       // gone — drop the dead banner
                return
            }
            guard let deck = try? catalog.loadDeck(id: dto.deckId) else {
                joinError = Self.joinErrorMessage
                pendingSession = nil       // don't leave a banner that would fail identically
                return
            }
            guard let hand = SessionLaunch.buildHand(cardIds: dto.cardIds, deck: deck),
                  let myId = localProfileId()
            else {
                joinError = Self.joinErrorMessage
                pendingSession = nil
                return
            }
            joinError = nil
            acceptedLaunch = SessionLaunch(
                hand: hand, entry: .joiner, role: role(for: myId), session: dto
            )
            pendingSession = nil
        }
    }

    /// Resume an interrupted session. Mirrors accept(): revalidate against the
    /// server first (the row may have been ended from the other device between
    /// refresh and this tap), rebuild the hand, then let the existing
    /// acceptedLaunch → cover wiring take over. CoupleSessionStore.resumeIfNeeded
    /// picks the airlock-skip logic up from there — not touched here.
    func resume() {
        guard let pending = pendingSession, pending.kind == .resume,
              let coupleId = appState.coupleId
        else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        Task { @MainActor in
            guard let dto = try? await realtime.fetchOpenSession(coupleId: coupleId),
                  dto.id == pending.id,
                  isResumableRow(dto)
            else {
                pendingSession = nil       // gone — drop the dead banner
                return
            }
            guard let deck = try? catalog.loadDeck(id: dto.deckId) else {
                joinError = Self.joinErrorMessage
                pendingSession = nil       // don't leave a banner that would fail identically
                return
            }
            guard let hand = SessionLaunch.buildHand(cardIds: dto.cardIds, deck: deck),
                  let myId = localProfileId()
            else {
                joinError = Self.joinErrorMessage
                pendingSession = nil
                return
            }
            joinError = nil
            acceptedLaunch = SessionLaunch(
                hand: hand,
                entry: dto.initiatorId == myId ? .initiator : .joiner,
                role: role(for: myId),
                session: dto
            )
            pendingSession = nil
        }
    }

    /// End an interrupted session outright — clears the DB row so the
    /// one-open-session-per-couple constraint doesn't block a fresh start.
    func endResumable() {
        guard let pending = pendingSession, pending.kind == .resume else { return }
        pendingSession = nil
        Task { @MainActor in
            try? await realtime.setStatus(sessionId: pending.id, status: .abandoned)
        }
    }

    func dismissBanner() {
        dismissedSessionId = pendingSession?.id
        pendingSession = nil
    }

    func clearJoinError() { joinError = nil }

    /// Exact copy (Bryan-approved, no em dashes) — shared with PlayStore's
    /// openError for the same failure class (spec 2026-07-09 §1.8).
    static let joinErrorMessage = "Couldn't open that session. Make sure you're both on the latest version, then try again."

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
