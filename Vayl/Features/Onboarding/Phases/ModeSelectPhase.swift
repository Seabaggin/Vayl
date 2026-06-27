//
//  ModeSelectPhase.swift
//  Vayl
//
//  Features/Onboarding/Phases/ModeSelectPhase.swift
//
//  Phase overlay for mode selection.
//  Two cards deal from opposite sides simultaneously.
//  User lifts one, swipes up to confirm.
//  Unchosen card flips face-down and slides back to origin.
//

import SwiftUI

struct ModeSelectPhase: View {

    let director:   VaylDirector
    let screenSize: CGSize

    @State private var deal              = CardMirrorDealController()
    @State private var speechTask:       Task<Void, Never>? = nil
    @State private var questionTask:     Task<Void, Never>? = nil
    @State private var liftTextTask:     Task<Void, Never>? = nil
    @State private var liftedText:       String?       = nil
    @State private var liftedSide:       MirrorCard?   = nil
    @State private var hasDealt:         Bool         = false
    @State private var liftHaptic:       Bool         = false
    @State private var deselectHaptic:   Bool         = false

    // ── Question gate ────────────────────────────────────────────────
    // The cards answer "How are you exploring?" — they must not be
    // tappable until the dealer has finished asking it. questionShown latches
    // the line fire; questionAsked opens interaction at type-complete + 250ms.
    @State private var questionShown:    Bool         = false
    @State private var questionAsked:    Bool         = false

    // ── Swipe-up hint — the lifted card tugs upward to cue the confirm gesture ──
    // ModeSelect is the first phase to reuse Name's "lift → swipe up" lesson, so it
    // needs the same cross-phase cue ExperienceLevel/Gender carry. See startSwipeHint.
    @State private var hintOffset:       CGFloat            = 0
    @State private var hintTask:         Task<Void, Never>? = nil

    // Live hand-off follow (Phase 4c): the lifted card tracks the finger as it's handed up
    // (shared HandBackFollow). View-local; the controller owns deal offsets, so this
    // resolves to .zero inside the pocket flight on confirm.
    @State private var handBackDrag:         CGSize = .zero
    @State private var handBackArmed:        Bool   = false
    @State private var handBackSelectionGen = UISelectionFeedbackGenerator()

    // ── Cheat code button animation ──────────────────────────────────
    @State private var leftActiveButtons:      Set<Int> = []
    @State private var rightActiveButtons:     Set<Int> = []
    @State private var rightBackActiveButtons: Set<Int> = []
    @State private var cheatCodeTask:          Task<Void, Never>? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // ── Card dimensions ──────────────────────────────────────────────
    private var cardWidth: CGFloat {
        AppLayout.obTableCardWidth(in: screenSize.width) * AppLayout.obTableCardCinematicScale
    }
    private var cardHeight: CGFloat {
        AppLayout.obTableCardHeight(in: screenSize.width) * AppLayout.obTableCardCinematicScale
    }

    /// Upward tug distance for the swipe-up hint — proportional to card height so it
    /// scales across devices. Negative = upward. Mirrors the sibling phases. Felt value.
    private var hintFlickY: CGFloat { -cardHeight * 0.10 }

    // MARK: — Body

    var body: some View {
        ZStack {
            cardsLayer

            // NOTE: the projected dealer line is rendered once at the canvas level
            // (OnboardingCanvasView, projectedText layer). It is intentionally NOT
            // re-rendered here — a second copy at the same position composites the text
            // twice (doubled shadow/glow). The canvas-level render is the single source,
            // matching ExperienceLevelPhase.

            if let text = liftedText, let side = liftedSide {
                liftCopyLayer(text: text, side: side)
                    .transition(.opacity)
                    .zIndex(20)
            }
        }
        .frame(width: screenSize.width, height: screenSize.height)
        .sensoryFeedback(.selection, trigger: liftHaptic)
        .sensoryFeedback(.selection, trigger: deselectHaptic)
        .sensoryFeedback(.success,   trigger: deal.confirmHapticTrigger)
        .onAppear    { runEntrance() }
        .onDisappear {
            speechTask?.cancel()
            questionTask?.cancel()
            liftTextTask?.cancel()
            cheatCodeTask?.cancel()
            hintTask?.cancel()
            deal.cancel()
        }
    }

    // MARK: — Lift copy overlay

    private func liftCopyLayer(text: String, side: MirrorCard) -> some View {
        let title = side == .left ? "Just me for now" : "We're both here"

        return ZStack {
            VStack(spacing: AppSpacing.sm) {
                // Card title — LivingText
                LivingText(
                    text: title,
                    font: AppFonts.heroTitle
                )

                // Selection reflection — GradientText
                GradientText(
                    text: text,
                    font: AppFonts.sectionHeading
                )
                .multilineTextAlignment(.center)

                // Table border hairline
                Rectangle()
                    .frame(height: 0.75)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                .clear,
                                AppColors.spectrumCyan,
                                AppColors.spectrumPurple,
                                AppColors.spectrumMagenta,
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .opacity(0.55)
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.top, AppSpacing.xs)
            }
            .liftCopyGlow()
        }
        .position(x: screenSize.width / 2, y: screenSize.height * 0.16)
        .allowsHitTesting(false)
    }

    // MARK: — Cards

    private var cardsLayer: some View {
        ZStack {
            cardView(for: .left)
            cardView(for: .right)
        }
    }

    @ViewBuilder
    private func cardView(for side: MirrorCard) -> some View {
        let isSolo  = side == .left
        let content: VaylCardContent = isSolo
            ? .controller(activeButtons: leftActiveButtons)
            : .dualController(
                activeButtonsFront: rightActiveButtons,
                activeButtonsBack:  rightBackActiveButtons
              )
        let isLifted   = isCardLifted(side)
        let isRejected = isCardRejected(side)
        let offset     = side == .left ? deal.leftOffset     : deal.rightOffset
        let angle      = side == .left ? deal.leftAngle      : deal.rightAngle
        let scale      = side == .left ? deal.leftScale      : deal.rightScale
        let baseAlpha  = side == .left ? deal.leftAlpha      : deal.rightAlpha
        let alpha      = isRejected ? deal.rejectedExitAlpha : baseAlpha
        let showFace   = side == .left ? deal.leftShowFace   : deal.rightShowFace
        let flipScaleX = side == .left ? deal.leftFlipScaleX : deal.rightFlipScaleX
        let showBack   = isRejected ? deal.rejectedShowBack  : !showFace

        // Both faces stay mounted (pre-warm) so the illustration face doesn't cold-render
        // at the flip pivot — swapped by opacity at edge-on. Face stays inert until shown.
        ZStack {
            VaylCardBack()
                .drawingGroup()
                .frame(width: cardWidth, height: cardHeight)
                .allowsHitTesting(false)
                .opacity(showFace && !showBack ? 0 : 1)
            VaylCardFace(
                content:  content,
                onAction: { action in handleAction(action, from: side) }
            )
            .drawingGroup()
            .frame(width: cardWidth, height: cardHeight)
            .allowsHitTesting(showFace && !showBack && canInteract(side))
            .opacity(showFace && !showBack ? 1 : 0)
        }
        .overlay(LiftHalo(visible: isLifted))
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    // Don't mash the cheat code while lifted — that's the hand-off drag.
                    guard canInteract(side), !isCardLifted(side) else { return }
                    if cheatCodeTask == nil || cheatCodeTask!.isCancelled {
                        startCheatCode(for: side)
                    }
                }
                .onEnded { _ in stopCheatCode() }
        )
        .scaleEffect(x: flipScaleX * (showBack ? deal.rejectedFlipScaleX : 1.0), y: 1.0)
        .scaleEffect(scale)
        // Tilt + follow as the lifted card is handed up (shared HandBackFollow).
        .rotationEffect(.degrees(angle + (isLifted ? HandBackFollow.tilt(for: handBackDrag.width, screenWidth: screenSize.width) : 0)))
        .offset(CGSize(width: offset.width, height: offset.height + tugOffset(for: side)))
        .offset(isLifted ? handBackDrag : .zero)
        .opacity(alpha)
        .zIndex(isLifted ? 10 : side == .right ? 6 : 4)
    }

    // MARK: — State helpers

    private func isCardLifted(_ side: MirrorCard) -> Bool {
        if case .lifted(let c) = deal.state { return c == side }
        return false
    }

    /// y-offset contribution from the swipe-up tug for `side` — only the currently
    /// lifted card tugs. Reads `deal.state`, so the tug auto-follows when the user
    /// switches the lifted card (no restart needed).
    private func tugOffset(for side: MirrorCard) -> CGFloat {
        isCardLifted(side) ? hintOffset : 0
    }

    private func isCardRejected(_ side: MirrorCard) -> Bool {
        if case .exiting(let confirmed) = deal.state { return confirmed != side }
        if case .done(let selected)     = deal.state { return selected   != side }
        return false
    }

    private func canInteract(_ side: MirrorCard) -> Bool {
        switch deal.state {
        case .faceUp: return questionAsked
        case .lifted: return true
        default:      return false
        }
    }

    // MARK: — Action handler

    private func handleAction(_ action: VaylCardAction, from side: MirrorCard) {
        switch action {
        case .tapped:
            switch deal.state {
            case .faceUp:
                stopCheatCode()
                withAnimation(AppAnimation.cardLift.reduceMotionSafe) { deal.lift(card: side) }
                liftHaptic.toggle()
                speechTask?.cancel()
                director.projector.hideDealerLine()
                scheduleLiftText(for: side)
                // Cue the confirm gesture — the lifted card tugs upward (the tug
                // auto-follows on switchLift since tugOffset reads deal.state).
                startSwipeHint()
            case .lifted(let current):
                if current != side {
                    stopCheatCode()
                    withAnimation(AppAnimation.cardLift.reduceMotionSafe) { deal.switchLift(to: side) }
                    deselectHaptic.toggle()
                    liftTextTask?.cancel()
                    withAnimation(AppAnimation.fast) { liftedText = nil; liftedSide = nil }
                    scheduleLiftText(for: side)
                }
                // Second tap on already-lifted card — do nothing. Swipe up confirms.
            default:
                break
            }

        case .dragChanged(let translation):
            // Live hand-off follow — only the lifted card tracks the finger.
            guard case .lifted(let current) = deal.state, current == side else { return }
            handBackDrag = HandBackFollow.offset(for: translation, cardWidth: cardWidth, cardHeight: cardHeight)
            let crossed = translation.height < -cardHeight * 0.14
            if crossed != handBackArmed { handBackArmed = crossed; handBackSelectionGen.selectionChanged() }

        case .dragEnded:
            // Released short of the commit threshold — settle the card back to the lift anchor.
            guard case .lifted = deal.state else { return }
            handBackArmed = false
            withAnimation(AppAnimation.cardSettle.reduceMotionSafe) { handBackDrag = .zero }

        case .swipedUp:
            guard case .lifted(let current) = deal.state, current == side else { return }
            handBackArmed = false
            stopSwipeHint()
            // Drift + tilt resolve INTO the pocket flight — no snap at the handoff.
            withAnimation(AppAnimation.cardPocket.reduceMotionSafe) { handBackDrag = .zero }
            deal.confirm(
                card:       side,
                screenSize: screenSize,
                cardWidth:  cardWidth,
                onLanded: { confirmedCard in
                    // Confirmed card has visually arrived at the corner deck (~520ms after swipe).
                    // Credit the deck now — count updates as the card lands, not after.
                    director.receiveCredential(.mode)

                    // Set appMode now — data is ready, rejected card is still exiting.
                    let mode: AppMode = confirmedCard == .left ? .solo : .together
                    director.onboardingData.appMode = mode
                },
                onConfirm: { confirmedCard in
                    // Rejected card has fully exited (~940ms after swipe). Clean up UI and advance.
                    liftTextTask?.cancel()
                    withAnimation(AppAnimation.fast) { liftedText = nil; liftedSide = nil }
                    director.projector.hideDealerLine()
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(180))
                        director.advance(to: .gender)
                    }
                }
            )

        default:
            break
        }
    }

    // MARK: — Entrance

    @MainActor
    private func runEntrance() {
        guard !hasDealt else { return }
        hasDealt = true

        if reduceMotion {
            speechTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(400))
                let tableY = AppLayout.obTableCardCenterY(in: screenSize.height)
                let restY  = tableY - screenSize.height / 2
                deal.leftOffset  = CGSize(width: -(cardWidth * 0.38), height: restY)
                deal.rightOffset = CGSize(width:  (cardWidth * 0.38), height: restY)
                deal.leftAngle   = -3; deal.rightAngle = 3
                deal.leftAlpha   = 1;  deal.rightAlpha = 1
                deal.leftShowFace = true; deal.rightShowFace = true
                deal.state       = .faceUp
                askQuestion()
            }
            return
        }

        // Table breathes before cards arrive — a beat, not a wait. The dealer
        // line fires from the controller's onFaceUp, so the question types
        // onto settled face-up cards instead of competing with the flips.
        speechTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            deal.deal(screenSize: screenSize, cardWidth: cardWidth) {
                askQuestion()
            }
        }
    }

    /// Shows the phase question once and opens the interaction gate when it has
    /// finished typing (+ a read beat: 500ms, or 250ms under Reduce Motion). The
    /// line then persists until the user picks a card (handleAction hides it on
    /// tap) — it's the only label on the deliberately label-free cards, so it must
    /// not auto-hide out from under a deliberating user.
    @MainActor
    private func askQuestion() {
        guard !questionShown else { return }
        questionShown = true
        let line = "How are you exploring?"
        director.projector.showDealerLineManual(line)
        let gateMs = reduceMotion ? 250 : AppDealerTyping.typeDuration(line) + 500
        // Own handle (not speechTask) — reusing speechTask orphaned the deal task's
        // handle, so an interrupted deal→question handoff couldn't be cancelled and
        // could project a stale line into the next phase.
        questionTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(gateMs))
            guard !Task.isCancelled else { return }
            questionAsked = true
            // Auto-select couples (the right card) as the default — couples-first. The
            // lifted card is the cue; the user taps the solo card to switch, or swipes up
            // to confirm. Skip if they already tapped during the question.
            guard case .faceUp = deal.state else { return }
            stopCheatCode()
            withAnimation(AppAnimation.cardLift.reduceMotionSafe) { deal.lift(card: .right) }
            liftHaptic.toggle()
            director.projector.hideDealerLine()
            scheduleLiftText(for: .right)
            startSwipeHint()
        }
    }

    // MARK: — Lift text

    private func scheduleLiftText(for side: MirrorCard) {
        liftTextTask?.cancel()
        liftTextTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(120))
            guard !Task.isCancelled else { return }
            let text = side == .left
                ? "Starting on my own — for now."
                : "We're doing this together."
            withAnimation(AppAnimation.standard) {
                liftedText = text
                liftedSide = side
            }
        }
    }

    // MARK: — Swipe-up hint (consistent cross-phase cue)

    /// Intermittent upward tug on the lifted card: flick up → spring home → rest → repeat.
    /// Mirrors ExperienceLevelPhase / GenderPhase so the confirm gesture reads the same
    /// everywhere. Cadence lives in Task.sleep (not animation tokens) per the codebase pattern.
    /// ModeSelect is an early reuse (the user has swiped up only once, in Name), so it uses a
    /// more frequent reminder than ExperienceLevel's sparse lifted-state cadence.
    private func startSwipeHint(initialDelayMs: UInt64 = 600, restMs: UInt64 = 1900) {
        hintTask?.cancel()
        guard !reduceMotion else {
            withAnimation(AppAnimation.spring.reduceMotionSafe) { hintOffset = 0 }
            return
        }
        hintOffset = 0
        hintTask = Task { @MainActor in
            // Let the lift settle before the first tug.
            try? await Task.sleep(for: .milliseconds(initialDelayMs))
            while !Task.isCancelled {
                withAnimation(AppAnimation.swipeHintFlick) { hintOffset = hintFlickY }
                try? await Task.sleep(for: .milliseconds(380))
                guard !Task.isCancelled else { break }
                withAnimation(AppAnimation.spring) { hintOffset = 0 }
                try? await Task.sleep(for: .milliseconds(restMs))
                guard !Task.isCancelled else { break }
            }
        }
    }

    private func stopSwipeHint() {
        hintTask?.cancel()
        withAnimation(AppAnimation.spring.reduceMotionSafe) { hintOffset = 0 }
    }

    // MARK: — Cheat code

    private let cheatSequence: [Set<Int>] = [
        [0],        // top
        [1],        // right
        [2],        // bottom
        [3],        // left
        [0, 2],     // top + bottom
        [1, 3],     // right + left
        [],         // clear — brief dark moment before loop
    ]

    @MainActor
    private func startCheatCode(for side: MirrorCard) {
        cheatCodeTask?.cancel()
        cheatCodeTask = Task { @MainActor in
            var step = 0
            while !Task.isCancelled {
                let buttons     = cheatSequence[step % cheatSequence.count]
                let backButtons = cheatSequence[(step + 2) % cheatSequence.count]
                switch side {
                case .left:
                    leftActiveButtons = buttons
                case .right:
                    rightActiveButtons     = buttons
                    rightBackActiveButtons = backButtons
                }
                try? await Task.sleep(for: .milliseconds(80))
                step += 1
            }
        }
    }

    @MainActor
    private func stopCheatCode() {
        cheatCodeTask?.cancel()
        cheatCodeTask          = nil
        leftActiveButtons      = []
        rightActiveButtons     = []
        rightBackActiveButtons = []
    }

}
