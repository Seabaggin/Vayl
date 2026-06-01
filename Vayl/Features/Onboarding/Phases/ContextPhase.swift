// Features/Onboarding/Phases/ContextPhase.swift
//
// OB Phase — Context · "Where are you right now?"
// Sits after ExperienceLevelPhase, advances to CompassPhase.
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

    let director:   VaylDirector
    let screenSize: CGSize

    // MARK: - Card geometry
    // Shared OB "hero card" size — identical to ModeSelectPhase / NamePhase /
    // GenderPhase (obTableCard × cinematic scale). Keeps the card system consistent.
    private var cardSize: CGSize {
        CGSize(
            width:  AppLayout.obTableCardWidth(in: screenSize.width)  * AppLayout.obTableCardCinematicScale,
            height: AppLayout.obTableCardHeight(in: screenSize.width) * AppLayout.obTableCardCinematicScale
        )
    }

    // MARK: - Data
    private let appMode: AppMode
    private let options: [ContextOption]

    @State private var physics:        CarouselPhysics
    @State private var confirmedIndex: Int?    = nil
    @State private var entered:        Bool    = false
    @State private var exiting:        Bool    = false
    @State private var defocusOthers:  Bool    = false
    @State private var hintOffset:     CGFloat = 0
    @State private var confirmTug:     CGFloat = 0
    @State private var tugTask:        Task<Void, Never>? = nil

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
        VStack(spacing: 0) {
            Spacer()

            VaylCardCarousel(
                count:          options.count,
                cardSize:       cardSize,
                physics:        physics,
                confirmedIndex:     confirmedIndex,
                confirmedCardYHint: confirmTug,
                exiting:            exiting,
                defocusUnselected:  defocusOthers,
                content: { index, isFront in
                    let o = options[index]
                    VaylCardFace(
                        content: .context(
                            number:   String(format: "%02d", index + 1),
                            title:    o.title,
                            subtitle: o.subtitle,
                            detail:   o.detail
                        ),
                        isFront: isFront
                    )
                },
                onConfirm:   handleConfirm,
                onUnconfirm: handleUnconfirm,
                onExit:      handleExit
            )
            .offset(x: hintOffset)
            .opacity(entered ? 1 : 0)                   // per-card exit handles fade-out
            .scaleEffect(entered ? 1 : 0.92)            // assembles in, not just fades
            .offset(y: entered ? 0 : screenSize.height * 0.06)
            .accessibilityLabel(a11yLabel)
            .accessibilityHint("Swipe left or right to browse. Double-tap to select. After selecting, swipe up to continue.")

            Spacer()

            Text(reassuranceText)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.spectrumText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xl)
                .opacity(entered && !exiting ? 1 : 0)
                .accessibilityAddTraits(.isStaticText)
        }

        // Dealer copy — rendered by the phase so it layers ABOVE the cards.
        // (The canvas's copy layer sits behind the phase and is occluded by the stack.)
        if director.projectedTextVisible, let copy = director.projectedText {
            ProjectedTextView(text: copy, screenSize: screenSize)
                .transition(.opacity)
                .zIndex(20)
                .allowsHitTesting(false)
        }
        }
        .frame(width: screenSize.width, height: screenSize.height)
        .sensoryFeedback(.impact(weight: .light), trigger: confirmedIndex)
        .onAppear(perform: runEntrance)
        .onDisappear { tugTask?.cancel() }
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
        director.hideDealerLine()

        if reduceMotion {
            director.recedeTableForContext()
            entered = true
            director.showContextHeadline()
            return
        }

        Task { @MainActor in
            // 1. Silent beat — clean felt, no copy. Context arrived to a clean table.
            try? await Task.sleep(for: .milliseconds(700))
            guard !entered else { return }

            // 2. Single strong bridging line. Fires on the still-present felt.
            //    Auto-fades at 2.8s — intentionally overlaps the carousel arrival.
            director.showContextHeadline()

            // 3. Let it breathe (~1.6s), then felt dissolves and carousel assembles
            //    simultaneously — copy is still fading as the carousel arrives.
            try? await Task.sleep(for: .milliseconds(1600))
            guard !entered else { return }
            director.recedeTableForContext()
            withAnimation(AppAnimation.spring) { entered = true }

            // 4. No further copy — the carousel is the question. Just schedule hint.
            try? await Task.sleep(for: .milliseconds(800))
            guard !exiting, confirmedIndex == nil else { return }
            scheduleHint()
        }
    }

    private func scheduleHint() {
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1200))
            guard confirmedIndex == nil, !exiting, !reduceMotion else { return }
            withAnimation(AppAnimation.fast) { hintOffset = -18 }
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            withAnimation(AppAnimation.spring) { hintOffset = 0 }
        }
    }

    // MARK: - Selection
    private func handleConfirm(_ index: Int) {
        guard !exiting else { return }
        withAnimation(AppAnimation.spring) { confirmedIndex = index }
        startConfirmTug()
    }

    private func handleUnconfirm() {
        guard !exiting else { return }
        stopConfirmTug()
        withAnimation(AppAnimation.spring) { confirmedIndex = nil }
    }

    // MARK: - Swipe-up hint (sparse — user has done this gesture 4 times already)
    private func startConfirmTug() {
        tugTask?.cancel()
        guard !reduceMotion else { return }
        confirmTug = 0
        // Flick is 3% of card height — barely noticeable, just directional.
        // Initial delay and rest match ExperienceLevel's .lifted cadence (2200/6000ms).
        let flickY = -cardSize.height * 0.03
        tugTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(2200))
            while !Task.isCancelled {
                withAnimation(AppAnimation.swipeHintFlick) { confirmTug = flickY }
                try? await Task.sleep(for: .milliseconds(320))
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
    // (beat) → advance to .compass (handled inside concludeContext).
    private func handleExit() {
        guard let index = confirmedIndex, !exiting else { return }
        stopConfirmTug()
        let option = options[index]
        director.hideDealerLine()

        // Step 1 — the chosen card launches up and off.
        withAnimation(AppAnimation.cardPocket.reduceMotionSafe) { exiting = true }

        Task { @MainActor in
            // Step 2 — a beat later, the rest drift out of focus (as the hero flies).
            try? await Task.sleep(for: .milliseconds(150))
            withAnimation(AppAnimation.exit.reduceMotionSafe) { defocusOthers = true }

            // Hero has cleared — return the felt, receive the credential, respond.
            try? await Task.sleep(for: .milliseconds(450))
            director.concludeContext(
                relationshipContext: option.context,
                situationalRegister: option.derivedRegister
            )
        }
    }
}
