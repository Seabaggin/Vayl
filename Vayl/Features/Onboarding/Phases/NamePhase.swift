// Vayl/Features/Onboarding/Phases/NamePhase.swift

import SwiftUI

private enum CardDealPhase: Equatable {
    case idle
    case swiping
    case resting
    case flipping
    case pausing
    case nameInput
    case collecting
}

struct NamePhase: View {

    let director:    VaylDirector
    let screenSize:  CGSize
    @Binding var tableRimBurst: Double

    // MARK: — Task handles

    @State private var dealTask:         Task<Void, Never>? = nil
    @State private var inputFocusTask:   Task<Void, Never>? = nil
    @State private var keyAnimationTask: Task<Void, Never>? = nil
    @State private var dealerTypingTask: Task<Void, Never>? = nil

    // MARK: — Dealer typing

    @State private var dealerDisplayed: String  = ""
    @State private var dealerAlpha:     Double  = 0.0
    @State private var dealerOffsetY:   CGFloat = 0.0

    // MARK: — Card animation

    @State private var dealPhase:       CardDealPhase = .idle
    @State private var cardOffset:      CGSize        = .zero
    @State private var cardAngle:       Double        = 0
    @State private var cardAlpha:       Double        = 0
    @State private var flipScaleX:      Double        = 1.0
    @State private var showFace:        Bool          = false
    @State private var cardScale:       Double        = 1.0
    @State private var cardScreenAlpha: Double        = 1.0

    // MARK: — Effects

    @State private var impactRingProgress: Double = 0
    @State private var flipBurstProgress:  Double = 0

    // MARK: — Typewriter

    @State private var activeKeyIndex:   Int     = -1
    @State private var carriageProgress: CGFloat = 0

    // MARK: — Name input

    @State private var name:    String = ""
    @State private var uiAlpha: Double = 0

    @State private var lineRevealProgress: CGFloat = 0
    @State private var hasSweptLine:       Bool    = false
    @State private var lineBounce:         CGFloat = 0

    // MARK: — Card return demo (post-name submission)
    //
    // After the greeting fades and the card flips back, the dealer asks for the
    // card back. The card demonstrates swipe-up twice, then waitingForCardReturn
    // enables the gesture. This is the gesture tutorial for the whole flow —
    // every subsequent phase closes the same way.

    @State private var waitingForCardReturn:  Bool    = false
    @State private var cardReturnHintOffset:  CGFloat = 0
    // Guided lesson: the dealer says "pick it up" → tap lifts the card (same LiftHalo
    // the selection phases use) → "slide it up to me" → swipe. waitingForCardLift gates
    // the tap; cardLifted drives the shared lift affordance.
    @State private var waitingForCardLift:    Bool    = false
    @State private var cardLifted:            Bool    = false
    @State private var liftTeachTask: Task<Void, Never>? = nil

    // MARK: — Beat 3 greeting

    @State private var showGreeting:  Bool   = false
    @State private var greetingName:  String = ""
    @State private var greetingAlpha: Double = 0.0
    @State private var nameVisible:   Bool   = false

    @State private var impactSoft   = UIImpactFeedbackGenerator(style: .soft)
    @State private var impactMedium = UIImpactFeedbackGenerator(style: .medium)
    @State private var impactHeavy  = UIImpactFeedbackGenerator(style: .heavy)

    @FocusState private var nameFieldFocused: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.displayScale)              private var displayScale

    private var cardWidth: CGFloat {
        AppLayout.obTableCardWidth(in: screenSize.width) * AppLayout.obTableCardCinematicScale
    }
    private var cardHeight: CGFloat {
        AppLayout.obTableCardHeight(in: screenSize.width) * AppLayout.obTableCardCinematicScale
    }

    // MARK: — Body

    var body: some View {
        ZStack {
            // Layer 1 — always present
            effectsLayer

            // Layer 2 — always present
            cardLayer()

            // Layer 3 — dealer copy, one line at a time via shuffle transitions.
            // Always mounted (empty Text renders nothing) — gating on
            // dealerDisplayed unmounted the view during shuffleEnterDealer,
            // so the 0.2s slide-in animated nothing and lines popped in.
            dealerCopyView

            // Layer 4 — Beat 3 greeting (replaces dealer copy after submit)
            if showGreeting {
                greetingView
            }

            // Layer 5 — name input, fades in after Beat 2 types
            if dealPhase == .nameInput || dealPhase == .collecting {
                dealerZone
                    .opacity(uiAlpha)
            }

        }
        .frame(width: screenSize.width, height: screenSize.height)
        .gesture(
            DragGesture()
                .onChanged { _ in }
                .onEnded { v in
                    handleSwipe(v.translation)
                }
        )
        .onAppear {
            director.hideDealerLine()   // clear any canvas line carried over from Demo's exit
            dealTask = Task { await runDealerIntro() }
        }
        .onDisappear {
            dealerTypingTask?.cancel()
            dealerTypingTask = nil
            dealTask?.cancel()
            liftTeachTask?.cancel()
            liftTeachTask = nil
            inputFocusTask?.cancel()
            inputFocusTask = nil
            keyAnimationTask?.cancel()
            keyAnimationTask = nil
            waitingForCardReturn  = false
            waitingForCardLift    = false
            cardLifted            = false
            cardReturnHintOffset  = 0
        }
    }

    // MARK: — Effects layer

    private var effectsLayer: some View {
        Canvas { context, size in
            let cx = size.width  / 2 + cardOffset.width
            let cy = size.height / 2 + cardOffset.height

            if impactRingProgress > 0 {
                let ringW     = cardWidth * 1.1 + (cardWidth * 2.2) * impactRingProgress
                let ringH     = ringW * 0.23
                let ringAlpha = (1.0 - impactRingProgress) * 0.55
                guard ringAlpha > 0 else { return }

                var ringPath = Path()
                ringPath.addEllipse(in: CGRect(
                    x: cx - ringW / 2,
                    y: cy + cardHeight * 0.48 - ringH / 2,
                    width:  ringW,
                    height: ringH
                ))
                context.stroke(
                    ringPath,
                    with: .color(AppColors.spectrumPurple.opacity(ringAlpha)),
                    lineWidth: 1.0
                )
            }

            if flipBurstProgress > 0 {
                let burstR     = max(cardWidth, cardHeight) * 1.8 * flipBurstProgress
                let burstAlpha = (1.0 - flipBurstProgress) * 0.45
                guard burstAlpha > 0 else { return }

                context.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .radialGradient(
                        Gradient(stops: [
                            .init(color: AppColors.spectrumPurple.opacity(burstAlpha),      location: 0),
                            .init(color: AppColors.spectrumCyan.opacity(burstAlpha * 0.45), location: 0.45),
                            .init(color: AppColors.spectrumCyan.opacity(0),                 location: 1),
                        ]),
                        center:      CGPoint(x: cx, y: cy),
                        startRadius: 0,
                        endRadius:   burstR
                    )
                )
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }

    // MARK: — Card layer

    private func cardLayer() -> some View {
        Group {
            if !showFace {
                VaylCardBack()
            } else {
                VaylCardFace(content: .typewriter(
                    activeKey:        activeKeyIndex,
                    carriageProgress: carriageProgress
                ))
            }
        }
        .drawingGroup()
        .frame(width: cardWidth, height: cardHeight)
        // Shared lift affordance — the exact spectrum ring the selection phases use,
        // so the gesture the dealer teaches here transfers to them by sight.
        // The lift itself is driven through cardOffset/cardScale (see handleLiftTap),
        // matching ThreeCardFanController.lift — y 0.42, scale 1.12, on cardLift.
        .overlay(LiftHalo(visible: cardLifted))
        .scaleEffect(x: flipScaleX, y: 1.0)
        .scaleEffect(cardScale)
        .rotationEffect(.degrees(cardAngle))
        .offset(cardOffset)
        // Return-demo drift — upward hint applied on top of positional offset
        .offset(y: cardReturnHintOffset)
        .opacity(cardAlpha * cardScreenAlpha)
        // Tap the card to pick it up (only live during the guided lesson; a drag
        // still bubbles to the screen-level swipe handler).
        .onTapGesture { handleLiftTap() }
    }

    // MARK: — Dealer zone (name input — no header)
    //
    // Beat 2 "Let's get acquainted." remains visible in dealerCopyView
    // while this input zone is shown. The two layers coexist intentionally.
    // dealerZone is positioned at 0.30 — below the Beat 2 copy at 0.22,
    // above the card center at 0.55. submitName() clears the copy instantly.

    private var dealerZone: some View {
        VStack(alignment: .center, spacing: AppSpacing.md) {
            TextField(
                "",
                text: $name,
                prompt: Text("Enter name")
                    .font(AppFonts.display(28, weight: .semibold, relativeTo: .title))
                    .foregroundColor(AppColors.textTertiary)
            )
            .font(AppFonts.display(28, weight: .semibold, relativeTo: .title))
            .foregroundStyle(AppColors.textPrimary)
            .tint(name.isEmpty ? .clear : AppColors.accentPrimary)
            .multilineTextAlignment(.center)
            .focused($nameFieldFocused)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .submitLabel(.done)
            .onSubmit {
                nameFieldFocused = false
                submitName()
            }
            .onChange(of: name) { _, newValue in
                // ── Length guard ──────────────────────────────────
                let trimmed = newValue.trimmingCharacters(in: .whitespaces)
                if trimmed.count > AppLayout.maxNameLength {
                    name = String(trimmed.prefix(AppLayout.maxNameLength))
                }

                // ── Typewriter keystroke animation ────────────────
                let isSpace = newValue.last == " "
                carriageProgress = CGFloat(newValue.count) / CGFloat(AppLayout.maxNameLength)
                activeKeyIndex = isSpace
                    ? 15
                    : (newValue.count > 0 ? (newValue.count - 1) % 15 : -1)

                keyAnimationTask?.cancel()
                keyAnimationTask = Task {
                    try? await Task.sleep(for: .milliseconds(120))
                    guard !Task.isCancelled else { return }
                    await MainActor.run { activeKeyIndex = -1 }
                }

                // ── Write line bounce ─────────────────────────────
                // Single self-settling spring — the old asyncAfter(0.08) settle
                // fired uncancelled after teardown on a fast submit.
                lineBounce = -3.0
                withAnimation(.interpolatingSpring(stiffness: 320, damping: 16)) {
                    lineBounce = 0
                }

                // No auto-submit — user commits via Done key or swipe up.
            }
            .onChange(of: nameFieldFocused) { _, isFocused in
                if isFocused && !hasSweptLine {
                    hasSweptLine = true
                    withAnimation(.easeOut(duration: 0.45)) {
                        lineRevealProgress = 1.0
                    }
                } else if isFocused {
                    lineRevealProgress = 1.0
                }
            }
            .overlay(alignment: .bottom) {
                ZStack {
                    // Spectrum hairline — 1.5pt rule
                    Rectangle()
                        .fill(AnyShapeStyle(AppColors.spectrumBorder))
                        .frame(height: 1.5)

                    // Glow layer 1 — tight
                    Rectangle()
                        .fill(LinearGradient(
                            colors: [
                                AppColors.accentPrimary.opacity(0.6),
                                AppColors.accentSecondary.opacity(0.9),
                                AppColors.accentTertiary.opacity(0.8),
                                AppColors.accentPrimary.opacity(0.6),
                            ],
                            startPoint: .leading,
                            endPoint:   .trailing
                        ))
                        .frame(height: 3)
                        .blur(radius: 4)

                    // Glow layer 2 — wide soft bloom
                    Rectangle()
                        .fill(LinearGradient(
                            colors: [
                                AppColors.accentPrimary.opacity(0.2),
                                AppColors.accentSecondary.opacity(0.35),
                                AppColors.accentTertiary.opacity(0.3),
                                AppColors.accentPrimary.opacity(0.2),
                            ],
                            startPoint: .leading,
                            endPoint:   .trailing
                        ))
                        .frame(height: 8)
                        .blur(radius: 6)
                }
                .frame(width: cardWidth)
                .scaleEffect(x: lineRevealProgress, anchor: .leading)
                .offset(y: lineBounce)
            }
        }
        .frame(width: cardWidth)
        .position(
            x: screenSize.width  / 2,
            y: screenSize.height * 0.30
        )
    }

    // MARK: — Dealer copy view

    /// Vertical anchor for the dealer copy. At rest it sits at 0.22; once the card is
    /// lifted (the swipe-up step) it rises to 0.16 — the same anchor the selection phases
    /// (ModeSelect / ExperienceLevel) use for their lift copy — so it clears the hovered
    /// card and the lesson matches what those phases do by sight. Animates in sync with
    /// the lift because `cardLifted` flips inside the cardLift withAnimation.
    private var dealerCopyY: CGFloat {
        cardLifted ? screenSize.height * 0.16 : screenSize.height * 0.22
    }

    private var dealerCopyView: some View {
        Text(dealerDisplayed)
            .font(AppDealerTyping.font)
            .foregroundStyle(AppColors.textPrimary)
            .multilineTextAlignment(.center)
            .frame(width: screenSize.width * 0.82)
            .opacity(dealerAlpha)
            .offset(y: dealerOffsetY)
            .position(
                x: screenSize.width / 2,
                y: dealerCopyY
            )
    }

    // MARK: — Beat 3 greeting view
    //
    // Occupies the same Y anchor as dealerCopyView (0.22).
    // Shown after submitName() clears the dealer copy.
    // "Welcome to the table," and "." are static Volkhov lines.
    // The name line fades in separately after a 200ms breath.

    private var greetingView: some View {
        VStack(spacing: AppSpacing.xs) {
            Text("Welcome to the table,")
                .font(AppDealerTyping.font)
                .foregroundStyle(AppColors.textPrimary)

            if nameVisible {
                Text(greetingName)
                    .font(AppFonts.display(28, weight: .bold, relativeTo: .title))
                    .foregroundStyle(AppColors.spectrumText)
                    .transition(.opacity)
            }

        
        }
        .opacity(greetingAlpha)
        .position(
            x: screenSize.width / 2,
            y: screenSize.height * 0.22
        )
    }

    // MARK: — Typing engine

    @MainActor
    private func typeDealerLine(_ text: String) async {
        var prev: Character? = nil
        for char in text {
            guard !Task.isCancelled else { return }
            let delay = AppDealerTyping.charDelay(char, prev: prev)
            try? await Task.sleep(for: .milliseconds(Int(delay)))
            guard !Task.isCancelled else { return }
            dealerDisplayed.append(char)
            prev = char
        }
    }

    // MARK: — Shuffle transitions

    @MainActor
    private func shuffleExitDealer() async {
        withAnimation(AppDealerTyping.shuffleExitAnim) {
            dealerAlpha   = 0.0
            dealerOffsetY = -22
        }
        try? await Task.sleep(for: .milliseconds(AppDealerTyping.shuffleExitMs))
        guard !Task.isCancelled else { return }
        dealerDisplayed = ""
        dealerOffsetY   = 0
    }

    /// Gentle exit for the lift-lesson prompt: the line drifts up and fades on a long
    /// ease-out so it "floats away," rather than snapping out like the shuffle swap.
    @MainActor
    private func floatAwayDealer() async {
        withAnimation(AppDealerTyping.floatAwayAnim) {
            dealerAlpha   = 0.0
            dealerOffsetY = AppDealerTyping.floatAwayDrift
        }
        try? await Task.sleep(for: .milliseconds(AppDealerTyping.floatAwayMs))
        guard !Task.isCancelled else { return }
        dealerDisplayed = ""
        dealerOffsetY   = 0
    }

    @MainActor
    private func shuffleEnterDealer() async {
        dealerAlpha   = 0.0
        dealerOffsetY = -18
        try? await Task.sleep(for: .milliseconds(AppDealerTyping.shuffleGapMs))
        guard !Task.isCancelled else { return }
        withAnimation(AppDealerTyping.shuffleEnterAnim) {
            dealerAlpha   = 1.0
            dealerOffsetY = 0
        }
        // Short beat, NOT the full enter duration — the first characters type
        // while the container is still gliding in, so the entrance reads as
        // motion. Waiting the slide out meant it animated an empty Text.
        try? await Task.sleep(for: .milliseconds(AppDealerTyping.shuffleGapMs))
    }

    @MainActor
    private func fadeFinalDealer() async {
        withAnimation(AppDealerTyping.finalFadeAnim) {
            dealerAlpha = 0.0
        }
        try? await Task.sleep(for: .milliseconds(AppDealerTyping.finalFadeMs))
        guard !Task.isCancelled else { return }
        dealerDisplayed = ""
        dealerAlpha     = 1.0
    }

    // MARK: — Dealer intro sequence

    @MainActor
    private func runDealerIntro() async {
        try? await Task.sleep(for: .milliseconds(500))
        guard !Task.isCancelled else { return }

        // ── Card deals while Line 1 types ─────────────
        Task { await dealCard() }
        
        dealerDisplayed = ""
        await shuffleEnterDealer()
        guard !Task.isCancelled else { return }
        await typeDealerLine("That's a good place to begin.")
        guard !Task.isCancelled else { return }
        
        // Wait a short breath after typing.
        try? await Task.sleep(for: .milliseconds(AppDealerTyping.hangShort))
        guard !Task.isCancelled else { return }

        await centerCard()
        try? await Task.sleep(for: .milliseconds(420))
        guard !Task.isCancelled else { return }
        await performFlipWithBurst()
        guard !Task.isCancelled else { return }

        // 300ms — typewriter face briefly visible before Line 2
        try? await Task.sleep(for: .milliseconds(300))
        guard !Task.isCancelled else { return }

        // ── Beat 2 dealer copy ────────────────────────────────────
        await shuffleExitDealer()
        guard !Task.isCancelled else { return }
        
        await shuffleEnterDealer()
        guard !Task.isCancelled else { return }
        await typeDealerLine("Let's get acquainted.")
        guard !Task.isCancelled else { return }
        try? await Task.sleep(for: .milliseconds(AppDealerTyping.hangShort))
        guard !Task.isCancelled else { return }

        // ── Inline name input entry ───────────────────────────────
        // Beat 2 copy remains visible at 0.22.
        // TextField rises at 0.30 — 56pt clear of the copy bottom.
        dealPhase = .nameInput
        // (Removed director.gender.placeCardSilently — a cross-phase reach into the
        // gender sequencer that wrote a pendingCard nothing ever reads. GenderPhase
        // crystallises its card from dissolution state, not pendingCard.)
        withAnimation(.easeOut(duration: 0.52)) { uiAlpha = 1.0 }
        impactHeavy.prepare()
        impactSoft.prepare()
        try? await Task.sleep(for: .milliseconds(200))
        guard !Task.isCancelled else { return }
        nameFieldFocused = true
    }

    // MARK: — Card deal

    @MainActor
    private func dealCard() async {
        guard !reduceMotion else {
            cardAlpha = 1
            dealPhase = .resting
            await fadeFinalDealer()
            await centerCard()
            return
        }

        // Card-flight physics now lives in CardFlightEngine (via the director). This
        // phase only triggers the deal and applies the rested transform to its card.
        dealPhase = .swiping
        cardAlpha = 0

        guard let deal = await director.dealSingleCard(screenSize: screenSize, scale: displayScale) else { return }
        guard !Task.isCancelled else { return }

        // Handoff SpriteKit → SwiftUI
        dealPhase  = .resting
        cardOffset = deal.offset
        cardAngle  = deal.angle
        cardAlpha  = 1
        // One frame overlap to eliminate the SpriteKit → SwiftUI flash
        try? await Task.sleep(for: .milliseconds(32))
        director.cardFlightScene.clearCard(id: deal.flightID)
    }

    @MainActor
    private func centerCard() async {
        let tableCenter = CGPoint(
            x: screenSize.width  * 0.50,
            y: screenSize.height * 0.55
        )
        withAnimation(AppAnimation.cardCenter) {
            cardOffset = CGSize(
                width:  tableCenter.x - screenSize.width  / 2,
                height: tableCenter.y - screenSize.height / 2
            )
            cardAngle = 0
        }
    }

    // MARK: — Flip mechanics

    @MainActor
    private func performFlipWithBurst() async {
        dealPhase = .flipping
        fireImpactRing()
        tableRimBurst = 1.0
        withAnimation(AppAnimation.rimBurstDecay) { tableRimBurst = 0.0 }
        await performFlip()
    }

    @MainActor
    private func performFlip() async {
        withAnimation(AppAnimation.cardFlipHalf) {
            flipScaleX = 0.0
        }
        try? await Task.sleep(for: .milliseconds(290))
        guard !Task.isCancelled else { return }

        showFace = true

        withAnimation(AppAnimation.cardFlipHalf) {
            flipScaleX = -1.0
        }
        try? await Task.sleep(for: .milliseconds(290))
    }

    @MainActor
    private func performFlipBack() async {
        if reduceMotion {
            showFace   = false
            flipScaleX = 1.0
            return
        }
        withAnimation(AppAnimation.cardFlipHalf) {
            flipScaleX = 0.0
        }
        try? await Task.sleep(for: .milliseconds(290))

        showFace = false

        withAnimation(AppAnimation.cardFlipHalf) {
            flipScaleX = 1.0
        }
        try? await Task.sleep(for: .milliseconds(290))
    }

    // MARK: — Card collect

    @MainActor
    private func performCardCollect() async {
        let cornerX = screenSize.width  - AppLayout.cornerDeckRight - AppLayout.cornerDeckWidth  / 2
        let cornerY = AppLayout.cornerDeckTop + AppLayout.cornerDeckHeight / 2

        withAnimation(AppAnimation.cardPocket) {
            cardOffset = CGSize(
                width:  cornerX - screenSize.width  / 2,
                height: cornerY - screenSize.height / 2
            )
            cardScale = AppLayout.cornerDeckWidth / cardWidth
        }
        // Alpha rides its own late curve: the card stays visible for ~90% of
        // the travel and dissolves INTO the deck. Fading alongside the whole
        // flight made it vanish in ~0.15s — the handoff never visibly arrived.
        withAnimation(.easeIn(duration: 0.2).delay(0.32)) {
            cardAlpha = 0
        }

        // Pulse the deck as the card lands (travel ends at 520ms), not before.
        try? await Task.sleep(for: .milliseconds(480))

        director.receiveCredential(.name)
    }

    // MARK: — Effects helpers

    @MainActor
    private func fireImpactRing() {
        impactRingProgress = 0
        withAnimation(AppAnimation.impactRingDecay) {
            impactRingProgress = 1.0
        }
    }

    @MainActor
    private func fireFlipBurst() {
        flipBurstProgress = 0
        withAnimation(AppAnimation.flipBurstDecay) {
            flipBurstProgress = 1.0
        }
    }

    // MARK: — Swipe handler
    //
    // Handles two distinct swipe-up moments:
    //   1. During nameInput  — upward swipe submits the name (matches all other phase gestures).
    //   2. waitingForCardReturn — upward swipe gives the card to the dealer and advances.
    //
    // Both gates require an upward swipe (negative height). The phases are mutually exclusive —
    // waitingForCardReturn is only true after dealPhase has moved past nameInput.

    @MainActor
    private func handleSwipe(_ translation: CGSize) {
        guard translation.height < -AppLayout.swipeSubmitThreshold else { return }

        if waitingForCardReturn {
            waitingForCardReturn = false
            completeCardReturn()
            return
        }

        guard dealPhase == .nameInput else { return }
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            impactMedium.impactOccurred()
            return
        }
        submitName()
    }

    // MARK: — Submit
    //
    // Collects the name, runs the greeting beat, flips the card back, then
    // plays the return-demo sequence. Task ends at waitingForCardReturn = true.
    // completeCardReturn() (triggered by swipe-up gesture) finishes the phase.

    @MainActor
    private func submitName() {
        guard dealPhase != .collecting else { return }
        inputFocusTask?.cancel()
        inputFocusTask = nil
        nameFieldFocused = false

        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            impactMedium.impactOccurred()
            return
        }

        impactHeavy.impactOccurred()
        director.onboardingData.displayName = trimmed
        dealPhase = .collecting

        Task { @MainActor in
            // Dismiss input zone
            withAnimation(AppAnimation.exit) { uiAlpha = 0 }

            // Instantly clear Beat 2 copy — no fade, no delay
            dealerDisplayed = ""
            dealerAlpha     = 0

            // ── Beat 3 — greeting rises ───────────────────────────
            greetingName = trimmed
            nameVisible  = false
            showGreeting = true
            withAnimation(AppAnimation.textProject.reduceMotionSafe) {
                greetingAlpha = 1.0
            }

            try? await Task.sleep(for: .milliseconds(200))
            withAnimation(AppAnimation.standard.reduceMotionSafe) { nameVisible = true }
            try? await Task.sleep(for: .milliseconds(800))

            withAnimation(AppAnimation.textProject.reduceMotionSafe) { greetingAlpha = 0.0 }
            // Full textProject duration — unmounting at 350ms cut the fade.
            try? await Task.sleep(for: .milliseconds(500))
            showGreeting = false
            nameVisible  = false

            // Card stays FACE UP through the lesson — the user picks up and hands back
            // their own card, exactly like the face-up cards in the selection phases.

            // ── The dealer's one-time lesson: how cards work at his table ──────
            //
            // He walks the user through the two gestures the whole flow uses —
            // tap to pick a card up, swipe up to hand it to him — on their first
            // card. Step 1 here ("pick it up"); the tap handler lifts the card and
            // continues to step 2 ("slide it up to me"). Every later phase reuses
            // the identical LiftHalo + swipe, so this teaches the entire onboarding.
            dealerDisplayed = ""
            await shuffleEnterDealer()
            await typeDealerLine("Tap the card to pick it up.")
            try? await Task.sleep(for: .milliseconds(300))

            // Hand off to the tap. Task ends here; handleLiftTap() drives the rest.
            waitingForCardLift = true
        }
    }

    // MARK: — Guided lesson (tap to lift, then swipe to hand back)

    /// Step 1 → 2: the user taps the card. It lifts with the shared affordance,
    /// then the dealer prompts the swipe.
    @MainActor
    private func handleLiftTap() {
        guard waitingForCardLift else { return }
        waitingForCardLift = false
        impactSoft.impactOccurred()
        // Lift exactly like the selection phases (ThreeCardFanController.lift): the
        // card rises to screen y = 0.42, centered, scaled 1.12, on cardLift.
        withAnimation(AppAnimation.cardLift.reduceMotionSafe) {
            cardLifted = true
            cardOffset = CGSize(width: 0, height: screenSize.height * 0.42 - screenSize.height / 2)
            cardScale  = 1.12
        }

        liftTeachTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(420))   // let the lift settle
            guard !Task.isCancelled else { return }
            await teachSwipeUp()
        }
    }

    /// Step 2: the dealer asks for the card, then the swipe becomes live
    /// (waitingForCardReturn shows the chevron and routes handleSwipe → return).
    @MainActor
    private func teachSwipeUp() async {
        // Let the "Tap the card" line float away — a gentle upward drift + fade, instead
        // of the quick shuffle-swap used between ordinary lines — then the next line enters.
        await floatAwayDealer()
        guard !Task.isCancelled else { return }
        await shuffleEnterDealer()
        guard !Task.isCancelled else { return }
        await typeDealerLine("Now swipe up to hand it to me.")
        guard !Task.isCancelled else { return }
        try? await Task.sleep(for: .milliseconds(300))
        waitingForCardReturn = true
    }

    // MARK: — Complete card return (called by swipe-up gesture after demo)

    @MainActor
    private func completeCardReturn() {
        // Snap any residual hint offset
        cardReturnHintOffset = 0

        // Fade the dealer line — text is cleared after the collect (≥350ms),
        // so the fade renders instead of the view emptying on the same frame.
        withAnimation(AppDealerTyping.finalFadeAnim) { dealerAlpha = 0 }

        impactHeavy.impactOccurred()

        Task { @MainActor in
            await performCardCollect()

            dealerDisplayed = ""
            dealerAlpha     = 1.0

            assert(
                !director.cornerDeckCards.isEmpty,
                "cornerDeckCards must have ≥1 card before advancing to modeSelect"
            )

            try? await Task.sleep(for: .milliseconds(250))
            director.advance(to: .modeSelect)
        }
    }
}
