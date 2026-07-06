//
//  RevealEngineTests.swift
//  VaylTests
//
//  RevealEngine state machine against a mock transport: seal orders,
//  payload-before-flag, flag-before-payload, the resend path, and reconnect
//  restore. Timings injected tiny so nothing waits in real time (matches
//  CoupleSessionPlaythroughTests' presenceSeconds pattern).
//

import XCTest
@testable import Vayl

@MainActor
final class RevealEngineTests: XCTestCase {

    // Isolated-deinit crash workaround (the DM-suite gotcha): app-hosted tests
    // abort when an @Observable @MainActor object deallocates mid-suite.
    // Retain every engine (and its @MainActor mock) for the test process.
    private static var retained: [AnyObject] = []
    private static func retain(_ objects: AnyObject...) { retained.append(contentsOf: objects) }

    // MARK: - Mock transport

    @MainActor
    final class MockRevealTransport: RevealTransporting {
        var sealedCardIds: [String] = []
        var revealedCardIds: [String] = []
        var clearedCardIds: [String] = []
        var sentEnvelopes: [RevealEnvelope] = []
        var resendRequests: [String] = []

        func setSealed(cardId: String) async throws { sealedCardIds.append(cardId) }
        func setRevealed(cardId: String) async throws { revealedCardIds.append(cardId) }
        func clearRevealCard(cardId: String) async throws { clearedCardIds.append(cardId) }
        func sendEnvelope(_ envelope: RevealEnvelope) { sentEnvelopes.append(envelope) }
        func requestResend(cardId: String) { resendRequests.append(cardId) }
    }

    private var transport: MockRevealTransport!

    private func makeEngine(
        role: SessionRole = .a,
        countdownStep: Double = 0.01,
        resendGrace: Double = 0.05
    ) -> RevealEngine {
        let transport = MockRevealTransport()
        self.transport = transport
        let engine = RevealEngine(
            role: role,
            transport: transport,
            countdownStepSeconds: countdownStep,
            resendGraceSeconds: resendGrace
        )
        engine.beginCard("card-07")
        Self.retain(engine, transport)
        return engine
    }

    private func partnerEnvelope(_ text: String = "their answer") -> RevealEnvelope {
        RevealEnvelope(cardId: "card-07", role: .b, body: .text(text))
    }

    private func waitUntil(_ message: String,
                           timeout: TimeInterval = 3,
                           _ condition: () -> Bool) async {
        let start = Date()
        while !condition() {
            if Date().timeIntervalSince(start) > timeout {
                XCTFail("Timed out waiting: \(message)")
                return
            }
            try? await Task.sleep(for: .milliseconds(10))
        }
    }

    // MARK: - Seal orders

    func testMySealFreezesAndFlagsAndBroadcasts() async {
        let engine = makeEngine()
        engine.seal(.text("mine"))

        XCTAssertEqual(engine.phase, .sealedMine)
        XCTAssertEqual(transport.sentEnvelopes.count, 1)
        XCTAssertEqual(transport.sentEnvelopes.first?.cardId, "card-07")
        await waitUntil("row seal flag written") { self.transport.sealedCardIds == ["card-07"] }
        // Sealing twice is a no-op.
        engine.seal(.text("again"))
        XCTAssertEqual(transport.sentEnvelopes.count, 1)
    }

    func testPartnerFirstThenMeReachesRevealed() async {
        let engine = makeEngine()
        // Partner's payload and flag both land before I even seal.
        engine.receive(partnerEnvelope())
        engine.applyRowFlags(mySealed: false, partnerSealed: true, revealed: false)
        XCTAssertEqual(engine.phase, .composing)   // nothing moves until I seal

        engine.seal(.text("mine"))
        await waitUntil("revealed after both gates") { engine.phase == .revealed }
        XCTAssertEqual(transport.revealedCardIds, ["card-07"])
        XCTAssertNil(transport.resendRequests.first)
    }

    // MARK: - Payload before flag

    func testPayloadBeforeFlag() async {
        let engine = makeEngine()
        engine.seal(.text("mine"))
        engine.receive(partnerEnvelope())          // payload arrives first
        XCTAssertEqual(engine.phase, .sealedMine)  // flag not seen yet → hold

        engine.applyRowFlags(mySealed: true, partnerSealed: true, revealed: false)
        await waitUntil("countdown ran to revealed") { engine.phase == .revealed }
        XCTAssertTrue(transport.resendRequests.isEmpty)
    }

    // MARK: - Flag before payload (+ resend path)

    func testFlagBeforePayloadArmsResendThenCompletes() async {
        let engine = makeEngine()
        engine.seal(.text("mine"))
        engine.applyRowFlags(mySealed: true, partnerSealed: true, revealed: false)
        XCTAssertEqual(engine.phase, .sealedMine)  // payload missing → no reveal

        await waitUntil("resend requested after grace") {
            self.transport.resendRequests.contains("card-07")
        }
        engine.receive(partnerEnvelope())          // the re-sent envelope lands
        await waitUntil("revealed after resend") { engine.phase == .revealed }
    }

    func testResendRequestAnsweredByReSendingMyEnvelope() {
        let engine = makeEngine()
        engine.seal(.text("mine"))
        XCTAssertEqual(transport.sentEnvelopes.count, 1)

        engine.receiveResendRequest(cardId: "card-07")
        XCTAssertEqual(transport.sentEnvelopes.count, 2)   // re-sent
        // A request for some other card is ignored.
        engine.receiveResendRequest(cardId: "card-99")
        XCTAssertEqual(transport.sentEnvelopes.count, 2)
    }

    // MARK: - Own-echo and stale-card hygiene

    func testOwnEchoAndOtherCardEnvelopesIgnored() {
        let engine = makeEngine()
        engine.seal(.text("mine"))
        engine.receive(RevealEnvelope(cardId: "card-07", role: .a, body: .text("echo")))
        engine.receive(RevealEnvelope(cardId: "card-99", role: .b, body: .text("stale")))
        XCTAssertNil(engine.partnerEnvelope)
    }

    // MARK: - Whole-card clear (partner's recompose)

    func testWholeCardClearRepromptsCompose() async {
        let engine = makeEngine()
        engine.seal(.text("mine"))
        // The row confirms my seal…
        engine.applyRowFlags(mySealed: true, partnerSealed: false, revealed: false)
        XCTAssertEqual(engine.phase, .sealedMine)
        // …then the whole card is cleared (partner reconnected without their
        // payload): the card re-prompts here too (spec §5).
        engine.applyRowFlags(mySealed: false, partnerSealed: false, revealed: false)
        XCTAssertEqual(engine.phase, .composing)
        XCTAssertNil(engine.myEnvelope)
        // Sealing again works from the top.
        engine.seal(.text("mine again"))
        XCTAssertEqual(engine.phase, .sealedMine)
    }

    // MARK: - Reconnect restore

    func testRestoreWithLostMyPayloadRecomposes() async {
        let engine = makeEngine()
        let outcome = engine.restore(
            cardId: "card-07", mySealed: true, partnerSealed: false, revealed: false
        )
        XCTAssertEqual(outcome, .recompose)
        XCTAssertEqual(engine.phase, .composing)
        await waitUntil("whole card cleared for re-compose") {
            self.transport.clearedCardIds == ["card-07"]
        }
    }

    func testRestoreWithPartnerSealedRequestsResend() async {
        let engine = makeEngine()
        let outcome = engine.restore(
            cardId: "card-07", mySealed: false, partnerSealed: true, revealed: false
        )
        XCTAssertEqual(outcome, .resumed)
        XCTAssertEqual(engine.phase, .composing)   // I still have to compose
        engine.seal(.text("mine"))
        await waitUntil("resend requested for missing payload") {
            self.transport.resendRequests.contains("card-07")
        }
        engine.receive(partnerEnvelope())
        await waitUntil("revealed") { engine.phase == .revealed }
    }

    func testRestoreIntoRevealedCardSkipsCountdownCeremony() async {
        let engine = makeEngine()
        _ = engine.restore(
            cardId: "card-07", mySealed: false, partnerSealed: true, revealed: true
        )
        engine.seal(.text("mine"))
        engine.receive(partnerEnvelope())
        // revealedOnRow short-circuits the 3-2-1: straight to revealed.
        await waitUntil("revealed without ceremony") { engine.phase == .revealed }
    }
}
