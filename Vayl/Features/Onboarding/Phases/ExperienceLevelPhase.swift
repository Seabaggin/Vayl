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
    @State private var liftedLevel: CandleIntensity? = nil
    @State private var liftTextTask: Task<Void, Never>? = nil
    @State private var entranceTask: Task<Void, Never>? = nil

    // Swipe-up hint — the lifted card tugs upward intermittently to teach the
    // confirm gesture (the consistent cue across phases, mirroring GenderPhase).
    @State private var hintOffset:  CGFloat            = 0
    @State private var hintTask:    Task<Void, Never>? = nil

    // Live hand-off follow (Phase 4c): the lifted card tracks the finger as it's handed up
    // (shared HandBackFollow). View-local; the controller owns monte.offsets, so this
    // resolves to .zero inside the pocket flight on confirm.
    @State private var handBackDrag:         CGSize = .zero
    @State private var handBackArmed:        Bool   = false
    @State private var handBackSelectionGen = UISelectionFeedbackGenerator()

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

    /// y-offset contribution from the swipe-up tug for slot `i`. Only the LIFTED card tugs
    /// (the swipe-up confirm cue). There's no resting "pick a card" bounce — the
    /// auto-selected default card is the cue, so no single card is singled out at rest.
    private func tugOffset(for i: Int) -> CGFloat {
        if case .lifted = monte.state, isLifted(i) { return hintOffset }
        return 0
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

        // Both faces stay mounted (dual-mount pre-warm) so the candle's Canvas +
        // .drawingGroup are warm before the turn. The reveal is a real 3D EDGE-TURN
        // (rotation3DEffect, ConfirmationPhase idiom) — not a flat scaleX squish: `turned`
        // drives both faces' rotation + opacity crossfade, and at the 90° edge-on midpoint
        // both are ~invisible so the swap is clean. The L→R wave (stagger) lives in
        // spreadTurnoverReveal, making it a ribbon-spread turnover.
        let turned = monte.showFace[i]
        ZStack {
            VaylCardBack()
                .frame(width: cardW, height: cardH)
                .rotation3DEffect(.degrees(turned ? 180 : 0),
                                  axis: (x: 0, y: 1, z: 0), perspective: 0.6)
                .opacity(turned ? 0 : 1)

            // Freeze the flame (time:0) until revealed — warm, but not redrawing while hidden.
            //
            // onAction is kept CONSTANT (never nil↔closure). Toggling it flips
            // FaceGestures' `if enabled` structural branch inside VaylCardFace, which
            // re-identifies the face subtree and COLD-re-rasterizes this — the OB's most
            // expensive, self-animating candle face (own @State breathe + drawingGroup) —
            // at the exact flip pivot. That cold raster IS the reveal glitch. Instead we
            // gate the hidden face inert with .allowsHitTesting, exactly like the working
            // ModeSelect flip. The tap/swipe handlers already guard on state
            // (questionAsked / .lifted), so an always-attached gesture is safe.
            VaylCardFace(
                content:  .candle(intensity: monte.intensities[i],
                                  time: turned ? t : 0),
                onAction: { handleCardAction($0, slot: i) }
            )
            .frame(width: cardW, height: cardH)
            .overlay(liftHalo(visible: lifted))
            .rotation3DEffect(.degrees(turned ? 0 : -180),
                              axis: (x: 0, y: 1, z: 0), perspective: 0.6)
            .allowsHitTesting(turned)
            .opacity(turned ? 1 : 0)
        }
        // The 3D turn curve — FEEL-GATE (~0.52s ease reads as a card rolling over its edge).
        // Nil under Reduce Motion so the face appears instantly (reveal() path).
        .animation(reduceMotion ? nil : AppAnimation.cardTurn3D,
                   value: monte.showFace[i])
        .scaleEffect(monte.scales[i])
        // Tilt + follow as the lifted card is handed up (shared HandBackFollow).
        .rotationEffect(.degrees(monte.angles[i] + (lifted ? HandBackFollow.tilt(for: handBackDrag.width, screenWidth: screenSize.width) : 0)))
        .offset(x: monte.offsets[i].width, y: offsetY)
        .offset(lifted ? handBackDrag : .zero)
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
            if let level = liftedLevel {
                liftCopyLayer(title: level.displayName,
                              durationText: duration(for: level))
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
                director.projector.showDealerLineManual("Let's see where you're starting.")
            case .revealing:
                // Clear the entrance line as the flip-reveal begins.
                director.projector.hideDealerLine()
            case .faceUp:
                // Cards finished revealing — ask the question, then AUTO-SELECT the default
                // (curious). No resting "pick a card" bounce: the auto-lifted card is the cue.
                // The tap gate opens at type-complete + a beat (questionAsked) so the cards
                // don't answer before it's asked.
                let line = "How much have you explored?"
                director.projector.showDealerLineManual(line)
                let gateMs = reduceMotion ? 250 : AppDealerTyping.typeDuration(line) + 500
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(gateMs))
                    questionAsked = true
                    // Start the user at curious — they can tap another card to switch, or
                    // swipe up to confirm. Skip if they somehow already picked.
                    guard case .faceUp = monte.state else { return }
                    director.projector.hideDealerLine()
                    withAnimation(AppAnimation.standard.reduceMotionSafe) {
                        monte.lift(.curious, screenSize: screenSize)
                    }
                    scheduleLiftText(for: .curious)
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

    /// Experience-duration credential shown under the level name (Bryan's literal ranges).
    private func duration(for intensity: CandleIntensity) -> String {
        switch intensity {
        case .curious:     return "No experience"
        case .exploring:   return "3 months – 1 year"
        case .experienced: return "1.5+ years"
        }
    }

    private func liftCopyLayer(title: String, durationText: String) -> some View {
        ZStack {
            VStack(spacing: AppSpacing.sm) {
                // Level name — LivingText
                LivingText(
                    text: title,
                    font: AppFonts.heroTitle
                )

                // Experience duration — the prominent "how long." Sized up to the section
                // heading now that it's the only sub-line (the encouraging dealer's-read
                // moved to the swipe-up response — director.showExpLevelExitLine).
                GradientText(
                    text: durationText,
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
            director.projector.hideDealerLine()
            withAnimation(AppAnimation.standard.reduceMotionSafe) {
                monte.lift(intensity, screenSize: screenSize)
            }
            liftTextTask?.cancel()
            withAnimation(AppAnimation.fast) {
                liftedLevel = nil
            }
            scheduleLiftText(for: intensity)

        case .dragChanged(let translation):
            // Live hand-off follow — only the lifted card tracks the finger.
            guard case .lifted(let held) = monte.state, held == intensity else { return }
            handBackDrag = HandBackFollow.offset(for: translation, cardWidth: cardW, cardHeight: cardH)
            let crossed = translation.height < -cardH * 0.14
            if crossed != handBackArmed { handBackArmed = crossed; handBackSelectionGen.selectionChanged() }

        case .swipedUp:
            guard case .lifted(let held) = monte.state, held == intensity else { return }
            handBackArmed = false
            liftTextTask?.cancel()
            withAnimation(AppAnimation.fast) {
                liftedLevel = nil
            }
            director.projector.hideDealerLine()
            // Drift + tilt resolve INTO the pocket flight — no snap at the handoff.
            withAnimation(AppAnimation.cardPocket.reduceMotionSafe) { handBackDrag = .zero }
            monte.confirm(held, screenSize: screenSize) {
                director.commitExperienceLevel($0)
            }

        case .dragEnded:
            // Released short of the commit threshold — settle the card back to the lift anchor.
            guard case .lifted = monte.state else { return }
            handBackArmed = false
            withAnimation(AppAnimation.cardSettle.reduceMotionSafe) { handBackDrag = .zero }

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
            // On lift we show only the level name + duration (see liftCopyLayer). The
            // encouraging dealer's-read line is spoken on CONFIRM (showExpLevelExitLine),
            // not parked statically on screen while the card is held.
            withAnimation(AppAnimation.standard) {
                liftedLevel = intensity
            }
        }
    }
}
