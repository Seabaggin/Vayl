//
//  SessionSyncCoordinator.swift
//  Vayl
//
//  Consumer side of the two-device session. Owns exactly one channel:
//  register streams BEFORE subscribeWithError(), track presence AFTER
//  (ordering per the verified PresenceDebugStore pattern). Fans presence /
//  rowUpdates / revealBroadcasts / resendRequests into async loops and pumps
//  typed deltas back to CoupleSessionStore. No UI knowledge, no SwiftData.
//
//  Stream factories (presenceChanges/rowUpdates/revealBroadcasts/resendRequests/
//  sendReveal/requestResend) are Section 1 service extensions.
//

import Foundation
import Supabase
import OSLog

private let logger = Logger(subsystem: "com.vayl.app", category: "SessionSyncCoordinator")

@MainActor
final class SessionSyncCoordinator {

    private let service: RealtimeSessionService
    private let coupleId: UUID
    private let userId: UUID
    private let sessionId: UUID

    private var channel: RealtimeChannelV2?
    private var tasks: [Task<Void, Never>] = []

    /// True once subscribed; the store's reconnect check reads this.
    private(set) var isConnected = false

    // Callbacks into the store; all fire on the MainActor.
    var onRowUpdate: ((CuratedSessionDTO) -> Void)?
    var onPresence: ((Set<String>) -> Void)?
    var onReveal: ((RevealEnvelope) -> Void)?
    var onResendRequest: ((String) -> Void)?
    var onSubscribeFailed: ((String) -> Void)?

    init(service: RealtimeSessionService, coupleId: UUID, userId: UUID, sessionId: UUID) {
        self.service = service
        self.coupleId = coupleId
        self.userId = userId
        self.sessionId = sessionId
    }

    /// Tracks who is currently on the channel so the presence callback carries
    /// the full present set, not just the delta.
    private var presentIds: Set<String> = []

    func start() {
        guard channel == nil else { return }
        let channel = service.sessionChannel(coupleId: coupleId, userId: userId)
        self.channel = channel

        // Register BEFORE subscribe — ordering matters.
        let presence = service.presenceChanges(on: channel)
        let rows = service.rowUpdates(on: channel, sessionId: sessionId)
        let reveals = service.revealBroadcasts(on: channel)
        let resends = service.resendRequests(on: channel)

        tasks.append(Task { [weak self] in
            guard let self else { return }
            do {
                try await channel.subscribeWithError()
                try await self.service.trackPresence(on: channel, userId: self.userId)
                self.isConnected = true
            } catch {
                logger.warning("session channel subscribe failed: \(error.localizedDescription)")
                self.onSubscribeFailed?(error.localizedDescription)
            }
        })
        tasks.append(Task { [weak self] in
            for await delta in presence {
                guard let self else { return }
                self.presentIds.formUnion(delta.joinedIds)
                self.presentIds.subtract(delta.leftIds)
                self.onPresence?(self.presentIds)
            }
        })
        tasks.append(Task { [weak self] in
            for await dto in rows { self?.onRowUpdate?(dto) }
        })
        tasks.append(Task { [weak self] in
            for await envelope in reveals { self?.onReveal?(envelope) }
        })
        tasks.append(Task { [weak self] in
            for await cardId in resends { self?.onResendRequest?(cardId) }
        })
    }

    /// Reveal payloads out (Section 3's engine calls through the store).
    func sendReveal(_ envelope: RevealEnvelope) {
        guard let channel, isConnected else { return }
        Task { try? await service.sendReveal(envelope, on: channel) }
    }

    /// Ask the partner device to re-send its payload for one card.
    func sendResendRequest(cardId: String) {
        guard let channel, isConnected else { return }
        Task { try? await service.requestResend(cardId: cardId, on: channel) }
    }

    func stop() {
        tasks.forEach { $0.cancel() }
        tasks.removeAll()
        isConnected = false
        presentIds = []
        if let channel {
            self.channel = nil
            Task { await service.leaveChannel(channel) }
        }
    }
}
