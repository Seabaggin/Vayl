// Features/Onboarding/Canvas/VaylDirector.swift

import SwiftUI
import SpriteKit

@Observable
@MainActor
final class VaylDirector: OnboardingStage {

    var phase: OBPhase = .stat

    var tableCards: [VaylCardModel] = []
    var cornerDeckCards: [VaylCardModel] = []
    var inFlightCards: [VaylCardModel] = []
    var muckCards: [VaylCardModel] = []

    var onboardingData: OnboardingData = OnboardingData()
    var openerDeckType: OpenerDeckType = .anxious

    /// Which credential the ConfirmationPhase is currently editing. Drives the
    /// edit half-sheet hosted at OnboardingCanvasWrapper (outside the canvas,
    /// which forbids .sheet). nil = no sheet open.
    var editingCredential: OBCredential?

    /// Drives the single-user couples-first greeting sheet, hosted OUTSIDE the canvas (the
    /// canvas forbids .sheet — same pattern as editingCredential). Set when the user confirms
    /// "I'm single" in ContextPhase; the greeting's Continue commits the pending conclusion.
    var showSingleGreeting: Bool = false
    @ObservationIgnored private var pendingSingleConclusion: (RelationshipContext, SituationalRegister)?

    var tableFade: Double = 0.0
    var dealPointIntensity: Double = 0.0

    // Lazy — deferred until first access so previews and unit tests that
    // create VaylDirector() don't spin up a SpriteKit scene unnecessarily.
    // @ObservationIgnored is safe because the scene object never changes;
    // only its contents mutate (handled internally by CardFlightScene itself).
    @ObservationIgnored lazy var cardFlightScene: CardFlightScene = CardFlightScene()

    // MARK: - Gender Phase  (extracted → GenderSequencer)
    //
    // All gender state + the autonomous sequence now live in GenderSequencer. The director
    // holds it (same @ObservationIgnored lazy pattern as cardFlightEngine) and conforms to
    // OnboardingStage so the sequencer can record its result into onboardingData.
    @ObservationIgnored lazy var gender = GenderSequencer(stage: self)

    @ObservationIgnored lazy var projector = DealerProjector()
    @ObservationIgnored lazy var curiosity = CuriositySequencer(stage: self)
    @ObservationIgnored lazy var ceremony = BuildDeckCeremony()

    // Name phase orchestration — extracted from NamePhase. NamePhase reads `director.name.*`
    // and forwards taps/gestures to it. Concrete director ref (it needs dealSingleCard /
    // cardFlightScene / receiveCredential / advance, beyond the OnboardingStage surface).
    @ObservationIgnored lazy var name = NameSequencer(director: self)

    // Demo phase orchestration — extracted from DemoPhase, same pattern as `name`.
    // DemoPhase reads `director.demo.*`; it calls commitDemoSnapshot / advance through here.
    @ObservationIgnored lazy var demo = DemoSequencer(director: self)

    var deckPulse: Bool = false

    private var sequenceAttempt: Int = 0

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

        projector.hideDealerLine()
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
        case .curiosity:       curiosity.runEntry()
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
            withAnimation(AppAnimation.cinematicFade) { tableFade = 1.0 }
        }
    }

    /// DemoPhase entry — owns only the table fade-in (moved off name). The full
    /// scene (intro lines → deal → flip → tap-lift → compose → swipe-seal) is
    /// driven by DemoPhase itself, mirroring how NamePhase owns runDealerIntro.
    private func runDemoEntry() {
        cardFlightEngine.resetSlotPool()
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(200))
            withAnimation(AppAnimation.cinematicFade) { tableFade = 1.0 }
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
        withAnimation(AppAnimation.tableBloom.reduceMotionSafe) { tableFade = 1.0 }
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
        let copy = DealerDictionary.contextHeadline(appMode: onboardingData.appMode)
        projector.showDealerLineManual(copy)
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
        let copy = DealerDictionary.experienceLevelExitLine(intensity: intensity)
        projector.showDealerLineManual(copy)
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
        withAnimation(AppAnimation.tableBloom.reduceMotionSafe) { tableFade = 1.0 }
        let reply = DealerDictionary.contextResponse(for: situationalRegister)
        projector.showDealerLineManual(reply)

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

    /// Show the couples-first greeting before concluding (single only). The pending
    /// (context, register) is committed when the user taps Continue in the sheet.
    func presentSingleGreeting(context: RelationshipContext, register: SituationalRegister) {
        pendingSingleConclusion = (context, register)
        withAnimation(AppAnimation.standard.reduceMotionSafe) { showSingleGreeting = true }
    }

    /// Continue from the greeting → conclude the context as normal (felt returns, the dealer
    /// replies, advance to Curiosity).
    func continueFromSingleGreeting() {
        withAnimation(AppAnimation.standard.reduceMotionSafe) { showSingleGreeting = false }
        guard let (context, register) = pendingSingleConclusion else { return }
        pendingSingleConclusion = nil
        concludeContext(relationshipContext: context, situationalRegister: register)
    }

    /// Dealer line that responds to the chosen situational register. Dealer voice = "I",
    /// never "we" / "let's" — the OB always addresses the individual.

    private func runConfirmationEntry() {
        // Confirmation reviews the deck on the table — ensure the felt is present
        // so the credential cards deal onto it. The cards themselves are rendered
        // by ConfirmationPhase (its own VaylCardFace symbol cards).
        withAnimation(AppAnimation.tableBloom.reduceMotionSafe) { tableFade = 1.0 }
    }
    /// BuildDeck entry. Pins the felt to 1.0 EXPLICITLY rather than relying on the
    /// carry-over from Confirmation — so the forge always mounts on a present table,
    /// even if Confirmation's exit ever changes to recede the felt. Then arms the
    /// ceremony state (foil sequence). The phase itself drives the melt/forge beats.
    private func runBuildDeckEntry() {
        tableFade = 1.0
        ceremony.runEntry()
    }

    // MARK: - OnboardingStage Protocol Conformance (Dealer Projector Forwarding)

    func showDealerLineManual(_ text: String, anchorYFrac: CGFloat) {
        projector.showDealerLineManual(text, anchorYFrac: anchorYFrac)
    }

    func hideDealerLine() {
        projector.hideDealerLine()
    }

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

    // MARK: - Card Flight Engine Forwarding

    @MainActor
    func dealSingleCard(screenSize: CGSize, scale: CGFloat) async -> (offset: CGSize, angle: Double, flightID: String)? {
        await cardFlightEngine.dealSingleCard(screenSize: screenSize, scale: scale)
    }

    func claimLandingSlot(screenSize: CGSize) -> CardLandingSlot.Resolved {
        cardFlightEngine.claimLandingSlot(screenSize: screenSize)
    }

    func sailCard(
        cardID: String,
        image: UIImage,
        from: CGPoint,
        to: CGPoint,
        sceneSize: CGSize,
        duration: TimeInterval = 0.92,
        initialAngle: CGFloat      = -0.24,
        finalAngle: CGFloat      = 0.0314,
        zPosition: CGFloat      = 0
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
        // 3 of the 5 sort cards kept = rich (single aspirational round since
        // 2026-07-04; was 4 of 10 across two rounds). Milestone keeps are heavy
        // signals, so the bar is a majority, not the old 40% ratio.
        let richCuriosity = onboardingData.curiositySelections.count >= 3

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

}
