// Features/Onboarding/Canvas/VaylDirector.swift

import SwiftUI
import SpriteKit

@Observable
@MainActor
final class VaylDirector: OnboardingStage {

    var phase: OBPhase = .stat

    var tableCards:      [VaylCardModel] = []
    var cornerDeckCards: [VaylCardModel] = []
    var inFlightCards:   [VaylCardModel] = []
    var muckCards:       [VaylCardModel] = []

    var onboardingData: OnboardingData = OnboardingData()
    var openerDeckType: OpenerDeckType = .anxious

    /// Which credential the ConfirmationPhase is currently editing. Drives the
    /// edit half-sheet hosted at OnboardingCanvasWrapper (outside the canvas,
    /// which forbids .sheet). nil = no sheet open.
    var editingCredential: OBCredential? = nil

    var tableFade:          Double = 0.0
    var dealPointIntensity: Double = 0.0

    // Lazy — deferred until first access so previews and unit tests that
    // create VaylDirector() don't spin up a SpriteKit scene unnecessarily.
    // @ObservationIgnored is safe because the scene object never changes;
    // only its contents mutate (handled internally by CardFlightScene itself).
    @ObservationIgnored lazy var cardFlightScene: CardFlightScene = CardFlightScene()

    var projectedText:        String? = nil
    var projectedTextVisible: Bool    = false
    /// Vertical anchor for the projected dealer line — set per-line by
    /// showDealerLine. Defaults to the table horizon; beats whose hero occupies
    /// the horizon band (BuildDeck Beat 4 float) project above it instead.
    var projectedTextAnchorYFrac: CGFloat = AppLayout.tableHorizonYFrac

    // MARK: - Gender Phase  (extracted → GenderSequencer)
    //
    // All gender state + the autonomous sequence now live in GenderSequencer. The director
    // holds it (same @ObservationIgnored lazy pattern as cardFlightEngine) and conforms to
    // OnboardingStage so the sequencer can record its result into onboardingData.
    @ObservationIgnored lazy var gender = GenderSequencer(stage: self)

    // MARK: - Curiosity Phase

    /// Remaining unseen cards in the current round. Index 0 = top of pile (interactive).
    var curiosityPile:               [CuriositySortCard] = []
    /// 0 = Round 1 (communicationGoals), 1 = Round 2 (learningGoals).
    var curiosityRoundIndex:         Int               = 0
    var curiosityKeptRound1:         [String]          = []
    var curiosityKeptRound2:         [String]          = []
    /// Live drag offset of the top card. View reads this; director writes it.
    var curiosityDragOffset:         CGSize            = .zero
    /// The card currently flying off-screen after a commit (user swipe or demo auto-swipe).
    /// Rendered by the View as a separate overlay so the departing card keeps its own
    /// identity while the next card rises from the pile underneath. nil when nothing is mid-flight.
    var curiosityFlyingCard:         CuriositySortCard? = nil
    /// Offset of the flying card. Starts at the release position, then animates off-screen.
    var curiosityFlyingOffset:       CGSize            = .zero
    /// Flips whenever the drag crosses the 95pt commit threshold. Triggers .selection haptic in View.
    var curiosityThresholdCrossed:   Bool              = false
    /// Toggled to trigger the deal animation in CuriosityPhase. View observes via onChange.
    var curiosityDealTrigger:        Bool              = false
    /// Prevents double-fire during the 1100ms round-gap beat.
    var curiosityRoundTransitioning: Bool              = false
    /// True while the 2-card auto-swipe tutorial is running. View disables user gesture when set.
    var curiosityDemoActive:         Bool              = false
    /// Demo-only commit thunk — the user path's commit haptic is view-owned; this
    /// fires the same impact for the dealer's demonstration swipes.
    var curiosityDemoCommitTrigger:  Bool              = false

    // The forged summary card — "your yeses build one card." Materialises at the
    // pile position after the last commit, then takes the standard cardPocket
    // flight to the corner deck. Rendered by CuriosityPhase.
    var curiositySummaryVisible: Bool   = false
    var curiositySummaryOffset:  CGSize = .zero
    var curiositySummaryScale:   Double = 1.0
    var curiositySummaryAlpha:   Double = 1.0
    /// True while the forged deck sits in the user's hand (lift anchor + halo)
    /// awaiting the swipe-up handoff. Gates the deck's gesture + tug hint.
    var curiositySummaryPresented: Bool = false

    @ObservationIgnored var curiositySequenceTask: Task<Void, Never>? = nil
    /// Cancellation token for the flying-card clear timer — bumped on each commit so a
    /// rapid second swipe doesn't let a stale timer wipe the newer flying card early.
    @ObservationIgnored private var curiosityFlyingClearAttempt: Int = 0

    var foilIntegrity: Double     = 1.0
    var foilTears:     [FoilTear] = []

    var deckPulse: Bool = false

    private var sequenceAttempt:   Int = 0
    private var dealerLineAttempt: Int = 0

    @ObservationIgnored lazy var cardFlightEngine: CardFlightEngine = CardFlightEngine(director: self)

    /// True when the final commit failed (incomplete data or save error). Observable
    /// hook for the terminal phase to surface an error / retry. finishOnboarding()
    /// resets it on each attempt. Failure is non-destructive — the user stays in OB.
    var commitFailed: Bool = false

    func start() {
        phase = .stat
        handlePhaseEntry(.stat)
    }

    private var isTransitioning: Bool = false

    func advance(to next: OBPhase) {
        guard !isTransitioning else { return }
        isTransitioning = true
        // No dealer line outlives its phase: hide it AT advance and invalidate
        // any pending hide timer. The next phase may show its own line from
        // entry — an outgoing phase's teardown (onDisappear fires ~300ms later,
        // mid cross-fade) must never be the thing that clears the canvas line,
        // or it wipes the incoming phase's copy.
        dealerLineAttempt += 1
        hideDealerLine()
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(50)) // advance debounce — double-fire guard only
            phase = next
            handlePhaseEntry(next)
            isTransitioning = false
        }
    }

    private func handlePhaseEntry(_ phase: OBPhase) {
        switch phase {
        case .stat:            break
        case .demo:            runDemoEntry()
        case .name:            runNameEntry()
        case .modeSelect:      runModeSelectEntry()
        case .gender:          gender.runEntry()
        case .experienceLevel: runExperienceLevelEntry()
        case .context:         runContextEntry()
        case .curiosity:       runCuriosityEntry()
        case .confirmation:    runConfirmationEntry()
        case .buildDeck:       runBuildDeckEntry()
        case .founderLetter:   runFounderLetterEntry()
        }
    }

    private func runNameEntry() {
        cardFlightEngine.resetSlotPool()
        Task { @MainActor in
            // One breath after the cross-fade, then the felt blooms. easeOut so
            // the table is perceptible immediately — easeIn held it at near-zero
            // for the first half and the world arrived after the dealer spoke.
            try? await Task.sleep(for: .milliseconds(200))
            // DemoPhase now owns the table fade-in (it precedes name). If the felt
            // is already up, don't re-animate to the same value — guard so the
            // carry-over from demo stays seamless. Re-fading 1.0→1.0 is a visual
            // no-op, but the guard keeps the intent explicit.
            guard tableFade < 1.0 else { return }
            withAnimation(.easeOut(duration: 1.2)) { tableFade = 1.0 }
        }
    }

    /// DemoPhase entry — owns only the table fade-in (moved off name). The full
    /// scene (intro lines → deal → flip → tap-lift → compose → swipe-seal) is
    /// driven by DemoPhase itself, mirroring how NamePhase owns runDealerIntro.
    private func runDemoEntry() {
        cardFlightEngine.resetSlotPool()
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(200))
            withAnimation(.easeOut(duration: 1.2)) { tableFade = 1.0 }
        }
    }

    /// Called by DemoPhase when the snapshot seals (card landed in the deck).
    /// Derives the EmotionalRegister from verb × noun, writes the snapshot data,
    /// and credits the corner deck. The phase owns the visual seal/dissolve/pocket
    /// and fires the advance to .name after its closing beat.
    func commitDemoSnapshot(verb: DemoVerb, noun: String) {
        let trimmed = noun.trimmingCharacters(in: .whitespaces)
        onboardingData.demoVerb          = verb.rawValue
        onboardingData.demoNoun          = trimmed
        onboardingData.emotionalRegister = DemoDictionary.register(verb: verb, noun: trimmed).rawValue
        receiveCredential(.snapshot)
    }

    private func runModeSelectEntry() {
        withAnimation(.easeOut(duration: 0.6)) { tableFade = 1.0 }
        // Speech bubble handled by ModeSelectPhase directly
    }
    private func runExperienceLevelEntry() {
        // Controller is View-owned (@State in ExperienceLevelPhase); nothing to reset here.
    }

    /// The single path for crediting the corner deck. Appends a freshly-collected
    /// credential card and plays the "deck receives a card" pulse. Phases call this
    /// instead of mutating `cornerDeckCards` / `deckPulse` directly — keeps card-state
    /// ownership in the director (Views never write card models).
    func receiveCredential(_ credential: OBCredential) {
        let card = VaylCardModel()
        card.credential = credential
        cornerDeckCards.append(card)
        withAnimation(AppAnimation.deckReceive) { deckPulse = true }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(600))
            deckPulse = false
        }
    }

    /// Called by ExperienceLevelPhase on confirm. Writes nmStage, adds the collected
    /// card to the corner deck (so the "X / 6" count grows), pulses the deck, then advances.
    func commitExperienceLevel(_ intensity: CandleIntensity) {
        onboardingData.nmStage = intensity.nmStage

        receiveCredential(.experienceLevel)
        // NOTE: advance to .context is NOT fired here. This method is the "receive"
        // step — it must coincide with the winner card landing in the deck. The phase
        // advance flows from ExperienceLevelPhase's `.done` state observer, after the
        // controller has cleared the two discards and held a settle beat.
    }
    private func runContextEntry() {
        cardFlightEngine.resetSlotPool()
        // Entrance copy + table recede are sequenced by ContextPhase.onAppear, so the
        // felt carries over from ExperienceLevel and only dissolves once the dealer
        // headline has greeted (earned transition, not an abrupt yank).
    }

    /// Bridging line that opens ContextPhase. Fires on the clean, still-present
    /// felt. No hide timer — ContextPhase holds for the returned copy's type
    /// time, then sequences the recede/assembly and hides the line itself.
    /// Built here, never raw from View.
    @discardableResult
    func showContextHeadline() -> String {
        let copy = onboardingData.appMode == .together
            ? "Where are you two starting from?"
            : "Where are you starting from?"
        showDealerLineManual(copy)
        return copy
    }

    /// Selection-dependent exit line shown at the end of ExperienceLevelPhase,
    /// before the phase advances to Context. Fires on the clean table after the
    /// deck pulse. Director-owned — never raw in the View. No hide timer: the
    /// phase holds for the returned copy's type time, then advance() fades the
    /// line into the cross-fade. Returns the copy so the caller can compute
    /// that hold via AppDealerTyping.typeDuration.
    @discardableResult
    func showExpLevelExitLine(_ intensity: CandleIntensity) -> String {
        let copy: String
        switch intensity {
        case .curious:     copy = "Good place to start."
        case .exploring:   copy = "There's a lot to work with."
        case .experienced: copy = "Let's build on that."
        }
        showDealerLineManual(copy)
        return copy
    }

    /// Fades the felt fully out so the context carousel reads as suspended *away
    /// from* the table. Safe to call from `ContextPhase.onAppear` as well as
    /// `runContextEntry()` — guarantees the fade regardless of how the phase was
    /// entered (real advance vs. direct phase set). The table (and corner deck)
    /// re-emerge at exit when the confirmed card is pocketed (see commitContext).
    func recedeTableForContext() {
        withAnimation(AppAnimation.tableRecede.reduceMotionSafe) { tableFade = 0.0 }
    }


    /// Called by ContextPhase once the cards have begun their exit. Writes the
    /// chosen relationship context + situational register, adds the `.context`
    /// credential to the corner deck, re-emerges the felt, projects a dealer line
    /// that responds to the choice, then advances to CuriosityPhase after a copy beat.
    /// `advance` stays the sole phase gate.
    func concludeContext(relationshipContext: RelationshipContext,
                         situationalRegister: SituationalRegister) {
        onboardingData.relationshipContext = relationshipContext.rawValue
        onboardingData.situationalRegister = situationalRegister.rawValue

        // Felt re-emerges; the responsive line types over it.
        withAnimation(AppAnimation.tableRecede.reduceMotionSafe) { tableFade = 1.0 }
        let reply = contextResponse(for: situationalRegister)
        showDealerLineManual(reply)

        sequenceAttempt += 1
        let current = sequenceAttempt
        Task { @MainActor in
            // Deck credit waits for the felt to be back on stage — the corner
            // deck is tableFade-gated, so an instant pulse fired on a deck that
            // was barely visible. 400ms ≈ mid-recede, deck clearly present.
            try? await Task.sleep(for: .milliseconds(400))
            guard current == self.sequenceAttempt else { return }
            receiveCredential(.context)

            // Hold for the reply to land + a read beat; advance() fades the
            // line into the cross-fade toward Curiosity.
            try? await Task.sleep(for: .milliseconds(
                AppDealerTyping.typeDuration(reply) + 300
            ))
            guard current == self.sequenceAttempt else { return }
            advance(to: .curiosity)
        }
    }

    /// Dealer line that responds to the chosen situational register.
    private func contextResponse(for register: SituationalRegister) -> String {
        switch register {
        case .anxious:  return "We'll take this slow."
        case .excited:  return "Let's keep that momentum."
        case .flexible: return "Good — let's find the shape of it."
        }
    }
    private func runCuriosityEntry() {
        curiositySequenceTask?.cancel()
        curiositySequenceTask = nil

        // Load the two tutorial demo cards. The real round-1 pile is built by
        // beginCuriosityDemo() after the auto-swipe sequence finishes.
        curiosityPile = [
            CuriositySortCard(id: "demo_keep", text: "This card fits you.",       round: 1),
            CuriositySortCard(id: "demo_pass", text: "This card... not so much.", round: 1),
        ]
        curiosityRoundIndex         = 0
        curiosityKeptRound1         = []
        curiosityKeptRound2         = []
        curiosityDragOffset         = .zero
        curiosityFlyingCard         = nil
        curiosityFlyingOffset       = .zero
        curiosityThresholdCrossed   = false
        curiosityDealTrigger        = false
        curiosityRoundTransitioning = false
        curiosityDemoActive         = true
        curiositySummaryVisible     = false
        curiositySummaryOffset      = .zero
        curiositySummaryScale       = 1.0
        curiositySummaryAlpha       = 1.0
        curiositySummaryPresented   = false
        // beginCuriosityDemo() is called from CuriosityPhase.onAppear and drives
        // the full deal + auto-swipe + real-pile sequence from there.
    }

    /// Runs the two-card auto-swipe tutorial, then deals the FULL deck (both
    /// halves) in one cascade. Called from CuriosityPhase.onAppear.
    func beginCuriosityDemo(screenWidth: CGFloat) {
        guard curiosityDemoActive else { return }

        curiositySequenceTask?.cancel()
        curiositySequenceTask = Task { @MainActor in

            // ── Deal demo cards ──────────────────────────────────────────
            try? await Task.sleep(for: .milliseconds(50))
            self.curiosityDealTrigger.toggle()

            // Wait for the staggered deal animation to settle
            try? await Task.sleep(for: .milliseconds(750))

            // ── Explain the mechanic ─────────────────────────────────────
            // The instruction finishes typing + a read beat BEFORE the gesture
            // it explains — the demo's entire job is to be read. (Fixed sleeps
            // used to fire the swipe at ~50% of the sentence.)
            let keepLine = "Swipe right if a card feels true for you."
            self.showDealerLineManual(keepLine)
            try? await Task.sleep(for: .milliseconds(AppDealerTyping.typeDuration(keepLine) + 450))

            await self.demoSwipe(right: true, screenWidth: screenWidth)

            // ── Line swap with a real fade, not an instant text replace ──
            self.hideDealerLine()
            try? await Task.sleep(for: .milliseconds(350))

            let passLine = "Left if it doesn't."
            self.showDealerLineManual(passLine)
            try? await Task.sleep(for: .milliseconds(AppDealerTyping.typeDuration(passLine) + 450))

            await self.demoSwipe(right: false, screenWidth: screenWidth)

            // ── End demo, hand off to user ───────────────────────────────
            self.curiosityDemoActive = false
            self.hideDealerLine()
            try? await Task.sleep(for: .milliseconds(350))

            // ── ONE deal — the full deck, both halves, one tall cascade. ──
            // The first question frames the sort as the waterfall lands.
            self.curiosityFlyingCard = nil
            self.curiosityDragOffset = .zero
            self.curiosityPile       = self.buildCuriosityPile(round: 1)
                                     + self.buildCuriosityPile(round: 2)
            self.curiosityDealTrigger.toggle()
            try? await Task.sleep(for: .milliseconds(400))
            self.showDealerLineManual("What keeps coming up for you?")
        }
    }

    /// One demonstration swipe, wearing the same physical signature it teaches:
    /// the threshold tick as the drag crosses the commit line, the commit thunk
    /// at release, and the standard departure mechanic.
    private func demoSwipe(right: Bool, screenWidth: CGFloat) async {
        let dir: CGFloat = right ? 1 : -1
        withAnimation(.easeIn(duration: 0.22)) {
            curiosityDragOffset = CGSize(width: dir * screenWidth * 0.28, height: 0)
        }
        // Drag covers ~0.28·W over 220ms; it crosses the 95pt threshold late.
        try? await Task.sleep(for: .milliseconds(160))
        curiosityThresholdCrossed = true
        try? await Task.sleep(for: .milliseconds(60))
        curiosityDemoCommitTrigger.toggle()
        advanceCuriosityTopCard(
            flingTo:      CGSize(width: dir * screenWidth * 1.6, height: 0),
            startingFrom: curiosityDragOffset
        )
        curiosityThresholdCrossed = false
        try? await Task.sleep(for: .milliseconds(520))
    }

    // MARK: - Curiosity Phase Methods

    // Non-private so the ConfirmationPhase curiosity editor can read the full tag
    // pool (kept + skipped) without duplicating the source list.
    func buildCuriosityPile(round: Int) -> [CuriositySortCard] {
        if round == 1 {
            return [
                CuriositySortCard(id: "comm_dont_know_what_i_want",  text: "I don't know what I actually want",      round: 1),
                CuriositySortCard(id: "comm_want_different_things",   text: "We want different things",               round: 1),
                CuriositySortCard(id: "comm_wouldnt_know_how_to_ask", text: "I wouldn't know how to ask for it",      round: 1),
                CuriositySortCard(id: "comm_jealousy_gets_stuck",     text: "Jealousy comes up and gets stuck",       round: 1),
                CuriositySortCard(id: "comm_lost_connection",         text: "We've lost some of our connection",      round: 1),
                CuriositySortCard(id: "comm_same_place",              text: "I keep ending up in the same place",     round: 1),
                CuriositySortCard(id: "comm_reactions_surprise_me",   text: "My reactions in intimacy surprise me",   round: 1),
            ]
        } else {
            return [
                CuriositySortCard(id: "learn_what_i_want",           text: "What I want — not what I've settled for",          round: 2),
                CuriositySortCard(id: "learn_why_i_respond",         text: "Why I respond to people the way I do",             round: 2),
                CuriositySortCard(id: "learn_jealousy_telling_me",   text: "What jealousy is actually telling me",             round: 2),
                CuriositySortCard(id: "learn_opening_up",            text: "Whether opening up could work for us",             round: 2),
                CuriositySortCard(id: "learn_ask_what_i_want",       text: "What it means to ask for what I want",             round: 2),
                CuriositySortCard(id: "learn_mapping_what_we_want",  text: "Mapping what we each want",                        round: 2),
                CuriositySortCard(id: "learn_brings_them_joy",       text: "Feeling good about what brings them joy",          round: 2),
                CuriositySortCard(id: "learn_what_our_agreements",   text: "What our agreements should look like",             round: 2),
            ]
        }
    }

    /// Called by the View on every drag change. Updates offset and fires threshold flip for haptics.
    func onCuriosityDrag(offset: CGSize) {
        curiosityDragOffset = offset
        let crossed = abs(offset.width) >= 95
        if crossed != curiosityThresholdCrossed {
            curiosityThresholdCrossed = crossed
        }
    }

    /// Commits a keep/pass: records the selection, hands the top card to the flying
    /// overlay so it departs as its own identity while the next card rises, then checks
    /// for round exhaustion after a short beat so the last card clears the pile first.
    func commitCuriositySwipe(screenSize: CGSize) {
        guard !curiosityPile.isEmpty, !curiosityRoundTransitioning else { return }

        let topCard = curiosityPile[0]
        let isKeep  = curiosityDragOffset.width > 0
        let flingX: CGFloat = isKeep ? screenSize.width * 1.6 : -screenSize.width * 1.6
        let flingY: CGFloat = curiosityDragOffset.height * 0.5

        // Keeps recorded by the CARD's round, not a phase counter — the
        // bookkeeping cannot drift from what's visually on the pile.
        if isKeep {
            if topCard.round == 1 { curiosityKeptRound1.append(topCard.id) }
            else                  { curiosityKeptRound2.append(topCard.id) }
        }

        advanceCuriosityTopCard(
            flingTo:      CGSize(width: flingX, height: flingY),
            startingFrom: curiosityDragOffset
        )
        curiosityThresholdCrossed = false

        // Pile is now post-removal.
        // Mid-deck boundary: last round-1 card committed, round-2 card surfacing —
        // pause the deck and swap the question.
        if topCard.round == 1, curiosityPile.first?.round == 2 {
            onCuriosityRoundBoundary()
            return
        }

        // Full deck done — forge the credential and conclude.
        guard curiosityPile.isEmpty else { return }

        sequenceAttempt += 1
        let current = sequenceAttempt
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(260))
            guard current == self.sequenceAttempt else { return }
            self.onCuriosityDeckExhausted(screenSize: screenSize)
        }
    }

    /// Pops the current top card into the flying overlay and reveals the next card.
    /// Shared by the user commit and the demo auto-swipe so both read identically:
    /// the departing card flies clear on the throw curve while the pile re-settles —
    /// the next card rises from depth 1 → 0. Retires the overlay once it is off-screen.
    private func advanceCuriosityTopCard(flingTo flingOffset: CGSize, startingFrom startOffset: CGSize) {
        guard let top = curiosityPile.first else { return }

        // Insert the overlay at exactly the release position. It must render here for a
        // frame before flinging, so the throw animates *from* the release point — a freshly
        // inserted view has no "from" value otherwise (same reason dealCards resets first).
        curiosityFlyingCard   = top
        curiosityFlyingOffset = startOffset

        // Drop the card from the pile and recenter the live drag. The pile.count change
        // drives the next card's rise, which the View animates with curiosityRise.
        withAnimation(AppAnimation.curiosityRise.reduceMotionSafe) {
            curiosityPile.removeFirst()
            curiosityDragOffset = .zero
        }

        curiosityFlyingClearAttempt += 1
        let current = curiosityFlyingClearAttempt
        Task { @MainActor in
            // Let the overlay commit at the release position, then fling it clear.
            try? await Task.sleep(for: .milliseconds(30))
            guard current == self.curiosityFlyingClearAttempt else { return }
            withAnimation(AppAnimation.curiosityThrow.reduceMotionSafe) {
                self.curiosityFlyingOffset = flingOffset
            }

            // Retire the overlay once the throw completes (curiosityThrow ≈ 360ms).
            try? await Task.sleep(for: .milliseconds(380))
            guard current == self.curiosityFlyingClearAttempt else { return }
            self.curiosityFlyingCard = nil
        }
    }

    /// Snaps the top card back to pile center when released below threshold.
    func snapBackCuriosityCard() {
        withAnimation(AppAnimation.cardSettle) { curiosityDragOffset = .zero }
        curiosityThresholdCrossed = false
    }

    /// Mid-deck pause — same deck, new question. The last round-1 card has
    /// committed and a round-2 card is surfacing: swiping locks
    /// (curiosityRoundTransitioning gates the top card's hit-testing), the held
    /// beat is the punctuation, then the second question types and unlocks.
    private func onCuriosityRoundBoundary() {
        guard !curiosityRoundTransitioning else { return }
        curiosityRoundTransitioning = true
        hideDealerLine()

        curiositySequenceTask?.cancel()
        curiositySequenceTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(600))
            self.curiosityRoundIndex = 1
            let line = "Now — what pulls your curiosity?"
            self.showDealerLineManual(line)
            // Swiping unlocks once the new question has landed + a beat.
            try? await Task.sleep(for: .milliseconds(AppDealerTyping.typeDuration(line) + 250))
            self.curiosityRoundTransitioning = false
        }
    }

    /// Full deck sorted. The kept cards compress into the squared deck, which
    /// the dealer places IN THE USER'S HAND — lift anchor + halo, the taught
    /// "ready to give" state. The user completes the phase by handing it over
    /// (swipe-up → handoffCuriosityDeck). The credential is the only one the
    /// user assembles themselves; it should also be one they choose to give.
    private func onCuriosityDeckExhausted(screenSize: CGSize) {
        onboardingData.communicationGoals  = curiosityKeptRound1
        onboardingData.learningGoals       = curiosityKeptRound2
        onboardingData.curiositySelections = curiosityKeptRound1 + curiosityKeptRound2
        evaluateOpenerDeckType()

        hideDealerLine()

        sequenceAttempt += 1
        let current = sequenceAttempt
        Task { @MainActor in
            // Last fling clears the stage.
            try? await Task.sleep(for: .milliseconds(350))
            guard current == self.sequenceAttempt else { return }

            // Materialise straight into the hand — spring from 0.82 to the
            // standard lift scale at the lift anchor, halo following.
            self.curiositySummaryOffset = CGSize(
                width:  0,
                height: screenSize.height * 0.42 - screenSize.height / 2
            )
            self.curiositySummaryScale   = 0.82
            self.curiositySummaryAlpha   = 0
            self.curiositySummaryVisible = true
            withAnimation(AppAnimation.spring.reduceMotionSafe) {
                self.curiositySummaryScale = 1.12
                self.curiositySummaryAlpha = 1.0
            }
            try? await Task.sleep(for: .milliseconds(600))
            guard current == self.sequenceAttempt else { return }
            self.curiositySummaryPresented = true
        }
    }

    /// The user hands the forged deck to the dealer (swipe-up on the presented
    /// deck). Standard pocket flight with late alpha; deck pulses 6/6 on
    /// landing, the dealer receipts the collection, then the phase advances.
    func handoffCuriosityDeck(screenSize: CGSize) {
        guard curiositySummaryPresented else { return }
        curiositySummaryPresented = false

        sequenceAttempt += 1
        let current = sequenceAttempt
        Task { @MainActor in
            let cardW   = AppLayout.obTableCardWidth(in: screenSize.width)
                        * AppLayout.obTableCardCinematicScale
            let cornerX = screenSize.width  - AppLayout.cornerDeckRight - AppLayout.cornerDeckWidth  / 2
            let cornerY = AppLayout.cornerDeckTop + AppLayout.cornerDeckHeight / 2
            withAnimation(AppAnimation.cardPocket.reduceMotionSafe) {
                self.curiositySummaryOffset = CGSize(width:  cornerX - screenSize.width  / 2,
                                                     height: cornerY - screenSize.height / 2)
                self.curiositySummaryScale  = AppLayout.cornerDeckWidth / cardW
            }
            withAnimation(.easeIn(duration: 0.2).delay(0.32).reduceMotionSafe) {
                self.curiositySummaryAlpha = 0
            }
            try? await Task.sleep(for: .milliseconds(480))
            guard current == self.sequenceAttempt else { return }
            self.receiveCredential(.curiosity)
            self.curiositySummaryVisible = false

            let line = "That's everything I need."
            self.showDealerLineManual(line)
            try? await Task.sleep(for: .milliseconds(AppDealerTyping.typeDuration(line) + 700))
            guard current == self.sequenceAttempt else { return }
            self.advance(to: .confirmation)
        }
    }

    private func runConfirmationEntry() {
        // Confirmation reviews the deck on the table — ensure the felt is present
        // so the credential cards deal onto it. The cards themselves are rendered
        // by ConfirmationPhase (its own VaylCardFace symbol cards).
        withAnimation(AppAnimation.standard.reduceMotionSafe) { tableFade = 1.0 }
    }
    private func runBuildDeckEntry() {
        tableFade = 1.0   // the felt stays as the stage — the forge happens ON it
        foilIntegrity = 1.0
        foilTears = []
        rollStrikeSequence()   // this ceremony's authored composition
    }

    /// Called by BuildDeckPhase as the cased deck leaves the table (ceremony
    /// Beat 3c) — the felt recedes while the case floats, ContextPhase grammar.
    func recedeTableForForge() {
        withAnimation(AppAnimation.tableRecede.reduceMotionSafe) { tableFade = 0.0 }
    }
    private func runFounderLetterEntry() {
        // Terminal phase entry. Commit no longer fires here — completion is an
        // explicit user action via finishOnboarding(), so it reflects intent rather
        // than a side effect of arriving at the phase. FounderLetter visuals are a
        // later design pass; they invoke finishOnboarding() and read commitFailed.
        //
        // Restore the felt INSTANTLY behind the now-opaque letter sheet. The forge
        // receded the table (Beat 3c) and nothing brought it back — so the curtain
        // pull-down had nothing to reveal, and finishOnboarding's cinematicFade
        // animated 0→0 (a no-op; the OB ended on a black frame). With the felt
        // present behind the sheet, the pull-down reveals the warm table and the
        // cinematicFade genuinely dissolves it as routing carries the user home.
        tableFade = 1.0
    }

    /// Called by FounderLetterPhase when the user finishes onboarding.
    /// Commits through the store (gated by isReadyToComplete; surfaces errors). On
    /// success the felt recedes and reactive routing (AppRootView reads AppState)
    /// carries the user out of onboarding. On failure the user stays put — nothing
    /// is lost — and commitFailed is set for the View to surface a retry.
    func finishOnboarding(using store: OnboardingStore) {
        commitFailed = false
        guard store.commit(data: onboardingData) else {
            commitFailed = true
            return
        }
        sequenceAttempt += 1
        let current = sequenceAttempt
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(100)) // post-commit settle
            guard current == self.sequenceAttempt else { return }
            // The set changes behind the descending letter: the warm felt
            // (restored in runFounderLetterEntry) dissolves to void as reactive
            // routing swaps in Home. (No deckPulse here — it was an orphan write
            // that never reset and pulsed a corner deck that isn't on stage.)
            withAnimation(AppAnimation.cinematicFade.reduceMotionSafe) { self.tableFade = 0 }
        }
    }

    func showDealerLine(_ text: String, hideAfter seconds: Double = 4.0,
                        anchorYFrac: CGFloat = AppLayout.tableHorizonYFrac) {
        dealerLineAttempt += 1
        let current = dealerLineAttempt
        projectedText = text
        projectedTextAnchorYFrac = anchorYFrac
        withAnimation(AppAnimation.textProject.reduceMotionSafe) { projectedTextVisible = true }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(seconds))
            guard current == self.dealerLineAttempt else { return }
            withAnimation(AppAnimation.textProject.reduceMotionSafe) { self.projectedTextVisible = false }
        }
    }

    func showDealerLineManual(_ text: String, anchorYFrac: CGFloat = AppLayout.tableHorizonYFrac) {
        projectedText = text
        projectedTextAnchorYFrac = anchorYFrac
        withAnimation(AppAnimation.textProject.reduceMotionSafe) { projectedTextVisible = true }
    }

    func hideDealerLine() {
        withAnimation(AppAnimation.textProject.reduceMotionSafe) { projectedTextVisible = false }
    }

    // MARK: - Card Flight Engine Forwarding

    @MainActor
    func dealSingleCard(screenSize: CGSize, scale: CGFloat) async -> (offset: CGSize, angle: Double, flightID: String)? {
        await cardFlightEngine.dealSingleCard(screenSize: screenSize, scale: scale)
    }

    func claimLandingSlot(screenSize: CGSize) -> CardLandingSlot.Resolved {
        cardFlightEngine.claimLandingSlot(screenSize: screenSize)
    }

    func sailCard(
        cardID:       String,
        image:        UIImage,
        from:         CGPoint,
        to:           CGPoint,
        sceneSize:    CGSize,
        duration:     TimeInterval = 0.92,
        initialAngle: CGFloat      = -0.24,
        finalAngle:   CGFloat      = 0.0314,
        zPosition:    CGFloat      = 0
    ) async -> (CGPoint, CGFloat) {
        await cardFlightEngine.sailCard(
            cardID: cardID, image: image, from: from, to: to,
            sceneSize: sceneSize, duration: duration,
            initialAngle: initialAngle, finalAngle: finalAngle, zPosition: zPosition
        )
    }

    func evaluateOpenerDeckType() {
        // NMStage-keyed opener selection. Mode-independent BY DESIGN — keys on
        // experience + register + curiosity, never appMode.
        let register = SituationalRegister(rawValue: onboardingData.situationalRegister ?? "") ?? .flexible
        let stage    = onboardingData.nmStage
        let richCuriosity = onboardingData.curiositySelections.count >= 4

        switch (stage, register) {
        case (.experienced, .anxious):
            openerDeckType = .reflectiveCalm
        case (.experienced, _):
            openerDeckType = .reflectiveOpen
        case (_, .anxious) where !richCuriosity:
            openerDeckType = .anxious
        default:
            openerDeckType = .excited
        }
        onboardingData.openerDeckType = openerDeckType
    }


    /// Authored strike SEQUENCES — Opal grammar: the tap is a TRIGGER, not an
    /// author. Each ceremony plays one of three vetted compositions (picked at
    /// phase entry, optionally mirrored — six visual outcomes), each placing
    /// one strike per horizontal third of the face with min pairwise spread
    /// ≥ 0.47 width-units and the centroid near face center. The KILL (strike
    /// 3, the bloom origin) lands somewhere different in every sequence —
    /// that's where the uniqueness reads.
    /// Each strike carries an authored ORIENTATION too (degrees; 0 = horizontal,
    /// 90 = vertical): the crack's main fracture runs along it, and within a
    /// sequence the three orientations are ≥ 40° apart — never two horizontals
    /// in one ceremony. Mirroring flips angles with the zones (180 − θ).
    private static let strikeSequences: [[(zone: CGPoint, angleDeg: Double)]] = [
        // The Descent — diagonal march downward; the case dies at its base
        [(CGPoint(x: 0.28, y: 0.233),  10),
         (CGPoint(x: 0.74, y: 0.480), 125),
         (CGPoint(x: 0.45, y: 0.747),  85)],
        // The Pincer — opposite corners first (≈ the full face diagonal),
        // the kill lands in the heart
        [(CGPoint(x: 0.72, y: 0.200), 150),
         (CGPoint(x: 0.27, y: 0.773),  15),
         (CGPoint(x: 0.50, y: 0.480),  90)],
        // The Crown — starts low and rises; the final blow strikes the crown
        [(CGPoint(x: 0.70, y: 0.787), 175),
         (CGPoint(x: 0.26, y: 0.467),  80),
         (CGPoint(x: 0.52, y: 0.200),  35)],
    ]
    private var strikeSequenceIndex: Int  = 0
    private var strikeMirrored:      Bool = false

    /// Roll this ceremony's composition — called on buildDeck entry.
    private func rollStrikeSequence() {
        strikeSequenceIndex = Int.random(in: 0..<Self.strikeSequences.count)
        strikeMirrored      = Bool.random()
    }

    /// Crack ceremony (Beat 5) — the view forwards each tap on the sealed case
    /// as a face-local UV point. Three tears collapse the foil integrity.
    func addFoilTear(atFaceUV uv: CGPoint) {
        guard foilIntegrity > 0.5, foilTears.count < 3 else { return }
        // the composed zone does the placement; the tap only STEERS within a
        // tight radius — strikes can never stack and the composition can't break
        let spec = Self.strikeSequences[strikeSequenceIndex][foilTears.count]
        var zone = spec.zone
        var angle = spec.angleDeg
        if strikeMirrored {
            zone.x = 1 - zone.x
            angle = 180 - angle
        }
        let pulled = CGPoint(x: uv.x + (zone.x - uv.x) * 0.75,
                             y: uv.y + (zone.y - uv.y) * 0.75)
        let dx = pulled.x - zone.x, dy = pulled.y - zone.y
        let offset = (dx * dx + dy * dy).squareRoot()
        let maxOffset: CGFloat = 0.10
        let strike = offset <= maxOffset ? pulled
            : CGPoint(x: zone.x + dx / offset * maxOffset,
                      y: zone.y + dy / offset * maxOffset)
        foilTears.append(FoilTear(faceUV: strike, angleDeg: angle))
        if foilTears.count >= 3 { beginFoilDissolve() }
    }

    private func beginFoilDissolve() {
        // Integrity is the state of record; the bloom-flood + shatter visuals
        // are Date-driven in the case view. No auto-advance — what happens
        // after the shatter belongs to the reveal / letter peek, and
        // `advance()` fires only on user action (ceremony spec, segment 6).
        withAnimation(AppAnimation.foilDissolve.reduceMotionSafe) { self.foilIntegrity = 0 }
    }

}
