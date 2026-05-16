//
//  VaylDirector.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/9/26.
//


//
//  VaylDirector.swift
//  Vayl
//

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

    // MARK: - User Data

    var onboardingData: OnboardingData = OnboardingData()

    // MARK: - Deck Assignment

    var openerDeckType: OpenerDeckType = .anxious

    // MARK: - Table State

    var tableFade:          Double = 0.0    // 0=gone 1=full
    var dealPointIntensity: Double = 0.0    // 0=off 1=full warm

    // MARK: - Projected Text

    var projectedText:        String? = nil
    var projectedTextVisible: Bool    = false

    // MARK: - Foil State

    var foilIntegrity: Double     = 1.0    // 1.0=sealed 0.0=dissolved
    var foilTears:     [FoilTear] = []

    // MARK: - Corner Deck

    var cornerDeckVisible: Bool = false

    // MARK: - Deck Pulse (AppArrival)

    var deckPulse: Bool = false

    // MARK: - Attempt Tracking
    // Prevents stale Tasks from acting after a phase change.
    // Each independent sequence family has its own counter so they
    // cannot cancel each other by incrementing a shared value.
    //
    // sequenceAttempt  — phase entry sequences (intro, appArrival,
    //                    foilDissolve, pocketToCornerDeck)
    // dealerLineAttempt — showDealerLine only

    private var sequenceAttempt:   Int = 0
    private var dealerLineAttempt: Int = 0

    // MARK: - Dependencies
    // Injected after init — VaylDirector is created by OnboardingCanvasView
    // before the store is available. Set via onboardingStore setter.

    var onboardingStore: OnboardingStore? = nil

    // MARK: - Start

    func start() {
        phase = .stat
        handlePhaseEntry(.stat)
    }

    // MARK: - Transition Guard

    private var isTransitioning: Bool = false

    // MARK: - Phase Advancement
    // VaylDirector is the ONLY thing that advances phase.
    // Phase overlays dispatch intents. Director decides.

    func advance(to next: OBPhase) {
        guard !isTransitioning else { return }
        isTransitioning = true
        Task { @MainActor in
            // Let current phase begin its fade-out before the next renders.
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
            break // StatPhase handles its own sequence

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

    // MARK: - Phase Sequences
    // Full animation sequences to be implemented per phase.
    // Barebones: advance timing only. No card physics yet.

  

    private func runNameEntry() {
        // TODO: deal point warms, card slides in, flips, corner deck appears
        cornerDeckVisible = true
    }

    private func runGenderEntry() {
        // TODO: deal next card sequence
    }

    private func runModeSelectEntry() {
        // TODO: three cards deal with stagger, dealer line fires
        showDealerLine("Everyone comes to this table differently.")
    }

    private func runExperienceLevelEntry() {
        // TODO: deck weave shuffle, fan, three cards deal
    }

    private func runContextEntry() {
        // TODO: cards deal, hand raise transition
        showDealerLine("Tell me where you're at.")
    }

    private func runQuizEntry() {
        // TODO: mid-arc flip, full bleed expansion
    }

    private func runCuriosityRound1Entry() {
        // TODO: 5 cards arrive overlapping quiz dissolve
        showDealerLine("Sweep away what you aren't ready for.")
    }

    private func runCuriosityRound2Entry() {
        // TODO: chapter break, 5 new cards deal
        showDealerLine("Pick one.")
    }

    private func runBuildingPathEntry() {
        // TODO: slot machine sequence, deck assembly
    }

    private func runFoilEntry() {
        // TODO: foil materialises over deck
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
            // AppState.isOnboardingComplete is set inside OnboardingStore.commit()
            // ContentView observes AppState and switches to AppShell automatically
        }
    }

    // MARK: - Dealer Lines
    // Exactly four. Projected on the felt. Not UI labels.
    // 1. "Everyone comes to this table differently." — ModeSelectPhase
    // 2. "Tell me where you're at."                 — ContextPhase
    // 3. "Sweep away what you aren't ready for."    — CuriosityPhase R1
    // 4. "Pick one."                                — CuriosityPhase R2

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

    /// Deal a card from the deal point to a position on the table.
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

    /// Send a card to the corner deck.
    func pocketToCornerDeck(_ card: VaylCardModel, screenSize: CGSize) {
        let cornerTarget = CGPoint(
            x: screenSize.width - AppLayout.cornerDeckRight - AppLayout.cornerDeckWidth / 2,
            y: AppLayout.cornerDeckTop + AppLayout.cornerDeckHeight / 2
        )
        sequenceAttempt += 1
        let current = sequenceAttempt
        withAnimation(AppAnimation.cardPocket) {
            card.position = cornerTarget
            card.scale    = 0.22    // physics constant — shrink to corner deck scale
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

    /// Evaluate and assign opener deck type from collected OB data.
    /// Called silently at the end of CuriosityPhase round 2.
    func evaluateOpenerDeckType() {
        let hasHeavyContext   = onboardingData.emotionalRegister == "anxious"
        let hasMoreSelections = onboardingData.curiositySelections.count >= 4
        openerDeckType = hasHeavyContext && !hasMoreSelections ? .anxious : .excited
        onboardingData.openerDeckType = openerDeckType
    }

    // MARK: - Foil

    /// Add a tear at the tapped point. Evaluate integrity threshold.
    func addFoilTear(at point: CGPoint) {
        let tear = FoilTear(tapPoint: point)
        foilTears.append(tear)
        // Three tears crosses the threshold — begin auto-dissolve
        if foilTears.count >= 3 {
            beginFoilDissolve()
        }
    }

    private func beginFoilDissolve() {
        sequenceAttempt += 1
        let current = sequenceAttempt
        // TODO: animate foil integrity to 0, fire particles, reveal deck
        withAnimation(AppAnimation.foilDissolve) {
            self.foilIntegrity = 0
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(800))
            guard current == self.sequenceAttempt else { return }
            // TODO: particles complete — advance
            try? await Task.sleep(for: .seconds(1))
            guard current == self.sequenceAttempt else { return }
            self.advance(to: .founderLetter)
        }
    }
}
