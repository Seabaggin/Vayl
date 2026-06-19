//
//  ExperienceLevelPhase.swift
//  Vayl

import SwiftUI
import SpriteKit

/// OB Phase — Experience Level
/// Three candle cards deal in one-at-a-time and settle into a fan, flip to reveal.
/// Tap to lift (shows level name + descriptor), swipe up to confirm.
/// On confirm writes nmStage via director.commitExperienceLevel (the deck "receive"); the
/// controller then clears the discards + settles and the .done state drives advance(to:.context).
struct ExperienceLevelPhase: View {

    let director:   VaylDirector
    let screenSize: CGSize

    @State private var monte        = ThreeCardFanController()
    @State private var liftedText:  String?          = nil
    @State private var liftedLevel: CandleIntensity? = nil
    @State private var liftTextTask: Task<Void, Never>? = nil
    @State private var entranceTask: Task<Void, Never>? = nil

    // Swipe-up hint — the lifted card tugs upward intermittently to teach the
    // confirm gesture (the consistent cue across phases, mirroring GenderPhase).
    @State private var hintOffset:  CGFloat            = 0
    @State private var hintTask:    Task<Void, Never>? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.displayScale)              private var displayScale

    // ── Question gate ────────────────────────────────────────────
    // "How much have you explored?" must finish typing before the cards
    // respond — the gate opens at type-complete + 250ms (.faceUp case).
    @State private var questionAsked = false

    // ── Card dimensions (fan tokens) ─────────────────────────────
    private var cardW: CGFloat { AppLayout.obFanCardWidth(in: screenSize.width) }
    private var cardH: CGFloat { AppLayout.obFanCardHeight(in: screenSize.width) }

    /// Upward tug distance for the swipe-up hint — proportional to card height so it
    /// scales across devices. Negative = upward. Felt value — verify travel on device.
    private var hintFlickY: CGFloat { -cardH * 0.10 }

    /// The most prominent card in the resting fan — the one with the highest zIndex
    /// (the center/top card the user sees front-and-center). It carries the selection
    /// tug while the fan rests face-up, signalling "this card can be picked."
    private var topCardIndex: Int {
        monte.zIndices.indices.max { monte.zIndices[$0] < monte.zIndices[$1] } ?? 1
    }

    /// y-offset contribution from the GenderPhase-style tug for slot `i`.
    /// • Resting fan (`.faceUp`): only the top card tugs — "pick a card."
    /// • A card lifted (`.lifted`): only the lifted card tugs — "swipe up to confirm."
    private func tugOffset(for i: Int) -> CGFloat {
        switch monte.state {
        case .faceUp: return i == topCardIndex ? hintOffset : 0
        case .lifted: return isLifted(i)        ? hintOffset : 0
        default:      return 0
        }
    }

    /// SpriteKit layer visible only while sprites carry the cards in flight (the deal-in).
    /// After the deal, the sprites hand off to SwiftUI backs and are cleared; the flourish
    /// and everything after run on the SwiftUI cards (see `runEntrance`).
    private var spriteActive: Bool {
        monte.state == .dealing
    }

    /// One fan card. Extracted from the `body` TimelineView so the per-card math +
    /// modifier chain is type-checked in isolation (the inline ForEach was 159ms).
    @ViewBuilder
    private func candleCard(slot i: Int, t: TimeInterval) -> some View {
        let lifted = isLifted(i)
        // Resting lift affordance — while face-up & idle, the cards sit
        // slightly raised with a deeper shadow (a static "floating, ready
        // to pick" look). No looping motion. The tapped card rises further
        // via monte.lift(); receded cards drop back to a flat fan.
        let restingUp: CGFloat = (monte.state == .faceUp) ? -6 : 0
        let restElevation: Double = (monte.state == .faceUp)
            ? max(monte.elevations[i], 0.5)
            : monte.elevations[i]
        let s = AppElevation.cardShadow(elevation: restElevation)
        let offsetY: CGFloat = monte.offsets[i].height + restingUp + tugOffset(for: i)

        // Both faces stay mounted so the candle's Canvas + .drawingGroup warm up at
        // deal time (drawn ONCE at time:0 while hidden behind the back). The reveal
        // then swaps opacity at the edge-on midpoint — no cold first-draw at the flip
        // pivot, which was the laggiest moment. Two-faced idiom, same as
        // ConfirmationPhase / CuriosityFlipCard.
        ZStack {
            VaylCardBack()
                .frame(width: cardW, height: cardH)
                .opacity(monte.showFace[i] ? 0 : 1)

            // Freeze the flame (time:0) until revealed — warm, but not redrawing
            // while hidden. onAction stays nil until shown so the hidden face is
            // fully inert and never intercepts a tap (matches the old back state).
            VaylCardFace(
                content:  .candle(intensity: monte.intensities[i],
                                  time: monte.showFace[i] ? t : 0),
                onAction: monte.showFace[i] ? { handleCardAction($0, slot: i) } : nil
            )
            .frame(width: cardW, height: cardH)
            .overlay(liftHalo(visible: lifted))
            .opacity(monte.showFace[i] ? 1 : 0)
        }
        .scaleEffect(x: monte.flipScaleX[i], y: 1, anchor: .center)
        .scaleEffect(monte.scales[i])
        .rotationEffect(.degrees(monte.angles[i]))
        .offset(x: monte.offsets[i].width, y: offsetY)
        .opacity(monte.alphas[i])
        .zIndex(monte.zIndices[i])
        .shadow(color: s.color, radius: s.radius, y: s.y)
        .animation(AppAnimation.standard, value: monte.state)
    }

    var body: some View {
        // NOTE: AppColors.void, AtmosphereView, and TableSurfaceView are provided by
        // OnboardingCanvasView — phases render as transparent overlays on top.
        ZStack {
            // ── Layer: SpriteKit card flight ──────────────────────────────────
            // Visible only during .dealing (sprites carry the cards in flight).
            // Hidden once deal completes — SwiftUI backs take over at fan positions.
            SpriteView(
                scene:   monte.flightScene,
                options: [.allowsTransparency]
            )
            .frame(width: screenSize.width, height: screenSize.height)
            .allowsHitTesting(false)
            .ignoresSafeArea()
            .opacity(spriteActive ? 1 : 0)
            .onAppear {
                monte.flightScene.size = screenSize
            }

            // ── Layer: SwiftUI cards ──────────────────────────────────────────
            // ~30fps cap — the candle flicker doesn't need display-rate redraws, and
            // the card MOVEMENT stays smooth (it's withAnimation-driven on the render
            // server, not this clock). Halves/quarters the per-frame Canvas + drawingGroup work.
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { tl in
                let t = reduceMotion ? 0 : tl.date.timeIntervalSinceReferenceDate
                ZStack {
                    ForEach(0..<3, id: \.self) { i in
                        candleCard(slot: i, t: t)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                // Group sweep for the fan flourish — rotates all three cards rigidly about
                // the fan center, so they never change relative position/z (clip-free).
                .rotationEffect(
                    .degrees(monte.sweep),
                    anchor: UnitPoint(
                        x: 0.5,
                        y: AppLayout.obTableCardCenterY(in: screenSize.height) / screenSize.height
                    )
                )
            }

            // NOTE: the projected dealer line is rendered once at the canvas level
            // (OnboardingCanvasView Layer 7). It is intentionally NOT re-rendered here —
            // a second copy at the same position composites the text twice (heavier /
            // doubled shadow). The canvas-level render is the single source.

            // ── Layer: Lift label ─────────────────────────────────────────────
            if let text = liftedText, let level = liftedLevel {
                liftCopyLayer(title: level.displayName, subtitle: text)
                    .transition(.opacity)
                    .zIndex(20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Fire only at the two interactive moments — VaylCardFace has no tap haptic of
        // its own, so .lifted must carry the tap feedback. Autonomous transitions
        // (dealing/shuffling/revealing/done) return nil so they don't buzz; confirm is
        // handled by confirmHapticTrigger below (no double-fire).
        .sensoryFeedback(trigger: monte.state) { _, new in
            switch new {
            case .faceUp: return .selection                // hand is ready to pick
            case .lifted: return .impact(weight: .light)   // card picked up
            default:      return nil
            }
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: monte.confirmHapticTrigger)
        .sensoryFeedback(.impact(weight: .light), trigger: monte.shuffleHapticTrigger)
        .onAppear {
            // Pre-set fan positions (alphas stay 0 until deal completes).
            monte.placeFanFaceDown(screenSize: screenSize)

            // Dealer prompt — driven by state (fires when cards become face-up &
            // tappable), not a fixed timer. See .onChange(of: monte.state) below.

            // Reduce Motion: skip deal-in theatre; show backs + reveal.
            if reduceMotion {
                monte.showSwiftUIBacks()
                Task { await monte.reveal() }
                return
            }

            // Defer the card-back rasterization OFF the appearance frame.
            // ImageRenderer.uiImage is a synchronous main-thread rasterize of a
            // VaylCardBack (.drawingGroup + spectrum strokes); running it inline in
            // onAppear hitched the deal-in. Let the phase paint first, then snapshot
            // + deal a couple of frames later (imperceptible in the ceremony).
            entranceTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(32))
                guard !Task.isCancelled else { return }
                let renderer = ImageRenderer(
                    content: VaylCardBack().frame(width: cardW, height: cardH)
                )
                renderer.scale = displayScale

                guard let backImage = renderer.uiImage else {
                    // Snapshot failed — fall back to instant reveal.
                    monte.showSwiftUIBacks()
                    await monte.reveal()
                    return
                }

                // Full entrance: deal → showSwiftUIBacks → reveal.
                monte.runEntrance(screenSize: screenSize, backImage: backImage)
            }
        }
        .onChange(of: monte.state) { _, newState in
            switch newState {
            case .dealing:
                // Set intent as the deal begins; the line carries through the flourish and
                // clears at .revealing. (Under Reduce Motion .dealing never fires, so it's
                // naturally skipped.)
                director.showDealerLineManual("Let's see where you're starting.")
            case .revealing:
                // Clear the entrance line as the flip-reveal begins.
                director.hideDealerLine()
            case .faceUp:
                // Cards finished revealing — tug the top card to invite a pick and ask
                // the question. The cards must not answer before it's asked: the tap
                // gate opens at type-complete + 250ms (questionAsked). The line then
                // persists until the user taps (hidden in handleCardAction).
                startSwipeHint()
                let line = "How much have you explored?"
                director.showDealerLineManual(line)
                let gateMs = reduceMotion ? 250 : AppDealerTyping.typeDuration(line) + 500
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(gateMs))
                    questionAsked = true
                }
            case .lifted:
                // A card is lifted & ready to confirm — tug it upward to cue swipe-up. By
                // now the user has swiped up in Name, ModeSelect, and Gender, so this is a
                // sparse reminder, not a tutorial: long initial wait, long rest between tugs.
                startSwipeHint(initialDelayMs: 1200, restMs: 6000)
            case .done(let intensity):
                // Exit complete: table is clean, deck received.
                // Show the dealer's selection response, hold until it finishes
                // typing + a read beat, then advance — advance() fades the line
                // INTO the cross-fade, so the voice trails into the scene change
                // instead of being clipped by a fixed timer.
                stopSwipeHint()
                let line = director.showExpLevelExitLine(intensity)
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(
                        AppDealerTyping.typeDuration(line) + 700
                    ))
                    director.advance(to: .context)
                }
            default:
                stopSwipeHint()
            }
        }
        .onDisappear {
            entranceTask?.cancel()
            liftTextTask?.cancel()
            hintTask?.cancel()
            // No hideDealerLine here: onDisappear fires mid cross-fade, AFTER the
            // next phase may have projected its own line — advance() owns
            // cross-phase line cleanup.
            // cancel() stops both sequenceTask and pocketTask.
            monte.cancel()
        }
        .accessibilityLabel("Experience level phase")
    }

    // MARK: — Swipe-up hint (consistent cross-phase cue)

    /// Intermittent upward tug on the lifted card: flick up → spring home → rest → repeat.
    /// Mirrors GenderPhase's swipe hint so the confirm gesture reads the same everywhere.
    /// Cadence lives in Task.sleep (not animation tokens) per the codebase pattern.
    /// - Parameters:
    ///   - initialDelayMs: wait before the first tug (lets the prior motion settle).
    ///   - restMs: pause between tugs. Higher = more intermittent — used for the lifted
    ///     confirm tug, since the user already knows swipe-up from earlier phases.
    private func startSwipeHint(initialDelayMs: UInt64 = 600, restMs: UInt64 = 1900) {
        hintTask?.cancel()
        guard !reduceMotion else {
            withAnimation(AppAnimation.spring.reduceMotionSafe) { hintOffset = 0 }
            return
        }
        hintOffset = 0
        hintTask = Task { @MainActor in
            // Let the prior motion settle before the first tug.
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

    // MARK: — Lift state

    /// True when slot `i`'s intensity is the one currently lifted.
    private func isLifted(_ i: Int) -> Bool {
        if case .lifted(let held) = monte.state { return held == monte.intensities[i] }
        return false
    }

    // MARK: — Lift halo (shared spectrum focus ring — see LiftHalo.swift)

    @ViewBuilder
    private func liftHalo(visible: Bool) -> some View {
        LiftHalo(visible: visible)
    }

    // MARK: — Lift copy overlay

    private func liftCopyLayer(title: String, subtitle: String) -> some View {
        ZStack {
            VStack(spacing: AppSpacing.sm) {
                // Level name — LivingText
                LivingText(
                    text: title,
                    font: AppFonts.heroTitle
                )

                // Descriptor — GradientText
                GradientText(
                    text: subtitle,
                    font: AppFonts.sectionHeading
                )
                .multilineTextAlignment(.center)

                // Spectrum hairline
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

    // MARK: — Card action handler

    /// Routes VaylCardFace's forwarded gestures: tap lifts the card (showing its level
    /// name + descriptor); swipe-up on the lifted card confirms the pick.
    private func handleCardAction(_ action: VaylCardAction, slot i: Int) {
        let intensity = monte.intensities[i]
        switch action {
        case .tapped:
            // The dealer finishes his question before the cards will answer it.
            guard questionAsked else { return }
            director.hideDealerLine()
            withAnimation(AppAnimation.standard.reduceMotionSafe) {
                monte.lift(intensity, screenSize: screenSize)
            }
            liftTextTask?.cancel()
            withAnimation(AppAnimation.fast) {
                liftedText  = nil
                liftedLevel = nil
            }
            scheduleLiftText(for: intensity)

        case .swipedUp:
            guard case .lifted(let held) = monte.state, held == intensity else { return }
            liftTextTask?.cancel()
            withAnimation(AppAnimation.fast) {
                liftedText  = nil
                liftedLevel = nil
            }
            director.hideDealerLine()
            monte.confirm(held, screenSize: screenSize) {
                director.commitExperienceLevel($0)
            }

        default:
            break
        }
    }

    // MARK: — Lift text scheduler

    private func scheduleLiftText(for intensity: CandleIntensity) {
        liftTextTask?.cancel()
        liftTextTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(120))
            guard !Task.isCancelled else { return }
            let descriptor: String = {
                switch intensity {
                case .curious:     return "Just opening the door."
                case .exploring:   return "Finding our rhythm."
                case .experienced: return "We know what we like."
                }
            }()
            withAnimation(AppAnimation.standard) {
                liftedText  = descriptor
                liftedLevel = intensity
            }
        }
    }
}
