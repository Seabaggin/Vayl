//
//  CoupleSessionStore.swift
//  Vayl
//
//  Brain of the in-person couple card session (the .vaylCover flow):
//  lobby/airlock → transition → in-session player → close +
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

    enum Phase { case airlock, transition, session, close, done }

    /// Who is drawing the current card.
    enum Drawer { case you, partner }

    let id = UUID()
    private(set) var phase: Phase = .airlock

    // MARK: - Launch context

    let entry: SessionLaunch.Entry
    private let sessionRole: SessionRole
    private(set) var remoteSessionId: UUID?
    /// Partner display name, resolved from the local Couple / profile rows at
    /// init; wayfinding copy only.
    private(set) var partnerLabel: String = "your partner"
    private(set) var deckTitle: String = "Tonight's deck"
    private(set) var localProfileId: UUID?
    private let perCardTimerSeconds: [String: Int]
    private let sessionStartedAt = Date()

    // MARK: - Airlock state (DEBUG local mock path)

    /// Mock presence — flips true shortly after the airlock appears (DEBUG local path).
    private(set) var partnerPresent: Bool = false

    // MARK: - Session state

    let hand: [Card]
    private(set) var index: Int = 0
    private(set) var records: [(card: Card, status: CardStatus)] = []

    // MARK: - Session settings (two knobs: who reads first, length/pace)

    /// The two chosen knobs for this sitting. `length` implies the in-session
    /// gentle timer (built later) via `softCapMinutes`. The settings-sheet UI
    /// is a later device-gated task; this store just holds the model + setters.
    var sessionSettings = SessionSettings()

    func setReader(_ reader: SessionSettings.Reader) { sessionSettings.reader = reader }
    func setLength(_ length: SessionSettings.Length) { sessionSettings.length = length }

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
        self.entry = launch.entry
        self.sessionRole = launch.role
        self.remoteSessionId = launch.session?.id
        self.perCardTimerSeconds = launch.session?.perCardTimer ?? [:]
        self.modelContainer = modelContainer
        self.appState = appState
        // Seed the two-knob session settings from AppState (set via the Home chest cog).
        self.sessionSettings = appState.sessionSettings
        self.presenceSeconds = presenceSeconds
        self.transitionSeconds = transitionSeconds
        self.realtime = realtime
        self.initiatorId = launch.session?.initiatorId
        self.revealEngine = RevealEngine(role: launch.role, transport: nil)
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
        // Deck title: resolve the pretty name from the catalog when possible.
        if let deckId = hand.first?.deckId,
           let title = (try? DeckCatalogService().loadSummaries())?
               .first(where: { $0.id == deckId })?.title {
            deckTitle = title
        }
        // Partner label stays the honest generic when no name is resolvable
        // (no hardcoded placeholder names).
    }

    // MARK: - Derived

    var currentCard: Card? {
        hand.indices.contains(index) ? hand[index] : nil
    }

    /// Role owning the current draw: A opens (even indices), then it alternates.
    /// Deterministic from the index, so both devices agree on whose card it is.
    private var drawingRole: SessionRole { index % 2 == 0 ? .a : .b }

    /// Whose draw this is, from THIS device's perspective (role-aware — the two
    /// devices render mirrored labels/tints, never the same one).
    var currentDrawer: Drawer { drawingRole == sessionRole ? .you : .partner }

    /// The badge letter for the drawer row ("A" / "B"), shared by both devices.
    var drawingRoleLabel: String { drawingRole == .a ? "A" : "B" }

    /// Mirror cards: the subject alternates per card (deterministic from the
    /// index, identical on both devices); the other partner guesses.
    var mirrorSubjectIsMe: Bool { drawingRole == sessionRole }

    var isLastCard: Bool { index >= hand.count - 1 }

    /// Cards still to come after the current one — drives the fanned deck.
    var upcomingCount: Int { max(0, hand.count - index - 1) }

    var discussedCount: Int { records.filter { $0.status == .discussed }.count }
    var skippedCount: Int { records.filter { $0.status == .skipped }.count }

    /// Position label for the in-session header ("Card 3 · 8").
    var positionLabel: String { "\(index + 1) · \(hand.count)" }

    /// Cover-family screen 7 stat line: cards / duration.
    var sessionStatLine: String {
        let cards = "\(discussedCount) \(discussedCount == 1 ? "card" : "cards")"
        let minutes = max(1, Int(Date().timeIntervalSince(sessionStartedAt) / 60))
        return "\(cards) · \(minutes) min"
    }

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

    /// DEBUG local path: cross the airlock into the transition, then card 1.
    func confirmSynced() {
        guard phase == .airlock else { return }
        phase = .transition
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(transitionSeconds))
            if phase == .transition {
                phase = .session
                cardDidChange()      // Section 3: first card's beat/reveal setup
                persistProgressCheckpoint()
            }
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
                cardDidChange()      // Section 3: first card's beat/reveal setup
                startTimerIfLeader()
                persistProgressCheckpoint()
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
        cardDidChange()                              // Section 3: beats / back / reveal per-card setup
        refreshTimer()
        persistProgressCheckpoint()
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
                    self.cardDidChange()
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
    private(set) var timerStartedAtRaw: String?
    /// Highest row index applied; the forward-only guard.
    private var confirmedIndex = 0
    /// ONE engine serves all five reveal mechanics (Section 3). Built at init
    /// with a nil transport (pure-local path: compose/seal render, bothSealed
    /// never fires); startRemoteSync attaches the real wire adapter.
    let revealEngine: RevealEngine
    /// The engine holds its transport weak — the store retains the adapter.
    private var revealTransportAdapter: RevealTransportAdapter?

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
            self?.revealEngine.applyBroadcast(envelope)
        }
        coordinator.onResendRequest = { [weak self] cardId in
            self?.receiveRevealResendRequest(cardId: cardId)
        }
        let adapter = RevealTransportAdapter(
            realtime: realtime,
            sessionId: sid,
            role: sessionRole,
            coordinator: coordinator
        )
        revealTransportAdapter = adapter
        revealEngine.attachTransport(adapter)
        coordinator.start()
        isLive = true
    }

    /// The partner asked for a re-send: the engine answers by re-broadcasting
    /// its buffered envelope (Section 3).
    func receiveRevealResendRequest(cardId: String) {
        revealEngine.receiveResendRequest(cardId: cardId)
    }

    func teardown() {
        coordinator?.stop()
        coordinator = nil
        revealEngine.teardown()
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
           hand.indices.contains(dto.currentIndex) {
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
        if indexChanged {
            startTimerIfLeader()
            cardDidChange()      // Section 3: beats / back / reveal per-card setup
            persistProgressCheckpoint()
        }
        isPaused = (dto.status == CuratedSessionStatus.paused.rawValue)
        if dto.status == CuratedSessionStatus.complete.rawValue, phase == .session {
            finishSession()                       // partner finished → follow to close
        }
        if dto.status == CuratedSessionStatus.abandoned.rawValue, phase == .session {
            endEarly()                            // partner confirmed exit
        }
        revealEngine.applyRow(dto.revealState)
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
            confirmedIndex = dto.currentIndex
            index = min(dto.currentIndex, max(0, hand.count - 1))
            timerStartedAtRaw = dto.timerStartedAt
            liveTimers = dto.perCardTimer
            isPaused = (dto.status == CuratedSessionStatus.paused.rawValue)
            if phase == .airlock { phase = .session }
            startRemoteSync()
            refreshTimer()
            cardDidChange()
            restoreReveal(flags: currentCard.flatMap { dto.revealState[$0.id] })
        default:
            break   // lobby/airlock: AirlockStore owns those states
        }
    }

    // MARK: - Card presentation state (Section 3: beats, card backs, reveal gate)

    /// The views need the role for role-aware prompts (Mirror). Exposing the
    /// private let through a computed keeps the stored property private.
    var sessionRoleForViews: SessionRole { sessionRole }

    /// Set true by restoreReveal when the row said "sealed" but the payload
    /// died with the process — the reveal views show the re-compose copy once.
    private(set) var revealRecomposing = false

    /// The beat waiting to play before the current card. nil = none / done.
    private(set) var activeContextBeat: (type: ContextBeatType, copy: String)?
    /// Beats play once per card per sitting.
    private var beatShownCardIds: Set<String> = []
    /// backCopy flip state for the current card.
    private(set) var showingCardBack = false

    /// A reveal card may only advance once revealed (the ceremony is the card).
    var revealSatisfied: Bool {
        guard currentCard?.isRevealMechanic == true else { return true }
        return revealEngine.phase == .revealed
    }

    func dismissContextBeat() {
        activeContextBeat = nil
    }

    func flipCardBack() {
        guard currentCard?.hasBackCopy == true else { return }
        showingCardBack = true
    }

    /// Central per-card setup. Called on session start and EVERY index move —
    /// the local path from advanceOrFinish, the live path from applyRemoteRow
    /// when the echoed current_index changes (never both for one move: the
    /// echo of our own advance lands on an index we already occupy).
    func cardDidChange() {
        showingCardBack = false
        revealRecomposing = false
        activeContextBeat = nil

        guard let card = currentCard else { return }

        if card.hasContextBeat,
           card.contextBeatType == .interstitial,
           let copy = card.contextBeatCopy,
           !beatShownCardIds.contains(card.id) {
            beatShownCardIds.insert(card.id)
            activeContextBeat = (.interstitial, copy)
        }

        if card.isRevealMechanic {
            revealEngine.beginCard(card.id)
        } else {
            revealEngine.teardown()
        }
    }

    /// Reconnect restore for the current card (resumeIfNeeded calls this after
    /// rebuilding state from fetchOpenSession). A sealed flag with no local
    /// payload means the answer died with the process → whole-card clear +
    /// re-compose (spec §5).
    func restoreReveal(flags: RevealCardState?) {
        guard let card = currentCard, card.isRevealMechanic else { return }
        let flags = flags ?? RevealCardState()
        let outcome = revealEngine.restore(
            cardId: card.id,
            mySealed: flags.sealed(for: sessionRole),
            partnerSealed: flags.sealed(for: sessionRole == .a ? .b : .a),
            revealed: flags.revealed
        )
        revealRecomposing = (outcome == .recompose)
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

    /// Whether tonight's sitting actually covered the whole hand. "End well"
    /// mid-deck is a clean close, not a completion — the deck stays resumable.
    private var reachedEndOfHand: Bool { records.count >= hand.count }

    /// Writes the completed CardSession + CardResults + DeckProgress (mirrors
    /// SessionStore) and moves to the close. The reflection is written later,
    /// only if the user saves one.
    private func finishSession() {
        persistSession()
        liveComplete()
        UserDefaults.standard.set(true, forKey: UserDefaultsKey.hasCompletedCoupleSession)
        phase = .close
    }

    /// Upsert this couple+deck's DeckProgress mid-play: where we are, when we
    /// first opened it, when we last touched it. Runs on session start and on
    /// every index move so an abandoned sitting is resumable from the builder.
    private func persistProgressCheckpoint() {
        guard let coupleId = appState.coupleId else { return }
        let deckId = hand.first?.deckId ?? "unknown"
        let context = ModelContext(modelContainer)
        var fetch = FetchDescriptor<DeckProgress>(
            predicate: #Predicate { $0.coupleId == coupleId && $0.deckId == deckId }
        )
        fetch.fetchLimit = 1
        let progress: DeckProgress
        if let existing = try? context.fetch(fetch).first {
            progress = existing
        } else {
            progress = DeckProgress(coupleId: coupleId, deckId: deckId)
            context.insert(progress)
        }
        if progress.firstOpenedAt == nil { progress.firstOpenedAt = Date() }
        progress.lastPlayedAt = Date()
        progress.currentCardIndex = index
        try? context.saveWithLogging()
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

            // A deck is COMPLETED only when the sitting covered the whole hand;
            // "End well" mid-deck keeps it in progress, resumable at this index.
            var progressFetch = FetchDescriptor<DeckProgress>(
                predicate: #Predicate { $0.coupleId == coupleId && $0.deckId == deckId }
            )
            progressFetch.fetchLimit = 1
            let progress: DeckProgress
            if let existing = try context.fetch(progressFetch).first {
                progress = existing
            } else {
                progress = DeckProgress(coupleId: coupleId, deckId: deckId)
                context.insert(progress)
            }
            if progress.firstOpenedAt == nil { progress.firstOpenedAt = Date() }
            progress.lastPlayedAt = Date()
            if reachedEndOfHand {
                progress.completedAt = Date()
                progress.currentCardIndex = 0
            } else {
                progress.currentCardIndex = min(records.count, max(0, hand.count - 1))
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

// MARK: - RevealTransportAdapter (glue: engine seam → real wire)

/// Adapts the Section-1 service (row flag merge-writes) + Section-2 coordinator
/// (broadcast) to the engine's RevealTransporting seam. Owned per-session by
/// CoupleSessionStore; holds no state of its own.
@MainActor
final class RevealTransportAdapter: RevealTransporting {

    private let realtime: RealtimeSessionService
    private let sessionId: UUID
    private let role: SessionRole
    private weak var coordinator: SessionSyncCoordinator?

    init(
        realtime: RealtimeSessionService,
        sessionId: UUID,
        role: SessionRole,
        coordinator: SessionSyncCoordinator?
    ) {
        self.realtime = realtime
        self.sessionId = sessionId
        self.role = role
        self.coordinator = coordinator
    }

    func setSealed(cardId: String) async throws {
        try await realtime.setSealed(sessionId: sessionId, cardId: cardId, role: role)
    }

    func setRevealed(cardId: String) async throws {
        try await realtime.setRevealed(sessionId: sessionId, cardId: cardId)
    }

    func clearRevealCard(cardId: String) async throws {
        try await realtime.clearRevealCard(sessionId: sessionId, cardId: cardId)
    }

    func sendEnvelope(_ envelope: RevealEnvelope) {
        coordinator?.sendReveal(envelope)
    }

    func requestResend(cardId: String) {
        coordinator?.sendResendRequest(cardId: cardId)
    }
}
