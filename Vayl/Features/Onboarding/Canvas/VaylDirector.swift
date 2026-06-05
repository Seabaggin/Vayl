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

    var cardFlightScene: CardFlightScene = CardFlightScene()

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

    /// nm: normalise t within a window [start, start+dur], clamp 0…1.
    private func nm(_ t: Double, _ s: Double, _ d: Double) -> Double {
        max(0, min(1, (t - s) / d))
    }
    private func eIO3(_ x: Double) -> Double {
        x < 0.5 ? 4*x*x*x : 1 - pow(-2*x+2, 3)/2
    }
    private func eO5(_ x: Double) -> Double { 1 - pow(max(0, 1-x), 5) }
    private func eO7(_ x: Double) -> Double { 1 - pow(max(0, 1-x), 7) }

    /// 0→1 — ambient density stir before anything visible.
    var dissolutionPre:      Double { eIO3(nm(dissolutionT, 0,    0.12)) }

    /// 0→0.52 — topo lines pulled inward toward card footprint.
    var dissolutionWarp:     Double { eIO3(nm(dissolutionT, 0.08, 0.20)) * 0.52 }

    /// 0→1 — card body density (felt-matched mass emerging).
    var dissolutionDensity:  Double { eO5(nm(dissolutionT, 0.18, 0.36)) }

    /// 0→1 — card material sharpness (blur + colour shift felt → void).
    var dissolutionSharp:    Double { eO7(nm(dissolutionT, 0.42, 0.32)) }

    /// 0°→8° — hex grid angle drift (phase-matched → native card moiré).
    var dissolutionHexAngle: Double { eIO3(nm(dissolutionT, 0.24, 0.42)) * 8.0 }

    /// 2.2→1.0 — hex cell spacing multiplier (topo frequency → card size).
    var dissolutionHexSpacing: Double { 2.2 + (1.0 - 2.2) * eIO3(nm(dissolutionT, 0.24, 0.44)) }

    /// 0→1 — topo lines relax outward, flowing around card boundary.
    var dissolutionFlowOut:  Double { eIO3(nm(dissolutionT, 0.50, 0.30)) }

    /// 0→1 — wordmark crystallises last.
    var dissolutionMark:     Double { eO7(nm(dissolutionT, 0.62, 0.26)) }

    /// Task handle for the gender visual sequence. Not observed — internal bookkeeping only.
    @ObservationIgnored var genderSequenceTask: Task<Void, Never>? = nil

    var foilIntegrity: Double     = 1.0
    var foilTears:     [FoilTear] = []

    var cornerDeckVisible: Bool = false
    var deckPulse: Bool = false

    private var sequenceAttempt:   Int = 0
    private var dealerLineAttempt: Int = 0

    // Slot pool — tracks which landing zones are still available this round.
    // Starts full; shrinks as cards are dealt; auto-resets when exhausted.
    private var availableSlotIDs: [Int] = AppLayout.obCardLandingSlots.map(\.id)

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
        resetSlotPool()
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

    /// Called by ExperienceLevelPhase on confirm. Writes nmStage, adds the collected
    /// card to the corner deck (so the "X / 6" count grows), pulses the deck, then advances.
    func commitExperienceLevel(_ intensity: CandleIntensity) {
        onboardingData.nmStage = intensity.nmStage

        let collected = VaylCardModel()
        collected.credential = .experienceLevel
        cornerDeckCards.append(collected)
        withAnimation(AppAnimation.deckReceive) { deckPulse = true }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(600))
            deckPulse = false
        }
        // NOTE: advance to .context is NOT fired here. This method is the "receive"
        // step — it must coincide with the winner card landing in the deck. The phase
        // advance flows from ExperienceLevelPhase's `.done` state observer, after the
        // controller has cleared the two discards and held a settle beat.
    }
    private func runContextEntry() {
        resetSlotPool()
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

        let collected = VaylCardModel()
        collected.credential = .context
        cornerDeckCards.append(collected)

        // Felt re-emerges and the corner deck receives the card.
        withAnimation(AppAnimation.tableRecede.reduceMotionSafe) { tableFade = 1.0 }
        withAnimation(AppAnimation.deckReceive) { deckPulse = true }
        showDealerLine(contextResponse(for: situationalRegister))

        sequenceAttempt += 1
        let current = sequenceAttempt
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(600))
            deckPulse = false
            try? await Task.sleep(for: .milliseconds(2000)) // let the responsive line land
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
    private func runCuriosityEntry() { showDealerLine("Sweep away what you aren't ready for.") }
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

    // MARK: - Card Flight

    /// Flies a single card via SpriteKit and returns its rested position and rotation.
    /// The `cardID` is threaded into the per-card callback so the continuation only
    /// resumes for the correct card, even if multiple sailCard calls overlap.
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
        if cardFlightScene.size == .zero || cardFlightScene.size != sceneSize {
            cardFlightScene.size = sceneSize
        }

        let skOrigin = CGPoint(x: from.x, y: sceneSize.height - from.y)
        let skDest   = CGPoint(x: to.x,   y: sceneSize.height - to.y)

        return await withCheckedContinuation { continuation in
            cardFlightScene.onCardRested[cardID] = { [weak self] cbID, pos, rot in
                guard let _ = self else { return }
                let swiftUIPos = CGPoint(x: pos.x, y: sceneSize.height - pos.y)
                continuation.resume(returning: (swiftUIPos, -rot * (180 / .pi)))
            }
            cardFlightScene.dealCard(
                id:           cardID,
                image:        image,
                from:         skOrigin,
                to:           skDest,
                initialAngle: initialAngle,
                finalAngle:   finalAngle,
                zPosition:    zPosition,
                duration:     duration
            )
        }
    }

    /// Deals a single card to a natural landing slot via CardFlightScene.
    ///
    /// Encapsulates the repeated pattern shared by every phase that cinematic-deals
    /// one card: snapshot → random launch point → slot claim with travel-distance
    /// guard → overshoot eligibility → SpriteKit flight.
    ///
    /// Returns `(offset, angle, flightID)` for the SwiftUI handoff.
    /// **Caller is responsible for:**
    ///   1. Setting `cardOffset = offset`, `cardAngle = angle`, `cardAlpha = 1`.
    ///   2. The 32 ms flash fix: `Task.sleep(32 ms)` → `cardFlightScene.clearCard(id: flightID)`.
    ///   3. Marking `cardSettled = true` (or equivalent phase flag).
    ///
    /// Returns `nil` if the VaylCardBack snapshot fails (caller should guard-return cleanly).
    /// Does **not** handle Reduce Motion — caller checks `reduceMotion` and branches before calling.
    @MainActor
    func dealSingleCard(
        screenSize: CGSize
    ) async -> (offset: CGSize, angle: Double, flightID: String)? {

        let cardW = AppLayout.obTableCardWidth(in: screenSize.width)  * AppLayout.obTableCardCinematicScale
        let cardH = AppLayout.obTableCardHeight(in: screenSize.width) * AppLayout.obTableCardCinematicScale

        let scale = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.screen.scale ?? 2.0

        let renderer = ImageRenderer(
            content: VaylCardBack().frame(width: cardW, height: cardH)
        )
        renderer.scale = scale
        guard let cardImage = renderer.uiImage else {
            print("[VaylDirector] dealSingleCard: VaylCardBack snapshot failed")
            return nil
        }

        let flightID      = UUID().uuidString
        let startAngleDeg = Double.random(in: 11.0...16.0)
        let launchX       = screenSize.width * CGFloat.random(in: -0.45...1.45)

        let origin = CGPoint(
            x: launchX,
            y: screenSize.height * AppLayout.tableHorizonYFrac
        )

        // Travel-distance guard — retry up to 4 times before accepting.
        let minTravelDistance = screenSize.width * 0.75
        var slot = claimLandingSlot(screenSize: screenSize)
        for _ in 0..<4 {
            let dist = hypot(slot.position.x - origin.x,
                             slot.position.y - origin.y)
            if dist >= minTravelDistance { break }
            slot = claimLandingSlot(screenSize: screenSize)
        }

        // Overshoot eligibility — only when the overshoot projection clears
        // at least 1/3 of the card width past the screen edge.
        let overshootDist   = slot.position.x + (slot.position.x - origin.x) * 0.22
        let cardThird       = cardW / 3
        let wouldClearLeft  = overshootDist < -cardThird
        let wouldClearRight = overshootDist > screenSize.width + cardThird
        let canOvershoot    = wouldClearLeft || wouldClearRight
        cardFlightScene.pendingShouldOvershoot = canOvershoot && Double.random(in: 0...1) < 0.60

        let skInitialAngle = CGFloat(-startAngleDeg * .pi / 180)
        let skFinalAngle   = CGFloat(-slot.angleDeg  * .pi / 180)

        let (restPos, restRot) = await sailCard(
            cardID:       flightID,
            image:        cardImage,
            from:         origin,
            to:           slot.position,
            sceneSize:    screenSize,
            duration:     0.45,
            initialAngle: skInitialAngle,
            finalAngle:   skFinalAngle
        )

        let offset = CGSize(
            width:  restPos.x - screenSize.width  / 2,
            height: restPos.y - screenSize.height / 2
        )
        return (offset, Double(restRot), flightID)
    }

    /// Slides a card from the deal point to a destination without SpriteKit flight.
    /// Used for non-cinematic deals (e.g. credential cards after the main sequence).
    func dealCard(_ card: VaylCardModel, to destination: CGPoint, screenSize: CGSize) {
        let dealOrigin = CGPoint(x: screenSize.width * 0.50, y: screenSize.height * AppLayout.dealPointYFrac)
        card.position = dealOrigin
        card.opacity  = 0
        card.zIndex   = 0
        tableCards.append(card)
        withAnimation(AppAnimation.cardSlide.reduceMotionSafe) {
            card.position = destination
            card.opacity  = 1
        }
    }

    /// Deals N cards with 150 ms stagger between launches.
    ///
    /// Slots and zIndex are pre-assigned before any async work so the stagger
    /// loop never contends with the slot pool. Each card hands off
    /// SpriteKit → SwiftUI independently the frame it rests.
    func dealCards(_ models: [VaylCardModel], screenSize: CGSize) {
        guard !models.isEmpty else { return }
        if cardFlightScene.size == .zero || cardFlightScene.size != screenSize {
            cardFlightScene.size = screenSize
        }

        let skLaunch   = CGPoint(x: screenSize.width * 1.05, y: screenSize.height * 0.08)
        let dealOrigin = CGPoint(x: screenSize.width * 0.50, y: screenSize.height * AppLayout.dealPointYFrac)

        // Pre-assign all slots and z-order before launching any Tasks.
        let assignments: [(model: VaylCardModel, slot: CardLandingSlot.Resolved, z: Int)] =
            models.enumerated().map { index, model in
                let slot = claimLandingSlot(screenSize: screenSize)
                model.zIndex = index
                model.slotID = index
                return (model, slot, index)
            }

        // Register all as in-flight at opacity 0 so Layer 6 holds space immediately.
        for (model, _, _) in assignments {
            model.position = dealOrigin
            model.opacity  = 0
            inFlightCards.append(model)
        }

        // Per-card callbacks: each rested card transitions inFlight → table independently,
        // without waiting for the other cards to land. Registered per-id so sailCard
        // handlers running concurrently are never overwritten.
        for (model, _, _) in assignments {
            let id = model.id.uuidString
            cardFlightScene.onCardRested[id] = { [weak self] cbID, pos, rot in
                guard let self else { return }
                let swiftUIPos = CGPoint(x: pos.x, y: screenSize.height - pos.y)
                let degrees    = -rot * (180.0 / .pi)
                if let m = self.inFlightCards.first(where: { $0.id.uuidString == cbID }) {
                    m.position = swiftUIPos
                    m.rotation = degrees
                    m.opacity  = 1
                    self.inFlightCards.removeAll { $0.id.uuidString == cbID }
                    self.tableCards.append(m)
                }
                self.cardFlightScene.clearCard(id: cbID)
            }
        }

        for (model, slot, z) in assignments {
            let id           = model.id.uuidString
            let delayMS      = z * 150
            let skDest       = CGPoint(x: slot.position.x, y: screenSize.height - slot.position.y)
            let initialAngle = CGFloat(-Double.random(in: 11.0...16.0) * .pi / 180)
            let finalAngle   = CGFloat(-slot.angleDeg * .pi / 180)

            Task { @MainActor in
                if delayMS > 0 { try? await Task.sleep(for: .milliseconds(delayMS)) }
                guard !Task.isCancelled else { return }
                guard let cardImage = self.snapshotCardBack(screenSize: screenSize) else {
                    print("[VaylDirector] dealCards: skipping card \(id) — snapshot failed")
                    return
                }
                self.cardFlightScene.dealCard(
                    id:           id,
                    image:        cardImage,
                    from:         skLaunch,
                    to:           skDest,
                    initialAngle: initialAngle,
                    finalAngle:   finalAngle,
                    zPosition:    CGFloat(z),
                    duration:     0.92
                )
            }
        }
    }

    @MainActor
    private func snapshotCardBack(screenSize: CGSize) -> UIImage? {
        let w        = AppLayout.obTableCardWidth(in: screenSize.width)
        let h        = AppLayout.obTableCardHeight(in: screenSize.width)
        let renderer = ImageRenderer(content: VaylCardBack().frame(width: w, height: h))
        let scale = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.screen.scale ?? 2.0
        renderer.scale = scale
        guard let image = renderer.uiImage else {
            // Non-fatal: card flight will show blank sprite.
            // This should never happen in production — log for diagnostics.
            print("[VaylDirector] snapshotCardBack returned nil — ImageRenderer failed")
            return nil
        }
        return image
    }

    func pocketToCornerDeck(_ card: VaylCardModel, screenSize: CGSize) {
        let cornerTarget = CGPoint(
            x: screenSize.width  - AppLayout.cornerDeckRight - AppLayout.cornerDeckWidth  / 2,
            y: AppLayout.cornerDeckTop + AppLayout.cornerDeckHeight / 2
        )
        sequenceAttempt += 1
        let current = sequenceAttempt
        withAnimation(AppAnimation.cardPocket.reduceMotionSafe) {
            card.position = cornerTarget
            card.scale    = 0.22
            card.opacity  = 0
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(550)) // pocket duration
            guard current == self.sequenceAttempt else { return }
            tableCards.removeAll    { $0.id == card.id }
            inFlightCards.removeAll { $0.id == card.id }
            let corner = VaylCardModel()
            corner.credential = card.credential
            cornerDeckCards.append(corner)
        }
        
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

    // MARK: - Landing Slot Pool

    /// Picks a random unused slot from the pool, removes it so the next call gets
    /// a different zone, and returns a resolved position + angle for `screenSize`.
    /// When all slots are exhausted the pool resets automatically, so a long flow
    /// that deals more than 5 cards simply cycles through all zones again.
    func claimLandingSlot(screenSize: CGSize) -> CardLandingSlot.Resolved {
        if availableSlotIDs.isEmpty {
            availableSlotIDs = AppLayout.obCardLandingSlots.map(\.id)
        }
        let pickIndex  = availableSlotIDs.indices.randomElement()!
        let slotID     = availableSlotIDs.remove(at: pickIndex)
        let slot       = AppLayout.obCardLandingSlots.first(where: { $0.id == slotID })!
        return slot.resolve(in: screenSize)
    }

    /// Resets the slot pool so the next deal sequence starts fresh.
    /// Call this when entering a new OB phase that deals cards.
    func resetSlotPool() {
        availableSlotIDs = AppLayout.obCardLandingSlots.map(\.id)
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
            genderDealerLineVisible  = true
            genderCardFaceUp         = true
            genderCardFlipScaleX     = 1.0
            genderBeatComplete       = true
            genderHandleOffset       = 38
            genderHandlePullComplete = true
            genderReelOffsets        = [0, 0, 0]
            genderReelsSpinning      = false
            genderSettledSymbols     = [0, 0, 0]
            genderActiveReel         = nil
            genderReelSettleComplete = true
            genderSwipeHintActive    = false   // no looping hint under reduce motion
            genderDealerLineVisible  = false
            genderPickerVisible      = true
            genderDrumOffset         = 0
            genderSelectedIndex      = 0
            genderDrumSettled        = false
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

    /// Beat B through Segment 7 — flip card, pull handle, spin + settle reels, show picker.
    ///
    /// Called immediately after the dealer line has been shown and a 300ms beat has passed.
    ///
    /// Preconditions on entry:
    ///   genderCardFaceUp         = false   (flip will reveal face)
    ///   genderDealerLineVisible  = true    (caller showed it)
    ///   genderHandleOffset       = 0
    ///   genderHandlePullComplete = false
    ///   genderSettledSymbols     = [nil, nil, nil]
    @MainActor
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

        // Beat C: hold (300ms after flip)
        try? await Task.sleep(for: .milliseconds(300))
        guard !Task.isCancelled else { return }
        genderBeatComplete = true

        // ── SEGMENTS 4+5+6 — Handle pull + reel spin + staggered settle ──────
        //
        // One drive loop covers all three phases so offsets are continuous:
        //   Phase 1 (0–500ms)  — handle pulls; reels join at 100ms elapsed
        //   Phase 2 (+300ms)   — coast: reels spin freely after pull settles
        //   Phase 3 (3 × 80ms) — stagger settle; unsettled reels spin until locked

        // 300ms beat post-flip
        try? await Task.sleep(for: .milliseconds(300))
        guard !Task.isCancelled else { return }

        let pullDuration:    Double    = 0.500
        let pullTarget:      CGFloat   = 38
        let reelSpeed:       CGFloat   = 600    // pts/s — fast enough to blur symbols
        let spinDelay:       Double    = 0.100  // reels start 100ms into the pull
        let coastDuration:   Double    = 0.300
        let staggerInterval: Double    = 0.080  // seconds between reel settles
        let reelFactors:     [CGFloat] = [1.0, 1.07, 0.94]  // per-reel speed variation

        let masterStart = Date()
        var spinStart: Date? = nil

        // Phase 1 — Handle pull + reel start
        while !Task.isCancelled {
            let elapsed = -masterStart.timeIntervalSinceNow
            let t       = min(elapsed / pullDuration, 1.0)
            let eased   = CGFloat(1 - pow(1 - t, 3))  // ease-out cubic

            genderHandleOffset = pullTarget * eased

            if elapsed >= spinDelay {
                if spinStart == nil {
                    spinStart = Date()
                    genderReelsSpinning = true
                    // Picker and dealer line transition together the moment reels start.
                    withAnimation(AppAnimation.textProject.reduceMotionSafe) {
                        genderDealerLineVisible = false
                    }
                    withAnimation(AppAnimation.standard.reduceMotionSafe) {
                        genderPickerVisible = true
                    }
                }
                let re = CGFloat(-spinStart!.timeIntervalSinceNow)
                genderReelOffsets = reelFactors.map { re * reelSpeed * $0 }
                let rawDrum1      = genderReelOffsets[0] / 0.68
                let drumCycle     = CGFloat(genderOptions.count) * symbolSlotH
                genderDrumOffset  = rawDrum1.truncatingRemainder(dividingBy: drumCycle)
            }

            if t >= 1.0 { break }
            try? await Task.sleep(for: .milliseconds(14))
        }

        guard !Task.isCancelled else { return }
        genderHandleOffset       = pullTarget
        genderHandlePullComplete = true

        // Phase 2 — Coast
        let coastEnd = Date().addingTimeInterval(coastDuration)
        while !Task.isCancelled {
            if let s = spinStart {
                let re            = CGFloat(-s.timeIntervalSinceNow)
                genderReelOffsets = reelFactors.map { re * reelSpeed * $0 }
                let rawDrum2      = genderReelOffsets[0] / 0.68
                let drumCycle2    = CGFloat(genderOptions.count) * symbolSlotH
                genderDrumOffset  = rawDrum2.truncatingRemainder(dividingBy: drumCycle2)
            }
            if Date() >= coastEnd { break }
            try? await Task.sleep(for: .milliseconds(14))
        }

        guard !Task.isCancelled else { return }

        // Phase 3 — Staggered settle
        // Random symbols for now — picker selection overwrites via settleGenderDrum.
        let settleTargets: [Int] = [
            Int.random(in: 0..<genderOptions.count),
            Int.random(in: 0..<genderOptions.count),
            Int.random(in: 0..<genderOptions.count),
        ]

        for i in 0..<3 {
            guard !Task.isCancelled else { return }

            // Snap reel i — canvas centres it from settledSymbols; reelOffset ignored.
            genderSettledSymbols[i] = settleTargets[i]
            genderActiveReel        = i     // triggers .sensoryFeedback in GenderPhase

            if i < 2 {
                // Keep unsettled reels live during the stagger window.
                let nextSettle = Date().addingTimeInterval(staggerInterval)
                while !Task.isCancelled {
                    if let s = spinStart {
                        let re = CGFloat(-s.timeIntervalSinceNow)
                        // Settled reels: canvas ignores reelOffsets — safe to write full array.
                        genderReelOffsets = reelFactors.map { re * reelSpeed * $0 }
                        let rawDrum3      = genderReelOffsets[0] / 0.68
                        let drumCycle3    = CGFloat(genderOptions.count) * symbolSlotH
                        genderDrumOffset  = rawDrum3.truncatingRemainder(dividingBy: drumCycle3)
                    }
                    if Date() >= nextSettle { break }
                    try? await Task.sleep(for: .milliseconds(14))
                }
                guard !Task.isCancelled else { return }
            }
        }

        guard !Task.isCancelled else { return }

        // Brief hold so the final reel glow reads before it clears.
        try? await Task.sleep(for: .milliseconds(400))
        guard !Task.isCancelled else { return }

        genderActiveReel         = nil
        genderReelsSpinning      = false
        genderReelSettleComplete = true
        genderSelectedIndex      = settleTargets[0]   // picker snaps to match settled reel
        genderDrumSettled        = true               // pronouns + confirm reveal
    }

    // MARK: - Gender Drum Interaction
    //
    // The only paths through which GenderPhase may write back to director state.
    // All reel-sync math lives here — zero logic in View.

    /// Internal canvas units per reel symbol slot. Must match SlotMachineCardFace.symbolSlotH.
    private let symbolSlotH: CGFloat = 58

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
