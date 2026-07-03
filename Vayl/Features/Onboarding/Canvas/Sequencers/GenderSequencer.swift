//
//  GenderSequencer.swift
//  Vayl
//
//  Extracted from VaylDirector (audit S1 — decomposition phase 1).
//

// Features/Onboarding/Canvas/Sequencers/GenderSequencer.swift

import SwiftUI

/// Owns the entire Gender phase: the dissolution / crystallisation sequence, the radio-tuner
/// signal, both drums (gender + pronouns), tap-to-lift → swipe-up confirm.
///
/// Self-contained — its callbacks to the coordinator are writing the chosen gender / pronouns
/// into `onboardingData` and projecting dealer lines (both via `OnboardingStage`). It does not
/// call `advance` (GenderPhase does that after observing `shouldPocket`).
///
/// Held by VaylDirector as `@ObservationIgnored lazy var gender = GenderSequencer(stage: self)`
/// — the same pattern the director uses for `cardFlightEngine`. Views read `director.gender.*`.
@Observable
@MainActor
final class GenderSequencer {

    /// Coordinator callback surface — used only to record the selection into `onboardingData`.
    @ObservationIgnored unowned let stage: OnboardingStage

    init(stage: OnboardingStage) {
        self.stage = stage
    }

    // MARK: - Card + dissolution state

    var cardOffset:     CGSize = .zero
    var cardFlipScaleX: Double = 1.0
    var cardFaceUp:     Bool   = false
    var cardVisible:    Bool   = false
    var cardSettled:    Bool   = false
    /// Lift transform — tap-to-lift → swipe-up, the grammar taught in NamePhase.
    var cardLifted:     Bool   = false
    var cardScale:      Double = 1.0
    /// Fades late in the pocket flight so the card visibly lands in the deck.
    var cardAlpha:      Double = 1.0

    /// Primary driver for the dissolution / recrystallisation sequence.
    /// 0 = indistinguishable from felt. 1 = fully crystallised. All curves derive from this —
    /// one @Observable write per frame keeps SwiftUI invalidation minimal.
    var dissolutionT:   Double = 0

    var beatComplete:      Bool   = false

    /// Swipe-hint loop flag — true while the card is lifted; false on grab / lower / confirm.
    var swipeHintActive:   Bool   = false

    /// Toggles when both drums sit settled on a choice — the "lined up" thud.
    /// GenderPhase observes via .sensoryFeedback.
    var lockThudTrigger:   Bool   = false

    // MARK: - Picker / drums

    var pickerVisible: Bool     = false
    var options:       [String] = [
        "Man", "Woman", "Trans Man", "Trans Woman", "Non-binary",
    ]
    var drumOffset:    CGFloat  = 0
    /// -1 = no real selection yet (dial sits on the "—" placeholder). Blank-start:
    /// the user must tune each dial (or decline) before the card can be lifted.
    var selectedIndex: Int      = -1
    var drumSettled:   Bool     = false

    /// Radio tuner signal state.
    var signalStrength: Double = 0

    // Pronouns drum (mirrors the gender drum). Pure pronoun preferences — the
    // "prefer not to say" opt-out is now the shared decline bar under both drums
    // (GenderPhase), so it lives in one place instead of two inconsistent ones.
    var pronounsOptions:       [String] = ["she/her", "he/him", "they/them", "ze/zir", "any pronouns"]
    var pronounsDrumOffset:    CGFloat  = 0
    var pronounsSelectedIndex: Int      = -1   // -1 = placeholder, no real selection yet
    var pronounsDrumSettled:   Bool     = false

    var bothSettled: Bool { drumSettled && pronounsDrumSettled }

    /// Shared "prefer not to say" opt-out — declines BOTH gender and pronouns at once
    /// (the bar under the dials). A valid, active completion of the identity card.
    var declined: Bool = false

    /// The card may be lifted once the user has tuned both dials to a real option OR
    /// tapped the decline bar. Blank-start means there's no valid default to passively
    /// accept, so requiring a choice strands no one (unlike the prior "did you scroll?"
    /// gate — see the runEntry note).
    var armedToLift: Bool { declined || bothSettled }

    /// GenderPhase observes this; advances to `.experienceLevel` on true.
    var shouldPocket: Bool = false

    /// Pre-placed gender card. Set during the NamePhase greeting via `placeCardSilently`.
    var pendingCard: VaylCardModel? = nil

    /// Task handle for the visual sequence. Not observed — internal bookkeeping only.
    @ObservationIgnored var sequenceTask: Task<Void, Never>? = nil

    // MARK: - Dissolution computed curves
    // All eight derive from dissolutionT (0→1). eIO3 = ease-in-out cubic, eO5/eO7 = ease-out quint/sept.

    var dissolutionPre:        Double { CanvasEasing.eIO3(CanvasEasing.nm(dissolutionT, 0,    0.12)) }
    var dissolutionWarp:       Double { CanvasEasing.eIO3(CanvasEasing.nm(dissolutionT, 0.08, 0.20)) * 0.52 }
    // Density window pulled forward (0.05 vs 0.18): visible matter must exist
    // within ~0.5s of entry — the old window left the first ~1.3s of the
    // sequence driving values nothing on screen could show.
    var dissolutionDensity:    Double { CanvasEasing.eO5(CanvasEasing.nm(dissolutionT, 0.05, 0.40)) }
    var dissolutionSharp:      Double { CanvasEasing.eO7(CanvasEasing.nm(dissolutionT, 0.42, 0.32)) }
    var dissolutionHexAngle:   Double { CanvasEasing.eIO3(CanvasEasing.nm(dissolutionT, 0.24, 0.42)) * 8.0 }
    var dissolutionHexSpacing: Double { 2.2 + (1.0 - 2.2) * CanvasEasing.eIO3(CanvasEasing.nm(dissolutionT, 0.24, 0.44)) }
    var dissolutionFlowOut:    Double { CanvasEasing.eIO3(CanvasEasing.nm(dissolutionT, 0.50, 0.30)) }
    var dissolutionMark:       Double { CanvasEasing.eO7(CanvasEasing.nm(dissolutionT, 0.62, 0.26)) }

    // MARK: - Pre-place (called from NamePhase)

    func placeCardSilently(screenSize: CGSize) {
        let card        = VaylCardModel()
        card.credential = .gender
        let tableY = screenSize.height * 0.58  // sits in upper felt, below the arc
        card.position  = CGPoint(x: screenSize.width / 2, y: tableY)
        card.rotation  = 0
        card.opacity   = 1.0
        card.elevation = 0.0
        card.isFaceUp  = false
        // Stored here, never in tableCards — VaylCardRenderer only renders tableCards,
        // so the card is invisible during NamePhase. GenderPhase consumes it on open.
        pendingCard = card
    }

    // MARK: - Entry & sequence
    //   runEntry()      = sync, router-owned, no View lifecycle coupling
    //   startSequence() = async, View-lifecycle-owned, never called by router

    /// Sync reset only — resets all visual state so the View starts clean on every entry.
    func runEntry() {
        sequenceTask?.cancel()
        sequenceTask = nil

        cardOffset         = .zero
        cardFlipScaleX     = 1.0
        cardFaceUp         = false
        cardVisible        = false
        cardSettled        = false
        cardLifted         = false
        cardScale          = 1.0
        cardAlpha          = 1.0
        dissolutionT       = 0
        beatComplete       = false
        signalStrength     = 0
        swipeHintActive    = false
        pickerVisible      = false
        options            = [
            "Man", "Woman", "Trans Man", "Trans Woman", "Non-binary",
        ]
        drumOffset         = 0
        selectedIndex      = -1
        pronounsDrumOffset    = 0
        pronounsSelectedIndex = -1
        // Drums START BLANK (both dials on the "—" placeholder). The card's lift is
        // gated on armedToLift — the user must tune both dials to a real option or tap
        // the decline bar. A PRIOR gate keyed on "did the user scroll both drums"
        // stranded anyone whose identity matched the default; blank-start removes the
        // valid default, so requiring a choice strands no one.
        drumSettled         = false
        pronounsDrumSettled = false
        declined            = false
        shouldPocket       = false
    }

    /// Called by GenderPhase.onAppear. Safe to call multiple times.
    func startSequence(screenSize: CGSize, reduceMotion: Bool) {
        sequenceTask?.cancel()
        sequenceTask = Task { await runRise(screenSize: screenSize, reduceMotion: reduceMotion) }
    }

    /// Called by GenderPhase.onDisappear. Cancel only — NEVER hide the dealer
    /// line here: onDisappear fires mid cross-fade, after the next phase has
    /// already projected its own line (advance() owns cross-phase line cleanup).
    func cancelSequence() {
        sequenceTask?.cancel()
        sequenceTask = nil
    }

    /// Full autonomous sequence: crystallise → dealer line → flip → picker.
    /// dissolutionT (0→1) drives the Segment 1 visual curves; later beats are direct state writes.
    @MainActor
    private func runRise(screenSize: CGSize, reduceMotion: Bool) async {
        guard !options.isEmpty else { return }

        // Rest position: centred, obGenderCardRestYFrac down screen (layout token — never UIScreen.main).
        let restY = screenSize.height * AppLayout.obGenderCardRestYFrac - screenSize.height / 2

        // ── Reduce Motion: instant all state ──────────────────────────────────
        if reduceMotion {
            cardOffset         = CGSize(width: 0, height: restY)
            cardVisible        = true
            dissolutionT       = 1
            cardSettled        = true
            cardFaceUp         = true
            cardFlipScaleX     = 1.0
            cardLifted         = false
            cardScale          = 1.0
            cardAlpha          = 1.0
            beatComplete       = true
            signalStrength     = 0
            swipeHintActive    = false
            pickerVisible      = true
            drumOffset         = 0
            selectedIndex      = -1
            pronounsDrumOffset    = 0
            pronounsSelectedIndex = -1
            // Blank-start under Reduce Motion too — the user still chooses (or declines);
            // only the deal/flip theatre is skipped, not the identity gate.
            drumSettled         = false
            pronounsDrumSettled = false
            declined            = false
            shouldPocket       = false
            return
        }

        // ── SEGMENT 1 — Card crystallises out of the felt ─────────────────────
        // dissolutionT drives eight computed curves; one @Observable write per ~14ms tick.
        cardOffset  = CGSize(width: 0, height: restY)
        cardVisible = true
        dissolutionT = 0

        // One frame before the drive loop so SwiftUI registers initial state.
        try? await Task.sleep(for: .milliseconds(16))
        guard !Task.isCancelled else { return }

        // 3.2s — compressed from 7.0: the long form left multiple seconds with
        // nothing legible on screen (density only began at T=0.18). The dealer
        // line types DURING crystallisation so the voice covers the formation —
        // the same bridge that makes the Gender→Experience seam read seamless.
        //
        // FrameClock (CADisplayLink) drives the loop — one dissolutionT write per
        // rendered frame. The previous 14ms Task.sleep loop beat against the
        // display cadence (double-writes some frames, skips others), which
        // juddered the crystallisation.
        let dur   = 3.2
        let line  = "Let's find your place at the table."
        var lineFired = false
        let start = Date()

        for await _ in FrameClock.frames() {
            guard !Task.isCancelled else { break }
            let elapsed = -start.timeIntervalSinceNow
            let t = min(elapsed / dur, 1.0)
            dissolutionT = t
            if !lineFired && elapsed >= 1.0 {
                lineFired = true
                stage.showDealerLineManual(line, anchorYFrac: AppLayout.tableHorizonYFrac)
            }
            if t >= 1.0 { break }
        }

        guard !Task.isCancelled else { return }
        dissolutionT = 1
        cardSettled  = true

        // ── SEGMENT 2 — Let the line land, then flip ──────────────────────────
        // Line fired at 1.0s in; hold until it finishes typing + a read beat
        // before the flip becomes the new motion anchor.
        let lineDoneS = 1.0 + Double(AppDealerTyping.typeDuration(line)) / 1000.0
        let holdMs    = max(200, Int((lineDoneS + 0.4 - dur) * 1000))
        try? await Task.sleep(for: .milliseconds(holdMs))
        guard !Task.isCancelled else { return }
        await runFlipAndSpin()
    }

    /// Beat B through Segment 7 — flip card face-up, power-on beat, show picker.
    private func runFlipAndSpin() async {

        // ── Flip half 1 — collapse scaleX to 0 ───────────────────────────────
        withAnimation(AppAnimation.cardFlipHalf.reduceMotionSafe) {
            cardFlipScaleX = 0.0
        }
        try? await Task.sleep(for: .milliseconds(300))
        guard !Task.isCancelled else { return }

        // Face swap at scaleX = 0 — card is invisible, no visual pop
        cardFaceUp = true

        // Flip half 2 — expand scaleX back to 1
        withAnimation(AppAnimation.cardFlipHalf.reduceMotionSafe) {
            cardFlipScaleX = 1.0
        }
        try? await Task.sleep(for: .milliseconds(300))
        guard !Task.isCancelled else { return }

        // Beat: hold so the radio face registers before the dealer line fades
        try? await Task.sleep(for: .milliseconds(300))
        guard !Task.isCancelled else { return }
        beatComplete = true

        stage.hideDealerLine()
        try? await Task.sleep(for: .milliseconds(180))
        guard !Task.isCancelled else { return }

        withAnimation(AppAnimation.standard.reduceMotionSafe) {
            pickerVisible = true
        }
    }

    // MARK: - Drum interaction
    // The only paths through which GenderPhase writes back. All drum-sync math lives here.

    /// Called every frame while the gender drum is dragged.
    func updateDrum(offset: CGFloat) {
        drumOffset  = offset
        drumSettled = false
        declined    = false   // grabbing a dial cancels a prior decline
        if signalStrength > 0 {
            withAnimation(AppAnimation.standard.reduceMotionSafe) { signalStrength = 0 }
        }
    }

    /// Called every frame while the pronouns drum is dragged.
    func updatePronounsDrum(offset: CGFloat) {
        pronounsDrumOffset  = offset
        pronounsDrumSettled = false
        declined            = false
        if signalStrength > 0 {
            withAnimation(AppAnimation.standard.reduceMotionSafe) { signalStrength = 0 }
        }
    }

    /// Called when the gender drum snaps. `index` is -1 when it lands back on the "—"
    /// placeholder (un-choosing), 0..n-1 on a real option.
    func settleDrum(index: Int) {
        selectedIndex = index
        drumSettled   = index >= 0
        if index >= 0 { declined = false }   // a real choice cancels a prior decline
        if armedToLift { fireBothSettled() }
    }

    /// Pronouns drum snap. `index` is -1 on the "—" placeholder, 0..n-1 on a real option.
    func settlePronounsDrum(index: Int) {
        pronounsSelectedIndex = index
        pronounsDrumSettled   = index >= 0
        if index >= 0 { declined = false }
        if armedToLift { fireBothSettled() }
    }

    /// Both drums sit settled on a choice — signal locks, and the "lined up"
    /// thud fires (GenderPhase observes lockThudTrigger). No dealer copy here:
    /// the lock is physical feedback, not a conversation beat.
    private func fireBothSettled() {
        withAnimation(AppAnimation.standard.reduceMotionSafe) {
            signalStrength = 1.0
        }
        lockThudTrigger.toggle()
    }

    /// Shared decline bar — "prefer not to say" for the whole identity card. Clears both
    /// dials back to the placeholder and arms the lift (a valid, active choice). The view
    /// resets the drum strips to the placeholder position; this owns the model state.
    func declineIdentity() {
        selectedIndex         = -1
        pronounsSelectedIndex = -1
        drumSettled           = false
        pronounsDrumSettled   = false
        declined              = true
        fireBothSettled()   // arm: signal locks + "lined up" thud
    }

    // MARK: - Lift / lower
    // Tap-to-lift → swipe-up — the grammar taught in NamePhase, identical to the
    // sibling selection phases. Callers wrap these in withAnimation(cardLift) so
    // animation context stays at the View layer (CardMirrorDealController pattern).

    /// Tap on the resting card. Gated on `armedToLift` — the user must tune both dials
    /// to a real option (or tap the decline bar) before the card will lift.
    func liftCard(screenSize: CGSize) {
        guard pickerVisible, armedToLift, !cardLifted else { return }
        cardLifted = true
        cardOffset = CGSize(width: 0, height: screenSize.height * 0.42 - screenSize.height / 2)
        cardScale  = 1.12
        beginSwipeHint()
    }

    /// Tap on the lifted card — set it back down to adjust the drums.
    func lowerCard(screenSize: CGSize) {
        guard cardLifted else { return }
        endSwipeHint()
        cardLifted = false
        cardOffset = CGSize(width: 0,
                            height: screenSize.height * AppLayout.obGenderCardRestYFrac
                                  - screenSize.height / 2)
        cardScale  = 1.0
    }

    // MARK: - Swipe hint

    /// Starts the looping "swipe up" affordance on the lifted card.
    func beginSwipeHint() { swipeHintActive = true }

    /// Stops the swipe-hint loop — called the instant the user grabs the card.
    func endSwipeHint()   { swipeHintActive = false }

    // MARK: - Confirm

    /// Swipe-up on the LIFTED card. Persists self gender/pronouns to onboardingData
    /// (genderA/pronounsA) via the stage — partner gender arrives via pairing, never
    /// set here — then flies the card to the corner deck (cardPocket travel, late
    /// alpha so it visibly lands). Sets `shouldPocket`; GenderPhase credits the deck
    /// on landing and advances.
    func confirmSelection(screenSize: CGSize, cardWidth: CGFloat) {
        guard cardLifted else { return }
        endSwipeHint()
        if declined {
            stage.onboardingData.genderA   = nil
            stage.onboardingData.pronounsA = nil
        } else {
            stage.onboardingData.genderA   = options.indices.contains(selectedIndex)
                ? options[selectedIndex] : nil
            stage.onboardingData.pronounsA = pronounsOptions.indices.contains(pronounsSelectedIndex)
                ? pronounsOptions[pronounsSelectedIndex] : nil
        }

        withAnimation(AppAnimation.fast.reduceMotionSafe) { pickerVisible = false }

        let cornerX = screenSize.width - AppLayout.cornerDeckRight - AppLayout.cornerDeckWidth / 2
        let cornerY = AppLayout.cornerDeckTop + AppLayout.cornerDeckHeight / 2
        withAnimation(AppAnimation.cardPocket.reduceMotionSafe) {
            cardLifted = false
            cardOffset = CGSize(width:  cornerX - screenSize.width  / 2,
                                height: cornerY - screenSize.height / 2)
            cardScale  = AppLayout.cornerDeckWidth / cardWidth
        }
        // Alpha rides its own late curve so the card stays visible for ~90% of
        // the flight and dissolves INTO the deck rather than vanishing at launch.
        withAnimation(AppAnimation.pocketAlphaFade.reduceMotionSafe) { cardAlpha = 0 }

        shouldPocket = true
    }

    /// Heals the felt after the gender card has pocketed. The dissolution curves
    /// (dissolutionWarp / dissolutionFlowOut) feed the PERSISTENT TableSurfaceView —
    /// left at dissolutionT = 1 they keep the topo lines deflected around the
    /// now-departed card for the entire rest of the OB (the "felt scar"). Reset on
    /// pocket so the felt returns to rest. Called by GenderPhase once the card lands.
    func resetDissolution() {
        dissolutionT = 0
    }
}
