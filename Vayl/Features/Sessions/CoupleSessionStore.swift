//
//  CoupleSessionStore.swift
//  Vayl
//
//  Brain of the in-person couple card session (the .vaylCover flow):
//  airlock → transition → in-session player → close + reflection.
//
//  ONE store owns the whole cover because the phases share a single hand,
//  one bandwidth reading, one card-result ledger, and one end-of-session
//  persistence write. Splitting into Airlock/Player stores would only add
//  cross-store coordination for state that is genuinely one session.
//
//  FRONT-END / LOCAL: partner presence and the partner's "ready" are mocked
//  here (no Realtime). The swap to RealtimeSessionService is a one-layer change
//  inside this store — the views never learn the difference. See
//  docs/superpowers/specs/2026-06-21-couple-session-quickplay-implementation-spec.md.
//
//  Dependencies injected via init — never @Environment. ModelContext is created
//  fresh at write time — never stored on self (matches SessionStore).
//

import SwiftUI
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.vayl.app", category: "CoupleSessionStore")

@Observable
@MainActor
final class CoupleSessionStore: Identifiable {

    // MARK: - Flow

    enum Phase { case airlock, transition, session, close, done }

    /// Who is drawing the current card.
    enum Drawer { case you, partner }

    /// Pre-session bandwidth reading. Informs depth; never hard-gates in V1.
    enum Bandwidth: String, CaseIterable {
        case light, open, deep
        var label: String { rawValue }
        var fraction: Float {
            switch self {
            case .light: return 0.25
            case .open:  return 0.55
            case .deep:  return 0.85
            }
        }
    }

    let id = UUID()
    private(set) var phase: Phase = .airlock

    // MARK: - Airlock state

    /// Your private bandwidth reading.
    var bandwidth: Bandwidth = .open
    /// Mock partner reading — shown once they "arrive". Realtime later.
    private(set) var partnerBandwidth: Bandwidth = .light
    /// Mock presence — flips true shortly after the airlock appears. Realtime later.
    private(set) var partnerPresent: Bool = false

    // MARK: - Session state

    let hand: [Card]
    private(set) var index: Int = 0
    private(set) var records: [(card: Card, status: CardStatus)] = []

    // MARK: - Close / reflection state

    var reflectionWords: Set<String> = []
    /// "who carried it" — 0 = you, 0.5 = even, 1 = partner.
    var carriedBalance: Double = 0.5
    /// "did you feel heard" — 0 = not really, 1 = fully.
    var feltHeard: Double = 0.72
    var reflectionNote: String = ""

    /// Set when the CardSession persists on entering close — links the reflection.
    private(set) var savedSessionId: UUID?

    // MARK: - Dependencies

    private let modelContainer: ModelContainer
    private let appState: AppState
    /// Sync hook — encodes the completed-session payload and hands it to the
    /// offline queue. Injected (default = the real SyncManager) so tests pass a
    /// no-op: the queue touches the on-disk app container + network, which must
    /// not run inside a unit test. Also keeps the store from reaching for the
    /// `SyncManager.shared` singleton inline (services injected, not reached for).
    private let enqueueSync: @MainActor (SessionRecordPayload) -> Void

    /// UX beat durations. Defaults match the felt design; tests pass tiny values
    /// so the airlock resolves without a real-time wait.
    private let presenceSeconds: Double
    private let transitionSeconds: Double

    // ── Realtime scaffold (UNVERIFIED — Seg 6/7, needs backend + two devices) ──
    // Injected service + role + initiator. Default nil = pure-local (the verified
    // path; the front-end behaves exactly as before). When a service is injected
    // (behind a flag, with real auth), the store ALSO pushes state to
    // curated_sessions. None of this has run against the backend or a second
    // device. See docs/superpowers/plans/2026-06-21-segments-6-9-scaffold-status.md.
    private let realtime: RealtimeSessionService?
    private let sessionRole: SessionRole
    private let initiatorId: UUID?
    private(set) var remoteSessionId: UUID?

    // MARK: - Init

    init(
        hand: [Card],
        modelContainer: ModelContainer,
        appState: AppState,
        presenceSeconds: Double = 1.4,
        transitionSeconds: Double = 2.6,
        realtime: RealtimeSessionService? = nil,
        sessionRole: SessionRole = .a,
        initiatorId: UUID? = nil,
        enqueueSync: (@MainActor (SessionRecordPayload) -> Void)? = nil
    ) {
        self.hand = hand
        self.modelContainer = modelContainer
        self.appState = appState
        self.presenceSeconds = presenceSeconds
        self.transitionSeconds = transitionSeconds
        self.realtime = realtime
        self.sessionRole = sessionRole
        self.initiatorId = initiatorId
        self.enqueueSync = enqueueSync ?? { payload in
            guard let data = try? JSONEncoder().encode(payload) else { return }
            SyncManager.shared.enqueueSyncTask(
                taskType: "sync_session",
                entityId: payload.id.uuidString,
                payload: data
            )
        }
    }

    // MARK: - Derived

    var currentCard: Card? {
        hand.indices.contains(index) ? hand[index] : nil
    }

    /// Drawer alternates; the partner (A) opens, matching the deck order.
    var currentDrawer: Drawer { index % 2 == 0 ? .partner : .you }

    var isLastCard: Bool { index >= hand.count - 1 }

    /// Cards still to come after the current one — drives the fanned deck.
    var upcomingCount: Int { max(0, hand.count - index - 1) }

    var discussedCount: Int { records.filter { $0.status == .discussed }.count }
    var skippedCount: Int { records.filter { $0.status == .skipped }.count }

    /// Position label for the in-session header ("Card 3 · 8").
    var positionLabel: String { "\(index + 1) · \(hand.count)" }

    // MARK: - Airlock actions

    /// Arms the mock partner-presence handshake. Called when the airlock appears.
    /// Realtime swap: replace with a RealtimeSessionService presence subscription.
    func armPresence() {
        guard !partnerPresent else { return }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(presenceSeconds))
            partnerPresent = true
        }
    }

    func setBandwidth(_ b: Bandwidth) { bandwidth = b }

    /// Both partners released the sync ring close enough together. Cross the
    /// airlock into the phones-down transition, then the first card.
    func confirmSynced() {
        guard phase == .airlock else { return }
        phase = .transition
        liveOpen()
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(transitionSeconds))
            if phase == .transition { phase = .session }
        }
    }

    // MARK: - Session actions

    /// Deal forward: the current card is done (discussed) → next, or finish.
    func dealNext() {
        recordCurrent(.discussed)
        liveAdvance(expectedIndex: index)
        advanceOrFinish()
    }

    /// Pass gracefully: the current card is skipped → next, or finish.
    func pass() {
        recordCurrent(.skipped)
        liveAdvance(expectedIndex: index)
        advanceOrFinish()
    }

    /// "End well" from the re-center sheet — a clean dual exit mid-session.
    /// Records the current card as skipped and goes straight to the close.
    func endEarly() {
        recordCurrent(.skipped)
        finishSession()
    }

    private func recordCurrent(_ status: CardStatus) {
        guard let card = currentCard else { return }
        records.append((card: card, status: status))
    }

    private func advanceOrFinish() {
        if isLastCard {
            finishSession()
        } else {
            index += 1
        }
    }

    // MARK: - Close actions

    func toggleWord(_ word: String) {
        if reflectionWords.contains(word) { reflectionWords.remove(word) }
        else { reflectionWords.insert(word) }
    }

    /// Save the private reflection against the just-saved session, then dismiss.
    func saveReflection() {
        persistReflection()
        phase = .done
    }

    /// Decline the reflection — the session itself is already saved.
    func skipReflection() {
        phase = .done
    }

    // MARK: - Persistence

    /// Writes the completed CardSession + CardResults + DeckProgress (mirrors
    /// SessionStore) and moves to the close. The reflection is written later,
    /// only if the user saves one.
    private func finishSession() {
        persistSession()
        liveComplete()
        phase = .close
    }

    // MARK: - Realtime scaffold methods (UNVERIFIED — Seg 6/7)
    //
    // Fire-and-forget pushes of local state to curated_sessions. Every one is a
    // no-op unless a RealtimeSessionService is injected, so the verified local flow
    // is untouched. NONE of this has run against the backend or a second device.
    // The service is accessed via `self` inside each @MainActor task (never captured
    // directly) to keep the closures free of non-Sendable captures.

    /// Opens the curated_sessions row + pushes initial presence / bandwidth / status.
    private func liveOpen() {
        guard realtime != nil, let coupleId = appState.coupleId, let initiatorId else { return }
        let draft = CuratedSessionDraft(
            deckId: hand.first?.deckId ?? "",
            deckVariant: nil,
            cardIds: hand.map(\.id),
            perCardTimer: [:],
            globalTimerSeconds: nil
        )
        let role = sessionRole
        let bandwidthValue = bandwidth.fraction
        Task { @MainActor in
            guard let realtime = self.realtime else { return }
            do {
                let dto = try await realtime.openSession(
                    coupleId: coupleId, initiatorId: initiatorId, draft: draft
                )
                self.remoteSessionId = dto.id
                try? await realtime.setPresence(sessionId: dto.id, role: role, present: true)
                try? await realtime.setBandwidth(sessionId: dto.id, role: role, value: bandwidthValue)
                try? await realtime.setStatus(sessionId: dto.id, status: .active)
            } catch {
                logger.warning("liveOpen failed (scaffold, unverified): \(error.localizedDescription)")
            }
        }
    }

    /// Server-authoritative advance, conditional on the expected index.
    private func liveAdvance(expectedIndex: Int) {
        guard realtime != nil, let sid = remoteSessionId else { return }
        Task { @MainActor in
            _ = try? await self.realtime?.advance(sessionId: sid, expectedIndex: expectedIndex)
        }
    }

    /// Marks this device gone + the session complete.
    private func liveComplete() {
        guard realtime != nil, let sid = remoteSessionId else { return }
        let role = sessionRole
        Task { @MainActor in
            try? await self.realtime?.setPresence(sessionId: sid, role: role, present: false)
            try? await self.realtime?.setStatus(sessionId: sid, status: .complete)
        }
    }

    /// Seg 7 (two-device sync) — the UNVERIFIED core. The push side above is wired;
    /// CONSUMING remote presence + postgres-changes to drive THIS device's state is
    /// the next step and needs two physical devices to validate.
    func startRemoteSync() {
        guard realtime != nil else { return }
        // TODO(Seg 7): open realtime.sessionChannel(coupleId:userId:), trackPresence,
        // and mirror remote current_index / presence / status into this store via
        // presenceChange() / postgres-changes. No-op beyond this guard today.
    }

    private func persistSession() {
        guard let coupleId = appState.coupleId else {
            logger.warning("no coupleId — session not persisted")
            return
        }
        let deckId = hand.first?.deckId ?? "unknown"
        let context = ModelContext(modelContainer)

        do {
            let session = CardSession(coupleId: coupleId, deckId: deckId)
            session.completedAt = Date()
            session.cardsAttempted = records.count
            session.cardsDiscussed = discussedCount
            session.cardsSkipped = skippedCount
            session.cardsBookmarked = 0
            session.lockInBandwidthA = partnerBandwidth.fraction
            session.lockInBandwidthB = bandwidth.fraction

            var sessionFetch = FetchDescriptor<CardSession>(
                predicate: #Predicate { $0.coupleId == coupleId && $0.deckId == deckId }
            )
            sessionFetch.fetchLimit = 100
            let existing = try context.fetch(sessionFetch)
            session.sessionNumber = existing.count + 1

            context.insert(session)

            for record in records {
                let result = CardResult(
                    sessionId: session.id,
                    cardId: record.card.id,
                    status: record.status
                )
                session.cardResults.append(result)
                context.insert(result)
            }

            var progressFetch = FetchDescriptor<DeckProgress>(
                predicate: #Predicate { $0.coupleId == coupleId && $0.deckId == deckId }
            )
            progressFetch.fetchLimit = 1
            if let progress = try context.fetch(progressFetch).first {
                progress.completedAt = Date()
                progress.lastPlayedAt = Date()
            } else {
                let newProgress = DeckProgress(coupleId: coupleId, deckId: deckId)
                newProgress.completedAt = Date()
                newProgress.lastPlayedAt = Date()
                context.insert(newProgress)
            }

            try context.saveWithLogging()
            savedSessionId = session.id
            logger.info("couple session saved — \(self.records.count) cards, deck \(deckId)")

            enqueueSync(SessionRecordPayload(
                id: session.id,
                coupleId: coupleId,
                startedAt: session.startedAt,
                endedAt: session.completedAt,
                cardsDiscussed: session.cardsDiscussed
            ))
        } catch {
            logger.error("couple session save failed — \(error.localizedDescription)")
        }
    }

    private func persistReflection() {
        guard let sessionId = savedSessionId else {
            logger.warning("no saved session — reflection not persisted")
            return
        }
        let context = ModelContext(modelContainer)
        let trimmedNote = reflectionNote.trimmingCharacters(in: .whitespacesAndNewlines)

        let reflection = SessionReflection(
            cardSessionId: sessionId,
            words: Array(reflectionWords),
            carriedBalance: carriedBalance,
            feltHeard: feltHeard,
            note: trimmedNote.isEmpty ? nil : trimmedNote
        )
        context.insert(reflection)

        do {
            try context.saveWithLogging()
            logger.info("session reflection saved — \(self.reflectionWords.count) words")
        } catch {
            logger.error("reflection save failed — \(error.localizedDescription)")
        }
    }
}
