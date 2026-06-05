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
    @State private var liftTextTask:     Task<Void, Never>? = nil
    @State private var liftedText:       String?       = nil
    @State private var liftedSide:       MirrorCard?   = nil
    @State private var hasDealt:         Bool         = false
    @State private var liftHaptic:       Bool         = false
    @State private var deselectHaptic:   Bool         = false

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

    // MARK: — Body

    var body: some View {
        ZStack {
            cardsLayer

            if director.projectedTextVisible, let copy = director.projectedText {
                ProjectedTextView(text: copy, screenSize: screenSize)
                    .transition(.opacity.combined(with: .offset(y: -6)))
                    .zIndex(18)
            }

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
            liftTextTask?.cancel()
            cheatCodeTask?.cancel()
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

        Group {
            if showFace && !showBack {
                VaylCardFace(
                    content:  content,
                    onAction: { action in handleAction(action, from: side) }
                )
                .drawingGroup()
                .frame(width: cardWidth, height: cardHeight)
                .allowsHitTesting(canInteract(side))
            } else {
                VaylCardBack()
                    .drawingGroup()
                    .frame(width: cardWidth, height: cardHeight)
                    .allowsHitTesting(false)
            }
        }
        .overlay(
            ZStack {
                // Halo — blurred spectrum stroke, outward bleed only
                RoundedRectangle(cornerRadius: AppRadius.obCard)
                    .stroke(
                        LinearGradient(
                            colors: [AppColors.spectrumCyan, AppColors.spectrumPurple, AppColors.spectrumMagenta],
                            startPoint: .topLeading,
                            endPoint:   .bottomTrailing
                        ),
                        lineWidth: AppGlows.spectrumBorder.strokeActive
                    )
                    .blur(radius: 7)
                    .opacity(isLifted ? 0.50 : 0)

                // Crisp border stroke with layered spectrum glow
                RoundedRectangle(cornerRadius: AppRadius.obCard)
                    .stroke(
                        LinearGradient(
                            colors: [AppColors.spectrumCyan, AppColors.spectrumPurple, AppColors.spectrumMagenta],
                            startPoint: .topLeading,
                            endPoint:   .bottomTrailing
                        ),
                        lineWidth: AppGlows.spectrumBorder.strokeGlowing
                    )
                    .opacity(isLifted ? 0.92 : 0)
                    .spectrumBorderGlow(intensity: isLifted ? 0.72 : 0)
            }
            .animation(AppAnimation.standard, value: isLifted)
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard canInteract(side) else { return }
                    if cheatCodeTask == nil || cheatCodeTask!.isCancelled {
                        startCheatCode(for: side)
                    }
                }
                .onEnded { _ in stopCheatCode() }
        )
        .scaleEffect(x: flipScaleX * (showBack ? deal.rejectedFlipScaleX : 1.0), y: 1.0)
        .scaleEffect(scale)
        .rotationEffect(.degrees(angle))
        .offset(offset)
        .opacity(alpha)
        .zIndex(isLifted ? 10 : side == .right ? 6 : 4)
    }

    // MARK: — State helpers

    private func isCardLifted(_ side: MirrorCard) -> Bool {
        if case .lifted(let c) = deal.state { return c == side }
        return false
    }

    private func isCardRejected(_ side: MirrorCard) -> Bool {
        if case .exiting(let confirmed) = deal.state { return confirmed != side }
        if case .done(let selected)     = deal.state { return selected   != side }
        return false
    }

    private func canInteract(_ side: MirrorCard) -> Bool {
        switch deal.state {
        case .faceUp: return true
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
                withAnimation(AppAnimation.cardLift) { deal.lift(card: side) }
                liftHaptic.toggle()
                speechTask?.cancel()
                director.hideDealerLine()
                scheduleLiftText(for: side)
            case .lifted(let current):
                if current != side {
                    stopCheatCode()
                    withAnimation(AppAnimation.cardLift) { deal.switchLift(to: side) }
                    deselectHaptic.toggle()
                    liftTextTask?.cancel()
                    withAnimation(AppAnimation.fast) { liftedText = nil; liftedSide = nil }
                    scheduleLiftText(for: side)
                }
                // Second tap on already-lifted card — do nothing. Swipe up confirms.
            default:
                break
            }

        case .swipedUp:
            guard case .lifted(let current) = deal.state, current == side else { return }
            deal.confirm(
                card:       side,
                screenSize: screenSize,
                cardWidth:  cardWidth,
                onLanded: { confirmedCard in
                    // Confirmed card has visually arrived at the corner deck (~740ms after swipe).
                    // Append the model and pulse now — count updates as the card lands, not after.
                    let modeCard = VaylCardModel()
                    modeCard.credential = .mode
                    director.cornerDeckCards.append(modeCard)
                    withAnimation(AppAnimation.deckReceive) { director.deckPulse = true }
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(600))
                        director.deckPulse = false
                    }

                    // Set appMode now — data is ready, rejected card is still exiting.
                    let mode: AppMode = confirmedCard == .left ? .solo : .together
                    director.onboardingData.appMode = mode
                },
                onConfirm: { confirmedCard in
                    // Rejected card has fully exited (~1160ms after swipe). Clean up UI and advance.
                    liftTextTask?.cancel()
                    withAnimation(AppAnimation.fast) { liftedText = nil; liftedSide = nil }
                    director.hideDealerLine()
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
                director.showDealerLineManual("Anyone at the table with you?")
                scheduleLineFade()
            }
            return
        }

        speechTask = Task { @MainActor in
            // Table breathes before cards arrive
            try? await Task.sleep(for: .milliseconds(800))
            guard !Task.isCancelled else { return }
            deal.deal(screenSize: screenSize, cardWidth: cardWidth)
            // Dealer line after deal completes (~880ms deal + buffer)
            try? await Task.sleep(for: .milliseconds(1180))
            guard !Task.isCancelled else { return }
            director.showDealerLineManual("Anyone at the table with you?")
            scheduleLineFade()
        }
    }

    private func scheduleLineFade() {
        speechTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(3000))
            guard !Task.isCancelled else { return }
            director.hideDealerLine()
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
