//
//  DemoSequencer.swift
//  Vayl
//
//  Extracted from DemoPhase (OB decomposition — phase split pass, mirrors NameSequencer).
//

// Features/Onboarding/Canvas/Sequencers/DemoSequencer.swift

import SwiftUI

/// Demo scene stages. `.intro → .dealing → .flipping → .awaitingLift → .composing →
/// .sealing → .done`.
enum DemoStage: Equatable {
    case intro, dealing, flipping, awaitingLift, composing, sealing, done
}

/// One spectrum mote shed from the sentence band at seal. Internal so DemoPhase's
/// effects Canvas can render `director.demo.dissolveSeeds`.
struct DemoDissolveSeed {
    let ox, oy: Double    // spawn offset from card center — across the sentence band
    let vx, vy: Double    // drift (rightward + upward bias, toward the corner deck)
    let size: Double
    let opacity: Double
    let color: Color
    let tw: Double    // twinkle phase
}

/// Owns the entire Demo phase orchestration: the two intro lines, deal → flip, the
/// "I [verb] [noun]." compose mechanic (verb drum + noun field + tone wash), and the
/// seal → dissolve → pocket → commit beats that write the EmotionalRegister.
///
/// Held by VaylDirector as `@ObservationIgnored lazy var demo = DemoSequencer(director: self)`,
/// the same pattern as `name` / `gender`. DemoPhase reads `director.demo.*` and forwards
/// taps/gestures to it.
///
/// Two things stay in the View because they cannot live on an `@Observable`:
///   • `@FocusState` (the noun field) — requested via `nounShouldFocus`, relayed by DemoPhase.
///   • the `tableRimBurst` `@Binding` — pulsed via `rimBurstTrigger`, relayed by DemoPhase.
/// The `@Environment` values (reduceMotion / displayScale) are passed in at `start`.
@Observable
@MainActor
final class DemoSequencer {

    @ObservationIgnored unowned let director: VaylDirector

    init(director: VaylDirector) {
        self.director = director
    }

    // MARK: — Bridges to View-only state (set at start; relayed back by DemoPhase)

    @ObservationIgnored private var screenSize: CGSize  = .zero
    @ObservationIgnored private var reduceMotion: Bool    = false
    @ObservationIgnored private var displayScale: CGFloat = 2.0

    /// The View relays this onto its `@FocusState` noun field.
    var nounShouldFocus: Bool = false
    /// Bumped to ask the View to fire the table rim-burst (it owns the `tableRimBurst` binding).
    var rimBurstTrigger: Int = 0

    @ObservationIgnored private let maxNounLength = 18   // a phrase, not a poem

    // MARK: — Tasks
    @ObservationIgnored var sceneTask: Task<Void, Never>?

    // MARK: — Card animation (mirrors NameSequencer)
    var stage: DemoStage = .intro
    var cardOffset: CGSize    = .zero
    var cardAngle: Double    = 0
    var cardAlpha: Double    = 0
    var flipScaleX: Double    = 1.0
    var showFace: Bool      = false
    var cardScale: Double    = 1.0
    var cardBlur: Double    = 0

    // MARK: — Lift / compose
    var cardLifted: Bool      = false
    var waitingForLift: Bool      = false
    var verb: DemoVerb  = .want
    var noun: String    = ""
    var nounPulse: CGFloat   = 0
    var borderPulse: Bool      = false
    var sentenceMelt: Double    = 0   // 0 hidden → 1 "I want" settled onto the card

    // MARK: — Seal
    var waitingForSeal: Bool   = false
    var hasEngaged: Bool   = false   // sticky: true once they've typed anything
    var sealProgress: Double = 0       // 0 composing → 1 fused
    var dissolveProgress: Double = 0       // 0 → 1 particle burst
    var dissolveSeeds: [DemoDissolveSeed] = []
    var sealBloom: Double = 0       // 0 → 1 spectrum bloom flash at seal

    // MARK: — Effects
    var impactRingProgress: Double = 0
    var flipBurstProgress: Double = 0

    @ObservationIgnored private var impactSoft   = UIImpactFeedbackGenerator(style: .soft)
    @ObservationIgnored private var impactHeavy  = UIImpactFeedbackGenerator(style: .heavy)
    @ObservationIgnored private var selectionGen = UISelectionFeedbackGenerator()

    // MARK: — Geometry

    private var cardWidth: CGFloat {
        AppLayout.obTableCardWidth(in: screenSize.width) * AppLayout.obTableCardCinematicScale
    }
    private var cardHeight: CGFloat {
        AppLayout.obTableCardHeight(in: screenSize.width) * AppLayout.obTableCardCinematicScale
    }

    // MARK: — Lifecycle (called from DemoPhase.onAppear / onDisappear)

    func start(screenSize: CGSize, reduceMotion: Bool, displayScale: CGFloat) {
        self.screenSize   = screenSize
        self.reduceMotion = reduceMotion
        self.displayScale = displayScale
        resetState()
        sceneTask = Task { await runScene() }
    }

    func stop() {
        sceneTask?.cancel(); sceneTask = nil
        waitingForLift = false; waitingForSeal = false; hasEngaged = false
        director.projector.hideDealerLine()
    }

    private func resetState() {
        nounShouldFocus = false
        stage = .intro
        cardOffset = .zero; cardAngle = 0; cardAlpha = 0; flipScaleX = 1.0
        showFace = false; cardScale = 1.0; cardBlur = 0
        cardLifted = false; waitingForLift = false
        verb = .want; noun = ""; nounPulse = 0; borderPulse = false; sentenceMelt = 0
        waitingForSeal = false; hasEngaged = false
        sealProgress = 0; dissolveProgress = 0; dissolveSeeds = []; sealBloom = 0
        impactRingProgress = 0; flipBurstProgress = 0
    }

    // MARK: — Scene

    private func runScene() async {
        // Felt fades in via director.runDemoEntry (≈1.4s). Hold for it.
        try? await Task.sleep(for: .milliseconds(800))
        guard !Task.isCancelled else { return }

        // Rasterize the deal's card-back snapshot on this idle beat (the phase
        // cross-fade has settled; the first dealer line hasn't started). The deal
        // itself fires mid-choreography, where a synchronous ImageRenderer pass
        // would eat the launch frame.
        if !reduceMotion {
            CardBackRaster.prewarm(width: cardWidth, height: cardHeight, scale: displayScale)
        }

        // ── Two intro lines ───────────────────────────────────────
        let line1 = "The things worth learning about yourself rarely surface on their own."
        director.projector.showDealerLineManual(line1, anchorYFrac: 0.29)   // FEEL-GATE: lifted off the table horizon
        try? await Task.sleep(for: .milliseconds(AppDealerTyping.typeDuration(line1) + AppDealerTyping.hangLong))
        guard !Task.isCancelled else { return }
        director.projector.hideDealerLine()
        try? await Task.sleep(for: .milliseconds(200))
        guard !Task.isCancelled else { return }

        // ── Deal — the card arrives BETWEEN the two lines ─────────
        stage = .dealing
        await dealCard()
        guard !Task.isCancelled else { return }

        // Slight rest — the dealt card sits a beat before the dealer names it. FEEL-GATE.
        try? await Task.sleep(for: .milliseconds(450))
        guard !Task.isCancelled else { return }

        // ── Copy 2 — types, then HANGS over the move + reveal ─────
        let line2 = "So let's bring one up."
        director.projector.showDealerLineManual(line2, anchorYFrac: 0.29)   // FEEL-GATE: match copy 1
        // Finish typing + a short beat, then the card moves WHILE the line hangs. FEEL-GATE.
        try? await Task.sleep(for: .milliseconds(AppDealerTyping.typeDuration(line2) + 300))
        guard !Task.isCancelled else { return }

        // ── Center → flip, the line hanging the whole way ─────────
        await centerCard()
        try? await Task.sleep(for: .milliseconds(200))   // FEEL-GATE: square-up before the flip
        guard !Task.isCancelled else { return }
        await performFlipWithBurst()
        // The line bows out as the face lands.
        director.projector.hideDealerLine()
        guard !Task.isCancelled else { return }
        try? await Task.sleep(for: .milliseconds(220))

        // ── "I want" melts onto the card ──────────────────────────
        stage = .awaitingLift
        withAnimation(reduceMotion ? AppAnimation.fast : AppAnimation.demoSentenceMelt) {
            sentenceMelt = 1.0
        }
        try? await Task.sleep(for: .milliseconds(400))
        guard !Task.isCancelled else { return }

        // ── Tease the verb cycling so the user knows the word changes ──
        await runVerbIntroCycle()
        guard !Task.isCancelled else { return }

        // ── Auto-lift into composing state ────────────────────────
        withAnimation(AppAnimation.cardLift.reduceMotionSafe) {
            cardLifted = true
            cardOffset = CGSize(width: 0, height: screenSize.height * 0.42 - screenSize.height / 2)
            cardScale  = 1.12
        }
        borderPulse = true   // alive pulse begins

        try? await Task.sleep(for: .milliseconds(360))
        guard !Task.isCancelled else { return }

        stage = .composing
        let composeLine = "Finish the sentence."
        director.projector.showDealerLineManual(composeLine, anchorYFrac: 0.15)

        // Focus the field only AFTER the dealer finishes asking — the instruction must
        // lead the action, not race it.
        try? await Task.sleep(for: .milliseconds(AppDealerTyping.typeDuration(composeLine) + AppDealerTyping.hangShort))
        guard !Task.isCancelled else { return }
        nounShouldFocus = true
    }

    /// One slot-machine pass through the verbs, landing back on `want`, so the user
    /// sees the word is changeable before they're asked to pick.
    private func runVerbIntroCycle() async {
        guard !reduceMotion else { return }
        // want (current) → need → desire → want.
        for v in [DemoVerb.need, .desire, .want] {
            withAnimation(AppAnimation.demoVerbCrossfade) { verb = v }
            selectionGen.selectionChanged()
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
        }
        try? await Task.sleep(for: .milliseconds(160))
    }

    // MARK: — Deal / center / flip (shared mechanics with NameSequencer)

    private func dealCard() async {
        if reduceMotion {
            cardAlpha = 1
            return
        }
        cardAlpha = 0
        guard let deal = await director.dealSingleCard(screenSize: screenSize, scale: displayScale) else {
            cardAlpha = 1; return
        }
        guard !Task.isCancelled else { return }
        cardOffset = deal.offset
        cardAngle  = deal.angle
        cardAlpha  = 1
        try? await Task.sleep(for: .milliseconds(32))
        director.cardFlightScene.clearCard(id: deal.flightID)
    }

    private func centerCard() async {
        // FEEL-GATE: Demo wants a slower, more deliberate glide than the shared cardCenter token.
        withAnimation(AppAnimation.demoCenterDeliberate) {
            cardOffset = CGSize(width: screenSize.width  * 0.50 - screenSize.width  / 2,
                                height: screenSize.height * 0.55 - screenSize.height / 2)
            cardAngle = 0
        }
        try? await Task.sleep(for: .milliseconds(720))
    }

    private func performFlipWithBurst() async {
        stage = .flipping
        impactRingProgress = 0
        withAnimation(AppAnimation.impactRingDecay) { impactRingProgress = 1.0 }
        flipBurstProgress = 0
        withAnimation(AppAnimation.flipBurstDecay) { flipBurstProgress = 1.0 }
        rimBurstTrigger += 1   // View owns tableRimBurst — relay the pulse

        if reduceMotion { showFace = true; flipScaleX = -1.0; return }
        // FEEL-GATE: a slower, more dramatic flip than cardFlipHalf — the user's first flip.
        let half = AppAnimation.demoFlipHalf
        withAnimation(half) { flipScaleX = 0.0 }
        try? await Task.sleep(for: .milliseconds(420))
        showFace = true
        withAnimation(half) { flipScaleX = -1.0 }
        try? await Task.sleep(for: .milliseconds(420))
    }

    // MARK: — Compose helpers

    /// Tap cycles need → want → desire → need. Called from DemoPhase's verb pill.
    func cycleVerb() {
        guard stage == .composing else { return }
        let all = DemoVerb.allCases
        guard let i = all.firstIndex(of: verb) else { return }
        withAnimation(AppAnimation.fast) { verb = all[(i + 1) % all.count] }
        selectionGen.selectionChanged()
    }

    private func pulseNoun() {
        impactSoft.impactOccurred()
        nounPulse = -6
        withAnimation(AppAnimation.demoFieldPulse) { nounPulse = 0 }
    }

    /// The `.onChange(of: noun)` body — clean the input, cap length, arm the seal.
    func onNounChanged(_ new: String) {
        // Allow short phrases — strip a leading space, collapse double spaces, cap length.
        var cleaned = new
        while cleaned.hasPrefix(" ") { cleaned.removeFirst() }
        while cleaned.contains("  ") { cleaned = cleaned.replacingOccurrences(of: "  ", with: " ") }
        cleaned = String(cleaned.prefix(maxNounLength))
        if cleaned != new {
            noun = cleaned
            pulseNoun()
        }
        updateSealArming()
    }

    private func updateSealArming() {
        let armed = !noun.trimmingCharacters(in: .whitespaces).isEmpty
        guard armed != waitingForSeal else { return }
        waitingForSeal = armed
        // Once they've typed at all, erasing does NOT bring the prompt back; it only shows
        // on the very first, untouched entry.
        if armed {
            hasEngaged = true
            director.projector.hideDealerLine()
        } else if !hasEngaged {
            director.projector.showDealerLineManual("Finish the sentence.", anchorYFrac: 0.15)
        }
    }

    /// Done key seals too (parity with swipe) once a word exists. Called from DemoPhase.
    func attemptSealFromKeyboard() {
        guard waitingForSeal else { return }
        nounShouldFocus = false
        Task { @MainActor in await performSeal() }
    }

    // MARK: — Swipe (teaches SWIPE / seals)

    func handleSwipe(_ translation: CGSize) {
        guard translation.height < -AppLayout.swipeSubmitThreshold else { return }
        guard stage == .composing, waitingForSeal else { return }
        nounShouldFocus = false
        Task { @MainActor in await performSeal() }
    }

    // MARK: — Seal → dissolve → pocket → commit

    private func performSeal() async {
        guard stage == .composing else { return }
        stage = .sealing
        waitingForSeal = false
        borderPulse = false
        impactHeavy.impactOccurred()
        director.projector.hideDealerLine()

        // 1 — fuse the sentence (chevron + prompt resolve into a clean line).
        withAnimation(AppAnimation.sealTrace) { sealProgress = 1.0 }
        try? await Task.sleep(for: .milliseconds(420))
        guard !Task.isCancelled else { return }

        // 2 — break the sentence into spectrum motes + a bloom flash while the card pockets.
        if !reduceMotion {
            dissolveSeeds = Self.makeSeeds(cardW: cardWidth, cardH: cardHeight)
            withAnimation(AppAnimation.slow) { sealBloom = 1.0 }
            withAnimation(AppAnimation.sealDissolve) { dissolveProgress = 1.0 }
            try? await Task.sleep(for: .milliseconds(120))   // let the motes lift off before the card flies
        }
        await pocketCard()

        // 3 — write data + credit the deck (director owns the data/routing).
        director.commitDemoSnapshot(verb: verb, noun: noun)

        // 4 — a breath on the cleared felt, then hand to name.
        stage = .done
        try? await Task.sleep(for: .milliseconds(reduceMotion ? 120 : 360))
        guard !Task.isCancelled else { return }
        director.advance(to: .name)
    }

    private func pocketCard() async {
        let cornerX = screenSize.width  - AppLayout.cornerDeckRight - AppLayout.cornerDeckWidth  / 2
        let cornerY = AppLayout.cornerDeckTop + AppLayout.cornerDeckHeight / 2
        withAnimation(AppAnimation.cardPocket.reduceMotionSafe) {
            cardLifted = false
            cardOffset = CGSize(width: cornerX - screenSize.width  / 2,
                                height: cornerY - screenSize.height / 2)
            cardScale  = AppLayout.cornerDeckWidth / cardWidth
        }
        withAnimation(AppAnimation.pocketAlphaFade) { cardAlpha = 0 }
        try? await Task.sleep(for: .milliseconds(reduceMotion ? 80 : 480))
    }

    // MARK: — Dissolve seeds

    private static func makeSeeds(cardW: CGFloat, cardH: CGFloat) -> [DemoDissolveSeed] {
        let palette = [AppColors.spectrumCyan, AppColors.spectrumPurple, AppColors.spectrumMagenta]
        let w = Double(cardW), h = Double(cardH)
        return (0..<48).map { _ in
            DemoDissolveSeed(
                ox: Double.random(in: -w * 0.36 ... w * 0.36),    // across the words
                oy: Double.random(in: -h * 0.12 ... h * 0.12),
                vx: Double.random(in: -w * 0.18 ... w * 0.55),    // rightward bias → corner deck
                vy: Double.random(in: -h * 0.6  ... -h * 0.1),    // upward
                size: Double.random(in: 1.2 ... 4.2),
                opacity: Double.random(in: 0.5 ... 0.95),
                color: palette[Int.random(in: 0..<palette.count)],
                tw: Double.random(in: 0 ..< (.pi * 2))
            )
        }
    }
}
