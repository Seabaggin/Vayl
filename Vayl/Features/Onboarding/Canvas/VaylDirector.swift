// Features/Onboarding/Canvas/VaylDirector.swift

import SwiftUI
import SpriteKit

@Observable
@MainActor
final class VaylDirector {

    var phase: OBPhase = .stat

    var tableCards:      [VaylCardModel] = []
    var cornerDeckCards: [VaylCardModel] = []
    var inFlightCards:   [VaylCardModel] = []
    var muckCards:       [VaylCardModel] = []

    /// Pre-placed gender card. Stored outside tableCards so VaylCardRenderer
    /// never renders it. Lives here from NamePhase greeting → GenderPhase open.
    /// GenderPhase reads this, takes local ownership, and nils it on consume.
    var pendingGenderCard: VaylCardModel? = nil

    var onboardingData: OnboardingData = OnboardingData()
    var openerDeckType: OpenerDeckType = .anxious

    var tableFade:          Double = 0.0
    var dealPointIntensity: Double = 0.0

    // Lazy — deferred until first access so previews and unit tests that
    // create VaylDirector() don't spin up a SpriteKit scene unnecessarily.
    // @ObservationIgnored is safe because the scene object never changes;
    // only its contents mutate (handled internally by CardFlightScene itself).
    @ObservationIgnored lazy var cardFlightScene: CardFlightScene = CardFlightScene()

    var projectedText:        String? = nil
    var projectedTextVisible: Bool    = false

    // MARK: - Gender Phase

    var genderCardOffset:         CGSize = .zero
    var genderCardFlipScaleX:     Double = 1.0
    var genderCardFaceUp:         Bool   = false
    var genderCardVisible:        Bool   = false
    var genderCardSettled:        Bool   = false

    /// Primary driver for the dissolution / recrystallisation sequence.
    /// 0 = card is indistinguishable from felt. 1 = card is fully crystallised.
    /// All visual curves are computed from this single value — only one @Observable
    /// write per frame, keeping SwiftUI invalidation to a minimum.
    var dissolutionT:             Double = 0

    var genderDealerLineVisible:  Bool   = false
    var genderBeatComplete:       Bool   = false
    /// Dealer line copy shown above the card. Set before the phase opens.
    var genderDealerLine:         String = "Let's find your place at the table."

    // Swipe-hint loop flag — true after both drums settle and fireBothSettled() fires;
    // false the moment the user grabs the card or confirms. Drives the looping
    // "swipe me right" affordance in GenderPhase (rightward drift + clockwise tip).
    var genderSwipeHintActive:    Bool       = false

    // Segment 7 — picker + reel sync
    var genderPickerVisible:  Bool     = false
    // Populated here so VaylDirector is always safe to use from previews or tests
    // that don't route through advance(to: .gender) / runGenderEntry().
    // runGenderEntry() resets this to the same values — idempotent, intentional.
    var genderOptions:        [String] = [
        "Man", "Woman", "Trans Man", "Trans Woman", "Non-binary",
    ]
    var genderDrumOffset:     CGFloat  = 0
    var genderSelectedIndex:  Int      = 0
    var genderDrumSettled:    Bool     = false

    // Radio tuner signal state
    var genderSignalStrength:        Double   = 0
    // Pronouns drum (mirrors gender drum)
    var genderPronounsOptions:       [String] = ["she/her", "he/him", "they/them", "ze/zir", "any pronouns", "prefer not to say"]
    var genderPronounsDrumOffset:    CGFloat  = 0
    var genderPronounsSelectedIndex: Int      = 0
    var genderPronounsDrumSettled:   Bool     = false

    var genderBothSettled: Bool { genderDrumSettled && genderPronounsDrumSettled }

    // Segment 8 — confirm logic (single spin, all modes)
    var genderShouldPocket:      Bool   = false  // GenderPhase observes; advances on true

    // MARK: — Dissolution computed curves
    //
    // All eight curves derive from dissolutionT (0→1).
    // Views read these; they are never stored individually.
    // Easing: eIO3 = ease-in-out cubic, eO5 = ease-out quint, eO7 = ease-out sept.

    /// 0→1 — ambient density stir before anything visible.
    var dissolutionPre:      Double { CanvasEasing.eIO3(CanvasEasing.nm(dissolutionT, 0,    0.12)) }

    /// 0→0.52 — topo lines pulled inward toward card footprint.
    var dissolutionWarp:     Double { CanvasEasing.eIO3(CanvasEasing.nm(dissolutionT, 0.08, 0.20)) * 0.52 }

    /// 0→1 — card body density (felt-matched mass emerging).
    var dissolutionDensity:  Double { CanvasEasing.eO5(CanvasEasing.nm(dissolutionT, 0.18, 0.36)) }

    /// 0→1 — card material sharpness (blur + colour shift felt → void).
    var dissolutionSharp:    Double { CanvasEasing.eO7(CanvasEasing.nm(dissolutionT, 0.42, 0.32)) }

    /// 0°→8° — hex grid angle drift (phase-matched → native card moiré).
    var dissolutionHexAngle: Double { CanvasEasing.eIO3(CanvasEasing.nm(dissolutionT, 0.24, 0.42)) * 8.0 }

    /// 2.2→1.0 — hex cell spacing multiplier (topo frequency → card size).
    var dissolutionHexSpacing: Double { 2.2 + (1.0 - 2.2) * CanvasEasing.eIO3(CanvasEasing.nm(dissolutionT, 0.24, 0.44)) }

    /// 0→1 — topo lines relax outward, flowing around card boundary.
    var dissolutionFlowOut:  Double { CanvasEasing.eIO3(CanvasEasing.nm(dissolutionT, 0.50, 0.30)) }

    /// 0→1 — wordmark crystallises last.
    var dissolutionMark:     Double { CanvasEasing.eO7(CanvasEasing.nm(dissolutionT, 0.62, 0.26)) }

    /// Task handle for the gender visual sequence. Not observed — internal bookkeeping only.
    @ObservationIgnored var genderSequenceTask: Task<Void, Never>? = nil

    // MARK: - Curiosity Phase

    /// Remaining unseen cards in the current round. Index 0 = top of pile (interactive).
    var curiosityPile:               [CuriositySortCard] = []
    /// 0 = Round 1 (communicationGoals), 1 = Round 2 (learningGoals).
    var curiosityRoundIndex:         Int               = 0
    var curiosityKeptRound1:         [String]          = []
    var curiosityKeptRound2:         [String]          = []
    /// Live drag offset of the top card. View reads this; director writes it.
    var curiosityDragOffset:         CGSize            = .zero
    /// Flips whenever the drag crosses the 95pt commit threshold. Triggers .selection haptic in View.
    var curiosityThresholdCrossed:   Bool              = false
    /// Toggled to trigger the deal animation in CuriosityPhase. View observes via onChange.
    var curiosityDealTrigger:        Bool              = false
    /// Prevents double-fire during the 1100ms round-gap beat.
    var curiosityRoundTransitioning: Bool              = false
    /// True while the 2-card auto-swipe tutorial is running. View disables user gesture when set.
    var curiosityDemoActive:         Bool              = false

    @ObservationIgnored var curiositySequenceTask: Task<Void, Never>? = nil

    var foilIntegrity: Double     = 1.0
    var foilTears:     [FoilTear] = []

    var deckPulse: Bool = false

    private var sequenceAttempt:   Int = 0
    private var dealerLineAttempt: Int = 0

    @ObservationIgnored lazy var cardFlightEngine: CardFlightEngine = CardFlightEngine(director: self)

    // ARCH: Injected via direct assignment from OnboardingCanvasView.onAppear.
    // commit() is a no-op until assigned — Director must be initialized before founderLetter fires.
    var onboardingStore: OnboardingStore? = nil

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
        case .gender:          runGenderEntry()
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
            withAnimation(.easeOut(duration: 0.32)) {
                self.curiosityDragOffset = CGSize(width: screenWidth * 1.6, height: 0)
            }
            try? await Task.sleep(for: .milliseconds(380))
            if !self.curiosityPile.isEmpty { self.curiosityPile.removeFirst() }
            self.curiosityDragOffset = .zero

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
            withAnimation(.easeOut(duration: 0.32)) {
                self.curiosityDragOffset = CGSize(width: -(screenWidth * 1.6), height: 0)
            }
            try? await Task.sleep(for: .milliseconds(380))
            if !self.curiosityPile.isEmpty { self.curiosityPile.removeFirst() }
            self.curiosityDragOffset = .zero

            // ── End demo, hand off to user ───────────────────────────────
            self.curiosityDemoActive = false
            try? await Task.sleep(for: .milliseconds(350))

            // Intro line fires when the real pile arrives so it frames the sort
            self.showDealerLine("What keeps coming up for you? Sweep through — keep what pulls at you.", hideAfter: 5.0)
            try? await Task.sleep(for: .milliseconds(600))

            // ── Deal real Round 1 pile ────────────────────────────────────
            self.curiosityPile = self.buildCuriosityPile(round: 1)
            self.curiosityDealTrigger.toggle()
        }
    }

    // MARK: - Curiosity Phase Methods

    private func buildCuriosityPile(round: Int) -> [CuriositySortCard] {
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

    /// Flings the top card off-screen, then after 300 ms pops it and checks for round exhaustion.
    func commitCuriositySwipe(screenSize: CGSize) {
        guard !curiosityPile.isEmpty, !curiosityRoundTransitioning else { return }

        let isKeep = curiosityDragOffset.width > 0
        let keptID = curiosityPile[0].id
        let flingX: CGFloat = isKeep ? screenSize.width * 1.6 : -screenSize.width * 1.6
        let flingY: CGFloat = curiosityDragOffset.height * 0.5

        withAnimation(.easeOut(duration: 0.36)) {
            curiosityDragOffset = CGSize(width: flingX, height: flingY)
        }

        sequenceAttempt += 1
        let current = sequenceAttempt
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            guard current == self.sequenceAttempt else { return }

            if isKeep {
                if self.curiosityRoundIndex == 0 {
                    self.curiosityKeptRound1.append(keptID)
                } else {
                    self.curiosityKeptRound2.append(keptID)
                }
            }

            if !self.curiosityPile.isEmpty { self.curiosityPile.removeFirst() }
            self.curiosityDragOffset      = .zero
            self.curiosityThresholdCrossed = false

            if self.curiosityPile.isEmpty {
                if self.curiosityRoundIndex == 0 {
                    self.onCuriosityRound1Exhausted()
                } else {
                    self.onCuriosityRound2Exhausted()
                }
            }
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

    private func runConfirmationEntry() {}
    private func runBuildDeckEntry() { foilIntegrity = 1.0; foilTears = [] }
    private func runFounderLetterEntry() {
        sequenceAttempt += 1
        let current = sequenceAttempt
        Task { @MainActor in
            onboardingStore?.commit(data: onboardingData)
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

    @MainActor
    func placeGenderCardSilently(screenSize: CGSize) {
        let card        = VaylCardModel()
        card.credential = .gender
        let tableY = screenSize.height * 0.58  // sits in upper felt, below the arc
        card.position = CGPoint(x: screenSize.width / 2, y: tableY)
        card.rotation   = 0
        card.opacity    = 1.0
        card.elevation  = 0.0
        card.isFaceUp   = false
        // Store in pendingGenderCard — NOT tableCards.
        // VaylCardRenderer only renders tableCards.
        // The card is invisible during NamePhase because it is never in tableCards.
        // GenderPhase reads pendingGenderCard on open and takes local ownership.
        pendingGenderCard = card
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

    // MARK: - Gender Phase Entry & Sequence
    //
    // Boundary contract (locked):
    //   runGenderEntry()      = sync, router-owned, no View lifecycle coupling
    //   startGenderSequence() = async, View-lifecycle-owned, never called by router

    /// Sync reset only — no animation, no async.
    /// Resets all gender visual state so the View starts clean on every entry.
    func runGenderEntry() {
        genderSequenceTask?.cancel()
        genderSequenceTask = nil

        genderCardOffset         = .zero
        genderCardFlipScaleX     = 1.0
        genderCardFaceUp         = false
        genderCardVisible        = false
        genderCardSettled        = false
        dissolutionT             = 0
        genderDealerLineVisible  = false
        genderBeatComplete       = false
        genderDealerLine         = "Let's find your place at the table."
        genderSignalStrength     = 0
        genderSwipeHintActive    = false
        genderPickerVisible      = false
        genderOptions            = [
            "Man", "Woman", "Trans Man", "Trans Woman", "Non-binary",
        ]
        genderDrumOffset         = 0
        genderSelectedIndex      = 0
        genderDrumSettled        = false
        genderPronounsDrumOffset    = 0
        genderPronounsSelectedIndex = 0
        genderPronounsDrumSettled   = false
        genderShouldPocket       = false
    }

    /// Called by GenderPhase.onAppear. Safe to call multiple times.
    func startGenderSequence(screenSize: CGSize, reduceMotion: Bool) {
        genderSequenceTask?.cancel()
        genderSequenceTask = Task { await runGenderRise(screenSize: screenSize, reduceMotion: reduceMotion) }
    }

    /// Called by GenderPhase.onDisappear.
    func cancelGenderSequence() {
        genderSequenceTask?.cancel()
        genderSequenceTask = nil
    }

    /// Full autonomous sequence: crystallise → dealer line → flip → handle pull.
    ///
    /// dissolutionT (0→1) drives the Segment 1 visual curves as computed properties.
    /// All subsequent beats are direct state writes on the @MainActor.
    @MainActor
    private func runGenderRise(screenSize: CGSize, reduceMotion: Bool) async {
        guard !genderOptions.isEmpty else { return } // safety: should never be empty after init fix

        // Rest position: horizontally centred, obGenderCardRestYFrac down screen.
        // Derived from layout token — never use UIScreen.main (iOS 26: banned).
        let restY = screenSize.height * AppLayout.obGenderCardRestYFrac - screenSize.height / 2

        // ── Reduce Motion: instant all state ──────────────────────────────────
        if reduceMotion {
            genderCardOffset         = CGSize(width: 0, height: restY)
            genderCardVisible        = true
            dissolutionT             = 1
            genderCardSettled        = true
            genderDealerLineVisible  = false
            genderCardFaceUp         = true
            genderCardFlipScaleX     = 1.0
            genderBeatComplete       = true
            genderSignalStrength     = 0
            genderSwipeHintActive    = false
            genderPickerVisible      = true
            genderDrumOffset         = 0
            genderSelectedIndex      = 0
            genderDrumSettled        = false
            genderPronounsDrumOffset    = 0
            genderPronounsSelectedIndex = 0
            genderPronounsDrumSettled   = false
            genderShouldPocket       = false
            return
        }

        // ── SEGMENT 1 — Card crystallises out of the felt ─────────────────────
        //
        // dissolutionT drives eight computed visual curves (see dissolution section above).
        // One @Observable write per ~14ms tick minimises SwiftUI invalidation.
        //
        // Phase timeline (fractions of 7s total):
        //   0.00–0.12  pre: ambient density stir
        //   0.08–0.28  warp: topo lines pull inward
        //   0.18–0.54  density: body emerges as felt-matched mass
        //   0.24–0.66  hex drift: angle 0°→8°, spacing 2.2→1.0
        //   0.42–0.74  sharp: blur 28→0, colour felt→void
        //   0.50–0.80  flowOut: topo lines flow around card boundary
        //   0.62–0.88  mark: wordmark crystallises

        genderCardOffset  = CGSize(width: 0, height: restY)
        genderCardVisible = true
        dissolutionT      = 0

        // One frame before the drive loop so SwiftUI registers initial state.
        try? await Task.sleep(for: .milliseconds(16))
        guard !Task.isCancelled else { return }

        let dur   = 7.0
        let start = Date()

        while !Task.isCancelled {
            let elapsed = -start.timeIntervalSinceNow
            let t = min(elapsed / dur, 1.0)
            dissolutionT = t
            if t >= 1.0 { break }
            try? await Task.sleep(for: .milliseconds(14))
        }

        guard !Task.isCancelled else { return }
        dissolutionT      = 1
        genderCardSettled = true

        // ── SEGMENT 2 — Dealer line → flip → hold ─────────────────────────────

        // Beat A: dealer line fades in (200ms after settled)
        try? await Task.sleep(for: .milliseconds(200))
        guard !Task.isCancelled else { return }
        withAnimation(AppAnimation.textProject.reduceMotionSafe) {
            genderDealerLineVisible = true
        }

        // Beat B onwards: 300ms after dealer line, then flip + handle pull + reel + picker.
        // Shared with partner spin — extracted into runGenderFlipAndSpin().
        try? await Task.sleep(for: .milliseconds(300))
        guard !Task.isCancelled else { return }
        await runGenderFlipAndSpin()
    }

    /// Beat B through Segment 7 — flip card face-up, power-on beat, show picker.
    ///
    /// Called immediately after the dealer line has been shown and a 300ms beat has passed.
    ///
    /// Preconditions on entry:
    ///   genderCardFaceUp         = false   (flip will reveal face)
    ///   genderDealerLineVisible  = true    (caller showed it)
    private func runGenderFlipAndSpin() async {

        // ── Flip half 1 — collapse scaleX to 0 ───────────────────────────────
        withAnimation(AppAnimation.cardFlipHalf.reduceMotionSafe) {
            genderCardFlipScaleX = 0.0
        }
        try? await Task.sleep(for: .milliseconds(300))
        guard !Task.isCancelled else { return }

        // Face swap at scaleX = 0 — card is invisible, no visual pop
        genderCardFaceUp = true

        // Flip half 2 — expand scaleX back to 1
        withAnimation(AppAnimation.cardFlipHalf.reduceMotionSafe) {
            genderCardFlipScaleX = 1.0
        }
        try? await Task.sleep(for: .milliseconds(300))
        guard !Task.isCancelled else { return }

        // Beat: hold so the radio face registers before dealer line fades
        try? await Task.sleep(for: .milliseconds(300))
        guard !Task.isCancelled else { return }
        genderBeatComplete = true

        // ── Power-on beat — brief pause before picker appears ─────────────────
        // Radio face is visible at signalStrength=0 (searching look).
        // Dealer line fades out, picker fades in after a short beat.
        try? await Task.sleep(for: .milliseconds(400))
        guard !Task.isCancelled else { return }

        withAnimation(AppAnimation.textProject.reduceMotionSafe) {
            genderDealerLineVisible = false
        }
        try? await Task.sleep(for: .milliseconds(180))
        guard !Task.isCancelled else { return }

        withAnimation(AppAnimation.standard.reduceMotionSafe) {
            genderPickerVisible = true
        }
    }

    // MARK: - Gender Drum Interaction
    //
    // The only paths through which GenderPhase may write back to director state.
    // All drum-sync math lives here — zero logic in View.

    /// Called every frame while the gender drum is dragged.
    func updateGenderDrum(offset: CGFloat) {
        genderDrumOffset  = offset
        genderDrumSettled = false
        genderSwipeHintActive = false
        if genderSignalStrength > 0 {
            withAnimation(AppAnimation.standard) { genderSignalStrength = 0 }
            withAnimation(AppAnimation.textProject.reduceMotionSafe) { genderDealerLineVisible = false }
        }
    }

    /// Called every frame while the pronouns drum is dragged.
    func updateGenderPronounsDrum(offset: CGFloat) {
        genderPronounsDrumOffset  = offset
        genderPronounsDrumSettled = false
        genderSwipeHintActive     = false
        if genderSignalStrength > 0 {
            withAnimation(AppAnimation.standard) { genderSignalStrength = 0 }
            withAnimation(AppAnimation.textProject.reduceMotionSafe) { genderDealerLineVisible = false }
        }
    }

    /// Called when the drum snaps to a gender option.
    func settleGenderDrum(index: Int) {
        genderSelectedIndex = index
        genderDrumSettled   = true
        if genderBothSettled { fireBothSettled() }
    }

    /// Called when the pronouns drum snaps to a selection.
    func settleGenderPronounsDrum(index: Int) {
        genderPronounsSelectedIndex = index
        genderPronounsDrumSettled   = true
        if genderBothSettled { fireBothSettled() }
    }

    /// Fires once both drums have settled. Shows signal lock and the dealer confirmation line.
    private func fireBothSettled() {
        withAnimation(AppAnimation.standard) {
            genderSignalStrength = 1.0
        }
        withAnimation(AppAnimation.textProject.reduceMotionSafe) {
            genderDealerLine        = "Found it."
            genderDealerLineVisible = true
        }
        beginGenderSwipeHint()
    }

    // MARK: - Gender Swipe Hint

    /// Starts the looping "swipe me right" affordance. Called by GenderPhase after the
    /// reels settle and the winning-glow haptics finish. The caller guards on the
    /// reduce-motion environment value before calling — no looping hint under reduce motion.
    func beginGenderSwipeHint() { genderSwipeHintActive = true }

    /// Stops the swipe-hint loop — called the instant the user grabs the card to swipe.
    func endGenderSwipeHint() { genderSwipeHintActive = false }

    /// Called when the user swipes to confirm their gender selection.
    ///
    /// Persists self gender/pronouns to onboardingData (genderA/pronounsA).
    /// Partner gender arrives via pairing — never set here.
    ///
    /// Pockets the card and sets genderShouldPocket so GenderPhase's onChange
    /// observer waits for the cardPocket animation then advances to .experienceLevel.
    func confirmGenderSelection(pronouns: String?) {
        genderSwipeHintActive = false
        onboardingData.genderA   = genderOptions[genderSelectedIndex]
        onboardingData.pronounsA = pronouns ?? (
            genderPronounsOptions.indices.contains(genderPronounsSelectedIndex)
                ? genderPronounsOptions[genderPronounsSelectedIndex]
                : nil
        )
        withAnimation(AppAnimation.fast.reduceMotionSafe)       { genderPickerVisible = false }
        withAnimation(AppAnimation.cardPocket.reduceMotionSafe) { genderCardVisible   = false }
        dissolutionT       = 0
        genderShouldPocket = true
    }

}
