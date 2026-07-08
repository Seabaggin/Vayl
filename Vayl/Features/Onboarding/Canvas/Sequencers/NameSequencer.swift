//
//  NameSequencer.swift
//  Vayl
//
//  Extracted from NamePhase (OB decomposition — phase split pass).
//

// Features/Onboarding/Canvas/Sequencers/NameSequencer.swift

import SwiftUI

/// The card-deal beats of the Name phase. `.idle → .swiping → .resting → .flipping →
/// .pausing → .nameInput → .collecting`. Drives the dealer intro, set-down + flip,
/// inline name entry, greeting, and the one-time tap-to-lift → swipe-to-hand-back lesson.
enum CardDealPhase: Equatable {
    case idle
    case swiping
    case resting
    case flipping
    case pausing
    case nameInput
    case collecting
}

/// Owns the entire Name phase orchestration: the dealer-typing engine, the card
/// set-down / flip / collect sequence, inline name entry, the Beat-3 greeting, and
/// the guided tap-to-lift → swipe-up-to-hand-back lesson that teaches the whole flow.
///
/// Held by VaylDirector as `@ObservationIgnored lazy var name = NameSequencer(director: self)`
/// — the same pattern the director uses for `gender` / `curiosity`. NamePhase reads
/// `director.name.*` for render state and forwards taps/gestures to its methods.
///
/// Three things stay in the View because they cannot live on an `@Observable`:
///   • `@FocusState` (the name field) — the sequencer requests focus via the observable
///     `nameFieldShouldFocus` flag, which the View relays onto its `@FocusState`.
///   • the `tableRimBurst` `@Binding` — the sequencer pulses `rimBurstTrigger`; the View
///     relays it into the binding with the same decay animation.
///   • the `@Environment` values (reduceMotion / displayScale) — passed in at `start`.
@Observable
@MainActor
final class NameSequencer {

    /// Owning director. Card flight, credential receipt, dealer projection, and phase
    /// advancement all flow through it. Unowned — the director owns this sequencer.
    @ObservationIgnored unowned let director: VaylDirector

    init(director: VaylDirector) {
        self.director = director
    }

    // MARK: — Bridges to View-only state (set at start; relayed back by NamePhase)

    @ObservationIgnored private var screenSize: CGSize  = .zero
    @ObservationIgnored private var reduceMotion: Bool    = false
    @ObservationIgnored private var displayScale: CGFloat = 2.0

    /// The View relays this onto its `@FocusState` name field.
    var nameFieldShouldFocus: Bool = false
    /// Bumped to ask the View to fire the table rim-burst (it owns the `tableRimBurst` binding).
    var rimBurstTrigger: Int = 0

    // MARK: — Task handles

    @ObservationIgnored var dealTask: Task<Void, Never>?
    @ObservationIgnored var inputFocusTask: Task<Void, Never>?
    @ObservationIgnored var keyAnimationTask: Task<Void, Never>?
    @ObservationIgnored var dealerTypingTask: Task<Void, Never>?
    @ObservationIgnored var liftTeachTask: Task<Void, Never>?

    // MARK: — Dealer typing

    var dealerDisplayed: String  = ""
    var dealerAlpha: Double  = 0.0
    var dealerOffsetY: CGFloat = 0.0

    // MARK: — Card animation

    var dealPhase: CardDealPhase = .idle
    var cardOffset: CGSize        = .zero
    var cardAngle: Double        = 0
    var cardAlpha: Double        = 0
    var flipScaleX: Double        = 1.0
    var showFace: Bool          = false
    var cardScale: Double        = 1.0
    var cardScreenAlpha: Double        = 1.0

    // MARK: — Effects

    var impactRingProgress: Double = 0
    var flipBurstProgress: Double = 0

    // MARK: — Typewriter

    var activeKeyIndex: Int     = -1
    var carriageProgress: CGFloat = 0

    // MARK: — Name input

    var name: String = ""
    var uiAlpha: Double = 0

    var lineRevealProgress: CGFloat = 0
    var hasSweptLine: Bool    = false
    var lineBounce: CGFloat = 0

    // MARK: — Card return demo (post-name submission)

    var waitingForCardReturn: Bool    = false
    var cardReturnHintOffset: CGFloat = 0
    var handBackDrag: CGSize  = .zero
    var handBackArmed: Bool    = false
    var waitingForCardLift: Bool    = false
    var cardLifted: Bool    = false

    // MARK: — Beat 3 greeting

    var showGreeting: Bool   = false
    var greetingName: String = ""
    var greetingAlpha: Double = 0.0
    var nameVisible: Bool   = false

    @ObservationIgnored private var impactSoft   = UIImpactFeedbackGenerator(style: .soft)
    @ObservationIgnored private var impactMedium = UIImpactFeedbackGenerator(style: .medium)
    @ObservationIgnored private var impactHeavy  = UIImpactFeedbackGenerator(style: .heavy)
    @ObservationIgnored private var selectionGen = UISelectionFeedbackGenerator()

    // MARK: — Geometry

    private var cardWidth: CGFloat {
        AppLayout.obTableCardWidth(in: screenSize.width) * AppLayout.obTableCardCinematicScale
    }
    private var cardHeight: CGFloat {
        AppLayout.obTableCardHeight(in: screenSize.width) * AppLayout.obTableCardCinematicScale
    }

    /// Gentle tilt as the card is dragged sideways during the hand-back — a held card
    /// leaning as it moves. Read by NamePhase's card layer.
    var handBackTilt: Double {
        HandBackFollow.tilt(for: handBackDrag.width, screenWidth: screenSize.width)
    }

    // MARK: — Lifecycle (called from NamePhase.onAppear / onDisappear)

    /// Kicks the phase: stores the View's environment, resets to a clean slate (the
    /// director owns this sequencer for the whole OB, so a re-mount must start fresh —
    /// matching the old @State-per-mount behaviour), clears any carried-over dealer
    /// line, and starts the intro.
    func start(screenSize: CGSize, reduceMotion: Bool, displayScale: CGFloat) {
        self.screenSize   = screenSize
        self.reduceMotion = reduceMotion
        self.displayScale = displayScale
        resetState()
        director.projector.hideDealerLine()   // clear any canvas line carried over from Demo's exit
        dealTask = Task { await runDealerIntro() }
    }

    /// Mirrors NamePhase's old onDisappear teardown.
    func stop() {
        dealerTypingTask?.cancel()
        dealerTypingTask = nil
        dealTask?.cancel()
        liftTeachTask?.cancel()
        liftTeachTask = nil
        inputFocusTask?.cancel()
        inputFocusTask = nil
        keyAnimationTask?.cancel()
        keyAnimationTask = nil
        waitingForCardReturn  = false
        waitingForCardLift    = false
        cardLifted            = false
        cardReturnHintOffset  = 0
        handBackDrag          = .zero
        handBackArmed         = false
    }

    private func resetState() {
        nameFieldShouldFocus = false
        dealerDisplayed = "";  dealerAlpha = 0.0;  dealerOffsetY = 0.0
        dealPhase = .idle
        cardOffset = .zero; cardAngle = 0; cardAlpha = 0; flipScaleX = 1.0
        showFace = false;   cardScale = 1.0; cardScreenAlpha = 1.0
        impactRingProgress = 0; flipBurstProgress = 0
        activeKeyIndex = -1; carriageProgress = 0
        name = ""; uiAlpha = 0
        lineRevealProgress = 0; hasSweptLine = false; lineBounce = 0
        waitingForCardReturn = false; cardReturnHintOffset = 0
        handBackDrag = .zero; handBackArmed = false
        waitingForCardLift = false; cardLifted = false
        showGreeting = false; greetingName = ""; greetingAlpha = 0.0; nameVisible = false
    }

    // MARK: — Name field events (called from NamePhase's .onChange handlers)

    func onNameChanged(_ newValue: String) {
        // ── Length guard ──────────────────────────────────
        let trimmed = newValue.trimmingCharacters(in: .whitespaces)
        if trimmed.count > AppLayout.maxNameLength {
            name = String(trimmed.prefix(AppLayout.maxNameLength))
        }

        // ── Typewriter keystroke animation ────────────────
        let isSpace = newValue.last == " "
        carriageProgress = CGFloat(newValue.count) / CGFloat(AppLayout.maxNameLength)
        activeKeyIndex = isSpace
            ? 15
            : (newValue.count > 0 ? (newValue.count - 1) % 15 : -1)

        keyAnimationTask?.cancel()
        keyAnimationTask = Task {
            try? await Task.sleep(for: .milliseconds(120))
            guard !Task.isCancelled else { return }
            await MainActor.run { self.activeKeyIndex = -1 }
        }

        // ── Write line bounce ─────────────────────────────
        lineBounce = -3.0
        withAnimation(AppAnimation.writeLineBounce) {
            lineBounce = 0
        }

        // No auto-submit — user commits via Done key or swipe up.
    }

    func onFocusChanged(_ isFocused: Bool) {
        if isFocused && !hasSweptLine {
            hasSweptLine = true
            withAnimation(AppAnimation.lineReveal) {
                lineRevealProgress = 1.0
            }
        } else if isFocused {
            lineRevealProgress = 1.0
        }
    }

    // MARK: — Typing engine

    private func typeDealerLine(_ text: String) async {
        var prev: Character?
        for char in text {
            guard !Task.isCancelled else { return }
            let delay = AppDealerTyping.charDelay(char, prev: prev)
            try? await Task.sleep(for: .milliseconds(Int(delay)))
            guard !Task.isCancelled else { return }
            dealerDisplayed.append(char)
            prev = char
        }
    }

    // MARK: — Shuffle transitions

    private func shuffleExitDealer() async {
        withAnimation(AppDealerTyping.shuffleExitAnim) {
            dealerAlpha   = 0.0
            dealerOffsetY = -22
        }
        try? await Task.sleep(for: .milliseconds(AppDealerTyping.shuffleExitMs))
        guard !Task.isCancelled else { return }
        dealerDisplayed = ""
        dealerOffsetY   = 0
    }

    /// Gentle exit for the lift-lesson prompt: the line drifts up and fades on a long
    /// ease-out so it "floats away," rather than snapping out like the shuffle swap.
    private func floatAwayDealer() async {
        withAnimation(AppDealerTyping.floatAwayAnim) {
            dealerAlpha   = 0.0
            dealerOffsetY = AppDealerTyping.floatAwayDrift
        }
        try? await Task.sleep(for: .milliseconds(AppDealerTyping.floatAwayMs))
        guard !Task.isCancelled else { return }
        dealerDisplayed = ""
        dealerOffsetY   = 0
    }

    private func shuffleEnterDealer() async {
        dealerAlpha   = 0.0
        dealerOffsetY = -18
        try? await Task.sleep(for: .milliseconds(AppDealerTyping.shuffleGapMs))
        guard !Task.isCancelled else { return }
        withAnimation(AppDealerTyping.shuffleEnterAnim) {
            dealerAlpha   = 1.0
            dealerOffsetY = 0
        }
        // Short beat, NOT the full enter duration — the first characters type
        // while the container is still gliding in, so the entrance reads as motion.
        try? await Task.sleep(for: .milliseconds(AppDealerTyping.shuffleGapMs))
    }

    // MARK: — Dealer intro sequence

    private func runDealerIntro() async {
        try? await Task.sleep(for: .milliseconds(500))
        guard !Task.isCancelled else { return }

        // 1. "Noted." lands FIRST — nothing moves yet.
        dealerDisplayed = ""
        await shuffleEnterDealer()
        guard !Task.isCancelled else { return }
        await typeDealerLine("Noted.")
        guard !Task.isCancelled else { return }
        try? await Task.sleep(for: .milliseconds(AppDealerTyping.hangShort))
        guard !Task.isCancelled else { return }

        // 2. THEN the card deal — the dealer SETS it down, it settles, and turns over.
        await setDownCard()
        guard !Task.isCancelled else { return }
        try? await Task.sleep(for: .milliseconds(300))   // FEEL-GATE: settle before the reveal
        guard !Task.isCancelled else { return }
        await performFlipWithBurst()
        guard !Task.isCancelled else { return }
        try? await Task.sleep(for: .milliseconds(300))   // FEEL-GATE: hold the revealed face
        guard !Task.isCancelled else { return }

        // ── Beat 2 dealer copy ────────────────────────────────────
        await shuffleExitDealer()
        guard !Task.isCancelled else { return }

        await shuffleEnterDealer()
        guard !Task.isCancelled else { return }
        await typeDealerLine("And who am I dealing in?")
        guard !Task.isCancelled else { return }
        try? await Task.sleep(for: .milliseconds(AppDealerTyping.hangShort))
        guard !Task.isCancelled else { return }

        // ── Inline name input entry ───────────────────────────────
        dealPhase = .nameInput
        withAnimation(AppAnimation.uiFadeIn) { uiAlpha = 1.0 }
        impactHeavy.prepare()
        impactSoft.prepare()
        try? await Task.sleep(for: .milliseconds(200))
        guard !Task.isCancelled else { return }
        nameFieldShouldFocus = true
    }

    // MARK: — Set-down (no re-deal)

    /// The card is SET DOWN, not dealt — it fades in already at the felt's center and
    /// eases down to rest (a hair high + large + transparent → settled).
    private func setDownCard() async {
        let tableCenter = CGPoint(x: screenSize.width * 0.50, y: screenSize.height * 0.55)
        let rest = CGSize(width: tableCenter.x - screenSize.width  / 2,
                          height: tableCenter.y - screenSize.height / 2)
        dealPhase = .resting
        cardAngle = 0

        guard !reduceMotion else {
            cardOffset = rest; cardScale = 1.0; cardAlpha = 1
            return
        }

        // Start a hair high, large, and transparent; settle down as it fades in.
        cardOffset = CGSize(width: rest.width, height: rest.height - 24)   // FEEL-GATE: drop distance
        cardScale  = 1.06
        cardAlpha  = 0
        withAnimation(AppAnimation.cardSetDown) {
            cardOffset = rest
            cardScale  = 1.0
            cardAlpha  = 1
        }
        try? await Task.sleep(for: .milliseconds(720))
    }

    // MARK: — Flip mechanics

    private func performFlipWithBurst() async {
        dealPhase = .flipping
        fireImpactRing()
        rimBurstTrigger += 1   // View owns tableRimBurst — relay the pulse
        await performFlip()
    }

    private func performFlip() async {
        withAnimation(AppAnimation.cardFlipHalf) {
            flipScaleX = 0.0
        }
        try? await Task.sleep(for: .milliseconds(290))
        guard !Task.isCancelled else { return }

        showFace = true

        withAnimation(AppAnimation.cardFlipHalf) {
            flipScaleX = -1.0
        }
        try? await Task.sleep(for: .milliseconds(290))
    }

    private func performFlipBack() async {
        if reduceMotion {
            showFace   = false
            flipScaleX = 1.0
            return
        }
        withAnimation(AppAnimation.cardFlipHalf) {
            flipScaleX = 0.0
        }
        try? await Task.sleep(for: .milliseconds(290))

        showFace = false

        withAnimation(AppAnimation.cardFlipHalf) {
            flipScaleX = 1.0
        }
        try? await Task.sleep(for: .milliseconds(290))
    }

    // MARK: — Card collect

    private func performCardCollect() async {
        let cornerX = screenSize.width  - AppLayout.cornerDeckRight - AppLayout.cornerDeckWidth  / 2
        let cornerY = AppLayout.cornerDeckTop + AppLayout.cornerDeckHeight / 2

        withAnimation(AppAnimation.cardPocket) {
            cardOffset = CGSize(
                width: cornerX - screenSize.width  / 2,
                height: cornerY - screenSize.height / 2
            )
            cardScale = AppLayout.cornerDeckWidth / cardWidth
            // The live hand-off drift (and its tilt) resolves INTO the pocket flight.
            handBackDrag = .zero
        }
        // Alpha rides its own late curve: the card stays visible for ~90% of the travel
        // and dissolves INTO the deck.
        withAnimation(AppAnimation.pocketAlphaFade) {
            cardAlpha = 0
        }

        // Pulse the deck as the card lands (travel ends at 520ms), not before.
        try? await Task.sleep(for: .milliseconds(480))

        director.receiveCredential(.name)
    }

    // MARK: — Effects helpers

    private func fireImpactRing() {
        impactRingProgress = 0
        withAnimation(AppAnimation.impactRingDecay) {
            impactRingProgress = 1.0
        }
    }

    // MARK: — Swipe handler
    //
    // Handles two distinct swipe-up moments:
    //   1. During nameInput  — upward swipe submits the name.
    //   2. waitingForCardReturn — upward swipe gives the card to the dealer and advances.

    func handleSwipe(_ translation: CGSize) {
        guard translation.height < -AppLayout.swipeSubmitThreshold else { return }

        guard dealPhase == .nameInput else { return }
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            impactMedium.impactOccurred()
            return
        }
        submitName()
    }

    // MARK: — Live hand-off (finger-following swipe-up)

    func updateHandBack(_ translation: CGSize) {
        // Shared, locked mechanic (see HandBackFollow): weighty, banded, can't fly off.
        handBackDrag = HandBackFollow.offset(for: translation,
                                             cardWidth: cardWidth, cardHeight: cardHeight)

        let crossed = translation.height < -AppLayout.swipeSubmitThreshold
        if crossed != handBackArmed {
            handBackArmed = crossed
            selectionGen.selectionChanged()
        }
    }

    func endHandBack(_ value: DragGesture.Value) {
        handBackArmed = false
        let travelled = value.translation.height
        let projected = value.predictedEndTranslation.height
        // Commit on distance crossed OR a confident upward flick.
        if travelled < -AppLayout.swipeSubmitThreshold
            || projected < -AppLayout.swipeSubmitThreshold * 1.6 {
            waitingForCardReturn = false
            // Let performCardCollect animate the live drag (and its tilt) to zero IN THE
            // SAME pocket flight, so the drift resolves smoothly into the corner-deck flight.
            completeCardReturn()
        } else {
            // Short of the threshold — the card settles back to the lift anchor.
            withAnimation(AppAnimation.cardSettle.reduceMotionSafe) { handBackDrag = .zero }
        }
    }

    // MARK: — Submit

    func submitName() {
        guard dealPhase != .collecting else { return }
        inputFocusTask?.cancel()
        inputFocusTask = nil
        nameFieldShouldFocus = false

        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            impactMedium.impactOccurred()
            return
        }

        impactHeavy.impactOccurred()
        director.onboardingData.displayName = trimmed
        dealPhase = .collecting

        Task { @MainActor in
            // Dismiss input zone
            withAnimation(AppAnimation.exit) { uiAlpha = 0 }

            // Instantly clear Beat 2 copy — no fade, no delay
            dealerDisplayed = ""
            dealerAlpha     = 0

            // ── Beat 3 — greeting rises ───────────────────────────
            greetingName = trimmed
            nameVisible  = false
            showGreeting = true
            withAnimation(AppAnimation.textProject.reduceMotionSafe) {
                greetingAlpha = 1.0
            }

            try? await Task.sleep(for: .milliseconds(200))
            withAnimation(AppAnimation.standard.reduceMotionSafe) { nameVisible = true }
            try? await Task.sleep(for: .milliseconds(800))

            withAnimation(AppAnimation.textProject.reduceMotionSafe) { greetingAlpha = 0.0 }
            // Full textProject duration — unmounting at 350ms cut the fade.
            try? await Task.sleep(for: .milliseconds(500))
            showGreeting = false
            nameVisible  = false

            // Card stays FACE UP through the lesson — the user picks up and hands back
            // their own card, exactly like the face-up cards in the selection phases.

            // ── The dealer's one-time lesson: how cards work at his table ──────
            dealerDisplayed = ""
            await shuffleEnterDealer()
            await typeDealerLine("Tap the card to pick it up.")
            try? await Task.sleep(for: .milliseconds(300))

            // Hand off to the tap. handleLiftTap() drives the rest.
            waitingForCardLift = true
        }
    }

    // MARK: — Guided lesson (tap to lift, then swipe to hand back)

    /// Step 1 → 2: the user taps the card. It lifts with the shared affordance,
    /// then the dealer prompts the swipe.
    func handleLiftTap() {
        guard waitingForCardLift else { return }
        waitingForCardLift = false
        impactSoft.impactOccurred()
        selectionGen.prepare()   // hand-off tick is imminent
        // Lift exactly like the selection phases (ThreeCardFanController.lift).
        withAnimation(AppAnimation.cardLift.reduceMotionSafe) {
            cardLifted = true
            cardOffset = CGSize(width: 0, height: screenSize.height * 0.42 - screenSize.height / 2)
            cardScale  = 1.12
        }

        liftTeachTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(420))   // let the lift settle
            guard !Task.isCancelled else { return }
            await teachSwipeUp()
        }
    }

    /// Step 2: the dealer asks for the card, then the swipe becomes live.
    private func teachSwipeUp() async {
        // Let the "Tap the card" line float away, then the next line enters.
        await floatAwayDealer()
        guard !Task.isCancelled else { return }
        await shuffleEnterDealer()
        guard !Task.isCancelled else { return }
        await typeDealerLine("Now swipe up to hand it to me.")
        guard !Task.isCancelled else { return }
        try? await Task.sleep(for: .milliseconds(300))
        waitingForCardReturn = true
    }

    // MARK: — Complete card return (called by swipe-up gesture after demo)

    private func completeCardReturn() {
        // Snap any residual hint offset
        cardReturnHintOffset = 0

        // Fade the dealer line — text is cleared after the collect (≥350ms).
        withAnimation(AppDealerTyping.finalFadeAnim) { dealerAlpha = 0 }

        impactHeavy.impactOccurred()

        Task { @MainActor in
            await performCardCollect()

            dealerDisplayed = ""
            dealerAlpha     = 1.0

            assert(
                !director.cornerDeckCards.isEmpty,
                "cornerDeckCards must have ≥1 card before advancing to modeSelect"
            )

            try? await Task.sleep(for: .milliseconds(250))
            director.advance(to: .modeSelect)
        }
    }
}
