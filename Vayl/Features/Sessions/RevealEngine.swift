//
//  RevealEngine.swift
//  Vayl
//
//  ONE state machine for all five reveal mechanics (whisper, whatIf, unspoken,
//  mirror, snapshot). Owned by CoupleSessionStore; the reveal views are thin
//  skins over its phase.
//
//  Authority split (spec §4.3 / D6):
//  - Seal/reveal FLAGS live in curated_sessions.reveal_state (row = durable,
//    reconnect-safe). The engine never trusts a broadcast for "partner sealed".
//  - Answer PAYLOADS (RevealEnvelope) cross ONLY via broadcast, are buffered in
//    memory here, and are NEVER persisted. Not to SwiftData, not to the row,
//    not to enqueueSync. Privacy invariant, not a nicety.
//
//  bothSealed requires BOTH the partner's row flag AND their buffered payload.
//  Payload may arrive before or after the flag. Flag without payload for
//  `resendGraceSeconds` → send a resend request; the partner device answers by
//  re-sending its envelope. Once both gates open, EACH device runs its own
//  local 3-2-1 (no countdown broadcast; small skew is a shared breath).
//
//  All wire access goes through RevealTransporting so unit tests inject a mock.
//

import Foundation
import Observation

// MARK: - Transport seam

/// Everything the engine needs from the wire. CoupleSessionStore adapts the
/// real service + coordinator (Sections 1-2) behind this; tests inject a mock.
@MainActor
protocol RevealTransporting: AnyObject {
    /// Merge-write my seal flag into reveal_state (Section 1 RPC).
    func setSealed(cardId: String) async throws
    /// Merge-write the revealed flag (idempotent; both devices may write it).
    func setRevealed(cardId: String) async throws
    /// Whole-card reset after a reconnect lost my local payload — both flags
    /// clear and the card re-prompts on both devices (spec §5, seam ruling 2).
    func clearRevealCard(cardId: String) async throws
    /// Broadcast my answer envelope (ephemeral).
    func sendEnvelope(_ envelope: RevealEnvelope)
    /// Ask the partner device to re-send its envelope for this card.
    func requestResend(cardId: String)
}

// MARK: - RevealEngine

@Observable
@MainActor
final class RevealEngine {

    enum Phase: Equatable {
        case composing
        case sealedMine
        case bothSealed
        case countdown(Int)     // 3, 2, 1
        case revealed
    }

    // MARK: State (views read these)

    private(set) var phase: Phase = .composing
    private(set) var cardId: String?
    /// My sealed answer — kept locally so the reveal renders without a round trip.
    private(set) var myEnvelope: RevealEnvelope?
    /// The partner's answer — arrives ONLY via broadcast. In-memory only.
    private(set) var partnerEnvelope: RevealEnvelope?
    /// Partner's seal flag as last seen on the ROW (never from broadcast).
    private(set) var partnerSealed = false

    /// True once the row says revealed (reconnect into an already-revealed card
    /// skips the countdown ceremony — no double 3-2-1).
    private var revealedOnRow = false
    /// The row has confirmed MY seal flag at least once. A later true→false
    /// transition means the whole card was cleared (partner's reconnect lost
    /// their payload) — the card re-prompts on BOTH devices (spec §5).
    private var mySealedSeenOnRow = false

    // MARK: Dependencies

    private let role: SessionRole
    private var partnerRole: SessionRole { role == .a ? .b : .a }
    private weak var transport: RevealTransporting?
    /// Injected so tests run without real waits (matches CoupleSessionStore's
    /// presenceSeconds/transitionSeconds pattern).
    private let countdownStepSeconds: Double
    private let resendGraceSeconds: Double

    private var countdownTask: Task<Void, Never>?
    private var resendTask: Task<Void, Never>?
    private var sealFlagTask: Task<Void, Never>?

    init(
        role: SessionRole,
        transport: RevealTransporting?,
        countdownStepSeconds: Double = 1.0,
        resendGraceSeconds: Double = 5.0
    ) {
        self.role = role
        self.transport = transport
        self.countdownStepSeconds = countdownStepSeconds
        self.resendGraceSeconds = resendGraceSeconds
    }

    /// The wire arrives after init (startRemoteSync builds the adapter once
    /// the coordinator exists). The engine holds it weak; the store retains it.
    func attachTransport(_ transport: RevealTransporting) {
        self.transport = transport
    }

    // MARK: - Lifecycle

    /// Arm the engine for a reveal card. Cancels any prior card's tasks.
    func beginCard(_ id: String) {
        cancelTasks()
        cardId = id
        phase = .composing
        myEnvelope = nil
        partnerEnvelope = nil
        partnerSealed = false
        revealedOnRow = false
        mySealedSeenOnRow = false
    }

    /// Leaving the card (advance / session end). Payloads die here — by design.
    func teardown() {
        cancelTasks()
        cardId = nil
        myEnvelope = nil
        partnerEnvelope = nil
        partnerSealed = false
    }

    /// Section-2 seam entry point: the store leaves a card. Kept as the
    /// stub's shape; a mismatched id is a no-op.
    func reset(forCardId id: String) {
        guard cardId == id else { return }
        teardown()
    }

    // MARK: - My side

    /// Seal my answer: freeze input, flag the row, broadcast the payload, keep
    /// it locally. Idempotent — a second call is a no-op. The row write retries
    /// each grace window until it lands or the card changes: a dropped flag
    /// would otherwise deadlock BOTH devices at "waiting on them" forever.
    func seal(_ body: RevealEnvelope.Body) {
        guard let cardId, phase == .composing else { return }
        let envelope = RevealEnvelope(cardId: cardId, role: role, body: body)
        myEnvelope = envelope
        phase = .sealedMine
        transport?.sendEnvelope(envelope)
        sealFlagTask?.cancel()
        sealFlagTask = Task { @MainActor [weak self] in
            guard let self else { return }
            while !Task.isCancelled, self.cardId == cardId {
                do {
                    try await self.transport?.setSealed(cardId: cardId)
                    return
                } catch {
                    try? await Task.sleep(for: .seconds(self.resendGraceSeconds))
                }
            }
        }
        evaluateGate()
    }

    // MARK: - Wire inputs (the store pumps these)

    /// Row update: this card's flags from reveal_state. The row is the only
    /// seal authority; absent card object = all flags false.
    func applyRow(_ revealState: [String: RevealCardState]) {
        guard let cardId else { return }
        let flags = revealState[cardId] ?? RevealCardState()
        applyRowFlags(
            mySealed: flags.sealed(for: role),
            partnerSealed: flags.sealed(for: partnerRole),
            revealed: flags.revealed
        )
    }

    /// Role-mapped flag application (also the unit-test seam).
    func applyRowFlags(mySealed: Bool, partnerSealed: Bool, revealed: Bool) {
        guard cardId != nil, phase != .revealed else { return }
        if revealed { revealedOnRow = true }
        if case .countdown = phase { return }   // ceremony launched; let it land

        self.partnerSealed = partnerSealed

        if mySealed {
            mySealedSeenOnRow = true
        } else if mySealedSeenOnRow, phase == .sealedMine {
            // The row confirmed my seal and then lost it: the whole card was
            // cleared (partner's reconnect lost their payload, spec §5). The
            // card re-prompts on BOTH devices — back to composing. The view's
            // draft @State survives, so nothing typed is lost.
            mySealedSeenOnRow = false
            myEnvelope = nil
            partnerEnvelope = nil
            resendTask?.cancel()
            resendTask = nil
            phase = .composing
            return
        }
        evaluateGate()
    }

    /// Section-2 seam entry point: a broadcast envelope arrived (may precede
    /// the row flag — buffer it). Own echoes and stale cards are ignored.
    func applyBroadcast(_ envelope: RevealEnvelope) {
        receive(envelope)
    }

    /// A broadcast envelope arrived (may precede the row flag — buffer it).
    func receive(_ envelope: RevealEnvelope) {
        guard envelope.cardId == cardId, envelope.role != role else { return }
        partnerEnvelope = envelope
        evaluateGate()
    }

    /// The partner asked us to re-send (their buffer lost our payload).
    func receiveResendRequest(cardId requested: String) {
        guard requested == cardId, let myEnvelope else { return }
        transport?.sendEnvelope(myEnvelope)
    }

    // MARK: - Reconnect restore

    enum RestoreOutcome: Equatable {
        /// Phase rebuilt from the flags; missing payloads are being re-requested.
        case resumed
        /// The row says I sealed but my payload died with the process — the
        /// engine clears the card (transport.clearRevealCard) and it re-prompts.
        case recompose
    }

    /// Rebuild phase from the row after an app kill / channel drop (spec §4.3:
    /// "flags from the row restore the phase; missing payload → resend path").
    @discardableResult
    func restore(cardId id: String, mySealed: Bool, partnerSealed: Bool, revealed: Bool) -> RestoreOutcome {
        beginCard(id)
        if mySealed && myEnvelope == nil {
            // My in-flight answer is gone. Whole-card reset (both flags clear,
            // spec §5) and re-prompt compose. Copy in the views acknowledges
            // it plainly: "that one got lost in the air, type it again".
            Task { @MainActor in
                try? await self.transport?.clearRevealCard(cardId: id)
            }
            return .recompose
        }
        revealedOnRow = revealed
        self.partnerSealed = partnerSealed
        if partnerSealed { evaluateGate() }
        return .resumed
    }

    // MARK: - The gate

    /// bothSealed requires: I sealed (have my envelope) AND the partner's row
    /// flag AND the partner's buffered payload. Flag-without-payload arms the
    /// resend loop instead.
    private func evaluateGate() {
        if phase == .revealed { return }
        if case .countdown = phase { return }
        guard myEnvelope != nil else { return }   // I haven't sealed yet
        guard partnerSealed else { return }       // row hasn't flagged them

        if partnerEnvelope != nil {
            resendTask?.cancel()
            resendTask = nil
            if phase == .sealedMine {
                phase = .bothSealed
                startCountdown()
            }
        } else {
            armResendLoop()
        }
    }

    /// Flag set but payload missing: after the grace window, request a re-send;
    /// keep requesting each window until the payload lands or the card changes.
    private func armResendLoop() {
        guard resendTask == nil, let cardId else { return }
        resendTask = Task { @MainActor [weak self] in
            guard let self else { return }
            while !Task.isCancelled, self.partnerEnvelope == nil {
                try? await Task.sleep(for: .seconds(self.resendGraceSeconds))
                guard !Task.isCancelled, self.partnerEnvelope == nil else { break }
                self.transport?.requestResend(cardId: cardId)
            }
        }
    }

    /// Both gates open → 3-2-1 → revealed. Reconnecting into an
    /// already-revealed card skips the ceremony (no double countdown).
    private func startCountdown() {
        countdownTask?.cancel()
        if revealedOnRow {
            phase = .revealed
            return
        }
        countdownTask = Task { @MainActor [weak self] in
            guard let self else { return }
            for n in [3, 2, 1] {
                guard !Task.isCancelled else { return }
                self.phase = .countdown(n)
                try? await Task.sleep(for: .seconds(self.countdownStepSeconds))
            }
            guard !Task.isCancelled else { return }
            self.phase = .revealed
            if let cardId = self.cardId {
                // Idempotent merge-write; both devices writing it is harmless.
                try? await self.transport?.setRevealed(cardId: cardId)
            }
        }
    }

    private func cancelTasks() {
        countdownTask?.cancel()
        countdownTask = nil
        resendTask?.cancel()
        resendTask = nil
        sealFlagTask?.cancel()
        sealFlagTask = nil
    }
}
