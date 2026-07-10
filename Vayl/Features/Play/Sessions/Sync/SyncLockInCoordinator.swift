//
//  SyncLockInCoordinator.swift
//  Vayl
//
//  The airlock sync round's brain (spec 2026-07-08 §"Where it lives"). Owned by
//  AirlockStore, created once the realtime transport is connected. Owns ONLY the
//  round lifecycle: arming, the shared start (role .a leads with `go`), the
//  local sweep clock anchor, release capture, deterministic judging via
//  SyncRound (both devices judge independently and agree), the miss counter
//  driving silent easing, the round timeout (broadcast-loss guard), and the
//  backstop flag. On success it calls the injected consent closure — the
//  server-authoritative flip in AirlockStore is untouched.
//
//  It never touches the channel directly: sends go through the injected `send`
//  closure (AirlockTransport.sendSyncSignal), and incoming signals arrive via
//  `handle(_:)` from AirlockStore's stream loop. Own echoes are ignored by role.
//
//  Timeout verdict decision (noted per the punch list): a round where the
//  partner's release never arrives is INCONCLUSIVE — it counts as a miss for
//  easing but shows the neutral `.soClose(gapDegrees: 0)` "So close. Once more?"
//  copy, never a blame verdict, because we genuinely don't know what happened.
//

import Foundation
import OSLog

private let logger = Logger(subsystem: "com.vayl.app", category: "SyncLockInCoordinator")

@Observable
@MainActor
final class SyncLockInCoordinator {

    // MARK: - Read surface (drives SyncLockInRing)

    private(set) var phase: SyncRingPhase = .idle
    /// Consecutive misses — drives SyncConfig.tolerance(afterMisses:), reset on success.
    private(set) var misses = 0
    /// After backstopAfterMisses consecutive misses, AirlockView shows the
    /// quiet "enter together anyway" button.
    private(set) var backstopAvailable = false

    let config: SyncConfig
    let role: SessionRole

    // MARK: - Injected seams

    private let send: (SyncSignal) async throws -> Void
    /// AirlockStore.consent() — returns whether the commit landed.
    private let requestConsent: () async -> Bool
    /// Whether the session already flipped to active (AirlockStore.state).
    /// Gates the success-latch drain: a passed round whose flip never lands
    /// (partner missed on THEIR phone) must not latch this device forever.
    private let isSessionActive: () -> Bool

    // MARK: - Round state

    private var partnerArmed = false
    private var myRelease: SyncRelease?
    private var partnerRelease: SyncRelease?
    private var judged = false
    private var roundTask: Task<Void, Never>?
    private var timeoutTask: Task<Void, Never>?
    private var resultResetTask: Task<Void, Never>?

    init(
        config: SyncConfig = .standard,
        role: SessionRole,
        send: @escaping (SyncSignal) async throws -> Void,
        requestConsent: @escaping () async -> Bool,
        isSessionActive: @escaping () -> Bool
    ) {
        self.config = config
        self.role = role
        self.send = send
        self.requestConsent = requestConsent
        self.isSessionActive = isSessionActive
    }

    // MARK: - Local gestures (from SyncLockInRing via AirlockView)

    /// Local press-hold begins. Broadcasts `arm`; if the partner is already
    /// armed the shared start proceeds immediately.
    func arm() {
        guard case .idle = phase else { return }
        resultResetTask?.cancel(); resultResetTask = nil
        phase = .arming
        broadcast(.arm(role))
        maybeGo()
    }

    /// Local release DURING the sweep. `fraction` is the elapsed fraction of
    /// the sweep from the ring's own clock (≥1 = overshoot).
    func release(fraction: Double) {
        guard case .sweeping = phase, myRelease == nil else { return }
        myRelease = currentRound.classify(elapsedFraction: fraction)
        broadcast(.release(role: role, angle: fraction * 360))
        judgeIfReady()
    }

    /// Local let-go BEFORE the sweep (arming / countdown) — cancel for both.
    func disarm() {
        switch phase {
        case .arming, .countdown:
            broadcast(.cancel(role))
            resetRound()
        default:
            break
        }
    }

    /// Teardown from AirlockStore (leave / drop-to-poll / scene restart).
    func teardown() {
        roundTask?.cancel(); roundTask = nil
        timeoutTask?.cancel(); timeoutTask = nil
        resultResetTask?.cancel(); resultResetTask = nil
    }

    // MARK: - Partner signals (from AirlockStore's stream loop)

    func handle(_ signal: SyncSignal) {
        guard signal.senderRole != role else { return }   // ignore own echoes
        switch signal {
        case .arm:
            partnerArmed = true
            maybeGo()
        case .go:
            // BOTH devices run the 3-2-1 from their own go receipt; the leader
            // already started from its send, so a leader ignores this by phase.
            startRoundIfArming()
        case .release(_, let angle):
            guard !judged, partnerRelease == nil else { return }
            switch phase {
            case .countdown, .sweeping:
                partnerRelease = currentRound.classify(elapsedFraction: angle / 360)
                judgeIfReady()
            default:
                break
            }
        case .cancel:
            if case .result(.inSync) = phase { return }   // success already latched
            resetRound()
        }
    }

    // MARK: - Shared start

    private var currentRound: SyncRound { SyncRound(config: config, misses: misses) }

    /// Leader rule: role .a, locally armed, partner armed → broadcast `go` and
    /// start from the send. The follower starts from its `go` receipt.
    private func maybeGo() {
        guard role == .a, partnerArmed, case .arming = phase else { return }
        broadcast(.go(role))
        startRoundIfArming()
    }

    private func startRoundIfArming() {
        guard case .arming = phase else { return }
        roundTask?.cancel()
        roundTask = Task { [weak self] in
            guard let self else { return }
            for beat in [3, 2, 1] {
                self.phase = .countdown(beat)
                try? await Task.sleep(for: .seconds(self.config.countdownStepSeconds))
                if Task.isCancelled { return }
            }
            self.phase = .sweeping(startedAt: Date())
            self.startRoundTimeout()
        }
    }

    /// Broadcast-loss guard (spec risk #2): if the partner's release never
    /// arrives within sweep + margin, the round is inconclusive — gentle reset,
    /// counts as a miss for easing, neutral "once more?" copy.
    private func startRoundTimeout() {
        timeoutTask?.cancel()
        timeoutTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: .seconds(self.config.sweepSeconds + self.config.roundTimeoutMarginSeconds))
            guard !Task.isCancelled, !self.judged else { return }
            logger.info("sync round timed out waiting for the partner release — inconclusive miss")
            self.judged = true
            self.recordMiss(showing: .soClose(gapDegrees: 0))
        }
    }

    // MARK: - Judging

    private func judgeIfReady() {
        guard let mine = myRelease, let theirs = partnerRelease, !judged else { return }
        judged = true
        timeoutTask?.cancel(); timeoutTask = nil
        let verdict = currentRound.judge(mine: mine, partner: theirs)
        if verdict == .inSync {
            misses = 0
            backstopAvailable = false
            phase = .result(.inSync)
            scheduleSuccessDrain()
            Task { [weak self] in
                guard let self else { return }
                // Consent write failure keeps the existing un-latch semantics:
                // the round resets and the couple can go again.
                if await !self.requestConsent() {
                    logger.warning("sync passed but consent write failed — resetting the round")
                    self.resetRound()
                }
            }
        } else {
            recordMiss(showing: verdict)
        }
    }

    private func recordMiss(showing verdict: SyncVerdict) {
        misses += 1
        backstopAvailable = misses >= config.backstopAfterMisses
        phase = .result(verdict)
        scheduleResultDrain()
    }

    /// A miss verdict shows briefly, then the ring drains back to idle — the
    /// gentle infinite retry (never a lockout, never "failed" language).
    private func scheduleResultDrain() {
        resultResetTask?.cancel()
        resultResetTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: .seconds(self.config.resultHoldSeconds))
            guard !Task.isCancelled else { return }
            self.resetRound()
        }
    }

    /// Half-consented deadlock guard: per-device miss counters can drift on
    /// one-way broadcast loss, so the SAME two angles can judge .inSync here
    /// and a miss on the partner's phone. If the flip has not landed by
    /// resultHoldSeconds, drain the success latch back to idle so both phones
    /// can re-arm together. Our consent is already written and stays written;
    /// a later passing round calling consent() again is an idempotent no-op.
    private func scheduleSuccessDrain() {
        resultResetTask?.cancel()
        resultResetTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: .seconds(self.config.resultHoldSeconds))
            guard !Task.isCancelled, !self.isSessionActive() else { return }
            if case .result(.inSync) = self.phase {
                logger.info("sync passed but the flip never landed — draining to idle for another round")
                self.resetRound()
            }
        }
    }

    /// Back to idle. Misses / backstop persist across rounds (easing memory);
    /// only a success clears them.
    private func resetRound() {
        roundTask?.cancel(); roundTask = nil
        timeoutTask?.cancel(); timeoutTask = nil
        resultResetTask?.cancel(); resultResetTask = nil
        partnerArmed = false
        myRelease = nil
        partnerRelease = nil
        judged = false
        phase = .idle
    }

    // MARK: - Send helper

    private func broadcast(_ signal: SyncSignal) {
        let send = self.send
        Task {
            do { try await send(signal) } catch {
                logger.warning("sync broadcast failed: \(error.localizedDescription)")
            }
        }
    }
}
