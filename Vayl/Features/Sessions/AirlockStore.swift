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
    func setBandwidth(sessionId: UUID, role: SessionRole, value: Float) async throws
    func setConsent(sessionId: UUID, role: SessionRole, consented: Bool) async throws
    func setPresence(sessionId: UUID, role: SessionRole, present: Bool) async throws
    func flipToActiveIfBoth(sessionId: UUID) async throws -> Bool
    func heartbeatOpenSession(coupleId: UUID, role: SessionRole) async throws -> CuratedSessionDTO?
    /// Subscribes the channel and returns the live streams. Throws on
    /// subscribe failure (the store falls back to polling).
    func connect(coupleId: UUID, profileId: UUID, sessionId: UUID) async throws -> AirlockStreams
    func disconnect() async
}

/// The two live streams the airlock consumes. (Reveal broadcasts are the
/// player's concern — SessionSyncCoordinator, Section 2 — not the airlock's.)
struct AirlockStreams {
    let presence: AsyncStream<PresenceDelta>
    let rows: AsyncStream<CuratedSessionDTO>
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

    func setBandwidth(sessionId: UUID, role: SessionRole, value: Float) async throws {
        try await service.setBandwidth(sessionId: sessionId, role: role, value: value)
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

    func connect(coupleId: UUID, profileId: UUID, sessionId: UUID) async throws -> AirlockStreams {
        let channel = service.sessionChannel(coupleId: coupleId, userId: profileId)
        self.channel = channel
        // Listeners BEFORE subscribe.
        let presence = service.presenceChanges(on: channel)
        let rows = service.rowUpdates(on: channel, sessionId: sessionId)
        try await channel.subscribeWithError()
        // Track AFTER subscribe.
        try await service.trackPresence(on: channel, userId: profileId)
        return AirlockStreams(presence: presence, rows: rows)
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
    case bandwidthSet
    case consented
    case activating
    case active(sessionId: UUID)
    case failed(reason: String)
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
    private(set) var selfBandwidthCommitted = false
    private(set) var selfConsented = false
    private(set) var partnerConsented = false
    private(set) var session: CuratedSessionDTO?

    /// min(a_bandwidth, b_bandwidth) once BOTH are on the row — the session's
    /// depth ceiling (spec §4.3). Each device computes it independently and
    /// deterministically; neither partner's raw reading is ever displayed.
    var depthCeiling: Float? {
        guard let a = session?.aBandwidth, let b = session?.bBandwidth else { return nil }
        return min(a, b)
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

    // MARK: - Private lifecycle

    private var presenceTask: Task<Void, Never>?
    private var rowsTask: Task<Void, Never>?
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
        pollInterval: TimeInterval = 2
    ) {
        self.coupleId = coupleId
        self.myProfileId = myProfileId
        self.role = role
        // Construct the default transport on the main actor (this init's isolation).
        self.transportLayer = transport ?? LiveAirlockTransport()
        self.presenceTimeout = presenceTimeout
        self.pollInterval = pollInterval
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
    /// lifecycle) — the airlock only ever fetches. No open row = failed.
    func start() async {
        do {
            guard let row = try await transportLayer.fetchOpenSession(coupleId: coupleId) else {
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
    }

    // MARK: - UI actions (this device)

    /// Bandwidth slider commit (Light/Open/Deep detent as a 0-1 Float).
    /// Set privately; the raw reading is never shown to the partner.
    func commitBandwidth(_ value: Float) async {
        guard let sessionId = session?.id else { return }
        do {
            try await transportLayer.setBandwidth(sessionId: sessionId, role: role, value: value)
            selfBandwidthCommitted = true
            recomputeLadder()
        } catch {
            logger.warning("bandwidth push failed: \(error.localizedDescription)")
        }
    }

    /// The 3-second lock-in press completes → this device consents.
    func consent() async {
        guard let sessionId = session?.id else { return }
        do {
            try await transportLayer.setConsent(sessionId: sessionId, role: role, consented: true)
            selfConsented = true
            recomputeLadder()
            await tryFlipToActive()
        } catch {
            logger.warning("consent push failed: \(error.localizedDescription)")
        }
    }

    // MARK: - State ladder

    /// Recomputes the pre-activation ladder from facts. activating / active /
    /// failed are sticky and never regress from here.
    private func recomputeLadder() {
        switch state {
        case .activating, .active, .failed: return
        default: break
        }
        if selfConsented {
            state = .consented
        } else if selfBandwidthCommitted, partnerPresent {
            state = .bandwidthSet
        } else if partnerPresent {
            state = .bothPresent
        } else {
            state = .waitingForPartner
        }
    }

    /// Mirrors the row's partner-side facts + status into local state. Row
    /// presence booleans are the backstop for a poll-mode partner.
    private func applyRow(_ row: CuratedSessionDTO) {
        let partnerPresentInRow = (partnerRole == .a) ? row.aPresent : row.bPresent
        if partnerPresentInRow { partnerPresent = true }
        partnerConsented = (partnerRole == .a) ? row.aConsented : row.bConsented
        selfConsented = selfConsented || ((role == .a) ? row.aConsented : row.bConsented)
        let myBandwidthInRow = (role == .a) ? row.aBandwidth : row.bBandwidth
        if myBandwidthInRow != nil { selfBandwidthCommitted = true }

        if row.status == CuratedSessionStatus.active.rawValue {
            state = .active(sessionId: row.id)
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
        await transportLayer.disconnect()
        startPollFallback()
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

    // MARK: - Teardown

    /// Clean exit: presence boolean false on the row (spec §4.3), streams down.
    func leave() {
        presenceTask?.cancel(); presenceTask = nil
        rowsTask?.cancel(); rowsTask = nil
        timeoutTask?.cancel(); timeoutTask = nil
        pollTask?.cancel(); pollTask = nil
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
