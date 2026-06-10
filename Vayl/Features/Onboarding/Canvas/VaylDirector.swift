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
            try? await Task.sleep(for: .milliseconds(900))
            withAnimation(.easeIn(duration: 1.6)) { tableFade = 1.0 }
        }
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
    /// felt and auto-fades at 2.8s — copy and carousel arrival overlap by design.
    /// Built here, never raw from View.
    func showContextHeadline() {
        let copy = onboardingData.appMode == .together
            ? "Where are you two starting from?"
            : "Where are you starting from?"
        showDealerLine(copy, hideAfter: 2.8)
    }

    /// Selection-dependent exit line shown at the end of ExperienceLevelPhase,
    /// before the phase advances to Context. Fires on the clean table after the
    /// deck pulse. Director-owned — never raw in the View.
    func showExpLevelExitLine(_ intensity: CandleIntensity) {
        let copy: String
        switch intensity {
        case .curious:     copy = "Good place to start."
        case .exploring:   copy = "There's a lot to work with."
        case .experienced: copy = "Let's build on that."
        }
        showDealerLine(copy, hideAfter: 2.4)
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

        // Felt re-emerges and the corner deck receives the card.
        withAnimation(AppAnimation.tableRecede.reduceMotionSafe) { tableFade = 1.0 }
        receiveCredential(.context)
        showDealerLine(contextResponse(for: situationalRegister))

        sequenceAttempt += 1
        let current = sequenceAttempt
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(2600)) // deck pulse (600) + let the responsive line land (2000)
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
        // beginCuriosityDemo() is called from CuriosityPhase.onAppear and drives
        // the full deal + auto-swipe + real-pile sequence from there.
    }

    /// Runs the two-card auto-swipe tutorial, then deals the real Round 1 pile.
    /// Called from CuriosityPhase.onAppear — the view triggers it once the phase is visible.
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
            self.showDealerLine("Swipe right if a card feels true for you.", hideAfter: 4.0)
            try? await Task.sleep(for: .milliseconds(1300))

            // ── Auto-swipe right (demo card 1: "This card fits you.") ────
            withAnimation(.easeIn(duration: 0.22)) {
                self.curiosityDragOffset = CGSize(width: screenWidth * 0.28, height: 0)
            }
            try? await Task.sleep(for: .milliseconds(220))
            // Hand off to the same departure mechanic the user gets:
            // the card flies clear while the next card rises into its place.
            self.advanceCuriosityTopCard(
                flingTo:      CGSize(width: screenWidth * 1.6, height: 0),
                startingFrom: self.curiosityDragOffset
            )
            try? await Task.sleep(for: .milliseconds(520))

            // ── Brief pause before second demo card ──────────────────────
            try? await Task.sleep(for: .milliseconds(350))

            // ── Explain left swipe ───────────────────────────────────────
            self.showDealerLine("Left if it doesn't.", hideAfter: 4.0)
            try? await Task.sleep(for: .milliseconds(1100))

            // ── Auto-swipe left (demo card 2: "This card... not so much.") ──
            withAnimation(.easeIn(duration: 0.22)) {
                self.curiosityDragOffset = CGSize(width: -(screenWidth * 0.28), height: 0)
            }
            try? await Task.sleep(for: .milliseconds(220))
            self.advanceCuriosityTopCard(
                flingTo:      CGSize(width: -(screenWidth * 1.6), height: 0),
                startingFrom: self.curiosityDragOffset
            )
            try? await Task.sleep(for: .milliseconds(520))

            // ── End demo, hand off to user ───────────────────────────────
            self.curiosityDemoActive = false
            try? await Task.sleep(for: .milliseconds(350))

            // Intro line fires when the real pile arrives so it frames the sort
            self.showDealerLine("What keeps coming up for you? Sweep through — keep what pulls at you.", hideAfter: 5.0)
            try? await Task.sleep(for: .milliseconds(600))

            // ── Deal real Round 1 pile ────────────────────────────────────
            self.curiosityFlyingCard   = nil
            self.curiosityDragOffset    = .zero
            self.curiosityPile          = self.buildCuriosityPile(round: 1)
            self.curiosityDealTrigger.toggle()
        }
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

        let isKeep = curiosityDragOffset.width > 0
        let keptID = curiosityPile[0].id
        let flingX: CGFloat = isKeep ? screenSize.width * 1.6 : -screenSize.width * 1.6
        let flingY: CGFloat = curiosityDragOffset.height * 0.5

        if isKeep {
            if curiosityRoundIndex == 0 { curiosityKeptRound1.append(keptID) }
            else                        { curiosityKeptRound2.append(keptID) }
        }

        advanceCuriosityTopCard(
            flingTo:      CGSize(width: flingX, height: flingY),
            startingFrom: curiosityDragOffset
        )
        curiosityThresholdCrossed = false

        // Pile is now post-removal. If that emptied the round, advance after a beat.
        guard curiosityPile.isEmpty else { return }

        sequenceAttempt += 1
        let current = sequenceAttempt
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(260))
            guard current == self.sequenceAttempt else { return }
            if self.curiosityRoundIndex == 0 {
                self.onCuriosityRound1Exhausted()
            } else {
                self.onCuriosityRound2Exhausted()
            }
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

    private func onCuriosityRound1Exhausted() {
        guard !curiosityRoundTransitioning else { return }
        curiosityRoundTransitioning = true

        curiositySequenceTask?.cancel()
        curiositySequenceTask = Task { @MainActor in
            self.showDealerLine("Good.", hideAfter: 2.0)
            try? await Task.sleep(for: .milliseconds(1100))

            self.showDealerLine("Now — what pulls your curiosity?", hideAfter: 2.5)
            try? await Task.sleep(for: .milliseconds(300))

            self.curiosityRoundIndex = 1
            self.curiosityFlyingCard = nil
            self.curiosityDragOffset = .zero
            self.curiosityPile       = self.buildCuriosityPile(round: 2)
            self.curiosityDealTrigger.toggle()
            self.curiosityRoundTransitioning = false
        }
    }

    private func onCuriosityRound2Exhausted() {
        onboardingData.communicationGoals  = curiosityKeptRound1
        onboardingData.learningGoals       = curiosityKeptRound2
        onboardingData.curiositySelections = curiosityKeptRound1 + curiosityKeptRound2
        evaluateOpenerDeckType()

        receiveCredential(.curiosity)

        showDealerLine("Good pile.", hideAfter: 3.0)

        sequenceAttempt += 1
        let current = sequenceAttempt
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1500)) // deck pulse (600) + settle (900)
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
            withAnimation(AppAnimation.cinematicFade.reduceMotionSafe) { self.tableFade = 0 }
            withAnimation(AppAnimation.spring.reduceMotionSafe) { self.deckPulse = true }
        }
    }

    func showDealerLine(_ text: String, hideAfter seconds: Double = 4.0) {
        dealerLineAttempt += 1
        let current = dealerLineAttempt
        projectedText = text
        withAnimation(AppAnimation.textProject.reduceMotionSafe) { projectedTextVisible = true }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(seconds))
            guard current == self.dealerLineAttempt else { return }
            withAnimation(AppAnimation.textProject.reduceMotionSafe) { self.projectedTextVisible = false }
        }
    }

    func showDealerLineManual(_ text: String) {
        projectedText = text
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


    func addFoilTear(at point: CGPoint) {
        let tear = FoilTear(tapPoint: point)
        foilTears.append(tear)
        if foilTears.count >= 3 { beginFoilDissolve() }
    }

    private func beginFoilDissolve() {
        sequenceAttempt += 1
        let current = sequenceAttempt
        withAnimation(AppAnimation.foilDissolve.reduceMotionSafe) { self.foilIntegrity = 0 }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(800)) // foil dissolve delay
            guard current == self.sequenceAttempt else { return }
            try? await Task.sleep(for: .seconds(1))
            guard current == self.sequenceAttempt else { return }
            self.advance(to: .founderLetter)
        }
    }

}
