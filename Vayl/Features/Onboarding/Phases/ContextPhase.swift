// Features/Onboarding/Phases/ContextPhase.swift
//
// OB Phase — Context · "Where are you right now?"
// Sits after ExperienceLevelPhase, advances to CuriosityPhase.
//
// A browsable card stack (VaylCardCarousel + CarouselPhysics): the user swipes
// to browse relationship-context cards, taps the front card to confirm, and
// swipes up to exit. On exit the selection is committed via the director.
//
// NOTE: This pass ships the browse + confirm + exit-commit core with a simple
// rise-in entrance / fade-out exit so the carousel *feel* can be verified on
// device. The full spec choreography (literal deal-onto-felt, and the
// sequential pocket → beat → lay-flat → vacuum exit) is layered in next, once
// the browse feel is confirmed.

import SwiftUI

struct ContextPhase: View {

    let director: VaylDirector
    let screenSize: CGSize

    // MARK: - Card geometry
    // Based on the shared OB "hero card" size (obTableCard × cinematic scale), bumped a
    // touch for the carousel — browsing wants more card presence. The bump is Context-ONLY;
    // it does not change the shared ModeSelect / Name / Gender card size.
    private var cardSize: CGSize {
        let bump: CGFloat = 1.1   // FEEL-GATE — carousel card size; dial to taste
        return CGSize(
            width: AppLayout.obTableCardWidth(in: screenSize.width)  * AppLayout.obTableCardCinematicScale * bump,
            height: AppLayout.obTableCardHeight(in: screenSize.width) * AppLayout.obTableCardCinematicScale * bump
        )
    }

    // MARK: - Data
    private let appMode: AppMode
    private let options: [ContextOption]

    @State private var physics: CarouselPhysics
    @State private var confirmedIndex: Int?
    @State private var entered: Bool    = false
    @State private var exiting: Bool    = false
    @State private var defocusOthers: Bool    = false
    @State private var hintOffset: CGFloat = 0
    @State private var confirmTug: CGFloat = 0
    @State private var confirmPulse: Bool    = false
    @State private var tugTask: Task<Void, Never>?
    @State private var hintTask: Task<Void, Never>?  // one-shot browse nudge; cancelled on confirm

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(director: VaylDirector, screenSize: CGSize) {
        self.director   = director
        self.screenSize = screenSize
        let data = director.onboardingData
        self.appMode = data.appMode
        self.options = ContextOption.options(appMode: data.appMode, stage: data.nmStage)
        // Infinite scroll — no reset point. The carousel renders a recycled window
        // with stable modular node identity, so wrap stays smooth (only the hidden
        // far-edge node ever swaps content).
        _physics = State(initialValue: CarouselPhysics(count: options.count, wraps: true))
    }

    // MARK: - Copy
    private var reassuranceText: String {
        appMode == .together
            ? "Every starting point is valid."
            : "No judgment on any answer."
    }

    // MARK: - Body
    var body: some View {
        ZStack {
        // Live accent glow — tinted by the front card's accent, crossfades on swipe.
        RadialGradient(
            colors: [
                tint(for: options[physics.currentIndex].accent)
                    .opacity(confirmPulse ? 0.34 : 0.18),   // FEEL-GATE — accent glow strength (turned down)
                Color.clear
            ],
            center: .center,
            startRadius: 0,
            endRadius: cardSize.width * (confirmPulse ? 1.5 : 1.2)
        )
        .frame(width: cardSize.width * 2.2, height: cardSize.width * 2.2)
        .blur(radius: cardSize.width * 0.20)
        .offset(y: -cardSize.height * 0.10)
        // Contain the oversized glow's LAYOUT footprint to the screen. Its visual frame
        // (cardSize.width * 2.2 ≈ 1.5× the screen) otherwise inflates this ZStack's width,
        // and the absolutely-positioned ProjectedTextView (x = screenWidth/2) is then
        // measured against that wider box — landing LEFT of centre. The gradient still
        // renders large (frame doesn't clip); only its reported layout size shrinks.
        .frame(width: screenSize.width, height: screenSize.height)
        .opacity(entered && !exiting ? 1 : 0)
        // One animation per property: the index-scoped standard drives ONLY the tint
        // crossfade on swipe. confirmPulse animates via withAnimation at its mutation
        // sites (spring up in handleConfirm, slow settle on release) — a second scoped
        // .animation here stacked onto the same gradient and clobbered that settle.
        .animation(AppAnimation.standard, value: physics.currentIndex)
        .allowsHitTesting(false)

        VStack(spacing: 0) {
            Spacer()

            // Spectrum progress line — fills the top void, grounds position.
            // barHeight omitted: OnboardingProgressBar defaults it to
            // ProgressBarConstants.defaultBarHeight (that enum is private to
            // its file and not referenceable here).
            OnboardingProgressBar(
                currentStep: physics.currentIndex + 1,
                totalSteps: options.count,
                totalWidth: screenSize.width * 0.34
            )
            .padding(.bottom, AppSpacing.xl)
            .opacity(entered && !exiting ? 1 : 0)
            .animation(AppAnimation.standard, value: physics.currentIndex)
            .accessibilityHidden(true)

            VaylCardCarousel(
                count: options.count,
                cardSize: cardSize,
                physics: physics,
                confirmedIndex: confirmedIndex,
                confirmedCardYHint: confirmTug,
                exiting: exiting,
                defocusUnselected: defocusOthers,
                content: { index, isFront in
                    let o = options[index]
                    VaylCardFace(
                        content: .context(
                            number: String(format: "%02d", index + 1),
                            title: o.title,
                            subtitle: o.subtitle,
                            detail: o.detail
                        ),
                        isFront: isFront,
                        confirmed: confirmedIndex == index
                    )
                },
                onConfirm: handleConfirm,
                onUnconfirm: handleUnconfirm,
                onExit: handleExit
            )
            .offset(x: hintOffset)
            .opacity(entered ? 1 : 0)                   // per-card exit handles fade-out
            // Assembly — the cards lift UP off the receding felt and grow into place with a
            // touch of overshoot (was a faint 8% scale + 6% rise that read as a soft fade).
            // FEEL-GATE — the grow-from scale and the rise distance.
            .scaleEffect(entered ? 1 : 0.82)
            .offset(y: entered ? 0 : screenSize.height * 0.13)
            .accessibilityLabel(a11yLabel)
            .accessibilityHint("Swipe left or right to browse. Double-tap to select. After selecting, swipe up to continue.")

            Spacer().frame(height: AppSpacing.xxl)

            // Hybrid detail panel.
            // Subtitle: live on swipe.  Detail: revealed only after confirm.
            VStack(spacing: AppSpacing.sm) {
                Rectangle()
                    .fill(LinearGradient(
                        colors: [AppColors.spectrumCyan, AppColors.spectrumPurple, AppColors.spectrumMagenta],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .frame(width: screenSize.width * 0.34, height: 1)
                    .opacity(0.5)
                    .spectrumBorderGlow(intensity: confirmedIndex != nil ? 0.72 : 0)
                    .padding(.bottom, AppSpacing.xs)
                    .animation(AppAnimation.standard, value: confirmedIndex)

                Text(options[physics.currentIndex].subtitle)
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(AppColors.textBody)
                    .multilineTextAlignment(.center)
                    .id("subtitle-\(physics.currentIndex)")
                    .transition(.opacity)

                Text(confirmedIndex.map { options[$0].detail } ?? " ")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .opacity(confirmedIndex != nil ? 1 : 0)
                    // Scoped here, not on the panel: the detail reveal is the only
                    // confirmedIndex-driven property in this subtree without its own
                    // animation (the divider glow carries one above). Keeps the panel
                    // under a single animation per property.
                    .animation(AppAnimation.standard, value: confirmedIndex)
            }
            .padding(.horizontal, AppSpacing.lg)
            .frame(minHeight: screenSize.height * 0.14, alignment: .top)
            .opacity(entered && !exiting ? 1 : 0)
            // Index-scoped: drives the subtitle's .opacity transition on swipe only.
            .animation(AppAnimation.standard, value: physics.currentIndex)

            Spacer()

            Text(reassuranceText)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textAccent)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xl)
                .opacity(entered && !exiting ? 1 : 0)
                .accessibilityAddTraits(.isStaticText)
        }

        // Dealer copy — rendered by the phase so it layers ABOVE the cards.
        // (The canvas's copy layer sits behind the phase and is occluded by the stack.)
        if director.projector.projectedTextVisible, let copy = director.projector.projectedText {
            // anchorYFrac lifts the line clear above the (enlarged) cards. The explicit
            // screen-sized frame pins ProjectedTextView's absolute .position (x = width/2)
            // to the SCREEN, immune to anything in this ZStack that renders wider than the
            // screen (the glow, the peeking cards) — otherwise the line drifts off-centre.
            // FEEL-GATE — anchorYFrac: lower value = higher on screen.
            ProjectedTextView(text: copy, screenSize: screenSize, anchorYFrac: 0.20, centerGrow: true)
                .frame(width: screenSize.width, height: screenSize.height)
                .transition(.opacity)
                .zIndex(20)
                .allowsHitTesting(false)
        }
        }
        .frame(width: screenSize.width, height: screenSize.height)
        .sensoryFeedback(.impact(weight: .light), trigger: confirmedIndex)
        .sensoryFeedback(.selection, trigger: physics.currentIndex)
        .onAppear(perform: runEntrance)
        .onDisappear { tugTask?.cancel(); hintTask?.cancel() }
        .accessibilityLabel("Context phase")
    }

    private var a11yLabel: String {
        let o = options[physics.currentIndex]
        return "\(o.title). \(o.subtitle). \(o.detail)"
    }

    // MARK: - Entrance (earned transition)
    // The felt carries over from ExperienceLevel. The dealer headline greets first;
    // after a beat the table dissolves as the carousel assembles. Driven from the
    // phase so it works regardless of entry path (real advance vs. dev phase-jump).
    private func runEntrance() {
        guard !entered else { return }
        // Clear any hangover dealer copy from the prior phase immediately. Re-hiding
        // here also wins the onAppear/onDisappear race with ExperienceLevel.
        director.projector.hideDealerLine()

        if reduceMotion {
            director.recedeTableForContext()
            entered = true
            director.showContextHeadline()
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(2500))
                director.projector.hideDealerLine()
            }
            return
        }

        Task { @MainActor in
            // 1. Silent beat — the clean felt (and the 5/6 deck) get their moment.
            try? await Task.sleep(for: .milliseconds(700))   // FEEL-GATE — trimmed from 900 (less dead air before the headline)
            guard !entered else { return }

            // 2. Single strong bridging line, typed on the STILL-PRESENT felt.
            let line = director.showContextHeadline()

            // 3. Hold until the question lands + a read beat — only then does
            //    the table give way. (The old fixed 1.6s recede cut into the
            //    type and ran recede + assembly + typing as one rushed beat.)
            try? await Task.sleep(for: .milliseconds(AppDealerTyping.typeDuration(line) + 500))
            guard !entered else { return }

            // 4. Table recedes as its own visible beat; the carousel assembles
            //    250ms INTO the recede, so the felt dissolves into the carousel.
            director.recedeTableForContext()
            try? await Task.sleep(for: .milliseconds(250))
            guard !entered else { return }
            // carouselAssemble — livelier than AppAnimation.spring; a bit of overshoot so the
            // carousel ARRIVES off the felt rather than fades in (FEEL-GATE, tuned in the token).
            withAnimation(AppAnimation.carouselAssemble) { entered = true }

            // 5. Headline fades over the rising cards.
            director.projector.hideDealerLine()

            // 6. No further copy — the carousel is the question. Just schedule hint.
            try? await Task.sleep(for: .milliseconds(800))
            guard !exiting, confirmedIndex == nil else { return }
            scheduleHint()
        }
    }

    private func scheduleHint() {
        hintTask?.cancel()
        hintTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(600))
            guard confirmedIndex == nil, !exiting, !reduceMotion,
                  !Task.isCancelled else { return }
            // Browse nudge — proportional, ≈18pt on current widths. Felt value.
            withAnimation(AppAnimation.fast) { hintOffset = -screenSize.width * 0.045 }
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            withAnimation(AppAnimation.spring) { hintOffset = 0 }
        }
    }

    // Maps the decorative CardAccent to spectrum tokens (no raw colors).
    private func tint(for accent: CardAccent) -> Color {
        switch accent {
        case .ember:   return AppColors.spectrumCyan
        case .spark:   return AppColors.spectrumCyan
        case .flame:   return AppColors.spectrumPurple
        case .inferno: return AppColors.spectrumMagenta
        case .nova:    return AppColors.spectrumMagenta
        }
    }

    // MARK: - Selection
    private func handleConfirm(_ index: Int) {
        guard !exiting else { return }
        // Kill the one-shot browse nudge — confirming during its hold window
        // must not let the spring-home fire against the confirmed transform.
        hintTask?.cancel()
        withAnimation(AppAnimation.spring) { hintOffset = 0 }
        withAnimation(AppAnimation.spring) { confirmedIndex = index }
        startConfirmTug()
        guard !reduceMotion else { return }
        Task { @MainActor in
            withAnimation(AppAnimation.spring) { confirmPulse = true }
            // 650ms — the pulse spring needs ~0.65s to peak; releasing at 450
            // retargeted it mid-flight.
            try? await Task.sleep(for: .milliseconds(650))
            withAnimation(AppAnimation.slow) { confirmPulse = false }
        }
    }

    private func handleUnconfirm() {
        guard !exiting else { return }
        stopConfirmTug()
        withAnimation(AppAnimation.spring) { confirmedIndex = nil }
        withAnimation(AppAnimation.spring) { confirmPulse = false }
    }

    // MARK: - Swipe-up hint (sparse — user has done this gesture 4 times already)
    private func startConfirmTug() {
        tugTask?.cancel()
        guard !reduceMotion, !AppAnimation.lowPower else { return }
        confirmTug = 0
        // Flick is 3% of card height — barely noticeable, just directional.
        // Initial delay and rest match ExperienceLevel's .lifted cadence (2200/6000ms).
        let flickY = -cardSize.height * 0.03
        tugTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(2200))
            while !Task.isCancelled {
                withAnimation(AppAnimation.swipeHintFlick) { confirmTug = flickY }
                try? await Task.sleep(for: .milliseconds(380))   // 260 flick + 120 peak hold — sibling cadence
                guard !Task.isCancelled else { break }
                withAnimation(AppAnimation.spring) { confirmTug = 0 }
                try? await Task.sleep(for: .milliseconds(6000))
                guard !Task.isCancelled else { break }
            }
        }
    }

    private func stopConfirmTug() {
        tugTask?.cancel()
        tugTask = nil
        withAnimation(AppAnimation.spring.reduceMotionSafe) { confirmTug = 0 }
    }

    // MARK: - Exit timeline
    // swipe-up → confirmed card lifts/fades + others drop away → (beat) → director
    // returns the felt, pockets the credential, and projects a responsive line →
    // (beat) → advance to .curiosity (handled inside concludeContext).
    private func handleExit() {
        guard let index = confirmedIndex, !exiting else { return }
        stopConfirmTug()
        let option = options[index]
        director.projector.hideDealerLine()

        // Step 1 — the chosen card launches up and off.
        withAnimation(AppAnimation.cardPocket.reduceMotionSafe) { exiting = true }

        Task { @MainActor in
            // Step 2 — a beat later, the rest drift out of focus (as the hero flies).
            try? await Task.sleep(for: .milliseconds(350))
            withAnimation(AppAnimation.exit.reduceMotionSafe) { defocusOthers = true }

            // Hero has cleared. Single → the couples-first greeting first (its Continue
            // concludes); everyone else concludes straight to the felt + dealer reply.
            try? await Task.sleep(for: .milliseconds(450))
            if option.context == .single {
                director.presentSingleGreeting(context: option.context,
                                               register: option.derivedRegister)
            } else {
                director.concludeContext(
                    relationshipContext: option.context,
                    situationalRegister: option.derivedRegister
                )
            }
        }
    }
}
