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
    /// The catalog's one-line deck tagline (e.g. "Start slow. Find your
    /// footing."). Reused as the pre-session beat's dealer-copy line —
    /// wired here rather than in the view because a View may not call
    /// DeckCatalogService directly. There is no dedicated "dealer intro
    /// line" content field yet; this is the closest existing warm line.
    private(set) var deckSubtitle: String?
    private(set) var localProfileId: UUID?
    private let perCardTimerSeconds: [String: Int]
    private let sessionStartedAt = Date()
    /// Shared session start — the row's created_at, so both devices show the
    /// same elapsed time on the close screen. nil on the pure-local path
    /// (falls back to the local sessionStartedAt).
    private var sharedStartedAt: Date?

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
    ///
    /// The close's slider UI was retired in the V6 reflection redesign (words +
    /// note only). The persisted field stays on SessionReflection so the Map's
    /// trend derivation keeps its schema, but with no control feeding it these
    /// hold a neutral centre — a reflection contributes no carried/heard signal
    /// rather than a phantom one.
    var carriedBalance: Double = 0.5
    /// "did you feel heard" — 0 = not really, 1 = fully. Neutral centre (see above).
    var feltHeard: Double = 0.5
    var reflectionNote: String = ""

    /// Set when the CardSession persists on entering close — links the reflection.
    private(set) var savedSessionId: UUID?

    /// True once a real sitting reached the close (a CardSession was written).
    /// A bail on the very first card leaves it false, so the cover leaves
    /// quietly with no "kept" beat and nothing logged to the Map.
    private(set) var sessionLogged = false

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
    private let deckCatalog: DeckCatalogService

    // MARK: - Init

    init(
        launch: SessionLaunch,
        modelContainer: ModelContainer,
        appState: AppState,
        realtime: RealtimeSessionService? = nil,
        presenceSeconds: Double = 1.4,
        transitionSeconds: Double = 2.5,          // 🎚️ spec 4.5: ~2.5s held beat
        budgetCheckSeconds: Double = 15,          // 🎚️ budget re-check cadence (minutes-granularity budget)
        enqueueSync: (@MainActor (SessionRecordPayload) -> Void)? = nil,
        deckCatalog: DeckCatalogService? = nil
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
        self.budgetCheckSeconds = budgetCheckSeconds
        self.liveGlobalTimerSeconds = launch.session?.globalTimerSeconds
        // A two-device launch resolves its own realtime service when the caller
        // doesn't inject one — the container view no longer constructs Services
        // (4-layer). A local/DEBUG launch (session == nil) stays realtime-free.
        self.realtime = realtime ?? (launch.session != nil ? RealtimeSessionService() : nil)
        self.initiatorId = launch.session?.initiatorId
        self.deckCatalog = deckCatalog ?? DeckCatalogService()
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
        applySharedStart(launch.session?.createdAt)
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
        // Deck title + tagline: resolve the pretty name/subtitle from the
        // catalog when possible.
        if let deckId = hand.first?.deckId,
           let summary = (try? deckCatalog.loadSummaries())?
               .first(where: { $0.id == deckId }) {
            deckTitle = summary.title
            deckSubtitle = summary.subtitle
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

    /// Unified partner connection signal for the in-session presence pill —
    /// the live path (partnerPresentLive/partnerAway) when two-device, the
    /// mock path (partnerPresent) in local DEBUG.
    var partnerConnected: Bool {
        isLive ? (partnerPresentLive && !partnerAway && partnerHeartbeatFresh) : partnerPresent
    }

    /// Mirror cards: the subject alternates per card (deterministic from the
    /// index, identical on both devices); the other partner guesses.
    var mirrorSubjectIsMe: Bool { drawingRole == sessionRole }

    var isLastCard: Bool { index >= hand.count - 1 }

    /// Cards still to come after the current one — drives the fanned deck.
    var upcomingCount: Int { max(0, hand.count - index - 1) }

    var discussedCount: Int { records.filter { $0.status == .discussed }.count }
    var skippedCount: Int { records.filter { $0.status == .skipped }.count }

    /// Close-screen "cards deep" — the local discussed count floored at the
    /// shared row progress, so a device that relaunched mid-session (empty
    /// local records) still shows how far the couple actually got. Accepted
    /// tradeoff: after a relaunch this can count skipped cards too.
    var closeCardsDeep: Int { max(discussedCount, confirmedIndex) }

    /// Position label for the in-session header ("Card 3 · 8").
    var positionLabel: String { "\(index + 1) · \(hand.count)" }

    /// Cover-family screen 7 stat line: cards / duration. Uses the same floored
    /// card count as the close headline and the shared row start when available,
    /// so both devices agree on both numbers.
    var sessionStatLine: String {
        let count = closeCardsDeep
        let cards = "\(count) \(count == 1 ? "card" : "cards")"
        return "\(cards) · \(sessionDurationLabel)"
    }

    /// Close-screen duration meta — minutes only. The close headline already
    /// owns the card count ("N cards deep"), so its sub-line carries time, not
    /// a repeat of the same number.
    var sessionDurationLabel: String {
        let start = sharedStartedAt ?? sessionStartedAt
        let minutes = max(1, Int(Date().timeIntervalSince(start) / 60))
        return "\(minutes) min"
    }

    /// Anchors the shared start to the row's created_at (first writer wins —
    /// the row is created once, so every source agrees).
    private func applySharedStart(_ raw: String?) {
        guard sharedStartedAt == nil, let raw,
              let date = Self.isoFractional.date(from: raw) ?? Self.isoPlain.date(from: raw)
        else { return }
        sharedStartedAt = date
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

    /// DEBUG local path: cross the airlock into the transition. The
    /// pre-session beat (SessionDealIntroView) now owns the held beat and
    /// calls `introDidFinish()` when it lands the first card — see below.
    func confirmSynced() {
        guard phase == .airlock else { return }
        phase = .transition
    }

    /// AirlockStore reported active — cross into the held transition beat and
    /// start the remote mirror. The pre-session beat drives the rest of the
    /// hand-off via `introDidFinish()`.
    func airlockDidActivate() {
        guard phase == .airlock else { return }
        phase = .transition
        startRemoteSync()
    }

    /// SessionDealIntroView's `onComplete` — the pre-session beat has landed
    /// the first card as reading text, so this is where `.session` actually
    /// begins. Reproduces the union of what the old timer tail did on either
    /// path: `cardDidChange`/budget-watch/checkpoint applied on both the
    /// DEBUG-local and real paths identically, and `startTimerIfNeeded` is
    /// safe to call unconditionally because it internally guards on `isLive`
    /// (a no-op on the DEBUG-local path) — so one unified call covers both,
    /// no branching needed here.
    func introDidFinish() {
        guard phase == .transition else { return }
        phase = .session
        cardDidChange()      // Section 3: first card's beat/reveal setup
        startTimerIfNeeded()
        startSessionBudgetWatch()
        persistProgressCheckpoint()
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
        // Wrapping up on the very first card, with nothing recorded yet, is a
        // bail rather than a sitting: don't write a CardSession and skip the
        // close entirely. `index == 0` (not just an empty record set) keeps a
        // resumed session — which rebuilds `index` from the row while local
        // records start empty — on the normal logged-close path.
        if records.isEmpty && index == 0 {
            endWithoutLogging()
            return
        }
        recordCurrent(.skipped)
        finishSession()
    }

    /// The no-engagement bail: leave the cover without logging a session or
    /// showing the close. Marks the row abandoned so the partner's device
    /// follows to its own quiet exit (its `endEarly` hits this same guard).
    private func endWithoutLogging() {
        abandonRemoteSession()
        phase = .done   // sessionLogged stays false → container dismisses, no beat
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
                self.startTimerIfNeeded()
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

    // MARK: - Poll fallback (mirrors AirlockStore's self-healing — spec 2026-07-09 §1.5)

    /// Live transport mode. Flips to `.poll` on subscribe failure or a dead
    /// initial window (no signal within the watchdog); flips back to
    /// `.realtime` the moment a real stream signal arrives while polling.
    private(set) var transport: Transport = .realtime
    enum Transport: String { case realtime, poll }
    /// 🎚️ Poll heartbeat interval in seconds — matches AirlockStore's fallback cadence.
    private let sessionPollInterval: TimeInterval = 2.5
    /// 🎚️ Seconds with no row/presence signal after (re)subscribe before assuming
    /// the channel is dead. Covers only the initial window, never ongoing
    /// mid-session silence (silence is normal between advances).
    private let sessionWatchdogTimeout: TimeInterval = 10
    private var pollTask: Task<Void, Never>?
    private var watchdogTask: Task<Void, Never>?

    // MARK: - Liveness heartbeat (fast partner-disconnect detection)
    // Channel presence alone takes 30s+ to notice a hard-killed partner app
    // (the server only emits the leave after the Phoenix socket heartbeat
    // times out). So while live, each device stamps its own last_seen column
    // every heartbeatWriteInterval and POLLS the partner's every
    // heartbeatReadInterval — polling, never realtime row-UPDATEs, because
    // row-UPDATE pushes to a foregrounded joiner are unreliable here (known
    // gotcha). Freshness window > write interval x2 tolerates a slow tick.

    /// 🎚️ Seconds between this device's own last_seen stamps.
    private static let heartbeatWriteInterval: TimeInterval = 4
    /// 🎚️ Seconds between reads of the partner's last_seen.
    private static let heartbeatReadInterval: TimeInterval = 5
    /// 🎚️ A partner heartbeat older than this means "not connected".
    static let heartbeatFreshWindow: TimeInterval = 10

    /// Partner's most recent heartbeat, parsed. nil = never seen one this
    /// session — the pill then trusts presence alone (session start: presence
    /// already handles join, and null must not read as "not connected").
    private(set) var partnerLastSeenAt: Date?
    /// Heartbeat verdict folded into partnerConnected. true when the partner's
    /// heartbeat is within the freshness window OR was never seen.
    private(set) var partnerHeartbeatFresh = true
    private var heartbeatWriteTask: Task<Void, Never>?
    private var heartbeatReadTask: Task<Void, Never>?
    /// Any row or presence signal proves the pipe is live; clears the watchdog.
    private var sawAnySignalSinceSubscribe = false
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
        coordinator.onRowUpdate = { [weak self] dto in
            self?.registerLiveSignal()
            self?.applyRemoteRow(dto)
        }
        coordinator.onPresence = { [weak self] present in
            guard let self, let me = self.localProfileId else { return }
            self.registerLiveSignal()
            let partnerHere = present.contains { $0 != me.uuidString }
            self.partnerPresentLive = partnerHere
            if partnerHere { self.partnerReturned() } else { self.partnerLost() }
        }
        coordinator.onReveal = { [weak self] envelope in
            self?.revealEngine.applyBroadcast(envelope)
        }
        coordinator.onResendRequest = { [weak self] cardId in
            self?.receiveRevealResendRequest(cardId: cardId)
        }
        coordinator.onSubscribeFailed = { [weak self] reason in
            logger.warning("session channel subscribe failed, dropping to poll: \(reason)")
            self?.startPollFallback()
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
        armWatchdog()
        startHeartbeat()
    }

    /// Starts both heartbeat loops (own stamp out, partner read back). Runs on
    /// BOTH transports — the write side is what the partner's poll reads, and
    /// the read side is our only reliable view of the partner (realtime
    /// row-UPDATE delivery is unreliable; see the gotcha note above).
    /// Loops end themselves once the phase leaves the live flow.
    private func startHeartbeat() {
        guard heartbeatWriteTask == nil, let realtime, let sid = remoteSessionId else { return }
        let role = sessionRole
        heartbeatWriteTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let self, self.phase == .session || self.phase == .transition else { return }
                try? await realtime.touchLastSeen(sessionId: sid, role: role)
                try? await Task.sleep(for: .seconds(Self.heartbeatWriteInterval))
            }
        }
        heartbeatReadTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let self, self.phase == .session || self.phase == .transition else { return }
                if let raw = try? await realtime.fetchPartnerLastSeen(sessionId: sid, myRole: role) {
                    self.registerPartnerHeartbeat(raw: raw)
                }
                // Re-evaluate every tick even when the fetch failed or brought
                // nothing new — staleness alone must flip the pill.
                self.evaluatePartnerHeartbeat()
                try? await Task.sleep(for: .seconds(Self.heartbeatReadInterval))
            }
        }
    }

    private func stopHeartbeat() {
        heartbeatWriteTask?.cancel()
        heartbeatWriteTask = nil
        heartbeatReadTask?.cancel()
        heartbeatReadTask = nil
    }

    /// Parses and records a partner heartbeat timestamp. Internal (not private)
    /// so tests can drive the freshness computation directly.
    func registerPartnerHeartbeat(raw: String?) {
        guard let raw,
              let date = Self.isoFractional.date(from: raw) ?? Self.isoPlain.date(from: raw)
        else { return }
        // Forward-only: a lagging read can never regress a newer heartbeat.
        if let current = partnerLastSeenAt, date <= current { return }
        partnerLastSeenAt = date
    }

    /// One freshness tick: never-seen trusts presence alone (fresh); otherwise
    /// fresh = within the window. Internal so tests can inject `now`.
    func evaluatePartnerHeartbeat(now: Date = Date()) {
        guard let seen = partnerLastSeenAt else {
            partnerHeartbeatFresh = true
            return
        }
        partnerHeartbeatFresh = now.timeIntervalSince(seen) <= Self.heartbeatFreshWindow
    }

    /// A real row/presence callback fired — the pipe is alive. Cancels the
    /// watchdog's countdown and, if we'd already dropped to poll, recovers
    /// back to realtime (the coordinator reconnected on its own).
    private func registerLiveSignal() {
        sawAnySignalSinceSubscribe = true
        if transport == .poll {
            logger.info("realtime signal received while polling — recovering to realtime")
            pollTask?.cancel()
            pollTask = nil
            transport = .realtime
        }
    }

    /// No row/presence signal within the watchdog window after (re)subscribe:
    /// assume the channel is dead and start the poll fallback. Only ever fires
    /// for the initial post-subscribe window — ongoing mid-session silence
    /// (nobody advancing) is expected and never trips this.
    private func armWatchdog() {
        watchdogTask?.cancel()
        sawAnySignalSinceSubscribe = false
        watchdogTask = Task { @MainActor [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: .seconds(self.sessionWatchdogTimeout))
            guard !Task.isCancelled, !self.sawAnySignalSinceSubscribe, self.transport == .realtime else { return }
            logger.warning("no session signal within \(self.sessionWatchdogTimeout)s — dropping to poll")
            self.startPollFallback()
        }
    }

    /// Every sessionPollInterval seconds: heartbeat (writes our presence +
    /// re-reads the row) and mirror the result in, exactly like AirlockStore's
    /// poll loop. The row is server-authoritative and fully reconstructable
    /// (spec §5), so this is a complete substitute for the dead stream.
    private func startPollFallback() {
        guard transport != .poll else { return }
        transport = .poll
        pollTask?.cancel()
        pollTask = Task { @MainActor [weak self] in
            guard let self, let realtime = self.realtime, let coupleId = self.appState.coupleId else { return }
            while !Task.isCancelled {
                do {
                    let open = try await realtime.heartbeatOpenSession(coupleId: coupleId, role: self.sessionRole)
                    if let dto = open, dto.id == self.remoteSessionId {
                        self.applyRemoteRow(dto)
                        let partnerPresentInRow = (self.sessionRole == .a) ? dto.bPresent : dto.aPresent
                        self.partnerPresentLive = partnerPresentInRow
                        if partnerPresentInRow { self.partnerReturned() } else { self.partnerLost() }
                    } else if let sid = self.remoteSessionId {
                        // Our row is no longer "open": fetchOpenSession filters to
                        // openStatuses, so a partner-driven complete/abandoned reads
                        // back as nil (or a different newer row). Re-fetch OUR row
                        // by id with no status filter and mirror the terminal truth.
                        if let row = try await realtime.fetchSession(id: sid) {
                            self.applyRemoteRow(row)   // routes complete/abandoned
                        } else if self.phase == .session {
                            // A SUCCESSFUL by-id fetch with no row = the session is
                            // gone; treat as abandoned. A thrown error never lands
                            // here — that is just a failed tick, retried below.
                            self.endEarly()
                        }
                        if self.phase != .session { break }   // terminal applied — stop polling
                    }
                } catch {
                    logger.warning("session poll tick failed: \(error.localizedDescription)")
                }
                try? await Task.sleep(for: .seconds(self.sessionPollInterval))
            }
        }
    }

    /// The partner asked for a re-send: the engine answers by re-broadcasting
    /// its buffered envelope (Section 3).
    func receiveRevealResendRequest(cardId: String) {
        revealEngine.receiveResendRequest(cardId: cardId)
    }

    /// Call when `scenePhase` returns to `.active` during an open session. The
    /// OS drops the Realtime websocket on background, but leaves `coordinator`
    /// itself intact — this re-subscribes the channel and re-tracks presence
    /// via the coordinator's existing stop/start (both idempotent). No-op if
    /// the session isn't live or isn't remote-synced.
    func handleScenePhaseActive() {
        guard isLive, let coordinator else { return }
        pollTask?.cancel()
        pollTask = nil
        transport = .realtime
        coordinator.stop()
        coordinator.start()
        armWatchdog()
    }

    func teardown() {
        coordinator?.stop()
        coordinator = nil
        revealEngine.teardown()
        graceTask?.cancel()
        timerTask?.cancel()
        budgetTask?.cancel()
        budgetTask = nil
        pollTask?.cancel()
        pollTask = nil
        watchdogTask?.cancel()
        watchdogTask = nil
        stopHeartbeat()
    }

    /// Mirror the authoritative row. Index only ever moves forward.
    /// Internal (not private) so tests can drive the row mirror directly.
    func applyRemoteRow(_ dto: CuratedSessionDTO) {
        applySharedStart(dto.createdAt)
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
        // Rebuild the countdown ONLY when a timer input actually changed. Row
        // echoes now arrive every few seconds (the liveness heartbeat UPDATEs),
        // and an unconditional refreshTimer() cancelled/rebuilt the task on
        // every echo — momentarily resetting timerElapsed and re-firing the
        // elapsed haptic + UI flicker on an already-elapsed card every ~4s.
        let timerInputsChanged =
            dto.timerStartedAt != timerStartedAtRaw || dto.perCardTimer != liveTimers
        timerStartedAtRaw = dto.timerStartedAt
        liveTimers = dto.perCardTimer
        if timerInputsChanged || indexChanged { refreshTimer() }
        // Whole-session budget mirrors live from every echo; nil = no budget /
        // cleared by either phone's "We're still here" — dismiss any open check.
        liveGlobalTimerSeconds = dto.globalTimerSeconds
        if dto.globalTimerSeconds == nil { budgetCheckPresented = false }
        if indexChanged {
            startTimerIfNeeded()
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
            applySharedStart(dto.createdAt)
            confirmedIndex = dto.currentIndex
            index = min(dto.currentIndex, max(0, hand.count - 1))
            timerStartedAtRaw = dto.timerStartedAt
            liveTimers = dto.perCardTimer
            liveGlobalTimerSeconds = dto.globalTimerSeconds
            isPaused = (dto.status == CuratedSessionStatus.paused.rawValue)
            if phase == .airlock { phase = .session }
            startRemoteSync()
            refreshTimer()
            cardDidChange()
            startTimerIfNeeded()
            // Re-anchor at resume time — generous by design (no persisted anchor).
            startSessionBudgetWatch()
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

    /// EITHER device stamps the anchor when a timed card presents — the write
    /// is conditional server-side (only where timer_started_at IS NULL and
    /// current_index still matches), so first writer wins and a slow phone can
    /// never stamp a previous card. The echoed UPDATE starts both countdowns
    /// together, so timed cards keep a timer even when one phone is offline.
    func startTimerIfNeeded() {
        guard isLive, let realtime, let sid = remoteSessionId,
              currentCardLimit != nil else { return }
        let expected = index
        Task { @MainActor in
            try? await realtime.markTimerStartedIfEmpty(sessionId: sid, expectedIndex: expected)
        }
    }

    // MARK: - Whole-session budget (invisible; a soft "Still in it?" check, never a hard cut)

    /// The session budget in seconds, mirrored live from row echoes.
    /// nil = no budget / cleared ("We're still here" on either phone).
    private(set) var liveGlobalTimerSeconds: Int?
    /// True while the soft check overlay is up. Cleared by "We're still here"
    /// (local + row echo on the partner's phone) or by wrap-up ending the session.
    private(set) var budgetCheckPresented = false
    /// Local anchor: captured when THIS phone's phase enters .session (and
    /// re-captured on resume-after-kill — generous by design). Minutes-level
    /// budget tolerates the sub-second skew between the two phones' flips.
    private(set) var budgetAnchor: Date?
    /// 🎚️ Re-check cadence; injectable via init for tests.
    private let budgetCheckSeconds: Double
    private var budgetTask: Task<Void, Never>?

    /// Budget minutes for the check's subline copy.
    var budgetMinutes: Int { max(1, (liveGlobalTimerSeconds ?? 0) / 60) }

    /// Anchors the budget at .session entry and starts the invisible watch
    /// (a Task that sleeps and re-evaluates, mirroring the per-card timer).
    private func startSessionBudgetWatch() {
        budgetAnchor = Date()
        budgetTask?.cancel()
        budgetTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                self.evaluateSessionBudget()
                try? await Task.sleep(for: .seconds(self.budgetCheckSeconds))
            }
        }
    }

    /// One budget tick: fire the soft check when elapsed >= budget mid-session.
    /// A cleared budget (nil) never re-fires, and a paused room is never
    /// interrupted (the check fires on a later tick after resume instead —
    /// two stacked overlays would fight). Internal (not private) so tests
    /// can drive the threshold logic with an injected `now`.
    func evaluateSessionBudget(now: Date = Date()) {
        guard phase == .session, !budgetCheckPresented, !isPaused,
              let budget = liveGlobalTimerSeconds, budget > 0,
              let anchor = budgetAnchor,
              now.timeIntervalSince(anchor) >= Double(budget) else { return }
        budgetCheckPresented = true
    }

    /// "We're still here": clears the budget for BOTH phones via the row —
    /// the echo (nil) dismisses the check on the partner's phone too and the
    /// check never asks again this session.
    func budgetStillHere() {
        budgetCheckPresented = false
        liveGlobalTimerSeconds = nil
        guard isLive, let realtime, let sid = remoteSessionId else { return }
        Task { @MainActor in
            try? await realtime.setGlobalTimer(sessionId: sid, seconds: nil)
        }
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

    // MARK: - Safety (pause / presence grace)

    private var graceTask: Task<Void, Never>?

    func togglePause() {
        isPaused.toggle()
        guard isLive, let realtime, let sid = remoteSessionId else { return }
        let status: CuratedSessionStatus = isPaused ? .paused : .active
        Task { @MainActor in try? await realtime.setStatus(sessionId: sid, status: status) }
    }

    // Presence loss (called from the coordinator's presence callback).
    // One healthy phone is enough to finish a session: the lock-in already
    // established mutual consent, so a device dropping never pauses the
    // session. partnerAway is still tracked (presence pill, reveal notice).
    private func partnerLost() {
        guard isLive, phase == .session, graceTask == nil else { return }
        graceTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(15))
            guard !Task.isCancelled, !partnerPresentLive else { return }
            partnerAway = true
        }
    }

    private func partnerReturned() {
        graceTask?.cancel()
        graceTask = nil
        partnerAway = false
    }

    // MARK: - Close actions

    func toggleWord(_ word: String) {
        if reflectionWords.contains(word) { reflectionWords.remove(word) } else { reflectionWords.insert(word) }
    }

    /// True when the user marked at least one word or wrote a note — the only
    /// case worth writing a SessionReflection row for, and the signal the close
    /// sheet reads to guard a stray dismiss against discarding entered content.
    var reflectionHasContent: Bool {
        !reflectionWords.isEmpty
            || !reflectionNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Save the private reflection against the just-saved session, then dismiss.
    /// An empty reflection (no words, no note) writes nothing — Save on a blank
    /// field is the same clean close as Skip, not an empty row on the Map.
    func saveReflection() {
        if reflectionHasContent { persistReflection() }
        phase = .done
    }

    /// Decline the reflection — the session itself is already saved. A skip is
    /// an honest close, not a delete: if the user marked words or wrote a note
    /// before choosing to skip, keep them. Only a truly empty reflection is let
    /// go silently.
    func skipReflection() {
        if reflectionHasContent { persistReflection() }
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
        sessionLogged = true
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
    /// Uses `completeIfOpen` (not `setStatus`) so a device finishing because
    /// the partner abandoned never stomps an `abandoned` row back to complete.
    private func liveComplete() {
        guard realtime != nil, let sid = remoteSessionId else { return }
        let role = sessionRole
        Task { @MainActor in
            try? await self.realtime?.setPresence(sessionId: sid, role: role, present: false)
            try? await self.realtime?.completeIfOpen(sessionId: sid)
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

            // Two devices in the same session must upsert the SAME remote row —
            // key the payload by the shared curated_sessions id, falling back to
            // the local UUID only on the pure-local DEBUG path (remoteSessionId
            // == nil). Local SwiftData keeps using session.id everywhere else.
            enqueueSync(SessionRecordPayload(
                id: remoteSessionId ?? session.id,
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
