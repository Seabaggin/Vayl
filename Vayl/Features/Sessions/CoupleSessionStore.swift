//
//  CoupleSessionStore.swift
//  Vayl
//
//  Brain of the in-person couple card session (the .vaylCover flow):
//  lobby/airlock → transition → in-session player → close (or safeClose) +
//  reflection.
//
//  ONE store owns the whole cover because the phases share a single hand,
//  one bandwidth reading, one card-result ledger, and one end-of-session
//  persistence write.
//
//  TWO-DEVICE: when a RealtimeSessionService is injected the row is the source
//  of truth — SessionSyncCoordinator mirrors it in (index forward-only,
//  optimistic advance with rollback), and every UI state is reconstructable
//  from fetchOpenSession after an app kill. `realtime == nil` is the pure-local
//  DEBUG path (mocked partner), behavior unchanged from master.
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

    enum Phase { case airlock, transition, session, close, safeClose, done }

    /// Who is drawing the current card.
    enum Drawer { case you, partner }

    /// Pre-session bandwidth reading. The gentler of the two readings becomes
    /// the session's depth ceiling; the raw reading is never shown to the partner.
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

    // MARK: - Launch context

    let entry: SessionLaunch.Entry
    private let sessionRole: SessionRole
    private(set) var remoteSessionId: UUID?
    /// Safe word label + partner display name, resolved from the local Couple /
    /// profile rows at init; wayfinding copy only.
    private(set) var safeWordLabel: String = "red"
    private(set) var partnerLabel: String = "your partner"
    private(set) var deckTitle: String = "Tonight's deck"
    private(set) var localProfileId: UUID?
    private let perCardTimerSeconds: [String: Int]
    private let sessionStartedAt = Date()

    // MARK: - Airlock state (DEBUG local mock path)

    /// Your private bandwidth reading.
    var bandwidth: Bandwidth = .open
    /// Mock partner reading — DEBUG local path only.
    private(set) var partnerBandwidth: Bandwidth = .light
    /// Mock presence — flips true shortly after the airlock appears (DEBUG local path).
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
    /// no-op.
    private let enqueueSync: @MainActor (SessionRecordPayload) -> Void

    /// UX beat durations. Defaults match the felt design; tests pass tiny values
    /// so the airlock resolves without a real-time wait.
    private let presenceSeconds: Double
    private let transitionSeconds: Double

    private let realtime: RealtimeSessionService?
    private let initiatorId: UUID?

    // MARK: - Init

    init(
        launch: SessionLaunch,
        modelContainer: ModelContainer,
        appState: AppState,
        realtime: RealtimeSessionService? = nil,
        presenceSeconds: Double = 1.4,
        transitionSeconds: Double = 2.5,          // 🎚️ spec 4.5: ~2.5s held beat
        enqueueSync: (@MainActor (SessionRecordPayload) -> Void)? = nil
    ) {
        self.hand = launch.hand
        self.effectiveHand = launch.hand
        self.entry = launch.entry
        self.sessionRole = launch.role
        self.remoteSessionId = launch.session?.id
        self.perCardTimerSeconds = launch.session?.perCardTimer ?? [:]
        self.modelContainer = modelContainer
        self.appState = appState
        self.presenceSeconds = presenceSeconds
        self.transitionSeconds = transitionSeconds
        self.realtime = realtime
        self.initiatorId = launch.session?.initiatorId
        self.enqueueSync = enqueueSync ?? { payload in
            guard let data = try? JSONEncoder().encode(payload) else { return }
            SyncManager.shared.enqueueSyncTask(
                taskType: "sync_session",
                entityId: payload.id.uuidString,
                payload: data
            )
        }
        resolveLocalContext()
    }

    /// Compatibility path for the DEBUG local flow, previews, and the existing
    /// playthrough tests: a plain hand = a pure-local launch.
    convenience init(
        hand: [Card],
        modelContainer: ModelContainer,
        appState: AppState,
        presenceSeconds: Double = 1.4,
        transitionSeconds: Double = 2.5,
        enqueueSync: (@MainActor (SessionRecordPayload) -> Void)? = nil
    ) {
        self.init(
            launch: SessionLaunch(hand: hand, entry: .localDebug, role: .a, session: nil),
            modelContainer: modelContainer,
            appState: appState,
            realtime: nil,
            presenceSeconds: presenceSeconds,
            transitionSeconds: transitionSeconds,
            enqueueSync: enqueueSync
        )
    }

    private func resolveLocalContext() {
        let context = ModelContext(modelContainer)
        var profileFetch = FetchDescriptor<UserProfile>()
        profileFetch.fetchLimit = 1
        localProfileId = try? context.fetch(profileFetch).first?.id
        if let coupleId = appState.coupleId {
            var coupleFetch = FetchDescriptor<Couple>(predicate: #Predicate { $0.id == coupleId })
            coupleFetch.fetchLimit = 1
            if let couple = try? context.fetch(coupleFetch).first {
                safeWordLabel = couple.sharedSafeWord
            }
        }
        // Deck title: resolve the pretty name from the catalog when possible.
        if let deckId = hand.first?.deckId,
           let title = (try? DeckCatalogService().loadSummaries())?
               .first(where: { $0.id == deckId })?.title {
            deckTitle = title
        }
        // Partner label stays the honest generic when no name is resolvable
        // (no hardcoded placeholder names).
    }

    // MARK: - Derived (reads the ceiling-trimmed hand)

    var currentCard: Card? {
        effectiveHand.indices.contains(index) ? effectiveHand[index] : nil
    }

    /// Drawer alternates; the partner (A) opens, matching the deck order.
    var currentDrawer: Drawer { index % 2 == 0 ? .partner : .you }

    var isLastCard: Bool { index >= effectiveHand.count - 1 }

    /// Cards still to come after the current one — drives the fanned deck.
    var upcomingCount: Int { max(0, effectiveHand.count - index - 1) }

    var discussedCount: Int { records.filter { $0.status == .discussed }.count }
    var skippedCount: Int { records.filter { $0.status == .skipped }.count }

    /// Position label for the in-session header ("Card 3 · 8").
    var positionLabel: String { "\(index + 1) · \(effectiveHand.count)" }

    /// Cover-family screen 7 stat line: cards / depth reached / duration.
    var sessionStatLine: String {
        let cards = "\(discussedCount) \(discussedCount == 1 ? "card" : "cards")"
        let depth = "reached \(depthLabel)"
        let minutes = max(1, Int(Date().timeIntervalSince(sessionStartedAt) / 60))
        return "\(cards) · \(depth) · \(minutes) min"
    }

    /// Depth reached: the ceiling when live, else my own reading. Names the
    /// band, never a number, never the partner's reading (spec 4.5).
    private var depthLabel: String { (depthCeiling ?? bandwidth).label }

    // MARK: - Airlock actions (DEBUG local mock path)

    /// Arms the mock partner-presence handshake. DEBUG local path only —
    /// the real presence comes from AirlockStore.
    func armPresence() {
        guard !partnerPresent else { return }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(presenceSeconds))
            partnerPresent = true
        }
    }

    func setBandwidth(_ b: Bandwidth) { bandwidth = b }

    /// DEBUG local path: cross the airlock into the transition, then card 1.
    func confirmSynced() {
        guard phase == .airlock else { return }
        phase = .transition
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(transitionSeconds))
            if phase == .transition { phase = .session }
        }
    }

    /// AirlockStore reported active — cross into the held transition beat,
    /// start the remote mirror, then land on card 1.
    func airlockDidActivate() {
        guard phase == .airlock else { return }
        phase = .transition
        startRemoteSync()
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(transitionSeconds))
            if phase == .transition {
                phase = .session
                startTimerIfLeader()
            }
        }
    }

    /// Lobby cancel: mark the row abandoned so the partner's device sees the
    /// session end (no-op on the pure-local path).
    func abandonRemoteSession() {
        guard let realtime, let sid = remoteSessionId else { return }
        Task { @MainActor in
            try? await realtime.setStatus(sessionId: sid, status: .abandoned)
        }
    }

    // MARK: - Session actions

    /// Deal forward: the current card is done (discussed) → next, or finish.
    func dealNext() {
        recordCurrent(.discussed)
        advanceOrFinish()
    }

    /// Pass gracefully: the current card is skipped → next, or finish.
    func pass() {
        recordCurrent(.skipped)
        advanceOrFinish()
    }

    /// "End well" from the re-center sheet — a clean dual exit mid-session.
    func endEarly() {
        recordCurrent(.skipped)
        finishSession()
    }

    private func recordCurrent(_ status: CardStatus) {
        guard let card = currentCard else { return }
        records.append((card: card, status: status))
    }

    /// Optimistic + conditional-write advance (spec D7). Both paths bump
    /// locally first; the live path then writes the conditional update and
    /// rolls the bump back only on a NETWORK failure (a `false` result just
    /// means the partner won the race and the echoed row confirms the same
    /// landing index).
    private func advanceOrFinish() {
        if isLastCard { finishSession(); return }
        let expected = index
        index += 1                                   // optimistic, both paths
        revealEngine?.reset(forCardId: effectiveHand[expected].id)
        refreshTimer()
        guard isLive, let realtime, let sid = remoteSessionId else { return }
        Task { @MainActor in
            do {
                _ = try await realtime.advance(sessionId: sid, expectedIndex: expected)
                self.startTimerIfLeader()
            } catch {
                // Network failure: roll the optimistic bump back; the next echo
                // or reconnect resolves the truth. Index never regresses below
                // the last confirmed row value.
                if self.index == expected + 1, self.confirmedIndex <= expected {
                    self.index = expected
                    self.refreshTimer()
                }
            }
        }
    }

    // MARK: - Remote sync (the row is the source of truth)

    private var coordinator: SessionSyncCoordinator?
    private(set) var isLive = false
    private(set) var partnerPresentLive = false
    private(set) var isPaused = false
    private(set) var partnerAway = false
    private(set) var safeWordUsed = false
    private(set) var timerStartedAtRaw: String?
    /// Highest row index applied; the forward-only guard.
    private var confirmedIndex = 0
    /// Depth ceiling once both bandwidths are on the row.
    private(set) var depthCeiling: Bandwidth?
    /// The hand actually played tonight (ceiling-trimmed; == hand until then).
    private(set) var effectiveHand: [Card]
    /// PLAN16-SECTION3 assigns the real engine; row/broadcast reveal deltas are
    /// forwarded to it.
    var revealEngine: RevealEngine?

    func startRemoteSync() {
        guard let realtime, let coupleId = appState.coupleId,
              let userId = localProfileId, let sid = remoteSessionId,
              coordinator == nil else { return }
        let coordinator = SessionSyncCoordinator(
            service: realtime, coupleId: coupleId, userId: userId, sessionId: sid
        )
        self.coordinator = coordinator
        coordinator.onRowUpdate = { [weak self] dto in self?.applyRemoteRow(dto) }
        coordinator.onPresence = { [weak self] present in
            guard let self, let me = self.localProfileId else { return }
            let partnerHere = present.contains { $0 != me.uuidString }
            self.partnerPresentLive = partnerHere
            partnerHere ? self.partnerReturned() : self.partnerLost()
        }
        coordinator.onReveal = { [weak self] envelope in
            self?.revealEngine?.applyBroadcast(envelope)
        }
        coordinator.onResendRequest = { [weak self] cardId in
            self?.receiveRevealResendRequest(cardId: cardId)
        }
        coordinator.start()
        isLive = true
    }

    /// PLAN16-SECTION3 replaces this stub (the engine answers resend requests
    /// by re-sending its buffered envelope).
    func receiveRevealResendRequest(cardId: String) {}

    func teardown() {
        coordinator?.stop()
        coordinator = nil
        graceTask?.cancel()
        timerTask?.cancel()
    }

    /// Mirror the authoritative row. Index only ever moves forward.
    private func applyRemoteRow(_ dto: CuratedSessionDTO) {
        if dto.currentIndex > confirmedIndex {
            confirmedIndex = dto.currentIndex
        }
        let indexChanged: Bool
        if dto.currentIndex != index, dto.currentIndex >= confirmedIndex,
           effectiveHand.indices.contains(dto.currentIndex) {
            index = dto.currentIndex
            indexChanged = true
        } else if dto.currentIndex < index, dto.currentIndex == confirmedIndex {
            // Our optimistic bump outran a row that never moved: roll back.
            index = dto.currentIndex
            indexChanged = true
        } else {
            indexChanged = false
        }
        timerStartedAtRaw = dto.timerStartedAt
        liveTimers = dto.perCardTimer
        refreshTimer()
        if indexChanged { startTimerIfLeader() }
        recomputeCeiling(a: dto.aBandwidth, b: dto.bBandwidth)
        if dto.safeWordUsed, !safeWordUsed {
            safeWordUsed = true
            enterSafeClose()
        }
        isPaused = (dto.status == CuratedSessionStatus.paused.rawValue)
        if dto.status == CuratedSessionStatus.complete.rawValue, phase == .session {
            finishSession()                       // partner finished → follow to close
        }
        if dto.status == CuratedSessionStatus.abandoned.rawValue,
           !safeWordUsed, phase == .session {
            endEarly()                            // partner confirmed exit
        }
        revealEngine?.applyRow(dto.revealState)
    }

    /// Depth ceiling (spec 4.3): min of the two private readings. Light keeps
    /// cards ≤ .split, Open ≤ .auroraBand, Deep everything. Closing ritual is
    /// never trimmed. Both devices derive this from the same row columns, so
    /// the trimmed hand (and therefore current_index) is identical on both.
    private func recomputeCeiling(a: Float?, b: Float?) {
        guard let a, let b, depthCeiling == nil else { return }
        let minFraction = min(a, b)
        let ceiling: Bandwidth = minFraction < 0.4 ? .light : (minFraction < 0.7 ? .open : .deep)
        depthCeiling = ceiling
        let maxIntensity: CardIntensity = {
            switch ceiling {
            case .light: return .split
            case .open:  return .auroraBand
            case .deep:  return .supernova
            }
        }()
        effectiveHand = hand.filter { $0.type == .closingRitual || $0.intensity <= maxIntensity }
    }

    /// Cover appeared with no live channel (app kill / relaunch): rebuild from
    /// the open row and resubscribe. Every UI state must be reconstructable
    /// from fetchOpenSession alone (spec section 5).
    func resumeIfNeeded() async {
        guard let realtime, coordinator == nil,
              let coupleId = appState.coupleId else { return }
        guard let dto = try? await realtime.fetchOpenSession(coupleId: coupleId),
              dto.id == remoteSessionId ?? dto.id else { return }
        remoteSessionId = dto.id
        switch dto.status {
        case CuratedSessionStatus.active.rawValue, CuratedSessionStatus.paused.rawValue:
            recomputeCeiling(a: dto.aBandwidth, b: dto.bBandwidth)
            confirmedIndex = dto.currentIndex
            index = min(dto.currentIndex, max(0, effectiveHand.count - 1))
            timerStartedAtRaw = dto.timerStartedAt
            liveTimers = dto.perCardTimer
            isPaused = (dto.status == CuratedSessionStatus.paused.rawValue)
            if phase == .airlock { phase = .session }
            startRemoteSync()
            refreshTimer()
            revealEngine?.applyRow(dto.revealState)
        default:
            break   // lobby/airlock: AirlockStore owns those states
        }
    }

    // MARK: - Timer — derived locally from the shared anchor, never ticked over the wire

    private var liveTimers: [String: Int] = [:]     // seeded from perCardTimerSeconds
    private(set) var timerRemaining: TimeInterval?
    private(set) var timerElapsed = false
    private var timerTask: Task<Void, Never>?

    private static let isoFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    private static let isoPlain = ISO8601DateFormatter()

    private var currentCardLimit: Int? {
        guard let id = currentCard?.id else { return nil }
        return liveTimers[id]
    }

    func refreshTimer() {
        timerTask?.cancel()
        timerElapsed = false
        if liveTimers.isEmpty { liveTimers = perCardTimerSeconds }
        guard let limit = currentCardLimit, let raw = timerStartedAtRaw,
              let started = Self.isoFractional.date(from: raw) ?? Self.isoPlain.date(from: raw)
        else { timerRemaining = nil; return }
        let deadline = started.addingTimeInterval(TimeInterval(limit))
        timerTask = Task { @MainActor in
            while !Task.isCancelled {
                let remaining = deadline.timeIntervalSinceNow
                timerRemaining = max(0, remaining)
                if remaining <= 0 { timerElapsed = true; break }   // soft: NEVER advances
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    /// Role-a stamps the anchor when a timed card presents (deterministic single
    /// writer; the echoed UPDATE starts both countdowns together).
    func startTimerIfLeader() {
        guard isLive, sessionRole == .a, let realtime, let sid = remoteSessionId,
              currentCardLimit != nil else { return }
        Task { @MainActor in try? await realtime.markTimerStarted(sessionId: sid) }
    }

    /// "keep going": null this card's timer for BOTH via the row (spec 4.3).
    func keepGoing() {
        guard let id = currentCard?.id else { return }
        liveTimers[id] = nil
        timerElapsed = false
        timerRemaining = nil
        timerTask?.cancel()
        guard isLive, let realtime, let sid = remoteSessionId else { return }
        let timers = liveTimers
        Task { @MainActor in try? await realtime.setPerCardTimer(sessionId: sid, timers: timers) }
    }

    // MARK: - Safety (pause / safe word / presence grace)

    private var graceTask: Task<Void, Never>?

    func togglePause() {
        isPaused.toggle()
        guard isLive, let realtime, let sid = remoteSessionId else { return }
        let status: CuratedSessionStatus = isPaused ? .paused : .active
        Task { @MainActor in try? await realtime.setStatus(sessionId: sid, status: status) }
    }

    /// The safe word: an immediate, no-questions exit for BOTH devices.
    /// abandoned + safe_word_used in one write; no reflection, no penalty
    /// beyond cards already recorded.
    func raiseSafeWord() {
        safeWordUsed = true
        if isLive, let realtime, let sid = remoteSessionId {
            Task { @MainActor in try? await realtime.raiseSafeWord(sessionId: sid) }
        }
        enterSafeClose()
    }

    /// Both the local raise and the remote echo land here.
    private func enterSafeClose() {
        guard phase == .session || phase == .transition else { return }
        timerTask?.cancel()
        phase = .safeClose
    }

    /// Leaving the safe-word close: nothing else to save, just leave the cover.
    func acknowledgeSafeClose() { phase = .done }

    // Presence loss (called from the coordinator's presence callback).
    private func partnerLost() {
        guard isLive, phase == .session, graceTask == nil else { return }
        graceTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(15))
            guard !Task.isCancelled, !partnerPresentLive else { return }
            partnerAway = true
            if !isPaused { togglePause() }
        }
    }

    private func partnerReturned() {
        graceTask?.cancel()
        graceTask = nil
        if partnerAway {
            partnerAway = false
            if isPaused { togglePause() }   // their return resumes
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
        UserDefaults.standard.set(true, forKey: UserDefaultsKey.hasCompletedCoupleSession)
        phase = .close
    }

    /// Marks this device gone + the session complete (no-op pure-local).
    private func liveComplete() {
        guard realtime != nil, let sid = remoteSessionId else { return }
        let role = sessionRole
        Task { @MainActor in
            try? await self.realtime?.setPresence(sessionId: sid, role: role, present: false)
            try? await self.realtime?.setStatus(sessionId: sid, status: .complete)
        }
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
