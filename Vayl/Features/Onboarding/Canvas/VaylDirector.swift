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

    var onboardingData: OnboardingData = OnboardingData()
    var openerDeckType: OpenerDeckType = .anxious

    var tableFade:          Double = 0.0
    var dealPointIntensity: Double = 0.0

    var cardFlightScene: CardFlightScene = CardFlightScene()

    var projectedText:        String? = nil
    var projectedTextVisible: Bool    = false

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
    // commit() is a no-op until assigned — Director must be initialized before appArrival fires.
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
            try? await Task.sleep(for: .milliseconds(200)) // advance debounce
            phase = next
            handlePhaseEntry(next)
            isTransitioning = false
        }
    }

    private func handlePhaseEntry(_ phase: OBPhase) {
        switch phase {
        case .stat:            break
        case .name:            runNameEntry()
        case .gender:          runGenderEntry()
        case .modeSelect:      runModeSelectEntry()
        case .experienceLevel: runExperienceLevelEntry()
        case .context:         runContextEntry()
        case .quiz:            runQuizEntry()
        case .curiosityRound1: runCuriosityRound1Entry()
        case .curiosityRound2: runCuriosityRound2Entry()
        case .buildingPath:    runBuildingPathEntry()
        case .foil:            runFoilEntry()
        case .founderLetter:   runFounderLetterEntry()
        case .appArrival:      runAppArrival()
        }
    }

    private func runNameEntry() {
        tableFade = 1.0
        withAnimation(AppAnimation.standard) { cornerDeckVisible = false }
        resetSlotPool()
    }

    private func runGenderEntry() {
        withAnimation(AppAnimation.standard) { cornerDeckVisible = false }
        resetSlotPool()
        withAnimation(AppAnimation.cinematicFade.reduceMotionSafe) {
            tableFade = 1.0
        }
        showDealerLine("Tell me a little more about you.", hideAfter: 3.5)
    }
    private func runModeSelectEntry() {
        withAnimation(AppAnimation.standard) { cornerDeckVisible = false }
        showDealerLine("Everyone comes to this table differently.")
    }
    private func runExperienceLevelEntry() {
        withAnimation(AppAnimation.standard) { cornerDeckVisible = false }
    }
    private func runContextEntry() {
        withAnimation(AppAnimation.standard) { cornerDeckVisible = false }
        showDealerLine("Tell me where you're at.")
    }
    private func runQuizEntry() {}
    private func runCuriosityRound1Entry() { showDealerLine("Sweep away what you aren't ready for.") }
    private func runCuriosityRound2Entry() { showDealerLine("Pick one.") }
    private func runBuildingPathEntry() {}
    private func runFoilEntry() { foilIntegrity = 1.0; foilTears = [] }
    private func runFounderLetterEntry() {}

    private func runAppArrival() {
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
        renderer.scale = UIScreen.main.scale // TODO: UIScreen.main.scale — no AppLayout equivalent for render scale, acceptable UIKit bridge
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

    func evaluateOpenerDeckType() {
        let hasHeavyContext   = onboardingData.emotionalRegister == "anxious"
        let hasMoreSelections = onboardingData.curiositySelections.count >= 4
        openerDeckType = hasHeavyContext && !hasMoreSelections ? .anxious : .excited
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
}
