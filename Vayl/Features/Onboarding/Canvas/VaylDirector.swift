// Features/Onboarding/Canvas/VaylDirector.swift

import SwiftUI

@Observable
@MainActor
final class VaylDirector {

    // MARK: - Phase

    var phase: OBPhase = .stat

    // MARK: - Card Arrays
    // Director writes. Renderers read.

    var tableCards:      [VaylCardModel] = []
    var cornerDeckCards: [VaylCardModel] = []
    var inFlightCards:   [VaylCardModel] = []
    var muckCards:       [VaylCardModel] = []

    // Phase card models — canvas-level rendering via VaylCardRenderer
    var nameCard:   VaylCardModel? = nil
    var genderCard: VaylCardModel? = nil

    // UI visibility signals — observed by phase overlays
    var nameInputVisible:    Bool    = false
    var nameInputDragY:      CGFloat = 0     // drives overlay offset + table/card peek
    var genderPickerVisible: Bool    = false
    var genderCopyVisible:   Bool    = false

    // MARK: - User Data

    var onboardingData: OnboardingData = OnboardingData()

    // MARK: - Deck Assignment

    var openerDeckType: OpenerDeckType = .anxious

    // MARK: - Table State

    var tableFade:          Double = 0.0
    var rimBurst:           Double = 0
    var dealPointIntensity: Double = 0.0

    // MARK: - Projected Text

    var projectedText:        String? = nil
    var projectedTextVisible: Bool    = false

    // MARK: - Foil State

    var foilIntegrity: Double     = 1.0
    var foilTears:     [FoilTear] = []

    // MARK: - Corner Deck

    var cornerDeckVisible: Bool = false

    // MARK: - Deck Pulse (AppArrival)

    var deckPulse: Bool = false

    // MARK: - Attempt Tracking

    private var sequenceAttempt:   Int = 0
    private var dealerLineAttempt: Int = 0

    // MARK: - Phase Sequence Private State
    // @ObservationIgnored — these never need to trigger view re-renders.

    @ObservationIgnored private var cachedScreenSize:    CGSize = .zero
    @ObservationIgnored private var nameLandingAngle:   Double = 0
    @ObservationIgnored private var nameLandingOffset:  CGSize = .zero
    @ObservationIgnored private var nameInputDismissFired: Bool = false

    @ObservationIgnored private var genderLiftFired:  Bool = false
    @ObservationIgnored private var genderHasTugged:  Bool = false
    @ObservationIgnored private var genderTugTask:    Task<Void, Never>? = nil
    @ObservationIgnored private var genderDriftTask:  Task<Void, Never>? = nil

    // MARK: - Dependencies

    var onboardingStore: OnboardingStore? = nil

    // MARK: - Screen Size

    func updateScreenSize(_ size: CGSize) {
        cachedScreenSize = size
    }

    // MARK: - Start

    func start() {
        phase = .stat
        handlePhaseEntry(.stat)
    }

    // MARK: - Transition Guard

    private var isTransitioning: Bool = false

    // MARK: - Phase Advancement

    func advance(to next: OBPhase) {
        guard !isTransitioning else { return }
        isTransitioning = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(200))
            phase = next
            handlePhaseEntry(next)
            isTransitioning = false
        }
    }

    // MARK: - Phase Entry Handlers

    private func handlePhaseEntry(_ phase: OBPhase) {
        switch phase {
        case .stat:
            break

        case .name:
            runNameEntry()

        case .gender:
            runGenderEntry()

        case .modeSelect:
            runModeSelectEntry()

        case .experienceLevel:
            runExperienceLevelEntry()

        case .context:
            runContextEntry()

        case .quiz:
            runQuizEntry()

        case .curiosityRound1:
            runCuriosityRound1Entry()

        case .curiosityRound2:
            runCuriosityRound2Entry()

        case .buildingPath:
            runBuildingPathEntry()

        case .foil:
            runFoilEntry()

        case .founderLetter:
            runFounderLetterEntry()

        case .appArrival:
            runAppArrival()
        }
    }

    // MARK: - Name Entry Sequence

    private func runNameEntry() {
        guard cachedScreenSize != .zero else { return }

        tableFade             = 1.0
        rimBurst              = 0
        cornerDeckVisible     = true
        nameInputVisible      = false
        nameInputDragY        = 0
        nameInputDismissFired = false

        // Seed landing position once per session
        nameLandingAngle  = Double.random(in: -7...7)
        nameLandingOffset = CGSize(
            width:  CGFloat.random(in: -38...38),
            height: CGFloat.random(in: -28...28)
        )

        let card = VaylCardModel()
        card.credential = .name
        card.opacity    = 0
        card.position   = CGPoint(
            x: cachedScreenSize.width  * (0.5 + 0.60),
            y: cachedScreenSize.height * (0.5 - 0.58)
        )
        card.rotation = -14
        nameCard = card
        tableCards.append(card)

        Task { @MainActor in
            await runNameDealSequence(card: card)
        }
    }

    private func runNameDealSequence(card: VaylCardModel) async {
        let sw = cachedScreenSize.width
        let sh = cachedScreenSize.height

        // Deal flight — card fades in while flying to landing position
        withAnimation(.linear(duration: 0.14)) {
            card.opacity = 1
        }
        withAnimation(.interpolatingSpring(mass: 1.1, stiffness: 160, damping: 18, initialVelocity: 6)) {
            card.position = CGPoint(
                x: sw / 2 + nameLandingOffset.width,
                y: sh / 2 + nameLandingOffset.height
            )
            card.rotation = nameLandingAngle
        }

        try? await Task.sleep(for: .milliseconds(940))
        guard !Task.isCancelled else { return }

        // Landing — rim burst fires
        rimBurst = 1.0
        withAnimation(.timingCurve(0.2, 0.8, 0.4, 1.0, duration: 0.6)) {
            rimBurst = 0.0
        }

        try? await Task.sleep(for: .milliseconds(300))
        guard !Task.isCancelled else { return }

        // Organize — critically damped, zero overshoot
        withAnimation(.spring(response: 0.72, dampingFraction: 1.0)) {
            card.position = CGPoint(x: sw / 2, y: sh / 2)
            card.rotation = 0
        }

        try? await Task.sleep(for: .milliseconds(780))
        guard !Task.isCancelled else { return }

        try? await Task.sleep(for: .milliseconds(1200))
        guard !Task.isCancelled else { return }

        await runNameFlip(card: card)
    }

    private func runNameFlip(card: VaylCardModel) async {
        // First half — collapse to scaleX 0
        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            card.scaleX = 0.0
        }

        try? await Task.sleep(for: .milliseconds(190))
        guard !Task.isCancelled else { return }

        // Swap to portal face at the invisible midpoint
        card.flipProgress = 1.0
        card.content      = .portal(startDate: Date())

        // Second half — renderer's built-in ×(-1) on face yields correct orientation
        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            card.scaleX = 1.0
        }

        try? await Task.sleep(for: .milliseconds(660))
        guard !Task.isCancelled else { return }

        await runNameExpand(card: card)
    }

    private func runNameExpand(card: VaylCardModel) async {
        let cardW = AppLayout.obCardWidth(in: cachedScreenSize.width)
        let cardH = AppLayout.obCardHeight(in: cachedScreenSize.width)
        let scaleX = cachedScreenSize.width  / cardW
        let scaleY = cachedScreenSize.height / cardH
        let target = max(scaleX, scaleY) * 1.04

        withAnimation(.easeIn(duration: 0.55)) {
            tableFade = 0.0
        }
        withAnimation(.timingCurve(0.4, 0.0, 0.2, 1.0, duration: 1.05)) {
            card.scale  = target
            card.scaleX = target
        }

        try? await Task.sleep(for: .milliseconds(550))
        guard !Task.isCancelled else { return }

        withAnimation(.easeIn(duration: 0.35)) {
            card.opacity = 0.0
        }

        try? await Task.sleep(for: .milliseconds(380))
        guard !Task.isCancelled else { return }

        nameInputVisible = true
        triggerNameInputHint()
    }

    private func triggerNameInputHint() {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.5))
            guard nameInputVisible, nameInputDragY == 0 else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                applyNameInputDragValues(dy: 16)
            }
            try? await Task.sleep(for: .milliseconds(400))
            guard nameInputDragY > 0 else { return }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                applyNameInputDragValues(dy: 0)
            }
        }
    }

    // MARK: - Name Input Drag API (called by NamePhase gesture)

    private func applyNameInputDragValues(dy: CGFloat) {
        let clampedDy   = max(0, dy)
        nameInputDragY  = clampedDy
        let progress    = min(clampedDy / (cachedScreenSize.height * 0.25), 1.0)
        tableFade       = progress * 0.75
        nameCard?.opacity = progress * 0.40
    }

    func applyNameInputDrag(dy: CGFloat) {
        guard nameInputVisible else { return }
        applyNameInputDragValues(dy: dy)
    }

    func snapBackNameInputDrag() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            nameInputDragY = 0
        }
        withAnimation(.easeOut(duration: 0.25)) {
            tableFade         = 0
            nameCard?.opacity = 0
        }
    }

    func commitNameAndDismiss(name: String) {
        guard !nameInputDismissFired else { return }
        nameInputDismissFired      = true
        onboardingData.displayName = name
        withAnimation(.spring(response: 0.48, dampingFraction: 0.88)) {
            nameInputDragY = cachedScreenSize.height * 1.2
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(480))
            advance(to: .gender)
        }
    }

    // MARK: - Gender Entry Sequence

    private func runGenderEntry() {
        guard cachedScreenSize != .zero else { return }

        // Clean up invisible name card — it finished its expand and is opacity 0
        if let nc = nameCard {
            tableCards.removeAll { $0.id == nc.id }
        }

        tableFade         = 1.0
        cornerDeckVisible = true
        genderLiftFired   = false
        genderHasTugged   = false
        genderPickerVisible = false
        genderCopyVisible   = true

        let card = VaylCardModel()
        card.credential = .gender
        card.opacity    = 1.0
        card.position   = CGPoint(
            x: cachedScreenSize.width / 2,
            y: AppLayout.obTableCardCenterY(in: cachedScreenSize.height)
        )
        genderCard = card
        tableCards.append(card)

        scheduleGenderTug(card: card)
        scheduleGenderDrift(card: card)
    }

    // MARK: - Gender Tug

    private func scheduleGenderTug(card: VaylCardModel) {
        guard !genderHasTugged else { return }
        genderTugTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled, !genderHasTugged, !genderLiftFired else { return }
            await runGenderTugSequence(card: card)
        }
    }

    private func runGenderTugSequence(card: VaylCardModel) async {
        genderHasTugged = true
        let restingY = AppLayout.obTableCardCenterY(in: cachedScreenSize.height)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
            card.position = CGPoint(x: cachedScreenSize.width / 2, y: restingY + 7)
        }
        try? await Task.sleep(for: .milliseconds(400))
        guard !Task.isCancelled else { return }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            card.position = CGPoint(x: cachedScreenSize.width / 2, y: restingY)
        }
        try? await Task.sleep(for: .milliseconds(700))
    }

    // MARK: - Gender Auto-Drift

    private func scheduleGenderDrift(card: VaylCardModel) {
        genderDriftTask?.cancel()
        genderDriftTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled, !genderLiftFired else { return }
            await runGenderDriftSequence(card: card)
        }
    }

    private func runGenderDriftSequence(card: VaylCardModel) async {
        let restingY  = AppLayout.obTableCardCenterY(in: cachedScreenSize.height)
        let threshold = cachedScreenSize.height * 0.18
        withAnimation(.spring(response: 1.2, dampingFraction: 0.9)) {
            card.position = CGPoint(x: cachedScreenSize.width / 2, y: restingY + threshold)
        }
        try? await Task.sleep(for: .milliseconds(900))
        guard !Task.isCancelled else { return }
        runGenderPortalLift(card: card)
    }

    // MARK: - Gender Portal Lift

    private func runGenderPortalLift(card: VaylCardModel) {
        guard !genderLiftFired else { return }
        genderLiftFired = true
        genderTugTask?.cancel()
        genderDriftTask?.cancel()
        genderCopyVisible = false

        Task { @MainActor in
            await runGenderFlip(card: card)
        }
    }

    private func runGenderFlip(card: VaylCardModel) async {
        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            card.scaleX = 0.0
        }
        try? await Task.sleep(for: .milliseconds(190))

        card.flipProgress = 1.0
        card.content      = .portal(startDate: Date())

        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            card.scaleX = 1.0
        }
        try? await Task.sleep(for: .milliseconds(660))

        await runGenderExpand(card: card)
    }

    private func runGenderExpand(card: VaylCardModel) async {
        let cardW = AppLayout.obCardWidth(in: cachedScreenSize.width)
        let cardH = AppLayout.obCardHeight(in: cachedScreenSize.width)
        let scaleX = cachedScreenSize.width  / cardW
        let scaleY = cachedScreenSize.height / cardH
        let target = max(scaleX, scaleY) * 1.04

        // Slide to center before expanding
        withAnimation(.spring(response: 0.45, dampingFraction: 0.80)) {
            card.position = CGPoint(x: cachedScreenSize.width / 2, y: cachedScreenSize.height / 2)
        }

        withAnimation(.easeIn(duration: 0.55)) {
            tableFade = 0.0
        }
        withAnimation(.timingCurve(0.4, 0.0, 0.2, 1.0, duration: 1.05)) {
            card.scale  = target
            card.scaleX = target
        }
        try? await Task.sleep(for: .milliseconds(550))

        withAnimation(.easeIn(duration: 0.35)) {
            card.opacity = 0.0
        }
        try? await Task.sleep(for: .milliseconds(380))

        genderPickerVisible = true
    }

    // MARK: - Gender Drag API (called by GenderPhase gesture)

    func applyGenderDrag(dy: CGFloat) {
        guard let card = genderCard, !genderLiftFired else { return }
        genderTugTask?.cancel()
        genderDriftTask?.cancel()
        let restingY  = AppLayout.obTableCardCenterY(in: cachedScreenSize.height)
        let clampedDy = max(0, dy) * 0.85
        card.position = CGPoint(x: cachedScreenSize.width / 2, y: restingY + clampedDy)
    }

    func endGenderDrag(translationY: CGFloat, velocityY: CGFloat) {
        guard let card = genderCard, !genderLiftFired else { return }
        let threshold = cachedScreenSize.height * 0.18
        if translationY >= threshold || velocityY >= 400 {
            runGenderPortalLift(card: card)
        } else {
            let restingY = AppLayout.obTableCardCenterY(in: cachedScreenSize.height)
            withAnimation(.spring(response: 0.45, dampingFraction: 0.80)) {
                card.position = CGPoint(x: cachedScreenSize.width / 2, y: restingY)
            }
            scheduleGenderDrift(card: card)
        }
    }

    // MARK: - Gender Collect (called by GenderPhase after confirm)

    func collectGenderCard() {
        guard let card = genderCard else { return }
        genderPickerVisible = false
        Task { @MainActor in
            withAnimation(AppAnimation.standard) {
                card.opacity = 1.0
                card.scale   = 1.0
                card.scaleX  = 1.0
            }
            try? await Task.sleep(for: .milliseconds(100))
            pocketToCornerDeck(card, screenSize: cachedScreenSize)
            try? await Task.sleep(for: .milliseconds(650))
            advance(to: .modeSelect)
        }
    }

    func cancelGenderTasks() {
        genderTugTask?.cancel()
        genderDriftTask?.cancel()
        genderLiftFired = false
    }

    // MARK: - Other Phase Sequences

    private func runModeSelectEntry() {
        showDealerLine("Everyone comes to this table differently.")
    }

    private func runExperienceLevelEntry() {
        // TODO: deck weave shuffle, fan, three cards deal
    }

    private func runContextEntry() {
        showDealerLine("Tell me where you're at.")
    }

    private func runQuizEntry() {
        // TODO: mid-arc flip, full bleed expansion
    }

    private func runCuriosityRound1Entry() {
        showDealerLine("Sweep away what you aren't ready for.")
    }

    private func runCuriosityRound2Entry() {
        showDealerLine("Pick one.")
    }

    private func runBuildingPathEntry() {
        // TODO: slot machine sequence, deck assembly
    }

    private func runFoilEntry() {
        foilIntegrity = 1.0
        foilTears = []
    }

    private func runFounderLetterEntry() {
        // TODO: card rises from deck
    }

    private func runAppArrival() {
        sequenceAttempt += 1
        let current = sequenceAttempt
        Task { @MainActor in
            onboardingStore?.commit(data: onboardingData)
            try? await Task.sleep(for: .milliseconds(100))
            guard current == self.sequenceAttempt else { return }
            withAnimation(.easeOut(duration: AppAnimation.cinematic)) {
                self.tableFade = 0
            }
            withAnimation(AppAnimation.spring) {
                self.deckPulse = true
            }
            try? await Task.sleep(for: .milliseconds(200))
            guard current == self.sequenceAttempt else { return }
        }
    }

    // MARK: - Dealer Lines

    func showDealerLine(_ text: String, hideAfter seconds: Double = 4.0) {
        dealerLineAttempt += 1
        let current = dealerLineAttempt
        projectedText = text
        withAnimation(AppAnimation.textProject) {
            projectedTextVisible = true
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(seconds))
            guard current == self.dealerLineAttempt else { return }
            withAnimation(AppAnimation.textProject) {
                self.projectedTextVisible = false
            }
        }
    }

    // MARK: - Card Operations

    func dealCard(_ card: VaylCardModel, to destination: CGPoint, screenSize: CGSize) {
        let dealOrigin = CGPoint(
            x: screenSize.width * 0.50,
            y: screenSize.height * AppLayout.dealPointYFrac
        )
        card.position = dealOrigin
        card.opacity  = 0
        tableCards.append(card)
        withAnimation(AppAnimation.cardSlide) {
            card.position = destination
            card.opacity  = 1
        }
    }

    func pocketToCornerDeck(_ card: VaylCardModel, screenSize: CGSize) {
        let cornerTarget = CGPoint(
            x: screenSize.width - AppLayout.cornerDeckRight - AppLayout.cornerDeckWidth / 2,
            y: AppLayout.cornerDeckTop + AppLayout.cornerDeckHeight / 2
        )
        sequenceAttempt += 1
        let current = sequenceAttempt
        withAnimation(AppAnimation.cardPocket) {
            card.position = cornerTarget
            card.scale    = 0.22
            card.opacity  = 0
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(550))
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

    // MARK: - Foil

    func addFoilTear(at point: CGPoint) {
        let tear = FoilTear(tapPoint: point)
        foilTears.append(tear)
        if foilTears.count >= 3 {
            beginFoilDissolve()
        }
    }

    private func beginFoilDissolve() {
        sequenceAttempt += 1
        let current = sequenceAttempt
        withAnimation(AppAnimation.foilDissolve) {
            self.foilIntegrity = 0
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(800))
            guard current == self.sequenceAttempt else { return }
            try? await Task.sleep(for: .seconds(1))
            guard current == self.sequenceAttempt else { return }
            self.advance(to: .founderLetter)
        }
    }
}
