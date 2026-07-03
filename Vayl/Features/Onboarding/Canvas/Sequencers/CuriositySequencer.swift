//
//  CuriositySequencer.swift
//  Vayl
//
//  Extracts all CuriosityPhase state from VaylDirector.
//

import SwiftUI

@Observable
@MainActor
final class CuriositySequencer {
    
    // MARK: - State
    
    var pile: [CuriositySortCard] = []
    var roundIndex: Int = 0
    var keptRound1: [String] = []
    var keptRound2: [String] = []
    var dragOffset: CGSize = .zero
    var flyingCard: CuriositySortCard? = nil
    var flyingOffset: CGSize = .zero
    var thresholdCrossed: Bool = false
    var dealTrigger: Bool = false
    var roundTransitioning: Bool = false
    var demoActive: Bool = false
    var demoCommitTrigger: Bool = false
    var summaryVisible: Bool = false
    var summaryOffset: CGSize = .zero
    var summaryScale: Double = 1.0
    var summaryAlpha: Double = 1.0
    var summaryPresented: Bool = false

    @ObservationIgnored private weak var stage: VaylDirector?
    @ObservationIgnored var sequenceTask: Task<Void, Never>? = nil
    @ObservationIgnored private var flyingClearAttempt: Int = 0

    init(stage: VaylDirector) {
        self.stage = stage
    }

    // MARK: - API
    
    func runEntry() {
        sequenceTask?.cancel()
        sequenceTask = nil
        
        pile = [
            CuriositySortCard(id: "demo_keep", text: "This card fits you.", round: 1),
            CuriositySortCard(id: "demo_pass", text: "This card... not so much.", round: 1),
        ]
        roundIndex         = 0
        keptRound1         = []
        keptRound2         = []
        dragOffset         = .zero
        flyingCard         = nil
        flyingOffset       = .zero
        thresholdCrossed   = false
        dealTrigger        = false
        roundTransitioning = false
        demoActive         = true
        summaryVisible     = false
        summaryOffset      = .zero
        summaryScale       = 1.0
        summaryAlpha       = 1.0
        summaryPresented   = false
    }

    func beginCuriosityDemo(screenWidth: CGFloat) {
        guard demoActive else { return }
        
        sequenceTask?.cancel()
        sequenceTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(50))
            self.dealTrigger.toggle()
            try? await Task.sleep(for: .milliseconds(750))
            
            let keepLine = DealerDictionary.curiosityDemoKeepInstruction
            self.stage?.projector.showDealerLineManual(keepLine)
            try? await Task.sleep(for: .milliseconds(AppDealerTyping.typeDuration(keepLine) + 450))
            
            await self.demoSwipe(right: true, screenWidth: screenWidth)
            
            self.stage?.projector.hideDealerLine()
            try? await Task.sleep(for: .milliseconds(350))
            
            let passLine = DealerDictionary.curiosityDemoPassInstruction
            self.stage?.projector.showDealerLineManual(passLine)
            try? await Task.sleep(for: .milliseconds(AppDealerTyping.typeDuration(passLine) + 450))
            
            await self.demoSwipe(right: false, screenWidth: screenWidth)
            
            self.demoActive = false
            self.stage?.projector.hideDealerLine()
            try? await Task.sleep(for: .milliseconds(350))
            
            let intro = DealerDictionary.curiosityDemoIntroRealHand
            self.stage?.projector.showDealerLineManual(intro)
            try? await Task.sleep(for: .milliseconds(AppDealerTyping.typeDuration(intro) + 500))
            self.stage?.projector.hideDealerLine()
            try? await Task.sleep(for: .milliseconds(300))
            
            self.flyingCard = nil
            self.dragOffset = .zero
            if let stage = self.stage {
                self.pile = self.buildCuriosityPile(round: 1, onboardingData: stage.onboardingData)
                          + self.buildCuriosityPile(round: 2, onboardingData: stage.onboardingData)
            }
            self.dealTrigger.toggle()
            try? await Task.sleep(for: .milliseconds(400))
            self.stage?.projector.showDealerLineManual(DealerDictionary.curiosityRound1Headline)
        }
    }

    func onCuriosityDrag(offset: CGSize) {
        dragOffset = offset
        let crossed = abs(offset.width) >= 95
        if crossed != thresholdCrossed {
            thresholdCrossed = crossed
        }
    }

    func commitCuriositySwipe(screenSize: CGSize) {
        guard !pile.isEmpty, !roundTransitioning else { return }
        let topCard = pile[0]
        let isKeep  = dragOffset.width > 0
        let flingX: CGFloat = isKeep ? screenSize.width * 1.6 : -screenSize.width * 1.6
        let flingY: CGFloat = dragOffset.height * 0.5

        if isKeep {
            if topCard.round == 1 { keptRound1.append(topCard.id) }
            else                  { keptRound2.append(topCard.id) }
        }

        advanceCuriosityTopCard(
            flingTo: CGSize(width: flingX, height: flingY),
            startingFrom: dragOffset
        )
        thresholdCrossed = false

        if topCard.round == 1, pile.first?.round == 2 {
            onCuriosityRoundBoundary()
            return
        }

        guard pile.isEmpty else { return }
        
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(260))
            self.onCuriosityDeckExhausted(screenSize: screenSize)
        }
    }

    func snapBackCuriosityCard() {
        withAnimation(AppAnimation.cardSettle) { dragOffset = .zero }
        thresholdCrossed = false
    }

    func handoffCuriosityDeck(screenSize: CGSize) {
        guard summaryPresented else { return }
        summaryPresented = false

        Task { @MainActor in
            let cardW = AppLayout.obTableCardWidth(in: screenSize.width) * AppLayout.obTableCardCinematicScale
            let cornerX = screenSize.width  - AppLayout.cornerDeckRight - AppLayout.cornerDeckWidth  / 2
            let cornerY = AppLayout.cornerDeckTop + AppLayout.cornerDeckHeight / 2
            
            withAnimation(AppAnimation.cardPocket.reduceMotionSafe) {
                self.summaryOffset = CGSize(width: cornerX - screenSize.width / 2,
                                            height: cornerY - screenSize.height / 2)
                self.summaryScale  = AppLayout.cornerDeckWidth / cardW
            }
            withAnimation(AppAnimation.pocketAlphaFade.reduceMotionSafe) {
                self.summaryAlpha = 0
            }
            try? await Task.sleep(for: .milliseconds(480))
            self.stage?.receiveCredential(.curiosity)
            self.summaryVisible = false

            // No dealer line on the handoff: the pocket motion IS the goodbye.
            // Advance straight into Confirmation so the deck flows back out as the
            // six credential cards in one continuous motion (Confirmation deals from
            // this same corner), no double line, no dead air. FEEL-GATE the beat.
            try? await Task.sleep(for: .milliseconds(120))
            self.stage?.advance(to: .confirmation)
        }
    }

    // MARK: - Private Implementations

    private func demoSwipe(right: Bool, screenWidth: CGFloat) async {
        let dir: CGFloat = right ? 1 : -1
        withAnimation(AppAnimation.curiosityDemoSwipe) {
            dragOffset = CGSize(width: dir * screenWidth * 0.28, height: 0)
        }
        try? await Task.sleep(for: .milliseconds(160))
        thresholdCrossed = true
        try? await Task.sleep(for: .milliseconds(60))
        demoCommitTrigger.toggle()
        advanceCuriosityTopCard(
            flingTo: CGSize(width: dir * screenWidth * 1.6, height: 0),
            startingFrom: dragOffset
        )
        thresholdCrossed = false
        try? await Task.sleep(for: .milliseconds(520))
    }

    private func advanceCuriosityTopCard(flingTo flingOffset: CGSize, startingFrom startOffset: CGSize) {
        guard let top = pile.first else { return }
        flyingCard = top
        flyingOffset = startOffset

        withAnimation(AppAnimation.curiosityRise.reduceMotionSafe) {
            pile.removeFirst()
            dragOffset = .zero
        }

        flyingClearAttempt += 1
        let current = flyingClearAttempt
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(30))
            guard current == self.flyingClearAttempt else { return }
            withAnimation(AppAnimation.curiosityThrow.reduceMotionSafe) {
                self.flyingOffset = flingOffset
            }
            try? await Task.sleep(for: .milliseconds(380))
            guard current == self.flyingClearAttempt else { return }
            self.flyingCard = nil
        }
    }

    private func onCuriosityRoundBoundary() {
        guard !roundTransitioning else { return }
        roundTransitioning = true
        stage?.projector.hideDealerLine()

        sequenceTask?.cancel()
        sequenceTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(600))
            self.roundIndex = 1
            // Stage-aware: curious users are sizing up first-times, in-it users
            // are refining a lane they already enjoy.
            let inIt = (self.stage?.onboardingData.nmStage ?? .curious) != .curious
            let line = inIt ? DealerDictionary.curiosityRound2HeadlineInIt
                            : DealerDictionary.curiosityRound2Headline
            self.stage?.projector.showDealerLineManual(line)
            try? await Task.sleep(for: .milliseconds(AppDealerTyping.typeDuration(line) + 250))
            self.roundTransitioning = false
        }
    }

    private func onCuriosityDeckExhausted(screenSize: CGSize) {
        guard let stage = stage else { return }
        
        stage.onboardingData.communicationGoals = keptRound1
        stage.onboardingData.learningGoals = keptRound2
        stage.onboardingData.curiositySelections = keptRound1 + keptRound2
        stage.evaluateOpenerDeckType()

        stage.projector.hideDealerLine()

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(350))
            
            self.summaryOffset = CGSize(
                width: 0,
                height: screenSize.height * 0.42 - screenSize.height / 2
            )
            self.summaryScale = 0.82
            self.summaryAlpha = 0
            self.summaryVisible = true
            
            withAnimation(AppAnimation.spring.reduceMotionSafe) {
                self.summaryScale = 1.12
                self.summaryAlpha = 1.0
            }
            try? await Task.sleep(for: .milliseconds(600))
            self.summaryPresented = true
        }
    }

    func buildCuriosityPile(round: Int, onboardingData: OnboardingData) -> [CuriositySortCard] {
        // R1 = mode x register (feelings). R2 = mode + stage (curious = first-time
        // acts, in-it = refine the lane). Deterministic, so the editor rebuilds it.
        let mode = onboardingData.appMode
        let register = SituationalRegister(rawValue: onboardingData.situationalRegister ?? "") ?? .flexible
        let stage = onboardingData.nmStage
        return CuriosityDeck.cards(round: round, mode: mode, register: register, stage: stage)
    }
}
