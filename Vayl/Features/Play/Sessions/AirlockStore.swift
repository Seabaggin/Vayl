//
//  AirlockStore.swift
//  Vayl
//
//  The two-device "both here → active" handshake brain (spec 2026-07-01 §4.3).
//  Owns ONLY the handshake: the curated_sessions channel (via AirlockTransport),
//  this device's SessionRole, the bandwidth + consent ladder, and the
//  server-authoritative flip to `active`. It does NOT own the card flow — that
//  stays in CoupleSessionStore. Wiring into the real .vaylCover is Section 2.
//
//  States: waitingForPartner → bothPresent → bandwidthSet → consented →
//  activating → active, plus failed(reason). The ladder is recomputed from
//  facts (partner presence, my commits) so a partner leaving pre-active drops
//  the ladder back; activating/active/failed are sticky.
//
//  Identity rule (hard): role derives from couple.partnerAId == myProfileId
//  where myProfileId is local SwiftData UserProfile.id. NEVER the auth id.
//
//  Poll fallback: transport connect failure OR no presence signal within
//  presenceTimeout (10s) drops to a 2s row-poll loop — same state machine,
//  worse latency, identical behavior (the row reconstructs everything).
//

import Foundation
import SwiftData
import Supabase
import OSLog

private let logger = Logger(subsystem: "com.vayl.app", category: "AirlockStore")

// MARK: - AirlockTransport (the store's seam — mocked in VaylTests)

/// Everything the handshake consumes. LiveAirlockTransport is the production
/// conformance; MockAirlockTransport (VaylTests) scripts the streams.
protocol AirlockTransport: AnyObject {
    func fetchOpenSession(coupleId: UUID) async throws -> CuratedSessionDTO?
    func setConsent(sessionId: UUID, role: SessionRole, consented: Bool) async throws
    func setPresence(sessionId: UUID, role: SessionRole, present: Bool) async throws
    func flipToActiveIfBoth(sessionId: UUID) async throws -> Bool
    func heartbeatOpenSession(coupleId: UUID, role: SessionRole) async throws -> CuratedSessionDTO?
    /// Fetches one row by id, NO status filter — a terminal (abandoned/complete)
    /// row still returns. The poll path uses this to notice a dead session when
    /// heartbeatOpenSession comes back nil (the row fell out of openStatuses).
    func fetchSession(id: UUID) async throws -> CuratedSessionDTO?
    /// Subscribes the channel and returns the live streams. Throws on
    /// subscribe failure (the store falls back to polling).
    func connect(coupleId: UUID, profileId: UUID, sessionId: UUID) async throws -> AirlockStreams
    /// Broadcasts one sync-round signal on the connected channel. Best-effort —
    /// loss is guarded by the sync coordinator's round timeout.
    func sendSyncSignal(_ signal: SyncSignal) async throws
    func disconnect() async
}

/// The live streams the airlock consumes. (Reveal broadcasts are the
/// player's concern — SessionSyncCoordinator, Section 2 — not the airlock's.)
struct AirlockStreams {
    let presence: AsyncStream<PresenceDelta>
    let rows: AsyncStream<CuratedSessionDTO>
    /// Partner sync-round signals (arm/go/release/cancel), sender-tagged.
    let sync: AsyncStream<SyncSignal>
}

// MARK: - LiveAirlockTransport (production conformance)

/// Owns the RealtimeChannelV2 lifecycle so the service stays a pure factory.
/// Ordering is load-bearing (PresenceDebugStore-proven): register BOTH stream
/// listeners BEFORE subscribeWithError(), track ONLY AFTER it succeeds.
final class LiveAirlockTransport: AirlockTransport {

    private let service: RealtimeSessionService
    private var channel: RealtimeChannelV2?

    init(service: RealtimeSessionService? = nil) {
        // Construct the default service on the main actor (this init's isolation).
        self.service = service ?? RealtimeSessionService()
    }

    func fetchOpenSession(coupleId: UUID) async throws -> CuratedSessionDTO? {
        try await service.fetchOpenSession(coupleId: coupleId)
    }

    func setConsent(sessionId: UUID, role: SessionRole, consented: Bool) async throws {
        try await service.setConsent(sessionId: sessionId, role: role, consented: consented)
    }

    func setPresence(sessionId: UUID, role: SessionRole, present: Bool) async throws {
        try await service.setPresence(sessionId: sessionId, role: role, present: present)
    }

    func flipToActiveIfBoth(sessionId: UUID) async throws -> Bool {
        try await service.flipToActiveIfBoth(sessionId: sessionId)
    }

    func heartbeatOpenSession(coupleId: UUID, role: SessionRole) async throws -> CuratedSessionDTO? {
        try await service.heartbeatOpenSession(coupleId: coupleId, role: role)
    }

    func fetchSession(id: UUID) async throws -> CuratedSessionDTO? {
        try await service.fetchSession(id: id)
    }

    func connect(coupleId: UUID, profileId: UUID, sessionId: UUID) async throws -> AirlockStreams {
        let channel = service.sessionChannel(coupleId: coupleId, userId: profileId)
        self.channel = channel
        // Listeners BEFORE subscribe.
        let presence = service.presenceChanges(on: channel)
        let rows = service.rowUpdates(on: channel, sessionId: sessionId)
        let sync = service.syncSignals(on: channel)
        try await channel.subscribeWithError()
        // Track AFTER subscribe.
        try await service.trackPresence(on: channel, userId: profileId)
        return AirlockStreams(presence: presence, rows: rows, sync: sync)
    }

    struct NotConnectedError: Error {}

    func sendSyncSignal(_ signal: SyncSignal) async throws {
        guard let channel else { throw NotConnectedError() }
        try await service.sendSyncSignal(signal, on: channel)
    }

    func disconnect() async {
        if let channel {
            self.channel = nil
            await service.leaveChannel(channel)
        }
    }
}

// MARK: - AirlockState

enum AirlockState: Equatable {
    case waitingForPartner
    case bothPresent
    case consented
    case activating
    case active(sessionId: UUID)
    case failed(reason: String)
    /// The row died before going active (abandoned/complete via realtime, or
    /// terminal/missing via poll). Sticky, like activating/active/failed — the
    /// container swaps to a calm "this session ended" screen and stops polling.
    case ended
}

// MARK: - AirlockStore

@Observable
@MainActor
final class AirlockStore {

    // MARK: - Public state (read surfaces for AirlockView / the harness)

    private(set) var state: AirlockState = .waitingForPartner
    /// Live transport mode. Flips to `.poll` on connect failure or presence timeout.
    private(set) var transport: Transport = .realtime
    private(set) var partnerPresent = false
    private(set) var selfConsented = false
    private(set) var partnerConsented = false
    private(set) var session: CuratedSessionDTO?
    /// The two-person sync lock-in round brain. Created once the realtime
    /// transport is connected; nil in poll mode (broadcasts need the channel),
    /// in which case AirlockView falls back to the per-device HoldToLockInRing.
    private(set) var sync: SyncLockInCoordinator?

    /// AirlockView's backstop visibility: the coordinator's local miss grind,
    /// OR asymmetric consent ("they're in and I can't get in" must never
    /// require grinding N local misses first). Only meaningful while the sync
    /// round exists — the fallback hold ring consents directly.
    var syncBackstopAvailable: Bool {
        guard let sync else { return false }
        return sync.backstopAvailable || (partnerConsented && !selfConsented)
    }

    enum Transport: String { case realtime, poll }

    // MARK: - Identity

    let coupleId: UUID
    let myProfileId: UUID
    let role: SessionRole

    private var partnerRole: SessionRole { role == .a ? .b : .a }

    // MARK: - Dependencies + tunables

    private let transportLayer: AirlockTransport
    /// 🎚️ Seconds with no presence signal before dropping to poll (default 10).
    private let presenceTimeout: TimeInterval
    /// 🎚️ Poll heartbeat interval in seconds (default 2).
    private let pollInterval: TimeInterval
    /// Sync lock-in feel tunables handed to the coordinator (default .standard).
    private let syncConfig: SyncConfig

    // MARK: - Private lifecycle

    private var presenceTask: Task<Void, Never>?
    private var rowsTask: Task<Void, Never>?
    private var syncTask: Task<Void, Never>?
    private var timeoutTask: Task<Void, Never>?
    private var pollTask: Task<Void, Never>?
    /// Any presence OR row signal proves the pipe is live and cancels the timeout.
    private var sawAnySignal = false
    /// The SERVER flip is idempotent (conditional update); this only avoids
    /// re-issuing it locally.
    private var didRequestFlip = false

    // MARK: - Init

    init(
        coupleId: UUID,
        myProfileId: UUID,
        role: SessionRole,
        transport: AirlockTransport? = nil,
        presenceTimeout: TimeInterval = 10,
        pollInterval: TimeInterval = 2,
        syncConfig: SyncConfig = .standard
    ) {
        self.coupleId = coupleId
        self.myProfileId = myProfileId
        self.role = role
        // Construct the default transport on the main actor (this init's isolation).
        self.transportLayer = transport ?? LiveAirlockTransport()
        self.presenceTimeout = presenceTimeout
        self.pollInterval = pollInterval
        self.syncConfig = syncConfig
    }

    /// Resolves this device's role from the LOCAL Couple (profile-id keyed).
    /// partnerAId == myProfileId → .a, else .b. NEVER supabase.auth's user id.
    /// Returns nil if the couple / profile can't be resolved locally (caller
    /// shows an error state).
    static func make(
        coupleId: UUID,
        modelContainer: ModelContainer,
        transport: AirlockTransport? = nil
    ) -> AirlockStore? {
        let context = ModelContext(modelContainer)
        guard let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first else {
            logger.error("make — no local UserProfile")
            return nil
        }
        var coupleFetch = FetchDescriptor<Couple>(predicate: #Predicate { $0.id == coupleId })
        coupleFetch.fetchLimit = 1
        guard let couple = try? context.fetch(coupleFetch).first else {
            logger.error("make — no local Couple \(coupleId)")
            return nil
        }
        let role: SessionRole = (couple.partnerAId == profile.id) ? .a : .b
        return AirlockStore(
            coupleId: coupleId,
            myProfileId: profile.id,
            role: role,
            transport: transport
        )
    }

    // MARK: - Entry

    /// The row is opened by the Builder/Lobby BEFORE the airlock (spec §5
    /// lifecycle) — the airlock only ever fetches. No open row = failed on a
    /// true first entry; on a restart (we already knew a session id) it means
    /// the row went terminal while we were away → ended, not failed.
    func start() async {
        do {
            guard let row = try await transportLayer.fetchOpenSession(coupleId: coupleId) else {
                if let knownId = session?.id {
                    let row = try? await transportLayer.fetchSession(id: knownId)
                    if row == nil
                        || row?.status == CuratedSessionStatus.abandoned.rawValue
                        || row?.status == CuratedSessionStatus.complete.rawValue {
                        logger.info("start: known session went terminal or missing — ended")
                        state = .ended
                        return
                    }
                }
                state = .failed(reason: "No open session for this couple.")
                return
            }
            session = row
            applyRow(row)
        } catch {
            logger.warning("fetch failed, dropping to poll: \(error.localizedDescription)")
            startPollFallback()
            return
        }

        guard let sessionId = session?.id else { return }

        let streams: AirlockStreams
        do {
            streams = try await transportLayer.connect(
                coupleId: coupleId, profileId: myProfileId, sessionId: sessionId
            )
            // Presence heartbeat boolean on the row too, so a poll-mode partner
            // still sees us (spec §4.3).
            try await transportLayer.setPresence(sessionId: sessionId, role: role, present: true)
            transport = .realtime
        } catch {
            logger.warning("connect failed, dropping to poll: \(error.localizedDescription)")
            await transportLayer.disconnect()
            startPollFallback()
            return
        }

        // Presence stream: partner joins/leaves, keyed by profile id.
        presenceTask = Task { [weak self] in
            guard let self else { return }
            for await delta in streams.presence {
                self.sawAnySignal = true
                let mine = self.myProfileId.uuidString
                if delta.joinedIds.contains(where: { $0 != mine }) { self.partnerPresent = true }
                if delta.leftIds.contains(where: { $0 != mine }) { self.partnerPresent = false }
                self.recomputeLadder()
                await self.tryFlipToActive()
            }
        }

        // Sync lock-in: the coordinator exists only while the channel is live
        // (broadcasts need it). Poll mode falls back to HoldToLockInRing.
        let coordinator = SyncLockInCoordinator(
            config: syncConfig,
            role: role,
            send: { [transportLayer] signal in
                try await transportLayer.sendSyncSignal(signal)
            },
            requestConsent: { [weak self] in
                await self?.consent() ?? false
            },
            isSessionActive: { [weak self] in
                // activating counts too: the flip is already requested (both
                // consented), so draining the success latch would only flash
                // an idle ring during the row echo.
                switch self?.state {
                case .active, .activating: return true
                default: return false
                }
            }
        )
        sync = coordinator

        // Sync stream: partner arm/go/release/cancel signals into the round brain.
        syncTask = Task { [weak self] in
            for await signal in streams.sync {
                self?.sync?.handle(signal)
            }
        }

        // Row stream: mirror partner facts + status, then check the flip.
        rowsTask = Task { [weak self] in
            guard let self else { return }
            for await row in streams.rows {
                self.sawAnySignal = true
                self.session = row
                self.applyRow(row)
                await self.tryFlipToActive()
            }
        }

        // No presence signal within the window → assume realtime is dead
        // (spec §4.3) and drop to poll.
        timeoutTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: .seconds(self.presenceTimeout))
            guard !Task.isCancelled, !self.sawAnySignal, self.transport == .realtime else { return }
            logger.warning("no presence signal within \(self.presenceTimeout)s — dropping to poll")
            await self.dropToPoll()
        }

        await debugAutoConsentIfRequested()
    }

    // MARK: - UI actions (this device)

    /// The 3-second lock-in press completes → this device consents. Returns
    /// whether the commit landed; the view un-latches its ring on false so the
    /// user can hold again instead of waiting on a consent that never wrote.
    @discardableResult
    func consent() async -> Bool {
        guard let sessionId = session?.id else { return false }
        do {
            try await transportLayer.setConsent(sessionId: sessionId, role: role, consented: true)
            selfConsented = true
            recomputeLadder()
            await tryFlipToActive()
            return true
        } catch {
            logger.warning("consent push failed: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - State ladder

    /// Recomputes the pre-activation ladder from facts. activating / active /
    /// failed are sticky and never regress from here.
    private func recomputeLadder() {
        switch state {
        case .activating, .active, .failed, .ended: return
        default: break
        }
        if selfConsented {
            state = .consented
        } else if partnerPresent {
            state = .bothPresent
        } else {
            state = .waitingForPartner
        }
    }

    /// Mirrors the row's partner-side facts + status into local state. Row
    /// presence booleans are the backstop for a poll-mode partner: in poll mode
    /// the row IS the presence signal, so it clears as well as sets (in
    /// realtime the stream owns clearing — the row only ever raises).
    private func applyRow(_ row: CuratedSessionDTO) {
        let partnerPresentInRow = (partnerRole == .a) ? row.aPresent : row.bPresent
        if transport == .poll {
            partnerPresent = partnerPresentInRow
        } else if partnerPresentInRow {
            partnerPresent = true
        }
        partnerConsented = (partnerRole == .a) ? row.aConsented : row.bConsented
        selfConsented = selfConsented || ((role == .a) ? row.aConsented : row.bConsented)

        if row.status == CuratedSessionStatus.active.rawValue {
            state = .active(sessionId: row.id)
        } else if row.status == CuratedSessionStatus.abandoned.rawValue
                    || row.status == CuratedSessionStatus.complete.rawValue {
            state = .ended
        } else {
            recomputeLadder()
        }
    }

    /// The EXACTLY-ONCE active flip. The server update is conditional (both
    /// present + both consented + still pre-active), so if both devices call
    /// it simultaneously exactly one write lands. Both devices then react to
    /// the row UPDATE, never to their own optimistic write (spec §4.3) —
    /// except in poll mode, where the winner advances locally.
    private func tryFlipToActive() async {
        if case .active = state { return }
        if case .failed = state { return }
        if case .ended = state { return }
        guard let sessionId = session?.id else { return }
        guard partnerPresent, selfConsented, partnerConsented, !didRequestFlip else { return }
        didRequestFlip = true
        state = .activating
        do {
            let didFlip = try await transportLayer.flipToActiveIfBoth(sessionId: sessionId)
            logger.info("flipToActive requested — thisDeviceWon=\(didFlip)")
            if didFlip, transport == .poll {
                state = .active(sessionId: sessionId)
            }
        } catch {
            didRequestFlip = false   // allow a retry on the next signal
            recomputeLadder()
            logger.warning("flipToActive failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Poll fallback

    private func dropToPoll() async {
        presenceTask?.cancel(); presenceTask = nil
        rowsTask?.cancel(); rowsTask = nil
        teardownSync()
        await transportLayer.disconnect()
        startPollFallback()
    }

    /// The sync round cannot run without the live channel — drop the
    /// coordinator so AirlockView falls back to the per-device hold ring.
    private func teardownSync() {
        syncTask?.cancel(); syncTask = nil
        sync?.teardown()
        sync = nil
    }

    /// Every pollInterval seconds: presence heartbeat + row re-read + ladder +
    /// flip check. Runs ONLY when realtime failed or timed out — it never
    /// regresses the realtime path.
    private func startPollFallback() {
        transport = .poll
        pollTask?.cancel()
        pollTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                do {
                    if let row = try await self.transportLayer.heartbeatOpenSession(
                        coupleId: self.coupleId, role: self.role
                    ) {
                        self.session = row
                        self.applyRow(row)
                        await self.tryFlipToActive()
                        if case .active = self.state { break }
                        if case .ended = self.state { break }
                    } else if let sessionId = self.session?.id {
                        // heartbeatOpenSession filters to openStatuses, so nil
                        // here means either the row went terminal or vanished
                        // — either way the session is dead, not merely absent.
                        let stillThere = try await self.transportLayer.fetchSession(id: sessionId)
                        if stillThere == nil
                            || stillThere?.status == CuratedSessionStatus.abandoned.rawValue
                            || stillThere?.status == CuratedSessionStatus.complete.rawValue {
                            logger.info("poll: session ended (terminal or missing)")
                            self.state = .ended
                            break
                        }
                    }
                } catch {
                    logger.warning("poll tick failed: \(error.localizedDescription)")
                }
                try? await Task.sleep(for: .seconds(self.pollInterval))
            }
        }
    }

    /// Debug/testing hook: force the poll path even if realtime is up.
    func forcePollMode() async {
        timeoutTask?.cancel(); timeoutTask = nil
        await dropToPoll()
    }

    // MARK: - Scene phase recovery

    /// iOS drops the realtime websocket on background, and the one-shot
    /// presence timeout has long since fired by the time we return — so simply
    /// waiting never recovers. Called when the container sees `scenePhase`
    /// return to `.active` while still in the airlock: tears down whatever
    /// tasks/transport are live and re-runs `start()` from scratch. A no-op
    /// once the handshake reached a sticky state (activating/active/failed/
    /// ended) — there is nothing left to recover. Does NOT touch
    /// `selfConsented`: our own commit already landed on the row.
    func handleScenePhaseActive() async {
        switch state {
        case .activating, .active, .failed, .ended: return
        default: break
        }
        presenceTask?.cancel(); presenceTask = nil
        rowsTask?.cancel(); rowsTask = nil
        timeoutTask?.cancel(); timeoutTask = nil
        pollTask?.cancel(); pollTask = nil
        teardownSync()
        await transportLayer.disconnect()
        sawAnySignal = false
        await start()
    }

    #if DEBUG
    /// Simulator harness hook: launch both devices with
    /// `-vaylDebugAutoAirlock` to bypass the press-and-hold gesture while still
    /// exercising the real backend presence, consent, and active-flip path.
    private var debugAutoAirlockEnabled: Bool {
        CommandLine.arguments.contains("-vaylDebugAutoAirlock")
    }
    #endif

    private func debugAutoConsentIfRequested() async {
        #if DEBUG
        guard debugAutoAirlockEnabled else { return }
        logger.info("Debug auto-airlock enabled — committing local consent")
        _ = await consent()
        #endif
    }

    // MARK: - Teardown

    /// Clean exit: presence boolean false on the row (spec §4.3), streams down.
    func leave() {
        presenceTask?.cancel(); presenceTask = nil
        rowsTask?.cancel(); rowsTask = nil
        timeoutTask?.cancel(); timeoutTask = nil
        pollTask?.cancel(); pollTask = nil
        teardownSync()
        let transportLayer = self.transportLayer
        let role = self.role
        let sessionId = session?.id
        Task {
            if let sessionId {
                try? await transportLayer.setPresence(sessionId: sessionId, role: role, present: false)
            }
            await transportLayer.disconnect()
        }
    }
}
